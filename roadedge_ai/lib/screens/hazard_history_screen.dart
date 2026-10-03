import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hazard.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/geo_utils.dart';
import '../widgets/hazard_card.dart';
import '../widgets/risk_indicator.dart';

/// HazardHistoryScreen - Local audit trail of all detected road hazards
class HazardHistoryScreen extends StatefulWidget {
  const HazardHistoryScreen({super.key});

  @override
  State<HazardHistoryScreen> createState() => _HazardHistoryScreenState();
}

class _HazardHistoryScreenState extends State<HazardHistoryScreen> {
  final StorageService _storageService = StorageService();
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];

  List<Hazard> get _filteredHazards {
    return _storageService.hazards.where((h) {
      final matchesFilter =
          _selectedFilter == 'ALL' || h.severity.toUpperCase() == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          h.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.roadName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _showHazardDetailDialog(Hazard hazard) {
    showDialog(
      context: context,
      builder: (context) {
        final color = AppColors.forSeverity(hazard.severity);
        final icon = GeoUtils.getHazardIcon(hazard.type);

        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hazard.type,
                      style: AppTextStyles.hudHeading.copyWith(fontSize: 18),
                    ),
                    Text(
                      hazard.id,
                      style: AppTextStyles.telemetrySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              RiskIndicator(severity: hazard.severity),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppColors.backgroundCardBorder),
              const SizedBox(height: 8),
              _buildDetailRow('Road Corridor', hazard.roadName),
              _buildDetailRow('Detection Confidence',
                  '${(hazard.confidence * 100).toStringAsFixed(1)}% (INT8)'),
              _buildDetailRow('Estimated Distance',
                  '${hazard.distance.toStringAsFixed(1)} meters'),
              _buildDetailRow('GNSS Coordinates',
                  GeoUtils.formatCoordinate(hazard.latitude, hazard.longitude)),
              _buildDetailRow('Detection Engine', hazard.source),
              _buildDetailRow('Municipal Status', hazard.status),
              _buildDetailRow('Timestamp', hazard.timestamp.toString()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final text =
                    '${hazard.type} at ${hazard.latitude}, ${hazard.longitude} (${hazard.severity})';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hazard details copied to clipboard')),
                );
                Navigator.pop(context);
              },
              child: const Text('COPY INFO',
                  style: TextStyle(color: AppColors.primaryCyan)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.telemetrySmall.copyWith(
                  fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.telemetryMedium.copyWith(
                  fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hazards = _filteredHazards;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('HAZARD HISTORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryCyan),
            tooltip: 'Reset to Sample Data',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _storageService.resetToSampleData();
              setState(() {});
              messenger.showSnackBar(
                const SnackBar(content: Text('Demo sample dataset restored.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by hazard class or road name...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primaryCyan, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.backgroundCardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.backgroundCardBorder),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),

            // Severity Filter Chips Row
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  final color = filter == 'ALL'
                      ? AppColors.primaryCyan
                      : AppColors.forSeverity(filter);

                  return ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: AppColors.backgroundSecondary,
                    side: BorderSide(
                      color: isSelected ? color : AppColors.backgroundCardBorder,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Hazard Count Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${hazards.length} RECORDED HAZARDS',
                    style: AppTextStyles.telemetrySmall.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'OFFLINE STORAGE',
                    style: AppTextStyles.badgeText.copyWith(
                      color: AppColors.statusReady,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Hazard Cards List
            Expanded(
              child: hazards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No hazards matching criteria',
                              style: AppTextStyles.hudSubheading),
                          const SizedBox(height: 6),
                          Text('Drive to detect road hazards or reset demo dataset',
                              style: AppTextStyles.body),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: hazards.length,
                      itemBuilder: (context, index) {
                        final hazard = hazards[index];
                        return HazardCard(
                          hazard: hazard,
                          showFullDetails: true,
                          onTap: () => _showHazardDetailDialog(hazard),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
