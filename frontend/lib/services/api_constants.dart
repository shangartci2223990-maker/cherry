// This file stores the base URL of our backend.
// Change this one place if the URL ever changes.

class ApiConstants {
  // Your FastAPI backend running locally.
  // When you deploy to a real server this is the only line that changes.
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String wsUrl = 'ws://10.0.2.2:8000';
}
