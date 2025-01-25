from fastapi.testclient import TestClient
from sqlmodel import Session


def test_create_user(client: TestClient):
    user_data = {
        "username": "홍길동",
        "phone_number": "010-9876-5432",
        "password": "testpass123",
        "student_id": 20240002,
    }
    response = client.post("/users/", json=user_data)
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == user_data["username"]
    assert data["phone_number"] == user_data["phone_number"]
    assert data["student_id"] == user_data["student_id"]
    assert "user_id" in data


def test_read_user(client: TestClient, test_user):
    response = client.get(f"/users/{test_user.user_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == test_user.username
    assert data["phone_number"] == test_user.phone_number


def test_read_user_not_found(client: TestClient):
    response = client.get("/users/999")
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found"


def test_update_user(client: TestClient, test_user):
    update_data = {"username": "김철수", "phone_number": "010-5555-5555"}
    response = client.put(f"/users/{test_user.user_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == update_data["username"]
    assert data["phone_number"] == update_data["phone_number"]


def test_delete_user(client: TestClient, test_user):
    response = client.delete(f"/users/{test_user.user_id}")
    assert response.status_code == 200
    assert response.json()["detail"] == "User deleted successfully"

    # Verify user is deleted
    response = client.get(f"/users/{test_user.user_id}")
    assert response.status_code == 404
