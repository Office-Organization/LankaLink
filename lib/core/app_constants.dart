/// Firestore collection and field names.
/// Typing a collection name by hand is a bug waiting to happen.
abstract final class Db {
  static const users = 'users';
  static const voters = 'voters_2024';
  static const surveys = 'survey_responses';
}

/// Route names used with Navigator.pushNamed.
abstract final class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const survey = '/survey';
  static const gnDetails = '/gn-details';
}

/// Field names commonly used.
abstract final class Fields {
  static const nic = 'nic';
  static const fullName = 'fullName';
  static const email = 'email';
  static const status = 'status';
  static const houseNumber = 'House_Number';
  static const name = 'Name';
  static const gender = 'Gender';
}