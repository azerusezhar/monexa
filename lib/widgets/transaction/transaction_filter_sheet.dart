import 'package:flutter/material.dart';
import 'package:monexa/utils/transaction_category.dart';

class TransactionFilterSheet extends StatefulWidget {
  final String initialFilter;
  final String initialSort;
  final List<String> initialSelectedCategories;
  final List<String> filterByOptions;
  final List<String> sortByOptions;
  final Function(String, String, List<String>) onApplyFilters;

  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
    required this.initialSort,
    required this.initialSelectedCategories,
    required this.filterByOptions,
    required this.sortByOptions,
    required this.onApplyFilters,
  });

  @override
  _TransactionFilterSheetState createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late String tempFilter;
  late String tempSort;
  late List<String> tempCategories;

  @override
  void initState() {
    super.initState();
    tempFilter = widget.initialFilter;
    tempSort = widget.initialSort;
    tempCategories = List.from(widget.initialSelectedCategories);
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  IconData _getSortIcon(String sortOption) {
    switch (sortOption) {
      case 'highest':
        return Icons.arrow_downward;
      case 'lowest':
        return Icons.arrow_upward;
      case 'newest':
        return Icons.calendar_today;
      case 'oldest':
        return Icons.history;
      default:
        return Icons.sort;
    }
  }

  Widget _buildFilterSection(String title, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showCategorySelectionDialog(
    BuildContext context,
    List<String> currentSelection,
    Function(List<String>) onSelected,
  ) {
    List<String> tempSelection = List.from(currentSelection);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.grey[900],
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select Categories",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F3DFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${tempSelection.length} selected",
                                style: const TextStyle(
                                  color: Color(0xFF7F3DFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              tempSelection = [];
                            });
                          },
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text("Clear All"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              tempSelection =
                                  TransactionCategory.allCategories
                                      .map((cat) => cat.name)
                                      .toList();
                            });
                          },
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text("Select All"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF7F3DFF,
                            ).withOpacity(0.2),
                            foregroundColor: const Color(0xFF7F3DFF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.grey),
                    ),

                    // Category list
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Income Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                bottom: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.green[400],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    margin: const EdgeInsets.only(right: 10),
                                  ),
                                  Text(
                                    "INCOME",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Income Categories
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final category =
                                    TransactionCategory.incomeCategories[index];
                                return _buildCategoryCheckbox(
                                  category,
                                  tempSelection,
                                  (value) {
                                    setState(() {
                                      if (value == true) {
                                        if (!tempSelection.contains(
                                          category.name,
                                        )) {
                                          tempSelection.add(category.name);
                                        }
                                      } else {
                                        tempSelection.remove(category.name);
                                      }
                                    });
                                  },
                                );
                              },
                              childCount:
                                  TransactionCategory.incomeCategories.length,
                            ),
                          ),

                          // Expense Header
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 20.0,
                                bottom: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    margin: const EdgeInsets.only(right: 10),
                                  ),
                                  Text(
                                    "EXPENSE",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Expense Categories
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final category =
                                    TransactionCategory
                                        .expenseCategories[index];
                                return _buildCategoryCheckbox(
                                  category,
                                  tempSelection,
                                  (value) {
                                    setState(() {
                                      if (value == true) {
                                        if (!tempSelection.contains(
                                          category.name,
                                        )) {
                                          tempSelection.add(category.name);
                                        }
                                      } else {
                                        tempSelection.remove(category.name);
                                      }
                                    });
                                  },
                                );
                              },
                              childCount:
                                  TransactionCategory.expenseCategories.length,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              onSelected(tempSelection);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7F3DFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Apply",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCheckbox(
    TransactionCategory category,
    List<String> selectedCategories,
    Function(bool?) onChanged,
  ) {
    final isSelected = selectedCategories.contains(category.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!isSelected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
          child: Row(
            children: [
              // Checkbox
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: isSelected,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF7F3DFF),
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: 14),
              // Label
              Text(
                category.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: const Color(0xFF7F3DFF).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F3DFF).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header with title and reset button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filter Transaction",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      tempFilter = 'all';
                      tempSort = 'newest';
                      tempCategories = [];
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Reset"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7F3DFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Filter By Section
                SliverToBoxAdapter(
                  child: _buildFilterSection(
                    "Filter By",
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children:
                            widget.filterByOptions.map((option) {
                              bool isSelected = tempFilter == option;
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      tempFilter = isSelected ? 'all' : option;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(
                                                0xFF7F3DFF,
                                              ).withOpacity(0.3)
                                              : Colors.grey[900],
                                      borderRadius: BorderRadius.circular(20),
                                      border:
                                          isSelected
                                              ? Border.all(
                                                color: const Color(0xFF7F3DFF),
                                                width: 1.5,
                                              )
                                              : Border.all(
                                                color: Colors.grey[800]!,
                                                width: 1,
                                              ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF7F3DFF,
                                                  ).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child: Text(
                                      capitalizeFirstLetter(option),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),

                // Sort By Section
                SliverToBoxAdapter(
                  child: _buildFilterSection(
                    "Sort By",
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            widget.sortByOptions.map((option) {
                              bool isSelected = tempSort == option;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    tempSort = option;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? const Color(
                                              0xFF7F3DFF,
                                            ).withOpacity(0.3)
                                            : Colors.grey[900],
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        isSelected
                                            ? Border.all(
                                              color: const Color(0xFF7F3DFF),
                                              width: 1.5,
                                            )
                                            : Border.all(
                                              color: Colors.grey[800]!,
                                              width: 1,
                                            ),
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF7F3DFF,
                                                ).withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                              ),
                                            ]
                                            : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getSortIcon(option),
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey[400],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        capitalizeFirstLetter(option),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),

                // Category Section
                SliverToBoxAdapter(
                  child: _buildFilterSection(
                    "Category",
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: InkWell(
                        onTap: () {
                          // Show category selection dialog
                          _showCategorySelectionDialog(
                            context,
                            tempCategories,
                            (selected) {
                              setState(() {
                                tempCategories = selected;
                              });
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  tempCategories.isNotEmpty
                                      ? const Color(0xFF7F3DFF).withOpacity(0.7)
                                      : Colors.grey[800]!,
                              width: tempCategories.isNotEmpty ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tempCategories.isEmpty
                                            ? "Choose Categories"
                                            : "${tempCategories.length} Categories Selected",
                                        style: TextStyle(
                                          color:
                                              tempCategories.isEmpty
                                                  ? Colors.grey[500]
                                                  : Colors.white,
                                          fontSize: 16,
                                          fontWeight:
                                              tempCategories.isNotEmpty
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                      if (tempCategories.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 10,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF7F3DFF,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            tempCategories.length.toString(),
                                            style: const TextStyle(
                                              color: Color(0xFF7F3DFF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey[500],
                                    size: 16,
                                  ),
                                ],
                              ),
                              if (tempCategories.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 32,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    children:
                                        tempCategories.map((cat) {
                                          final category =
                                              TransactionCategory.fromName(cat);
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              right: 10,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: category.color.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: category.color
                                                    .withOpacity(0.4),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  category.icon,
                                                  color: category.color,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  category.label,
                                                  style: TextStyle(
                                                    color: category.color,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Spacer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 90), // Space for the button
                ),
              ],
            ),
          ),

          // Apply Button - Fixed at the bottom
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () {
                  // Apply filters and close sheet
                  widget.onApplyFilters(tempFilter, tempSort, tempCategories);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F3DFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Apply Filters",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.check_circle_outline, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
