import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouda_market/core/services/dashboard_service.dart';
import 'package:fouda_market/core/services/dashboard/helpers.dart';
import '../widgets/detailed_activity_item.dart';

class AllActivityScreen extends StatefulWidget {
  const AllActivityScreen({super.key});

  @override
  State<AllActivityScreen> createState() => _AllActivityScreenState();
}

class _AllActivityScreenState extends State<AllActivityScreen> {
  DateTime? selectedDate;
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> allActivities = [];

  // متغيرات pagination
  dynamic _lastTimestamp;
  String? _lastDocumentId;
  String? _lastType;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  Future<void> _loadAllActivities() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _dashboardService.getRecentActivityPaginated(
        limit: 20,
      );

      if (mounted) {
        setState(() {
          allActivities = result['activities'] as List<Map<String, dynamic>>;
          _hasMore = result['hasMore'] as bool;
          _lastTimestamp = result['lastTimestamp'];
          _lastDocumentId = result['lastDocumentId'] as String?;
          _lastType = result['lastType'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل النشاطات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreActivities() async {
    if (!_hasMore || _isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final result = await _dashboardService.getRecentActivityPaginated(
        limit: 20,
        lastTimestamp: _lastTimestamp,
        lastDocumentId: _lastDocumentId,
        lastType: _lastType,
      );

      if (mounted) {
        // فلترة النشاطات الجديدة حسب الشهر الأخير
        final now = DateTime.now();
        final monthAgo = now.subtract(const Duration(days: 30));
        final newActivities =
            (result['activities'] as List<Map<String, dynamic>>)
                .where((a) {
                  final activityDate = parseTimestamp(a['timestamp']);
                  return activityDate.isAfter(monthAgo) &&
                      activityDate.isBefore(now.add(const Duration(days: 1)));
                })
                // منع التكرار
                .where((a) => !allActivities.any((b) => b['id'] == a['id']))
                .toList();

        setState(() {
          allActivities.addAll(newActivities);
          // إذا لم نجد نشاطات حديثة في الصفحة الجديدة، أوقف التحميل
          if (newActivities.isEmpty) {
            _hasMore = false;
          } else {
            _hasMore = result['hasMore'] as bool;
          }
          _lastTimestamp = result['lastTimestamp'];
          _lastDocumentId = result['lastDocumentId'] as String?;
          _lastType = result['lastType'] as String?;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المزيد من النشاطات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredActivities {
    if (selectedDate != null) {
      return allActivities.where((a) {
        final activityDate = parseTimestamp(a['timestamp']);
        return activityDate.day == selectedDate!.day &&
            activityDate.month == selectedDate!.month &&
            activityDate.year == selectedDate!.year;
      }).toList();
    }
    return allActivities;
  }

  String get dateLabel {
    if (selectedDate == null) return 'الكل';
    final d = selectedDate!;
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMore) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMoreActivities,
                child: const Text('تحميل المزيد'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كل النشاطات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllActivities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(dateLabel),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      if (selectedDate != null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => setState(() => selectedDate = null),
                          child: const Text('الكل'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredActivities.isEmpty
                        ? const Center(
                            child: Text('لا يوجد نشاطات في هذا اليوم'),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scrollInfo) {
                              if (scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent) {
                                if (_hasMore && !_isLoadingMore) {
                                  _loadMoreActivities();
                                }
                              }
                              return true;
                            },
                            child: ListView.separated(
                              itemCount:
                                  filteredActivities.length +
                                  (_hasMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == filteredActivities.length) {
                                  return _buildLoadMoreIndicator();
                                }

                                final activity = filteredActivities[index];
                                return DetailedActivityItem(
                                  icon: activity['icon'],
                                  iconColor: activity['iconColor'],
                                  text: activity['text'],
                                  time: activity['time'],
                                  details: activity['details'],
                                  activityData: activity,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
