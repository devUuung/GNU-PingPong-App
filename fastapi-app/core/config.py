import os
from typing import List
from functools import lru_cache

# pydantic v1 또는 v2 호환성을 위한 설정
try:
    from pydantic_settings import BaseSettings
except ImportError:
    from pydantic import BaseSettings


class Settings(BaseSettings):
    # 기본 API 설정
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "GNU-PingPong-App"

    # CORS 설정
    BACKEND_CORS_ORIGINS: List[str] = [
        "*"
    ]  # 실제 운영 환경에서는 구체적인 도메인으로 제한하세요

    # JWT 설정
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY", "YOUR_SECRET_KEY"
    )  # 실제 운영에서는 환경변수로 설정하세요
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 365  # 1년

    # 파일 업로드 설정
    UPLOAD_DIR: str = "static/uploads"
    DEFAULT_PROFILE_IMAGE: str = "static/default_profile.png"

    # 서버 URL 설정
    SERVER_HOST: str = os.getenv("SERVER_HOST", "0.0.0.0")
    PORT: int = os.getenv("PORT", 8000)

    # SSL 설정
    SSL_ENABLED: bool = os.getenv("SSL_ENABLED", "True").lower() in ("true", "1", "t")
    SSL_CERTFILE: str = os.getenv("SSL_CERTFILE", "certs/cert.pem")
    SSL_KEYFILE: str = os.getenv("SSL_KEYFILE", "certs/key.pem")

    class Config:
        case_sensitive = True
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()


settings = get_settings()
