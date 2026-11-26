# GitHub에 올리고 공개하기

이 사이트는 GitHub Pages에 자동 배포됩니다. 공개 방문자는 글을 읽고, GitHub 계정 `mjkang312`만 글과 사진을 발행합니다. 실제 글 저장과 권한 검사는 Supabase가 처리합니다.

## 1. Supabase 데이터베이스 설정

1. [Supabase](https://supabase.com/dashboard)에서 프로젝트를 만듭니다.
2. SQL Editor에서 이 폴더의 `supabase-setup.sql` 전체를 실행합니다. 글 테이블, 작성자 허용 목록, 권한 정책, 사진 저장 버킷, 예시 글이 생성됩니다.
3. Authentication > Sign In / Providers에서 GitHub를 켭니다.
4. Supabase가 보여주는 GitHub callback URL을 복사합니다. 형식은 `https://<project-ref>.supabase.co/auth/v1/callback`입니다.
5. GitHub Settings > Developer settings > OAuth Apps에서 새 OAuth App을 만들고 callback URL을 입력합니다. Client ID와 Client secret을 Supabase GitHub provider 설정에 등록합니다. Client secret은 Supabase에만 보관하고 이 저장소에는 넣지 마세요.
6. GitHub Pages 주소를 정합니다. 사용자 사이트는 `https://mjkang312.github.io/`, 프로젝트 사이트는 `https://mjkang312.github.io/<저장소이름>/`입니다. Supabase Authentication URL Configuration에서 Site URL과 허용 Redirect URL에 해당 주소를 등록합니다.

SQL을 먼저 적용한 다음 `mjkang312` 계정으로 최초 로그인해야 작성자 목록에 등록됩니다. SQL 트리거는 Auth가 확인한 GitHub identity에서 사용자명을 확인합니다. 다른 계정은 로그인해도 읽기만 가능하고 발행 권한을 받지 않습니다.

## 2. 저장소와 자동 배포

1. 파일 전체를 GitHub 저장소의 기본 브랜치(`main` 또는 `master`) 루트에 올립니다. `.github/workflows/deploy.yml`도 포함해야 합니다.
2. 저장소의 Settings > Secrets and variables > Actions > Variables에서 아래 두 Repository variables를 만듭니다.
   - `SUPABASE_URL`: Supabase Project URL
   - `SUPABASE_PUBLISHABLE_KEY`: Supabase 브라우저용 publishable key (구형 프로젝트는 anon key)
3. Settings > Pages > Build and deployment에서 Source를 **GitHub Actions**로 설정합니다.
4. `main` 또는 `master`에 push하면 workflow가 사이트 파일과 `config.js`를 묶어 Pages에 배포합니다. 설정값이 빠지면 workflow가 이유를 표시하며 배포를 중단합니다. 배포 주소는 Settings > Pages에 표시됩니다.
5. 해당 HTTPS 주소가 위의 Supabase Site URL 및 Redirect URL과 일치하는지 확인합니다.

Repository variable로 넣는 Supabase URL과 publishable/anon key는 브라우저용 공개 값입니다. `service_role` key를 변수나 프론트엔드 파일에 넣지 마세요. GitHub OAuth Client secret은 GitHub OAuth App에서 발급받아 Supabase Dashboard에만 등록합니다.

## 로컬 미리보기

`config.js`는 로컬 미리보기용 빈 설정 템플릿입니다. Supabase Project URL과 publishable/anon key를 직접 입력하면 웹 서버에서 미리볼 수 있습니다. `file://` 주소는 OAuth 리디렉션 대상이 될 수 없으므로 로그인 확인은 HTTPS 배포 주소에서 진행하세요.

## 배포 후 동작 확인

- 로그인 전: 글과 사진을 읽을 수 있고, 글쓰기 버튼은 GitHub 로그인 창을 엽니다.
- `mjkang312`로 로그인: 글쓰기와 사진 발행이 가능하며, 새 글은 모든 방문자에게 보입니다.
- 다른 GitHub 계정: 글과 사진을 읽을 수 있지만 발행 요청은 Supabase RLS 정책에서 차단됩니다.

`supabase-setup.sql`은 초기 설정용입니다. 예시 글이 포함되어 있으므로 데이터가 있는 상태에서 전체 스크립트를 다시 실행하지 마세요.
