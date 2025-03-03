// API URL 상수
const API_BASE_URL = '';
const API_LOGIN = `${API_BASE_URL}/api/login`;
const API_USERS = `${API_BASE_URL}/api/usersinfo`;
const API_GAMES = `${API_BASE_URL}/api/games`;
const API_POSTS = `${API_BASE_URL}/api/recruit/posts`;

// 전역 변수
let currentUser = null;
let authToken = null;
let currentPage = 'dashboard';

// 초기화 함수
document.addEventListener('DOMContentLoaded', function() {
    // 저장된 토큰 확인
    const savedToken = localStorage.getItem('adminToken');
    if (savedToken) {
        // 토큰 유효성 검증
        validateToken(savedToken);
    }

    // 로그인 폼 제출 이벤트
    document.getElementById('login-form').addEventListener('submit', function(e) {
        e.preventDefault();
        loginUser();
    });

    // 네비게이션 이벤트
    document.getElementById('dashboard-link').addEventListener('click', function(e) {
        e.preventDefault();
        showPage('dashboard');
    });

    document.getElementById('users-link').addEventListener('click', function(e) {
        e.preventDefault();
        showPage('users');
    });

    document.getElementById('games-link').addEventListener('click', function(e) {
        e.preventDefault();
        showPage('games');
    });

    document.getElementById('posts-link').addEventListener('click', function(e) {
        e.preventDefault();
        showPage('posts');
    });

    document.getElementById('logout-link').addEventListener('click', function(e) {
        e.preventDefault();
        logout();
    });

    // 사용자 모달 저장 버튼
    document.getElementById('save-user-btn').addEventListener('click', function() {
        saveUserChanges();
    });

    // 사용자 모달 삭제 버튼
    document.getElementById('delete-user-btn').addEventListener('click', function() {
        showConfirmModal('사용자 삭제', '정말로 이 사용자를 삭제하시겠습니까?', function() {
            deleteUser(document.getElementById('user-id').value);
        });
    });

    // 게시물 삭제 버튼
    document.getElementById('delete-post-btn').addEventListener('click', function() {
        showConfirmModal('게시물 삭제', '정말로 이 게시물을 삭제하시겠습니까?', function() {
            deletePost(document.getElementById('post-id').value);
        });
    });

    // 검색 버튼
    document.getElementById('search-user-btn').addEventListener('click', function() {
        const searchTerm = document.getElementById('user-search').value;
        loadUsers(1, searchTerm);
    });

    document.getElementById('search-post-btn').addEventListener('click', function() {
        const searchTerm = document.getElementById('post-search').value;
        loadPosts(1, searchTerm);
    });

    // 게임 필터 버튼
    document.getElementById('filter-games-btn').addEventListener('click', function() {
        loadGames(1);
    });
});

// 로그인 함수
function loginUser() {
    const studentId = document.getElementById('student-id').value;
    const password = document.getElementById('password').value;
    
    console.log('로그인 시도:', studentId);
    
    // 로그인 요청
    fetch(API_LOGIN, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            student_id: studentId,
            password: password
        })
    })
    .then(response => {
        console.log('로그인 응답 상태:', response.status);
        return response.json();
    })
    .then(data => {
        console.log('로그인 응답 데이터:', data);
        if (data.access_token || (data.success && data.access_token)) {
            // 로그인 성공
            authToken = data.access_token;
            localStorage.setItem('adminToken', authToken);
            
            // 사용자 정보 가져오기
            return fetch(`${API_BASE_URL}/api/userinfo/${data["user"].user_id || data["user"].id}`, {
                headers: {
                    'Authorization': `Bearer ${authToken}`
                }
            });
        } else {
            // 로그인 실패
            throw new Error(data.detail || data.message || '로그인에 실패했습니다.');
        }
    })
    .then(response => {
        console.log('사용자 정보 응답 상태:', response.status);
        return response.json();
    })
        .then(Data => {
        console.log('사용자 정보:', Data);
        userData = Data["user"];
        console.log('사용자 정보:', userData);
        console.log('is_admin 값:', userData.is_admin);
        console.log('is_admin 타입:', typeof userData.is_admin);
        currentUser = userData;
        
        // 관리자 여부 확인 - 유연하게 처리
        if (userData.is_admin === true || userData.is_admin === 'true' || userData.is_admin === 't' || userData.is_admin === 1) {
            // 관리자 페이지 표시
            document.getElementById('admin-name').textContent = userData.name || '관리자';
            showAdminDashboard();
            loadDashboardData();
        } else {
            console.error('관리자 권한 없음:', userData);
            throw new Error('관리자 권한이 없습니다. (is_admin 값: ' + userData.is_admin + ')');
        }
    })
    .catch(error => {
        console.error('Login error:', error);
        const errorDiv = document.getElementById('login-error');
        errorDiv.textContent = error.message;
        errorDiv.classList.remove('hidden');
        localStorage.removeItem('adminToken');
    });
}

