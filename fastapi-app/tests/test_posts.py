from fastapi.testclient import TestClient
from sqlmodel import Session
from models import User
from datetime import datetime, timedelta


def test_create_post(client: TestClient, test_user: User):
    game_time = datetime.now() + timedelta(days=1)
    post_data = {
        "writer_id": test_user.user_id,
        "game_at": game_time.isoformat(),
        "game_place": "체육관",
        "max_user": 4,
        "content": "탁구 한 판 하실 분~",
        "title": "탁구 같이 치실 분 구합니다",
    }
    response = client.post("/posts/", json=post_data)
    assert response.status_code == 200
    data = response.json()
    assert data["writer_id"] == post_data["writer_id"]
    assert data["game_place"] == post_data["game_place"]
    assert data["max_user"] == post_data["max_user"]
    assert data["content"] == post_data["content"]
    assert data["title"] == post_data["title"]


def test_read_post(client: TestClient, test_user: User):
    # Create a post first
    game_time = datetime.now() + timedelta(days=1)
    post_data = {
        "writer_id": test_user.user_id,
        "game_at": game_time.isoformat(),
        "game_place": "학생회관",
        "max_user": 2,
        "content": "초보자도 환영합니다",
        "title": "점심시간 탁구",
    }
    create_response = client.post("/posts/", json=post_data)
    post_id = create_response.json()["post_id"]

    # Test reading the post
    response = client.get(f"/posts/{post_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["writer_id"] == post_data["writer_id"]
    assert data["game_place"] == post_data["game_place"]
    assert data["title"] == post_data["title"]


def test_read_writer_posts(client: TestClient, test_user: User):
    response = client.get(f"/posts/writer/{test_user.user_id}")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_update_post(client: TestClient, test_user: User):
    # Create a post first
    game_time = datetime.now() + timedelta(days=1)
    post_data = {
        "writer_id": test_user.user_id,
        "game_at": game_time.isoformat(),
        "game_place": "도서관",
        "max_user": 3,
        "content": "실력자만 오세요",
        "title": "저녁 탁구",
    }
    create_response = client.post("/posts/", json=post_data)
    post_id = create_response.json()["post_id"]

    # Test updating the post
    new_game_time = datetime.now() + timedelta(days=2)
    update_data = {
        "game_at": new_game_time.isoformat(),
        "game_place": "신체육관",
        "max_user": 4,
        "content": "누구나 환영",
        "title": "수정된 제목",
    }
    response = client.put(f"/posts/{post_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["game_place"] == update_data["game_place"]
    assert data["max_user"] == update_data["max_user"]
    assert data["content"] == update_data["content"]
    assert data["title"] == update_data["title"]


def test_delete_post(client: TestClient, test_user: User):
    # Create a post first
    game_time = datetime.now() + timedelta(days=1)
    post_data = {
        "writer_id": test_user.user_id,
        "game_at": game_time.isoformat(),
        "game_place": "강당",
        "max_user": 2,
        "content": "삭제될 게시물",
        "title": "삭제 테스트",
    }
    create_response = client.post("/posts/", json=post_data)
    post_id = create_response.json()["post_id"]

    # Test deleting the post
    response = client.delete(f"/posts/{post_id}")
    assert response.status_code == 200
    assert response.json()["detail"] == "Post deleted successfully"

    # Verify post is deleted
    response = client.get(f"/posts/{post_id}")
    assert response.status_code == 404


def test_create_post_participant(client: TestClient, test_user: User):
    # Create a post first
    game_time = datetime.now() + timedelta(days=1)
    post_data = {
        "writer_id": test_user.user_id,
        "game_at": game_time.isoformat(),
        "game_place": "강당",
        "max_user": 2,
        "content": "참가자 테스트",
        "title": "참가 테스트",
    }
    create_response = client.post("/posts/", json=post_data)
    post_id = create_response.json()["post_id"]

    # Test creating a participant
    response = client.post(
        "/post-participants/", params={"post_id": post_id, "user_id": test_user.user_id}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["post_id"] == post_id
    assert data["user_id"] == test_user.user_id


def test_read_post_participants(client: TestClient, test_user: User):
    # Create a post first
    game_time = datetime.now() + timedelta(days=1)
    post_data = {
        "writer_id": test_user.user_id,
        "game_at": game_time.isoformat(),
        "game_place": "강당",
        "max_user": 2,
        "content": "참가자 조회 테스트",
        "title": "참가자 목록 테스트",
    }
    create_response = client.post("/posts/", json=post_data)
    post_id = create_response.json()["post_id"]

    # Test reading participants
    response = client.get(f"/post-participants/post/{post_id}")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
