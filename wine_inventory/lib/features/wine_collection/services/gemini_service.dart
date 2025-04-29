import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../domain/models/wine_bottle.dart';
import '../../../core/models/wine_type.dart';

class GeminiService {
  final String apiKey;
  final String modelName;
  
  GeminiService({
    required this.apiKey, 
    this.modelName = 'gemini-1.5-flash', // Default to 1.5 Pro
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
            TextPart('''You are a highly skilled AI assistant specializing in analyzing wine images and extracting key information. You are also a wine expert with deep knowledge of wine regions, grape varieties, and wine characteristics worldwide. Your task is to examine an image of a wine bottle and return a JSON object containing the following details. It is CRUCIAL that your output adheres strictly to the specified JSON format. If you cannot confidently determine a value, use `null` for that field. Do NOT include any surrounding text or conversational elements in your output; ONLY the JSON.

**Desired JSON Structure:**

```json
{
  "name": "Wine Name (e.g., Chateau Margaux)",
  "winery": "Winery Name (e.g., Antinori)",
  "year": "Vintage Year (e.g., 2018), or null if not visible",
  "grapes": ["Grape Variety 1", "Grape Variety 2", ...],
  "color": "Wine Color (e.g., red, white, rosé, sparkling, dessert)",
  "country": "Country of Origin (e.g., France, Italy, USA)"
}
```

**Instructions:**

1. **Image Analysis:** Analyze the provided wine bottle image for labels, text, and any other visual cues that provide information about the wine.

2. **Field Extraction:** Extract the requested fields (name, winery, year, grapes, color, country) from the image. Prioritize information from the label, but also consider other visual elements.

3. **Grapes:** Use your extensive wine knowledge to identify the grape varietals used in the wine:
   - For wines where the grape variety is explicitly stated on the label, use that information.
   - For wines where grape varieties are not stated but region is known (e.g., Bordeaux, Barolo), use your knowledge of typical grape varieties for that region.
   - For example, if you see a Bordeaux red, include ["Cabernet Sauvignon", "Merlot", "Cabernet Franc"] as typical Bordeaux varieties.
   - For Barolo, you would know it's 100% Nebbiolo.
   - For Burgundy reds, typically 100% Pinot Noir.
   - Be specific and accurate - use your wine expertise to match grape varieties to regions and wine styles.
   - Return an array of strings for each grape variety.
   - If you absolutely cannot determine grape varieties, set the value to `null`.

4. **Color:** Determine the wine color based on bottle color, label information, and wine type. Provide a general color description (e.g., red, white, rosé, sparkling, dessert).

5. **Year:** Extract the vintage year from the label. If no year is visible, use `null`.

6. **Country of Origin:** 
   - Use your knowledge of wine regions to determine the country with high confidence.
   - Look for indicators like language on the label, appellation systems, etc.
   - For example: Antinori (Italy), Opus One (USA), Chateau Margaux (France), etc.
   - If you cannot determine the country with confidence, use `null`. Do NOT guess based on uncertain factors.
   - Key wine regions and their countries:
     - Zyme, Antinori, Barolo, Chianti, Brunello → Italy
     - Bordeaux, Burgundy, Champagne, Loire, Rhône → France
     - Rioja, Ribera del Duero, Priorat → Spain
     - Napa Valley, Sonoma, Willamette Valley → USA
     - Barossa Valley, Margaret River, Hunter Valley → Australia
     - Mosel, Rheingau, Baden → Germany
     - Douro, Dao, Alentejo → Portugal
     - Golan Heights, Judean Hills, Galilee → Israel
     - Marlborough, Central Otago → New Zealand
     - Mendoza, Uco Valley → Argentina
     - Casablanca Valley, Maipo Valley → Chile
     - Stellenbosch, Swartland, Hemel-en-Aarde → South Africa

7. **IMPORTANT: Use All Available Knowledge**: Use your extensive wine knowledge to interpret what you see on the label. If you recognize a specific appellation or classification system (like Grand Cru, DOCG, etc.), use this to inform your analysis of grape varieties, quality level, and other attributes.

8. **JSON Output:** Construct a JSON object matching the EXACT structure provided above. Ensure that the JSON is valid and contains ONLY the JSON object itself. No extra text, explanations, or conversational elements.''')
          ]),
          Content.model([
            TextPart('I will analyze the wine image according to your specifications and leverage my knowledge of wine regions, grape varieties, and wine characteristics worldwide. I\'ll return a valid JSON object with all the requested fields in the exact format specified. I\'ll be particularly careful about grape identification, using region-specific knowledge when appropriate, and will provide accurate country information based on visual cues and wine knowledge. My response will contain only the JSON object without any surrounding text or explanations.')
          ]),
        ]);

        // Send the image to Gemini
        final content = Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart('Please analyze this wine image and respond with ONLY the JSON object containing the details. Use your extensive wine knowledge to identify grape varieties based on the region and style if not explicitly stated on the label. Remember to only specify the country if you can confidently determine it from the label, winery name, or recognized wine region.'),
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
      
      return WineBottle(
        name: data['name'],
        winery: data['winery'],
        year: data['year']?.toString(),
        notes: grapesInfo,
        country: data['country'],
        type: wineType,
        price: null, // Always set price to null
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing wine bottle from JSON: $e');
      return WineBottle();
    }
  }
} 



