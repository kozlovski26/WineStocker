import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../wine_collection/domain/models/wine_bottle.dart';
import '../../../core/models/wine_type.dart';

class GeminiService {
  final String apiKey;
  final String modelName;
  
  GeminiService({
    required this.apiKey, 
    this.modelName = 'gemini-2.0-flash', // Default to 1.5 Pro
  });
  
  Future<WineBottle?> analyzeWineImage(File imageFile) async {
    try {
      if (apiKey.isEmpty) {
        debugPrint('Empty API key provided');
        return null;
      }
      
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.4,
          topK: 32,
          topP: 0.95,
          maxOutputTokens: 4096,
        ),
      );

      // Read the image bytes and convert to Uint8List
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      try {
        // Create a chat session with Gemini using the improved prompt
        final chat = model.startChat(history: [
          Content.multi([
            TextPart('''You are a highly skilled AI assistant specializing in analyzing wine images and extracting key information. Your task is to examine an image of a wine bottle and return a JSON object containing the following details. It is CRUCIAL that your output adheres strictly to the specified JSON format. If you cannot confidently determine a value, use `null` for that field. Do NOT include any surrounding text or conversational elements in your output; ONLY the JSON.

**Desired JSON Structure:**

```json
{
  "name": "Wine Name (e.g., Chateau Margaux)",
  "winery": "Winery Name (e.g., Antinori)",
  "year": "Vintage Year (e.g., 2018), or null if not visible",
  "grapes": ["Grape Variety 1", "Grape Variety 2", ...],
  "color": "Wine Color (e.g., red, white, rosé, sparkling, dessert)",
  "country": "Country of Origin (e.g., France, Italy, USA)",
  "price": "Estimated Price (numeric value only, e.g., 45.99 or null)",
  "currency": "Currency code (USD, ILS, EUR, GBP, or JPY)"
}
```

**Instructions:**

1. **Image Analysis:** Analyze the provided wine bottle image for labels, text, and any other visual cues that provide information about the wine.

2. **Field Extraction:** Extract the requested fields (name, winery, year, grapes, color, country, price, currency) from the image. Prioritize information from the label, but also consider other visual elements.

3. **Grapes:** Identify the grape varietals used in the wine. For grapes, make educated guesses based on the wine's region, type, and other context clues, even if not explicitly shown on the label. Return an array of strings for each grape variety. For example, if you see a Bordeaux red wine, you can include ["Cabernet Sauvignon", "Merlot", "Cabernet Franc"] as these are typical Bordeaux grape varieties. If you absolutely cannot determine grape varieties, set the value to `null`.

4. **Color:** Determine the wine color based on the liquid's appearance in the image. Provide a general color description (e.g., red, white, rosé, sparkling, dessert).

5. **Year:** Extract the vintage year from the label. If no year is visible, use `null`.

6. **Country of Origin:** 
   - Only specify the country if you can confidently determine it from the label or if the winery is clearly from a specific country.
   - For example: Antinori (Italy), Opus One (USA), Chateau Margaux (France), etc.
   - If you cannot determine the country with confidence, use `null`. Do NOT guess the country based on other factors.
   - Be especially careful with these well-known wine regions and their countries:
     - Zyme, Antinori, Barolo, Chianti, Brunello → Italy
     - Bordeaux, Burgundy, Champagne → France
     - Rioja, Ribera del Duero → Spain
     - Napa Valley, Sonoma → USA
     - Barossa Valley, Margaret River → Australia
     - Mosel, Rheingau → Germany
     - Douro, Dao → Portugal
     - Golan Heights, Judean Hills → Israel

7. **Price and Currency:** 
   - Provide an *estimated* price of the wine if possible.
   - The price MUST be a numeric value only, with no currency symbols or formatting (e.g., 25.50). 
   - Add a "currency" field with the appropriate currency code based on the country or visible price information:
     - For Israeli wines, use "ILS" (Israeli Shekel)
     - For European wines, use "EUR" (Euro)
     - For UK wines, use "GBP" (British Pound)
     - For US wines, use "USD" (US Dollar)
     - For Japanese wines, use "JPY" (Japanese Yen)
     - For other regions or if country is null, use `null` for currency
   - If you cannot estimate the price, use `null` for both price and currency.

8. **IMPORTANT: Accuracy Over Completeness**: It is better to return `null` for fields you cannot confidently determine than to provide incorrect information. Never guess the country or winery if not clearly indicated.

9. **JSON Output:** Construct a JSON object matching the EXACT structure provided above. Ensure that the JSON is valid and contains ONLY the JSON object itself. No extra text, explanations, or conversational elements.''')
          ]),
          Content.model([
            TextPart('I will analyze the wine image according to your specifications. I\'ll return a valid JSON object with all the requested fields in the exact format specified. I\'ll be particularly careful about country identification, using null if I cannot confidently determine it. For currency, I\'ll match it to the country when known, and use null otherwise. My response will contain only the JSON object without any surrounding text or explanations.')
          ]),
        ]);

        // Send the image to Gemini
        final content = Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart('Please analyze this wine image and respond with ONLY the JSON object containing the details. Remember to only specify the country if you can confidently determine it from the label or winery name - use null if uncertain. For grape varieties, make educated guesses based on the wine\'s region and style if appropriate.'),
        ]);

        // Get the response from Gemini
        final response = await chat.sendMessage(content);
        final responseText = response.text ?? '';
        
        debugPrint('Gemini response using model $modelName: $responseText');
        
        // Extract JSON from the response text
        final jsonString = _extractJsonFromText(responseText);
        if (jsonString != null) {
          debugPrint('Extracted JSON: $jsonString');
          return _parseWineBottleFromJson(jsonString);
        } else {
          debugPrint('Failed to extract JSON from response');
        }
      } catch (apiError) {
        debugPrint('Gemini API error with model $modelName: $apiError');
        // Create a basic wine bottle with no data to allow the process to continue
        return WineBottle();
      }
      
      return null;
    } catch (e) {
      debugPrint('Error analyzing wine image: $e');
      return null;
    }
  }
  
  String? _extractJsonFromText(String text) {
    // Regular expression to find JSON content within markdown code blocks
    final jsonRegex = RegExp(r'```(?:json)?\s*({[\s\S]*?})\s*```');
    final jsonMatch = jsonRegex.firstMatch(text);
    
    if (jsonMatch != null && jsonMatch.groupCount >= 1) {
      return jsonMatch.group(1)?.trim();
    }
    
    // If no JSON found in code blocks, try to find any JSON object in the text
    final fallbackRegex = RegExp(r'{[\s\S]*?}');
    final fallbackMatch = fallbackRegex.firstMatch(text);
    
    if (fallbackMatch != null) {
      return fallbackMatch.group(0)?.trim();
    }
    
    return null;
  }
  
  WineBottle _parseWineBottleFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Map color string to WineType enum
      WineType? wineType;
      if (data['color'] != null) {
        switch (data['color'].toString().toLowerCase()) {
          case 'red':
            wineType = WineType.red;
            break;
          case 'white':
            wineType = WineType.white;
            break;
          case 'rose':
          case 'rosé':
            wineType = WineType.rose;
            break;
          case 'sparkling':
            wineType = WineType.sparkling;
            break;
          case 'dessert':
            wineType = WineType.dessert;
            break;
        }
      }
      
      // Extract grape types as a comma-separated string for notes
      String? grapesInfo;
      if (data['grapes'] != null && data['grapes'] is List) {
        final grapesList = List<String>.from(data['grapes']);
        if (grapesList.isNotEmpty) {
          grapesInfo = 'Grape varieties: ${grapesList.join(', ')}';
        }
      }
      
      // Handle price - try multiple approaches to extract numeric value
      double? priceValue;
      if (data['price'] != null) {
        if (data['price'] is num) {
          priceValue = (data['price'] as num).toDouble();
        } else {
          // Try to extract numeric value from string
          final priceStr = data['price'].toString().replaceAll(RegExp(r'[^\d.,]'), '');
          try {
            priceValue = double.parse(priceStr.replaceAll(',', '.'));
          } catch (e) {
            debugPrint('Could not parse price: $e');
          }
        }
      }
      
      // Handle currency information
      String? currencyInfo = data['currency'];
      
      // Only default to ILS if we're confident the wine is from Israel
      if (data['country'] == 'Israel' && currencyInfo == null) {
        currencyInfo = 'ILS'; // Default to ILS for Israeli wines if not specified
      }
      
      // We no longer add price information to notes, as it's shown separately in the UI
      // Just keep grape information in notes
      
      return WineBottle(
        name: data['name'],
        winery: data['winery'],
        year: data['year']?.toString(),
        notes: grapesInfo,
        country: data['country'],
        type: wineType,
        price: priceValue,
        dateAdded: DateTime.now(),
        // Add any extra metadata as needed
        metadata: {'currency': currencyInfo},
      );
    } catch (e) {
      debugPrint('Error parsing wine bottle from JSON: $e');
      return WineBottle();
    }
  }
} 



