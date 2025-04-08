// import 'package:flutter_test/flutter_test.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../mocks/mock_supabase_client.dart';

// void main() {
//   late MockSupabaseClient mockSupabaseClient;

//   setUp(() {
//     mockSupabaseClient = MockSupabaseClient();
//   });

//   group('Authentication Tests', () {
//     test('로그인 성공 테스트', () async {
//       final response = await mockSupabaseClient.auth.signInWithPassword(
//         email: 'test@gnu.ac.kr',
//         password: 'password123',
//       );

//       expect(response.user, isNotNull);
//       expect(response.session, isNotNull);
//       expect(response.user?.email, equals('test@gnu.ac.kr'));
//     });

//     test('로그인 실패 테스트', () async {
//       expect(
//         () => mockSupabaseClient.auth.signInWithPassword(
//           email: 'wrong@gnu.ac.kr',
//           password: 'wrongpassword',
//         ),
//         throwsA(isA<AuthException>()),
//       );
//     });

//     test('로그아웃 테스트', () async {
//       // 먼저 로그인
//       await mockSupabaseClient.auth.signInWithPassword(
//         email: 'test@gnu.ac.kr',
//         password: 'password123',
//       );

//       expect(mockSupabaseClient.auth.currentUser, isNotNull);

//       // 로그아웃
//       await mockSupabaseClient.auth.signOut();

//       expect(mockSupabaseClient.auth.currentUser, isNull);
//       expect(mockSupabaseClient.auth.currentSession, isNull);
//     });
//   });
// }
