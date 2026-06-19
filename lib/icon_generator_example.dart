import 'package:flutter/material.dart';
import 'icon_generator.dart';

/// Example usage of the IconGenerator with enhanced design
class IconGeneratorExample extends StatefulWidget {
  const IconGeneratorExample({super.key});

  @override
  State<IconGeneratorExample> createState() => _IconGeneratorExampleState();
}

class _IconGeneratorExampleState extends State<IconGeneratorExample> {
  String? _generatedIconPath;
  bool _isGenerating = false;
  String? _errorMessage;
  final double _previewSize = 200; // Increased preview size

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Icon Generator'),
        backgroundColor: IconConfig.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Enhanced icon preview with larger size
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: IconGenerator(size: _previewSize),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Design improvements showcase
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Colors.blue.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Enhanced Design Features',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('🎨', 'Darker teal colors for better contrast'),
                  _buildFeatureItem('📏', 'Larger elements (50% bigger) for clarity'),
                  _buildFeatureItem('✨', 'Rounded corners and smooth edges'),
                  _buildFeatureItem('💫', 'Subtle shadows and glow effects'),
                  _buildFeatureItem('🔍', 'Thicker barcode lines (4-16px width)'),
                  _buildFeatureItem('⚡', 'Enhanced scanning line with glow'),
                  _buildFeatureItem('🏥', 'Larger medical cross (60px radius)'),
                  _buildFeatureItem('🛡️', 'Bigger safety shield (180x280px)'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Generate icon button with enhanced styling
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateIcon,
              icon: _isGenerating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 24),
              label: Text(
                _isGenerating ? 'Generating Enhanced Icon...' : 'Generate Enhanced Icon',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: IconConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Generate different sizes with enhanced styling
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () => _generateIcon(size: 512),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IconConfig.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '512x512',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () => _generateIcon(size: 256),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IconConfig.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '256x256',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status display with enhanced styling
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_generatedIconPath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Enhanced Icon Generated Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Path: $_generatedIconPath',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Technical specifications
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.grey.shade600, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Technical Specifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSpecItem('Primary Color', '#2E8B8A (Darker Teal)'),
                  _buildSpecItem('Accent Color', '#E53E3E (Bright Red)'),
                  _buildSpecItem('Frame Size', '500x500px (25% larger)'),
                  _buildSpecItem('Stroke Width', '12px (50% thicker)'),
                  _buildSpecItem('Corner Brackets', '30x30px (50% larger)'),
                  _buildSpecItem('Medical Cross', '60px radius (50% larger)'),
                  _buildSpecItem('Safety Shield', '180x280px (33% larger)'),
                  _buildSpecItem('Barcode Lines', '4-16px width range'),
                  _buildSpecItem('Scanning Line', '6px height with glow effect'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateIcon({int size = 1024}) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedIconPath = null;
    });

    try {
      final path = await IconGenerator.generateIcon(size: size);
      setState(() {
        _generatedIconPath = path;
        _isGenerating = false;
      });
    } on IconGenerationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isGenerating = false;
      });
    }
  }
}

/// Example of how to use the IconGenerator in a simple app
class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Icon Generator Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const IconGeneratorExample(),
    );
  }
} 