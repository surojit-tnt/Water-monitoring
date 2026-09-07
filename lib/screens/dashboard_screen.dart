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
  // ==========================================
  // 1. STATE CONFIGURATION
  // ==========================================
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

  // ==========================================
  // 2. LOCALIZATION DICTIONARY
  // ==========================================
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
      'desc_drinkable': 'All chemical, mineral, and physical parameters are within safe drinking limits.',
      'desc_domestic': 'Water is turbid or warm/mineralized. Unfit for drinking, but safe for washing and bathing.',
      'desc_toxic': 'Hazardous water parameters detected. Severe toxicity or physical hazard risk.',
      'desc_thermal_danger': 'Extreme thermal hazard detected. Immediate scalding risk or sensor fault.',
      'health_alerts_title': 'DETECTED PARAMETER WARNINGS',
      
      // Health Warnings
      'alert_ph_low': 'Acidic Water: Risk of gastrointestinal irritation and heavy metal leaching from pipes.',
      'alert_ph_high': 'Alkaline Water: Bitter taste, skin dryness/irritation, and digestive disruption.',
      'alert_tds_high': 'High TDS: Excess minerals strain kidney filtration and create digestive discomfort.',
      'alert_turb_high': 'High Turbidity: Suspended matter shields bacteria and pathogens from disinfection.',
      'alert_temp_high': 'Elevated Temperature: Accelerates bacterial growth and microbial pathogen incubation.',
      'alert_temp_critical': 'Critical Thermal Hazard: Temperature exceeds safe physical limits. Severe burn risk.',
      
      // Dynamic Water Treatment Protocols
      'treatment_title': 'WATER TREATMENT PROTOCOL',
      'treatment_sub': 'Parameter-Specific Purification Guide',
      'action_plan': 'TAILORED PURIFICATION PLAN',
      'tap_details': 'Tap for Hardware Automation',
      'in_progress_title': 'Feature In Progress',
      'in_progress_desc': 'Automated chemical dosing valves and IoT peristaltic pump control are currently under development in firmware v2.0.',
      'in_progress_ok': 'UNDERSTOOD',
      'safe_treatment': 'Water meets all WHO potability standards. No chemical neutralization required. Optional 1-micron polish or UV-C sterilization for storage.',
      'remedy_ph_low': 'pH Neutralization: Water is acidic (<6.5). Dose with food-grade Sodium Bicarbonate (Baking Soda) or filter through Calcite mineral beds until pH reaches 7.2.',
      'remedy_ph_high': 'Alkaline Buffer: Water is excessively alkaline (>8.5). Buffer by infusing food-grade Citric Acid or blending with demineralized neutral water.',
      'remedy_tds': 'RO Desalination: High TDS detected (>300 PPM). Run water through a multi-stage Reverse Osmosis (RO) membrane (>50 PSI) to filter heavy mineral salts down below 150 PPM.',
      'remedy_turb': 'Coagulation & Sedimentation: Turbidity is elevated (>1.0 NTU). Add 10-15 mg/L Alum (fitkari), stir gently for 1 minute, settle for 30 minutes, then filter through activated carbon.',
      'remedy_temp_high': 'Thermal Dissipation: Water is too hot (>35°C). Allow natural convection cooling to 20-25°C before handling to eliminate burn risk and halt bacterial incubation.',
      'remedy_temp_low': 'Low Temperature / Sensor Check: Temperature reading is <= 0°C. Verify fluid phase against freezing or inspect DS18B20 sensor wiring connection.',
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
      'desc_drinkable': 'জলের সমস্ত রাসায়নিক ও শারীরিক উপাদান পানের জন্য সম্পূর্ণ নিরাপদ।',
      'desc_domestic': 'জলটি ঘোলাটে বা গরম/অতিরিক্ত খনিজযুক্ত। পানের অযোগ্য, তবে স্নান ও ধোয়ার জন্য নিরাপদ।',
      'desc_toxic': 'মারাত্মক ক্ষতিকর জল সনাক্ত হয়েছে। বিষাক্ততার উচ্চ ঝুঁকি রয়েছে।',
      'desc_thermal_danger': 'মারাত্মক তাপমাত্রার ঝুঁকি সনাক্ত হয়েছে। গুরুতরভাবে পুড়ে যাওয়ার ঝুঁকি বা সেন্সর ত্রুটি।',
      'health_alerts_title': 'সনাক্তকৃত স্বাস্থ্য ঝুঁকি ও সতর্কতা',
      
      // Health Warnings
      'alert_ph_low': 'অম্লীয় জল (Low pH): পেটের সমস্যা, দাঁতের এনামেল ক্ষয় এবং পাইপ থেকে বিষাক্ত ধাতু দ্রবীভূত হওয়ার ঝুঁকি।',
      'alert_ph_high': 'ক্ষারীয় জল (High pH): সাবানের মতো কটু স্বাদ, ত্বকে চুলকানি/শুষ্কতা এবং হজম প্রক্রিয়ায় বিঘ্ন।',
      'alert_tds_high': 'উচ্চ TDS: অতিরিক্ত খনিজের উপস্থিতি কিডনির উপর চাপ বৃদ্ধি করে এবং পেটের ব্যাধি ঘটায়।',
      'alert_turb_high': 'উচ্চ ঘোলাটে ভাব (Turbidity): ভাসমান ধূলিকণা ক্ষতিকর জীবাণু ও পরজীবীকে ফিল্টারিং থেকে রক্ষা করে।',
      'alert_temp_high': 'উচ্চ তাপমাত্রা: ক্ষতিকর ব্যাকটেরিয়া এবং অণুজীবের বংশবৃদ্ধির হার বিপজ্জনকভাবে বৃদ্ধি পায়।',
      'alert_temp_critical': 'মারাত্মক তাপীয় ঝুঁকি: জলের তাপমাত্রা অত্যন্ত বিপজ্জনক। তীব্রভাবে পুড়ে যাওয়ার চরম ঝুঁকি রয়েছে।',
      
      // Dynamic Water Treatment Protocols
      'treatment_title': 'জল শোধন নির্দেশিকা',
      'treatment_sub': 'প্যারামিটার-ভিত্তিক পরিশোধন প্রক্রিয়া',
      'action_plan': 'নির্দিষ্ট পরিশোধন পরিকল্পনা',
      'tap_details': 'হার্ডওয়্যার অটোমেশনের জন্য স্পর্শ করুন',
      'in_progress_title': 'বৈশিষ্ট্যটি প্রক্রিয়াধীন',
      'in_progress_desc': 'স্বয়ংক্রিয় রাসায়নিক নিয়ন্ত্রক পাম্প এবং হার্ডওয়্যার ডোজার মডিউল ফার্মওয়্যার v2.0 সংস্করণে নির্মাণাধীন রয়েছে।',
      'in_progress_ok': 'বুঝেছি',
      'safe_treatment': 'জলটি পানের জন্য সম্পূর্ণ নিরাপদ। অতিরিক্ত রাসায়নিক শোধনের প্রয়োজন নেই। দীর্ঘমেয়াদী সংরক্ষণের জন্য সাধারণ UV ব্যবহার করতে পারেন।',
      'remedy_ph_low': 'pH সমতাকরণ: জল অম্লীয় (<৬.৫)। বেকিং সোডা মেশান অথবা ক্যালসাইট ফিল্টারের মধ্য দিয়ে চালিয়ে pH ৭.২-এ আনুন।',
      'remedy_ph_high': 'ক্ষারীয়তা হ্রাস: জল অতিরিক্ত ক্ষারীয় (>৮.৫)। পরিমিত সাইট্রিক অ্যাসিড বা সাধারণ জল মিশিয়ে pH স্বাভাবিক মাত্রায় আনুন।',
      'remedy_tds': 'RO ফিল্টারিং: উচ্চ TDS (>৩০০ PPM) দূর করতে জলটিকে উচ্চচাপযুক্ত রিভার্স অসমোসিস (RO) মেমব্রেনের মধ্য দিয়ে চালান।',
      'remedy_turb': 'থিতানো ও ফিল্টারিং: ঘোলাটে ভাব দূর করতে প্রতি লিটারে ১০-১৫ মিলিগ্রাম ফটকিরি মেশান এবং কার্বন ফিল্টার ব্যবহার করুন।',
      'remedy_temp_high': 'তাপমাত্রা হ্রাস: জল অত্যন্ত গরম (>৩৫°C)। ব্যবহারের পূর্বে জল স্বাভাবিক তাপমাত্রায় (২০-২৫°C) ঠান্ডা হতে দিন।',
      'remedy_temp_low': 'হিমায়িত/সেন্সর পরীক্ষা: তাপমাত্রা <= ০°C। বরফ পরীক্ষা করুন অথবা তাপমাত্রা সেন্সরের তার পরীক্ষা করুন।',
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
      'desc_drinkable': 'सभी रासायनिक, खनिज और भौतिक मानक सुरक्षित पेयजल सीमा के भीतर हैं।',
      'desc_domestic': 'पानी धुंधला या गर्म/खनिजों से युक्त है। पीने योग्य नहीं, लेकिन नहाने और धोने के लिए सुरक्षित।',
      'desc_toxic': 'घातक स्तर पाया गया। पानी का सेवन या उपयोग न करें।',
      'desc_thermal_danger': 'अत्यधिक तापीय खतरा। जलने का गंभीर जोखिम या सेंसर में खराबी।',
      'health_alerts_title': 'स्वास्थ्य जोखिम एवं चेतावनियाँ',
      
      // Health Warnings
      'alert_ph_low': 'अम्लीय पानी (Low pH): पेट में जलन, दांतों के क्षरण और पाइप से जहरीली धातुओं के घुलने का खतरा।',
      'alert_ph_high': 'क्षारीय पानी (High pH): कड़वा साबुन जैसा स्वाद, त्वचा में सूखापन और पाचन एंजाइमों में व्यवधान।',
      'alert_tds_high': 'उच्च TDS: अत्यधिक खनिज गुर्दे (किडनी) पर दबाव डालते हैं और पेट की समस्याएं पैदा करते हैं।',
      'alert_turb_high': 'अधिक मैलापन (Turbidity): निलंबित कण हानिकारक बैक्टीरिया और कीटाणुओं को नष्ट होने से बचाते हैं।',
      'alert_temp_high': 'उच्च तापमान: बैक्टीरिया और संक्रामक रोगाणुओं के तेजी से पनपने का खतरा बढ़ता है।',
      'alert_temp_critical': 'गंभीर तापीय जोखिम: तापमान अत्यधिक खतरनाक स्तर पर है। जलने का तीव्र खतरा।',
      
      // Dynamic Water Treatment Protocols
      'treatment_title': 'जल शोधन प्रोटोकॉल',
      'treatment_sub': 'पैरामीटर-आधारित शुद्धिकरण गाइड',
      'action_plan': 'विशिष्ट शुद्धिकरण योजना',
      'tap_details': 'हार्डवेयर ऑटोमेशन के लिए टैप करें',
      'in_progress_title': 'सुविधा प्रगति पर है',
      'in_progress_desc': 'स्वचालित रासायनिक नियंत्रण वाल्व और पंप डोजिंग सिस्टम फर्मवेयर v2.0 के लिए निर्माणाधीन है।',
      'in_progress_ok': 'ठीक है',
      'safe_treatment': 'जल पीने के लिए पूरी तरह सुरक्षित है। किसी रासायनिक प्रक्रिया की आवश्यकता नहीं है। भंडारण के लिए वैकल्पिक यूवी (UV) शुद्धिकरण करें।',
      'remedy_ph_low': 'pH संतुलन: पानी अम्लीय है (<6.5)। बेकिंग सोडा मिलाएं या कैल्साइट फिल्टर से गुजार कर pH 7.2 तक लाएं।',
      'remedy_ph_high': 'क्षारीयता में कमी: पानी अधिक क्षारीय है (>8.5)। साइट्रिक एसिड या सामान्य पानी मिलाकर pH को सामान्य करें।',
      'remedy_tds': 'RO शुद्धिकरण: उच्च TDS (>300 PPM) के लिए पानी को रिवर्स ऑस्मोसिस (RO) मेम्ब्रेन से गुजारें।',
      'remedy_turb': 'स्कंदन और निस्पंदन: मैलापन हटाने के लिए १०-१५ मिलीग्राम फिटकरी मिलाएं और एक्टिवेटेड कार्बन फिल्टर से छानें।',
      'remedy_temp_high': 'तापमान सामान्य करें: पानी अत्यधिक गर्म है (>35°C)। उपयोग से पहले इसे सामान्य तापमान (20-25°C) तक ठंडा होने दें।',
      'remedy_temp_low': 'कम तापमान / सेंसर जांच: तापमान <= 0°C है। पानी के जमने या सेंसर कनेक्शन की जांच करें।',
    }
  };

  String t(String key) => _dict[currentLang]?[key] ?? _dict['en']![key]!;

  // ==========================================
  // 3. LIFECYCLE & BACKGROUND POLLING
  // ==========================================
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

  // ==========================================
  // 4. HTTP TELEMETRY CLIENT
  // ==========================================
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

  // ==========================================
  // 5. PRESENTATION SIMULATION (DEMO MODE)
  // ==========================================
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

  // ==========================================
  // 6. POTABILITY & BIOLOGICAL EFFECTS ENGINE
  // ==========================================
  Map<String, dynamic>? _getPotabilityAnalysis() {
    if (!isConnected || ph == null || tds == null || turbidity == null) return null;

    final List<String> healthAlerts = [];
    final double temp = temperature ?? 25.0;

    // Health Effect Warnings
    if (ph! < 6.5) {
      healthAlerts.add(t('alert_ph_low'));
    } else if (ph! > 8.5) {
      healthAlerts.add(t('alert_ph_high'));
    }

    if (tds! > 500) {
      healthAlerts.add(t('alert_tds_high'));
    }

    if (turbidity! > 5.0) {
      healthAlerts.add(t('alert_turb_high'));
    }

    if (temp >= 50.0 || temp < 0.0) {
      healthAlerts.add(t('alert_temp_critical'));
    } else if (temp > 28.0) {
      healthAlerts.add(t('alert_temp_high'));
    }

    // RED TIER: Severe Contamination, Extreme Turbidity/TDS, or Hazardous Temp
    final bool isToxic = ph! < 5.5 || ph! > 9.5 || tds! > 1000 || turbidity! > 10.0 || temp >= 50.0 || temp < 0.0;
    if (isToxic) {
      return {
        'status': t('status_toxic'),
        'description': (temp >= 50.0 || temp < 0.0)
            ? t('desc_thermal_danger')
            : t('desc_toxic'),
        'color': const Color(0xFFF43F5E), // Danger Red
        'icon': Icons.cancel_rounded,
        'tier': 'red',
        'alerts': healthAlerts,
      };
    }

    // YELLOW TIER: Sub-optimal pH, elevated TDS, turbidity > 5 NTU, or hot water
    final bool isDomesticOnly =
        (ph! < 6.5 || ph! > 8.5) || (tds! > 500) || (turbidity! > 5.0) || (temp > 35.0);
    if (isDomesticOnly) {
      return {
        'status': t('status_domestic'),
        'description': t('desc_domestic'),
        'color': const Color(0xFFF59E0B), // Advisory Yellow
        'icon': Icons.warning_amber_rounded,
        'tier': 'yellow',
        'alerts': healthAlerts,
      };
    }

    // GREEN TIER: Fully Potable & Safe
    return {
      'status': t('status_drinkable'),
      'description': t('desc_drinkable'),
      'color': const Color(0xFF10B981), // Safe Green
      'icon': Icons.check_circle_rounded,
      'tier': 'green',
      'alerts': healthAlerts,
    };
  }

  // ==========================================
  // 7. SPECIFIC PARAMETER-DRIVEN TREATMENT ENGINE
  // ==========================================
  List<String> _getSpecificTreatmentProtocol() {
    final List<String> protocols = [];
    final double temp = temperature ?? 25.0;

    // 1. Thermal Anomalies
    if (temp >= 35.0) {
      protocols.add(t('remedy_temp_high'));
    } else if (temp <= 0.0) {
      protocols.add(t('remedy_temp_low'));
    }

    // 2. pH Anomalies
    if (ph != null && ph! < 6.5) {
      protocols.add(t('remedy_ph_low'));
    } else if (ph != null && ph! > 8.5) {
      protocols.add(t('remedy_ph_high'));
    }

    // 3. Turbidity / Clarity Anomalies
    if (turbidity != null && turbidity! > 1.0) {
      protocols.add(t('remedy_turb'));
    }

    // 4. TDS / Mineral Load Anomalies
    if (tds != null && tds! > 300) {
      protocols.add(t('remedy_tds'));
    }

    // 5. Default Safe Treatment
    if (protocols.isEmpty) {
      protocols.add(t('safe_treatment'));
    }

    return protocols;
  }

  // Synchronized Purity Rating matching sensor limits
  String _calculatePurity() {
    if (!isConnected || ph == null || tds == null || turbidity == null) return '-- ${t('purity')}';
    final double temp = temperature ?? 25.0;

    if (temp >= 50.0 || temp < 0.0 || ph! < 5.5 || ph! > 9.5 || tds! > 1000 || turbidity! > 10.0) {
      return '15% ${t('alert')}';
    }

    if (temp > 35.0 || ph! < 6.5 || ph! > 8.5 || tds! > 500 || turbidity! > 5.0) {
      return '68% ${t('alert')}';
    }

    return '98% ${t('purity')}';
  }

  // ==========================================
  // 8. POP-UP: FEATURE IN PROGRESS DIALOG
  // ==========================================
  void _showInProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        final Color dlgBg = isDarkMode ? const Color(0xFF16223F) : Colors.white;
        final Color dlgBorder = isDarkMode ? const Color(0xFF243356) : const Color(0xFFE2E8F0);
        final Color dlgText = isDarkMode ? Colors.white : const Color(0xFF0F172A);

        return AlertDialog(
          backgroundColor: dlgBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: dlgBorder),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0x3300E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.engineering_rounded, color: Color(0xFF00E5FF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('in_progress_title'),
                  style: TextStyle(color: dlgText, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            t('in_progress_desc'),
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                t('in_progress_ok'),
                style: const TextStyle(color: Color(0xFF0B132B), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 9. SETTINGS DIALOG (IP, Language, Theme)
  // ==========================================
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

  // ==========================================
  // 10. PRIMARY USER INTERFACE
  // ==========================================
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
    final specificProtocols = _getSpecificTreatmentProtocol();

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

                // ==========================================
                // 4 SENSOR CARDS
                // ==========================================
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
                  statusText: isConnected ? (turbidity! <= 5.0 ? t('clear') : t('hazy')) : t('offline'),
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
                  statusText: isConnected
                      ? ((temperature! >= 50.0 || temperature! < 0.0)
                          ? t('warning_status')
                          : (temperature! > 28.0 ? t('elevated') : t('normal')))
                      : t('offline'),
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),

                // =============================================================
                // END SCREEN: WATER USAGE ADVISORY & PHYSIOLOGICAL WARNINGS
                // =============================================================
                if (isConnected && potability != null) ...[
                  // Potability Status Card
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
                        
                        // Parameter Biological/Health Alerts
                        if ((potability['alerts'] as List).isNotEmpty) ...[
                          const Divider(height: 22, thickness: 0.8),
                          Text(
                            t('health_alerts_title'),
                            style: TextStyle(
                              color: potability['color'] as Color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...List.generate(
                            (potability['alerts'] as List).length,
                            (idx) => Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: potability['color'] as Color,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      potability['alerts'][idx],
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 11.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===========================================================
                  // INTERACTIVE WATER TREATMENT PROTOCOL CARD
                  // Tapping triggers the "Feature In Progress" dialog
                  // ===========================================================
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _showInProgressDialog,
                    child: Container(
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
                                      t('treatment_sub'),
                                      style: const TextStyle(
                                        color: neonCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0x2600E5FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0x6600E5FF)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.touch_app_rounded, color: neonCyan, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      t('tap_details'),
                                      style: const TextStyle(
                                        color: neonCyan,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                          ...specificProtocols.map(
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
                  ),
                  const SizedBox(height: 16),
                ],

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

  // ==========================================
  // 11. REUSABLE SENSOR CARD COMPONENT
  // ==========================================
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