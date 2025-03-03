/// 게시물 정보를 나타내는 모델 클래스
class Post {
  final int postId;
  final String title;
  final String content;
  final int creatorId;
  final String creatorName;
  final int maxParticipants;
  final DateTime meetingTime;
  final DateTime createdAt;
  final List<PostParticipant> participants;
  final bool isParticipant;
  final bool isCreator;

  Post({
    required this.postId,
    required this.title,
    required this.content,
    required this.creatorId,
    required this.creatorName,
    required this.maxParticipants,
    required this.meetingTime,
    required this.createdAt,
    required this.participants,
    this.isParticipant = false,
    this.isCreator = false,
  });

  /// JSON에서 Post 객체로 변환하는 팩토리 생성자
  factory Post.fromJson(Map<String, dynamic> json) {
    List<PostParticipant> participantsList = [];
    if (json['participants'] != null) {
      participantsList = (json['participants'] as List)
          .map((item) => PostParticipant.fromJson(item))
          .toList();
    }

    return Post(
      postId: json['post_id'],
      title: json['title'],
      content: json['content'],
      creatorId: json['creator_id'],
      creatorName: json['creator_name'],
      maxParticipants: json['max_participants'],
      meetingTime: json['meeting_time'] != null
          ? DateTime.parse(json['meeting_time'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      participants: participantsList,
      isParticipant: json['is_participant'] ?? false,
      isCreator: json['is_creator'] ?? false,
    );
  }

  /// Post 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'title': title,
      'content': content,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'max_participants': maxParticipants,
      'meeting_time': meetingTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'is_participant': isParticipant,
      'is_creator': isCreator,
    };
  }
}

/// 게시물 참가자 정보를 나타내는 모델 클래스
class PostParticipant {
  final int participantId;
  final int postId;
  final int userId;
  final String username;
  final DateTime joinedAt;

  PostParticipant({
    required this.participantId,
    required this.postId,
    required this.userId,
    required this.username,
    required this.joinedAt,
  });

  /// JSON에서 PostParticipant 객체로 변환하는 팩토리 생성자
  factory PostParticipant.fromJson(Map<String, dynamic> json) {
    return PostParticipant(
      participantId: json['participant_id'],
      postId: json['post_id'],
      userId: json['user_id'],
      username: json['username'],
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),
    );
  }

  /// PostParticipant 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'participant_id': participantId,
      'post_id': postId,
      'user_id': userId,
      'username': username,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

/// 게시물 생성 요청을 위한 모델 클래스
class PostCreateRequest {
  final String title;
  final String content;
  final int maxParticipants;
  final DateTime meetingTime;

  PostCreateRequest({
    required this.title,
    required this.content,
    required this.maxParticipants,
    required this.meetingTime,
  });

  /// PostCreateRequest 객체를 JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'max_participants': maxParticipants,
      'meeting_time': meetingTime.toIso8601String(),
    };
  }
}
