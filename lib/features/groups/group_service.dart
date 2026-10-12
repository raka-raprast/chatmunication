import 'dart:convert';

import 'package:chatmunication/features/groups/group.dart';
import 'package:chatmunication/features/users/user.dart';
import 'package:chatmunication/shared/config/app_config.dart';
import 'package:http/http.dart' as http;

class GroupService {
  final String baseUrl;
  final String token;

  GroupService({required this.token, String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Creates a group with the given name and initial member ids (the
  /// caller is added automatically server-side).
  Future<Group> createGroup(String name, List<String> memberIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'member_ids': memberIds}),
    );

    if (response.statusCode == 201) {
      return Group.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create group: ${response.statusCode}');
    }
  }

  Future<List<GroupWithLastMessage>> getUserGroups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GroupWithLastMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load groups');
    }
  }

  Future<List<GroupChatMessage>> getGroupMessages(String groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GroupChatMessage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load group messages');
    }
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GroupMember.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load group members');
    }
  }

  /// Users invited to this group who haven't accepted yet — shown
  /// alongside actual members so inviters can see who's still pending.
  Future<List<User>> getPendingInvitees(String groupId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/$groupId/pending-invites'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending invitees');
    }
  }

  Future<void> addMembers(String groupId, List<String> memberIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/$groupId/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'member_ids': memberIds}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add members: ${response.statusCode}');
    }
  }

  /// Removes [userId] from the group. Removing yourself is "leave group";
  /// removing someone else requires being the group's creator (enforced
  /// server-side).
  Future<void> removeMember(String groupId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/groups/$groupId/members/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove member: ${response.statusCode}');
    }
  }

  Future<void> markGroupRead(String groupId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/groups/$groupId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark group read: ${response.statusCode}');
    }
  }

  /// Pending group invites for the authenticated user.
  Future<List<GroupInvite>> getGroupInvites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/groups/invites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load group invites');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((json) => GroupInvite.fromJson(json)).toList();
  }

  Future<void> acceptGroupInvite(String inviteId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/invites/$inviteId/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to accept group invite');
    }
  }

  Future<void> declineGroupInvite(String inviteId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/groups/invites/$inviteId/decline'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to decline group invite');
    }
  }
}
