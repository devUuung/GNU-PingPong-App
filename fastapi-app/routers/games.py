from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from typing import List, Optional
from pydantic import BaseModel
from sqlmodel import Session

from core.config import settings
from core.auth import get_current_active_user
from core.utils import prepare_user_response
from models import (
    User,
    Game,
    create_game,
    read_games_by_all,
    read_user_by_user_id,
    update_user,
    engine,
)

router = APIRouter(prefix=f"{settings.API_V1_STR}/games", tags=["games"])


# 게임 생성 모델
class GameCreate(BaseModel):
    winner_id: int
    loser_id: int


# 모든 게임 조회 API
@router.get("/all", response_model=List[dict])
async def get_all_games(current_user: User = Depends(get_current_active_user)):
    games = read_games_by_all()
    return [game.dict() for game in games]


# 게임 생성 API
@router.post("/create", status_code=status.HTTP_201_CREATED)
async def create_new_game(
    game_create: GameCreate, current_user: User = Depends(get_current_active_user)
):
    try:
        # 승자와 패자 정보 조회
        winner = read_user_by_user_id(game_create.winner_id)
        loser = read_user_by_user_id(game_create.loser_id)

        if not winner or not loser:
            return JSONResponse(
                status_code=status.HTTP_404_NOT_FOUND,
                content={"success": False, "message": "사용자를 찾을 수 없습니다."},
            )

        # 점수 계산 (예: ELO 레이팅 시스템)
        K = 32  # K 팩터 (점수 변동 폭)
        expected_winner = 1 / (1 + 10 ** ((loser.score - winner.score) / 400))
        expected_loser = 1 / (1 + 10 ** ((winner.score - loser.score) / 400))

        plus_score = round(K * (1 - expected_winner))
        minus_score = round(K * (0 - expected_loser))

        # 승자 정보 업데이트
        winner.score += plus_score
        winner.game_count += 1
        winner.win_count += 1
        winner.point += 3  # 승리 시 3포인트 추가
        update_user(winner)

        # 패자 정보 업데이트
        loser.score += minus_score
        loser.game_count += 1
        loser.lose_count += 1
        loser.point += 1  # 패배 시 1포인트 추가
        update_user(loser)

        # 게임 정보 저장
        new_game = Game(
            winner_id=winner.user_id,
            loser_id=loser.user_id,
            winner_name=winner.username,
            loser_name=loser.username,
            plus_score=plus_score,
            minus_score=minus_score,
        )
        created_game = create_game(new_game)

        return {
            "success": True,
            "game": created_game.dict(),
            "winner": prepare_user_response(winner),
            "loser": prepare_user_response(loser),
        }

    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"success": False, "message": f"서버 오류: {str(e)}"},
        )
