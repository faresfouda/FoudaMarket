import 'package:flutter/material.dart';
import '../../theme/appcolors.dart';
import '../../components/Button.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديث كلمة المرور'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'أدخل كلمة المرور الحالية' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: newController,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أدخل كلمة المرور الجديدة';
                  if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف أو أكثر';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أدخل تأكيد كلمة المرور';
                  if (v != newController.text) return 'كلمتا المرور غير متطابقتين';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Button(
                buttonContent: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ', style: TextStyle(color: Colors.white)),
                buttonColor: AppColors.orangeColor,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 