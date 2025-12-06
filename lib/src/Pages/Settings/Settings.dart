import 'package:flutter/material.dart';
import 'package:rent_hive_app/src/Components/SettingsPage/settingSection.dart';
import 'package:rent_hive_app/src/Components/SettingsPage/settingItem.dart';
import 'package:rent_hive_app/test/profile_management.dart';
import 'package:rent_hive_app/test/security.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your preferences',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              children: [
                buildSettingsSection(
                  title: 'Account',
                  items: [
                    buildSettingsItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Manage your profile information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const ProfileManagementScreen(),
                          ),
                        );
                      },
                    ),
                    buildSettingsItem(
                      icon: Icons.security,
                      title: 'Security',
                      subtitle: 'Password and security settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const SecuritySettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                buildSettingsSection(
                  title: 'Preferences',
                  items: [
                    buildSettingsItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {},
                    ),
                    buildSettingsItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Choose your language',
                      onTap: () {},
                    ),
                    buildSettingsItem(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme',
                      subtitle: 'Light or dark mode',
                      onTap: () {},
                    ),
                  ],
                ),

                buildSettingsSection(
                  title: 'Support',
                  items: [
                    buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      onTap: () {},
                    ),
                    buildSettingsItem(
                      icon: Icons.feedback_outlined,
                      title: 'Feedback',
                      subtitle: 'Send us your feedback',
                      onTap: () {},
                    ),
                    buildSettingsItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App version and information',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
