import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/payment.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';

/// Hosts the actual gateway checkout inside a WebView and hands control
/// back once the gateway redirects to the backend's public return route
/// (`/api/payment/khalti/return` or `/api/payment/esewa/return` - see
/// paymentRoutes.ts). Those routes already verify the payment server-side
/// and return `{ data: payment }`, so we intercept the redirect, fetch
/// that same URL ourselves, and pop with the parsed [PaymentResult]
/// instead of letting the WebView render raw JSON.
class PaymentWebViewScreen extends StatefulWidget {
  final PaymentInitiation initiation;
  const PaymentWebViewScreen({super.key, required this.initiation});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final _paymentService = PaymentService();
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isResolving = false;
  String? _error;

  bool _looksLikeReturnUrl(String url) {
    return url.contains('/api/payment/khalti/return') ||
        url.contains('/api/payment/esewa/return');
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            if (_looksLikeReturnUrl(request.url)) {
              _resolveReturnUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    final initiation = widget.initiation;
    if (initiation.paymentUrl != null) {
      // Khalti: a direct URL to load.
      await _controller.loadRequest(Uri.parse(initiation.paymentUrl!));
    } else if (initiation.formAction != null && initiation.formFields != null) {
      // eSewa: needs a real HTML form POST (signed fields), so we build a
      // tiny self-submitting HTML page and load that instead.
      final html = _buildAutoSubmitForm(
        initiation.formAction!,
        initiation.formFields!,
      );
      await _controller.loadHtmlString(html);
    } else {
      setState(() => _error = "This payment method didn't return a checkout URL.");
    }
  }

  String _buildAutoSubmitForm(String action, Map<String, String> fields) {
    final inputs = fields.entries
        .map((e) =>
            '<input type="hidden" name="${_escape(e.key)}" value="${_escape(e.value)}" />')
        .join();
    return '''
<!DOCTYPE html>
<html>
  <body onload="document.forms[0].submit()">
    <form action="${_escape(action)}" method="POST">
      $inputs
    </form>
  </body>
</html>
''';
  }

  String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  Future<void> _resolveReturnUrl(String url) async {
    if (_isResolving) return;
    setState(() {
      _isResolving = true;
      _isLoading = true;
    });
    try {
      final result = await _paymentService.fetchReturnUrl(Uri.parse(url));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = extractErrorMessage(e);
        _isLoading = false;
        _isResolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initiation.provider == 'khalti' ? 'Khalti checkout' : 'eSewa checkout',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const ColoredBox(
                      color: Colors.white,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
