from datetime import datetime, timedelta
from typing import Optional
from fastapi import FastAPI, HTTPException, File, UploadFile, Form, Header
from fastapi.responses import JSONResponse, RedirectResponse, HTMLResponse
from fastapi.encoders import jsonable_encoder
from sqlalchemy.exc import IntegrityError
from models import (
    create_user,
    read_user_by_student_id,
    update_user,
    User,
    read_user_by_user_id,
    read_user_by_phone_number,
    read_games_by_all,
    Game,
    read_users_by_all,
    create_game,
    create_post,
    read_post,
    read_post_participants_by_post_id,
    read_post_participant,
    create_post_participant,
    Post,
    PostParticipant,
    engine,
)
from pydantic import BaseModel
from jose import jwt
import shutil, uuid, os
from sqlmodel import Session, select
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import bcrypt

from core.config import settings
from routers import users, games, posts, admin

# JWT 관련 상수 (실제 운영에서는 비밀키를 환경변수로 관리하세요)
SECRET_KEY = "YOUR_SECRET_KEY"  # 반드시 안전하게 관리할 것
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 365

# 업로드 디렉토리 설정
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)

# 기본 프로필 이미지 경로 설정
DEFAULT_PROFILE_IMAGE = "static/default_profile.png"

app = FastAPI(title=settings.PROJECT_NAME)

# CORS 미들웨어 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 한글 인코딩을 위한 미들웨어 추가
@app.middleware("http")
async def add_charset_utf8_to_json_response(request, call_next):
    response = await call_next(request)
    if response.headers.get("content-type") == "application/json":
        response.headers["content-type"] = "application/json; charset=utf-8"
    return response


# 정적 파일 마운트 설정 - fastapi-app 내부의 static 폴더 사용
app.mount("/static", StaticFiles(directory="static"), name="static")

# 라우터 등록
app.include_router(users.router)
app.include_router(games.router)
app.include_router(posts.router)
app.include_router(admin.router, prefix=settings.API_V1_STR)


# JWT 토큰 생성 함수
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    # 'exp'를 정수형 timestamp로 저장
    to_encode.update({"exp": int(expire.timestamp())})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


# 파일 경로를 URL로 변환하는 함수
def get_file_url(file_path: str) -> str:
    if not file_path:
        return None

    # 파일 경로에서 static 폴더 이후의 경로만 추출
    if file_path.startswith("static/"):
        relative_path = file_path
    else:
        relative_path = f"static/{os.path.basename(file_path)}"

    # 서버 URL 기반으로 완전한 URL 생성
    base_url = f"{settings.SERVER_HOST}:{settings.PORT}"  # 실제 서버 URL로 변경해야 함
    return f"{base_url}/{relative_path}"


# 사용자 정보를 응답용으로 가공하는 함수
def prepare_user_response(user: User) -> dict:
    user_data = jsonable_encoder(user)

    # 프로필 이미지 URL 추가
    if user.profile_image:
        user_data["profile_image_url"] = get_file_url(user.profile_image)
    else:
        # 기본 프로필 이미지 URL 설정
        user_data["profile_image_url"] = get_file_url(DEFAULT_PROFILE_IMAGE)

    return user_data


# 로그인 요청 바디 모델
class LoginData(BaseModel):
    student_id: str
    password: str


@app.post("/api/login")
def login(data: LoginData):
    # 삭제: 라우터에 동일 기능이 있음
    pass


# 회원가입 및 기타 엔드포인트는 그대로 유지
class SignupData(BaseModel):
    student_id: str
    name: str
    phone: str
    password: str
    device_id: Optional[str] = None  # device_id 필드 추가


@app.post("/api/signup")
def signup(data: SignupData):
    # 삭제: 라우터에 동일 기능이 있음
    pass


@app.post("/api/upload-profile-image")
async def upload_profile_image(file: UploadFile = File(...)):
    # 삭제: 라우터에 동일 기능이 있음
    pass


@app.get("/api/userinfo/{user_id}")
def get_user_info(user_id: str):
    # 삭제: 라우터에 동일 기능이 있음
    pass


@app.get("/api/usersinfo")
def get_users_info():
    # 삭제: 라우터에 동일 기능이 있음
    pass


@app.put("/api/userinfo/{user_id}")
async def update_user_info(
    user_id: str,
    username: Optional[str] = Form(None),
    status_message: Optional[str] = Form(None),
    device_id: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
):
    # 삭제: 라우터에 동일 기능이 있음
    pass


@app.post("/api/validateToken")
def validate_token(authorization: Optional[str] = Header(None)):
    # 삭제: 라우터에 동일 기능이 있음
    pass


# 로그인, 회원가입, 사용자 정보 관련 API는 라우터로 이관되었습니다.
# users.router를 참조하세요.


# 게임 관련 API는 라우터로 이관되었습니다.
# games.router를 참조하세요.


# 모집 공고 관련 API 엔드포인트
class PostInfo(BaseModel):
    writer_id: int
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    title: str


# 게시물 관련 API는 라우터로 이관되었습니다.
# posts.router를 참조하세요.


# 관리자 페이지 엔드포인트
@app.get("/admin", response_class=HTMLResponse)
async def admin_page():
    # HTML 응답
    with open(os.path.join(os.path.dirname(__file__), "static/admin.html"), "r") as f:
        html_content = f.read()
    return HTMLResponse(content=html_content)


# 루트 경로를 관리자 페이지로 리다이렉트
@app.get("/", response_class=RedirectResponse)
async def root():
    return RedirectResponse(url="/admin")


# 서버 실행 (직접 실행 시)
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=settings.SERVER_HOST, port=settings.PORT)
