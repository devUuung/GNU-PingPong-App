from datetime import datetime, timedelta
from typing import Optional
from fastapi import FastAPI, HTTPException, File, UploadFile, Form, Header
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from sqlalchemy.exc import IntegrityError
from models import create_user, read_user_by_student_id, update_user, User, read_user_by_user_id
from pydantic import BaseModel
from jose import jwt
import shutil, uuid, os

# JWT 관련 상수 (실제 운영에서는 비밀키를 환경변수로 관리하세요)
SECRET_KEY = "YOUR_SECRET_KEY"  # 반드시 안전하게 관리할 것
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 365

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

app = FastAPI()

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

    if user.password != password:
        return {"success": False, "message": "비밀번호가 틀렸습니다."}
    
    # JWT 토큰 생성 (예: student_id를 sub에 담음)
    access_token = create_access_token(data={"sub": str(user.user_id)})
    
    return {
        "success": True,
        "message": "로그인 성공",
        "access_token": access_token
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
            content={"success": False, "message": "해당 학번의 사용자가 이미 존재합니다."},
            media_type="application/json; charset=utf-8",
        )

    try:
        new_user = create_user(
            username=data.name,
            phone_number=data.phone,
            password=data.password,
            student_id=int(data.student_id),
            device_id=data.device_id,
        )
        new_user_data = jsonable_encoder(new_user)
        return JSONResponse(
            content={"success": True, "message": "회원가입 성공", "user": new_user_data},
            media_type="application/json; charset=utf-8",
        )
    except IntegrityError as e:
        return JSONResponse(
            content={"success": False, "message": "중복된 정보가 있습니다. 전화번호가 이미 등록되어 있을 수 있습니다."},
            status_code=400,
            media_type="application/json; charset=utf-8",
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.post("/api/upload-profile-image")
async def upload_profile_image(file: UploadFile = File(...)):
    file_extension = file.filename.split(".")[-1].lower()
    allowed_extensions = ["jpg", "jpeg", "png", "gif"]
    if file_extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="지원하지 않는 파일 형식입니다.")
    
    # 고유한 파일명 생성
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # 저장된 file_path를 데이터베이스에 저장하면 됩니다.
    return {"message": "업로드 성공", "file_path": file_path}

@app.get("/api/userinfo/{user_id}")
def get_user_info(user_id: str):
    user: Optional[User] = read_user_by_user_id(user_id)
    if not user:
        return JSONResponse(
            content={"success": False, "message": "사용자 정보를 찾을 수 없습니다."},
            status_code=404,
            media_type="application/json; charset=utf-8",
        )
    
    user_data = jsonable_encoder(user)
    return JSONResponse(
        content={"success": True, "user": user_data},
        media_type="application/json; charset=utf-8",
    )


@app.patch("/api/userinfo/{user_id}")
async def update_user_info(
    user_id: str,
    nickname: Optional[str] = Form(None),
    status_message: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None)
):
    # 사용자 조회
    user: Optional[User] = read_user_by_user_id(user_id)
    if not user:
        return JSONResponse(
            content={"success": False, "message": "사용자 정보를 찾을 수 없습니다."},
            status_code=404,
            media_type="application/json; charset=utf-8",
        )
    
    updated_fields = {}

    if nickname is not None:
        updated_fields["username"] = nickname
    if status_message is not None:
        updated_fields["status_message"] = status_message
    
    if file is not None:
        # 파일 확장자 검증
        file_extension = file.filename.split('.')[-1].lower()
        allowed_extensions = ["jpg", "jpeg", "png", "gif"]
        if file_extension not in allowed_extensions:
            raise HTTPException(status_code=400, detail="지원하지 않는 파일 형식입니다.")
        
        # 고유 파일명 생성 후 저장
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(UPLOAD_DIR, unique_filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        updated_fields["profile_image"] = file_path

    # 업데이트할 필드가 없는 경우
    if not updated_fields:
        return JSONResponse(
            content={"success": False, "message": "업데이트할 정보가 없습니다."},
            status_code=400,
            media_type="application/json; charset=utf-8",
        )

    # models.py의 update_user 함수를 호출하여 데이터베이스 업데이트 (구현에 따라 user와 딕셔너리를 넘긴다고 가정)
    updated_user = update_user(user, updated_fields)
    if not updated_user:
        raise HTTPException(status_code=500, detail="업데이트에 실패했습니다.")

    user_data = jsonable_encoder(updated_user)
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
        raise HTTPException(status_code=401, detail="Invalid authorization header format.")
    
    token = parts[1]
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Token payload missing user_id.")
        return JSONResponse(content={"valid": True, "user_id": user_id})
    except Exception as e:
        # 디버깅을 위해 에러 메시지 출력
        print("JWT decode error:", e)
        raise HTTPException(status_code=401, detail="Invalid or expired token.")