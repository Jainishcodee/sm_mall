import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// FAQ data (Blinkit / Zomato–style content for a mall delivery app)
// ---------------------------------------------------------------------------

const _faqs = [
  _Faq(
    q: 'When will my order arrive?',
    a: 'Most orders are delivered within 20–40 minutes. You can track your order in real-time from the My Orders section.',
  ),
  _Faq(
    q: 'How do I change my delivery address?',
    a: 'Go to Profile → Saved Addresses to add or edit your delivery address before placing an order.',
  ),
  _Faq(
    q: 'What if an item is missing from my order?',
    a: 'If any item is missing, tap "Report Issue" on the order detail page and our support team will resolve it within 24 hours.',
  ),
  _Faq(
    q: 'Can I cancel my order?',
    a: 'Orders can be cancelled within 2 minutes of placement. Once the order is being packed, cancellation is not possible.',
  ),
  _Faq(
    q: 'Which payment methods are accepted?',
    a: 'We accept Cash on Delivery, UPI, Debit/Credit Cards, Net Banking and popular digital wallets.',
  ),
  _Faq(
    q: 'Is there a minimum order amount?',
    a: 'There is no minimum order amount. However, a delivery fee of ₹30 applies to orders below ₹299.',
  ),
  _Faq(
    q: 'How do I use a promo code?',
    a: 'Enter your promo code at checkout in the "Apply Coupon" field. Discounts are applied automatically.',
  ),
  _Faq(
    q: 'What are your delivery hours?',
    a: 'We deliver every day from 8 AM to 11 PM, including public holidays.',
  ),
];

// ---------------------------------------------------------------------------
// Contact options
// ---------------------------------------------------------------------------

const _contacts = [
  _Contact(
    icon: Icons.chat_bubble_outline,
    label: 'Live Chat',
    detail: 'Typically replies in 2 mins',
    color: AppColors.success,
  ),
  _Contact(
    icon: Icons.phone_outlined,
    label: 'Call Support',
    detail: 'Mon – Sun, 8 AM – 11 PM',
    color: AppColors.primary,
  ),
  _Contact(
    icon: Icons.email_outlined,
    label: 'Email Us',
    detail: 'support@smmall.in',
    color: Colors.indigo,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero banner ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find answers or reach us instantly.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.support_agent, color: Colors.white, size: 48),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Contact options ────────────────────────────────────────
          _SectionHeader('Contact Us'),
          const SizedBox(height: 10),
          Row(
            children: _contacts
                .map(
                  (c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ContactCard(contact: c),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 24),

          // ── FAQs ─────────────────────────────────────────────────
          _SectionHeader('Frequently Asked Questions'),
          const SizedBox(height: 10),
          ..._faqs.asMap().entries.map((entry) {
            final i = entry.key;
            final faq = entry.value;
            final expanded = _expandedIndex == i;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey(i),
                  initiallyExpanded: expanded,
                  onExpansionChanged: (v) =>
                      setState(() => _expandedIndex = v ? i : null),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  leading: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    faq.q,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    Text(
                      faq.a,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 30),
          Center(
            child: Text(
              'SM Mall v1.0 · support@smmall.in',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate400),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _Contact {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  const _Contact({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: contact.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(contact.icon, color: contact.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              contact.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              contact.detail,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate400),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
