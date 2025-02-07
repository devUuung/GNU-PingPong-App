from fastapi import FastAPI, HTTPException
from models import (
    create_user,
    read_user_by_user_id,
    User,
    Session,
    engine,
    create_game,
    read_game,
    read_games_by_user_id,
    update_game,
    delete_game,
    create_score_rank,
    read_score_rank,
    read_score_rank_by_user_id,
    update_score_rank,
    delete_score_rank,
    create_post,
    read_post,
    read_posts_by_writer_id,
    update_post,
    delete_post,
    create_post_participant,
    read_post_participant,
    read_post_participants_by_post_id,
    read_post_participants_by_user_id,
    delete_post_participant,
    update_user,
    delete_user,
    read_user_by_student_id,
)
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

app = FastAPI()


# 로그인 요청 바디 모델
class LoginData(BaseModel):
    student_id: str
    password: str
    device_id: str | None = None


@app.post("/api/login")
def login(data: LoginData):
    student_id = data.student_id
    password = data.password  # 해시화 된 정보
    device_id = data.device_id  # 해시화 된 정보

    # (1) 사용자 존재 확인
    user: User | None = read_user_by_student_id(student_id)
    if not user:
        # 학번이 없음
        return {"success": False, "message": "해당 학번의 사용자를 찾을 수 없습니다."}

    # (2) 비밀번호 검증
    if user["password"] != password:
        return {"success": False, "message": "비밀번호가 틀렸습니다."}

    # (3) 기기정보 매칭
    # 서버에 저장된 기기와 동일하면 deviceMatch=True
    server_device_id = user["device_id"]
    device_match = False
    if server_device_id is not None and device_id is not None:
        device_match = server_device_id == device_id

    if not device_match:
        # 기기 정보 업데이트
        update_user(user_id=user.user_id, device_id=device_id)

    # (4) 응답
    return {
        "success": True,
        "message": "로그인 성공",
        "deviceMatch": device_match,
    }
