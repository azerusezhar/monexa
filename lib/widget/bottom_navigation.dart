import 'dart:math';

import 'package:flutter/material.dart';
import 'package:monexa/screens/dashboard/dashboard_screen.dart';
import 'package:monexa/screens/profiles/profiles_screen.dart';
import 'package:monexa/screens/transaction/transaction_screen.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key, required this.currentIndex});

  final int currentIndex;

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
  }) {
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double radius = 70.0 * animation.value;
        final double xOffset = radius * cos(angle);
        final double yOffset = radius * sin(angle);

        return Positioned(
          bottom: 65.0 + yOffset,
          left: MediaQuery.of(context).size.width / 2 - 28.0 + xOffset,
          child: Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: FloatingActionButton(
                heroTag: 'action_$angle',
                backgroundColor: color,
                mini: true,
                elevation: 6.0,
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                ),
                _buildBottomNavItem(
                  Icons.swap_horiz,
                  'Transaction',
                  1,
                  widget.currentIndex == 1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnhancedTransactionsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 40), // Placeholder for FAB
                _buildBottomNavItem(
                  Icons.pie_chart_outline,
                  'Budget',
                  2,
                  widget.currentIndex == 2,
                  onTap: () {
                    // Navigate to Budget page
                  },
                ),
                _buildBottomNavItem(
                  Icons.person_outline,
                  'Profile',
                  3,
                  widget.currentIndex == 3,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Main FAB
        Positioned(
          bottom: 30,
          child: FloatingActionButton(
            backgroundColor: Colors.purple,
            elevation: 8.0,
            onPressed: _toggleFAB,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
        ),

        // Action buttons that appear when expanded
        if (_isExpanded) ...[
          // Red Button (Top Right) - Wallet icon
          _buildActionButton(
            color: Colors.red,
            icon: Icons.account_balance_wallet,
            onPressed: () {
              // Handle wallet action
              _toggleFAB();
            },
            angle: -0.7, // Top right position
          ),

          // Blue Button (Top) - People/Group icon
          _buildActionButton(
            color: Colors.blue,
            icon: Icons.people,
            onPressed: () {
              // Handle people/group action
              _toggleFAB();
            },
            angle: -1.6, // Top position
          ),

          // Green Button (Top Left) - Add icon
          _buildActionButton(
            color: Colors.green,
            icon: Icons.add,
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
