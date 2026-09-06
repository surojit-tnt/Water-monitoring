import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ---------------------------------------------------------------------------
  // 1. STATE VARIABLES
  // ---------------------------------------------------------------------------
  bool isDarkMode = true;
  bool isDemoMode = false;
  String currentLang = 'en';

  // ESP32 IP Configuration (managed via Settings dialog)
  String currentIp = '192.168.4.1';
  late final TextEditingController _ipController;

  // Real-time sensor metrics
  double? tds;
  double? ph;
  double? turbidity;
  double? temperature;
  bool isConnected = false;
  bool isFetching = false;
  Timer? _pollingTimer;
  String? lastError;

  // ---------------------------------------------------------------------------
  // 2. MULTI-LANGUAGE DICTIONARY (English, Bengali, Hindi)
  // ---------------------------------------------------------------------------
  final Map<String, Map<String, String>> _dict = {
    'en': {
      'hydro': 'HYDROMETRIC',
      'station': 'STATION v1.0',
      'demo': 'DEMO',
      'purity': 'PURITY',
      'alert': 'ALERT',
      'connected': 'IOT NODE CONNECTED',
      'disconnected': 'IOT NODE DISCONNECTED',
      'sim_running': 'SIMULATION RUNNING',
      'sim_data': 'Presentation Simulation Active',
      'stream_active': 'Stream Active',
      'connect_to': 'Connect to',
      'hotspot': 'hotspot',
      'reset': 'RESET',
      'poll': 'POLL',
      'retry': 'RETRY',
      'tds': 'TOTAL DISSOLVED SOLIDS',
      'ph': 'POTENTIAL OF HYDROGEN (pH)',
      'turb': 'WATER CLARITY / TURBIDITY',
      'temp': 'WATER TEMPERATURE',
      'offline': 'OFFLINE',
      'good': 'GOOD',
      'elevated': 'ELEVATED',
      'optimal': 'OPTIMAL',
      'warning_status': 'WARNING',
      'clear': 'CLEAR',
      'hazy': 'HAZY',
      'normal': 'NORMAL',
      'telemetry_active': 'TELEMETRY FEED ACTIVE',
      'waiting_link': 'WAITING FOR SENSOR LINK',
      'settings_title': 'Network Settings',
      'ip_address_label': 'ESP32 IP / Host URL',
      'ip_hint': 'e.g. 192.168.4.1 or 10.152.170.159',
      'save': 'SAVE',
      'cancel': 'CANCEL',
      'potability_title': 'WATER USAGE ADVISORY',
      'status_drinkable': 'DRINKABLE WATER (SAFE)',
      'status_domestic': 'NOT DRINKABLE (USE FOR BATH / WASH)',
      'status_toxic': 'DANGER: NOT DRINKABLE (UNSAFE)',
      'desc_drinkable': 'Parameters are within safe drinking thresholds.',
      'desc_domestic': 'Cloudy or hard water. Not for drinking, but safe for skin and washing.',
      'desc_toxic': 'Severe chemical/clarity risk. Avoid drinking and skin contact.',
    },
    'bn': {
      'hydro': 'হাইড্রোমেট্রিক',
      'station': 'স্টেশন v1.0',
      'demo': 'ডেমো',
      'purity': 'বিশুদ্ধতা',
      'alert': 'সতর্কতা',
      'connected': 'আইওটি নোড সংযুক্ত',
      'disconnected': 'আইওটি নোড বিচ্ছিন্ন',
      'sim_running': 'সিমুলেশন চলছে',
      'sim_data': 'প্রেজেন্টেশন সিমুলেশন সক্রিয়',
      'stream_active': 'স্ট্রিম সক্রিয়',
      'connect_to': 'সংযোগ করুন',
      'hotspot': 'হটস্পট এ',
      'reset': 'রিসেট',
      'poll': 'পোল',
      'retry': 'পুনরায়',
      'tds': 'মোট দ্রবীভূত কঠিন পদার্থ',
      'ph': 'হাইড্রোজেনের মাত্রা (pH)',
      'turb': 'জলের স্বচ্ছতা / ঘোলাটে ভাব',
      'temp': 'জলের তাপমাত্রা',
      'offline': 'অফলাইন',
      'good': 'ভালো',
      'elevated': 'বেশি',
      'optimal': 'অনুকূল',
      'warning_status': 'সতর্কীকরণ',
      'clear': 'পরিষ্কার',
      'hazy': 'ঘোলাটে',
      'normal': 'স্বাভাবিক',
      'telemetry_active': 'টেলিমেট্রি ফিড সক্রিয়',
      'waiting_link': 'সেন্সর লিঙ্কের জন্য অপেক্ষারত',
      'settings_title': 'নেটওয়ার্ক সেটিংস',
      'ip_address_label': 'ESP32 আইপি / হোস্ট URL',
      'ip_hint': 'যেমন 192.168.4.1 বা 10.152.170.159',
      'save': 'সংরক্ষণ',
      'cancel': 'বাতিল',
      'potability_title': 'জল ব্যবহারের নির্দেশিকা',
      'status_drinkable': 'পানযোগ্য জল (নিরাপদ)',
      'status_domestic': 'পানীয় নয় (স্নান ও ধোয়ার কাজে ব্যবহারযোগ্য)',
      'status_toxic': 'বিপদ: পানের অযোগ্য (অনিরাপদ)',
      'desc_drinkable': 'জলের সমস্ত প্যারামিটার পানের জন্য সম্পূর্ণ নিরাপদ।',
      'desc_domestic': 'ঘোলাটে বা খনিজযুক্ত জল। পান করবেন না, তবে স্নান বা ধোয়ার জন্য নিরাপদ।',
      'desc_toxic': 'মারাত্মক ক্ষতিকর জল। পান করা বা স্পর্শ করা থেকে বিরত থাকুন।',
    },
    'hi': {
      'hydro': 'हाइड्रोमेट्रिक',
      'station': 'स्टेशन v1.0',
      'demo': 'डेमो',
      'purity': 'शुद्धता',
      'alert': 'चेतावनी',
      'connected': 'आईओटी नोड कनेक्टेड',
      'disconnected': 'आईओटी नोड डिस्कनेक्टेड',
      'sim_running': 'सिमुलेशन सक्रिय',
      'sim_data': 'प्रेजेंटेशन सिमुलेशन सक्रिय',
      'stream_active': 'स्ट्रीम सक्रिय',
      'connect_to': 'कनेक्ट करें',
      'hotspot': 'हॉटस्पॉट से',
      'reset': 'रीसेट',
      'poll': 'पोल',
      'retry': 'पुनः',
      'tds': 'कुल घुलित ठोस (TDS)',
      'ph': 'हाइड्रोजन की क्षमता (pH)',
      'turb': 'जल की स्पष्टता / मैलापन',
      'temp': 'जल का तापमान',
      'offline': 'ऑफ़लाइन',
      'good': 'अच्छा',
      'elevated': 'उच्च',
      'optimal': 'अनुकूल',
      'warning_status': 'चेतावनी',
      'clear': 'साफ़',
      'hazy': 'धुंधला',
      'normal': 'सामान्य',
      'telemetry_active': 'टेलीमेट्री फीड सक्रिय',
      'waiting_link': 'सेंसर लिंक की प्रतीक्षा...',
      'settings_title': 'नेटवर्क सेटिंग्स',
      'ip_address_label': 'ESP32 आईपी / होस्ट URL',
      'ip_hint': 'उदा. 192.168.4.1 या 10.152.170.159',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'potability_title': 'जल उपयोग सलाह',
      'status_drinkable': 'पीने योग्य पानी (सुरक्षित)',
      'status_domestic': 'पीने योग्य नहीं (नहाने और कपड़े धोने योग्य)',
      'status_toxic': 'खतरा: पीने योग्य नहीं (असुरक्षित)',
      'desc_drinkable': 'सभी सेंसर मानक सुरक्षित पेयजल सीमा के भीतर हैं।',
      'desc_domestic': 'धुंधला या कठोर जल। केवल नहाने और घरेलू धोने के काम में लाएं।',
      'desc_toxic': 'हानिकारक रासायनिक स्तर पाया गया। पानी से दूर रहें।',
    }
  };

  String t(String key) => _dict[currentLang]?[key] ?? _dict['en']![key]!;

  // ---------------------------------------------------------------------------
  // 3. LIFECYCLE & POLLING ENGINE
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: currentIp);
    _fetchSensorData();

    // Polls the ESP32 endpoint automatically every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !isFetching && !isDemoMode) {
        _fetchSensorData();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 4. NETWORK CLIENT (HTTP GET to ESP32 /data)
  // ---------------------------------------------------------------------------
  Future<void> _fetchSensorData() async {
    if (isDemoMode) return;

    setState(() {
      isFetching = true;
      lastError = null;
    });

    try {
      final response = await http
          .get(Uri.parse('http://$currentIp/data'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          tds = (data['tds'] as num?)?.toDouble();
          ph = (data['ph'] as num?)?.toDouble();
          turbidity = (data['turbidity'] as num?)?.toDouble();
          temperature = (data['temperature'] as num?)?.toDouble();
          isConnected = true;
          lastError = null;
        });
      } else {
        _resetToOffline('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      if (!isDemoMode) {
        _resetToOffline(e.toString());
      }
    } finally {
      if (mounted) setState(() => isFetching = false);
    }
  }

  void _resetToOffline([String? error]) {
    setState(() {
      isConnected = false;
      lastError = error;
      tds = null;
      ph = null;
      turbidity = null;
      temperature = null;
    });
  }

  // ---------------------------------------------------------------------------
  // 5. PRESENTATION DEMO MODE (Long-press Header Title)
  // ---------------------------------------------------------------------------
  void _triggerDemoMode() {
    setState(() {
      isDemoMode = !isDemoMode;
      if (isDemoMode) {
        isConnected = true;
        ph = 7.38;
        tds = 142.0;
        turbidity = 0.85;
        temperature = 24.2;
        lastError = null;
      } else {
        _resetToOffline();
      }
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDemoMode ? 'Demo Simulation: ACTIVATED' : 'Demo Simulation: DEACTIVATED',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16223F),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. WATER POTABILITY DECISION ENGINE
  // ---------------------------------------------------------------------------
  Map<String, dynamic>? _getPotabilityAnalysis() {
    if (!isConnected || ph == null || tds == null || turbidity == null) return null;

    // RED TIER: Severe contamination / toxic thresholds
    final bool isToxic = ph! < 6.0 || ph! > 9.0 || tds! > 600 || turbidity! > 5.0;
    if (isToxic) {
      return {
        'status': t('status_toxic'),
        'description': t('desc_toxic'),
        'color': const Color(0xFFF43F5E), // Danger Red
        'icon': Icons.cancel_rounded,
      };
    }

    // YELLOW TIER: Sub-optimal / Hard / Turbid (Safe for bath, skin, washing)
    final bool isDomesticOnly =
        (ph! < 6.5 || ph! > 8.5) || (tds! > 300) || (turbidity! > 1.0);
    if (isDomesticOnly) {
      return {
        'status': t('status_domestic'),
        'description': t('desc_domestic'),
        'color': const Color(0xFFF59E0B), // Advisory Yellow
        'icon': Icons.warning_amber_rounded,
      };
    }

    // GREEN TIER: Fully Potable & Safe
    return {
      'status': t('status_drinkable'),
      'description': t('desc_drinkable'),
      'color': const Color(0xFF10B981), // Safe Green
      'icon': Icons.check_circle_rounded,
    };
  }

  String _calculatePurity() {
    if (!isConnected || ph == null || tds == null) return '-- ${t('purity')}';
    if (ph! >= 6.5 && ph! <= 8.5 && tds! <= 300) return '98% ${t('purity')}';
    if (ph! >= 6.0 && ph! <= 9.0 && tds! <= 600) return '82% ${t('purity')}';
    return '45% ${t('alert')}';
  }

  // ---------------------------------------------------------------------------
  // 7. SETTINGS DIALOG (Replaces direct IP field on main screen)
  // ---------------------------------------------------------------------------
  void _openSettingsDialog(Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary) {
    _ipController.text = currentIp;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: cardBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.settings_rounded, color: Color(0xFF00E5FF), size: 22),
              const SizedBox(width: 10),
              Text(
                t('settings_title'),
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('ip_address_label'),
                style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ipController,
                style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: t('ip_hint'),
                  hintStyle: const TextStyle(color: Color(0x8094A3B8), fontSize: 12),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorder),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF00E5FF)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('cancel'), style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final String enteredIp = _ipController.text.trim();
                if (enteredIp.isNotEmpty) {
                  setState(() => currentIp = enteredIp);
                  Navigator.of(ctx).pop();
                  if (!isDemoMode) _fetchSensorData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                t('save'),
                style: const TextStyle(color: Color(0xFF0B132B), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 8. MAIN UI SCREEN BUILDER
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
    final Color cardBg = isDarkMode ? const Color(0xFF16223F) : Colors.white;
    final Color cardBorder = isDarkMode ? const Color(0xFF243356) : const Color(0xFFE2E8F0);
    final Color textPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color textSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color neonCyan = Color(0xFF00E5FF);
    const Color emeraldGreen = Color(0xFF10B981);
    const Color alertRed = Color(0xFFF43F5E);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    final potability = _getPotabilityAnalysis();

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? const Color(0xFF1C2B54) : const Color(0xFFE0F2FE),
                        border: Border.all(color: const Color(0x6600E5FF), width: 1.5),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: neonCyan, size: 22),
                    ),
                    const SizedBox(width: 10),

                    // Gesture Title (Long-press activates presentation demo mode)
                    Expanded(
                      child: GestureDetector(
                        onLongPress: _triggerDemoMode,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    t('hydro'),
                                    style: const TextStyle(
                                      color: neonCyan,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isDemoMode) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0x3310B981),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      t('demo'),
                                      style: const TextStyle(
                                        color: emeraldGreen,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              t('station'),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Metric Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1C2B54) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isConnected ? const Color(0x8010B981) : cardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: isConnected ? emeraldGreen : alertRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _calculatePurity(),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Language Selector
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.translate_rounded,
                        color: isDarkMode ? Colors.white70 : const Color(0xFF0F172A),
                        size: 20,
                      ),
                      tooltip: 'Language',
                      padding: EdgeInsets.zero,
                      color: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (String lang) => setState(() => currentLang = lang),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'en',
                          child: Text('English', style: TextStyle(color: textPrimary, fontWeight: currentLang == 'en' ? FontWeight.bold : FontWeight.normal)),
                        ),
                        PopupMenuItem(
                          value: 'bn',
                          child: Text('বাংলা', style: TextStyle(color: textPrimary, fontWeight: currentLang == 'bn' ? FontWeight.bold : FontWeight.normal)),
                        ),
                        PopupMenuItem(
                          value: 'hi',
                          child: Text('हिंदी', style: TextStyle(color: textPrimary, fontWeight: currentLang == 'hi' ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ],
                    ),

                    // Theme Switcher
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                        color: isDarkMode ? Colors.white70 : const Color(0xFF0F172A),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Toggle Theme',
                      onPressed: () => setState(() => isDarkMode = !isDarkMode),
                    ),

                    // Settings Dialog Trigger
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: isDarkMode ? Colors.white70 : const Color(0xFF0F172A),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                      tooltip: 'Settings',
                      onPressed: () => _openSettingsDialog(cardBg, cardBorder, textPrimary, textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Hardware Connection Banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0x1F10B981) : const Color(0x1FF43F5E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected ? const Color(0x5910B981) : const Color(0x59F43F5E),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off_rounded,
                        color: isConnected ? emeraldGreen : alertRed,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDemoMode
                                  ? t('sim_running')
                                  : (isConnected ? t('connected') : t('disconnected')),
                              style: TextStyle(
                                color: isConnected ? emeraldGreen : alertRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isDemoMode
                                  ? t('sim_data')
                                  : (isConnected
                                      ? '$currentIp • ${t('stream_active')}'
                                      : (lastError ?? '${t('connect_to')} $currentIp ${t('hotspot')}')),
                              style: TextStyle(
                                color: isConnected ? const Color(0xCC10B981) : textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: isFetching
                            ? null
                            : () {
                                if (isDemoMode) {
                                  _triggerDemoMode();
                                } else {
                                  _fetchSensorData();
                                }
                              },
                        style: TextButton.styleFrom(
                          backgroundColor: isConnected ? const Color(0x2610B981) : const Color(0x26F43F5E),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isFetching
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isConnected ? emeraldGreen : alertRed,
                                  ),
                                ),
                              )
                            : Text(
                                isDemoMode ? t('reset') : (isConnected ? t('poll') : t('retry')),
                                style: TextStyle(
                                  color: isConnected ? emeraldGreen : alertRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Potability Status Card (Green / Yellow / Red Alert Light)
                if (potability != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: (potability['color'] as Color == emeraldGreen)
                          ? const Color(0x1F10B981)
                          : (potability['color'] as Color == alertRed
                              ? const Color(0x1FF43F5E)
                              : const Color(0x1FF59E0B)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: potability['color'] as Color,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              potability['icon'] as IconData,
                              color: potability['color'] as Color,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t('potability_title'),
                              style: TextStyle(
                                color: potability['color'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          potability['status'] as String,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          potability['description'] as String,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sensor Cards
                _buildSensorCard(
                  title: t('tds'),
                  value: (isConnected && tds != null) ? tds!.toStringAsFixed(0) : '--',
                  unit: 'PPM',
                  icon: Icons.grain_rounded,
                  accentColor: neonCyan,
                  statusText: isConnected ? (tds! <= 300 ? t('good') : t('elevated')) : t('offline'),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 12),

                _buildSensorCard(
                  title: t('ph'),
                  value: (isConnected && ph != null) ? ph!.toStringAsFixed(2) : '--',
                  unit: 'pH',
                  icon: Icons.science_rounded,
                  accentColor: const Color(0xFF38BDF8),
                  statusText: isConnected
                      ? (ph! >= 6.5 && ph! <= 8.5 ? t('optimal') : t('warning_status'))
                      : t('offline'),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 12),

                _buildSensorCard(
                  title: t('turb'),
                  value: (isConnected && turbidity != null) ? turbidity!.toStringAsFixed(2) : '--',
                  unit: 'NTU',
                  icon: Icons.water_rounded,
                  accentColor: const Color(0xFF67E8F9),
                  statusText: isConnected ? (turbidity! <= 1.0 ? t('clear') : t('hazy')) : t('offline'),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 12),

                _buildSensorCard(
                  title: t('temp'),
                  value: (isConnected && temperature != null) ? temperature!.toStringAsFixed(1) : '--',
                  unit: '°C',
                  icon: Icons.thermostat_rounded,
                  accentColor: emeraldGreen,
                  statusText: isConnected ? t('normal') : t('offline'),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 22),

                // Bottom Link Feed Action Button
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0x2E10B981) : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected ? emeraldGreen : cardBorder,
                      width: 1.2,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (!isDemoMode) _fetchSensorData();
                    },
                    onLongPress: _triggerDemoMode,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            color: isConnected ? emeraldGreen : textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isConnected
                                ? (isDemoMode ? t('sim_running') : t('telemetry_active'))
                                : t('waiting_link'),
                            style: TextStyle(
                              color: isConnected ? emeraldGreen : textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. REUSABLE CARD WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required String statusText,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final bool isOffline = statusText == t('offline');

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isOffline ? textSecondary : accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOffline ? const Color(0x1F94A3B8) : const Color(0x2600E5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: isOffline ? textSecondary : accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isOffline ? const Color(0x9994A3B8) : textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  color: isOffline ? const Color(0x8094A3B8) : accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}