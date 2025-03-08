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


# 모집공고 생성 API - v1 버전
class RecruitPostData(BaseModel):
    title: str
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    user_id: int  # 작성자 ID


@app.post("/api/v1/recruit/post")
def create_recruit_post_v1(data: RecruitPostData):
    """모집공고 생성 API - v1 버전"""
    try:
        # 포스트 작성자 확인
        user = read_user_by_user_id(data.user_id)
        if not user:
            return JSONResponse(
                status_code=404,
                content={"success": False, "message": "사용자를 찾을 수 없습니다."},
            )

        # 게시물 생성 - 개별 파라미터로 전달
        post = create_post(
            writer_id=data.user_id,
            game_at=data.game_at,
            game_place=data.game_place,
            max_user=data.max_user,
            content=data.content,
            title=data.title,
        )

        # post 객체에서 post_id 가져오기
        post_id = post.post_id

        # 작성자를 첫 번째 참가자로 자동 등록 - 객체 전달 대신 매개변수 전달
        create_post_participant(post_id=post_id, user_id=data.user_id)

        return JSONResponse(
            status_code=201,
            content={
                "success": True,
                "message": "모집 공고가 성공적으로 등록되었습니다.",
                "post_id": post_id,
            },
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
            media_type="application/json; charset=utf-8",
        )


# 모집공고 참가 API - v1 버전
@app.post("/api/v1/recruit/post/{post_id}/join")
def join_recruit_post_v1(post_id: int, user_id: int):
    """모집공고 참가 API - v1 버전"""
    try:
        # 모집 공고 조회
        post = read_post(post_id)

        # 사용자 조회
        user = read_user_by_user_id(user_id)
        if not user:
            return JSONResponse(
                content={
                    "success": False,
                    "message": "사용자 정보를 찾을 수 없습니다.",
                },
                status_code=404,
                media_type="application/json; charset=utf-8",
            )

        # 이미 참가 중인지 확인
        existing_participant = read_post_participant(post_id, user_id)
        if existing_participant:
            return JSONResponse(
                content={
                    "success": False,
                    "message": "이미 참가 중인 모집 공고입니다.",
                },
                status_code=400,
                media_type="application/json; charset=utf-8",
            )

        # 현재 참가자 수 확인
        participants = read_post_participants_by_post_id(post_id)
        if len(participants) >= post.max_user:
            return JSONResponse(
                content={"success": False, "message": "모집 인원이 가득 찼습니다."},
                status_code=400,
                media_type="application/json; charset=utf-8",
            )

        # 참가자 추가
        participant = create_post_participant(post_id, user_id)

        return JSONResponse(
            content={"success": True, "message": "모집 공고 참가 성공"},
            media_type="application/json; charset=utf-8",
        )
    except HTTPException as e:
        return JSONResponse(
            content={"success": False, "message": e.detail},
            status_code=e.status_code,
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        print(f"모집 공고 참가 중 오류 발생: {e}")
        return JSONResponse(
            content={
                "success": False,
                "message": f"모집 공고 참가 중 오류가 발생했습니다: {str(e)}",
            },
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


# 아래 API는 앱에서 특별히 사용하고 있는 경로이므로 다시 추가합니다
@app.get("/api/v1/recruit/posts")
def get_recruit_posts_v1():
    """모든 모집공고 조회 API - v1 버전"""
    try:
        # 모든 모집 공고 조회
        with Session(engine) as session:
            posts = session.exec(select(Post)).all()

        if not posts:
            return JSONResponse(
                content={
                    "success": True,
                    "message": "모집 공고가 없습니다.",
                    "posts": [],
                },
                media_type="application/json; charset=utf-8",
            )

        posts_data = jsonable_encoder(posts)
        return JSONResponse(
            content={"success": True, "posts": posts_data},
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        print(f"모집 공고 조회 중 오류 발생: {e}")
        return JSONResponse(
            content={
                "success": False,
                "message": f"모집 공고 조회 중 오류가 발생했습니다: {str(e)}",
            },
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


# 특정 모집공고 조회 API - v1 버전
@app.get("/api/v1/recruit/post/{post_id}")
def get_recruit_post_v1(post_id: int):
    """특정 모집공고 조회 API - v1 버전"""
    try:
        # 게시물 정보 조회
        with Session(engine) as session:
            post = session.get(Post, post_id)
            if not post:
                return JSONResponse(
                    content={
                        "success": False,
                        "message": "게시물을 찾을 수 없습니다.",
                    },
                    status_code=404,
                )

            # 참가자 정보 조회
            participants = session.exec(
                select(PostParticipant).where(PostParticipant.post_id == post_id)
            ).all()

            # 게시물과 참가자 정보 응답
            post_data = jsonable_encoder(post)
            participants_data = jsonable_encoder(participants)

            return JSONResponse(
                content={
                    "success": True,
                    "post": post_data,
                    "participants": participants_data,
                },
            )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": f"서버 오류: {str(e)}",
            },
        )


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
