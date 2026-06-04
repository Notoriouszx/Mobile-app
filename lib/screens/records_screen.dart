// لا dart:io هنا — نستخدم PlatformFile لدعم الويب والموبايل معاً
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/medical_record_model.dart';
import '../services/records_service.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final _service = RecordsService();
  List<MedicalRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await _service.getMyRecords();
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      // withData: true مهم للويب لتحميل الـ bytes
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final platformFile = result.files.single;

    String? description;
    if (mounted) {
      description = await _showDescriptionDialog();
      if (description == null) return; // ضغط إلغاء
    }

    if (mounted) {
      _showUploadingSheet(platformFile, description ?? '');
    }
  }

  Future<String?> _showDescriptionDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('وصف الملف (اختياري)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'مثال: نتيجة تحليل الدم'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('رفع'),
          ),
        ],
      ),
    );
  }

  void _showUploadingSheet(PlatformFile platformFile, String description) {
    double progress = 0;
    bool done = false;
    bool started = false;
    String? uploadError;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (!started) {
            started = true;
            _service
                .uploadFile(
              platformFile,
              description: description.isNotEmpty ? description : null,
              onProgress: (sent, total) {
                setSheetState(() => progress = sent / total);
              },
            )
                .then((record) {
              setSheetState(() {
                done = true;
                progress = 1;
              });
              setState(() => _records.insert(0, record));
              Future.delayed(const Duration(milliseconds: 900), () {
                if (ctx.mounted) Navigator.pop(ctx);
              });
            }).catchError((e) {
              setSheetState(() {
                uploadError = e.toString().replaceAll('Exception: ', '');
                done = true;
              });
            });
          }

          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!done) ...[
                  const Icon(Icons.cloud_upload_outlined,
                      color: AppTheme.primary, size: 48),
                  const SizedBox(height: 16),
                  const Text('جاري رفع الملف...',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 8,
                      backgroundColor: AppTheme.divider,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toInt()}%',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ] else if (uploadError != null) ...[
                  const Icon(Icons.error_outline,
                      color: AppTheme.danger, size: 48),
                  const SizedBox(height: 12),
                  Text(uploadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.danger)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger),
                    child: const Text('إغلاق'),
                  ),
                ] else ...[
                  const Icon(Icons.check_circle_outline,
                      color: AppTheme.success, size: 48),
                  const SizedBox(height: 12),
                  const Text('تم رفع الملف بنجاح!',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.success)),
                ],
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadRecords,
      color: AppTheme.primary,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _records.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _records.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == 0) return _buildUploadCard();
        return _buildRecordCard(_records[i - 1]);
      },
    );
  }

  Widget _buildEmpty() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUploadCard(),
              const SizedBox(height: 40),
              const Icon(Icons.folder_open_outlined,
                  size: 70, color: AppTheme.divider),
              const SizedBox(height: 16),
              const Text('لا توجد سجلات طبية بعد',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              const Text('ابدأ برفع ملفاتك الطبية',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 60, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadRecords,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickAndUpload,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رفع ملف طبي',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('PDF أو صورة (JPG, PNG) — حتى 15MB',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecord record) {
    final icon = record.isPdf
        ? Icons.picture_as_pdf_outlined
        : record.isImage
            ? Icons.image_outlined
            : Icons.description_outlined;
    final iconColor = record.isPdf
        ? AppTheme.danger
        : record.isImage
            ? AppTheme.accent
            : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.fileName ?? 'ملف طبي',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.description != null) ...[
                  const SizedBox(height: 2),
                  Text(record.description!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(record.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11.5),
                    ),
                    if (record.fileSizeFormatted.isNotEmpty) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppTheme.textSecondary)),
                      Text(record.fileSizeFormatted,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11.5)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.danger, size: 20),
            onPressed: () => _confirmDelete(record),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MedicalRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الملف'),
        content: Text(
            'هل تريد حذف "${record.fileName ?? 'هذا الملف'}"؟ لا يمكن التراجع.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteRecord(record.id);
                setState(() => _records.remove(record));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الملف'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
