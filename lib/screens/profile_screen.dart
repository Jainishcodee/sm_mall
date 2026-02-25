import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/user_profile.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'auth_landing_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'help_screen.dart';
import 'home_screen.dart';
import 'my_orders_screen.dart';
import 'saved_addresses_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: uid.isEmpty
              ? null
              : FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, snapshot) {
            UserProfile? profile;
            if (snapshot.hasData && snapshot.data?.data() != null) {
              profile = UserProfile.fromFirestore(uid, snapshot.data!.data()!);
            }
            return _ProfileBody(profile: profile, uid: uid);
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.slate500,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 4) return;
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (separated so FutureBuilder can provide profile data)
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  final UserProfile? profile;
  final String uid;

  const _ProfileBody({required this.profile, required this.uid});

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final displayName =
        profile?.displayName ?? (phone.isNotEmpty ? phone : 'Guest');
    final email = profile?.email ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Name ─────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _initials(displayName),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Menu tiles ────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _ProfileTile(
                  icon: Icons.receipt_long,
                  title: 'My Orders',
                  subtitle: 'View order history',
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfileTile(
                  icon: Icons.location_on,
                  title: 'Saved Addresses',
                  subtitle: 'Manage delivery locations',
                  color: AppColors.success,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SavedAddressesScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfileTile(
                  icon: Icons.favorite,
                  title: 'Favorites',
                  subtitle: 'Your liked products',
                  color: Colors.pink,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfileTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App preferences, theme',
                  color: AppColors.slate500,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ProfileTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs and contact us',
                  color: Colors.indigo,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
                ),
                const Spacer(),
              ],
            ),
          ),

          // ── Log out ──────────────────────────────────────────────
          PrimaryButton(
            label: 'Log Out',
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthLandingScreen()),
                  (route) => false,
                );
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to log out.')),
                );
              }
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              AppConstants.appName,
              style: const TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Tile widget
// ---------------------------------------------------------------------------

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}
