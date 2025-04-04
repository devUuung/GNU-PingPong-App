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
    password: str = Field(max_length=200)
    created_at: datetime = Field(default=datetime.now())
    student_id: int = Field(unique=True)
    department: str = Field(default="")

    score: float = Field(default=0)
    total_prize: int = Field(default=0)
    game_count: int = Field(default=0)
    win_count: int = Field(default=0)
    lose_count: int = Field(default=0)

    rank: int = Field(default=0)
    initial_score: float = Field(default=0)
    point: int = Field(default=0)
    custom_point: int = Field(default=0)
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


# 경기 입력 요청을 저장하는 모델
class MatchRequest(SQLModel, table=True, tablename="match_request"):
    request_id: int = Field(primary_key=True, default=None)
    user_id: int = Field(foreign_key="user.user_id")
    created_at: datetime = Field(default=datetime.now())


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
    department: str,
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
            department=department,
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
        # user가 int인 경우(user_id)와 User 객체인 경우를 모두 처리
        if isinstance(user, int):
            user_obj = session.get(User, user)
        else:
            user_obj = session.get(User, user.user_id)

        for field, value in updated_fields.items():
            setattr(user_obj, field, value)
        session.commit()
        session.refresh(user_obj)
        return user_obj


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

        # 게시물 저장하고 ID 생성
        session.add(post)
        session.commit()
        session.refresh(post)

        # post 객체의 복사본을 생성하여 세션과의 관계를 끊음
        post_data = {
            "post_id": post.post_id,
            "writer_id": post.writer_id,
            "game_at": post.game_at,
            "game_place": post.game_place,
            "max_user": post.max_user,
            "content": post.content,
            "title": post.title,
            "created_at": post.created_at,
        }

        # 딕셔너리로 변환된 post 데이터 반환
        return Post(**post_data)


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
        statement = select(PostParticipant).where(
            PostParticipant.post_id == post_id, PostParticipant.user_id == user_id
        )
        post_participant = session.exec(statement).first()
        if post_participant:
            session.delete(post_participant)
            session.commit()
        return {"message": "참가자가 삭제되었습니다."}


# 경기 입력 요청 생성
def create_match_request(user_id: int):
    with Session(engine) as session:
        # 기존 활성화된 요청이 있는지 확인
        statement = select(MatchRequest).where(MatchRequest.user_id == user_id)
        existing_request = session.exec(statement).first()

        # 이미 요청이 있으면 기존 요청 반환
        if existing_request:
            return existing_request

        # 새 요청 생성
        match_request = MatchRequest(user_id=user_id)
        session.add(match_request)
        session.commit()
        session.refresh(match_request)
        return match_request


# 경기 입력 요청 조회
def read_match_request(request_id: int):
    with Session(engine) as session:
        statement = select(MatchRequest).where(MatchRequest.request_id == request_id)
        return session.exec(statement).first()


# 사용자ID로 경기 입력 요청 조회
def read_match_request_by_user_id(user_id: int):
    with Session(engine) as session:
        statement = select(MatchRequest).where(MatchRequest.user_id == user_id)
        return session.exec(statement).first()


# 모든 활성화된 경기 입력 요청 조회
def read_all_active_match_requests():
    with Session(engine) as session:
        statement = select(MatchRequest)
        return session.exec(statement).all()


# 경기 입력 요청 비활성화
def deactivate_match_request(request_id: int):
    with Session(engine) as session:
        match_request = read_match_request(request_id)
        if match_request:
            session.delete(match_request)
            session.commit()
            return True
        return False


# 사용자ID로 경기 입력 요청 비활성화
def delete_match_request_by_user_id(user_id: int):
    with Session(engine) as session:
        statement = select(MatchRequest).where(MatchRequest.user_id == user_id)
        match_request = session.exec(statement).first()
        if match_request:
            session.delete(match_request)
            session.commit()
            return True
        return False
