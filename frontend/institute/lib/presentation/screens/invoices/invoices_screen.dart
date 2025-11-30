import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/invoice_card.dart';
import 'create_invoice_enhanced_screen.dart';
import 'invoice_detail_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().getInvoices(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = context.read<InvoiceProvider>();
      if (!provider.isLoading && provider.hasMoreData) {
        provider.getInvoices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'all' ? null : value;
              });
              context.read<InvoiceProvider>().filterByStatus(_selectedStatus);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'paid', child: Text('Paid')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
              const PopupMenuItem(value: 'canceled', child: Text('Canceled')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateInvoice(),
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.state == InvoiceState.loading &&
              provider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == InvoiceState.error &&
              provider.invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'An error occurred'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.getInvoices(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No invoices found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateInvoice(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Invoice'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.getInvoices(refresh: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.invoices.length +
                  (provider.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.invoices.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final invoice = provider.invoices[index];
                return InvoiceCard(
                  invoice: invoice,
                  onTap: () => _navigateToInvoiceDetail(invoice),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToCreateInvoice() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateInvoiceEnhancedScreen(),
      ),
    );

    if (result == true && mounted) {
      context.read<InvoiceProvider>().getInvoices(refresh: true);
    }
  }

  Future<void> _navigateToInvoiceDetail(invoice) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );

    // Refresh the list when coming back
    if (mounted) {
      context.read<InvoiceProvider>().getInvoices(refresh: true);
    }
  }
}
