import 'package:flutter/material.dart';
import 'package:monexa/models/transaction.dart';
import 'package:monexa/widgets/transaction/transaction_card.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onTransactionTap;
  final Map<String, List<Transaction>> Function(List<Transaction>)
  groupTransactionsByDate;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onTransactionTap,
    required this.groupTransactionsByDate,
  });

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = groupTransactionsByDate(transactions);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final sectionTitle = groupedTransactions.keys.elementAt(index);
              return _buildTransactionSection(
                context,
                sectionTitle,
                groupedTransactions[sectionTitle]!,
              );
            }, childCount: groupedTransactions.length),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSection(
    BuildContext context,
    String sectionTitle,
    List<Transaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                height: 24,
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.purple[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                sectionTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (sectionTitle == "Today")
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "NEW",
                    style: TextStyle(
                      color: Colors.purple[200],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return TransactionCard(
              transaction: transactions[index],
              onTap: () => onTransactionTap(transactions[index]),
            );
          },
        ),
      ],
    );
  }
}
