import 'package:flutter_test/flutter_test.dart';
import 'package:bbeta/models/user.dart';

void main() {
  group('User Model', () {
    test('fromJson creates User correctly', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'email_verified': true,
        'username': 'testuser',
        'first_name': 'John',
        'last_name': 'Doe',
        'role': 'USER',
        'is_active': true,
        'is_staff': false,
        'created_at': '2024-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.emailVerified, true);
      expect(user.username, 'testuser');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.role, 'USER');
      expect(user.isActive, true);
      expect(user.isStaff, false);
    });

    test('displayName returns firstName when available', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        emailVerified: true,
        firstName: 'John',
        username: 'testuser',
        role: 'USER',
        isActive: true,
        isStaff: false,
        createdAt: DateTime.now(),
      );

      expect(user.displayName, 'John');
    });

    test('displayName returns username when firstName is empty', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        emailVerified: true,
        firstName: '',
        username: 'testuser',
        role: 'USER',
        isActive: true,
        isStaff: false,
        createdAt: DateTime.now(),
      );

      expect(user.displayName, 'testuser');
    });

    test('displayName returns email prefix when both firstName and username are empty', () {
      final user = User(
        id: 1,
        email: 'john.doe@example.com',
        emailVerified: true,
        firstName: '',
        username: '',
        role: 'USER',
        isActive: true,
        isStaff: false,
        createdAt: DateTime.now(),
      );

      expect(user.displayName, 'john.doe');
    });

    test('fullName combines firstName and lastName', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        emailVerified: true,
        firstName: 'John',
        lastName: 'Doe',
        role: 'USER',
        isActive: true,
        isStaff: false,
        createdAt: DateTime.now(),
      );

      expect(user.fullName, 'John Doe');
    });

    test('toJson creates correct map', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        emailVerified: true,
        username: 'testuser',
        firstName: 'John',
        lastName: 'Doe',
        role: 'USER',
        isActive: true,
        isStaff: false,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['email'], 'test@example.com');
      expect(json['email_verified'], true);
      expect(json['username'], 'testuser');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
    });
  });
}
