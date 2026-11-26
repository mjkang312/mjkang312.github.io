-- 느린 문장: 공개 읽기 + GitHub 사용자 mjkang312만 글/사진 작성
-- Supabase SQL Editor에서 전체를 실행하세요.

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null check (category in ('일상', '생각', '관계')),
  excerpt text not null default '',
  body text not null,
  image_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.blog_authors (
  user_id uuid primary key references auth.users(id) on delete cascade,
  github_username text not null unique,
  created_at timestamptz not null default now()
);

alter table public.posts enable row level security;
alter table public.blog_authors enable row level security;
revoke all on public.blog_authors from anon, authenticated;
grant select on public.posts to anon, authenticated;
grant insert, update, delete on public.posts to authenticated;

create or replace function public.is_blog_author()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.blog_authors a where a.user_id = (select auth.uid())
  );
$$;
revoke all on function public.is_blog_author() from public, anon;
grant execute on function public.is_blog_author() to authenticated;

drop policy if exists "Anyone can read posts" on public.posts;
create policy "Anyone can read posts" on public.posts for select using (true);
drop policy if exists "Only author can create posts" on public.posts;
create policy "Only author can create posts" on public.posts for insert to authenticated with check (public.is_blog_author());
drop policy if exists "Only author can edit posts" on public.posts;
create policy "Only author can edit posts" on public.posts for update to authenticated using (public.is_blog_author()) with check (public.is_blog_author());
drop policy if exists "Only author can delete posts" on public.posts;
create policy "Only author can delete posts" on public.posts for delete to authenticated using (public.is_blog_author());

-- GitHub OAuth identity는 Auth 서비스가 기록합니다. 승인 identity만
-- 서버 측 author 목록에 저장하므로 클라이언트에서 작성 권한을 위조할 수 없습니다.
create or replace function public.approve_blog_github_author()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  github_login text;
begin
  if new.provider = 'github' then
    github_login := lower(coalesce(
      new.identity_data ->> 'user_name',
      new.identity_data ->> 'login',
      new.identity_data ->> 'preferred_username',
      ''
    ));
    if github_login = 'mjkang312' then
      insert into public.blog_authors (user_id, github_username)
      values (new.user_id, github_login)
      on conflict (user_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.approve_blog_github_author() from public, anon, authenticated;
drop trigger if exists approve_blog_github_author on auth.identities;
create trigger approve_blog_github_author
  after insert on auth.identities
  for each row execute function public.approve_blog_github_author();

-- 공개 이미지 조회, 작성자만 업로드/수정/삭제
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('post-images', 'post-images', true, 10485760, array['image/jpeg'])
on conflict (id) do update set public = true, file_size_limit = 10485760, allowed_mime_types = array['image/jpeg'];

drop policy if exists "Public can view post images" on storage.objects;
create policy "Public can view post images" on storage.objects for select using (bucket_id = 'post-images');
drop policy if exists "Author can upload post images" on storage.objects;
create policy "Author can upload post images" on storage.objects for insert to authenticated with check (bucket_id = 'post-images' and public.is_blog_author());
drop policy if exists "Author can update post images" on storage.objects;
create policy "Author can update post images" on storage.objects for update to authenticated using (bucket_id = 'post-images' and public.is_blog_author()) with check (bucket_id = 'post-images' and public.is_blog_author());
drop policy if exists "Author can delete post images" on storage.objects;
create policy "Author can delete post images" on storage.objects for delete to authenticated using (bucket_id = 'post-images' and public.is_blog_author());

-- 첫 공개 시 보일 예시 글 3개
insert into public.posts (title, category, excerpt, body, created_at) values
('아무 일도 없던 날의 소중함', '일상', '특별한 사건 없이 지나간 하루를 돌아보다가, 문득 그런 날이 가장 귀하다는 생각을 했다.', '특별한 일이 없었다.
아침에 커튼을 열고, 식은 커피를 한 모금 마시고, 창가에 오래 앉아 있었다.

한때는 이런 날을 아무것도 하지 않은 날이라고 불렀다. 하지만 오늘은 조금 다르게 생각해보기로 했다. 무사히 지나간 하루, 마음이 크게 흔들리지 않은 저녁. 그런 평범함이 내게 얼마나 많은 여유를 건네는지 이제는 안다.

아무 일도 없던 날은 아무것도 아닌 날이 아니었다.', '2025-05-18 09:00:00+09'),
('느리게 가도 괜찮다는 마음', '생각', '남들보다 늦은 것 같아 조급해질 때, 내 안의 계절을 떠올려본다.', '남들보다 늦은 것 같다는 생각이 들 때가 있다. 누군가는 벌써 저만치 앞서 있는 듯하고, 나는 같은 자리를 맴도는 것처럼 느껴진다.

그럴 때면 계절을 생각한다. 나무마다 꽃이 피는 시기가 다르듯 마음에도 각자의 때가 있다. 지금 내게 필요한 것은 더 빨리 달리는 일이 아니라, 오늘 할 수 있는 만큼을 다정하게 해내는 일일지도 모른다.

조금 느린 걸음도 분명 앞으로 가고 있다.', '2025-05-11 09:00:00+09'),
('안부를 묻는 일에 대하여', '관계', '잘 지내냐는 짧은 말이 오래 마음에 남는 날이 있다.', '오랜만에 친구에게서 안부가 왔다. 잘 지내냐는 짧은 말이었다. 별일 없다는 답장을 쓰다가 잠깐 멈추었다.

정말 별일이 없었나. 작게 웃었던 순간도, 괜히 마음이 무거웠던 저녁도 있었다. 그 모든 것을 한 문장에 담기는 어렵지만, 누군가 물어봐 주었다는 사실만으로도 오늘은 조금 가벼워졌다.

안부를 묻는 일은 어쩌면 이렇게 말하는 것인지도 모른다. 나는 여전히 당신을 생각하고 있다고.', '2025-05-03 09:00:00+09')
on conflict do nothing;
