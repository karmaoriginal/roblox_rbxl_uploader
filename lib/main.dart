import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const RobloxUploaderApp());
}

class RobloxUploaderApp extends StatelessWidget {
  const RobloxUploaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roblox .rbxl Uploader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A2FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00A2FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A2FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const UploadScreen(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _storage = const FlutterSecureStorage();
  final _apiKeyController = TextEditingController();
  final _placeIdController = TextEditingController();
  final _dio = Dio();

  bool _obscureApiKey = true;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final apiKey = await _storage.read(key: 'roblox_api_key');
    final placeId = await _storage.read(key: 'roblox_place_id');
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
    if (placeId != null) {
      _placeIdController.text = placeId;
    }
  }

  Future<void> _saveCredentials() async {
    await _storage.write(key: 'roblox_api_key', value: _apiKeyController.text.trim());
    await _storage.write(key: 'roblox_place_id', value: _placeIdController.text.trim());
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['rbxl'],
        allowMultiple: false,
        withData: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final stat = await file.stat();
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = stat.size;
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar archivo: \$e', isError: true);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '\$bytes B';
    if (bytes < 1024 * 1024) return '\${(bytes / 1024).toStringAsFixed(1)} KB';
    return '\${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _uploadToRoblox() async {
    final apiKey = _apiKeyController.text.trim();
    final placeId = _placeIdController.text.trim();

    if (apiKey.isEmpty) {
      _showSnackBar('Ingresa tu x-api-key de Roblox', isError: true);
      return;
    }
    if (placeId.isEmpty) {
      _showSnackBar('Ingresa el Place ID', isError: true);
      return;
    }
    if (_selectedFilePath == null) {
      _showSnackBar('Selecciona un archivo .rbxl primero', isError: true);
      return;
    }

    await _saveCredentials();

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final file = File(_selectedFilePath!);
      final fileBytes = await file.readAsBytes();

      final url = 'https://apis.roblox.com/v1/places/\$placeId/versions?versionType=Saved';

      final response = await _dio.post(
        url,
        data: Stream.fromIterable([fileBytes]),
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'Content-Type': 'application/octet-stream',
          },
          contentType: 'application/octet-stream',
          responseType: ResponseType.json,
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (response.statusCode == 200) {
        final versionNumber = response.data['versionNumber'];
        _showSnackBar(
          '¡Subida exitosa! Nueva versión: #\$versionNumber',
          isError: false,
        );
      } else {
        _showSnackBar(
          'Error del servidor: \${response.statusCode}',
          isError: true,
        );
      }
    } on DioException catch (e) {
      String message = 'Error de conexión';
      if (e.response != null) {
        message = 'Error \${e.response?.statusCode}: \${e.response?.data ?? e.message}';
      } else {
        message = e.message ?? 'Error desconocido';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('Error inesperado: \$e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _placeIdController.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A2FF), Color(0xFF0066CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A2FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Roblox .rbxl Uploader',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sube tus places a Roblox vía Open Cloud API',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // API Key
                        TextField(
                          controller: _apiKeyController,
                          obscureText: _obscureApiKey,
                          decoration: InputDecoration(
                            labelText: 'x-api-key de Roblox',
                            hintText: 'Ingresa tu API Key de Open Cloud',
                            prefixIcon: const Icon(Icons.vpn_key_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureApiKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Place ID
                        TextField(
                          controller: _placeIdController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Place ID',
                            hintText: 'Ej: 123456789',
                            prefixIcon: Icon(Icons.place_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // File Picker
                        OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickFile,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: Text(
                            _selectedFileName ?? 'Seleccionar archivo .rbxl',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        if (_selectedFileName != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_rounded,
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFileName!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_selectedFileSize != null)
                                        Text(
                                          _formatFileSize(_selectedFileSize!),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFilePath = null;
                                      _selectedFileName = null;
                                      _selectedFileSize = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Upload Button
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadToRoblox,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: Text(
                            _isUploading ? 'Subiendo...' : 'Publicar / Subir a Roblox',
                          ),
                        ),

                        // Progress
                        if (_isUploading) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00A2FF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\${(_uploadProgress * 100).toStringAsFixed(1)}% completado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer
                  Text(
                    'Tu API Key se guarda de forma segura en el dispositivo.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
