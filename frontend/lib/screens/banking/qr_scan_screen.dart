import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans a recipient's account QR code and pops with the decoded
/// account number (a [String]), or with `null` if the user backs out.
///
/// Accepts either a bare account number (e.g. `"1000234567"`) or a small
/// JSON payload such as `{"accountNumber":"1000234567","name":"..."}`,
/// so it keeps working if account QR codes ever get richer metadata.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _imagePicker = ImagePicker();
  bool _handled = false;
  bool _isProcessingImage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _extractAccountNumber(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['accountNumber'] != null) {
          final value = decoded['accountNumber'].toString().trim();
          if (value.isNotEmpty) return value;
        }
      } catch (_) {
        // Not valid JSON - fall back to using the raw payload below.
      }
    }
    return trimmed;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    final accountNumber = _extractAccountNumber(raw);
    if (accountNumber == null || accountNumber.isEmpty) return;

    _handled = true;
    Navigator.of(context).pop(accountNumber);
  }

  Future<void> _pickFromGallery() async {
    if (_handled || _isProcessingImage) return;

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Scanning an uploaded photo isn't supported on web yet. "
            "Please use the camera, or enter the account number manually.",
          ),
        ),
      );
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null || !mounted) return;

    setState(() => _isProcessingImage = true);
    try {
      // In mobile_scanner 4.0.1, analyzeImage returns a bool indicating
      // whether a barcode was found. The decoded barcode itself arrives
      // through the same onDetect callback used for live camera scanning,
      // which will pop this screen with the account number.
      final bool found = await _controller.analyzeImage(image.path);
      if (!mounted) return;

      if (!found) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No QR code found in that photo. Try another."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan account QR'),
        actions: [
          IconButton(
            tooltip: 'Upload from gallery',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _isProcessingImage ? null : _pickFromGallery,
          ),
          IconButton(
            tooltip: 'Toggle flash',
            icon: ValueListenableBuilder<TorchState>(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                final isOn = state == TorchState.on;
                return Icon(
                  isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) =>
                _ScannerError(error: error),
          ),
          const IgnorePointer(child: _ScanFrame()),
          if (_isProcessingImage)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              children: [
                const Text(
                  "Point the camera at the recipient's account QR code",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Can't scan? Enter it manually",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2.5),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final MobileScannerException error;
  const _ScannerError({required this.error});

  String get _message {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission was denied.\n'
            'Enable camera access in Settings to scan QR codes.';
      default:
        final detail = error.errorDetails?.message;
        return 'Could not start the camera.'
            '${detail != null ? '\n$detail' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
