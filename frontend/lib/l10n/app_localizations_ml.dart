// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appName => 'ORCA';

  @override
  String get appTagline =>
      'സഹകരണ ഏജന്റുകളോടെയുള്ള സമുദ്രസ്ഥിതിയും സുരക്ഷാ ഉപദേശവും';

  @override
  String get tabHome => 'ഹോം';

  @override
  String get tabMap => 'ഭൂപടം';

  @override
  String get tabAi => 'AI ഏജന്റുകൾ';

  @override
  String get tabAlerts => 'മുന്നറിയിപ്പുകൾ';

  @override
  String get tabNavigate => 'വഴി';

  @override
  String get tabInfo => 'വിവരം';

  @override
  String get verdictGo => 'പോകുന്നത് സുരക്ഷിതം';

  @override
  String get verdictCaution => 'ജാഗ്രത';

  @override
  String get verdictNoGo => 'അപകടം — പോകരുത്';

  @override
  String get verdictUnknown => 'അജ്ഞാതം';

  @override
  String get canIGoTitle => 'ഇന്ന് കടലിൽ പോകാമോ?';

  @override
  String get safeWindowLabel => 'സുരക്ഷിത സമയം';

  @override
  String get noSafeWindow => 'No safe window in next 48 hours';

  @override
  String get variablesTitle => 'നിലവിലെ സ്ഥിതി';

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
  String get alertsTitle => 'സജീവ സമുദ്ര മുന്നറിയിപ്പുകൾ';

  @override
  String get noActiveAlerts => 'No active weather or cyclone warnings';

  @override
  String get navigateTitle => 'വഴി സുരക്ഷയും കര പരിശോധനയും';

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
  String get infoTitle => 'സിസ്റ്റവും ഡാറ്റ നിലയും';

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
  String get languageLabel => 'ഭാഷ';

  @override
  String get aboutOrca => 'About ORCA SIH26176 (ISRO)';

  @override
  String get save => 'സംരക്ഷിക്കുക';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get retry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get offlineBanner =>
      'You are offline. Showing last verified cached advisory.';
}
