from fastapi import FastAPI, HTTPException
from models import create_user, read_user_by_user_id

app = FastAPI()


@app.get("/")
def read_root():
    return {"Hello": "World?"}


@app.post("/user/")
def create_user_endpoint(
    user_id: int,
    username: str,
    phone_number: str,
    password: str,
    student_id: int,
):
    try:
        user = create_user(user_id, username, phone_number, password, student_id)
        return {"user_id": user.user_id, "username": user.username}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/user/{user_id}")
def read_user(user_id: int):
    user = read_user_by_user_id(user_id)
    return {"user_id": user}
