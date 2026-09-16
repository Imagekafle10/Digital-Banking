import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../services/banking_service.dart';
import '../../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  final BankAccount account;
  const TransactionsScreen({super.key, required this.account});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _bankingService = BankingService();
  final List<BankTransaction> _transactions = [];
  String? _typeFilter;
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  final _filters = const [
    {'label': 'All', 'value': null},
    {'label': 'Deposits', 'value': 'deposit'},
    {'label': 'Withdrawals', 'value': 'withdrawal'},
    {'label': 'Received', 'value': 'transfer_in'},
    {'label': 'Sent', 'value': 'transfer_out'},
  ];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _transactions.clear();
        _hasMore = true;
      }
    });
    try {
      final page = await _bankingService.getTransactionHistory(
        accountId: widget.account.id,
        type: _typeFilter,
        page: _page,
        limit: 20,
      );
      setState(() {
        _transactions.addAll(page.rows);
        _hasMore = _transactions.length < page.count;
        _page++;
      });
    } catch (e) {
      setState(() => _error = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _typeFilter == filter['value'];
                  return ChoiceChip(
                    label: Text(filter['label'] as String),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _typeFilter = filter['value'] as String?);
                      _load(reset: true);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _load(reset: true),
                child: _error != null
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(child: Text(_error!)),
                        ],
                      )
                    : _transactions.isEmpty && !_isLoading
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'No transactions found',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (_hasMore &&
                                  !_isLoading &&
                                  notification.metrics.pixels >=
                                      notification.metrics.maxScrollExtent -
                                          200) {
                                _load();
                              }
                              return false;
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount:
                                  _transactions.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _transactions.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final tx = _transactions[index];
                                // Other user name, date, Rs
                                return Column(
                                  children: [
                                    TransactionTile(
                                      transaction: tx,
                                      currency: widget.account.currency,
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
