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
)
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel

app = FastAPI()


# 데이터 모델 정의
class GameCreate(BaseModel):
    winner_id: int
    loser_id: int
    plus_score: int
    minus_score: int


class GameUpdate(BaseModel):
    plus_score: Optional[int] = None
    minus_score: Optional[int] = None


class ScoreRankCreate(BaseModel):
    user_id: int
    rank: int
    score: float
    prize: Optional[int] = 0


class ScoreRankUpdate(BaseModel):
    rank: Optional[int] = None
    score: Optional[float] = None
    prize: Optional[int] = None
    game_count: Optional[int] = None
    win_count: Optional[int] = None
    lose_count: Optional[int] = None


class PostCreate(BaseModel):
    writer_id: int
    game_at: datetime
    game_place: str
    max_user: int
    content: str
    title: str


class PostUpdate(BaseModel):
    game_at: Optional[datetime] = None
    game_place: Optional[str] = None
    max_user: Optional[int] = None
    content: Optional[str] = None
    title: Optional[str] = None


class UserCreate(BaseModel):
    username: str
    phone_number: str
    password: str
    student_id: int


class UserUpdate(BaseModel):
    username: Optional[str] = None
    phone_number: Optional[str] = None
    password: Optional[str] = None
    student_id: Optional[int] = None


@app.get("/")
def read_root():
    return {"Hello": "World?"}


# User 관련 엔드포인트
@app.post("/users/")
def create_user_endpoint(user: UserCreate):
    try:
        created_user = create_user(
            username=user.username,
            phone_number=user.phone_number,
            password=user.password,
            student_id=user.student_id,
        )
        return created_user
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/users/{user_id}")
def read_user_endpoint(user_id: int):
    try:
        user = read_user_by_user_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.put("/users/{user_id}")
def update_user_endpoint(user_id: int, user_update: UserUpdate):
    try:
        updated_user = update_user(
            user_id=user_id,
            username=user_update.username,
            phone_number=user_update.phone_number,
            password=user_update.password,
            student_id=user_update.student_id,
        )
        return updated_user
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/users/{user_id}")
def delete_user_endpoint(user_id: int):
    try:
        return delete_user(user_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# Game 관련 엔드포인트
@app.post("/games/")
def create_game_endpoint(game: GameCreate):
    try:
        created_game = create_game(
            winner_id=game.winner_id,
            loser_id=game.loser_id,
            plus_score=game.plus_score,
            minus_score=game.minus_score,
        )
        return created_game
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/games/{game_id}")
def read_game_endpoint(game_id: int):
    try:
        return read_game(game_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/games/user/{user_id}")
def read_user_games(user_id: int):
    try:
        return read_games_by_user_id(user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.put("/games/{game_id}")
def update_game_endpoint(game_id: int, game_update: GameUpdate):
    try:
        return update_game(
            game_id=game_id,
            plus_score=game_update.plus_score,
            minus_score=game_update.minus_score,
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/games/{game_id}")
def delete_game_endpoint(game_id: int):
    try:
        return delete_game(game_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# ScoreRank 관련 엔드포인트
@app.post("/score-ranks/")
def create_score_rank_endpoint(score_rank: ScoreRankCreate):
    try:
        return create_score_rank(
            user_id=score_rank.user_id,
            rank=score_rank.rank,
            score=score_rank.score,
            prize=score_rank.prize,
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/score-ranks/{rank_id}")
def read_score_rank_endpoint(rank_id: int):
    try:
        return read_score_rank(rank_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/score-ranks/user/{user_id}")
def read_user_score_rank(user_id: int):
    try:
        return read_score_rank_by_user_id(user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.put("/score-ranks/{rank_id}")
def update_score_rank_endpoint(rank_id: int, score_rank_update: ScoreRankUpdate):
    try:
        return update_score_rank(
            rank_id=rank_id,
            rank=score_rank_update.rank,
            score=score_rank_update.score,
            prize=score_rank_update.prize,
            game_count=score_rank_update.game_count,
            win_count=score_rank_update.win_count,
            lose_count=score_rank_update.lose_count,
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/score-ranks/{rank_id}")
def delete_score_rank_endpoint(rank_id: int):
    try:
        return delete_score_rank(rank_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# Post 관련 엔드포인트
@app.post("/posts/")
def create_post_endpoint(post: PostCreate):
    try:
        return create_post(
            writer_id=post.writer_id,
            game_at=post.game_at,
            game_place=post.game_place,
            max_user=post.max_user,
            content=post.content,
            title=post.title,
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/posts/{post_id}")
def read_post_endpoint(post_id: int):
    try:
        return read_post(post_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/posts/writer/{writer_id}")
def read_writer_posts(writer_id: int):
    try:
        return read_posts_by_writer_id(writer_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.put("/posts/{post_id}")
def update_post_endpoint(post_id: int, post_update: PostUpdate):
    try:
        return update_post(
            post_id=post_id,
            game_at=post_update.game_at,
            game_place=post_update.game_place,
            max_user=post_update.max_user,
            content=post_update.content,
            title=post_update.title,
        )
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/posts/{post_id}")
def delete_post_endpoint(post_id: int):
    try:
        return delete_post(post_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


# PostParticipant 관련 엔드포인트
@app.post("/post-participants/")
def create_post_participant_endpoint(post_id: int, user_id: int):
    try:
        return create_post_participant(post_id=post_id, user_id=user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/post-participants/{post_id}/{user_id}")
def read_post_participant_endpoint(post_id: int, user_id: int):
    try:
        return read_post_participant(post_id=post_id, user_id=user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/post-participants/post/{post_id}")
def read_post_participants(post_id: int):
    try:
        return read_post_participants_by_post_id(post_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/post-participants/user/{user_id}")
def read_user_participations(user_id: int):
    try:
        return read_post_participants_by_user_id(user_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/post-participants/{post_id}/{user_id}")
def delete_post_participant_endpoint(post_id: int, user_id: int):
    try:
        return delete_post_participant(post_id=post_id, user_id=user_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
