import 'package:test/test.dart';
import 'package:shared_models/models.dart';

void main() {
  group('Shared Models Tests', () {
    test('Team JSON serialization test', () {
      final team = Team(id: 1, name: 'Alpha');
      final json = team.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Alpha');

      final deserialized = Team.fromJson(json);
      expect(deserialized.id, 1);
      expect(deserialized.name, 'Alpha');
    });

    test('Member JSON serialization test', () {
      final member = Member(id: 10, teamId: 1, name: 'John');
      final json = member.toJson();
      expect(json['id'], 10);
      expect(json['teamId'], 1);
      expect(json['name'], 'John');

      final deserialized = Member.fromJson(json);
      expect(deserialized.id, 10);
      expect(deserialized.teamId, 1);
      expect(deserialized.name, 'John');
    });
  });
}
