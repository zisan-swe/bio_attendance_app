import 'package:flutter/material.dart';
import 'package:biometric_attendance/models/setting_model.dart';
import 'package:biometric_attendance/db/database_helper.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyValueController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();

  SettingModel? _currentSetting;

  @override
  void initState() {
    super.initState();
    _loadSetting();

    // Always update slug when company name changes
    _companyNameController.addListener(() {
      final slug = _companyNameController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      _slugController.text = slug;
    });
  }

  Future<void> _loadSetting() async {
    final setting = await DatabaseHelper.instance.getFirstSetting();

    if (setting != null) {
      setState(() {
        _currentSetting = setting;
        _companyNameController.text = setting.name;
        _companyValueController.text = setting.value ?? "";
        _slugController.text = setting.slug;
      });
    } else {
      _slugController.text = "";
    }
  }



  Future<void> _saveOrUpdateSetting() async {
    if (_formKey.currentState!.validate()) {
      final setting = SettingModel(
        id: _currentSetting?.id,
        name: _companyNameController.text.trim(),
        value: _companyValueController.text.trim(),
        slug: _slugController.text.trim(),
      );

      if (_currentSetting == null) {
        await DatabaseHelper.instance.insertSetting(setting);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Settings saved successfully')),
        );
      } else {
        await DatabaseHelper.instance.updateSetting(setting);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Settings updated successfully')),
        );
      }

      _loadSetting(); // reload UI with fresh data
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Card(
            elevation: 6,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Settings Information",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 20),

                    _buildTextField(
                      label: 'Name',
                      icon: Icons.business,
                      controller: _companyNameController,
                    ),
                    _buildTextField(
                      label: 'Value',
                      icon: Icons.attach_money,
                      controller: _companyValueController,
                    ),
                    _buildTextField(
                      label: 'Slug',
                      icon: Icons.link,
                      controller: _slugController,
                      readOnly: true, // slug auto-generated
                    ),

                    SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveOrUpdateSetting,
                        icon: Icon(Icons.save),
                        label: Text(
                          _currentSetting == null ? 'Save' : 'Update',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
