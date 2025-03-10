@echo off
chcp 65001

REM certs 디렉토리 생성 (이미 있으면 건너뜁니다)
if not exist certs (
    mkdir certs
)

REM 자체 서명 인증서 생성 (출력 및 에러 메시지를 숨깁니다)
openssl req -x509 -newkey rsa:4096 -keyout certs\key.pem -out certs\cert.pem -days 365 -nodes -subj "/CN=localhost" >nul 2>&1

echo.
echo 자체 서명 SSL 인증서가 certs 디렉토리에 생성되었습니다.
echo cert.pem: SSL 인증서
echo key.pem: SSL 개인 키
echo.
echo SSL 설정이 완료되었습니다. 이제 애플리케이션을 시작하면 HTTPS가 자동으로 활성화됩니다.
pause
