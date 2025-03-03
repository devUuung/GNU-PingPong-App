import 'package:flutter/material.dart';
import '../api_config.dart';
import '../models/index.dart';
import 'api_client.dart';

/// 게시물 관련 API 요청을 처리하는 서비스 클래스
class PostService {
  final ApiClient _apiClient = ApiClient();

  /// 모든 게시물 정보를 가져오는 메서드
  Future<List<Post>> getAllPosts() async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/posts/all');

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> postsData = response['data'];
        return postsData.map((post) => Post.fromJson(post)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('게시물 정보를 가져오는 중 오류 발생: $e');
      return [];
    }
  }

  /// 특정 게시물 정보를 가져오는 메서드
  Future<Post?> getPostById(int postId) async {
    try {
      final response =
          await _apiClient.get('${ApiConfig.baseUrl}/posts/$postId');

      if (response['success'] == true && response['post'] != null) {
        return Post.fromJson(response['post']);
      }

      return null;
    } catch (e) {
      debugPrint('게시물 정보를 가져오는 중 오류 발생: $e');
      return null;
    }
  }

  /// 새로운 게시물을 생성하는 메서드
  Future<Post?> createPost(String title, String content, int maxParticipants,
      DateTime meetingTime) async {
    try {
      final postRequest = PostCreateRequest(
        title: title,
        content: content,
        maxParticipants: maxParticipants,
        meetingTime: meetingTime,
      );

      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/posts/create',
        body: postRequest.toJson(),
      );

      if (response['success'] == true && response['post_id'] != null) {
        final postId = response['post_id'];
        return await getPostById(postId);
      }

      return null;
    } catch (e) {
      debugPrint('게시물을 생성하는 중 오류 발생: $e');
      return null;
    }
  }

  /// 게시물에 참가하는 메서드
  Future<bool> participatePost(int postId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/posts/participate',
        body: {'post_id': postId},
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('게시물에 참가하는 중 오류 발생: $e');
      return false;
    }
  }
}
