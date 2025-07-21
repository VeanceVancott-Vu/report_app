import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/report_viewmodel.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class NewReportScreen extends StatefulWidget {
  const NewReportScreen({super.key});

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final reportVM = context.watch<ReportViewModel>();
    final authService = context.watch<AuthService>();
    final AppUser? user = authService.currentAppUser;

    // If user is not available yet, show loading
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.address ?? 'Unknown location',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: reportVM.isLoading ? null : () => _sendReport(user),
              child: reportVM.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReport(AppUser user) async {
    final reportVM = context.read<ReportViewModel>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter title and description')),
      );
      return;
    }


    // final success = await reportVM.add(
    //   userId: user.uid,
    //   title: title,
    //   description: description,
    //   address: user.address ?? 'Unknown',
    //   latitude: user.latitude,
    //   longitude: user.longitude,
    // );

    // if (success) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Report submitted successfully')),
    //   );
    //   _titleController.clear();
    //   _descriptionController.clear();
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Failed to submit report')),
    //   );
    // }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
