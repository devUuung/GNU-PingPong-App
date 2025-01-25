#!/bin/bash

# 테스트 데이터베이스 생성
PGPASSWORD=postgres psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS pingpong_test;"
PGPASSWORD=postgres psql -U postgres -h localhost -c "CREATE DATABASE pingpong_test;"

# 환경 변수 설정
export $(cat .env.test | xargs)

# 테스트 실행
pytest "$@" 