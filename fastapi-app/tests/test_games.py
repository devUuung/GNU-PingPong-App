from fastapi.testclient import TestClient
from sqlmodel import Session
from models import User


def test_create_game(client: TestClient, test_user: User, session: Session):
    # Create another user for the game
    opponent = User(
        username="상대방",
        phone_number="010-9999-9999",
        password="testpass",
        student_id=20240003,
    )
    session.add(opponent)
    session.commit()
    session.refresh(opponent)

    game_data = {
        "winner_id": test_user.user_id,
        "loser_id": opponent.user_id,
        "plus_score": 10,
        "minus_score": 5,
    }
    response = client.post("/games/", json=game_data)
    assert response.status_code == 200
    data = response.json()
    assert data["winner_id"] == game_data["winner_id"]
    assert data["loser_id"] == game_data["loser_id"]
    assert data["plus_score"] == game_data["plus_score"]
    assert data["minus_score"] == game_data["minus_score"]


def test_read_game(client: TestClient, test_user: User, session: Session):
    # Create a game first
    opponent = User(
        username="상대방2",
        phone_number="010-8888-8888",
        password="testpass",
        student_id=20240004,
    )
    session.add(opponent)
    session.commit()
    session.refresh(opponent)

    game_data = {
        "winner_id": test_user.user_id,
        "loser_id": opponent.user_id,
        "plus_score": 15,
        "minus_score": 7,
    }
    create_response = client.post("/games/", json=game_data)
    game_id = create_response.json()["game_id"]

    # Test reading the game
    response = client.get(f"/games/{game_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["winner_id"] == game_data["winner_id"]
    assert data["loser_id"] == game_data["loser_id"]


def test_read_user_games(client: TestClient, test_user: User):
    response = client.get(f"/games/user/{test_user.user_id}")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_update_game(client: TestClient, test_user: User, session: Session):
    # Create a game first
    opponent = User(
        username="상대방3",
        phone_number="010-7777-7777",
        password="testpass",
        student_id=20240005,
    )
    session.add(opponent)
    session.commit()
    session.refresh(opponent)

    game_data = {
        "winner_id": test_user.user_id,
        "loser_id": opponent.user_id,
        "plus_score": 20,
        "minus_score": 10,
    }
    create_response = client.post("/games/", json=game_data)
    game_id = create_response.json()["game_id"]

    # Test updating the game
    update_data = {"plus_score": 25, "minus_score": 12}
    response = client.put(f"/games/{game_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["plus_score"] == update_data["plus_score"]
    assert data["minus_score"] == update_data["minus_score"]


def test_delete_game(client: TestClient, test_user: User, session: Session):
    # Create a game first
    opponent = User(
        username="상대방4",
        phone_number="010-6666-6666",
        password="testpass",
        student_id=20240006,
    )
    session.add(opponent)
    session.commit()
    session.refresh(opponent)

    game_data = {
        "winner_id": test_user.user_id,
        "loser_id": opponent.user_id,
        "plus_score": 30,
        "minus_score": 15,
    }
    create_response = client.post("/games/", json=game_data)
    game_id = create_response.json()["game_id"]

    # Test deleting the game
    response = client.delete(f"/games/{game_id}")
    assert response.status_code == 200
    assert response.json()["detail"] == "Game deleted successfully"

    # Verify game is deleted
    response = client.get(f"/games/{game_id}")
    assert response.status_code == 404
