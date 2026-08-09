/// The single exception type used throughout the app.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
}