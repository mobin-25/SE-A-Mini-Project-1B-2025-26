import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class VisitorPassScreen extends StatefulWidget {
  final UserModel user;
  const VisitorPassScreen({super.key, required this.user});

  @override
  State<VisitorPassScreen> createState() => _VisitorPassScreenState();
}

class _VisitorPassScreenState extends State<VisitorPassScreen> {
  final _nameCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  DateTime _visitDate = DateTime.now();
  String _visitTime = '10:00 AM';
  bool _generated = false;
  String _qrData = '';

  void _generatePass() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final payload = jsonEncode({
      'visitor': _nameCtrl.text.trim(),
      'purpose': _purposeCtrl.text.trim(),
      'flat': widget.user.flatNo,
      'resident': widget.user.name,
      'date': DateFormat('dd MMM yyyy').format(_visitDate),
      'time': _visitTime,
      'generatedAt': DateTime.now().toIso8601String(),
    });
    setState(() {
      _qrData = payload;
      _generated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Visitor Pass'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _generated ? buildPassCard() : buildForm(),
      ),
    );
  }

  Widget buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.qr_code_2_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text('Generate Visitor Pass',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('Generate a QR code for your guest',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Visitor Name',
            prefixIcon: Icon(Icons.person_outline_rounded,
                color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _purposeCtrl,
          decoration: const InputDecoration(
            labelText: 'Purpose of Visit',
            prefixIcon:
                Icon(Icons.info_outline_rounded, color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _visitDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (d != null) setState(() => _visitDate = d);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.secondary, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd MMMM yyyy').format(_visitDate),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (v) => _visitTime = v,
          decoration: const InputDecoration(
            labelText: 'Visit Time (e.g. 3:00 PM)',
            prefixIcon: Icon(Icons.access_time_rounded,
                color: AppColors.secondary),
          ),
          controller: TextEditingController(text: _visitTime),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
          ),
          onPressed: _generatePass,
          icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
          label: const Text('Generate Pass'),
        ),
      ],
    );
  }

  Widget buildPassCard() {
    final data = jsonDecode(_qrData) as Map<String, dynamic>;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('VISITOR PASS',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 12)),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 180,
              ),
              const SizedBox(height: 16),
              Text(data['visitor'],
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Visiting Flat ${widget.user.flatNo}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
              const Divider(height: 24),
              _InfoRow(
                  icon: Icons.calendar_today_rounded, text: data['date']),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.access_time_rounded, text: data['time']),
              if ((data['purpose'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.info_outline_rounded,
                    text: data['purpose']),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _generated = false),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('New Pass'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
