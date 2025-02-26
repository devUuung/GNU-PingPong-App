# from typing import Optional

from datetime import datetime
from sqlmodel import Field, SQLModel, create_engine, Session, select
import os
import time
from sqlalchemy.exc import OperationalError

from fastapi import HTTPException
from typing import Optional
from pydantic import BaseModel


class User(SQLModel, table=True, tablename="user"):
    user_id: Optional[int] = Field(default=None, primary_key=True)
    username: str
    phone_number: str = Field(unique=True)
    password: str
    created_at: datetime = Field(default=datetime.now())
    student_id: int = Field(unique=True)

    score: float = Field(default=0)
    total_prize: int = Field(default=0)
    game_count: int = Field(default=0)
    win_count: int = Field(default=0)
    lose_count: int = Field(default=0)
    initial_score: float = Field(default=0)
    point: int = Field(default=0)
    is_admin: bool = Field(default=False)
    profile_image: Optional[str] = Field(default=None)
    status_message: Optional[str] = Field(default="안녕하세요!")
    device_id: Optional[str] = Field(default=None)


class Game(SQLModel, table=True, tablename="game"):
    game_id: int = Field(primary_key=True)
    winner_id: int = Field(foreign_key="user.user_id")
    loser_id: int = Field(foreign_key="user.user_id")
    winner_name: str = Field(nullable=False)
    loser_name: str = Field(nullable=False)
    plus_score: int = Field(default=0)
    minus_score: int = Field(default=0)
    created_at: datetime = Field(default=datetime.now())


class ScoreRank(SQLModel, table=True, tablename="score_rank"):
    rank_id: int = Field(primary_key=True)
    user_id: int = Field(foreign_key="user.user_id")
    rank: int = Field(default=0)
    score: float = Field(default=0)
    updated_at: datetime = Field(default=datetime.now())
    prize: int = Field(default=0)
    game_count: int = Field(default=0)
    win_count: int = Field(default=0)
    lose_count: int = Field(default=0)


class Post(SQLModel, table=True, tablename="post"):
    post_id: int = Field(primary_key=True)
    writer_id: int = Field(foreign_key="user.user_id")
    created_at: datetime = Field(default=datetime.now())
    game_at: datetime = Field(nullable=False)
    game_place: str = Field(nullable=False)
    max_user: int = Field(nullable=False)
    content: str = Field(nullable=False)
    title: str = Field(nullable=False)


class PostParticipant(SQLModel, table=True, tablename="post_participant"):
    post_id: int = Field(foreign_key="post.post_id", primary_key=True)
    user_id: int = Field(foreign_key="user.user_id", primary_key=True)


# 데이터베이스 엔진 생성 (여기서는 SQLite 메모리 데이터베이스 사용)
engine = create_engine(os.getenv("CONN_URL"))


def create_db_and_tables(retries: int = 10, delay: int = 2):
    """데이터베이스 연결에 실패할 경우 재시도하여 테이블을 생성합니다."""
    attempt = 0
    while attempt < retries:
        try:
            SQLModel.metadata.create_all(engine)
            print("DB 연결 성공 및 테이블 생성 완료.")
            return
        except OperationalError as e:
            attempt += 1
            print(f"DB 연결 실패, 재시도 {attempt}/{retries} (2초 후 재시도)...", e)
            time.sleep(delay)
    raise Exception("여러 번 재시도 후에도 DB 연결에 실패했습니다.")


# DB 연결 재시도 후 테이블 생성
create_db_and_tables()


def create_user(
    username: str,
    phone_number: str,
    password: str,
    student_id: int,
    device_id: Optional[str] = None,
    status_message: Optional[str] = "안녕하세요!",
    profile_image: Optional[str] = None,
):
    with Session(engine) as session:
        user = User(
            username=username,
            phone_number=phone_number,
            password=password,
            student_id=student_id,
            device_id=device_id,
            status_message=status_message,
            profile_image=profile_image,
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        return user


def read_users_by_all():
    with Session(engine) as session:
        users = session.exec(select(User)).all()
        return users


def read_user_by_user_id(user_id: int):
    with Session(engine) as session:
        user = session.get(User, user_id)
        return user


def read_user_by_phone_number(phone_number: str):
    with Session(engine) as session:
        user = session.exec(
            select(User).where(User.phone_number == phone_number)
        ).first()
        return user


# 학번으로 사람 찾기
def read_user_by_student_id(student_id: int):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.student_id == student_id)).first()
        return user


def update_user(user, updated_fields: dict):
    with Session(engine) as session:
        # user 전체 대신 user.user_id를 식별자로 사용합니다.
        user = session.get(User, user.user_id)
        for field, value in updated_fields.items():
            setattr(user, field, value)
        session.commit()
        session.refresh(user)
        return user


def delete_user(user_id: int):
    with Session(engine) as session:
        user = session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        session.delete(user)
        session.commit()
        return {"detail": "User deleted successfully"}


def create_post(
    writer_id: int,
    game_at: datetime,
    game_place: str,
    max_user: int,
    content: str,
    title: str,
):
    with Session(engine) as session:
        post = Post(
            writer_id=writer_id,
            game_at=game_at,
            game_place=game_place,
            max_user=max_user,
            content=content,
            title=title,
        )

        # 먼저 post를 저장하여 post_id를 생성합니다
        session.add(post)
        session.commit()
        session.refresh(post)

        # post_id가 생성된 후에 post_participant를 생성합니다
        post_participant = PostParticipant(
            post_id=post.post_id,
            user_id=writer_id,
        )

        session.add(post_participant)
        session.commit()
        session.refresh(post_participant)

        return post


