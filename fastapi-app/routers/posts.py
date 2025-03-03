from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from sqlmodel import Session

from core.config import settings
from core.auth import get_current_active_user
from core.utils import prepare_user_response
from models import (
    User,
    Post,
    PostParticipant,
    create_post,
    read_post,
    read_post_participants_by_post_id,
    read_post_participant,
    create_post_participant,
    read_user_by_user_id,
    engine,
)

router = APIRouter(prefix=f"{settings.API_V1_STR}/posts", tags=["posts"])


# 게시물 생성 모델
class PostCreate(BaseModel):
    title: str
    content: str
    max_participants: int
    meeting_time: datetime


# 게시물 참가 모델
class PostParticipantCreate(BaseModel):
    post_id: int


# 게시물 생성 API
@router.post("/create", status_code=status.HTTP_201_CREATED)
async def create_new_post(
    post_create: PostCreate, current_user: User = Depends(get_current_active_user)
):
    try:
        # 게시물 생성
        new_post = Post(
            title=post_create.title,
            content=post_create.content,
            max_participants=post_create.max_participants,
            meeting_time=post_create.meeting_time,
            creator_id=current_user.user_id,
            creator_name=current_user.username,
        )
        created_post = create_post(new_post)

        # 작성자를 첫 번째 참가자로 자동 등록
        new_participant = PostParticipant(
            post_id=created_post.post_id,
            user_id=current_user.user_id,
            username=current_user.username,
        )
        create_post_participant(new_participant)

        return {"success": True, "post_id": created_post.post_id}

    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
        )


# 게시물 조회 API
@router.get("/{post_id}")
async def get_post(post_id: int, current_user: User = Depends(get_current_active_user)):
    post = read_post(post_id)
    if not post:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="게시물을 찾을 수 없습니다."
        )

    # 게시물 참가자 조회
    participants = read_post_participants_by_post_id(post_id)

    # 현재 사용자의 참가 여부 확인
    is_participant = any(p.user_id == current_user.user_id for p in participants)

    return {
        "success": True,
        "post": post.dict(),
        "participants": [p.dict() for p in participants],
        "is_participant": is_participant,
        "is_creator": post.creator_id == current_user.user_id,
    }


# 게시물 참가 API
@router.post("/participate")
async def participate_post(
    participant_create: PostParticipantCreate,
    current_user: User = Depends(get_current_active_user),
):
    try:
        post_id = participant_create.post_id

        # 게시물 조회
        post = read_post(post_id)
        if not post:
            return JSONResponse(
                status_code=status.HTTP_404_NOT_FOUND,
                content={"success": False, "message": "게시물을 찾을 수 없습니다."},
            )

        # 이미 참가 중인지 확인
        existing_participant = read_post_participant(post_id, current_user.user_id)
        if existing_participant:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={"success": False, "message": "이미 참가 중인 게시물입니다."},
            )

        # 참가자 수 확인
        participants = read_post_participants_by_post_id(post_id)
        if len(participants) >= post.max_participants:
            return JSONResponse(
                status_code=status.HTTP_400_BAD_REQUEST,
                content={
                    "success": False,
                    "message": "참가자 수가 이미 최대에 도달했습니다.",
                },
            )

        # 참가자 등록
        new_participant = PostParticipant(
            post_id=post_id,
            user_id=current_user.user_id,
            username=current_user.username,
        )
        create_post_participant(new_participant)

        return {"success": True, "message": "게시물에 참가했습니다."}

    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
        )


# 모든 게시물 조회 API
@router.get("/all", response_model=List[dict])
async def get_all_posts(current_user: User = Depends(get_current_active_user)):
    with Session(engine) as session:
        posts = session.query(Post).order_by(Post.created_at.desc()).all()

        result = []
        for post in posts:
            # 게시물 참가자 조회
            participants = read_post_participants_by_post_id(post.post_id)

            # 현재 사용자의 참가 여부 확인
            is_participant = any(
                p.user_id == current_user.user_id for p in participants
            )

            post_data = post.dict()
            post_data["participants"] = [p.dict() for p in participants]
            post_data["is_participant"] = is_participant
            post_data["is_creator"] = post.creator_id == current_user.user_id

            result.append(post_data)

        return result
