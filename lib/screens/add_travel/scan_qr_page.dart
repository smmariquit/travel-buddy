// Flutter & Material
import 'package:flutter/material.dart';

// Firebase & External Services
import 'package:mobile_scanner/mobile_scanner.dart';

// State Management
// (none in this file)

// App-specific
import 'package:travel_app/utils/constants.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: primaryColor,
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (barcodeCapture) {
          final barcode = barcodeCapture.barcodes.first;
          final String? code = barcode.rawValue;
          if (code != null) {
            controller.stop(); // Optionally stop after scanning
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}
