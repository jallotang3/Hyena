import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/commercial/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../order/order_use_case.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({super.key, required this.paymentResult});
  final PaymentResult paymentResult;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  Timer? _pollTimer;
  bool _paid = false;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _launchPayment();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _launchPayment() async {
    final url = widget.paymentResult.redirectUrl;
    if (url == null) return;
    setState(() => _launching = true);
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (mounted) setState(() => _launching = false);
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final uc = context.read<OrderUseCase>();
      final result = await uc.checkOrderStatus(
          tradeNo: widget.paymentResult.tradeNo);
      if (!mounted) return;
      if (result.isSuccess) {
        final status = OrderStatus.fromCode(result.value);
        if (status == OrderStatus.completed || status == OrderStatus.processing) {
          _pollTimer?.cancel();
          setState(() => _paid = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.paymentTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _paid ? Icons.check_circle : Icons.hourglass_top,
              size: 72,
              color: _paid ? Colors.green : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _paid ? s.paymentSuccess : s.paymentWaiting,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (!_paid)
              Text(
                s.paymentWaitingHint,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            if (!_paid && widget.paymentResult.redirectUrl != null)
              FilledButton.icon(
                onPressed: _launching ? null : _launchPayment,
                icon: const Icon(Icons.open_in_new),
                label: Text(s.paymentOpenBrowser),
              ),
            const SizedBox(height: 12),
            if (_paid)
              FilledButton(
                onPressed: () => context.go('/home'),
                child: Text(s.paymentBackHome),
              )
            else
              OutlinedButton(
                onPressed: () => context.go('/orders'),
                child: Text(s.paymentViewOrders),
              ),
          ],
        ),
      ),
    );
  }
}