// 토큰 검증 함수
function validateToken(token) {
    // 저장된 토큰이 있으면 사용자를 로그인 상태로 간주
    if (token) {
        authToken = token;
        
        // 사용자 정보 가져오기 시도
        fetch(`${API_BASE_URL}/api/userinfo/1`, {  // 관리자 ID를 1로 가정
            headers: {
                'Authorization': `Bearer ${token}`
            }
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('토큰이 유효하지 않습니다.');
            }
            return response.json();
        })
        .then(data => {
            currentUser = data.user || data;
            
            // 관리자 페이지 표시
            document.getElementById('admin-name').textContent = '관리자';
            showAdminDashboard();
            loadDashboardData();
        })
        .catch(error => {
            console.error('Token validation error:', error);
            localStorage.removeItem('adminToken');
            // 로그인 페이지 유지
        });
    }
}

// 로그아웃 함수
function logout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('adminToken');
    
    // 로그인 페이지 표시
    document.getElementById('login-page').classList.remove('hidden');
    document.getElementById('admin-dashboard').classList.add('hidden');
    
    // 로그인 폼 초기화
    document.getElementById('login-form').reset();
    document.getElementById('login-error').classList.add('hidden');
}

// 관리자 대시보드 표시 함수
function showAdminDashboard() {
    document.getElementById('login-page').classList.add('hidden');
    document.getElementById('admin-dashboard').classList.remove('hidden');
    showPage('dashboard');
}

// 페이지 전환 함수
function showPage(pageName) {
    currentPage = pageName;
    
    // 모든 페이지 숨기기
    document.getElementById('dashboard-page').classList.add('hidden');
    document.getElementById('users-page').classList.add('hidden');
    document.getElementById('games-page').classList.add('hidden');
    document.getElementById('posts-page').classList.add('hidden');
    
    // 모든 네비게이션 링크 비활성화
    document.getElementById('dashboard-link').classList.remove('active');
    document.getElementById('users-link').classList.remove('active');
    document.getElementById('games-link').classList.remove('active');
    document.getElementById('posts-link').classList.remove('active');
    
    // 선택한 페이지 표시 및 네비게이션 링크 활성화
    document.getElementById(`${pageName}-page`).classList.remove('hidden');
    document.getElementById(`${pageName}-link`).classList.add('active');
    
    // 페이지별 데이터 로드
    if (pageName === 'dashboard') {
        loadDashboardData();
    } else if (pageName === 'users') {
        loadUsers(1);
    } else if (pageName === 'games') {
        loadGames(1);
    } else if (pageName === 'posts') {
        loadPosts(1);
    }
}

