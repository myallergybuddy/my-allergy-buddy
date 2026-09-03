import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/missing_product_report_service.dart';
import 'services/ocr_service.dart';
import 'services/user_learned_product_store.dart';

enum _PhotoSlot { front, back }

/// Collects a missing-product report and emails it to the app owner with photos.
class ReportMissingProductScreen extends StatefulWidget {
  final String? initialBarcode;
  final String? initialProductName;
  final String? initialBrand;

  const ReportMissingProductScreen({
    super.key,
    this.initialBarcode,
    this.initialProductName,
    this.initialBrand,
  });

  @override
  State<ReportMissingProductScreen> createState() =>
      _ReportMissingProductScreenState();
}

class _ReportMissingProductScreenState extends State<ReportMissingProductScreen> {
  static const Color _primaryColor = Color(0xFF4A9E9C);

  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _noteController;

  File? _frontPhoto;
  File? _backPhoto;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.initialBarcode ?? '');
    _nameController = TextEditingController(text: widget.initialProductName ?? '');
    _brandController = TextEditingController(text: widget.initialBrand ?? '');
    _noteController = TextEditingController();
    _prefillLastScanIfNeeded();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _prefillLastScanIfNeeded() async {
    if (_barcodeController.text.trim().isNotEmpty) return;
    final last = await UserLearnedProductStore.getLastScan();
    if (!mounted || last == null) return;
    setState(() {
      _barcodeController.text = last['barcode']?.toString() ?? '';
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = last['name']?.toString() ?? '';
      }
      if (_brandController.text.trim().isEmpty) {
        _brandController.text = last['brand']?.toString() ?? '';
      }
    });
  }

  File? _photoFor(_PhotoSlot slot) {
    switch (slot) {
      case _PhotoSlot.front:
        return _frontPhoto;
      case _PhotoSlot.back:
        return _backPhoto;
    }
  }

  void _setPhoto(_PhotoSlot slot, File? file) {
    setState(() {
      switch (slot) {
        case _PhotoSlot.front:
          _frontPhoto = file;
        case _PhotoSlot.back:
          _backPhoto = file;
      }
    });
  }

  String _slotTitle(_PhotoSlot slot) {
    switch (slot) {
      case _PhotoSlot.front:
        return 'Front of pack';
      case _PhotoSlot.back:
        return 'Back (ingredients)';
    }
  }

  IconData _slotIcon(_PhotoSlot slot) {
    switch (slot) {
      case _PhotoSlot.front:
        return Icons.image_outlined;
      case _PhotoSlot.back:
        return Icons.list_alt;
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) return true;
    }
    if (!mounted) return false;
    final permanentlyBlocked = status.isPermanentlyDenied || status.isRestricted;
    _showSnackBar(
      permanentlyBlocked
          ? 'Camera access is turned off. Enable it in Settings to photograph the product.'
          : 'Camera access is required to photograph the product.',
      isError: true,
    );
    return false;
  }

  Future<void> _pickPhoto(_PhotoSlot slot, {required bool fromCamera}) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      if (fromCamera) {
        final allowed = await _ensureCameraPermission();
        if (!allowed || !mounted) return;
      }
      final image = fromCamera
          ? await OCRService.pickImageFromCamera()
          : await OCRService.pickImageFromGallery();
      if (!mounted || image == null) return;
      _setPhoto(slot, image);
    } catch (e) {
      if (kDebugMode) {
        print('ReportMissingProduct: Error picking image: $e');
      }
      if (mounted) {
        _showSnackBar(
          fromCamera
              ? 'Failed to open the camera. Please try again.'
              : 'Failed to open the photo library. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      } else {
        _isPickingImage = false;
      }
    }
  }

  Future<void> _showPhotoSourceSheet(_PhotoSlot slot) async {
    final hasPhoto = _photoFor(slot) != null;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: _primaryColor),
                title: Text('Take photo', style: GoogleFonts.nunito()),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(slot, fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _primaryColor),
                title: Text('Choose from gallery', style: GoogleFonts.nunito()),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(slot, fromCamera: false);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Remove photo', style: GoogleFonts.nunito()),
                  onTap: () {
                    Navigator.pop(context);
                    _setPhoto(slot, null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();
    final note = _noteController.text.trim();
    final hasAnyField = barcode.isNotEmpty ||
        name.isNotEmpty ||
        brand.isNotEmpty ||
        note.isNotEmpty ||
        _frontPhoto != null ||
        _backPhoto != null;

    if (!hasAnyField) {
      _showSnackBar(
        'Add a barcode, product details, a note, or at least one photo.',
        isError: true,
      );
      return;
    }

    if (kIsWeb) {
      _showSnackBar(
        'Photo reports need the mobile app so they can be emailed with attachments.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await MissingProductReportService.sendReport(
        barcode: barcode,
        productName: name,
        brand: brand,
        note: note,
        frontPhoto: _frontPhoto,
        backPhoto: _backPhoto,
      );
      if (!mounted) return;
      _showSnackBar(
        'Your email app opened. Send the message to myallergybuddy@gmail.com to finish the report.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (kDebugMode) {
        print('ReportMissingProduct: Send failed: $e');
      }
      if (!mounted) return;
      _showSnackBar(
        'Could not open your email app with photos attached. Set up Gmail or another mail app and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(color: Colors.black45),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.nunito(fontSize: 16),
          decoration: _fieldDecoration(hint ?? ''),
        ),
      ],
    );
  }

  Widget _photoSlot(_PhotoSlot slot) {
    final photo = _photoFor(slot);
    return Expanded(
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isPickingImage ? null : () => _showPhotoSourceSheet(slot),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                height: 108,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4A9E9C).withValues(alpha: 0.4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photo != null && !kIsWeb
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(photo, fit: BoxFit.cover),
                            const Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_slotIcon(slot), color: _primaryColor, size: 28),
                            const SizedBox(height: 6),
                            Icon(Icons.add_a_photo_outlined, color: Colors.grey[600], size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _slotTitle(slot),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Report a missing product',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product not found?',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send photos of the front and back and fill in the form below to email to us. We\'ll review and add to our secure catalog.',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87, height: 1.35),
              ),
              const SizedBox(height: 16),
              _labeledField(
                label: 'Barcode',
                controller: _barcodeController,
                hint: 'e.g. 9300652801234',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _labeledField(
                label: 'Product name',
                controller: _nameController,
                hint: 'Name on the pack',
              ),
              const SizedBox(height: 12),
              _labeledField(
                label: 'Brand (optional)',
                controller: _brandController,
                hint: 'Brand name',
              ),
              const SizedBox(height: 12),
              _labeledField(
                label: 'Note (optional)',
                controller: _noteController,
                hint: 'Anything else that would help us add it',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Photos',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Camera or gallery. Front and back (ingredients).',
                style: GoogleFonts.nunito(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _photoSlot(_PhotoSlot.front),
                  const SizedBox(width: 8),
                  _photoSlot(_PhotoSlot.back),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.email_outlined, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Opening email…' : 'Email report',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    disabledBackgroundColor: _primaryColor.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
