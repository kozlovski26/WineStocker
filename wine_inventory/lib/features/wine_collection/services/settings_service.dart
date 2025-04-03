import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  
  // Save the Gemini API key to shared preferences
  Future<bool> saveGeminiApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_geminiApiKeyKey, apiKey);
    } catch (e) {
      print('Error saving Gemini API key: $e');
      return false;
    }
  }
  
  // Get the Gemini API key from shared preferences
  Future<String?> getGeminiApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_geminiApiKeyKey);
    } catch (e) {
      print('Error getting Gemini API key: $e');
      return null;
    }
  }
  
  // Check if the Gemini API key is set
  Future<bool> isGeminiApiKeySet() async {
    final apiKey = await getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  // Remove the Gemini API key from shared preferences
  Future<bool> removeGeminiApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_geminiApiKeyKey);
    } catch (e) {
      print('Error removing Gemini API key: $e');
      return false;
    }
  }
} 