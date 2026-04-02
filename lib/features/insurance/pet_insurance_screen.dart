import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';

class PetInsuranceScreen extends StatefulWidget {
  const PetInsuranceScreen({super.key});

  @override
  State<PetInsuranceScreen> createState() => _PetInsuranceScreenState();
}

class _PetInsuranceScreenState extends State<PetInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _petNameCtrl = TextEditingController();
  final _petBreedCtrl = TextEditingController();
  final _petAgeCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _petType = 'Dog';
  String _coverage = 'Basic';
  bool _saving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _petNameCtrl.dispose();
    _petBreedCtrl.dispose();
    _petAgeCtrl.dispose();
    _conditionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('insuranceQuotes').add({
        'userId': uid,
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'petName': _petNameCtrl.text.trim(),
        'petType': _petType,
        'petBreed': _petBreedCtrl.text.trim(),
        'petAge': _petAgeCtrl.text.trim(),
        'preExistingConditions': _conditionsCtrl.text.trim(),
        'coverageType': _coverage,
        'notes': _notesCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Submission failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: ResponsiveContainer(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pet Insurance',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Request a quote from insurers',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _submitted
                  ? _SuccessView(isDark: isDark)
                  : _FormView(
                      formKey: _formKey,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      emailCtrl: _emailCtrl,
                      petNameCtrl: _petNameCtrl,
                      petBreedCtrl: _petBreedCtrl,
                      petAgeCtrl: _petAgeCtrl,
                      conditionsCtrl: _conditionsCtrl,
                      notesCtrl: _notesCtrl,
                      petType: _petType,
                      coverage: _coverage,
                      saving: _saving,
                      isDark: isDark,
                      onPetTypeChanged: (v) => setState(() => _petType = v!),
                      onCoverageChanged: (v) => setState(() => _coverage = v!),
                      onSubmit: _submit,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF22C55E),
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quote Request Submitted!',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Insurance companies will review your request and get back to you with personalised quotes.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form view ─────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.petNameCtrl,
    required this.petBreedCtrl,
    required this.petAgeCtrl,
    required this.conditionsCtrl,
    required this.notesCtrl,
    required this.petType,
    required this.coverage,
    required this.saving,
    required this.isDark,
    required this.onPetTypeChanged,
    required this.onCoverageChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, phoneCtrl, emailCtrl;
  final TextEditingController petNameCtrl, petBreedCtrl, petAgeCtrl;
  final TextEditingController conditionsCtrl, notesCtrl;
  final String petType, coverage;
  final bool saving, isDark;
  final ValueChanged<String?> onPetTypeChanged;
  final ValueChanged<String?> onCoverageChanged;
  final VoidCallback onSubmit;

  static const _petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Reptile', 'Other'];
  static const _coverageTypes = ['Basic', 'Comprehensive', 'Premium'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Your Details', isDark: isDark),
            const SizedBox(height: 10),
            _Field(ctrl: nameCtrl, label: 'Full Name', hint: 'John Doe',
                icon: Icons.person_outline_rounded, isDark: isDark,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            _Field(ctrl: phoneCtrl, label: 'Phone Number',
                hint: '+27 82 000 0000', icon: Icons.phone_outlined,
                isDark: isDark, keyboard: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            _Field(ctrl: emailCtrl, label: 'Email Address',
                hint: 'you@example.com', icon: Icons.email_outlined,
                isDark: isDark, keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
            const SizedBox(height: 20),
            _SectionLabel('Pet Details', isDark: isDark),
            const SizedBox(height: 10),
            _Field(ctrl: petNameCtrl, label: 'Pet Name', hint: 'Buddy',
                icon: Icons.pets_rounded, isDark: isDark,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            _DropdownField(
              label: 'Pet Type',
              value: petType,
              items: _petTypes,
              isDark: isDark,
              onChanged: onPetTypeChanged,
            ),
            const SizedBox(height: 10),
            _Field(ctrl: petBreedCtrl, label: 'Breed',
                hint: 'e.g. Golden Retriever', icon: Icons.category_outlined,
                isDark: isDark),
            const SizedBox(height: 10),
            _Field(ctrl: petAgeCtrl, label: 'Pet Age',
                hint: 'e.g. 3 years', icon: Icons.cake_outlined,
                isDark: isDark,
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            _Field(ctrl: conditionsCtrl,
                label: 'Pre-existing Conditions',
                hint: 'e.g. Hip dysplasia, allergies (or "None")',
                icon: Icons.medical_information_outlined,
                isDark: isDark, maxLines: 2),
            const SizedBox(height: 20),
            _SectionLabel('Coverage', isDark: isDark),
            const SizedBox(height: 10),
            _DropdownField(
              label: 'Coverage Type',
              value: coverage,
              items: _coverageTypes,
              isDark: isDark,
              onChanged: onCoverageChanged,
            ),
            const SizedBox(height: 4),
            _CoverageHint(coverage: coverage, isDark: isDark),
            const SizedBox(height: 10),
            _Field(ctrl: notesCtrl, label: 'Additional Notes',
                hint: 'Anything else you\'d like insurers to know...',
                icon: Icons.notes_rounded, isDark: isDark, maxLines: 3),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: saving ? null : onSubmit,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: saving
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : Text(
                          'Submit Quote Request',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboard,
    this.validator,
    this.maxLines = 1,
  });
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.inter(fontSize: 13),
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });
  final String label, value;
  final List<String> items;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13),
          border: InputBorder.none,
        ),
        style: GoogleFonts.inter(fontSize: 14),
        dropdownColor:
            isDark ? AppColors.cardDark : Colors.white,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _CoverageHint extends StatelessWidget {
  const _CoverageHint({required this.coverage, required this.isDark});
  final String coverage;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hints = {
      'Basic': 'Covers accidents & emergency vet visits',
      'Comprehensive': 'Covers accidents, illnesses & routine care',
      'Premium': 'Full coverage including dental, specialist & wellness',
    };
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        hints[coverage] ?? '',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
