// //FileHandlerPage.dart

// // ignore_for_file: file_names, avoid_web_libraries_in_flutter, avoid_print

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:dio/dio.dart';
// import 'package:http_parser/http_parser.dart';
// import 'package:intl/intl.dart';
// import 'package:paper_summarizer_frontend/LoginPage.dart';
// import 'dart:html' as html;
// import 'dart:typed_data';

// import 'package:paper_summarizer_frontend/model/FileInfo.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class FileHandlerPage extends StatefulWidget {
//   const FileHandlerPage({super.key});

//   @override
//   State<FileHandlerPage> createState() => _FileHandlerPageState();
// }

// class _FileHandlerPageState extends State<FileHandlerPage> {
//   final Dio _dio = Dio();
//   PlatformFile? _selectedFile;
//   Uint8List? _selectedFileBytes;
//   bool _isUploading = false;
//   bool _isDownloading = false;
//   double _uploadProgress = 0;
//   double _downloadProgress = 0;
//   List<FileInfo> _uploadedFiles = [];
//   String? _errorMessage;
//   final String serverUrl = 'http://localhost:8080/api/paper_summarizer';

//   @override
//   void initState() {
//     super.initState();
//     _initializeTokenAndFetchFiles();
//   }

//   Future<void> _initializeTokenAndFetchFiles() async {
//     bool isTokenValid = await _checkTokenValidity();
//     if (isTokenValid) {
//       _fetchUploadedFiles();
//     } else {
//       _redirectToLoginPage();
//     }
//   }

//   Future<bool> _checkTokenValidity() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('jwtToken');

//     if (token == null) return false;

//     // Decode token and check expiration (Assuming JWT structure)
//     final decodedToken = _decodeJwt(token);
//     if (decodedToken == null || decodedToken['exp'] == null) return false;

//     int expiryTimestamp = decodedToken['exp'] * 1000;
//     return DateTime.now().millisecondsSinceEpoch < expiryTimestamp;
//   }

