import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hazard.dart';
import '../services/geojson_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/hazard_card.dart';
import '../widgets/municipal_map_view.dart';

/// Municipal Intelligence & GIS Hazard Map Screen
class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  final StorageService _storageService = StorageService();
  String _selectedCategory = 'ALL';
  Hazard? _selectedHazard;

  final List<String> _categories = [
    'ALL',
    'POTHOLE',
    'ROAD CRACK',
    'OBSTACLE',
    'PEDESTRIAN',
    'DEBRIS',
  ];

  List<Hazard> get _filteredHazards {
    final list = _storageService.hazards;
    if (_selectedCategory == 'ALL') return list;
    return list
        .where((h) =>
            h.type.toUpperCase().replaceAll(' ', '_') ==
            _selectedCategory.replaceAll(' ', '_'))
        .toList();
  }

  void _showGeoJsonExportDialog() {
    final hazards = _storageService.hazards;
    final geoJsonString = GeoJsonService.exportGeoJsonString(hazards, pretty: true);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.primaryCyan, width: 1.2),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.public_rounded,
                      color: AppColors.primaryCyan, size: 22),
                  SizedBox(width: 10),
                  Text('MUNICIPAL GEOJSON', style: AppTextStyles.hudHeading),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusReady.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RFC 7946 VALID',
                  style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.statusReady,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hazards.length} road hazards packaged for Highway Authorities, PWD & Smart City Operations Centers.',
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.backgroundCardBorder),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        geoJsonString,
                        style: const TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 10,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('COPY GEOJSON',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: geoJsonString));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'GeoJSON FeatureCollection copied to clipboard!',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.backgroundCard,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHazards = _storageService.hazards;
    final total = allHazards.length;
    final critical = allHazards.where((h) => h.severity == 'CRITICAL').length;
    final high = allHazards.where((h) => h.severity == 'HIGH').length;
    final medium = allHazards.where((h) => h.severity == 'MEDIUM').length;
    final low = allHazards.where((h) => h.severity == 'LOW').length;

    final displayedHazards = _filteredHazards;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MUNICIPAL INTELLIGENCE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined,
                color: AppColors.primaryCyan),
            tooltip: 'Export GeoJSON',
            onPressed: _showGeoJsonExportDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Severity Counter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.backgroundSecondary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatPill('TOTAL', '$total', AppColors.textPrimary),
                  _buildStatPill('CRITICAL', '$critical', AppColors.severityCritical),
                  _buildStatPill('HIGH', '$high', AppColors.severityHigh),
                  _buildStatPill('MEDIUM', '$medium', AppColors.severityMedium),
                  _buildStatPill('LOW', '$low', AppColors.severityLow),
                ],
              ),
            ),

            // Category Selector Chips
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.background,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;

                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryCyan,
                    backgroundColor: AppColors.backgroundSecondary,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryCyan
                          : AppColors.backgroundCardBorder,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                          _selectedHazard = null;
                        });
                      }
                    },
                  );
                },
              ),
            ),

            // Vector GIS Map View Area
            Expanded(
              child: Stack(
                children: [
                  // Vector GIS Map Canvas
                  MunicipalMapView(
                    hazards: displayedHazards,
                    selectedHazard: _selectedHazard,
                    onHazardSelected: (hazard) {
                      setState(() {
                        _selectedHazard = hazard;
                      });
                    },
                  ),

                  // Map Legend & GPS center watermark
                  Positioned(
                    top: 12,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryCyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'DELHI-NCR SMART CORRIDOR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '28.6139° N, 77.2090° E • Offline Vector GIS',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tap guidance hint
                  if (_selectedHazard == null)
                    Positioned(
                      top: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.primaryCyan.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'TAP PIN TO INSPECT',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                  // Bottom Inspector Card when a hazard pin is tapped
                  if (_selectedHazard != null)
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: HazardCard(
                        hazard: _selectedHazard!,
                        showFullDetails: true,
                        onTap: () {
                          setState(() => _selectedHazard = null);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Action Bar: EXPORT GEOJSON
            Container(
              padding: const EdgeInsets.all(14),
              color: AppColors.backgroundSecondary,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.file_upload_outlined, size: 20),
                  label: const Text(
                    'EXPORT GEOJSON (RFC 7946)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  onPressed: _showGeoJsonExportDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.telemetrySmall.copyWith(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count,
          style: AppTextStyles.telemetryMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
