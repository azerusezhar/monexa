import 'dart:math';

import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  final int currentIndex;
  final Function(int) onIndexChanged;

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
      duration: const Duration(milliseconds: 300),
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
    String? tooltip,
  }) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.9, curve: Curves.easeOutQuint),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double radius = min(screenWidth * 0.2, 80.0) * animation.value;
        final double xOffset = radius * cos(angle);
        final double yOffset = radius * sin(angle);

        return Positioned(
          bottom: 70.0 + yOffset,
          left: screenWidth / 2 - 28.0 + xOffset,
          child: Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: FloatingActionButton(
                heroTag: 'action_$angle',
                backgroundColor: color,
                mini: true,
                elevation: 4.0 * animation.value,
                tooltip: tooltip,
                onPressed: onPressed,
                child: Icon(icon, color: Colors.white),
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
          color: const Color(0xFF2A2A2A),
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 10,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildBottomNavItem(
                  Icons.home_filled,
                  'Home',
                  0,
                  widget.currentIndex == 0,
                  onTap: () => widget.onIndexChanged(0),
                ),
                _buildBottomNavItem(
                  Icons.swap_horiz,
                  'Transaction',
                  1,
                  widget.currentIndex == 1,
                  onTap: () => widget.onIndexChanged(1),
                ),
                const SizedBox(width: 40), // Placeholder for FAB
                _buildBottomNavItem(
                  Icons.pie_chart_outline,
                  'Budget',
                  2,
                  widget.currentIndex == 2,
                  onTap: () => widget.onIndexChanged(2),
                ),
                _buildBottomNavItem(
                  Icons.person_outline,
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
                      color: Colors.black.withOpacity(0.3),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                  : const SizedBox(),
        ),

        // Main FAB
        Positioned(
          bottom: 30,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(_isExpanded ? 0.6 : 0.3),
                  blurRadius: _isExpanded ? 12 : 6,
                  spreadRadius: _isExpanded ? 2 : 0,
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.purple,
              elevation: _isExpanded ? 10.0 : 6.0,
              onPressed: _toggleFAB,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child:
                    _isExpanded
                        ? const Icon(
                          Icons.close,
                          key: ValueKey('close'),
                          color: Colors.white,
                          size: 28,
                        )
                        : const Icon(
                          Icons.add,
                          key: ValueKey('add'),
                          color: Colors.white,
                          size: 28,
                        ),
              ),
            ),
          ),
        ),

        // Action buttons that appear when expanded
        if (_isExpanded) ...[
          // Red Button (Top Right) - Wallet icon
          _buildActionButton(
            color: Colors.red.shade400,
            icon: Icons.account_balance_wallet,
            tooltip: 'Add expense',
            onPressed: () {
              // Handle wallet action
              _toggleFAB();
            },
            angle: -0.7, // Top right position
          ),

          // Blue Button (Top) - People/Group icon
          _buildActionButton(
            color: Colors.blue.shade400,
            icon: Icons.people,
            tooltip: 'Split bill',
            onPressed: () {
              // Handle people/group action
              _toggleFAB();
            },
            angle: -1.6, // Top position
          ),

          // Green Button (Top Left) - Add icon
          _buildActionButton(
            color: Colors.green.shade400,
            icon: Icons.attach_money,
            tooltip: 'Add income',
            onPressed: () {
              // Handle add action
              _toggleFAB();
            },
            angle: -2.4, // Top left position
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
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? Colors.purple : Colors.white60,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purple : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