//   Map<String, dynamic>? _decodeJwt(String token) {
//     try {
//       final parts = token.split('.');
//       if (parts.length != 3) return null;
//       final payload =
//           utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
//       return jsonDecode(payload) as Map<String, dynamic>;
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<void> _redirectToLoginPage() async {
//     //show snackbar message that session has expired
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Session has expired. Please login again.'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const LoginPage()),
//     );
//   }

//   Future<void> _pickFile() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.any,
//         allowMultiple: false,
//         withData: true, // Important: This ensures we get the file bytes
//       );

//       if (result != null && result.files.isNotEmpty) {
//         setState(() {
//           _selectedFile = result.files.first;
//           _selectedFileBytes = result.files.first.bytes;
//           _errorMessage = null;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error picking file: $e';
//       });
//       _showSnackBar('Error picking file: $e');
//     }
//   }

//   Future<void> _uploadFile() async {
//     if (_selectedFile == null || _selectedFileBytes == null) {
//       _showSnackBar('Please select a file first');
//       return;
//     }

//     setState(() {
//       _isUploading = true;
//       _uploadProgress = 0;
//       _errorMessage = null;
//     });

//     try {
//       // Get file extension
//       String fileExtension = _selectedFile!.name.split('.').last.toLowerCase();

//       // Determine MIME type
//       String mimeType = 'application/octet-stream';
//       if (fileExtension == 'pdf') {
//         mimeType = 'application/pdf';
//       } else {
//         setState(() {
//           _errorMessage = 'Only PDF files are allowed';
//         });
//         _showSnackBar('Only PDF files are allowed');
//         return;
//       }

//       // Create form data
//       FormData formData = FormData.fromMap({
//         'file': MultipartFile.fromBytes(
//           _selectedFileBytes!,
//           filename: _selectedFile!.name,
//           contentType: MediaType.parse(mimeType),
//         ),
//       });

//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('jwtToken');
//       if (token == null) {
//         _redirectToLoginPage();
//         return;
//       }

//       _dio.options.headers['Authorization'] = token;
//       // Replace with your server URL
//       final String uploadUrl = '$serverUrl/upload';

//       // Configure Dio
//       _dio.options.headers['Accept'] = '*/*';
//       // _dio.options.headers['Content-Type'] = 'multipart/form-data';

//       // Make POST request
//       final response = await _dio.post(
//         uploadUrl,
//         data: formData,
//         onSendProgress: (sent, total) {
//           if (total != -1) {
//             double progress = (sent / total) * 100;
//             print('Upload Progress: $progress'); // Print progress to debug
//             setState(() {
//               _uploadProgress = progress;
//             });
//           }
//         },
//       );

//       print(response.data);

//       if (response.statusCode == 200) {
//         setState(() {
//           _selectedFile = null;
//           _selectedFileBytes = null;
//         });
//         _fetchUploadedFiles();
//         _showSnackBar('File uploaded successfully!');
//       } else {
//         throw 'Upload failed with status: ${response.statusCode}';
//       }
//     } catch (e) {
//       if (e is DioException && e.response?.statusCode == 401) {
//         _redirectToLoginPage();
//       } else {
//         setState(() {
//           _errorMessage = 'Error uploading file: $e';
//         });
//         _showSnackBar('Error uploading file: $e');
//       }
//       print(e.toString());
//     } finally {
//       setState(() {
//         _isUploading = false;
//       });
//     }
//   }

//   Future<void> _fetchUploadedFiles() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('jwtToken');
//       if (token == null) {
//         _redirectToLoginPage();
//         return;
//       }

//       _dio.options.headers['Authorization'] = token;
//       // Replace with your server URL for fetching files
//       final String fetchUrl = '$serverUrl/files';

//       final response = await _dio.get(fetchUrl);

//       print(response.data);

//       if (response.statusCode == 200) {
//         setState(() {
//           _uploadedFiles = (response.data as List)
//               .map((file) => FileInfo.fromJson(file))
//               .toList();
//         });
//       } else {
//         throw 'Failed to fetch files. Status code: ${response.statusCode}';
//       }
//     } catch (e) {
//       if (e is DioException && e.response?.statusCode == 401) {
//         _redirectToLoginPage();
//       } else {
//         setState(() {
//           _errorMessage = 'Error fetching files: $e';
//         });
//         _showSnackBar('Error fetching files: $e');
//       }
//     }
//   }

//   Future<void> _downloadFile(String fileName) async {
//     setState(() {
//       _isDownloading = true;
//       _downloadProgress = 0;
//       _errorMessage = null;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('jwtToken');
//       if (token == null) {
//         _redirectToLoginPage();
//         return;
//       }

//       _dio.options.headers['Authorization'] = token;
//       // Replace with your server URL
//       final String downloadUrl = '$serverUrl/download?filePath=$fileName';

//       _dio.options.headers['Accept'] = '*/*';
//       _dio.options.responseType = ResponseType.bytes;

//       // Make GET request with progress tracking
//       final response = await _dio.get(
//         downloadUrl,
//         onReceiveProgress: (received, total) {
//           if (total != -1) {
//             double progress = (received / total) * 100;
//             print('Download Progress: $progress'); // Print progress to debug
//             setState(() {
//               _downloadProgress = progress;
//             });
//           }
//         },
//       );

//       if (response.statusCode == 200 && response.data != null) {
//         // Create blob and trigger download
//         final blob = html.Blob([response.data]);
//         final url = html.Url.createObjectUrlFromBlob(blob);

//         // Create a temporary anchor element
//         final anchor = html.document.createElement('a') as html.AnchorElement
//           ..href = url
//           ..style.display = 'none'
//           ..download = fileName;

//         html.document.body!.children.add(anchor);

//         // Trigger download
//         anchor.click();

//         // Cleanup
//         html.document.body!.children.remove(anchor);
//         html.Url.revokeObjectUrl(url);

//         _showSnackBar('File downloaded successfully!');
//       } else {
//         throw 'Download failed with status: ${response.statusCode}';
//       }
//     } catch (e) {
//       if (e is DioException && e.response?.statusCode == 401) {
//         _redirectToLoginPage();
//       } else {
//         setState(() {
//           _errorMessage = 'Error downloading file: $e';
//         });
//         _showSnackBar('Error downloading file: $e');
//       }
//     } finally {
//       setState(() {
//         _isDownloading = false;
//         _downloadProgress = 0;
//       });
//     }
//   }

//   void _showSnackBar(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('File Upload/Download Demo'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Error Message
//             if (_errorMessage != null) ...[
//               Card(
//                 color: Colors.red.shade100,
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     _errorMessage!,
//                     style: TextStyle(color: Colors.red.shade900),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],
//             // File Selection Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Upload File',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         ElevatedButton(
//                           onPressed: _isUploading ? null : _pickFile,
//                           child: const Text('Select File'),
//                         ),
//                         const SizedBox(width: 16),
//                         if (_selectedFile != null) ...[
//                           Expanded(
//                             child: Text(
//                               _selectedFile!.name,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           ElevatedButton(
//                             onPressed: _isUploading ? null : _uploadFile,
//                             child: const Text('Upload'),
//                           ),
//                         ],
//                       ],
//                     ),
//                     if (_isUploading) ...[
//                       const SizedBox(height: 16),
//                       LinearProgressIndicator(value: _uploadProgress / 100),
//                       const SizedBox(height: 8),
//                       Text('${_uploadProgress.toStringAsFixed(1)}%'),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             // Downloaded Files Section
//             // Downloaded Files Section
//             Expanded(
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Uploaded Files',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Expanded(
//                         child: _uploadedFiles.isEmpty
//                             ? const Center(child: Text('No files uploaded yet'))
//                             : ListView.builder(
//                                 itemCount: _uploadedFiles.length,
//                                 itemBuilder: (context, index) {
//                                   FileInfo file = _uploadedFiles[index];
//                                   String fileUrl = file.fileUrl;
//                                   String fileName = fileUrl.split('/').last;
//                                   DateTime uploadedAt = file.uploadedAt;
//                                   double fileSize = file.fileSize;
//                                   fileSize = (fileSize / 1024);
//                                   fileSize = (fileSize * 100).round() / 100;
//                                   //remove ?alt=media
//                                   fileName = fileName.split('?').first;

//                                   return ListTile(
//                                     title: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         // File name (ellipsis if it's too long)
//                                         Expanded(
//                                           flex: 4, // Flex for file name column
//                                           child: Text(
//                                             fileName,
//                                             overflow: TextOverflow.ellipsis,
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(
//                                             width:
//                                                 16), // Spacer between columns

//                                         // File size
//                                         Expanded(
//                                           flex: 1, // Flex for file size column
//                                           child: Text(
//                                             '$fileSize KB',
//                                             style: TextStyle(
//                                               color: Colors.grey.shade600,
//                                               fontSize: 12,
//                                             ),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                         ),
//                                         const SizedBox(
//                                             width:
//                                                 16), // Spacer between columns

//                                         // Upload date
//                                         Expanded(
//                                           flex:
//                                               3, // Flex for date and time column
//                                           child: Text(
//                                             DateFormat('dd-MM-yyyy HH:mm')
//                                                 .format(uploadedAt),
//                                             style: TextStyle(
//                                               color: Colors.grey.shade600,
//                                               fontSize: 12,
//                                             ),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                     trailing: IconButton(
//                                       icon: const Icon(Icons.download),
//                                       onPressed: _isDownloading
//                                           ? null
//                                           : () => _downloadFile(fileName),
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                       if (_isDownloading) ...[
//                         const SizedBox(height: 16),
//                         LinearProgressIndicator(value: _downloadProgress / 100),
//                         const SizedBox(height: 8),
//                         Text('${_downloadProgress.toStringAsFixed(1)}%'),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
