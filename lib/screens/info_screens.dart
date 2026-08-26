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

// --- INVITE FRIENDS SCREEN ---
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = SettingsService();
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'INVITE FRIENDS',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
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
      ),
      body: ResponsiveLayoutWrapper(
        child: FutureBuilder<Map<String, String>>(
          future: settingsService.fetchSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
            }

            final data = snapshot.data ?? {};
            final inviteLink = data['invite_url'] ?? data['invite_link'] ?? 'https://dechoicemall.com';

            Widget content = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                    ),
                    child: const Icon(Icons.card_giftcard, size: 36, color: Color(0xFFF28C00)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SHARE THE EXPERIENCE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Invite friends to Dechoice Mall',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: 0.5, color: Color(0xFF1E1E1E)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share your boutique favorites with friends and family.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: inviteLink),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
                    decoration: InputDecoration(
                      labelText: 'INVITE LINK',
                      labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 10, letterSpacing: 1.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share, size: 16),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ABOUT US',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
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
      ),
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

            Widget content = Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  const Text(
                    'WELCOME TO DECHOICE MALL',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    aboutText,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF666666), letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFDDDDDD), height: 1, thickness: 1),
                  const SizedBox(height: 24),
                  const Text('GET IN TOUCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Color(0xFFF28C00)),
                      const SizedBox(width: 12),
                      Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Color(0xFF1E1E1E))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: Color(0xFFF28C00)),
                      const SizedBox(width: 12),
                      Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: Color(0xFF1E1E1E))),
                    ],
                  ),
                ],
              ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SOCIAL CHANNELS',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
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
      ),
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
                'icon': Icons.chat_bubble_outline,
                'url': data['whatsapp_url'] ?? 'https://wa.me/2348000000000'
              },
              {
                'name': 'Instagram',
                'icon': Icons.camera_alt_outlined,
                'url': data['instagram_url'] ?? 'https://instagram.com/dechoicemall'
              },
              {
                'name': 'TikTok',
                'icon': Icons.video_library_outlined,
                'url': data['tiktok_url'] ?? 'https://tiktok.com/@dechoicemall'
              },
              {
                'name': 'Facebook',
                'icon': Icons.facebook_outlined,
                'url': data['facebook_url'] ?? 'https://facebook.com/dechoicemall'
              },
              {
                'name': 'Telegram',
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
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Icon(social['icon'] as IconData, color: const Color(0xFFF28C00), size: 20),
                    title: Text(social['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.3, color: Color(0xFF1E1E1E))),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF666666)),
                    onTap: () => _launchURL(context, social['url'] as String),
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

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CUSTOMER CARE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Need assistance with your order?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: 0.5, color: Color(0xFF1E1E1E)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Our customer support team is available to help you with deliveries, pick-up inquiries, and payment issues.',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF28C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('CHAT WITH SUPPORT ON WHATSAPP', style: TextStyle(fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              onPressed: () => _launchWhatsAppSupport(context),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'HELP & SUPPORT',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
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
      ),
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