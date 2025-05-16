import 'package:flutter/material.dart';
import 'package:monexa/screens/budget/detail_budget.dart';
import 'package:monexa/utils/formatters.dart';
import 'package:monexa/utils/transaction_category.dart';

class BudgetCard extends StatelessWidget {
  final String category;
  final int spent;
  final int limit;
  final Color? categoryColor;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    this.categoryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get category info from the utility class
    final categoryInfo = TransactionCategory.fromName(category);

    final double progress = spent / limit;
    final bool isOverLimit = spent > limit;
    final remaining = limit - spent;

    // Use utility extension for currency formatting
    final formattedRemaining =
        isOverLimit ? "Rp. 0" : remaining.toRupiahFormat();
    final formattedSpent = spent.toRupiahFormat();
    final formattedLimit = limit.toRupiahFormat();

    // Default to category color from utility or use provided one
    final Color actualCategoryColor = categoryColor ?? categoryInfo.color;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        DetailBudgetPage(
                          category: category,
                          spent: spent,
                          limit: limit,
                          categoryColor: actualCategoryColor,
                        ),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
      child: Hero(
        tag: 'budget_card_$category',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1C1C1E),
                  Color.alphaBlend(
                    actualCategoryColor.withOpacity(0.1),
                    const Color(0xFF1C1C1E),
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: actualCategoryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category icon and name
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: actualCategoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryInfo.icon,
                          color: actualCategoryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        categoryInfo.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (isOverLimit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                "Exceeded",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Remaining amount
                  Text(
                    "Remaining",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedRemaining,
                    style: TextStyle(
                      color: isOverLimit ? Colors.red : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress bar with indicators
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Progress background
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),

                          // Progress fill
                          FractionallySizedBox(
                            widthFactor: progress > 1.0 ? 1.0 : progress,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color:
                                    isOverLimit
                                        ? Colors.red
                                        : actualCategoryColor,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isOverLimit
                                            ? Colors.red
                                            : actualCategoryColor)
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Alert threshold indicator at 80%
                          if (!isOverLimit && progress < 0.8)
                            Positioned(
                              left: constraints.maxWidth * 0.8,
                              top: -2,
                              child: Container(
                                width: 2,
                                height: 14,
                                color: Colors.yellow,
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Spent vs Limit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Spent: $formattedSpent",
                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      ),
                      Text(
                        "Limit: $formattedLimit",
                        style: TextStyle(color: Colors.grey[300], fontSize: 13),
                      ),
                    ],
                  ),

                  // Show warning if over limit
                  if (isOverLimit) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Budget limit exceeded!",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Show almost reached warning if close to limit
                  if (!isOverLimit && progress >= 0.8) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Almost reached limit!",
                          style: TextStyle(
                            color: Colors.amber[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