// 대시보드 데이터 로드 함수
function loadDashboardData() {
    // 기존 API가 없으므로 기본 데이터를 표시합니다
    document.getElementById('total-users').textContent = '-';
    document.getElementById('new-users').textContent = '-';
    document.getElementById('total-games').textContent = '-';
    document.getElementById('recent-games').textContent = '-';
    document.getElementById('total-posts').textContent = '-';
    document.getElementById('avg-score').textContent = '-';
    
    // 사용자 데이터 가져오기
    fetch(`${API_USERS}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(data => {
        console.log('사용자 데이터:', data);
        
        // 총 사용자 수 업데이트
        if (data.users && Array.isArray(data.users)) {
            document.getElementById('total-users').textContent = data.users.length;
            
            // 상위 사용자 표시
            const tbody = document.getElementById('top-users');
            tbody.innerHTML = '';
            
            // 점수 기준으로 정렬
            const sortedUsers = [...data.users].sort((a, b) => (b.score || 0) - (a.score || 0)).slice(0, 5);
            
            if (sortedUsers.length === 0) {
                const tr = document.createElement('tr');
                tr.innerHTML = '<td colspan="4" class="text-center">데이터가 없습니다.</td>';
                tbody.appendChild(tr);
                return;
            }
            
            sortedUsers.forEach((user, index) => {
                const tr = document.createElement('tr');
                // 이름이 undefined일 경우 대체 텍스트 추가
                const userName = user.username || `사용자 ${user.id || ''}`;
                tr.innerHTML = `
                    <td>${index + 1}</td>
                    <td>${userName}</td>
                    <td>${user.score || 0}</td>
                    <td>${user.wins || 0}/${user.losses || 0}</td>
                `;
                tbody.appendChild(tr);
            });
        }
    })
    .catch(error => {
        console.error('Error loading users data:', error);
        document.getElementById('total-users').textContent = '0';
        
        const tbody = document.getElementById('top-users');
        tbody.innerHTML = '<tr><td colspan="4" class="text-center">데이터 로드 실패</td></tr>';
    });
    
    // 게임 데이터 가져오기 - /api/gamesinfo가 없는 경우 대비
    fetch(`${API_GAMES}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => {
        if (!response.ok) {
            // 404 등의 오류인 경우 빈 데이터로 처리
            return { success: false, games: [] };
        }
        return response.json();
    })
    .then(data => {
        console.log('게임 데이터:', data);
        
        // 총 게임 수 업데이트
        const games = data.games || [];
        const gamesArray = Array.isArray(games) ? games : [];
        
        document.getElementById('total-games').textContent = gamesArray.length;
        document.getElementById('recent-games').textContent = gamesArray.filter(
            game => new Date(game.created_at) > new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
        ).length;
        
        // 점수 평균 계산
        if (gamesArray.length > 0) {
            const totalScore = gamesArray.reduce((sum, game) => sum + (game.plus_score || 0), 0);
            document.getElementById('avg-score').textContent = (totalScore / gamesArray.length).toFixed(1);
        }
        
        // 최근 게임 표시
        const tbody = document.getElementById('recent-games-list');
        tbody.innerHTML = '';
        
        // 최근 순으로 정렬하고 5개만 표시
        const recentGames = [...gamesArray]
            .sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0))
            .slice(0, 5);
        
        if (recentGames.length === 0) {
            const tr = document.createElement('tr');
            tr.innerHTML = '<td colspan="4" class="text-center">데이터가 없습니다.</td>';
            tbody.appendChild(tr);
            return;
        }
        
        recentGames.forEach(game => {
            const tr = document.createElement('tr');
            // 승자/패자 이름이 없을 경우 ID로 대체
            const winnerName = game.winner_name || `사용자 ${game.winner_id || '?'}`;
            const loserName = game.loser_name || `사용자 ${game.loser_id || '?'}`;
            tr.innerHTML = `
                <td>${winnerName}</td>
                <td>${loserName}</td>
                <td>${game.plus_score || 0}:${game.minus_score || 0}</td>
                <td>${formatDate(game.created_at) || '-'}</td>
            `;
            tbody.appendChild(tr);
        });
    })
    .catch(error => {
        console.error('Error loading games data:', error);
        document.getElementById('total-games').textContent = '0';
        document.getElementById('recent-games').textContent = '0';
        document.getElementById('avg-score').textContent = '0';
        
        const tbody = document.getElementById('recent-games-list');
        tbody.innerHTML = '<tr><td colspan="4" class="text-center">데이터 로드 실패</td></tr>';
    });
    
    // 게시물 데이터 가져오기
    fetch(`${API_POSTS}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(data => {
        console.log('게시물 데이터:', data);
        
        // 총 게시물 수 업데이트
        if (data.posts && Array.isArray(data.posts)) {
            document.getElementById('total-posts').textContent = data.posts.length;
        }
    })
    .catch(error => {
        console.error('Error loading posts data:', error);
        document.getElementById('total-posts').textContent = '0';
    });
}

// 사용자 데이터 로드 함수
function loadUsers(page, searchTerm = '') {
    // API 호출
    fetch(`${API_USERS}?page=${page}&search=${searchTerm}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(data => {
        const tbody = document.getElementById('users-table');
        tbody.innerHTML = '';
        
        const users = data.users || [];
        const usersArray = Array.isArray(users) ? users : [];
        
        if (usersArray.length === 0) {
            const tr = document.createElement('tr');
            tr.innerHTML = '<td colspan="9" class="text-center">데이터가 없습니다.</td>';
            tbody.appendChild(tr);
            return;
        }
        
        usersArray.forEach(user => {
            const tr = document.createElement('tr');
            // 누락된 필드에 대한 기본값 제공
            const userName = user.username || '이름 없음';
            const studentId = user.student_id || '-';
            const phone = user.phone_number || '-';
            const score = user.score || 0;
            const wins = user.win_count || 0;
            const losses = user.lose_count || 0;
            const createdAt = formatDate(user.created_at) || '-';
            const isAdmin = user.is_admin ? '<span class="badge bg-success">관리자</span>' : '<span class="badge bg-secondary">일반</span>';
            
            tr.innerHTML = `
                <td>${user.user_id || '-'}</td>
                <td>${userName}</td>
                <td>${studentId}</td>
                <td>${phone}</td>
                <td>${score}</td>
                <td>${wins}/${losses}</td>
                <td>${createdAt}</td>
                <td>${isAdmin}</td>
                <td>
                    <button class="btn btn-sm btn-primary edit-user" data-id="${user.id}">편집</button>
                </td>
            `;
            tbody.appendChild(tr);
        });
        
        // 이벤트 핸들러 추가
        document.querySelectorAll('.edit-user').forEach(btn => {
            btn.addEventListener('click', function() {
                const userId = this.getAttribute('data-id');
                openUserModal(userId);
            });
        });
        
        // 페이지네이션
        setupPagination('users-pagination', page, data.total_pages || 1, function(newPage) {
            loadUsers(newPage, searchTerm);
        });
    })
    .catch(error => {
        console.error('Error loading users:', error);
        const tbody = document.getElementById('users-table');
        tbody.innerHTML = '<tr><td colspan="9" class="text-center">데이터 로드 실패</td></tr>';
    });
}

