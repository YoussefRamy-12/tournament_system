import 'package:admin_app/database/csv_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);
  
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isLoading = false;

  Future<void> _pickAndImportCsv() async {
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final csvService = CsvService();
        
        // Check if database has existing data
        final hasData = await csvService.hasExistingData();
        
        if (hasData) {
          // Clear existing rows before importing
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Exist!'),
              backgroundColor: Colors.green,
            ),
          );
          await csvService.clearAllMembers();
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data Cleared!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        await csvService.importMembersFromCsv(result.files.single.path!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Import Successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tournament Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Import Members from CSV', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndImportCsv,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.folder_open),
              label: Text(_isLoading ? 'Importing...' : 'Pick CSV File'),
            ),
          ],
        ),
      ),
    );
  }
}