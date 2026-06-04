class MedicalRecord {
  final String id;
  final String patientId;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String? description;
  final DateTime createdAt;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.description,
    required this.createdAt,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'],
      patientId: json['patientId'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1048576) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / 1048576).toStringAsFixed(1)}MB';
  }

  bool get isImage => fileType?.startsWith('image/') ?? false;
  bool get isPdf => fileType == 'application/pdf';
}
