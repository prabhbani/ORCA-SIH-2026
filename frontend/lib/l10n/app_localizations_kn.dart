// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appName => 'ORCA';

  @override
  String get appTagline =>
      'ಸಹಯೋಗಿ ಏಜೆಂಟ್‌ಗಳೊಂದಿಗೆ ಸಮುದ್ರ ಸ್ಥಿತಿ ಮತ್ತು ಸುರಕ್ಷತಾ ಸಲಹೆ';

  @override
  String get tabHome => 'ಮುಖಪುಟ';

  @override
  String get tabMap => 'ನಕ್ಷೆ';

  @override
  String get tabAi => 'AI ಏಜೆಂಟ್‌ಗಳು';

  @override
  String get tabAlerts => 'ಎಚ್ಚರಿಕೆಗಳು';

  @override
  String get tabNavigate => 'ಮಾರ್ಗ';

  @override
  String get tabInfo => 'ಮಾಹಿತಿ';

  @override
  String get verdictGo => 'ಹೋಗಲು ಸುರಕ್ಷಿತ';

  @override
  String get verdictCaution => 'ಎಚ್ಚರಿಕೆ';

  @override
  String get verdictNoGo => 'ಅಪಾಯ — ಹೋಗಬೇಡಿ';

  @override
  String get verdictUnknown => 'ತಿಳಿದಿಲ್ಲ';

  @override
  String get canIGoTitle => 'ಇಂದು ಸಮುದ್ರಕ್ಕೆ ಹೋಗಬಹುದೇ?';

  @override
  String get safeWindowLabel => 'ಸುರಕ್ಷಿತ ಸಮಯ';

  @override
  String get noSafeWindow => 'No safe window in next 48 hours';

  @override
  String get variablesTitle => 'ಪ್ರಸ್ತುತ ಸ್ಥಿತಿ';

  @override
  String get hourlyForecastTitle => '48-Hour Wave & Wind Forecast';

  @override
  String get sourceLabel => 'Source';

  @override
  String get dataFreshnessLabel => 'Freshness';

  @override
  String get freshStatus => 'Fresh (<30m)';

  @override
  String get recentStatus => 'Recent (<3h)';

  @override
  String get staleStatus => 'Stale';

  @override
  String get unreachableStatus => 'Unreachable';

  @override
  String get waveHeight => 'Wave Height';

  @override
  String get windSpeed => 'Wind Speed';

  @override
  String get windGusts => 'Wind Gusts';

  @override
  String get seaTemp => 'Sea Surface Temp';

  @override
  String get oceanCurrent => 'Ocean Current';

  @override
  String get mapProbeTapPrompt =>
      'Tap any ocean point on the map to probe conditions';

  @override
  String get mapLayersTitle => 'Data Layers';

  @override
  String get synopticOverlay => 'Synoptic Weather Overlay';

  @override
  String get locateMe => 'Locate Me';

  @override
  String get probeCoordinates => 'Location';

  @override
  String get probeChlorophyll => 'Chlorophyll-a';

  @override
  String get probeFishingEffort => 'Fishing Effort';

  @override
  String get aiAgentsTitle => 'Collaborative Multi-Agent System';

  @override
  String get aiRunAnalysis => 'Run 10-Agent Analysis';

  @override
  String get aiRunning => 'Agents collaborating...';

  @override
  String get aiCollaborationTrace => 'Agent Collaboration Trace';

  @override
  String get aiOrchestrationSynthesis => 'Orchestrator Synthesis';

  @override
  String get aiChatTitle => 'Marine Advisory Assistant';

  @override
  String get aiChatUnavailable =>
      'Ollama LLM chat is currently paused by design choice to conserve edge resources.';

  @override
  String get aiChatInputHint => 'Ask about ocean conditions...';

  @override
  String get alertsTitle => 'ಸಕ್ರಿಯ ಸಮುದ್ರ ಎಚ್ಚರಿಕೆಗಳು';

  @override
  String get noActiveAlerts => 'No active weather or cyclone warnings';

  @override
  String get navigateTitle => 'ಮಾರ್ಗ ಸುರಕ್ಷತೆ ಮತ್ತು ಭೂ ಪರಿಶೀಲನೆ';

  @override
  String get fromPort => 'Departure Port / Point';

  @override
  String get toDestination => 'Destination / Fishing Spot';

  @override
  String get checkRouteButton => 'Verify Route Safety';

  @override
  String get detourWaypoint => 'Detour Waypoint';

  @override
  String get landVerifiedClear => 'Land Check: Verified Clear';

  @override
  String get landDetourRequired => 'Detour Required (Avoids Land)';

  @override
  String get landBlocked => 'Route Blocked by Land';

  @override
  String get transitVerdict => 'Transit Safety Verdict';

  @override
  String get infoTitle => 'ವ್ಯವಸ್ಥೆ ಮತ್ತು ಡೇಟಾ ಸ್ಥಿತಿ';

  @override
  String get serverUrlLabel => 'ORCA Box Server URL';

  @override
  String get serverUrlChange => 'Change Server URL';

  @override
  String get serverUrlDialogTitle => 'Configure Server URL';

  @override
  String get serverUrlHint => 'http://10.0.2.2:8000 or http://192.168.1.x:8000';

  @override
  String get checkHealthButton => 'Check Data Sources Health';

  @override
  String get dataSourceCatalog => 'Provider Source Status';

  @override
  String get cacheManagement => 'Local Storage & Cache';

  @override
  String get clearCache => 'Clear Cached Data';

  @override
  String get languageLabel => 'ಭಾಷೆ';

  @override
  String get aboutOrca => 'About ORCA SIH26176 (ISRO)';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get cancel => 'ರದ್ದು';

  @override
  String get retry => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get offlineBanner =>
      'You are offline. Showing last verified cached advisory.';
}
