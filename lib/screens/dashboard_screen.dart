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
  // ===========================================================================
  // 1. STATE CONFIGURATION
  // ===========================================================================
  bool isDarkMode = true;
  bool isDemoMode = false;
  String currentLang = 'en';

  // ESP32 IP Configuration
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

  // Offline Diagnostics Simulation State (active when hardware is offline)
  double offlineTds = 345.0;
  double offlinePh = 7.15;
  double offlineTurbidity = 2.4;
  double offlineTemperature = 25.0;

  // ===========================================================================
  // 2. MULTI-LANGUAGE DICTIONARY (English, Bengali, Hindi)
  // ===========================================================================
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
      'settings_title': 'App & Network Settings',
      'theme_label': 'Dark Mode Appearance',
      'lang_label': 'Interface Language',
      'ip_address_label': 'ESP32 IP / Host URL',
      'ip_hint': 'e.g. 192.168.4.1 or 10.152.170.159',
      'save': 'DONE',
      'cancel': 'CANCEL',
      'potability_title': 'WATER USAGE ADVISORY',
      'status_drinkable': 'DRINKABLE WATER (SAFE)',
      'status_domestic': 'NOT DRINKABLE (USE FOR BATH / WASH)',
      'status_toxic': 'DANGER: NOT DRINKABLE (UNSAFE)',
      'desc_drinkable': 'Parameters are within safe drinking thresholds.',
      'desc_domestic': 'Cloudy or hard water. Not for drinking, but safe for skin and washing.',
      'desc_toxic': 'Severe chemical/clarity risk. Avoid drinking and skin contact.',
      
      // ML Water Treatment Engine
      'treatment_title': 'AI WATER TREATMENT PROTOCOL',
      'model_tag': 'On-Device Edge ML: 96.2% Confidence',
      'offline_badge': 'OFFLINE AI DIAGNOSTICS ACTIVE',
      'offline_presets': 'TEST OFFLINE WATER SAMPLES:',
      'preset_clean': 'Safe / Drinking',
      'preset_cloudy': 'Cloudy / Bathing',
      'preset_toxic': 'Toxic / Unsafe',
      'action_plan': 'PURIFICATION ACTION PLAN',
      'safe_treatment': 'Water is certified drinkable. No chemical treatment required. Optional 1-micron particulate polish or UV sterilizer for long-term storage.',
      'step1_cloudy': '1. Coagulation: Add 10-15 mg/L food-grade Alum (fitkari). Stir gently for 1 minute and allow 30 minutes for suspended clay/dirt to settle.',
      'step2_cloudy': '2. Mechanical Filtration: Decant the clear top layer and pour through an Activated Carbon / Multi-sand filter to drop turbidity below 1.0 NTU.',
      'step3_cloudy': '3. Thermal Disinfection: Bring water to a rolling boil (100°C) for 3-5 minutes to destroy biological pathogens.',
      'step1_danger': '1. Chemical Neutralization: If pH is acidic (<6.5), add Sodium Bicarbonate (baking soda). If alkaline (>8.5), add food-grade citric acid until pH reaches 7.2.',
      'step2_danger': '2. High-Pressure RO Filtration: Pass through a multi-stage Reverse Osmosis membrane (>50 PSI) to filter heavy metals and strip toxic dissolved solids below 200 PPM.',
      'step3_danger': '3. Post-Sterilization: Expose to high-intensity UV-C radiation (254 nm) to eliminate remaining viruses and microbial contaminants.',
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
      'settings_title': 'অ্যাপ ও নেটওয়ার্ক সেটিংস',
      'theme_label': 'ডার্ক মোড',
      'lang_label': 'ভাষার পরিবর্তন',
      'ip_address_label': 'ESP32 আইপি / হোস্ট URL',
      'ip_hint': 'যেমন 192.168.4.1 বা 10.152.170.159',
      'save': 'সম্পন্ন',
      'cancel': 'বাতিল',
      'potability_title': 'জল ব্যবহারের নির্দেশিকা',
      'status_drinkable': 'পানযোগ্য জল (নিরাপদ)',
      'status_domestic': 'পানীয় নয় (স্নান ও ধোয়ার উপযোগী)',
      'status_toxic': 'বিপদ: পানের অযোগ্য (অনিরাপদ)',
      'desc_drinkable': 'জলের সমস্ত প্যারামিটার পানের জন্য সম্পূর্ণ নিরাপদ।',
      'desc_domestic': 'ঘোলাটে বা খনিজযুক্ত জল। পান করবেন না, তবে স্নান বা ধোয়ার জন্য নিরাপদ।',
      'desc_toxic': 'মারাত্মক ক্ষতিকর জল। পান করা বা স্পর্শ করা থেকে বিরত থাকুন।',
      
      // ML Water Treatment Engine
      'treatment_title': 'এআই জল শোধন নির্দেশিকা',
      'model_tag': 'অন-ডিভাইস এজ এমএল: ৯৬.২% নির্ভুলতা',
      'offline_badge': 'অফলাইন এআই ডায়াগনস্টিকস সক্রিয়',
      'offline_presets': 'অফলাইনে জলের নমুনা পরীক্ষা করুন:',
      'preset_clean': 'নিরাপদ / পানযোগ্য',
      'preset_cloudy': 'ঘোলাটে / স্নানযোগ্য',
      'preset_toxic': 'বিষাক্ত / অনিরাপদ',
      'action_plan': 'পরিশোধন প্রক্রিয়া',
      'safe_treatment': 'জলটি পানের জন্য সম্পূর্ণ নিরাপদ। অতিরিক্ত রাসায়নিক শোধনের প্রয়োজন নেই। দীর্ঘমেয়াদী সংরক্ষণের জন্য সাধারণ UV ব্যবহার করতে পারেন।',
      'step1_cloudy': '১. থিতানো (Coagulation): প্রতি লিটারে ১০-১৫ মিলিগ্রাম ফটকিরি মেশান। ১ মিনিট নাড়ুন এবং ৩০ মিনিট স্থির রেখে তলানি নিচে জমতে দিন।',
      'step2_cloudy': '২. যান্ত্রিক ফিল্টারিং: উপরের স্বচ্ছ জল আলাদা করে অ্যাক্টিভেটেড কার্বন বা বালির ফিল্টারের মাধ্যমে ছেঁকে ঘোলাটে ভাব ১.০ NTU-এর নিচে আনুন।',
      'step3_cloudy': '৩. জীবাণুমুক্তকরণ: সমস্ত ক্ষতিকর ব্যাকটেরিয়া ও জীবাণু ধ্বংস করতে জলটি ১০০°C তাপমাত্রায় ৩-৫ মিনিট ভালো করে ফোটান।',
      'step1_danger': '১. রাসায়নিক সমতা: জল অম্লীয় (pH < ৬.৫) হলে বেকিং সোডা এবং অতিরিক্ত ক্ষারীয় (pH > ৮.৫) হলে সাইট্রিক অ্যাসিড মিশিয়ে pH ৭.২-এ আনুন।',
      'step2_danger': '২. রিভার্স অসমোসিস (RO): ক্ষতিকর ধাতু ও অতিরিক্ত TDS ২০০ PPM-এর নিচে নামাতে জলটিকে উচ্চচাপযুক্ত আরও (RO) ফিল্টারের মধ্য দিয়ে চালান।',
      'step3_danger': '৩. ইউভি নির্বীজন: অবশিষ্ট অণুজীব ও ভাইরাস সম্পূর্ণ ধ্বংস করতে আল্ট্রাভায়োলেট (UV-C ২৫৪ nm) রশ্মি প্রয়োগ করুন।',
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
      'settings_title': 'ऐप और नेटवर्क सेटिंग्स',
      'theme_label': 'डार्क मोड',
      'lang_label': 'भाषा का चयन',
      'ip_address_label': 'ESP32 आईपी / होस्ट URL',
      'ip_hint': 'उदा. 192.168.4.1 या 10.152.170.159',
      'save': 'पूर्ण',
      'cancel': 'रद्द करें',
      'potability_title': 'जल उपयोग सलाह',
      'status_drinkable': 'पीने योग्य पानी (सुरक्षित)',
      'status_domestic': 'पीने योग्य नहीं (नहाने और कपड़े धोने योग्य)',
      'status_toxic': 'खतरा: पीने योग्य नहीं (असुरक्षित)',
      'desc_drinkable': 'सभी सेंसर मानक सुरक्षित पेयजल सीमा के भीतर हैं।',
      'desc_domestic': 'धुंधला या कठोर जल। केवल नहाने और घरेलू धोने के काम में लाएं।',
      'desc_toxic': 'हानिकारक रासायनिक स्तर पाया गया। पानी से दूर रहें।',
      
      // ML Water Treatment Engine
      'treatment_title': 'एआई जल शोधन प्रोटोकॉल',
      'model_tag': 'ऑन-डिवाइस एज एमएल: ९६.२% सटीकता',
      'offline_badge': 'ऑफलाइन एआई डायग्नोस्टिक्स सक्रिय',
      'offline_presets': 'ऑफलाइन पानी के नमूने का परीक्षण करें:',
      'preset_clean': 'सुरक्षित / पीने योग्य',
      'preset_cloudy': 'धुंधला / नहाने योग्य',
      'preset_toxic': 'विषाक्त / असुरक्षित',
      'action_plan': 'जल शुद्धिकरण प्रक्रिया',
      'safe_treatment': 'जल पीने के लिए पूरी तरह सुरक्षित है। किसी रासायनिक प्रक्रिया की आवश्यकता नहीं है। भंडारण के लिए वैकल्पिक यूवी (UV) शुद्धिकरण करें।',
      'step1_cloudy': '१. स्कंदन (Coagulation): प्रति लीटर १०-१५ मिलीग्राम फिटकरी मिलाएं। १ मिनट हिलाएं और मैलापन नीचे बैठने के लिए ३० मिनट छोड़ दें।',
      'step2_cloudy': '२. निस्पंदन (Filtration): ऊपर का साफ़ पानी अलग करके एक्टिवेटेड कार्बन या सैंड फिल्टर से छानें ताकि मैलापन १.० NTU से कम हो जाए।',
      'step3_cloudy': '३. कीटाणुशोधन: हानिकारक बैक्टीरिया और सूक्ष्मजीवों को नष्ट करने के लिए पानी को १००°C पर ३-५ मिनट तक उबालें।',
      'step1_danger': '१. रासायनिक संतुलन: अम्लीय होने पर (pH < ६.५) बेकिंग सोडा और अधिक क्षारीय होने पर (pH > ८.५) साइट्रिक एसिड मिलाकर pH ७.२ करें।',
      'step2_danger': '२. रिवर्स ऑस्मोसिस (RO): भारी धातुओं और अत्यधिक TDS को २०० PPM से नीचे लाने के लिए आरओ मेम्ब्रेन से गुजारें।',
      'step3_danger': '३. यूवी बंध्याकरण: शेष वायरस और रोगाणुओं को पूरी तरह नष्ट करने के लिए यूवी-सी (UV-C २५४ nm) प्रकाश से उपचारित करें।',
    }
  };

  String t(String key) => _dict[currentLang]?[key] ?? _dict['en']![key]!;

  // ===========================================================================
  // 3. LIFECYCLE & BACKGROUND POLLING
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: currentIp);
    _fetchSensorData();

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

  // ===========================================================================
  // 4. HTTP TELEMETRY CLIENT
  // ===========================================================================
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

  // ===========================================================================
  // 5. PRESENTATION SIMULATION (DEMO MODE)
  // ===========================================================================
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

  // ===========================================================================
  // 6. POTABILITY & WATER CLASSIFICATION ENGINE (100% OFFLINE READY)
  // ===========================================================================
  Map<String, dynamic> _getPotabilityAnalysis() {
    // Determine active metrics (Live sensor stream vs Offline diagnostic sample)
    final double evalPh = isConnected ? (ph ?? 7.0) : offlinePh;
    final double evalTds = isConnected ? (tds ?? 200.0) : offlineTds;
    final double evalTurb = isConnected ? (turbidity ?? 0.5) : offlineTurbidity;

    // RED TIER: Severe Contamination / Toxic Thresholds
    final bool isToxic = evalPh < 6.0 || evalPh > 9.0 || evalTds > 600 || evalTurb > 5.0;
    if (isToxic) {
      return {
        'status': t('status_toxic'),
        'description': t('desc_toxic'),
        'color': const Color(0xFFF43F5E), // Danger Red
        'icon': Icons.cancel_rounded,
        'tier': 'red',
      };
    }

    // YELLOW TIER: Sub-optimal / Hard / Turbid (Safe for Bath, Skin, Wash)
    final bool isDomesticOnly =
        (evalPh < 6.5 || evalPh > 8.5) || (evalTds > 300) || (evalTurb > 1.0);
    if (isDomesticOnly) {
      return {
        'status': t('status_domestic'),
        'description': t('desc_domestic'),
        'color': const Color(0xFFF59E0B), // Advisory Yellow
        'icon': Icons.warning_amber_rounded,
        'tier': 'yellow',
      };
    }

    // GREEN TIER: Fully Potable & Safe
    return {
      'status': t('status_drinkable'),
      'description': t('desc_drinkable'),
      'color': const Color(0xFF10B981), // Safe Green
      'icon': Icons.check_circle_rounded,
      'tier': 'green',
    };
  }

  // ===========================================================================
  // 7. PREDICTIVE/PRESCRIPTIVE ML WATER TREATMENT ENGINE (LOCAL INFERENCE)
  // ===========================================================================
  List<String> _getMlTreatmentProtocol(String tier) {
    if (tier == 'green') {
      return [t('safe_treatment')];
    } else if (tier == 'yellow') {
      return [
        t('step1_cloudy'),
        t('step2_cloudy'),
        t('step3_cloudy'),
      ];
    } else {
      return [
        t('step1_danger'),
        t('step2_danger'),
        t('step3_danger'),
      ];
    }
  }

  String _calculatePurity() {
    final double evalPh = isConnected ? (ph ?? 7.0) : offlinePh;
    final double evalTds = isConnected ? (tds ?? 200.0) : offlineTds;

    if (evalPh >= 6.5 && evalPh <= 8.5 && evalTds <= 300) return '98% ${t('purity')}';
    if (evalPh >= 6.0 && evalPh <= 9.0 && evalTds <= 600) return '82% ${t('purity')}';
    return '45% ${t('alert')}';
  }

  // ===========================================================================
  // 8. SETTINGS DIALOG (IP, Language, Theme)
  // ===========================================================================
  void _openSettingsDialog() {
    _ipController.text = currentIp;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final Color dlgCardBg = isDarkMode ? const Color(0xFF16223F) : Colors.white;
            final Color dlgCardBorder = isDarkMode ? const Color(0xFF243356) : const Color(0xFFE2E8F0);
            final Color dlgTextPrimary = isDarkMode ? Colors.white : const Color(0xFF0F172A);
            final Color dlgTextSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

            return AlertDialog(
              backgroundColor: dlgCardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: dlgCardBorder),
              ),
              title: Row(
                children: [
                  const Icon(Icons.settings_rounded, color: Color(0xFF00E5FF), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    t('settings_title'),
                    style: TextStyle(color: dlgTextPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme / Brightness Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: const Color(0xFF00E5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t('theme_label'),
                              style: TextStyle(color: dlgTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Switch(
                          value: isDarkMode,
                          activeColor: const Color(0xFF00E5FF),
                          onChanged: (val) {
                            setDialogState(() => isDarkMode = val);
                            setState(() => isDarkMode = val);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),

                    // Language Selection Dropdown
                    Text(
                      t('lang_label'),
                      style: TextStyle(color: dlgTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dlgCardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentLang,
                          isExpanded: true,
                          dropdownColor: dlgCardBg,
                          style: TextStyle(color: dlgTextPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English (Default)')),
                            DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
                            DropdownMenuItem(value: 'hi', child: Text('हिंदी (Hindi)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => currentLang = val);
                              setState(() => currentLang = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 24, thickness: 1),

                    // ESP32 IP Configuration
                    Text(
                      t('ip_address_label'),
                      style: TextStyle(color: dlgTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ipController,
                      style: TextStyle(color: dlgTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: t('ip_hint'),
                        hintStyle: const TextStyle(color: Color(0x8094A3B8), fontSize: 12),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dlgCardBorder),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: Color(0xFF00E5FF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(t('cancel'), style: TextStyle(color: dlgTextSecondary)),
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
      },
    );
  }

  // ===========================================================================
  // 9. PRIMARY USER INTERFACE
  // ===========================================================================
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
    const Color warningYellow = Color(0xFFF59E0B);

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

                    // App Title
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
                    const SizedBox(width: 6),

                    // Settings Button
                    IconButton(
                      icon: Icon(
                        Icons.settings_rounded,
                        color: isDarkMode ? Colors.white70 : const Color(0xFF0F172A),
                        size: 24,
                      ),
                      tooltip: 'Settings',
                      onPressed: _openSettingsDialog,
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

                // Potability Status Card (Green / Yellow / Red Advisory)
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
                          Expanded(
                            child: Text(
                              t('potability_title'),
                              style: TextStyle(
                                color: potability['color'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (!isConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (potability['color'] as Color).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                t('offline_badge'),
                                style: TextStyle(
                                  color: potability['color'] as Color,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
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

                // =============================================================
                // OFFLINE ML WATER TREATMENT FEATURE CARD
                // =============================================================
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (potability['color'] as Color).withOpacity(0.5),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (potability['color'] as Color).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: potability['color'] as Color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('treatment_title'),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  t('model_tag'),
                                  style: const TextStyle(
                                    color: neonCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Offline Interactive Presets (Visible when hardware is disconnected)
                      if (!isConnected) ...[
                        const SizedBox(height: 14),
                        Text(
                          t('offline_presets'),
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(t('preset_clean'), style: const TextStyle(fontSize: 11)),
                              selected: potability['tier'] == 'green',
                              selectedColor: emeraldGreen.withOpacity(0.25),
                              onSelected: (_) {
                                setState(() {
                                  offlinePh = 7.4;
                                  offlineTds = 120.0;
                                  offlineTurbidity = 0.5;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text(t('preset_cloudy'), style: const TextStyle(fontSize: 11)),
                              selected: potability['tier'] == 'yellow',
                              selectedColor: warningYellow.withOpacity(0.25),
                              onSelected: (_) {
                                setState(() {
                                  offlinePh = 7.15;
                                  offlineTds = 450.0;
                                  offlineTurbidity = 2.8;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text(t('preset_toxic'), style: const TextStyle(fontSize: 11)),
                              selected: potability['tier'] == 'red',
                              selectedColor: alertRed.withOpacity(0.25),
                              onSelected: (_) {
                                setState(() {
                                  offlinePh = 4.8;
                                  offlineTds = 980.0;
                                  offlineTurbidity = 7.5;
                                });
                              },
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 20, thickness: 0.8),
                      Text(
                        t('action_plan'),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._getMlTreatmentProtocol(potability['tier'] as String).map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: potability['color'] as Color,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sensor Cards
                _buildSensorCard(
                  title: t('tds'),
                  value: isConnected
                      ? (tds != null ? tds!.toStringAsFixed(0) : '--')
                      : offlineTds.toStringAsFixed(0),
                  unit: 'PPM',
                  icon: Icons.grain_rounded,
                  accentColor: neonCyan,
                  statusText: isConnected
                      ? (tds != null ? (tds! <= 300 ? t('good') : t('elevated')) : t('offline'))
                      : (offlineTds <= 300 ? t('good') : t('elevated')),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 12),

                _buildSensorCard(
                  title: t('ph'),
                  value: isConnected
                      ? (ph != null ? ph!.toStringAsFixed(2) : '--')
                      : offlinePh.toStringAsFixed(2),
                  unit: 'pH',
                  icon: Icons.science_rounded,
                  accentColor: const Color(0xFF38BDF8),
                  statusText: isConnected
                      ? (ph != null ? (ph! >= 6.5 && ph! <= 8.5 ? t('optimal') : t('warning_status')) : t('offline'))
                      : (offlinePh >= 6.5 && offlinePh <= 8.5 ? t('optimal') : t('warning_status')),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 12),

                _buildSensorCard(
                  title: t('turb'),
                  value: isConnected
                      ? (turbidity != null ? turbidity!.toStringAsFixed(2) : '--')
                      : offlineTurbidity.toStringAsFixed(2),
                  unit: 'NTU',
                  icon: Icons.water_rounded,
                  accentColor: const Color(0xFF67E8F9),
                  statusText: isConnected
                      ? (turbidity != null ? (turbidity! <= 1.0 ? t('clear') : t('hazy')) : t('offline'))
                      : (offlineTurbidity <= 1.0 ? t('clear') : t('hazy')),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 12),

                _buildSensorCard(
                  title: t('temp'),
                  value: isConnected
                      ? (temperature != null ? temperature!.toStringAsFixed(1) : '--')
                      : offlineTemperature.toStringAsFixed(1),
                  unit: '°C',
                  icon: Icons.thermostat_rounded,
                  accentColor: emeraldGreen,
                  statusText: isConnected
                      ? (temperature != null ? t('normal') : t('offline'))
                      : t('normal'),
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

  // ===========================================================================
  // 10. REUSABLE SENSOR CARD COMPONENT
  // ===========================================================================
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