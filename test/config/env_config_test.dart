import 'package:flutter_test/flutter_test.dart';
import 'package:bbeta/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    tearDown(() {
      EnvConfig.setEnvironment(Environment.production);
    });

    test('default environment is production', () {
      expect(EnvConfig.environment, Environment.production);
      expect(EnvConfig.isProduction, true);
      expect(EnvConfig.isDevelopment, false);
      expect(EnvConfig.isStaging, false);
    });

    test('can switch to development environment', () {
      EnvConfig.setEnvironment(Environment.development);

      expect(EnvConfig.environment, Environment.development);
      expect(EnvConfig.isDevelopment, true);
      expect(EnvConfig.isProduction, false);
    });

    test('can switch to staging environment', () {
      EnvConfig.setEnvironment(Environment.staging);

      expect(EnvConfig.environment, Environment.staging);
      expect(EnvConfig.isStaging, true);
      expect(EnvConfig.isProduction, false);
    });

    test('apiBaseUrl returns correct URL for production', () {
      EnvConfig.setEnvironment(Environment.production);

      expect(EnvConfig.apiBaseUrl, 'https://bud-ruby.vercel.app/api');
    });

    test('apiBaseUrl returns correct URL for development', () {
      EnvConfig.setEnvironment(Environment.development);

      expect(EnvConfig.apiBaseUrl, 'http://10.0.2.2:8000/api');
    });

    test('enableLogging is false for production', () {
      EnvConfig.setEnvironment(Environment.production);

      expect(EnvConfig.enableLogging, false);
    });

    test('enableLogging is true for development', () {
      EnvConfig.setEnvironment(Environment.development);

      expect(EnvConfig.enableLogging, true);
    });

    test('enableLogging is true for staging', () {
      EnvConfig.setEnvironment(Environment.staging);

      expect(EnvConfig.enableLogging, true);
    });

    test('quotesApiUrl is constant across environments', () {
      expect(EnvConfig.quotesApiUrl, 'https://zenquotes.io/api/quotes');

      EnvConfig.setEnvironment(Environment.development);
      expect(EnvConfig.quotesApiUrl, 'https://zenquotes.io/api/quotes');

      EnvConfig.setEnvironment(Environment.staging);
      expect(EnvConfig.quotesApiUrl, 'https://zenquotes.io/api/quotes');
    });

    test('toMap returns all config values', () {
      EnvConfig.setEnvironment(Environment.production);

      final map = EnvConfig.toMap();

      expect(map['environment'], 'production');
      expect(map['apiBaseUrl'], 'https://bud-ruby.vercel.app/api');
      expect(map['enableLogging'], 'false');
    });

    test('connectTimeout is 30 seconds', () {
      expect(EnvConfig.connectTimeout, const Duration(seconds: 30));
    });

    test('receiveTimeout is 30 seconds', () {
      expect(EnvConfig.receiveTimeout, const Duration(seconds: 30));
    });
  });
}