# Game CRUD 함수들
def create_game(
    winner_id: int,
    loser_id: int,
    plus_score: int,
    minus_score: int,
    winner_name: str,
    loser_name: str,
):
    with Session(engine) as session:
        game = Game(
            winner_id=winner_id,
            loser_id=loser_id,
            plus_score=plus_score,
            minus_score=minus_score,
            winner_name=winner_name,
            loser_name=loser_name,
        )
        session.add(game)
        session.commit()
        session.refresh(game)
        return game


def read_game(game_id: int):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")
        return game


def read_games_by_user_id(user_id: int):
    with Session(engine) as session:
        games = session.exec(
            select(Game).where((Game.winner_id == user_id) | (Game.loser_id == user_id))
        ).all()
        return games


def read_games_by_all():
    with Session(engine) as session:
        games = session.exec(select(Game)).all()
        return games


def update_game(game_id: int, plus_score: int = None, minus_score: int = None):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")

        if plus_score is not None:
            game.plus_score = plus_score
        if minus_score is not None:
            game.minus_score = minus_score

        session.commit()
        session.refresh(game)
        return game


def delete_game(game_id: int):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if not game:
            raise HTTPException(status_code=404, detail="Game not found")
        session.delete(game)
        session.commit()
        return {"detail": "Game deleted successfully"}


# ScoreRank CRUD 함수들
def create_score_rank(user_id: int, rank: int, score: float, prize: int = 0):
    with Session(engine) as session:
        score_rank = ScoreRank(user_id=user_id, rank=rank, score=score, prize=prize)
        session.add(score_rank)
        session.commit()
        session.refresh(score_rank)
        return score_rank


def read_score_rank(rank_id: int):
    with Session(engine) as session:
        score_rank = session.get(ScoreRank, rank_id)
        if not score_rank:
            raise HTTPException(status_code=404, detail="Score rank not found")
        return score_rank


def read_score_rank_by_user_id(user_id: int):
    with Session(engine) as session:
        score_rank = session.exec(
            select(ScoreRank).where(ScoreRank.user_id == user_id)
        ).first()
        return score_rank


def update_score_rank(
    rank_id: int,
    rank: int = None,
    score: float = None,
    prize: int = None,
    game_count: int = None,
    win_count: int = None,
    lose_count: int = None,
):
    with Session(engine) as session:
        score_rank = session.get(ScoreRank, rank_id)
        if not score_rank:
            raise HTTPException(status_code=404, detail="Score rank not found")

        if rank is not None:
            score_rank.rank = rank
        if score is not None:
            score_rank.score = score
        if prize is not None:
            score_rank.prize = prize
        if game_count is not None:
            score_rank.game_count = game_count
        if win_count is not None:
            score_rank.win_count = win_count
        if lose_count is not None:
            score_rank.lose_count = lose_count

        score_rank.updated_at = datetime.now()
        session.commit()
        session.refresh(score_rank)
        return score_rank


def delete_score_rank(rank_id: int):
    with Session(engine) as session:
        score_rank = session.get(ScoreRank, rank_id)
        if not score_rank:
            raise HTTPException(status_code=404, detail="Score rank not found")
        session.delete(score_rank)
        session.commit()
        return {"detail": "Score rank deleted successfully"}


# Post 추가 함수들
def read_post(post_id: int):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        return post


def read_posts_by_writer_id(writer_id: int):
    with Session(engine) as session:
        posts = session.exec(select(Post).where(Post.writer_id == writer_id)).all()
        return posts


def update_post(
    post_id: int,
    game_at: datetime = None,
    game_place: str = None,
    max_user: int = None,
    content: str = None,
    title: str = None,
):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")

        if game_at is not None:
            post.game_at = game_at
        if game_place is not None:
            post.game_place = game_place
        if max_user is not None:
            post.max_user = max_user
        if content is not None:
            post.content = content
        if title is not None:
            post.title = title

        session.commit()
        session.refresh(post)
        return post


def delete_post(post_id: int):
    with Session(engine) as session:
        post = session.get(Post, post_id)
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        session.delete(post)
        session.commit()
        return {"detail": "Post deleted successfully"}


# PostParticipant CRUD 함수들
def create_post_participant(post_id: int, user_id: int):
    with Session(engine) as session:
        post_participant = PostParticipant(post_id=post_id, user_id=user_id)
        session.add(post_participant)
        session.commit()
        session.refresh(post_participant)
        return post_participant


def read_post_participant(post_id: int, user_id: int):
    with Session(engine) as session:
        post_participant = session.exec(
            select(PostParticipant).where(
                (PostParticipant.post_id == post_id)
                & (PostParticipant.user_id == user_id)
            )
        ).first()
        return post_participant


def read_post_participants_by_post_id(post_id: int):
    with Session(engine) as session:
        participants = session.exec(
            select(PostParticipant).where(PostParticipant.post_id == post_id)
        ).all()
        return participants


def read_post_participants_by_user_id(user_id: int):
    with Session(engine) as session:
        participations = session.exec(
            select(PostParticipant).where(PostParticipant.user_id == user_id)
        ).all()
        return participations


def delete_post_participant(post_id: int, user_id: int):
    with Session(engine) as session:
        post_participant = session.exec(
            select(PostParticipant).where(
                (PostParticipant.post_id == post_id)
                & (PostParticipant.user_id == user_id)
            )
        ).first()
        if not post_participant:
            raise HTTPException(status_code=404, detail="Post participant not found")
        session.delete(post_participant)
        session.commit()
        return {"detail": "Post participant deleted successfully"}
