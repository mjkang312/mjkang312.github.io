# 느린 문장

생각과 일상을 기록하는 개인 블로그입니다. 공개 방문자는 글을 읽을 수 있고, GitHub 사용자 `mjkang312`만 로그인해 글과 사진을 발행할 수 있습니다.

## GitHub Pages 배포

저장소의 `main` 또는 `master` 브랜치에 이 폴더의 파일을 올리면 `.github/workflows/deploy.yml`이 자동으로 사이트를 배포합니다. 저장소 Settings > Secrets and variables > Actions > Variables에 아래 항목이 먼저 있어야 합니다.

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

배포 workflow는 이 값으로 `config.js`를 생성합니다. 값이 없으면 배포가 실패하고 필요한 설정을 안내합니다. GitHub Pages 설정의 Build and deployment Source는 **GitHub Actions**로 선택하세요.

## 최초 설정

Supabase 프로젝트, GitHub OAuth 앱, 데이터베이스/RLS 정책을 먼저 준비해야 로그인 및 게시가 동작합니다. 전체 순서는 [SETUP.md](SETUP.md)를 참고하세요. SQL 초기 스키마와 예시 글은 [supabase-setup.sql](supabase-setup.sql)에 있습니다.

Supabase 브라우저용 publishable/anon key만 사용하세요. `service_role` key와 GitHub OAuth Client secret은 사이트 파일에 넣지 않습니다.
