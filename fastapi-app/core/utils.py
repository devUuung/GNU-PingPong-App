import os
import uuid
import shutil
from fastapi import UploadFile
from core.config import settings
from fastapi.encoders import jsonable_encoder
from models import User


def save_upload_file(upload_file: UploadFile) -> str:
    """
    업로드된 파일을 저장하고 파일 경로를 반환합니다.
    """
    # 업로드 디렉토리가 없으면 생성
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

    # 고유한 파일 이름 생성
    file_extension = os.path.splitext(upload_file.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = os.path.join(settings.UPLOAD_DIR, unique_filename)

    # 파일 저장
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)

    return file_path


def get_file_url(file_path: str) -> str:
    """
    파일 경로를 URL로 변환합니다.
    """
    if not file_path:
        return None

    # 파일 경로에서 static 폴더 이후의 경로만 추출
    if file_path.startswith("static/"):
        relative_path = file_path
    else:
        relative_path = f"static/{os.path.basename(file_path)}"

    # 서버 URL 기반으로 완전한 URL 생성
    return f"{relative_path}"


def prepare_user_response(user: User) -> dict:
    """
    사용자 정보를 응답용으로 가공합니다.
    """
    user_data = jsonable_encoder(user)

    # 프로필 이미지 URL 추가
    if user.profile_image:
        user_data["profile_image_url"] = get_file_url(user.profile_image)
    else:
        # 기본 프로필 이미지 URL 설정
        user_data["profile_image_url"] = get_file_url(settings.DEFAULT_PROFILE_IMAGE)

    return user_data
