enum Environment { development, staging, production }

class EnvConfig {
  static Environment _environment = Environment.production;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static Environment get environment => _environment;

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://10.0.2.2:8000/api';
      case Environment.staging:
        return 'https://bud-staging.vercel.app/api';
      case Environment.production:
        return 'https://bud-ruby.vercel.app/api';
    }
  }

  static String get bookstoreBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://10.0.2.2:8000';
      case Environment.staging:
        return 'https://bookstore-staging.example.com';
      case Environment.production:
        return 'https://bookstore.example.com';
    }
  }

  static String get quotesApiUrl => 'https://zenquotes.io/api/quotes';

  static Duration get connectTimeout => const Duration(seconds: 30);
  static Duration get receiveTimeout => const Duration(seconds: 30);

  static bool get enableLogging {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }

  static Map<String, String> toMap() => {
        'environment': _environment.name,
        'apiBaseUrl': apiBaseUrl,
        'bookstoreBaseUrl': bookstoreBaseUrl,
        'enableLogging': enableLogging.toString(),
      };
}
