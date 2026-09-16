import '../core/constants/api_constants.dart';
import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  final _client = ApiClient.instance;

  Future<PaymentInitiation> initiate({
    required String accountId,
    required String provider, // 'khalti' | 'esewa'
    required double amount,
    String? remarks,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.paymentInitiate,
      data: {
        'accountId': accountId,
        'provider': provider,
        'amount': amount,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
    );
    return PaymentInitiation.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// The backend's own khalti/esewa return endpoints already verify and
  /// return the payment - so once the webview intercepts the redirect we
  /// just GET that exact URL (it's a public route, no auth needed) to get
  /// the final [PaymentResult].
  Future<PaymentResult> fetchReturnUrl(Uri url) async {
    final response = await _client.dio.getUri(url);
    return PaymentResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
