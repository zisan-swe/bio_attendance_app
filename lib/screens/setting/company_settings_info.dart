import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/company_setting_model.dart';
import '../../providers/company_settings_provider.dart';

class CompanySettingsInfoPage extends StatefulWidget {
  const CompanySettingsInfoPage({super.key});

  @override
  State<CompanySettingsInfoPage> createState() => _CompanySettingsInfoPageState();
}

class _CompanySettingsInfoPageState extends State<CompanySettingsInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _branchIdCtrl = TextEditingController();
  final _userCtrl = TextEditingController();

  final _companyNode = FocusNode();
  final _addressNode = FocusNode();
  final _branchNode = FocusNode();
  final _userNode = FocusNode();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<CompanySettingsProvider>();
      await p.load();
      final s = p.setting;
      if (s != null) {
        _companyNameCtrl.text = s.companyName;
        _addressCtrl.text = s.address ?? '';
        _branchIdCtrl.text = s.branchId?.toString() ?? '';
        _userCtrl.text = s.user ?? '';
      }
    });
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _branchIdCtrl.dispose();
    _userCtrl.dispose();
    _companyNode.dispose();
    _addressNode.dispose();
    _branchNode.dispose();
    _userNode.dispose();
    super.dispose();
  }

  void _resetForm() {
    _companyNameCtrl.clear();
    _addressCtrl.clear();
    _branchIdCtrl.clear();
    _userCtrl.clear();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CompanySettingsProvider>();
    final wasExisting = provider.setting != null; // <-- determine update vs create BEFORE save

    final branchId = _branchIdCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_branchIdCtrl.text.trim());

    final model = CompanySettingModel(
      companyName: _companyNameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      branchId: branchId,
      user: _userCtrl.text.trim().isEmpty ? null : _userCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await provider.save(model);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasExisting ? '✅ Updated successfully' : '✅ Saved successfully'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed: $e'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CompanySettingsProvider>().isLoading;
    final theme = Theme.of(context);
    final setting = context.watch<CompanySettingsProvider>().setting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings Info'),
        backgroundColor: Colors.blueGrey,        // actions: [
        //   IconButton(
        //     tooltip: 'Reset form',
        //     onPressed: isLoading || _saving ? null : _resetForm,
        //     icon: const Icon(Icons.refresh),
        //   ),
        // ],
      ),

      // Subtle gradient background
      body: AbsorbPointer(
        absorbing: isLoading || _saving,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: ListView(
                  children: [
                    // Header / Summary card
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              child: Icon(Icons.business, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    setting?.companyName?.isNotEmpty == true
                                        ? setting!.companyName
                                        : 'No company configured',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _ChipLine(icon: Icons.place, label: setting?.address ?? '—'),
                                      _ChipLine(
                                        icon: Icons.account_tree_rounded,
                                        label: setting?.branchId?.toString() ?? '—',
                                      ),
                                      _ChipLine(icon: Icons.person_outline, label: setting?.user ?? '—'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Form Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _companyNameCtrl,
                                focusNode: _companyNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _addressNode.requestFocus(),
                                autofillHints: const [AutofillHints.organizationName],
                                decoration: const InputDecoration(
                                  labelText: 'Company Name *',
                                  prefixIcon: Icon(Icons.apartment),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Company name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressCtrl,
                                focusNode: _addressNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _branchNode.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _branchIdCtrl,
                                focusNode: _branchNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _userNode.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Plot ID',
                                  hintText: 'e.g., 1',
                                  prefixIcon: Icon(Icons.account_tree),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v != null && v.trim().isNotEmpty) {
                                    final parsed = int.tryParse(v.trim());
                                    if (parsed == null) return 'Branch ID must be a number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _userCtrl,
                                focusNode: _userNode,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _save(),
                                decoration: const InputDecoration(
                                  labelText: 'Supervisor',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _saving
                                      ? const _SavingBtn()
                                      : FilledButton.icon(
                                    key: const ValueKey('saveBtn'),
                                    onPressed: _save,
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(
                                      (setting != null) ? 'Update' : 'Save',
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _ChipLine extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SavingBtn extends StatelessWidget {
  const _SavingBtn();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('savingBtn'),
      onPressed: null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Saving…'),
        ],
      ),
    );
  }
}
