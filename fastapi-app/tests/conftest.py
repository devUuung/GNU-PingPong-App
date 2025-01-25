import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
import os
from main import app
from models import User


@pytest.fixture(name="session")
def session_fixture():
    # 테스트용 데이터베이스 URL 설정
    TEST_DATABASE_URL = os.getenv(
        "TEST_DATABASE_URL",
        "postgresql://postgres:postgres@localhost:5432/pingpong_test",
    )

    engine = create_engine(TEST_DATABASE_URL)

    # 테스트용 데이터베이스 테이블 생성
    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        yield session

    # 테스트 후 데이터베이스 정리
    SQLModel.metadata.drop_all(engine)


@pytest.fixture(name="client")
def client_fixture(session: Session):
    def get_session_override():
        return session

    app.dependency_overrides = {}
    client = TestClient(app)
    return client


@pytest.fixture(name="test_user")
def test_user_fixture(session: Session):
    user = User(
        username="테스트유저",
        phone_number="010-1234-5678",
        password="testpassword",
        student_id=20240001,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user
