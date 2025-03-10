# HTTPS 설정 가이드

## ⚠️ 중요 보안 경고

**절대로 SSL 인증서(cert.pem)와 개인 키 파일(key.pem)을 GitHub와 같은 공개 저장소에 올리지 마세요!**

개인 키가 노출되면 다음과 같은 심각한 보안 위험이 있습니다:
- 서버 신원 가장 가능
- 암호화된 통신 감청
- 중간자 공격 위험
- 개인정보 유출

이러한 파일들은 항상 `.gitignore`에 추가하여 저장소에서 제외해야 합니다.

## 자체 서명 SSL 인증서 생성하기 (개발용)

개발 환경에서 HTTPS를 테스트하기 위해 자체 서명된 인증서를 생성할 수 있습니다. 
아래 명령어를 사용하여 `certs` 디렉토리에 인증서와 키를 생성합니다:

```bash
cd fastapi-app
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes -subj "/CN=localhost"
```

## 안전한 SSL 인증서 관리 방법

SSL 인증서와 개인 키를 안전하게 관리하기 위해 다음 방법을 권장합니다:

### 개발 환경

1. 개발 환경에서는 각 개발자가 `generate_certs.sh` 스크립트를 사용하여 자신의 로컬 환경에 인증서를 직접 생성합니다.
2. 인증서 파일을 `.gitignore`에 추가하여 실수로 저장소에 커밋되지 않도록 합니다.
3. 팀원 간에 인증서 파일을 공유해야 할 경우, 안전한 채널(암호화된 이메일, 보안 파일 공유 서비스 등)을 사용합니다.

### 프로덕션 환경

1. 프로덕션 인증서는 신뢰할 수 있는 인증 기관(CA)에서 발급받습니다.
2. 인증서와 키 파일은 서버의 안전한 위치에 저장하고, 제한된 접근 권한을 설정합니다:
   ```bash
   sudo chmod 600 /path/to/your/key.pem
   sudo chmod 644 /path/to/your/cert.pem
   ```
3. 환경 변수나 비공개 설정 파일을 통해 인증서 경로를 지정합니다.
4. 가능하면 키 관리 서비스(AWS KMS, HashiCorp Vault 등)를 사용합니다.
5. 정기적으로 인증서를 갱신하고, 만료일을 모니터링합니다.

### CI/CD 파이프라인에서의 관리

1. 인증서와 키를 CI/CD 파이프라인에서 환경 변수로 설정합니다.
2. 환경 변수는 저장소가 아닌 CI/CD 시스템의 보안 저장소에 저장합니다.
3. 배포 과정에서 필요한 경우에만 인증서 파일을 생성합니다.

## 프로덕션 환경에서의 HTTPS 설정

실제 프로덕션 환경에서는 다음 중 하나의 방법을 권장합니다:

### 1. 공인 SSL 인증서 사용하기

Let's Encrypt와 같은 서비스를 통해 무료로 SSL 인증서를 발급받을 수 있습니다.
인증서를 발급받은 후, 다음과 같이 환경 변수를 설정합니다:

```bash
export SSL_ENABLED=True
export SSL_CERTFILE=/path/to/your/fullchain.pem
export SSL_KEYFILE=/path/to/your/privkey.pem
```

또는 `.env` 파일에 다음과 같이 설정합니다:

```
SSL_ENABLED=True
SSL_CERTFILE=/path/to/your/fullchain.pem
SSL_KEYFILE=/path/to/your/privkey.pem
```

### 2. 리버스 프록시 사용하기

Nginx, Apache, Traefik 등의 리버스 프록시를 사용하여 SSL 종료를 처리하는 방법도 있습니다.
이 경우 애플리케이션은 HTTP로 실행하고, 리버스 프록시가 HTTPS를 처리합니다.

예시 Nginx 설정:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTP를 HTTPS로 리다이렉트
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}
```

## 설정 확인

애플리케이션을 시작하면 설정에 따라 자동으로 HTTPS가 활성화됩니다.
HTTPS가 정상적으로 작동하는지 확인하려면 브라우저에서 `https://domain-or-ip:port`로 접속해보세요. 