// 게임 데이터 로드 함수
function loadGames(page) {
    const startDate = document.getElementById('games-start-date').value;
    const endDate = document.getElementById('games-end-date').value;
    
    // API 호출
    fetch(`${API_GAMES}?page=${page}&start_date=${startDate}&end_date=${endDate}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => {
        if (!response.ok) {
            // 404 등의 오류인 경우 빈 데이터로 처리
            return { success: false, games: [] };
        }
        return response.json();
    })
    .then(data => {
        const tbody = document.getElementById('games-table');
        tbody.innerHTML = '';
        
        const games = data.games || [];
        const gamesArray = Array.isArray(games) ? games : [];
        
        if (gamesArray.length === 0) {
            const tr = document.createElement('tr');
            tr.innerHTML = '<td colspan="6" class="text-center">데이터가 없습니다.</td>';
            tbody.appendChild(tr);
            return;
        }
        
        gamesArray.forEach(game => {
            const tr = document.createElement('tr');
            // 승자/패자 이름이 없을 경우 ID로 대체
            const winnerName = game.winner_name || `사용자 ${game.winner_id || '?'}`;
            const loserName = game.loser_name || `사용자 ${game.loser_id || '?'}`;
            tr.innerHTML = `
                <td>${game.id || '-'}</td>
                <td>${winnerName}</td>
                <td>${loserName}</td>
                <td>${game.plus_score || 0}:${game.minus_score || 0}</td>
                <td>${formatDate(game.created_at) || '-'}</td>
                <td>
                    <button class="btn btn-sm btn-danger delete-game" data-id="${game.id}">삭제</button>
                </td>
            `;
            tbody.appendChild(tr);
        });
        
        // 이벤트 핸들러 추가
        document.querySelectorAll('.delete-game').forEach(btn => {
            btn.addEventListener('click', function() {
                const gameId = this.getAttribute('data-id');
                showConfirmModal('게임 삭제', '정말로 이 게임을 삭제하시겠습니까?', function() {
                    deleteGame(gameId);
                });
            });
        });
        
        // 페이지네이션 - 데이터에 total_pages가 없을 경우 기본값 1로 설정
        setupPagination('games-pagination', page, data.total_pages || 1, function(newPage) {
            loadGames(newPage);
        });
    })
    .catch(error => {
        console.error('Error loading games:', error);
        const tbody = document.getElementById('games-table');
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">데이터 로드 실패</td></tr>';
    });
}

// 게시물 데이터 로드 함수
function loadPosts(page, searchTerm = '') {
    // API 호출
    fetch(`${API_POSTS}?page=${page}&search=${searchTerm}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(data => {
        const tbody = document.getElementById('posts-table');
        tbody.innerHTML = '';
        
        if (data.posts.length === 0) {
            const tr = document.createElement('tr');
            tr.innerHTML = '<td colspan="8" class="text-center">데이터가 없습니다.</td>';
            tbody.appendChild(tr);
            return;
        }
        
        data.posts.forEach(post => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${post.id}</td>
                <td>${post.title}</td>
                <td>${post.writer_name}</td>
                <td>${formatDate(post.game_at)}</td>
                <td>${post.game_place}</td>
                <td>${post.current_user}/${post.max_user}</td>
                <td>${formatDate(post.created_at)}</td>
                <td>
                    <button class="btn btn-sm btn-primary view-post" data-id="${post.id}">보기</button>
                </td>
            `;
            tbody.appendChild(tr);
        });
        
        // 이벤트 핸들러 추가
        document.querySelectorAll('.view-post').forEach(btn => {
            btn.addEventListener('click', function() {
                const postId = this.getAttribute('data-id');
                openPostModal(postId);
            });
        });
        
        // 페이지네이션
        setupPagination('posts-pagination', page, data.total_pages, function(newPage) {
            loadPosts(newPage, searchTerm);
        });
    })
    .catch(error => {
        console.error('Error loading posts:', error);
        const tbody = document.getElementById('posts-table');
        tbody.innerHTML = '<tr><td colspan="8" class="text-center">데이터 로드 실패</td></tr>';
    });
}

// 사용자 모달 열기 함수
function openUserModal(userId) {
    // userId가 없으면 오류 메시지 표시 후 반환
    if (!userId) {
        console.error('사용자 ID가 없습니다.');
        alert('사용자 정보를 불러올 수 없습니다.');
        return;
    }
    
    // 사용자 정보 가져오기
    fetch(`${API_BASE_URL}/api/userinfo/${userId}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('사용자 정보를 불러오는데 실패했습니다.');
        }
        return response.json();
    })
    .then(data => {
        const user = data.user || data;
        
        // 모달 폼에 데이터 채우기
        document.getElementById('user-id').value = user.id || '';
        document.getElementById('username').value = user.username || '';
        document.getElementById('student-id-modal').value = user.student_id || '';
        document.getElementById('phone').value = user.phone || '';
        document.getElementById('status-message').value = user.status_message || '';
        document.getElementById('is-admin').checked = user.is_admin || false;
        
        // 모달 표시
        const userModal = new bootstrap.Modal(document.getElementById('userModal'));
        userModal.show();
    })
    .catch(error => {
        console.error('Error loading user data:', error);
        alert('사용자 정보를 불러오는데 실패했습니다.');
    });
}

// 게시물 모달 열기 함수
function openPostModal(postId) {
    // 게시물 정보 가져오기
    fetch(`${API_BASE_URL}/api/recruit/post/${postId}`, {
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(post => {
        // 모달 폼에 데이터 채우기
        document.getElementById('post-id').value = post.id;
        document.getElementById('post-title').value = post.title;
        document.getElementById('post-writer').value = post.writer_name;
        document.getElementById('post-game-at').value = formatDateTimeForInput(post.game_at);
        document.getElementById('post-place').value = post.game_place;
        document.getElementById('post-content').value = post.content;
        
        // 참가자 목록
        const tbody = document.getElementById('post-participants');
        tbody.innerHTML = '';
        
        if (post.participants.length === 0) {
            const tr = document.createElement('tr');
            tr.innerHTML = '<td colspan="3" class="text-center">참가자가 없습니다.</td>';
            tbody.appendChild(tr);
        } else {
            post.participants.forEach(participant => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td>${participant.id}</td>
                    <td>${participant.username}</td>
                    <td>${participant.student_id}</td>
                `;
                tbody.appendChild(tr);
            });
        }
        
        // 모달 표시
        const postModal = new bootstrap.Modal(document.getElementById('postModal'));
        postModal.show();
    })
    .catch(error => {
        console.error('Error loading post data:', error);
        alert('게시물 정보를 불러오는데 실패했습니다.');
    });
}

// 확인 모달 표시 함수
function showConfirmModal(title, message, confirmCallback) {
    document.getElementById('confirm-title').textContent = title;
    document.getElementById('confirm-message').textContent = message;
    
    const confirmModal = new bootstrap.Modal(document.getElementById('confirmModal'));
    
    // 기존 이벤트 리스너 제거
    const confirmBtn = document.getElementById('confirm-action-btn');
    const newConfirmBtn = confirmBtn.cloneNode(true);
    confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
    
    // 새 이벤트 리스너 추가
    newConfirmBtn.addEventListener('click', function() {
        confirmCallback();
        confirmModal.hide();
    });
    
    confirmModal.show();
}

// 사용자 정보 저장 함수
function saveUserChanges() {
    const userId = document.getElementById('user-id').value;
    const userData = {
        name: document.getElementById('username').value,
        phone: document.getElementById('phone').value,
        status_message: document.getElementById('status-message').value,
        is_admin: document.getElementById('is-admin').checked
    };
    
    // API 호출
    fetch(`${API_BASE_URL}/api/admin/user/${userId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify(userData)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // 성공
            const userModal = bootstrap.Modal.getInstance(document.getElementById('userModal'));
            userModal.hide();
            
            // 사용자 목록 새로고침
            loadUsers(1);
            
            alert('사용자 정보가 업데이트되었습니다.');
        } else {
            // 실패
            throw new Error(data.message || '사용자 정보 업데이트에 실패했습니다.');
        }
    })
    .catch(error => {
        console.error('Error updating user:', error);
        alert('사용자 정보 업데이트에 실패했습니다.');
    });
}

// 사용자 삭제 함수
function deleteUser(userId) {
    // API 호출
    fetch(`${API_BASE_URL}/api/admin/user/${userId}`, {
        method: 'DELETE',
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // 성공
            const userModal = bootstrap.Modal.getInstance(document.getElementById('userModal'));
            userModal.hide();
            
            // 사용자 목록 새로고침
            loadUsers(1);
            
            alert('사용자가 삭제되었습니다.');
        } else {
            // 실패
            throw new Error(data.message || '사용자 삭제에 실패했습니다.');
        }
    })
    .catch(error => {
        console.error('Error deleting user:', error);
        alert('사용자 삭제에 실패했습니다.');
    });
}

// 게임 삭제 함수
function deleteGame(gameId) {
    // API 호출
    fetch(`${API_BASE_URL}/api/admin/game/${gameId}`, {
        method: 'DELETE',
        headers: {
            'Authorization': `Bearer ${authToken}`
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // 성공
            alert('게임이 삭제되었습니다.');
            
            // 게임 목록 새로고침
            loadGames(1);
        } else {
            // 실패
            throw new Error(data.message || '게임 삭제에 실패했습니다.');
        }
    })
    .catch(error => {
        console.error('Error deleting game:', error);
        alert('게임 삭제에 실패했습니다.');
    });
}

// 게시물 삭제 함수
function deletePost(postId) {
    // API 호출
    fetch(`${API_BASE_URL}/api/recruit/post/${postId}`, {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify({
            user_id: currentUser.id
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            // 성공
            const postModal = bootstrap.Modal.getInstance(document.getElementById('postModal'));
            postModal.hide();
            
            // 게시물 목록 새로고침
            loadPosts(1);
            
            alert('게시물이 삭제되었습니다.');
        } else {
            // 실패
            throw new Error(data.message || '게시물 삭제에 실패했습니다.');
        }
    })
    .catch(error => {
        console.error('Error deleting post:', error);
        alert('게시물 삭제에 실패했습니다.');
    });
}

// 페이지네이션 설정 함수
function setupPagination(elementId, currentPage, totalPages, callback) {
    const pagination = document.getElementById(elementId);
    pagination.innerHTML = '';
    
    // 이전 페이지
    const prevLi = document.createElement('li');
    prevLi.className = `page-item ${currentPage === 1 ? 'disabled' : ''}`;
    prevLi.innerHTML = `<a class="page-link" href="#">이전</a>`;
    pagination.appendChild(prevLi);
    
    if (currentPage > 1) {
        prevLi.addEventListener('click', function(e) {
            e.preventDefault();
            callback(currentPage - 1);
        });
    }
    
    // 페이지 번호
    const maxVisiblePages = 5;
    const startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
    const endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
    
    for (let i = startPage; i <= endPage; i++) {
        const pageLi = document.createElement('li');
        pageLi.className = `page-item ${i === currentPage ? 'active' : ''}`;
        pageLi.innerHTML = `<a class="page-link" href="#">${i}</a>`;
        pagination.appendChild(pageLi);
        
        if (i !== currentPage) {
            pageLi.addEventListener('click', function(e) {
                e.preventDefault();
                callback(i);
            });
        }
    }
    
    // 다음 페이지
    const nextLi = document.createElement('li');
    nextLi.className = `page-item ${currentPage === totalPages ? 'disabled' : ''}`;
    nextLi.innerHTML = `<a class="page-link" href="#">다음</a>`;
    pagination.appendChild(nextLi);
    
    if (currentPage < totalPages) {
        nextLi.addEventListener('click', function(e) {
            e.preventDefault();
            callback(currentPage + 1);
        });
    }
}

// 날짜 포맷 함수
function formatDate(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleString('ko-KR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// 날짜시간 입력용 포맷 함수
function formatDateTimeForInput(dateString) {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toISOString().slice(0, 16);
} 