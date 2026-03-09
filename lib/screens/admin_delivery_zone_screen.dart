import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/delivery_zone.dart';
import '../providers/delivery_zone_provider.dart';
import '../theme/app_colors.dart';

class AdminDeliveryZoneScreen extends ConsumerStatefulWidget {
  const AdminDeliveryZoneScreen({super.key});

  @override
  ConsumerState<AdminDeliveryZoneScreen> createState() =>
      _AdminDeliveryZoneScreenState();
}

class _AdminDeliveryZoneScreenState
    extends ConsumerState<AdminDeliveryZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();

  bool _seeded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zoneAsync = ref.watch(deliveryZoneProvider);
    final saveAsync = ref.watch(deliveryZoneAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Zone Settings')),
      body: zoneAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Unable to load settings.')),
        data: (zone) {
          _seedForm(zone);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Configure where delivery is allowed. Users can place orders only when they are inside the configured radius.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.slate700),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Location Name',
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(hintText: 'SM Megamall'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Location name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Latitude',
                  child: TextFormField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(hintText: '14.5853'),
                    validator: (value) {
                      final number = double.tryParse((value ?? '').trim());
                      if (number == null) {
                        return 'Enter a valid latitude';
                      }
                      if (number < -90 || number > 90) {
                        return 'Latitude must be between -90 and 90';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Longitude',
                  child: TextFormField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(hintText: '121.0568'),
                    validator: (value) {
                      final number = double.tryParse((value ?? '').trim());
                      if (number == null) {
                        return 'Enter a valid longitude';
                      }
                      if (number < -180 || number > 180) {
                        return 'Longitude must be between -180 and 180';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Delivery Radius (km)',
                  child: TextFormField(
                    controller: _radiusCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: '10'),
                    validator: (value) {
                      final number = double.tryParse((value ?? '').trim());
                      if (number == null) {
                        return 'Enter a valid radius';
                      }
                      if (number <= 0) {
                        return 'Radius must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: saveAsync.isLoading ? null : _save,
                  icon: saveAsync.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save Delivery Zone'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _seedForm(DeliveryZone zone) {
    if (_seeded) {
      return;
    }
    _seeded = true;
    _nameCtrl.text = zone.name;
    _latCtrl.text = zone.latitude.toStringAsFixed(6);
    _lngCtrl.text = zone.longitude.toStringAsFixed(6);
    _radiusCtrl.text = zone.radiusKm.toStringAsFixed(1);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final zone = DeliveryZone(
      name: _nameCtrl.text.trim(),
      latitude: double.parse(_latCtrl.text.trim()),
      longitude: double.parse(_lngCtrl.text.trim()),
      radiusKm: double.parse(_radiusCtrl.text.trim()),
    );

    await ref.read(deliveryZoneAdminProvider.notifier).saveZone(zone);
    final saveState = ref.read(deliveryZoneAdminProvider);
    if (!mounted) {
      return;
    }
    if (saveState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save delivery settings.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery zone updated successfully.')),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
