import 'package:bbeta/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? user;
  final bool needsVerification;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.needsVerification = false,
  });
}

class AuthService {
  final ApiService _api = ApiService();

  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final response = await _api.register(email, password);
      if (response.statusCode == 201) {
        return AuthResult(
          success: true,
          needsVerification: true,
          message: response.data['message'] ?? 'Check your email for a verification code.',
        );
      }
      return AuthResult(success: false, message: 'Registration failed');
    } on DioException catch (e) {
      final error = _extractError(e);
      print('⚠️ [Auth] SignUp Error: $error');
      print('⚠️ [Auth] Response Status: ${e.response?.statusCode}');
      print('⚠️ [Auth] Response Data: ${e.response?.data}');
      return AuthResult(
        success: false,
        message: error,
      );
    } catch (e) {
      print('⚠️ [Auth] SignUp Unexpected Error: $e');
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  Future<AuthResult> verifyEmail(String code) async {
    try {
      final response = await _api.verifyEmail(code);
      if (response.statusCode == 200) {
        await _api.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );
        return AuthResult(
          success: true,
          user: response.data['user'],
          message: 'Email verified!',
        );
      }
      return AuthResult(success: false, message: 'Verification failed');
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: _extractError(e),
      );
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _api.login(email, password);
      if (response.statusCode == 200) {
        await _api.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );
        print('✅ [Auth] Login successful for $email');
        return AuthResult(
          success: true,
          user: response.data['user'],
        );
      }
      print('⚠️ [Auth] Login returned non-200 status: ${response.statusCode}');
      return AuthResult(success: false, message: 'Login failed');
    } on DioException catch (e) {
      final error = _extractError(e);
      print('⚠️ [Auth] Login Error: $error');
      print('⚠️ [Auth] Response Status: ${e.response?.statusCode}');
      print('⚠️ [Auth] Response Data: ${e.response?.data}');
      return AuthResult(
        success: false,
        message: error,
      );
    } catch (e) {
      print('⚠️ [Auth] Login Unexpected Error: $e');
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
      if (googleUser == null) {
        return AuthResult(success: false, message: 'Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return AuthResult(success: false, message: 'Failed to get Google token');
      }

      final response = await _api.googleAuth(idToken);
      if (response.statusCode == 200) {
        await _api.saveTokens(
          response.data['access'],
          response.data['refresh'],
        );
        return AuthResult(
          success: true,
          user: response.data['user'],
        );
      }
      return AuthResult(success: false, message: 'Google sign-in failed');
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: _extractError(e),
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Google sign-in failed');
    }
  }

  Future<void> logout() async {
    await _api.logout();
    await GoogleSignIn().signOut();
  }

  Future<bool> isLoggedIn() => _api.isLoggedIn();

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _api.getProfile();
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (_) {}
    return null;
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    print('🔍 [Auth] Error Response Data: $data');
    print('🔍 [Auth] Error Type: ${e.type}');
    print('🔍 [Auth] Error Message: ${e.message}');
    
    if (data is Map) {
      // Check for standard error field names
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      
      // Check for field-specific errors (serializer validation errors)
      for (final key in data.keys) {
        final value = data[key];
        if (value is List && value.isNotEmpty) {
          return '${key.toString().replaceAll('_', ' ')}: ${value.first}';
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    
    // Fallback: use the error message or DioException message
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    
    return 'Connection error. Please check if the backend is running.';
  }
}
