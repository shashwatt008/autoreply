import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/page_model.dart';
import '../models/post_model.dart';
import '../models/automation_model.dart';
import '../models/instagram_account_model.dart';

class ApiService {
  static final String baseUrl = AppConstants.apiBaseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth ───

  static Future<UserModel?> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['user'] ?? data;
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Facebook Pages ───

  static Future<List<PageModel>> getPages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pages'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data is List ? data : (data['pages'] ?? data['data'] ?? []);
        return (pages as List).map((p) => PageModel.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Facebook Posts ───

  static Future<List<PostModel>> getPosts(String pageId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$pageId/posts'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final posts = data is List ? data : (data['posts'] ?? data['data'] ?? []);
        return (posts as List).map((p) => PostModel.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Instagram Accounts ───

  static Future<List<InstagramAccountModel>> getInstagramAccounts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instagram'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accounts = data is List ? data : (data['accounts'] ?? data['data'] ?? []);
        return (accounts as List).map((a) => InstagramAccountModel.fromJson(a)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Instagram Media ───

  static Future<List<PostModel>> getInstagramMedia(String accountId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instagram/$accountId/media'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final media = data is List ? data : (data['media'] ?? data['data'] ?? []);
        return (media as List).map((m) => PostModel.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Automation Rules ───

  static Future<int> getRuleCount({required String platform}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/automation?platform=$platform'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rules = data is List ? data : (data['rules'] ?? data['data'] ?? []);
        return (rules as List).where((r) => r['is_active'] == true).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<List<AutomationModel>> getAutomationRules({
    required String pageId,
    String? platform,
  }) async {
    try {
      String url = '$baseUrl/automation?pageId=$pageId';
      if (platform != null) url += '&platform=$platform';
      final response = await http.get(
        Uri.parse(url),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rules = data is List ? data : (data['rules'] ?? data['data'] ?? []);
        return (rules as List).map((r) => AutomationModel.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<AutomationModel?> createAutomationRule(AutomationModel rule) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/automation'),
        headers: await _headers(),
        body: json.encode(rule.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final ruleData = data['rule'] ?? data;
        return AutomationModel.fromJson(ruleData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateAutomationRule(String id, Map<String, dynamic> updates) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/automation/$id'),
        headers: await _headers(),
        body: json.encode(updates),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAutomationRule(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/automation/$id'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── Bulk Reply ───

  static Future<List<dynamic>> fetchComments(String postId, String platform, {String? pageId, String? accountId}) async {
    try {
      final params = <String, String>{'platform': platform};
      if (pageId != null) params['pageId'] = pageId;
      if (accountId != null) params['accountId'] = accountId;
      final uri = Uri.parse('$baseUrl/bulk-reply/comments/$postId').replace(queryParameters: params);
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : (data['comments'] ?? data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> startBulkReply(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bulk-reply/start'),
        headers: await _headers(),
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getBulkReplyJobs({String? platform}) async {
    try {
      final uri = platform != null
          ? Uri.parse('$baseUrl/bulk-reply/jobs?platform=$platform')
          : Uri.parse('$baseUrl/bulk-reply/jobs');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is List ? data : (data['jobs'] ?? data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bulk-reply/jobs/$jobId'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> pauseJob(String jobId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bulk-reply/jobs/$jobId/pause'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resumeJob(String jobId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bulk-reply/jobs/$jobId/resume'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ─── Payment ───

  static Future<Map<String, dynamic>?> createOrder() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/create-order'),
        headers: await _headers(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> verifyPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/verify'),
        headers: await _headers(),
        body: json.encode(paymentData),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
