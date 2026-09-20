
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';

class ApiService {
  static const String baseUrl = 
  'http://192.168.1.5:8000';

  
  // =====================================================
  // LOGIN
  // =====================================================

  static Future<Map<String, dynamic>> login(
  String email,
  String password,
) async {
  final url = '$baseUrl/api/login/';

  print('LOGIN URL: $url');

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  print('LOGIN STATUS: ${response.statusCode}');
  print('LOGIN RESPONSE: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'access_token',
      data['access'],
    );

    await prefs.setString(
      'refresh_token',
      data['refresh'],
    );

    return data;
  }

  throw Exception(
    'Status: ${response.statusCode}\n'
    'Response: ${response.body}',
  );
}

  // =====================================================
  // GET ACCESS TOKEN
  // =====================================================

  static Future<String?> getAccessToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('access_token');
  }

  // =====================================================
  // GET REFRESH TOKEN
  // =====================================================

  static Future<String?> getRefreshToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('refresh_token');
  }

  // =====================================================
  // REFRESH ACCESS TOKEN
  // =====================================================

  static Future<bool> refreshAccessToken() async {
    final refreshToken =
        await getRefreshToken();

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data =
          jsonDecode(response.body);

      final newAccessToken =
          data['access'];

      if (newAccessToken == null) {
        return false;
      }

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'access_token',
        newAccessToken,
      );

      return true;
    } catch (e) {
      print(
        'Refresh token error: $e',
      );

      return false;
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'access_token',
    );

    await prefs.remove(
      'refresh_token',
    );
  }

  // =====================================================
  // AUTHENTICATED GET
  // =====================================================

  static Future<http.Response> authenticatedGet(
    String endpoint,
  ) async {
    String? token =
        await getAccessToken();

    if (token == null) {
      throw Exception(
        'No access token found.',
      );
    }

    http.Response response =
        await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
    );

    // Access token expired
    if (response.statusCode == 401) {
      final refreshed =
          await refreshAccessToken();

      if (!refreshed) {
        throw Exception(
          'Session expired. Please login again.',
        );
      }

      token =
          await getAccessToken();

      response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      );
    }

    return response;
  }

  // =====================================================
  // AUTHENTICATED POST
  // =====================================================

  static Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    String? token =
        await getAccessToken();

    if (token == null) {
      throw Exception(
        'No access token found.',
      );
    }

    http.Response response =
        await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode(body),
    );

    // Access token expired
    if (response.statusCode == 401) {
      final refreshed =
          await refreshAccessToken();

      if (!refreshed) {
        throw Exception(
          'Session expired. Please login again.',
        );
      }

      token =
          await getAccessToken();

      response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode(body),
      );
    }

    return response;
  }

  // =====================================================
  // GET PROFILE
  // =====================================================

  static Future<Map<String, dynamic>> getProfile() async {
    final response =
        await authenticatedGet(
      '/api/profile/',
    );

    final data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }

  // =====================================================
  // REGISTER
  // =====================================================

  static Future<void> register(
  String username,
  String email,
  String password,
  String role,
  String? parentEmail,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/register/'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      if (parentEmail != null && parentEmail.isNotEmpty)
        'parent_email': parentEmail,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception(
      'Registration failed.\n'
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }
}
  // =====================================================
  // IS LOGGED IN
  // =====================================================

  static Future<bool> isLoggedIn() async {
    final token =
        await getAccessToken();

    return token != null &&
        token.isNotEmpty;
  }

  // =====================================================
  // GET FAMILY MEMBERS
  // =====================================================

  static Future<List<dynamic>>
      getFamilyMembers() async {
    final response =
        await authenticatedGet(
      '/api/family-members/',
    );

    final data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }

  // =====================================================
  // GET ALERTS
  // =====================================================

  static Future<List<Alert>>
      getAlerts() async {
    final response =
        await authenticatedGet(
      '/api/alerts/',
    );

    final data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List)
          .map(
            (json) =>
                Alert.fromJson(json),
          )
          .toList();
    }

    throw Exception(
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }

  // =====================================================
  // GET ALL LOCATIONS
  // =====================================================

  static Future<List<dynamic>>
      getLocations() async {
    final response =
        await authenticatedGet(
      '/api/locations/',
    );

    final data =
        jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }

  // =====================================================
  // SEND NEW LOCATION
  // =====================================================


static Future<Map<String, dynamic>> sendLocation(
  double latitude,
  double longitude,
) async {
  final response = await authenticatedPost(
    '/api/locations/',
    {
      'latitude': latitude,
      'longitude': longitude,
    },
  );

  print('=================================');
  print('LOCATION STATUS: ${response.statusCode}');
  print('LOCATION RESPONSE: ${response.body}');
  print('=================================');

  if (response.statusCode != 201) {
    throw Exception(
      'Location request failed.\n'
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }

  return jsonDecode(response.body);
}



  // =====================================================
  // GET LATEST LOCATION
  // =====================================================

  static Future<Map<String, dynamic>?>
      getLatestLocation(
    int familyMemberId,
  ) async {
    final response =
        await authenticatedGet(
      '/api/locations/',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    final data =
        jsonDecode(response.body);

    if (data is! List) {
      throw Exception(
        'Invalid location response.',
      );
    }

    final locations = data
        .where(
          (location) =>
              location['family_member'] ==
              familyMemberId,
        )
        .toList();

    if (locations.isEmpty) {
      return null;
    }

    return locations.first
        as Map<String, dynamic>;
  }

static Future<bool> isFamilyMember() async {

  final response = await authenticatedGet(
    '/api/role/',
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data['is_family_member'] == true;
  }

  throw Exception(
    'Status: ${response.statusCode}\n'
    'Response: ${response.body}',
  );
}

// =====================================================
// UPDATE FCM TOKEN
// =====================================================

static Future<void> updateFCMToken(String token) async {
  final response = await authenticatedPost(
    '/api/update-fcm-token/',
    {
      'fcm_token': token,
    },
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to update FCM token.\n'
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }
}

// =====================================================
// SEND HELP
// =====================================================

static Future<Map<String, dynamic>> sendHelp() async {
  final response = await authenticatedPost(
    '/api/alerts/',
    {
      'alert_type': 'assistance',
      'object_name': '',
      'message': 'Patient requested assistance.',
    },
  );

  print('=================================');
  print('HELP STATUS: ${response.statusCode}');
  print('HELP RESPONSE: ${response.body}');
  print('=================================');

  if (response.statusCode != 201) {
    throw Exception(
      'Help request failed.\n'
      'Status: ${response.statusCode}\n'
      'Response: ${response.body}',
    );
  }

  return jsonDecode(response.body);
}

// =====================================================
// GET USER ROLE
// =====================================================

static Future<String> getUserRole() async {
  final response = await authenticatedGet(
    '/api/role/',
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data['role'] as String;
  }

  throw Exception(
    'Status: ${response.statusCode}\n'
    'Response: ${response.body}',
  );
}




}

