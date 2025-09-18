import 'package:flutter/material.dart';
import '../../../services/image_cache_service.dart';

class CacheInfoWidget extends StatefulWidget {
  const CacheInfoWidget({super.key});

  @override
  State<CacheInfoWidget> createState() => _CacheInfoWidgetState();
}

class _CacheInfoWidgetState extends State<CacheInfoWidget> {
  CacheInfo? _cacheInfo;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheInfo = await ImageCacheService().getCacheInfo();
      setState(() {
        _cacheInfo = cacheInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل معلومات التخزين المؤقت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح التخزين المؤقت'),
        content: const Text('هل أنت متأكد من مسح جميع الصور المخزنة مؤقتاً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isClearing = true;
      });

      try {
        await ImageCacheService().clearCache();
        await _loadCacheInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم مسح التخزين المؤقت بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في مسح التخزين المؤقت: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  Color _getUsageColor(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'معلومات التخزين المؤقت للصور',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : _loadCacheInfo,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_cacheInfo != null)
              Column(
                children: [
                  // معلومات الحجم
                  _buildInfoRow(
                    'الحجم المستخدم',
                    '${_cacheInfo!.totalSizeMB.toStringAsFixed(2)} MB',
                    Icons.storage,
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    'الحد الأقصى',
                    '${_cacheInfo!.maxSizeMB.toStringAsFixed(0)} MB',
                    Icons.storage_outlined,
                  ),
                  const SizedBox(height: 8),

                  // شريط التقدم
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'نسبة الاستخدام',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${_cacheInfo!.usagePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getUsageColor(
                                _cacheInfo!.usagePercentage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _cacheInfo!.usagePercentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getUsageColor(_cacheInfo!.usagePercentage),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // معلومات الملفات
                  _buildInfoRow(
                    'عدد الملفات',
                    '${_cacheInfo!.fileCount}',
                    Icons.image,
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    'الملفات الصالحة',
                    '${_cacheInfo!.validFiles}',
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 8),

                  _buildInfoRow(
                    'عمر التخزين الأقصى',
                    '${_cacheInfo!.maxAgeDays} يوم',
                    Icons.schedule,
                  ),
                  const SizedBox(height: 16),

                  // أزرار التحكم
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isClearing ? null : _clearCache,
                          icon: _isClearing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.delete_sweep),
                          label: Text(
                            _isClearing
                                ? 'جاري المسح...'
                                : 'مسح التخزين المؤقت',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              const Center(
                child: Text(
                  'لا توجد معلومات متاحة',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
