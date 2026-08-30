import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/responsive_wrapper.dart';

// --- HELPER SERVICE FOR SETTINGS ---
class SettingsService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, String>> fetchSettings() async {
    try {
      final response = await _supabase.from('settings').select('key, value');
      Map<String, String> settingsMap = {};
      for (var row in response) {
        settingsMap[row['key'].toString()] = row['value'].toString();
      }
      return settingsMap;
    } catch (e) {
      return {};
    }
  }
}

// --- SHARED APP BAR DESIGN ---
PreferredSizeWidget buildCustomAppBar(String title) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E1E1E),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF28C00),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFF0F0F0),
          height: 1,
        ),
      ),
    ),
  );
}

// --- INVITE FRIENDS SCREEN ---
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: buildCustomAppBar('INVITE FRIENDS'),
      body: ResponsiveLayoutWrapper(
        child: FutureBuilder<Map<String, String>>(
          future: settingsService.fetchSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
            }

            final data = snapshot.data ?? {};
            final inviteLink = data['invite_url'] ?? data['invite_link'] ?? 'https://dechoicemall.com';

            Widget content = SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Header Badge Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFF28C00).withValues(alpha: 0.1), Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF28C00).withValues(alpha: 0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF28C00).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, size: 40, color: Color(0xFFF28C00)),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'SHARE THE EXPERIENCE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2.5, color: Color(0xFFF28C00)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Invite friends to Dechoice Mall',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: Color(0xFF1E1E1E)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share your boutique favorites, gourmet meals, and daily essentials with family and friends seamlessly.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Copy/Invite Link Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR UNIQUE INVITE LINK',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(text: inviteLink),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E), fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.link, color: Color(0xFFF28C00), size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF28C00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text('SHARE INVITE LINK', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Share.share(
                                'Check out Dechoice Mall! Shop your favorite provisions, meals, drinks and more. Download the app here: $inviteLink',
                                subject: 'Invite to Dechoice Mall',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            return isDesktop
                ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: content,
              ),
            )
                : content;
          },
        ),
      ),
    );
  }
}

// --- ABOUT SCREEN ---
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: buildCustomAppBar('ABOUT US'),
      body: ResponsiveLayoutWrapper(
        child: FutureBuilder<Map<String, String>>(
          future: settingsService.fetchSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
            }

            final data = snapshot.data ?? {};
            final aboutText = data['about_text'] ??
                'Dechoice Mall is your premier one-stop destination for quality provisions, confectionaries, drinks, snacks, toiletries, frozen foods, delicious eatery meals, children clothing, and exquisite cocktails and mocktails.';
            final phone = data['support_phone'] ?? '+234 800 000 0000';
            final email = data['support_email'] ?? 'support@dechoicemall.com';

            Widget content = ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // About Hero Section Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront, color: Color(0xFFF28C00), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'WELCOME TO DECHOICE MALL',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFFF28C00)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        aboutText,
                        style: const TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF555555), letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact / Get In Touch Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEAEAEA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GET IN TOUCH',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF28C00).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFFF28C00)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Call Support', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                              const SizedBox(height: 2),
                              Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: Color(0xFF1E1E1E))),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF28C00).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.email_outlined, size: 18, color: Color(0xFFF28C00)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email Address', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                              const SizedBox(height: 2),
                              Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: Color(0xFF1E1E1E))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            return isDesktop
                ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: content,
              ),
            )
                : content;
          },
        ),
      ),
    );
  }
}

// --- SOCIAL MEDIA SCREEN ---
class SocialMediaScreen extends StatelessWidget {
  const SocialMediaScreen({super.key});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString'), backgroundColor: const Color(0xFF1E1E1E)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: buildCustomAppBar('SOCIAL CHANNELS'),
      body: ResponsiveLayoutWrapper(
        child: FutureBuilder<Map<String, String>>(
          future: settingsService.fetchSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
            }

            final data = snapshot.data ?? {};
            final socials = [
              {
                'name': 'WhatsApp',
                'subtitle': 'Chat with us directly',
                'icon': Icons.chat_bubble_outline_rounded,
                'url': data['whatsapp_url'] ?? 'https://wa.me/2348000000000'
              },
              {
                'name': 'Instagram',
                'subtitle': 'See our latest updates & catalog',
                'icon': Icons.camera_alt_outlined,
                'url': data['instagram_url'] ?? 'https://instagram.com/dechoicemall'
              },
              {
                'name': 'TikTok',
                'subtitle': 'Catch our short videos & reels',
                'icon': Icons.video_library_outlined,
                'url': data['tiktok_url'] ?? 'https://tiktok.com/@dechoicemall'
              },
              {
                'name': 'Facebook',
                'subtitle': 'Join our community page',
                'icon': Icons.facebook_outlined,
                'url': data['facebook_url'] ?? 'https://facebook.com/dechoicemall'
              },
              {
                'name': 'Telegram',
                'subtitle': 'Get instant announcements',
                'icon': Icons.send_outlined,
                'url': data['telegram_url'] ?? 'https://t.me/dechoicemall'
              },
            ];

            Widget content = ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: socials.length,
              itemBuilder: (context, index) {
                final social = socials[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFEAEAEA), width: 1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _launchURL(context, social['url'] as String),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF28C00).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(social['icon'] as IconData, color: const Color(0xFFF28C00), size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    social['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3, color: Color(0xFF1E1E1E)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    social['subtitle'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8F8F8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF666666)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );

            return isDesktop
                ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: content,
              ),
            )
                : content;
          },
        ),
      ),
    );
  }
}

// --- HELP SCREEN ---
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchWhatsAppSupport(BuildContext context) async {
    final settings = await SettingsService().fetchSettings();
    final whatsappUrl = settings['whatsapp_url'] ??
        settings['whatsapp_support_url'] ??
        'https://wa.me/2348000000000?text=Hello%20Dechoice%20Support,%20I%20need%20help%20with%20my%20order.';

    final Uri url = Uri.parse(whatsappUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp support.'), backgroundColor: Color(0xFF1E1E1E)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Hero Card Container for Customer Care
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAEAEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF28C00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.support_agent_rounded, size: 24, color: Color(0xFFF28C00)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'CUSTOMER CARE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFFF28C00)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Online Assistance',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E1E)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Need assistance with your order?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: 0.3, color: Color(0xFF1E1E1E)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Our dedicated customer support team is available to help you with deliveries, pick-up inquiries, and payment issues in real time.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.6),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('CHAT WITH SUPPORT ON WHATSAPP', style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    onPressed: () => _launchWhatsAppSupport(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: buildCustomAppBar('HELP & SUPPORT'),
      body: ResponsiveLayoutWrapper(
        child: isDesktop
            ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: content,
          ),
        )
            : content,
      ),
    );
  }
}