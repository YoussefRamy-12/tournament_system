class Team {
  final int id;
  final String name;
  // final List<Member> members;

  Team({required this.id, required this.name /*required this.members*/});
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // 'members': members.map((m) => m.id).toList(),
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(id: json['id'], name: json['name'] /*members: []*/);
  }
}

class Member {
  final int id;
  final int teamId;
  final String name;

  Member({required this.id, required this.name, required this.teamId});
  Map<String, dynamic> toJson() => {'id': id, 'teamId': teamId, 'name': name};
  factory Member.fromJson(Map<String, dynamic> json) =>
      Member(id: json['id'], teamId: json['team_id'], name: json['name']);
}

class Leader {
  final String id;
  final String name;
  final String deviceInfo;
  final String status; // PENDING, APPROVED, REJECTED

  Leader({
    required this.id,
    required this.name,
    required this.deviceInfo,
    this.status = 'PENDING',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deviceInfo': deviceInfo,
    'status': status,
  };

  factory Leader.fromJson(Map<String, dynamic> json) => Leader(
    id: json['id'],
    name: json['name'],
    deviceInfo: json['deviceInfo'] ?? '',
    status: json['status'] ?? 'PENDING',
  );
}

class ScoreTransaction {
  final String id;
  final String leaderId;
  final int memberId;
  final int points;
  final String tag;
  final String status;
  final String description;
  final DateTime timestamp;

  ScoreTransaction({
    required this.id,
    required this.memberId,
    required this.leaderId,
    required this.points,
    required this.timestamp,
    required this.tag,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': memberId,
    'points': points,
    'tag': tag,
    'status': status,
    'description': description,
    'leaderId': leaderId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ScoreTransaction.fromJson(Map<String, dynamic> json) =>
      ScoreTransaction(
        id: json['id'],
        memberId: json['targetId'],
        leaderId: json['leader_id'],
        points: json['points'],
        tag: json['tag'],
        status: json['status'],
        description: json['description'] ?? 'No description',
        timestamp: DateTime.parse(json['timestamp']),
      );
}
