from fastapi import APIRouter, Depends, HTTPException, Header, Body, Query
from typing import List, Optional
from datetime import datetime, timedelta
from sqlmodel import Session, select
from jose import jwt
from core.config import settings
from models import (
    User,
    Game,
    Post,
    PostParticipant,
    ScoreRank,
    engine,
    read_users_by_all,
    read_games_by_all,
    read_post,
    read_post_participants_by_post_id,
    update_user,
    delete_user,
    delete_post,
    delete_game,
)

router = APIRouter(
    prefix="/admin",
    tags=["admin"],
    responses={404: {"description": "찾을 수 없음"}},
)


# JWT 토큰 검증 및 관리자 권한 확인 함수
def verify_admin_token(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="인증 토큰이 제공되지 않았습니다.")

    try:
        token = authorization.replace("Bearer ", "")
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id = payload.get("sub")

        if not user_id:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")

        with Session(engine) as session:
            user = session.get(User, int(user_id))
            if not user or not user.is_admin:
                raise HTTPException(status_code=403, detail="관리자 권한이 없습니다.")

        return int(user_id)
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다.")


# 모든 사용자 정보 조회
@router.get("/users")
def get_all_users(admin_id: int = Depends(verify_admin_token)):
    users = read_users_by_all()
    return {"users": users}


# 사용자 정보 수정 (관리자 권한)
@router.put("/users/{user_id}")
def update_user_info(
    user_id: int,
    user_data: dict = Body(...),
    admin_id: int = Depends(verify_admin_token),
):
    try:
        updated_user = update_user(user_id, user_data)
        return {"message": "사용자 정보가 업데이트되었습니다.", "user": updated_user}
    except Exception as e:
        raise HTTPException(
            status_code=400, detail=f"사용자 정보 업데이트 실패: {str(e)}"
        )


# 사용자 삭제
@router.delete("/users/{user_id}")
def remove_user(user_id: int, admin_id: int = Depends(verify_admin_token)):
    try:
        delete_user(user_id)
        return {"message": "사용자가 성공적으로 삭제되었습니다."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"사용자 삭제 실패: {str(e)}")


# 모든 게임 정보 조회
@router.get("/games")
def get_all_games(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    admin_id: int = Depends(verify_admin_token),
):
    games = read_games_by_all()

    # 날짜 필터링
    if start_date or end_date:
        filtered_games = []
        for game in games:
            if start_date and game.created_at < start_date:
                continue
            if end_date and game.created_at > end_date:
                continue
            filtered_games.append(game)
        games = filtered_games

    return {"games": games}


# 게임 삭제
@router.delete("/games/{game_id}")
def remove_game(game_id: int, admin_id: int = Depends(verify_admin_token)):
    try:
        delete_game(game_id)
        return {"message": "게임이 성공적으로 삭제되었습니다."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"게임 삭제 실패: {str(e)}")


# 모든 게시물 조회
@router.get("/posts")
def get_all_posts(admin_id: int = Depends(verify_admin_token)):
    with Session(engine) as session:
        posts = session.exec(select(Post)).all()
        return {"posts": posts}


# 게시물 및 참가자 상세 조회
@router.get("/posts/{post_id}")
def get_post_detail(post_id: int, admin_id: int = Depends(verify_admin_token)):
    post = read_post(post_id)
    if not post:
        raise HTTPException(status_code=404, detail="게시물을 찾을 수 없습니다.")

    participants = read_post_participants_by_post_id(post_id)

    return {"post": post, "participants": participants}


# 게시물 삭제
@router.delete("/posts/{post_id}")
def remove_post(post_id: int, admin_id: int = Depends(verify_admin_token)):
    try:
        delete_post(post_id)
        return {"message": "게시물이 성공적으로 삭제되었습니다."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"게시물 삭제 실패: {str(e)}")


# 대시보드 통계 정보
@router.get("/dashboard")
def get_dashboard_stats(admin_id: int = Depends(verify_admin_token)):
    with Session(engine) as session:
        total_users = session.exec(select(User)).count()
        total_games = session.exec(select(Game)).count()
        total_posts = session.exec(select(Post)).count()

        # 최근 가입자 (최근 7일)
        one_week_ago = datetime.now() - timedelta(days=7)
        new_users = session.exec(
            select(User).where(User.created_at >= one_week_ago)
        ).count()

        # 최근 게임 (최근 7일)
        recent_games = session.exec(
            select(Game).where(Game.created_at >= one_week_ago)
        ).count()

        # 상위 랭킹 사용자
        top_users = session.exec(
            select(User).order_by(User.score.desc()).limit(5)
        ).all()

        return {
            "total_users": total_users,
            "total_games": total_games,
            "total_posts": total_posts,
            "new_users_last_week": new_users,
            "games_last_week": recent_games,
            "top_users": top_users,
        }


# 관리자 권한 부여
@router.put("/promote/{user_id}")
def promote_to_admin(user_id: int, admin_id: int = Depends(verify_admin_token)):
    try:
        updated_user = update_user(user_id, {"is_admin": True})
        return {
            "message": f"{updated_user.username}님이 관리자로 승격되었습니다.",
            "user": updated_user,
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"관리자 승격 실패: {str(e)}")


# 관리자 권한 해제
@router.put("/demote/{user_id}")
def demote_from_admin(user_id: int, admin_id: int = Depends(verify_admin_token)):
    # 자기 자신의 관리자 권한은 해제할 수 없음
    if user_id == admin_id:
        raise HTTPException(
            status_code=400, detail="자신의 관리자 권한은 해제할 수 없습니다."
        )

    try:
        updated_user = update_user(user_id, {"is_admin": False})
        return {
            "message": f"{updated_user.username}님의 관리자 권한이 해제되었습니다.",
            "user": updated_user,
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"관리자 권한 해제 실패: {str(e)}")
