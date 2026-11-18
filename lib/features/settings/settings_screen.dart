import 'package:flutter/material.dart';

import '../../core/services/app_settings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/sample_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deliveryReports = AppSettings.instance.deliveryReports;
  bool _smartOtpClean = AppSettings.instance.autoOrganizeOtps;
  bool _rcsFallback = AppSettings.instance.rcsFallback;
  bool _deleteExpiredOtps = AppSettings.instance.deleteExpiredOtps;
  String _soundTone = AppSettings.instance.soundTone;
  String _bubbleRadius = AppSettings.instance.bubbleRadius;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.greigeStone,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.deepEspresso,
                      ),
                    ),
                  ),
                  const Text(
                    'SMS Settings',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepEspresso,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  // Theme Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.deepEspresso,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Theme: Sage Forest',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.softCream,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.chestnut,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '5-Tone',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.softCream,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _SwatchBar(
                              color: AppColors.deepEspresso,
                              hasBorder: true,
                            ),
                            const SizedBox(width: 6),
                            _SwatchBar(color: AppColors.chestnut),
                            const SizedBox(width: 6),
                            _SwatchBar(color: AppColors.warmTaupe),
                            const SizedBox(width: 6),
                            _SwatchBar(color: AppColors.greigeStone),
                            const SizedBox(width: 6),
                            _SwatchBar(color: AppColors.swatchCream),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Messaging Preferences Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.extraLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.greigeStone,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _ToggleRow(
                          title: 'SMS Delivery Reports',
                          description:
                              'Show Delivered / Read status under bubbles',
                          value: _deliveryReports,
                          onChanged: (val) {
                            setState(() => _deliveryReports = val);
                          },
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.greigeStone,
                        ),
                        _ToggleRow(
                          title: 'Auto-Organize OTPs',
                          description: 'Group bank & courier codes in OTP tab',
                          value: _smartOtpClean,
                          onChanged: (val) {
                            setState(() => _smartOtpClean = val);
                          },
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.greigeStone,
                        ),
                        _ToggleRow(
                          title: 'RCS to SMS Fallback',
                          description: 'Automatically switch to SMS offline',
                          value: _rcsFallback,
                          onChanged: (val) {
                            setState(() => _rcsFallback = val);
                            AppSettings.instance.rcsFallback = val;
                          },
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.greigeStone,
                        ),
                        _ToggleRow(
                          title: 'Delete Expired OTPs',
                          description:
                              'Automatically delete expired OTP messages after 24 hours',
                          value: _deleteExpiredOtps,
                          onChanged: (val) {
                            setState(() {
                              _deleteExpiredOtps = val;
                              AppSettings.instance.deleteExpiredOtps = val;
                            });
                            if (val) {
                              final count = AppSettings.instance
                                  .cleanExpiredOtps(SampleData.conversations);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(count > 0
                                      ? 'Auto-cleanup enabled: $count expired OTP(s) deleted.'
                                      : 'Auto-cleanup enabled. OTPs will be deleted 24h after expiry.'),
                                  backgroundColor: AppColors.deepForest,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sound & Style Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greigeStone,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notification Tone',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepEspresso,
                              ),
                            ),
                            Text(
                              _soundTone,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.chestnut,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bubble Geometry',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepEspresso,
                              ),
                            ),
                            Text(
                              _bubbleRadius,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.chestnut,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchBar extends StatelessWidget {
  final Color color;
  final bool hasBorder;

  const _SwatchBar({required this.color, this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: hasBorder
              ? Border.all(color: const Color(0x4DE1D4C2), width: 1)
              : null,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepEspresso,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.chestnut,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? AppColors.chestnut : AppColors.warmTaupe,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.softCream,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
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
