#!/bin/bash

# 인증서 디렉토리 생성
mkdir -p certs

# 자체 서명 인증서 생성
openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes -subj "/CN=localhost"

echo "자체 서명 SSL 인증서가 certs 디렉토리에 생성되었습니다."
echo "cert.pem: SSL 인증서"
echo "key.pem: SSL 개인 키"
echo ""
echo "SSL 설정이 완료되었습니다. 이제 애플리케이션을 시작하면 HTTPS가 자동으로 활성화됩니다." 