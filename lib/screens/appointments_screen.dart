import 'package:flutter/material.dart';
import '../models/access_grant_model.dart';
import '../services/grants_service.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  final _service = GrantsService();
  List<AccessGrant> _grants = [];
  List<Doctor> _doctors = [];
  bool _loading = true;
  String? _error;
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_service.getMyGrants(), _service.getDoctors()]);
      setState(() { _grants = results[0] as List<AccessGrant>; _doctors = results[1] as List<Doctor>; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _requestAppointment() async {
    if (_doctors.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد أطباء متاحون'))); return; }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _RequestAppointmentSheet(doctors: _doctors),
    );
    if (result == null) return;
    try {
      final grant = await _service.createGrant(doctorId: result['doctorId'], expiresInHours: result['expiresInHours']);
      setState(() => _grants.insert(0, grant));
      if (mounted) _showGrantDialog(grant);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.danger));
    }
  }

  void _showGrantDialog(AccessGrant grant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [Icon(Icons.check_circle, color: AppTheme.success, size: 28), SizedBox(width: 10), Text('تم إنشاء الطلب')]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('شارك رمز OTP مع الطبيب:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3))),
            child: Column(children: [
              const Text('رمز OTP', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(grant.otp ?? '—', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: 4)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text('صالح حتى: ${DateFormat('dd/MM/yyyy HH:mm').format(grant.expiresAt)}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(14)),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'مواعيدي'), Tab(text: 'طلب موعد جديد')],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _error != null
                ? _buildError()
                : TabBarView(controller: _tabCtrl, children: [_buildGrantsList(), _buildNewRequest()]),
      ),
    ]);
  }

  Widget _buildGrantsList() {
    if (_grants.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.calendar_today_outlined, size: 70, color: AppTheme.divider),
      SizedBox(height: 16),
      Text('لا توجد مواعيد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
    ]));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView.separated(padding: const EdgeInsets.all(20), itemCount: _grants.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => _buildGrantCard(_grants[i])),
    );
  }

  Widget _buildGrantCard(AccessGrant grant) {
    final statusColor = grant.status == 'active' ? AppTheme.success : grant.status == 'pending' ? AppTheme.warning : grant.status == 'revoked' ? AppTheme.danger : AppTheme.textSecondary;
    final statusLabel = grant.status == 'active' ? 'نشط' : grant.status == 'pending' ? 'قيد الانتظار' : grant.status == 'revoked' ? 'ملغي' : 'مكتمل';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppTheme.cardShadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.person_outline, color: AppTheme.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(grant.doctorName ?? 'طبيب', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(DateFormat('dd/MM/yyyy').format(grant.createdAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (grant.otp != null && grant.isPending) ...[
          const SizedBox(height: 12),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.pin_outlined, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            const Text('رمز OTP:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(width: 8),
            Text(grant.otp!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.accent, letterSpacing: 3)),
          ]),
        ],
        if (grant.isPending && !grant.isExpired) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _revokeGrant(grant),
            icon: const Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 16),
            label: const Text('إلغاء الطلب', style: TextStyle(color: AppTheme.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger, width: 1.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
          )),
        ],
      ]),
    );
  }

  Future<void> _revokeGrant(AccessGrant grant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء طلب الموعد', textAlign: TextAlign.right),
        content: const Text('هل تريد إلغاء هذا الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، إلغاء')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.revokeGrant(grant.id);
      setState(() {
        final idx = _grants.indexWhere((g) => g.id == grant.id);
        if (idx != -1) _grants[idx] = AccessGrant(id: grant.id, patientId: grant.patientId, doctorId: grant.doctorId, nurseId: grant.nurseId, expiresAt: grant.expiresAt, status: 'revoked', createdAt: grant.createdAt);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppTheme.danger));
    }
  }

  Widget _buildNewRequest() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.info_outline, color: AppTheme.primary, size: 20), SizedBox(width: 8), Text('كيف يعمل طلب الموعد؟', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary))]),
          const SizedBox(height: 12),
          _step('1', 'اختر الطبيب وأرسل الطلب'),
          _step('2', 'ستحصل على رمز OTP'),
          _step('3', 'شارك الرمز مع الطبيب لتأكيد الموعد'),
        ]),
      ),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: _requestAppointment,
          icon: const Icon(Icons.add_circle_outline, size: 22),
          label: const Text('طلب موعد جديد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    ]),
  );

  Widget _step(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Container(width: 24, height: 24, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 13.5)),
    ]),
  );

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 60, color: AppTheme.textSecondary),
    const SizedBox(height: 16),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
    const SizedBox(height: 20),
    ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
  ]));
}

// ─── Bottom Sheet ──────────────────────────────────────────────────────────────
class _RequestAppointmentSheet extends StatefulWidget {
  final List<Doctor> doctors;
  const _RequestAppointmentSheet({required this.doctors});
  @override
  State<_RequestAppointmentSheet> createState() => _RequestAppointmentSheetState();
}

class _RequestAppointmentSheetState extends State<_RequestAppointmentSheet> {
  Doctor? _selected;
  int _hours = 72;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
      builder: (ctx, scroll) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Align(alignment: Alignment.centerRight, child: Text('اختر طبيباً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 8),
        Expanded(child: ListView.separated(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          itemCount: widget.doctors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final doc = widget.doctors[i];
            final selected = _selected?.id == doc.id;
            return GestureDetector(
              onTap: () => setState(() => _selected = doc),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 2 : 1.5),
                ),
                child: Row(children: [
                  CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: Text(doc.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(doc.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ])),
                  if (selected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
                ]),
              ),
            );
          },
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('مدة صلاحية الطلب:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              for (final h in [24, 48, 72]) Expanded(child: GestureDetector(
                onTap: () => setState(() => _hours = h),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: _hours == h ? AppTheme.primary : AppTheme.divider, borderRadius: BorderRadius.circular(10)),
                  child: Text('$h ساعة', textAlign: TextAlign.center, style: TextStyle(color: _hours == h ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              )),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _selected == null ? null : () => Navigator.pop(context, {'doctorId': _selected!.id, 'expiresInHours': _hours}),
              child: const Text('تأكيد الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}
