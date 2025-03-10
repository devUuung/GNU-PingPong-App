from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from sqlmodel import Session
from sqlalchemy import select
from fastapi.encoders import jsonable_encoder

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

# 새로운 라우터 추가 - 직접적인 /api/v1/recruit 경로 처리용
recruit_router = APIRouter(prefix="/api/v1/recruit", tags=["recruit"])


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


# 모집 공고 API 모델
class RecruitPostData(BaseModel):
    title: str
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    user_id: int  # 작성자 ID


# 모집 공고 목록 조회 - v1 버전
@router.get("/recruit/posts", tags=["recruit"])
async def get_recruit_posts(current_user: User = Depends(get_current_active_user)):
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


# 모집 공고 상세 조회
@router.get("/recruit/post/{post_id}", tags=["recruit"])
async def get_recruit_post(
    post_id: int, current_user: User = Depends(get_current_active_user)
):
    try:
        with Session(engine) as session:
            post = session.exec(select(Post).where(Post.post_id == post_id)).first()

            if not post:
                return JSONResponse(
                    status_code=status.HTTP_404_NOT_FOUND,
                    content={"success": False, "message": "게시물을 찾을 수 없습니다."},
                )

            post_data = post.dict()
            post_data["writer_id"] = post.creator_id
            post_data["title"] = post.title
            post_data["content"] = post.content
            post_data["max_user"] = post.max_participants
            post_data["game_at"] = post.meeting_time
            post_data["game_place"] = post.location if hasattr(post, "location") else ""

            return {"success": True, "post": post_data}

    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
        )


# API v1 경로 - 원래 main.py에 있던 것과 동일한 엔드포인트
@router.get("/v1/recruit/posts", tags=["recruit"])
async def get_recruit_posts_v1():
    # 기존 함수 재사용
    return await get_recruit_posts(
        None
    )  # current_user는 None으로 처리 (권한 체크 무시)


# 클라이언트 요청 경로에 맞추는 GET 엔드포인트
@router.get("/v1/recruit/post/{post_id}", tags=["recruit"])
async def get_recruit_post_v1(post_id: int):
    # 기존 함수 재사용
    return await get_recruit_post(post_id, None)


# 새 recruit_router에 추가하는 엔드포인트들


# 모집 공고 수정 API
@recruit_router.put("/post/{post_id}")
async def update_recruit_post_direct(post_id: int, post_data: RecruitPostData):
    try:
        with Session(engine) as session:
            # 게시물 존재 여부 확인
            post = session.exec(select(Post).where(Post.post_id == post_id)).first()[0]
            

            if not post:
                return JSONResponse(
                    status_code=status.HTTP_404_NOT_FOUND,
                    content={"success": False, "message": "게시물을 찾을 수 없습니다."},
                )

            # user_id와 writer_id 비교하기 전에 디버깅 정보 출력
            print(
                f"요청 user_id: {post_data.user_id}, 게시물 creator_id: {post.writer_id}"
            )

            # 작성자 확인 (작성자만 수정 가능)
            if post.writer_id != post_data.user_id:
                return JSONResponse(
                    status_code=status.HTTP_403_FORBIDDEN,
                    content={
                        "success": False,
                        "message": "게시물 수정 권한이 없습니다.",
                    },
                )

            # 게시물 정보 업데이트
            post.title = post_data.title
            post.content = post_data.content
            post.max_user = post_data.max_user
            post.game_at = post_data.game_at

            # location 필드가 있는지 확인하고 업데이트
            if hasattr(post, "location"):
                post.location = post_data.game_place

            # 변경사항 커밋
            session.add(post)
            session.commit()
            session.refresh(post)

            return {"success": True, "message": "게시물이 성공적으로 수정되었습니다."}

    except Exception as e:
        print(f"게시물 수정 중 오류 발생: {str(e)}")  # 디버깅용 로그
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
        )
