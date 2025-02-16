FROM postgres:15

# Locale 설정에 필요한 패키지 설치 및 gosu 설치
RUN apt-get update && apt-get install -y locales gosu

# ko_KR.UTF-8 locale 생성
RUN locale-gen ko_KR.UTF-8 && \
    localedef -i ko_KR -f UTF-8 ko_KR.UTF-8

# 환경 변수 설정
ENV LANG=ko_KR.UTF-8 \
    LC_ALL=ko_KR.UTF-8 \
    TZ=Asia/Seoul

# PostgreSQL 데이터 디렉토리 권한 설정 (공식 이미지가 자동 처리하므로 선택 사항)
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql

# 공식 이미지에서는 데이터 디렉토리가 비어있으면 initdb가 자동 실행되므로
# 별도의 initdb 명령은 생략합니다.
EXPOSE 5432

CMD ["postgres"]