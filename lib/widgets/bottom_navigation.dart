import 'dart:math';

import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  final int currentIndex;
  final Function(int) onIndexChanged;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFAB() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildActionButton({
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    required double angle,
    required String label,
    String? tooltip,
  }) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.9, curve: Curves.elasticOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double radius = min(screenWidth * 0.25, 100.0) * animation.value;
        final double xOffset = radius * cos(angle);
        final double yOffset = radius * sin(angle);

        return Positioned(
          bottom: 85.0 + yOffset,
          left: screenWidth / 2 - 30.0 + xOffset,
          child: Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: max(0.0, min(animation.value, 1.0)),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Container(
                          height: 56,
                          width: 56,
                          padding: const EdgeInsets.all(16),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        BottomAppBar(
          color: const Color(0xFF242424),
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          elevation: 12,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,

                colors: [const Color(0xFF2A2A2A), const Color(0xFF232323)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildBottomNavItem(
                  Icons.home_rounded,
                  'Home',
                  0,
                  widget.currentIndex == 0,
                  onTap: () => widget.onIndexChanged(0),
                ),
                _buildBottomNavItem(
                  Icons.swap_horiz_rounded,
                  'Transaction',
                  1,
                  widget.currentIndex == 1,
                  onTap: () => widget.onIndexChanged(1),
                ),
                const SizedBox(width: 40), // Placeholder for FAB
                _buildBottomNavItem(
                  Icons.pie_chart_rounded,
                  'Budget',
                  2,
                  widget.currentIndex == 2,
                  onTap: () => widget.onIndexChanged(2),
                ),
                _buildBottomNavItem(
                  Icons.person_rounded,
                  'Profile',
                  3,
                  widget.currentIndex == 3,
                  onTap: () => widget.onIndexChanged(3),
                ),
              ],
            ),
          ),
        ),

        // Semi-transparent overlay when FAB is expanded
        AnimatedOpacity(
          opacity: _isExpanded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child:
              _isExpanded
                  ? GestureDetector(
                    onTap: _toggleFAB,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                  : const SizedBox(),
        ),

        // Main FAB
        Positioned(
          bottom: 30,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleFAB,
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade300, Colors.purple.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: _isExpanded ? 2 : 0,
                    ),
                  ],
                ),
                child: AnimatedRotation(
                  turns: _isExpanded ? 0.125 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child:
                        _isExpanded
                            ? const Icon(
                              Icons.close_rounded,
                              key: ValueKey('close'),
                              color: Colors.white,
                              size: 28,
                            )
                            : const Icon(
                              Icons.add_rounded,
                              key: ValueKey('add'),
                              color: Colors.white,
                              size: 28,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Action buttons that appear when expanded
        if (_isExpanded) ...[
          // Income (Left position)
          _buildActionButton(
            color: Colors.green.shade500,
            icon: Icons.trending_up_rounded,
            label: 'Income',
            tooltip: 'Add income',
            onPressed: () {
              _toggleFAB();
              widget.onAddIncome();
            },
            angle: -3.29, // Left position
          ),

          // Expense (Right position - symmetrical to income)
          _buildActionButton(
            color: Colors.red.shade500,
            icon: Icons.trending_down_rounded,
            label: 'Expense',
            tooltip: 'Add expense',
            onPressed: () {
              _toggleFAB();
              widget.onAddExpense();
            },
            angle: 0.15, // Right position, symmetrical to income
          ),
        ],
      ],
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    int index,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuad,
              height: isSelected ? 30 : 28,
              width: isSelected ? 30 : 28,
              child: Icon(
                icon,
                color: isSelected ? Colors.purple.shade300 : Colors.white60,
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purple.shade300 : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
