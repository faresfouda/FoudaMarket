import 'package:flutter/material.dart';
import 'dart:io';
import '../../../services/image_compression_service.dart';

class ImageCompressionInfoWidget extends StatefulWidget {
  final File? imageFile;
  final VoidCallback? onCompress;

  const ImageCompressionInfoWidget({super.key, this.imageFile, this.onCompress});

  @override
  State<ImageCompressionInfoWidget> createState() =>
      _ImageCompressionInfoWidgetState();
}

class _ImageCompressionInfoWidgetState
    extends State<ImageCompressionInfoWidget> {
  Map<String, dynamic>? _fileInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  @override
  void didUpdateWidget(ImageCompressionInfoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageFile != widget.imageFile) {
      _loadFileInfo();
    }
  }

  Future<void> _loadFileInfo() async {
    if (widget.imageFile == null) {
      setState(() => _fileInfo = null);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final info = await ImageCompressionService().getFileInfo(
        widget.imageFile!,
      );
      setState(() => _fileInfo = info);
    } catch (e) {
      debugPrint('خطأ في تحميل معلومات الملف: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageFile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'معلومات الصورة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_fileInfo != null)
            _buildFileInfo()
          else
            const Text('لا يمكن تحميل معلومات الملف'),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    final sizeInMB = _fileInfo!['sizeInMB'] as double;
    final sizeInKB = _fileInfo!['sizeInKB'] as double;

    // تحديد لون التحذير حسب الحجم
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (sizeInMB > 5) {
      statusColor = Colors.red;
      statusText = 'ملف كبير جداً - يوصى بالضغط';
      statusIcon = Icons.warning;
    } else if (sizeInMB > 2) {
      statusColor = Colors.orange;
      statusText = 'ملف كبير - يوصى بالضغط';
      statusIcon = Icons.info;
    } else if (sizeInMB > 1) {
      statusColor = Colors.yellow[700]!;
      statusText = 'ملف متوسط - ضغط اختياري';
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = Colors.green;
      statusText = 'حجم مناسب';
      statusIcon = Icons.check_circle;
    }

    return Column(
      children: [
        // معلومات الحجم
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                'الحجم',
                '${sizeInMB.toStringAsFixed(2)} MB (${sizeInKB.toStringAsFixed(0)} KB)',
                Icons.storage,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                'الحالة',
                statusText,
                statusIcon,
                color: statusColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // شريط التقدم للحجم
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نسبة الحجم',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: _getSizePercentage(sizeInMB),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${_getSizePercentage(sizeInMB) * 100}% من الحد الموصى به',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // زر الضغط (إذا كان الملف كبير)
        if (sizeInMB > 1.0)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onCompress,
              icon: const Icon(Icons.compress, size: 18),
              label: const Text('ضغط الصورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }

  double _getSizePercentage(double sizeInMB) {
    // حساب النسبة المئوية من الحد الموصى به (5 MB)
    const maxRecommendedSize = 5.0;
    return (sizeInMB / maxRecommendedSize).clamp(0.0, 1.0);
  }
}
