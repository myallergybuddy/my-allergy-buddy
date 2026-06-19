import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static final ImagePicker _imagePicker = ImagePicker();
  
  /// Extract text from an image file
  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      if (kDebugMode) {
        print('OCR: Starting text extraction from image');
      }
      
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final extractedText = recognizedText.text;
      
      if (kDebugMode) {
        print('OCR: Extracted text length: ${extractedText.length}');
        print('OCR: First 200 characters: ${extractedText.substring(0, extractedText.length > 200 ? 200 : extractedText.length)}');
      }
      
      return extractedText;
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error extracting text: $e');
      }
      throw Exception('Failed to extract text from image: $e');
    }
  }
  
  /// Extract text from image bytes
  static Future<String> extractTextFromBytes(Uint8List imageBytes) async {
    try {
      if (kDebugMode) {
        print('OCR: Starting text extraction from bytes');
      }
      
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(0, 0),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: 0,
        ),
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final extractedText = recognizedText.text;
      
      if (kDebugMode) {
        print('OCR: Extracted text length: ${extractedText.length}');
      }
      
      return extractedText;
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error extracting text from bytes: $e');
      }
      throw Exception('Failed to extract text from image bytes: $e');
    }
  }
  
  /// Extract ingredients from text using pattern matching
  static List<String> extractIngredientsFromText(String text) {
    if (text.isEmpty) return [];
    
    final ingredients = <String>[];
    final lines = text.split('\n');
    
    // Common ingredient list patterns
    final ingredientPatterns = [
      RegExp(r'ingredients?[:\s]*', caseSensitive: false),
      RegExp(r'contains?[:\s]*', caseSensitive: false),
      RegExp(r'ingredients? list[:\s]*', caseSensitive: false),
    ];
    
    bool foundIngredientSection = false;
    
    for (String line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line indicates the start of ingredients
      for (final pattern in ingredientPatterns) {
        if (pattern.hasMatch(trimmedLine)) {
          foundIngredientSection = true;
          // Extract ingredients from this line if they follow the pattern
          final match = pattern.firstMatch(trimmedLine);
          if (match != null) {
            final ingredientPart = trimmedLine.substring(match.end).trim();
            if (ingredientPart.isNotEmpty) {
              ingredients.addAll(_parseIngredientList(ingredientPart));
            }
          }
          break;
        }
      }
      
      // If we're in the ingredient section, parse this line
      if (foundIngredientSection && !ingredientPatterns.any((p) => p.hasMatch(trimmedLine))) {
        ingredients.addAll(_parseIngredientList(trimmedLine));
      }
    }
    
    // If no ingredient section was found, try to extract ingredients from the entire text
    if (ingredients.isEmpty) {
      ingredients.addAll(_extractIngredientsFromFullText(text));
    }
    
    // Remove duplicates and clean up
    return ingredients
        .map((ingredient) => _cleanIngredient(ingredient))
        .where((ingredient) => ingredient.isNotEmpty && ingredient.length > 2)
        .toSet()
        .toList();
  }
  
  /// Parse ingredient list from a string
  static List<String> _parseIngredientList(String text) {
    if (text.isEmpty) return [];
    
    // Split by common separators
    final separators = [',', ';', '•', '·', '|', 'and', '&'];
    List<String> ingredients = [text];
    
    for (final separator in separators) {
      ingredients = ingredients
          .expand((ingredient) => ingredient.split(separator))
          .map((ingredient) => ingredient.trim())
          .where((ingredient) => ingredient.isNotEmpty)
          .toList();
    }
    
    return ingredients;
  }
  
  /// Extract ingredients from full text when no clear ingredient section is found
  static List<String> _extractIngredientsFromFullText(String text) {
    final ingredients = <String>[];
    final lines = text.split('\n');
    
    // Common ingredient keywords that might indicate an ingredient
    final ingredientKeywords = [
      'flour', 'sugar', 'salt', 'oil', 'water', 'milk', 'egg', 'eggs',
      'butter', 'cheese', 'cream', 'vanilla', 'chocolate', 'cocoa',
      'starch', 'protein', 'fiber', 'vitamin', 'mineral', 'preservative',
      'emulsifier', 'stabilizer', 'color', 'flavor', 'sweetener',
      'acid', 'base', 'enzyme', 'antioxidant', 'thickener',
    ];
    
    for (String line in lines) {
      final trimmedLine = line.trim().toLowerCase();
      if (trimmedLine.isEmpty) continue;
      
      // Check if this line contains ingredient-like words
      bool containsIngredient = ingredientKeywords.any((keyword) => 
          trimmedLine.contains(keyword));
      
      if (containsIngredient) {
        ingredients.addAll(_parseIngredientList(line));
      }
    }
    
    return ingredients;
  }
  
  /// Clean and normalize ingredient text
  static String _cleanIngredient(String ingredient) {
    return ingredient
        .trim()
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '') // Remove special characters except hyphens and dots
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .toLowerCase();
  }
  
  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error picking image from camera: $e');
      }
      return null;
    }
  }
  
  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error picking image from gallery: $e');
      }
      return null;
    }
  }
  
  /// Save image to app's temporary directory
  static Future<File> saveImageToTemp(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempPath = path.join(tempDir.path, fileName);
      
      await imageFile.copy(tempPath);
      return File(tempPath);
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error saving image to temp: $e');
      }
      throw Exception('Failed to save image: $e');
    }
  }
  
  /// Save image to app's documents directory
  static Future<File> saveImageToDocuments(File imageFile, String fileName) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(documentsDir.path, 'product_images'));
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final filePath = path.join(imagesDir.path, fileName);
      await imageFile.copy(filePath);
      return File(filePath);
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error saving image to documents: $e');
      }
      throw Exception('Failed to save image to documents: $e');
    }
  }
  
  /// Get list of saved product images
  static Future<List<File>> getSavedProductImages() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(documentsDir.path, 'product_images'));
      
      if (!await imagesDir.exists()) {
        return [];
      }
      
      final files = await imagesDir.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg') || 
                          file.path.toLowerCase().endsWith('.jpeg') ||
                          file.path.toLowerCase().endsWith('.png'))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error getting saved images: $e');
      }
      return [];
    }
  }
  
  /// Delete a saved product image
  static Future<bool> deleteProductImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('OCR: Error deleting image: $e');
      }
      return false;
    }
  }
  
  /// Clean up resources
  static void dispose() {
    _textRecognizer.close();
  }
} 