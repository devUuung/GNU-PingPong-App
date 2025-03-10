# HTTPS 설정 가이드

## 자체 서명 SSL 인증서 생성하기 (개발용)

개발 환경에서 HTTPS를 테스트하기 위해 자체 서명된 인증서를 생성할 수 있습니다. 
아래 명령어를 사용하여 `certs` 디렉토리에 인증서와 키를 생성합니다:

```bash
cd fastapi-app
mkdir -p certs
openssl req -x509 -newkey rsa:4096 -keyout certs/key.pem -out certs/cert.pem -days 365 -nodes -subj "/CN=localhost"
```

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