from fastapi.testclient import TestClient
from sqlmodel import Session
from models import User


def test_create_score_rank(client: TestClient, test_user: User):
    score_rank_data = {
        "user_id": test_user.user_id,
        "rank": 1,
        "score": 1500.0,
        "prize": 1000,
    }
    response = client.post("/score-ranks/", json=score_rank_data)
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == score_rank_data["user_id"]
    assert data["rank"] == score_rank_data["rank"]
    assert data["score"] == score_rank_data["score"]
    assert data["prize"] == score_rank_data["prize"]


def test_read_score_rank(client: TestClient, test_user: User):
    # Create a score rank first
    score_rank_data = {
        "user_id": test_user.user_id,
        "rank": 2,
        "score": 1200.0,
        "prize": 500,
    }
    create_response = client.post("/score-ranks/", json=score_rank_data)
    rank_id = create_response.json()["rank_id"]

    # Test reading the score rank
    response = client.get(f"/score-ranks/{rank_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == score_rank_data["user_id"]
    assert data["rank"] == score_rank_data["rank"]
    assert data["score"] == score_rank_data["score"]


def test_read_user_score_rank(client: TestClient, test_user: User):
    # Create a score rank first
    score_rank_data = {
        "user_id": test_user.user_id,
        "rank": 3,
        "score": 1100.0,
        "prize": 200,
    }
    client.post("/score-ranks/", json=score_rank_data)

    # Test reading user's score rank
    response = client.get(f"/score-ranks/user/{test_user.user_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == test_user.user_id


def test_update_score_rank(client: TestClient, test_user: User):
    # Create a score rank first
    score_rank_data = {
        "user_id": test_user.user_id,
        "rank": 4,
        "score": 1000.0,
        "prize": 100,
    }
    create_response = client.post("/score-ranks/", json=score_rank_data)
    rank_id = create_response.json()["rank_id"]

    # Test updating the score rank
    update_data = {
        "rank": 1,
        "score": 1800.0,
        "prize": 2000,
        "game_count": 10,
        "win_count": 8,
        "lose_count": 2,
    }
    response = client.put(f"/score-ranks/{rank_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["rank"] == update_data["rank"]
    assert data["score"] == update_data["score"]
    assert data["prize"] == update_data["prize"]
    assert data["game_count"] == update_data["game_count"]
    assert data["win_count"] == update_data["win_count"]
    assert data["lose_count"] == update_data["lose_count"]


def test_delete_score_rank(client: TestClient, test_user: User):
    # Create a score rank first
    score_rank_data = {
        "user_id": test_user.user_id,
        "rank": 5,
        "score": 900.0,
        "prize": 50,
    }
    create_response = client.post("/score-ranks/", json=score_rank_data)
    rank_id = create_response.json()["rank_id"]

    # Test deleting the score rank
    response = client.delete(f"/score-ranks/{rank_id}")
    assert response.status_code == 200
    assert response.json()["detail"] == "Score rank deleted successfully"

    # Verify score rank is deleted
    response = client.get(f"/score-ranks/{rank_id}")
    assert response.status_code == 404


def test_create_score_rank_invalid_user(client: TestClient):
    score_rank_data = {
        "user_id": 999,  # Non-existent user
        "rank": 1,
        "score": 1500.0,
        "prize": 1000,
    }
    response = client.post("/score-ranks/", json=score_rank_data)
    assert (
        response.status_code == 400
    )  # or whatever error code you're using for foreign key violations


def test_update_score_rank_invalid_data(client: TestClient, test_user: User):
    # Create a score rank first
    score_rank_data = {
        "user_id": test_user.user_id,
        "rank": 6,
        "score": 800.0,
        "prize": 25,
    }
    create_response = client.post("/score-ranks/", json=score_rank_data)
    rank_id = create_response.json()["rank_id"]

    # Test updating with invalid data
    update_data = {"game_count": 5, "win_count": 10}  # Invalid: more wins than games
    response = client.put(f"/score-ranks/{rank_id}", json=update_data)
    assert (
        response.status_code == 400
    )  # or whatever error code you're using for validation errors
