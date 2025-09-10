import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../blocs/promo_code/index.dart';
import '../../blocs/auth/index.dart';
import '../../models/promo_code_model.dart';
import '../../theme/appcolors.dart';
import '../../components/CustomTextField.dart';

class AddEditPromoCodeScreen extends StatefulWidget {
  final PromoCodeModel? promoCode;

  const AddEditPromoCodeScreen({super.key, this.promoCode});

  @override
  State<AddEditPromoCodeScreen> createState() => _AddEditPromoCodeScreenState();
}

class _AddEditPromoCodeScreenState extends State<AddEditPromoCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _fixedAmountController = TextEditingController();
  final _maxDiscountAmountController = TextEditingController();
  final _minOrderAmountController = TextEditingController();
  final _maxUsageCountController = TextEditingController();

  DateTime _selectedExpiryDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _hasMaxDiscount = false;
  bool _hasMinOrderAmount = false;
  String? _expiryDateError;
  bool _isLoading = false;
  int _discountType = 0; // 0: نسبة, 1: مبلغ ثابت
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.promoCode != null) {
      _loadPromoCodeData();
    } else {
      _maxUsageCountController.text = '100';
    }
  }

  void _loadPromoCodeData() {
    final promoCode = widget.promoCode!;
    _codeController.text = promoCode.code;
    _descriptionController.text = promoCode.description;
    _discountPercentageController.text = promoCode.discountPercentage
        .toString();
    _fixedAmountController.text = promoCode.fixedAmount?.toString() ?? '';
    _maxUsageCountController.text = promoCode.maxUsageCount.toString();
    _selectedExpiryDate = promoCode.expiryDate;
    _isActive = promoCode.isActive;
    // تحديد نوع الخصم بناءً على البيانات
    if (promoCode.fixedAmount != null && promoCode.fixedAmount! > 0) {
      _discountType = 1;
    } else {
      _discountType = 0;
    }
    if (promoCode.maxDiscountAmount != null) {
      _hasMaxDiscount = true;
      _maxDiscountAmountController.text = promoCode.maxDiscountAmount!
          .toString();
    }
    if (promoCode.minOrderAmount != null) {
      _hasMinOrderAmount = true;
      _minOrderAmountController.text = promoCode.minOrderAmount!.toString();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _fixedAmountController.dispose();
    _maxDiscountAmountController.dispose();
    _minOrderAmountController.dispose();
    _maxUsageCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // التحقق من أن المستخدم مدير
        if (authState is! Authenticated ||
            authState.userProfile == null ||
            authState.userProfile!.role != 'admin') {
          return _buildUnauthorizedScreen();
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                widget.promoCode == null
                    ? 'إضافة كود خصم جديد'
                    : 'تعديل كود الخصم',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: BlocListener<PromoCodeBloc, PromoCodeState>(
              listener: (context, state) {
                if (state is PromoCodeError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is PromoCodeCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إنشاء كود الخصم بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                } else if (state is PromoCodeUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث كود الخصم بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildForm(),
                      const Divider(height: 32, thickness: 1.2),
                      // خيارات متقدمة
                      const Text(
                        'خيارات متقدمة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // الحد الأقصى للخصم
                      Row(
                        children: [
                          Checkbox(
                            value: _hasMaxDiscount,
                            onChanged: (value) {
                              setState(() {
                                _hasMaxDiscount = value ?? false;
                                if (!_hasMaxDiscount) {
                                  _maxDiscountAmountController.clear();
                                }
                              });
                            },
                            activeColor: AppColors.orangeColor,
                          ),
                          const Text('الحد الأقصى للخصم'),
                        ],
                      ),
                      if (_hasMaxDiscount) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _maxDiscountAmountController,
                          title: 'الحد الأقصى للخصم (جنيه)',
                          hinttext: 'مثال: 50',
                          button: null,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_hasMaxDiscount &&
                                (value == null || value.trim().isEmpty)) {
                              return 'يرجى إدخال الحد الأقصى للخصم';
                            }
                            if (value != null && value.trim().isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'الحد الأقصى للخصم يجب أن يكون رقم موجب';
                              }
                            }
                            return null;
                          },
                        ),
                      ],

                      // الحد الأدنى للطلب
                      Row(
                        children: [
                          Checkbox(
                            value: _hasMinOrderAmount,
                            onChanged: (value) {
                              setState(() {
                                _hasMinOrderAmount = value ?? false;
                                if (!_hasMinOrderAmount) {
                                  _minOrderAmountController.clear();
                                }
                              });
                            },
                            activeColor: AppColors.orangeColor,
                          ),
                          const Text('الحد الأدنى للطلب'),
                        ],
                      ),
                      if (_hasMinOrderAmount) ...[
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _minOrderAmountController,
                          title: 'الحد الأدنى للطلب (جنيه)',
                          hinttext: 'مثال: 100',
                          button: null,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_hasMinOrderAmount &&
                                (value == null || value.trim().isEmpty)) {
                              return 'يرجى إدخال الحد الأدنى للطلب';
                            }
                            if (value != null && value.trim().isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'الحد الأدنى للطلب يجب أن يكون رقم موجب';
                              }
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // عدد مرات الاستخدام الأقصى
                      CustomTextField(
                        controller: _maxUsageCountController,
                        title: 'عدد مرات الاستخدام الأقصى',
                        hinttext: 'مثال: 100',
                        button: null,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال عدد مرات الاستخدام الأقصى';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'عدد مرات الاستخدام يجب أن يكون رقم موجب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // تاريخ انتهاء الصلاحية
                      Text(
                        'تاريخ انتهاء الصلاحية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mediumGrayColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectExpiryDate(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.blackColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.blackColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedExpiryDate != null
                                    ? '${_selectedExpiryDate.day}/${_selectedExpiryDate.month}/${_selectedExpiryDate.year}'
                                    : 'اختر تاريخ انتهاء الصلاحية',
                                style: TextStyle(
                                  color: _selectedExpiryDate != null
                                      ? AppColors.blackColor
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_expiryDateError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _expiryDateError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // تفعيل الكود
                      Row(
                        children: [
                          Checkbox(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value ?? true;
                              });
                            },
                            activeColor: AppColors.orangeColor,
                          ),
                          const Text('تفعيل الكود'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // زر الحفظ
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _savePromoCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orangeColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.promoCode == null
                                      ? 'إنشاء كود الخصم'
                                      : 'تحديث كود الخصم',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.confirmation_number,
                      color: AppColors.orangeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        controller: _codeController,
                        title: 'كود الخصم',
                        hinttext: 'مثال: FOUDA10',
                        button: null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال كود الخصم';
                          }
                          if (value.trim().length < 3) {
                            return 'كود الخصم يجب أن يكون 3 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: AppColors.orangeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        controller: _descriptionController,
                        title: 'وصف كود الخصم',
                        hinttext: 'مثال: خصم 10% على جميع المنتجات',
                        button: null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال وصف كود الخصم';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'نوع الخصم:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.orangeColor,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        value: 0,
                        groupValue: _discountType,
                        onChanged: (val) =>
                            setState(() => _discountType = val!),
                        title: Row(
                          children: [
                            Icon(
                              Icons.percent,
                              color: AppColors.orangeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'نسبة مئوية',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'مثال: 10% من قيمة الطلب',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        value: 1,
                        groupValue: _discountType,
                        onChanged: (val) =>
                            setState(() => _discountType = val!),
                        title: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: AppColors.orangeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'مبلغ ثابت',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'مثال: 50 جنيه خصم مباشر',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_discountType == 0) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.percent,
                        color: AppColors.orangeColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomTextField(
                          controller: _discountPercentageController,
                          title: 'نسبة الخصم (%)',
                          hinttext: 'مثال: 10',
                          button: null,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال نسبة الخصم';
                            }
                            final percentage = double.tryParse(value);
                            if (percentage == null ||
                                percentage <= 0 ||
                                percentage > 100) {
                              return 'نسبة الخصم يجب أن تكون بين 1 و 100';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 32),
                    child: Text(
                      'أدخل نسبة مئوية فقط إذا كان الخصم نسبي',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
                if (_discountType == 1) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: AppColors.orangeColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: CustomTextField(
                          controller: _fixedAmountController,
                          title: 'مبلغ خصم ثابت (جنيه)',
                          hinttext: 'مثال: 50',
                          button: null,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال مبلغ الخصم الثابت';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'مبلغ الخصم الثابت يجب أن يكون رقم موجب';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 32),
                    child: Text(
                      'أدخل مبلغًا فقط إذا كان الخصم ثابتًا',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
  }

  void _savePromoCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _expiryDateError = null;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      double? discountValue;
      if (_discountType == 0) {
        discountValue = double.tryParse(
          _discountPercentageController.text.trim(),
        );
        if (discountValue == null || discountValue == 0) {
          setState(() {
            _error = 'يرجى إدخال نسبة الخصم';
          });
          return;
        }
      } else {
        discountValue = double.tryParse(_fixedAmountController.text.trim());
        if (discountValue == null || discountValue == 0) {
          setState(() {
            _error = 'يرجى إدخال مبلغ الخصم الثابت';
          });
          return;
        }
      }

      final promoCode = PromoCodeModel(
        id:
            widget.promoCode?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        code: _codeController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
        discountPercentage: _discountType == 0 ? discountValue : 0.0,
        fixedAmount: _discountType == 1 ? discountValue : null,
        maxDiscountAmount:
            _hasMaxDiscount && _maxDiscountAmountController.text.isNotEmpty
            ? double.parse(_maxDiscountAmountController.text)
            : null,
        minOrderAmount:
            _hasMinOrderAmount && _minOrderAmountController.text.isNotEmpty
            ? double.parse(_minOrderAmountController.text)
            : null,
        maxUsageCount: int.parse(_maxUsageCountController.text),
        currentUsageCount: widget.promoCode?.currentUsageCount ?? 0,
        expiryDate: _selectedExpiryDate,
        isActive: _isActive,
        createdAt: widget.promoCode?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
      );

      if (widget.promoCode == null) {
        context.read<PromoCodeBloc>().add(CreatePromoCode(promoCode));
      } else {
        context.read<PromoCodeBloc>().add(
          UpdatePromoCode(promoCode.id, promoCode.toJson()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.promoCode == null ? 'إضافة كود خصم جديد' : 'تعديل كود الخصم',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: AppColors.orangeColor.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            const Text(
              'غير مصرح لك بالوصول',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'يجب تسجيل الدخول بحساب مدير للوصول إلى إدارة أكواد الخصم',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orangeColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'العودة',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
