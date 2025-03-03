import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'win_lost_select.dart';
import 'package:flutter_app/providers/users_info_provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';

class FindUserPage extends StatefulWidget {
  const FindUserPage({Key? key}) : super(key: key);

  @override
  _FindUserPageState createState() => _FindUserPageState();
}

class _FindUserPageState extends State<FindUserPage> {
  // 블루투스 관련 변수
  late FlutterBluetoothSerial _bluetooth;
  List<BluetoothDiscoveryResult> _results = [];
  bool _isDiscovering = false;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<dynamic> _nearbyUsers = [];

  @override
  void initState() {
    super.initState();
    // 블루투스 인스턴스 초기화
    _bluetooth = FlutterBluetoothSerial.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUsersInfo(context);
      Provider.of<UsersInfoProvider>(context, listen: false)
          .fetchUserInfo(context);
      // 블루투스 검색 시작
      _startDiscovery();
    });
  }

  @override
  void dispose() {
    // 블루투스 검색 종료
    _streamSubscription?.cancel();
    super.dispose();
  }

  // 블루투스 검색 시작 메서드
  void _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
      _results = [];
      _nearbyUsers = [];
    });

    try {
      // 블루투스 권한 요청
      bool? isEnabled;
      try {
        isEnabled = await _bluetooth.isEnabled;
      } catch (e) {
        print('블루투스 활성화 상태 확인 중 오류: $e');
        // 일부 기기에서는 isEnabled가 실패할 수 있으므로
        // 기본값으로 진행
        isEnabled = false;
      }

      if (isEnabled != true) {
        try {
          await _bluetooth.requestEnable();
        } catch (e) {
          print('블루투스 활성화 요청 중 오류: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('블루투스를 활성화해주세요.'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _isDiscovering = false;
          });
          return;
        }
      }

      // 블루투스 검색 시작
      try {
        _streamSubscription = _bluetooth.startDiscovery().listen(
          (result) {
            setState(() {
              final existingIndex = _results.indexWhere(
                (element) => element.device.address == result.device.address,
              );
              if (existingIndex >= 0) {
                _results[existingIndex] = result;
              } else {
                _results.add(result);
                print(
                    '발견된 기기: ${result.device.name} - ${result.device.address}');
              }
              _updateNearbyUsers();
            });
          },
          onDone: () {
            setState(() {
              _isDiscovering = false;
            });
          },
          onError: (error) {
            print('블루투스 검색 리스너 오류: $error');
            setState(() {
              _isDiscovering = false;
            });
          },
        );

        // 60초 후 검색 종료
        await Future.delayed(const Duration(seconds: 60));
        if (_streamSubscription != null) {
          _streamSubscription!.cancel();
          setState(() {
            _isDiscovering = false;
          });
        }
      } catch (e) {
        print('블루투스 검색 시작 중 오류: $e');
        setState(() {
          _isDiscovering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('블루투스 검색 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('블루투스 검색 중 오류 발생: $e');
      setState(() {
        _isDiscovering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('블루투스 오류: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 블루투스로 발견된 기기와 사용자 정보 매칭
  void _updateNearbyUsers() {
    final usersProvider =
        Provider.of<UsersInfoProvider>(context, listen: false);
    final allUsers = usersProvider.users ?? [];

    setState(() {
      _nearbyUsers = allUsers.where((user) {
        String? deviceId = user.deviceId;
        // deviceId가 null이 아니고, 발견된 블루투스 기기 중에 일치하는 것이 있으면 추가
        return deviceId != null &&
            _results.any((result) =>
                result.device.address == deviceId ||
                result.device.name == deviceId);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = Provider.of<UsersInfoProvider>(context);

    // 로딩 중이면 로딩 인디케이터 표시
    if (usersProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('주변 사람 찾는중..'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFFFEF7FF),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: const Color(0xFFFEF7FF),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 사람 찾는중..'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFEF7FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 블루투스 검색 다시 시작 버튼
          IconButton(
            icon: Icon(
                _isDiscovering ? Icons.bluetooth_searching : Icons.bluetooth),
            onPressed: _isDiscovering ? null : _startDiscovery,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFFEF7FF),
          child: Column(
            children: [
              // 검색 상태 표시
              if (_isDiscovering)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('블루투스로 주변 사용자를 검색 중...'),
                    ],
                  ),
                ),

              // 발견된 사용자가 없을 경우
              if (_nearbyUsers.isEmpty && !_isDiscovering)
                const Expanded(
                  child: Center(
                    child: Text(
                      '주변에 사용자가 없습니다.\n블루투스를 활성화하고 다시 시도해보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              // 발견된 사용자 목록
              Expanded(
                child: GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _nearbyUsers.length,
                  itemBuilder: (context, index) {
                    final student = _nearbyUsers[index];
                    final String studentName = student.username ?? '이름없음';
                    final int userId = student.userId ?? 0;
                    final String myName =
                        usersProvider.userInfo?.username ?? '';
                    final int myUserId = usersProvider.userInfo?.userId ?? 0;
                    final String? profileImage = student.profileImageUrl;

                    return _buildStudentItem(
                      context,
                      myName,
                      myUserId,
                      studentName,
                      userId,
                      profileImage,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 학생 아이콘, 이름, 탭 시 이벤트 처리
  Widget _buildStudentItem(
    BuildContext context,
    String myName,
    int myUserId,
    String otherName,
    int otherUserId,
    String? profileImageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WinLoseSelect(
                otherName: otherName,
                otherId: otherUserId,
                myName: myName,
                myId: myUserId,
              ),
            ),
          );
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 프로필 이미지 또는 기본 아이콘
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_outline,
                        size: 60,
                        color: Colors.black54,
                      ),
                    )
                  : const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: Colors.black54,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            otherName,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
