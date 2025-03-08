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
    student_id = data.student_id
    password = data.password

    user: Optional[User] = read_user_by_student_id(student_id)
    if not user:
        return {"success": False, "message": "해당 학번의 사용자를 찾을 수 없습니다."}

    if not bcrypt.checkpw(password.encode("utf-8"), user.password.encode("utf-8")):
        return {"success": False, "message": "비밀번호가 틀렸습니다."}

    # JWT 토큰 생성 (예: student_id를 sub에 담음)
    access_token = create_access_token(data={"sub": str(user.user_id)})

    # 사용자 정보 가공
    user_data = prepare_user_response(user)

    return {
        "success": True,
        "message": "로그인 성공",
        "access_token": access_token,
        "user": user_data,
    }


# 회원가입 및 기타 엔드포인트는 그대로 유지
class SignupData(BaseModel):
    student_id: str
    name: str
    phone: str
    password: str
    device_id: Optional[str] = None  # device_id 필드 추가


@app.post("/api/signup")
def signup(data: SignupData):
    existing_user = read_user_by_student_id(data.student_id)
    if existing_user:
        return JSONResponse(
            content={
                "success": False,
                "message": "해당 학번의 사용자가 이미 존재합니다.",
            },
            media_type="application/json; charset=utf-8",
        )

    existing_phone_user = read_user_by_phone_number(data.phone)
    if existing_phone_user:
        return JSONResponse(
            content={
                "success": False,
                "message": "해당 전화번호로 가입된 사용자가 이미 존재합니다.",
            },
            media_type="application/json; charset=utf-8",
        )

    hashed_password = bcrypt.hashpw(
        data.password.encode("utf-8"), bcrypt.gensalt()
    ).decode("utf-8")

    try:
        new_user = create_user(
            username=data.name,
            phone_number=data.phone,
            password=hashed_password,
            student_id=int(data.student_id),
            device_id=data.device_id,
            profile_image=DEFAULT_PROFILE_IMAGE,  # 기본 프로필 이미지 설정
        )
        new_user_data = prepare_user_response(new_user)
        return JSONResponse(
            content={
                "success": True,
                "message": "회원가입 성공",
                "user": new_user_data,
            },
            media_type="application/json; charset=utf-8",
        )
    except IntegrityError as e:
        return JSONResponse(
            content={
                "success": False,
                "message": "중복된 정보가 있습니다. 전화번호가 이미 등록되어 있을 수 있습니다.",
            },
            status_code=400,
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/upload-profile-image")
async def upload_profile_image(file: UploadFile = File(...)):
    file_extension = file.filename.split(".")[-1].lower()
    allowed_extensions = ["jpg", "jpeg", "png", "gif"]
    if file_extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="지원하지 않는 파일 형식입니다.")

    # 고유한 파일명 생성
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = os.path.join(settings.UPLOAD_DIR, unique_filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 파일 URL 생성
    file_url = get_file_url(file_path)

    # 저장된 file_path를 데이터베이스에 저장하면 됩니다.
    return {
        "success": True,
        "message": "업로드 성공",
        "file_path": file_path,
        "file_url": file_url,
    }


@app.get("/api/userinfo/{user_id}")
def get_user_info(user_id: str):
    try:
        user_id_int = int(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="유효하지 않은 user_id 입니다.")

    user: Optional[User] = read_user_by_user_id(user_id_int)
    if not user:
        return JSONResponse(
            content={"success": False, "message": "사용자 정보를 찾을 수 없습니다."},
            status_code=404,
            media_type="application/json; charset=utf-8",
        )

    user_data = prepare_user_response(user)
    return JSONResponse(
        content={"success": True, "user": user_data},
        media_type="application/json; charset=utf-8",
    )


@app.get("/api/usersinfo")
def get_users_info():
    users: Optional[User] = read_users_by_all()
    if not users:
        return JSONResponse(
            content={"success": False, "message": "사용자 정보를 찾을 수 없습니다."},
            status_code=404,
            media_type="application/json; charset=utf-8",
        )

    # 각 사용자의 프로필 이미지 URL 추가
    users_data = [prepare_user_response(user) for user in users]

    return JSONResponse(
        content={"success": True, "users": users_data},
        media_type="application/json; charset=utf-8",
    )


@app.put("/api/userinfo/{user_id}")
async def update_user_info(
    user_id: str,
    username: Optional[str] = Form(None),
    status_message: Optional[str] = Form(None),
    device_id: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
):
    try:
        user_id_int = int(user_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="유효하지 않은 user_id 입니다.")

    # 사용자 조회
    user: Optional[User] = read_user_by_user_id(user_id_int)
    if not user:
        return JSONResponse(
            content={"success": False, "message": "사용자 정보를 찾을 수 없습니다."},
            status_code=404,
            media_type="application/json; charset=utf-8",
        )

    updated_fields = {}

    if username is not None:
        updated_fields["username"] = username
    if status_message is not None:
        updated_fields["status_message"] = status_message
    if device_id is not None:
        updated_fields["device_id"] = device_id

    if file is not None:
        # 파일 확장자 검증
        file_extension = file.filename.split(".")[-1].lower()
        allowed_extensions = ["jpg", "jpeg", "png", "gif"]
        if file_extension not in allowed_extensions:
            raise HTTPException(
                status_code=400, detail="지원하지 않는 파일 형식입니다."
            )

        # 고유 파일명 생성 후 저장
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(settings.UPLOAD_DIR, unique_filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        updated_fields["profile_image"] = file_path

    print(updated_fields)

    # 업데이트할 필드가 없는 경우, 400 대신 현재 정보를 반환
    if not updated_fields:
        user_data = prepare_user_response(user)
        return JSONResponse(
            content={
                "success": True,
                "message": "변경된 정보가 없습니다.",
                "user": user_data,
            },
            media_type="application/json; charset=utf-8",
        )

    # models.py의 update_user 함수를 호출하여 데이터베이스 업데이트
    updated_user = update_user(user, updated_fields)
    if not updated_user:
        raise HTTPException(status_code=500, detail="업데이트에 실패했습니다.")

    user_data = prepare_user_response(updated_user)
    return JSONResponse(
        content={"success": True, "message": "프로필 업데이트 성공", "user": user_data},
        media_type="application/json; charset=utf-8",
    )


@app.post("/api/validateToken")
def validate_token(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header is missing.")

    parts = authorization.split()
    if parts[0].lower() != "bearer" or len(parts) != 2:
        raise HTTPException(
            status_code=401, detail="Invalid authorization header format."
        )

    token = parts[1]

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=401, detail="Token payload missing user_id."
            )
        user: Optional[User] = read_user_by_user_id(user_id)
        if not user:
            raise HTTPException(status_code=401, detail="User not found.")
        return JSONResponse(content={"valid": True, "user_id": user.user_id})
    except Exception as e:
        # 디버깅을 위해 에러 메시지 출력
        print("JWT decode error:", e)
        raise HTTPException(status_code=401, detail="Invalid or expired token.")


@app.get("/api/gamesinfo")
def get_games_info():
    games: Optional[Game] = read_games_by_all()
    if not games:
        return JSONResponse(
            content={"success": False, "message": "게임 정보를 찾을 수 없습니다."},
            status_code=404,
            media_type="application/json; charset=utf-8",
        )

    games_data = jsonable_encoder(games)
    return JSONResponse(
        content={"success": True, "games": games_data},
        media_type="application/json; charset=utf-8",
    )


# 요청 데이터를 위한 Pydantic 모델 정의
class GameInfo(BaseModel):
    winner_id: int
    loser_id: int
    plus_score: int
    minus_score: int


@app.post("/api/gamesinfo")
def post_game_info(game_info: GameInfo):
    print(game_info)
    winner: Optional[User] = read_user_by_user_id(game_info.winner_id)
    loser: Optional[User] = read_user_by_user_id(game_info.loser_id)

    update_user(
        winner,
        {
            "game_count": winner.game_count + 1,
            "score": winner.score + game_info.plus_score,
            "win_count": winner.win_count + 1,
        },
    )
    update_user(
        loser,
        {
            "game_count": loser.game_count + 1,
            "score": loser.score - game_info.minus_score,
            "lose_count": loser.lose_count + 1,
        },
    )

    game = create_game(
        winner_id=game_info.winner_id,
        loser_id=game_info.loser_id,
        plus_score=game_info.plus_score,
        minus_score=game_info.minus_score,
        winner_name=winner.username,
        loser_name=loser.username,
    )
    # game 객체를 직렬화 가능한 dict로 변환
    game_data = jsonable_encoder(game)
    return JSONResponse(
        content={
            "success": True,
            "message": "게임 정보 생성 성공",
            "game": game_data,
        },
        media_type="application/json; charset=utf-8",
    )


# 모집 공고 관련 API 엔드포인트
class PostInfo(BaseModel):
    writer_id: int
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    title: str


@app.post("/api/posts")
def create_post_api(post_info: PostInfo):
    try:
        # 작성자 확인
        writer: Optional[User] = read_user_by_user_id(post_info.writer_id)
        if not writer:
            return JSONResponse(
                content={
                    "success": False,
                    "message": "작성자 정보를 찾을 수 없습니다.",
                },
                status_code=404,
                media_type="application/json; charset=utf-8",
            )

        # 모집 공고 생성
        post = create_post(
            writer_id=post_info.writer_id,
            game_at=post_info.game_at,
            game_place=post_info.game_place,
            max_user=post_info.max_user,
            content=post_info.content,
            title=post_info.title,
        )

        # 응답 데이터 생성
        post_data = jsonable_encoder(post)
        return JSONResponse(
            content={
                "success": True,
                "message": "모집 공고 생성 성공",
                "post": post_data,
            },
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        print(f"모집 공고 생성 중 오류 발생: {e}")
        return JSONResponse(
            content={
                "success": False,
                "message": f"모집 공고 생성 중 오류가 발생했습니다: {str(e)}",
            },
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


@app.get("/api/posts")
def get_posts():
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


@app.get("/api/posts/{post_id}")
def get_post(post_id: int):
    try:
        post = read_post(post_id)

        # 참가자 정보 조회
        participants = read_post_participants_by_post_id(post_id)
        participant_ids = [p.user_id for p in participants]

        # 참가자 상세 정보 조회
        participant_details = []
        for user_id in participant_ids:
            user = read_user_by_user_id(user_id)
            if user:
                participant_details.append(jsonable_encoder(user))

        post_data = jsonable_encoder(post)
        post_data["participants"] = participant_details

        return JSONResponse(
            content={"success": True, "post": post_data},
            media_type="application/json; charset=utf-8",
        )
    except HTTPException as e:
        return JSONResponse(
            content={"success": False, "message": e.detail},
            status_code=e.status_code,
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


@app.post("/api/posts/{post_id}/join")
def join_post(post_id: int, user_id: int):
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


# Flutter 앱에서 모집공고 등록을 위한 API
class RecruitPostData(BaseModel):
    title: str
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    user_id: int  # 작성자 ID


@app.post("/api/recruit/post")
def create_recruit_post(data: RecruitPostData):
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
            status_code=200,
            content={
                "success": True,
                "message": "모집 공고가 성공적으로 등록되었습니다.",
                "post_id": post_id,
            },
            media_type="application/json; charset=utf-8",  # 명시적 인코딩 지정
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
            media_type="application/json; charset=utf-8",  # 명시적 인코딩 지정
        )


@app.post("/api/v1/recruit/post")
def create_recruit_post_v1(data: RecruitPostData):
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
            status_code=200,
            content={
                "success": True,
                "message": "모집 공고가 성공적으로 등록되었습니다.",
                "post_id": post_id,
            },
            media_type="application/json; charset=utf-8",  # 명시적 인코딩 지정
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
            media_type="application/json; charset=utf-8",  # 명시적 인코딩 지정
        )


# 모든 모집공고 조회 API
@app.get("/api/recruit/posts")
def get_recruit_posts():
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


# 게시물 목록 조회 API v1 경로 추가
@app.get("/api/v1/recruit/posts")
def get_recruit_posts_v1():
    # 기존 함수 재사용
    return get_recruit_posts()


# 모집공고 수정 API
class UpdatePostData(BaseModel):
    post_id: int
    title: str
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    user_id: int  # 작성자 ID (권한 확인용)


@app.put("/api/recruit/post/{post_id}")
def update_recruit_post(post_id: int, data: UpdatePostData):
    try:
        # 모집 공고 조회
        with Session(engine) as session:
            post = session.get(Post, post_id)
            if not post:
                return JSONResponse(
                    content={
                        "success": False,
                        "message": "모집 공고를 찾을 수 없습니다.",
                    },
                    status_code=404,
                    media_type="application/json; charset=utf-8",
                )

            # 작성자 확인 (권한 검증)
            if post.writer_id != data.user_id:
                return JSONResponse(
                    content={
                        "success": False,
                        "message": "모집 공고 수정 권한이 없습니다.",
                    },
                    status_code=403,
                    media_type="application/json; charset=utf-8",
                )

            # 모집 공고 수정
            post.title = data.title
            post.game_at = data.game_at
            post.game_place = data.game_place
            post.max_user = data.max_user
            post.content = data.content

            session.add(post)
            session.commit()
            session.refresh(post)

            post_data = jsonable_encoder(post)
            return JSONResponse(
                content={
                    "success": True,
                    "message": "모집 공고 수정 성공",
                    "post": post_data,
                },
                media_type="application/json; charset=utf-8",
            )
    except Exception as e:
        print(f"모집 공고 수정 중 오류 발생: {e}")
        return JSONResponse(
            content={
                "success": False,
                "message": f"모집 공고 수정 중 오류가 발생했습니다: {str(e)}",
            },
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


# 모집공고 삭제 API
@app.delete("/api/recruit/post/{post_id}")
def delete_recruit_post(post_id: int, user_id: int):
    try:
        # 모집 공고 조회
        with Session(engine) as session:
            post = session.get(Post, post_id)
            if not post:
                return JSONResponse(
                    content={
                        "success": False,
                        "message": "모집 공고를 찾을 수 없습니다.",
                    },
                    status_code=404,
                    media_type="application/json; charset=utf-8",
                )

            # 작성자 확인 (권한 검증)
            if post.writer_id != user_id:
                return JSONResponse(
                    content={
                        "success": False,
                        "message": "모집 공고 삭제 권한이 없습니다.",
                    },
                    status_code=403,
                    media_type="application/json; charset=utf-8",
                )

            # 참가자 정보 삭제
            participants = session.exec(
                select(PostParticipant).where(PostParticipant.post_id == post_id)
            ).all()
            for participant in participants:
                session.delete(participant)

            # 참가자 정보 삭제 후 commit
            session.commit()

            # 참가자 정보가 모두 삭제되었는지 확인
            remaining_participants = session.exec(
                select(PostParticipant).where(PostParticipant.post_id == post_id)
            ).all()

            if remaining_participants:
                return JSONResponse(
                    content={
                        "success": False,
                        "message": "참가자 정보 삭제에 실패했습니다.",
                    },
                    status_code=500,
                    media_type="application/json; charset=utf-8",
                )

            # 모집 공고 삭제
            session.delete(post)
            session.commit()

            return JSONResponse(
                content={
                    "success": True,
                    "message": "모집 공고 삭제 성공",
                },
                media_type="application/json; charset=utf-8",
            )
    except Exception as e:
        print(f"모집 공고 삭제 중 오류 발생: {e}")
        return JSONResponse(
            content={
                "success": False,
                "message": f"모집 공고 삭제 중 오류가 발생했습니다: {str(e)}",
            },
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


# 모집공고 참가 API
@app.post("/api/recruit/post/{post_id}/join")
def join_recruit_post(post_id: int, user_id: int):
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


# 모집공고 참가 취소 API
@app.delete("/api/recruit/post/{post_id}/leave")
def leave_recruit_post(post_id: int, user_id: int):
    try:
        # 모집 공고 조회
        post = read_post(post_id)

        # 참가 중인지 확인
        existing_participant = read_post_participant(post_id, user_id)
        if not existing_participant:
            return JSONResponse(
                content={
                    "success": False,
                    "message": "참가 중인 모집 공고가 아닙니다.",
                },
                status_code=400,
                media_type="application/json; charset=utf-8",
            )

        # 작성자는 참가 취소 불가 (모집 공고 삭제로 유도)
        if post.writer_id == user_id:
            return JSONResponse(
                content={
                    "success": False,
                    "message": "작성자는 참가 취소가 불가능합니다. 모집 공고를 삭제해주세요.",
                },
                status_code=400,
                media_type="application/json; charset=utf-8",
            )

        # 참가자 삭제
        with Session(engine) as session:
            participant = session.exec(
                select(PostParticipant)
                .where(
                    (PostParticipant.post_id == post_id)
                    & (PostParticipant.user_id == user_id)
                )
                .first()
            )

            if participant:
                session.delete(participant)
                session.commit()

        return JSONResponse(
            content={"success": True, "message": "모집 공고 참가 취소 성공"},
            media_type="application/json; charset=utf-8",
        )
    except HTTPException as e:
        return JSONResponse(
            content={"success": False, "message": e.detail},
            status_code=e.status_code,
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        print(f"모집 공고 참가 취소 중 오류 발생: {e}")
        return JSONResponse(
            content={
                "success": False,
                "message": f"모집 공고 참가 취소 중 오류가 발생했습니다: {str(e)}",
            },
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


# 비밀번호 변경 요청 바디 모델
class ChangePasswordData(BaseModel):
    old_password: str
    new_password: str


@app.post("/api/userinfo/{user_id}/change-password")
def change_password(
    user_id: str, data: ChangePasswordData, authorization: str = Header(None)
):
    if not authorization or not authorization.startswith("Bearer "):
        return JSONResponse(
            content={"success": False, "message": "인증이 필요합니다."},
            status_code=401,
            media_type="application/json; charset=utf-8",
        )

    token = authorization.replace("Bearer ", "")

    try:
        # JWT 토큰 검증
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_user_id = payload.get("sub")

        if token_user_id != user_id:
            return JSONResponse(
                content={"success": False, "message": "권한이 없습니다."},
                status_code=403,
                media_type="application/json; charset=utf-8",
            )

        # 사용자 조회
        user_id_int = int(user_id)
        user: Optional[User] = read_user_by_user_id(user_id_int)

        if not user:
            return JSONResponse(
                content={
                    "success": False,
                    "message": "사용자 정보를 찾을 수 없습니다.",
                },
                status_code=404,
                media_type="application/json; charset=utf-8",
            )

        # 현재 비밀번호 확인
        if not bcrypt.checkpw(
            data.old_password.encode("utf-8"), user.password.encode("utf-8")
        ):
            return JSONResponse(
                content={
                    "success": False,
                    "message": "현재 비밀번호가 일치하지 않습니다.",
                },
                status_code=401,
                media_type="application/json; charset=utf-8",
            )

        # 비밀번호 업데이트
        hashed_new_password = bcrypt.hashpw(
            data.new_password.encode("utf-8"), bcrypt.gensalt()
        ).decode("utf-8")

        updated_user = update_user(user_id_int, {"password": hashed_new_password})

        return JSONResponse(
            content={
                "success": True,
                "message": "비밀번호가 성공적으로 변경되었습니다.",
            },
            media_type="application/json; charset=utf-8",
        )

    except jwt.JWTError:
        return JSONResponse(
            content={"success": False, "message": "유효하지 않은 토큰입니다."},
            status_code=401,
            media_type="application/json; charset=utf-8",
        )
    except ValueError:
        return JSONResponse(
            content={"success": False, "message": "유효하지 않은 user_id 입니다."},
            status_code=400,
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        return JSONResponse(
            content={"success": False, "message": f"오류가 발생했습니다: {str(e)}"},
            status_code=500,
            media_type="application/json; charset=utf-8",
        )


# 관리자 페이지 엔드포인트
@app.get("/admin", response_class=HTMLResponse)
async def admin_page():
    try:
        # fastapi-app 내부의 static 폴더 사용
        with open("static/admin.html", "r", encoding="utf-8") as f:
            content = f.read()
        return HTMLResponse(content=content)
    except FileNotFoundError:
        return HTMLResponse(
            content="<h1>관리자 페이지를 찾을 수 없습니다.</h1><p>파일 경로를 확인해주세요.</p>"
        )


# 루트 페이지 (관리자 페이지로 리디렉션)
@app.get("/", response_class=RedirectResponse)
async def root():
    return RedirectResponse(url="/admin")


# 게시물 수정 API v1 경로 추가
@app.put("/api/v1/recruit/post/{post_id}")
def update_recruit_post_v1(post_id: int, data: UpdatePostData):
    # 기존 함수 재사용
    return update_recruit_post(post_id, data)


# 게시물 삭제 API v1 경로 추가
@app.delete("/api/v1/recruit/post/{post_id}")
def delete_recruit_post_v1(post_id: int, user_id: int):
    # 기존 함수 재사용
    return delete_recruit_post(post_id, user_id)


# 게시물 조회 API v1 경로 추가
@app.get("/api/v1/recruit/post/{post_id}")
def get_recruit_post_v1(post_id: int):
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


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host=settings.SERVER_HOST, port=settings.PORT)
