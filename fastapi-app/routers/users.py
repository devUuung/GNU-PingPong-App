from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError
from typing import List, Optional
from pydantic import BaseModel
from datetime import timedelta
from sqlmodel import Session

from core.config import settings
from core.auth import create_access_token, get_current_active_user, get_admin_user
from core.utils import save_upload_file, prepare_user_response
from models import (
    User,
    create_user,
    read_user_by_student_id,
    read_user_by_user_id,
    read_user_by_phone_number,
    read_users_by_all,
    update_user,
    engine,
)

router = APIRouter(prefix=f"{settings.API_V1_STR}/users", tags=["users"])


# 사용자 인증 모델
class UserAuth(BaseModel):
    student_id: int
    password: str


# 사용자 생성 모델
class UserCreate(BaseModel):
    username: str
    phone_number: str
    password: str
    student_id: int
    device_id: Optional[str] = None


# 사용자 업데이트 모델
class UserUpdate(BaseModel):
    username: Optional[str] = None
    phone_number: Optional[str] = None
    status_message: Optional[str] = None
    device_id: Optional[str] = None


# 비밀번호 변경 모델
class PasswordChange(BaseModel):
    old_password: str
    new_password: str


# 로그인 API
@router.post("/login")
async def login(user_auth: UserAuth):
    user = read_user_by_student_id(user_auth.student_id)
    if not user or user.password != user_auth.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect student ID or password",
        )

    # JWT 토큰 생성
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.user_id)}, expires_delta=access_token_expires
    )

    return {"success": True, "access_token": access_token, "token_type": "bearer"}


# 회원가입 API
@router.post("/signup", status_code=status.HTTP_201_CREATED)
async def signup(user_create: UserCreate):
    try:
        # 학번 중복 확인
        existing_user = read_user_by_student_id(user_create.student_id)
        if existing_user:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={"success": False, "message": "이미 등록된 학번입니다."},
            )

        # 전화번호 중복 확인
        existing_user = read_user_by_phone_number(user_create.phone_number)
        if existing_user:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={"success": False, "message": "이미 등록된 전화번호입니다."},
            )

        # 사용자 생성
        user = create_user(
            username=user_create.username,
            phone_number=user_create.phone_number,
            password=user_create.password,
            student_id=user_create.student_id,
            device_id=user_create.device_id,
        )

        # JWT 토큰 생성
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.user_id)}, expires_delta=access_token_expires
        )

        return {
            "success": True,
            "access_token": access_token,
            "token_type": "bearer",
        }

    except IntegrityError:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"success": False, "message": "데이터베이스 오류가 발생했습니다."},
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
        )


# 현재 사용자 정보 조회 API
@router.get("/me")
async def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    return {"success": True, "user": prepare_user_response(current_user)}


# 사용자 정보 업데이트 API
@router.put("/me")
async def update_current_user(
    user_update: UserUpdate, current_user: User = Depends(get_current_active_user)
):
    # 업데이트할 필드 설정
    update_data = {}
    if user_update.username is not None:
        update_data["username"] = user_update.username
    if user_update.phone_number is not None:
        # 전화번호 중복 검사
        existing_user = read_user_by_phone_number(user_update.phone_number)
        if existing_user and existing_user.user_id != current_user.user_id:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={"success": False, "message": "이미 등록된 전화번호입니다."},
            )
        update_data["phone_number"] = user_update.phone_number
    if user_update.status_message is not None:
        update_data["status_message"] = user_update.status_message
    if user_update.device_id is not None:
        update_data["device_id"] = user_update.device_id

    # 사용자 정보 업데이트
    try:
        updated_user = update_user(current_user, update_data)
        # 사용자 정보에서 비밀번호를 제외하고 응답
        return {"success": True, "user": prepare_user_response(updated_user)}
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": str(e)},
        )


# 프로필 이미지 업로드 API
@router.post("/me/profile-image")
async def upload_profile_image(
    file: UploadFile = File(...), current_user: User = Depends(get_current_active_user)
):
    try:
        # 파일 저장
        file_path = save_upload_file(file)

        # 사용자 프로필 이미지 업데이트
        current_user.profile_image = file_path
        updated_user = update_user(current_user)

        return {"success": True, "user": prepare_user_response(updated_user)}

    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"파일 업로드 오류: {str(e)}"},
        )


# 비밀번호 변경 API
@router.put("/me/password")
async def change_password(
    password_change: PasswordChange,
    current_user: User = Depends(get_current_active_user),
):
    # 현재 비밀번호 확인
    if current_user.password != password_change.old_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="현재 비밀번호가 일치하지 않습니다.",
        )

    # 비밀번호 업데이트
    current_user.password = password_change.new_password
    update_user(current_user)

    return {"success": True, "message": "비밀번호가 변경되었습니다."}


# 모든 사용자 조회 API (일반 사용자도 접근 가능)
@router.get("/all", response_model=List[dict])
async def get_all_users(current_user: User = Depends(get_current_active_user)):
    users = read_users_by_all()

    # 모든 사용자가 유저 목록에 접근 가능하도록 제한 해제
    return [prepare_user_response(user) for user in users]


# 특정 사용자 조회 API
@router.get("/{user_id}")
async def get_user(user_id: int, current_user: User = Depends(get_current_active_user)):
    user = read_user_by_user_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="사용자를 찾을 수 없습니다."
        )

    return {"success": True, "user": prepare_user_response(user)}


# 특정 사용자 정보 업데이트 API (프로필 이미지 포함)
@router.put("/{user_id}")
async def update_user_profile(
    user_id: int,
    username: Optional[str] = Form(None),
    status_message: Optional[str] = Form(None),
    device_id: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_active_user),
):
    # 권한 확인: 자신의 정보만 수정 가능
    if current_user.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 프로필만 수정할 수 있습니다.",
        )

    # 업데이트할 필드 설정
    update_data = {}
    if username is not None:
        update_data["username"] = username
    if status_message is not None:
        update_data["status_message"] = status_message
    if device_id is not None:
        update_data["device_id"] = device_id

    # 파일 처리
    if file is not None:
        try:
            # 파일 저장
            file_path = save_upload_file(file)
            update_data["profile_image"] = file_path
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"파일 업로드 오류: {str(e)}",
            )

    # 사용자 정보 업데이트
    try:
        updated_user = update_user(current_user, update_data)
        return {"success": True, "user": prepare_user_response(updated_user)}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


# 토큰 검증 API
@router.post("/validate-token")
async def validate_token(current_user: User = Depends(get_current_active_user)):
    return {"success": True, "valid": True, "user_id": current_user.user_id}
