# 삼국지 성격 유형 검사

삼국지 인물 중 나와 가장 닮은 캐릭터를 찾아보는 간단한 성격 유형 테스트입니다.

## 사이트

https://avaroki.github.io/three-kingdoms-personality-test/

## 소개

총 7개의 질문에 답하면 선택한 답변에 따라 삼국지 인물별 점수가 계산됩니다.  
가장 높은 점수를 받은 인물이 결과로 나오며, 캐릭터 이미지와 간단한 설명을 함께 확인할 수 있습니다.

## 등장 인물

- 유비
- 조조
- 제갈량
- 관우
- 장비
- 손권
- 여포
- 조운
- 주유
- 사마의

## 사용 기술

- HTML
- CSS
- JavaScript

## 만든 사람

- avaroki

## Docker로 실행하기

```powershell
docker build -t three-kingdoms-hw3:local .
docker run -d --name three-kingdoms-hw3-local -p 127.0.0.1:8088:80 three-kingdoms-hw3:local
```

http://localhost:8088 에서 사이트를 확인할 수 있습니다.
`/health`는 서버 상태, `/version.json`은 배포 버전을 반환합니다.

## HW3 자동 빌드

main에 push하면 Docker CI가 이미지를 빌드하고, 페이지와 정적 파일의 HTTP 응답 및 배포 버전을 확인한 후 Docker Hub의 `avaroki/three-kingdoms-personality-test`에 업로드합니다.
필요한 GitHub Repository secrets는 `DOCKERHUB_USERNAME`과 `DOCKERHUB_TOKEN`입니다.
현재 워크플로는 CI 단계이며, 로컬 컨테이너 자동 배포와 재배포 중 응답 검증은 이어서 구성합니다.

## 로컬 자동 배포

Windows x64 self-hosted runner가 실행 중이면 CI 성공 후 CD가 이어서 실행됩니다.
서비스 주소는 http://localhost:8090 입니다. 기존 수동 실행 주소 8088과 별도로 동작합니다.
새 컨테이너를 먼저 실행하고 상태와 커밋을 확인한 뒤 nginx 프록시를 reload하여 전환합니다.
재배포 시에는 전환 전·중·후의 HTTP 요청과 버전을 기록하고 Actions Summary 및 artifact에 검증 결과를 저장합니다.
첫 배포에서는 기존 서비스가 없으므로 연속 응답 검증은 다음 업데이트부터 수행합니다.
