# from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
# from fastapi.responses import JSONResponse
# from sqlalchemy.exc import IntegrityError
# from typing import List, Optional
# from pydantic import BaseModel, Field
# from datetime import timedelta
# from sqlmodel import Session
# import bcrypt
# from sqlalchemy.sql import select

# from core.config import settings
# from core.auth import create_access_token, get_current_active_user, get_admin_user
# from core.utils import save_upload_file, prepare_user_response
# from models import (
#     User,
#     create_user,
#     read_user_by_student_id,
#     read_user_by_user_id,
#     read_user_by_phone_number,
#     read_users_by_all,
#     update_user,
#     engine,
#     create_match_request,
#     read_match_request_by_user_id,
#     read_all_active_match_requests,
#     delete_match_request_by_user_id,
#     MatchRequest,
# )

# router = APIRouter(prefix=f"{settings.API_V1_STR}/users", tags=["users"])

# # 경기 입력 요청 관련 엔드포인트
# @router.post("/match-request")
# async def create_new_match_request(
#     current_user: User = Depends(get_current_active_user),
# ):
#     """
#     현재 사용자의 경기 입력 요청을 생성합니다.
#     이미 활성화된 요청이 있으면 기존 요청을 반환합니다.
#     """
#     match_request = create_match_request(current_user.user_id)
#     return {
#         "success": True,
#         "request_id": match_request.request_id,
#         "user_id": match_request.user_id,
#         "created_at": match_request.created_at,
#     }


# @router.get("/match-request/all")
# async def get_all_match_requests(current_user: User = Depends(get_current_active_user)):
#     """
#     모든 활성화된 경기 입력 요청을 조회합니다.
#     """
#     match_requests = read_all_active_match_requests()
#     user_ids = [request.user_id for request in match_requests]
#     current_user_id = current_user.user_id

#     with Session(engine) as session:
#         # 요청한 사용자들의 정보 조회
#         statement = select(User).where(User.user_id.in_(user_ids))
#         users = session.exec(statement).all()

#         # 사용자 정보와 요청 정보 매핑
#         result = []
#         for user in users:
#             try:
#                 user = user[0]
#                 user_id = user.user_id

#                 if user_id is None:
#                     print(f"주의: user 객체에 user_id 필드 없음: {dir(user)}")
#                     continue

#                 if user_id == current_user_id:
#                     continue

#                 # 응답 데이터 준비
#                 user_data = prepare_user_response(user)
#                 match_request = next(
#                     (r for r in match_requests if r.user_id == user_id), None
#                 )

#                 if match_request:
#                     result.append(
#                         {
#                             "user": user_data,
#                             "request_id": match_request.request_id,
#                             "created_at": match_request.created_at,
#                         }
#                     )
#             except Exception as e:
#                 print(f"사용자 처리 중 오류: {e}, 사용자 ID: {user}")
#                 continue

#     return {"success": True, "match_requests": result}


# @router.delete("/match-request/me")
# async def cancel_my_match_request(
#     current_user: User = Depends(get_current_active_user),
# ):
#     """
#     현재 사용자의 경기 입력 요청을 비활성화합니다.
#     """
#     match_request = delete_match_request_by_user_id(current_user.user_id)

#     return {"success": True, "message": "경기 입력 요청이 취소되었습니다."}
