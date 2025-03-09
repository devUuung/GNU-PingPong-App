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


def calculate_k_factor(rating: float, streak: int) -> float:
    """
    레이팅과 연승 기록에 따라 K-팩터를 동적으로 계산합니다.
    - rating이 800 미만이면 40,
    - 800 ~ 1800 구간에서는 40에서 선형적으로 16까지 감소,
    - 1800 이상이면 16.
    또한, 연승이 2연승 이상이면 K-팩터에 보정을 적용합니다.
    """
    if rating < 800:
        base_k = 40
    elif rating <= 1800:
        base_k = 40 - (24 * (rating - 800) / 1000)
    else:
        base_k = 16

    # 연승 보정: 2연승이면 +1, 3연승 이상이면 +3
    if streak >= 2 and streak < 3:
        base_k += 1
    elif streak >= 3:
        base_k += 3

    return base_k


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

        # winner의 K 팩터 계산
        winner_k = calculate_k_factor(winner.score, winner.point)
        loser_k = calculate_k_factor(loser.score, loser.point)

        # 예상 승률 계산
        expected_winner = 1 / (1 + 10 ** ((loser.score - winner.score) / 400))
        expected_loser = 1 / (1 + 10 ** ((winner.score - loser.score) / 400))

        # 점수 계산
        plus_score = round(winner_k * (1 - expected_winner))
        minus_score = round(loser_k * (0 - expected_loser))

        # 승자 정보 업데이트
        winner.score += plus_score
        winner.game_count += 1
        winner.win_count += 1
        winner.point += 1
        update_user(
            winner,
            {
                "score": winner.score,
                "game_count": winner.game_count,
                "win_count": winner.win_count,
                "point": winner.point,
            },
        )

        # 패자 정보 업데이트
        loser.score += minus_score
        loser.game_count += 1
        loser.lose_count += 1
        loser.point = 0
        update_user(
            loser,
            {
                "score": loser.score,
                "game_count": loser.game_count,
                "lose_count": loser.lose_count,
                "point": loser.point,
            },
        )

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
