class FileInfo {
  String fileName;
  String fileUrl;
  DateTime uploadedAt;
  double fileSize;

  FileInfo(
      {required this.fileName,
      required this.fileUrl,
      required this.uploadedAt,
      required this.fileSize});

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
        fileName: json['fileName'],
        fileUrl: json['fileUrl'],
        uploadedAt: DateTime.parse(json['uploadDate']),
        fileSize: json['fileSize']);
  }

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'fileUrl': fileUrl,
        'uploadDate': uploadedAt.toIso8601String(),
        'fileSize': fileSize
      };
}
