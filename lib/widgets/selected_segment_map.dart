import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_colors.dart';
import '../models/bus_location_model.dart';
import '../models/station.dart';
import '../l10n/localization_context.dart';

class SelectedSegmentMap extends StatefulWidget {
  const SelectedSegmentMap({
    super.key,
    required this.stations,
    this.location,
    this.roadPath = const [],
  });
  final List<Station> stations;
  final BusLocationModel? location;
  final List<LatLng> roadPath;

  @override
  State<SelectedSegmentMap> createState() => _SelectedSegmentMapState();
}

class _SelectedSegmentMapState extends State<SelectedSegmentMap> {
  bool failed = false;
  int retry = 0;
  late _MapTileClient client = createClient();
  _MapTileClient createClient() {
    final generation = retry;
    return _MapTileClient(() {
      if (!mounted || failed || generation != retry) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !failed && generation == retry) {
          setState(() => failed = true);
        }
      });
    });
  }

  late NetworkTileProvider provider = NetworkTileProvider(
    httpClient: client,
    silenceExceptions: true,
  );
  List<Station> get stations => widget.stations;
  BusLocationModel? get location => widget.location;

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final located = stations
        .where(
          (s) =>
              s.lat.isFinite &&
              s.lng.isFinite &&
              s.lat.abs() <= 90 &&
              s.lng.abs() <= 180 &&
              (s.lat != 0 || s.lng != 0),
        )
        .toList();
    if (located.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Map unavailable · stop coordinates have not been reviewed. Use the stop list.',
        ),
      );
    }
    final points = [
      ...widget.roadPath,
      for (final s in located) LatLng(s.lat, s.lng),
      if (location != null) LatLng(location!.latitude, location!.longitude),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: points.first,
                  initialZoom: 12,
                  initialCameraFit: points.length > 1
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(points),
                          padding: const EdgeInsets.all(36),
                          maxZoom: 15,
                        )
                      : null,
                ),
                children: [
                  TileLayer(
                    key: ValueKey(retry),
                    tileProvider: provider,
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.accesstransit.access_transit',
                  ),
                  if (widget.roadPath.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.roadPath,
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      for (final s in located)
                        Marker(
                          point: LatLng(s.lat, s.lng),
                          child: Tooltip(
                            message: s.name,
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              semanticLabel: s.name,
                            ),
                          ),
                        ),
                      if (location != null)
                        Marker(
                          point: LatLng(
                            location!.latitude,
                            location!.longitude,
                          ),
                          child: const Icon(
                            Icons.directions_bus,
                            color: AppColors.primary,
                            semanticLabel: 'Current bus location',
                          ),
                        ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(color: Colors.black, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            widget.roadPath.length > 1
                ? context.l10n.geometryMap
                : 'Stop locations · road route geometry unavailable',
          ),
          if (failed)
            TextButton(
              onPressed: () => setState(() {
                failed = false;
                retry++;
                client = createClient();
                provider = NetworkTileProvider(
                  httpClient: client,
                  silenceExceptions: true,
                );
              }),
              child: const Text(
                'Map tiles unavailable · retry or use the stop list',
              ),
            ),
          if (location != null)
            Text('Location updated: ${location!.timestamp}'),
        ],
      ),
    );
  }
}

class _MapTileClient extends http.BaseClient {
  _MapTileClient(this.onFailure);
  final void Function() onFailure;
  final http.Client delegate = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final response = await delegate.send(request);
      if (response.statusCode >= 400) onFailure();
      return response;
    } catch (_) {
      onFailure();
      rethrow;
    }
  }

  @override
  void close() => delegate.close();
}
