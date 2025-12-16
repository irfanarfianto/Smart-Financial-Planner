import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';

class TransactionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  const TransactionSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppTextField(
        controller: controller,
        hintText: 'Cari transaksi...',
        label: '',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
            : null,
        onChanged: onChanged,
      ),
    );
  }
}
