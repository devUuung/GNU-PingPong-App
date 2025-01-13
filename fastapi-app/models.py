# from typing import Optional

from datetime import datetime
from sqlmodel import Field, SQLModel, create_engine, Session, select
import os


class User(SQLModel, table=True, tablename="user"):
    user_id: int = Field(primary_key=True)
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


class Game(SQLModel, table=True, tablename="game"):
    game_id: int = Field(primary_key=True)
    winner_id: int = Field(foreign_key="user.user_id")
    loser_id: int = Field(foreign_key="user.user_id")
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

# 데이터베이스 테이블 생성
SQLModel.metadata.create_all(engine)


def create_user(
    user_id: int,
    username: str,
    phone_number: str,
    password: str,
    student_id: int,
):
    with Session(engine) as session:
        user = User(
            user_id=user_id,
            username=username,
            phone_number=phone_number,
            password=password,
            student_id=student_id,
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        return user


def read_user_by_user_id(user_id: int):
    with Session(engine) as session:
        user = session.get(User, user_id)
        return user


# 학번으로 사람 찾기
def read_user_by_student_id(student_id: int):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.student_id == student_id)).first()
        return user


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
        post_participant = PostParticipant(
            post_id=post.post_id,
            user_id=writer_id,
        )

        session.add(post)
        session.add(post_participant)
        session.commit()
        session.refresh(post)
        session.refresh(post_participant)
        return post
