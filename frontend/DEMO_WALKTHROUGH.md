# ORCA Demo Walkthrough

Use Demo Mode from the onboarding or System & Data Health screen before the
walkthrough. The yellow `DEMO DATA` badge stays visible so fixture-backed
content is never presented as live production data.

1. Open **Map**. Point out the map, online status, layer control, legend, and
   the location control. Use **Recenter** only when browser GPS is available;
   otherwise the map honestly remains at its configured map area.
2. Tap the map to open the existing zone probe sheet. Show the supplied
   observation values, source footer, and freshness badge.
3. Point out the advisory safety chip. It reflects the existing advisory
   verdict and does not calculate a new safety decision in Flutter.
4. Open **Navigate**. Show the fixture-backed route check, detour waypoint,
   transit verdict, sampled points, and source list.
5. Open **System & Data Health**. Show the demo-mode switch, cache status, and
   the honest ORCA credibility statement.
6. Turn off network access. The app continues to label the session offline and
   can restore supported last-known location, zone, and route data from cache.

Fallback: if the backend, venue network, or GPS fails, enable Demo Mode from
**System & Data Health** and continue with the clearly labeled sample data.

The current frontend has no real fishing-zone polygon, IMBL geometry, sea
history, port-return route, SOS transport, or TTS contract, so the walkthrough
does not claim those features.