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
import 'profile_edit_screen.dart';
import 'saved_addresses_screen.dart';
import 'settings_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _refreshKey = 0;

  void _refresh() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey(_refreshKey),
          future: uid.isEmpty
              ? null
              : FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, snapshot) {
            UserProfile? profile;
            if (snapshot.hasData && snapshot.data?.data() != null) {
              profile = UserProfile.fromFirestore(uid, snapshot.data!.data()!);
            }
            return _ProfileBody(profile: profile, uid: uid, onEdited: _refresh);
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
  final VoidCallback onEdited;

  const _ProfileBody({
    required this.profile,
    required this.uid,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    final displayName =
        profile?.displayName ?? (phone.isNotEmpty ? phone : 'Guest');
    final email = profile?.email ?? '';
    final gender = profile?.gender ?? '';
    final photoUrl = (profile?.photoUrl ?? '').trim();
    final hasPhoto = photoUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar + Name + Edit ───────────────────────────────────
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _initialsWidget(displayName),
                            )
                          : _initialsWidget(displayName),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _openEdit(context),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                    if (gender.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          gender,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openEdit(context),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.slate500,
                  size: 20,
                ),
                tooltip: 'Edit profile',
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

  Widget _initialsWidget(String name) {
    final parts = name.trim().split(' ');
    String init;
    if (parts.isEmpty || parts.first.isEmpty) {
      init = '?';
    } else if (parts.length == 1) {
      init = parts[0][0].toUpperCase();
    } else {
      init = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return Center(
      child: Text(
        init,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 26,
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          uid: uid,
          initialFirstName: profile?.firstName ?? '',
          initialLastName: profile?.lastName ?? '',
          initialEmail: profile?.email ?? '',
          initialGender: profile?.gender ?? '',
          initialPhotoUrl: profile?.photoUrl ?? '',
        ),
      ),
    );
    if (result == true) onEdited();
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
