# docker/fastapi-dev.Dockerfile
FROM python:3.10-slim

# 작업 디렉토리 설정
WORKDIR /app

# 필요한 파일 복사
COPY ./fastapi-app /app
COPY ./fastapi-app/requirements.txt /app/requirements.txt

# 의존성 설치
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt