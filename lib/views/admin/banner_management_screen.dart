import 'package:flutter/material.dart';
import 'package:fouda_market/theme/appcolors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fouda_market/models/banner_image_model.dart';
import 'package:fouda_market/core/services/banner_service.dart';
import 'package:fouda_market/core/services/auth_service.dart';
import 'package:fouda_market/components/cached_image.dart';
import 'dart:io';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final BannerService _bannerService = BannerService();
  final AuthService _authService = AuthService();

  List<BannerImage> _banners = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final banners = await _bannerService.getAllBanners();
      setState(() {
        _banners = banners;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في تحميل صور العروض: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewBanner() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    // عرض نافذة إدخال العنوان
    final title = await _showTitleDialog();
    if (title == null || title.trim().isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // جلب معلومات الأدمن
      final adminInfo = await _authService.getCurrentAdminInfo();
      if (adminInfo == null) {
        throw Exception('غير مصرح لك بإضافة صور العروض');
      }

      final success = await _bannerService.addBanner(
        imageFile: File(image.path),
        title: title.trim(),
        adminId: adminInfo['id']!,
        adminName: adminInfo['name'],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة صورة العرض بنجاح')),
        );
        _loadBanners(); // إعادة تحميل القائمة
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في إضافة صورة العرض')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _showTitleDialog() async {
    final TextEditingController titleController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إدخال عنوان الصورة'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الصورة',
              hintText: 'مثال: عرض خاص على الأجهزة',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(titleController.text),
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleBannerStatus(BannerImage banner) async {
    try {
      final adminInfo = await _authService.getCurrentAdminInfo();
      if (adminInfo == null) {
        throw Exception('غير مصرح لك بتحديث حالة الصورة');
      }

      final success = await _bannerService.updateBannerStatus(
        bannerId: banner.id,
        isActive: !banner.isActive,
        adminId: adminInfo['id']!,
        adminName: adminInfo['name'],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              banner.isActive ? 'تم إلغاء تفعيل الصورة' : 'تم تفعيل الصورة',
            ),
          ),
        );
        _loadBanners(); // إعادة تحميل القائمة
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحديث حالة الصورة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _editBannerTitle(BannerImage banner) async {
    final TextEditingController titleController = TextEditingController(
      text: banner.title,
    );

    final newTitle = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تعديل عنوان الصورة'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'عنوان الصورة'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(titleController.text),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (newTitle == null || newTitle.trim().isEmpty) return;

    try {
      final adminInfo = await _authService.getCurrentAdminInfo();
      if (adminInfo == null) {
        throw Exception('غير مصرح لك بتعديل الصورة');
      }

      final success = await _bannerService.updateBannerTitle(
        bannerId: banner.id,
        title: newTitle.trim(),
        adminId: adminInfo['id']!,
        adminName: adminInfo['name'],
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث عنوان الصورة بنجاح')),
        );
        _loadBanners(); // إعادة تحميل القائمة
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحديث عنوان الصورة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  Future<void> _deleteBanner(BannerImage banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف صورة "${banner.title}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final adminInfo = await _authService.getCurrentAdminInfo();
      if (adminInfo == null) {
        throw Exception('غير مصرح لك بحذف الصورة');
      }

      final success = await _bannerService.deleteBanner(
        bannerId: banner.id,
        adminId: adminInfo['id']!,
        adminName: adminInfo['name'],
      );

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الصورة بنجاح')));
        _loadBanners(); // إعادة تحميل القائمة
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل في حذف الصورة')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة صور العروض'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.orangeColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBanners,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // إحصائيات سريعة
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue[600], size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'إحصائيات العروض',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'إجمالي العروض',
                              _banners.length.toString(),
                              Icons.image,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'العروض المفعلة',
                              _banners.where((b) => b.isActive).length.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'العروض المعطلة',
                              _banners.where((b) => !b.isActive).length.toString(),
                              Icons.cancel,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // قائمة الصور
                Expanded(
                  child: _banners.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد صور عروض',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _banners.length,
                          itemBuilder: (context, index) {
                            final banner = _banners[index];
                            return _buildBannerCard(banner);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _addNewBanner,
        child: _isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBannerCard(BannerImage banner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // الصورة مع overlay للحالة
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, size: 48),
                    ),
                  ),
                ),
              ),
              // حالة الصورة كـ overlay
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: banner.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        banner.isActive ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        banner.isActive ? 'مفعلة' : 'معطلة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // معلومات الصورة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Text(
                  banner.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // معلومات التواريخ
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'تم الإنشاء: ${_formatDate(banner.createdAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (banner.updatedAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.update, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'آخر تحديث: ${_formatDate(banner.updatedAt!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // أزرار التحكم
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleBannerStatus(banner),
                        icon: Icon(
                          banner.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        label: Text(
                          banner.isActive ? 'إخفاء' : 'إظهار',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: banner.isActive ? Colors.orange[600] : Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _editBannerTitle(banner),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteBanner(banner),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('حذف', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
