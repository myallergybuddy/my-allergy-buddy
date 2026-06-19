import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'models/medication.dart';
import 'package:flutter/services.dart';
import 'scan_label_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  final _personalFormKey = GlobalKey<FormState>();
  final _medicalFormKey = GlobalKey<FormState>();
  
  // Individual section editing states
  bool _isEditingPersonal = false;
  bool _isEditingMedical = false;
  bool _isEditingSavedMedications = false;
  
  // Profile fields
  String _name = '';
  String _phone = '';
  
  // Text controllers for form fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Allergies list
  List<Map<String, dynamic>> _allergies = [];
  
  // Medication management
  List<Medication> _medications = [];
  final _medicationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMedications();
    _loadProfileData();
    _loadAllergies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _phoneController.dispose();
    _medicationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      _loadAllergies();
      _loadMedications();
      _loadProfileData();
    }
  }

  // Add method to refresh data when screen becomes visible
  void _refreshData() {
    _loadAllergies();
    _loadMedications();
    _loadProfileData();
  }

  Future<void> _loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medicationsJson = prefs.getStringList('medications') ?? [];
    setState(() {
      _medications = medicationsJson
          .map((json) => Medication.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('profile_name') ?? '';
      _phone = prefs.getString('profile_phone') ?? '';
      
      // Update controllers with loaded data
      _nameController.text = _name;
      _phoneController.text = _phone;
    });
  }

  Future<void> _loadAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final allergiesJson = prefs.getStringList('saved_allergies') ?? [];
    setState(() {
      _allergies = allergiesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _name);
    await prefs.setString('profile_phone', _phone);
  }

  Future<void> _saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medicationsJson = _medications
        .map((med) => jsonEncode(med.toJson()))
        .toList();
    await prefs.setStringList('medications', medicationsJson);
  }

  Future<void> _deleteMedication(Medication medication) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Medication',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete ${medication.name}?',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _medications.removeWhere((m) => m.id == medication.id);
                });
                _saveMedications();
                Navigator.pop(context);
                _showSuccessSnackBar('${medication.name} has been deleted');
              },
              child: Text(
                'Delete',
                style: GoogleFonts.nunito(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditMedicationDialog(Medication medication, int index) {
    final TextEditingController nameController = TextEditingController(text: medication.name);
    final TextEditingController notesController = TextEditingController(text: medication.notes ?? '');
    DateTime selectedDate = medication.expiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Edit Medication',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name *',
                      prefixIcon: Icon(Icons.medication, color: Color(0xFF4A9E9C)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter medication name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date *',
                        prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF4A9E9C)),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(selectedDate),
                        style: GoogleFonts.nunito(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note, color: Color(0xFF4A9E9C)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter medication name')),
                    );
                    return;
                  }

                  final updatedMedication = Medication(
                    id: medication.id,
                    name: nameController.text,
                    expiryDate: selectedDate,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );

                  this.setState(() {
                    _medications[index] = updatedMedication;
                  });

                  _saveMedications();
                  Navigator.pop(context);
                  _showSuccessSnackBar('Medication updated successfully!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9E9C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  'Update',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addMedication() {
    if (_medicationController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _medicationController.text,
      expiryDate: _selectedDate!,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    setState(() {
      _medications.add(medication);
      _medicationController.clear();
      _notesController.clear();
      _selectedDate = null;
    });

    _saveMedications();
    _showSuccessSnackBar('Medication added successfully!');
  }

  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add Medication',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                  prefixIcon: Icon(Icons.medication, color: Color(0xFF4A9E9C)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date *',
                    prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF4A9E9C)),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    style: GoogleFonts.nunito(
                      color: _selectedDate == null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note, color: Color(0xFF4A9E9C)),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_medicationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter medication name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (_selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select expiry date'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _addMedication();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
            ),
            child: Text(
              'Add',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4A9E9C),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPersonalInfoEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Personal Information',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Form(
          key: _personalFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                label: 'Full Name',
                controller: _nameController,
                icon: Icons.person,
                enabled: true,
                capitalizeWords: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone,
                enabled: true,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_personalFormKey.currentState!.validate()) {
                _name = _nameController.text;
                _phone = _phoneController.text;
                _saveProfileData();
                Navigator.pop(context);
                setState(() {});
                _showSuccessSnackBar('Personal information updated successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePersonalInfo() async {
    if (_personalFormKey.currentState!.validate()) {
      _name = _nameController.text;
      _phone = _phoneController.text;
      await _saveProfileData();
      setState(() {
        _isEditingPersonal = false;
      });
      _showSuccessSnackBar('Personal information updated successfully!');
    }
  }

  void _saveMedicalInfo() async {
    // Medical info is now just displaying allergies, no save needed
    setState(() {
      _isEditingMedical = false;
    });
    _showSuccessSnackBar('Medical information updated successfully!');
  }

  void _cancelPersonalEdit() {
    setState(() {
      _isEditingPersonal = false;
      _nameController.text = _name;
      _phoneController.text = _phone;
    });
  }

  void _cancelMedicalEdit() {
    setState(() {
      _isEditingMedical = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Personal Information Section
              if (_name.isEmpty && _phone.isEmpty) ...[
                // Show the full section only when no data exists
                Form(
                  key: _personalFormKey,
                  child: _buildEditableSection(
                    title: 'Personal Information',
                    isEditing: _isEditingPersonal,
                    onEditToggle: () => setState(() => _isEditingPersonal = !_isEditingPersonal),
                    onSave: _savePersonalInfo,
                    onCancel: _cancelPersonalEdit,
                    children: [
                      const SizedBox(height: 8),
                      if (_isEditingPersonal) ...[
                        // Show form fields when editing
                        _buildTextField(
                          label: 'Full Name',
                          controller: _nameController,
                          icon: Icons.person,
                          enabled: _isEditingPersonal,
                          capitalizeWords: true,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          icon: Icons.phone,
                          enabled: _isEditingPersonal,
                          keyboardType: TextInputType.phone,
                        ),
                      ] else ...[
                        // Show placeholder when not editing and no data
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300]!.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Add your personal information',
                                  style: GoogleFonts.nunito(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Show name prominently when data exists
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _name,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      _buildEditButton(onTap: _showPersonalInfoEditDialog),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Medical Information Section
              if (_allergies.isEmpty) ...[
                // Show the full section only when no allergies exist
                Form(
                  key: _medicalFormKey,
                  child: _buildEditableSection(
                    title: 'Medical Information',
                    isEditing: _isEditingMedical,
                    onEditToggle: () => setState(() => _isEditingMedical = !_isEditingMedical),
                    onSave: _saveMedicalInfo,
                    onCancel: _cancelMedicalEdit,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No allergies added yet',
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your allergies from the My Allergies screen',
                              style: GoogleFonts.nunito(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(context, '/my_allergies');
                                // Refresh data when returning from my allergies screen
                                if (result != null || mounted) {
                                  _refreshData();
                                }
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(
                                'Add Allergies',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A9E9C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Show allergies prominently when they exist
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Allergies',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildEditButton(
                                onTap: () {
                                  Navigator.pushNamed(context, '/my_allergies').then((_) {
                                    _refreshData();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Column(
                            children: _allergies.map((allergy) {
                              Color severityColor;
                              switch (allergy['severity']) {
                                case 'High':
                                  severityColor = Colors.red;
                                  break;
                                case 'Medium':
                                  severityColor = Colors.orange;
                                  break;
                                case 'Low':
                                  severityColor = Colors.yellow[700]!;
                                  break;
                                default:
                                  severityColor = Colors.grey;
                              }

                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border(
                                    bottom: _allergies.indexOf(allergy) < _allergies.length - 1
                                        ? BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 0.5)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minVerticalPadding: 0,
                                  minLeadingWidth: 40,
                                  horizontalTitleGap: 12,
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: severityColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.health_and_safety,
                                      color: severityColor,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    allergy['name'],
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: severityColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              allergy['severity'],
                                              style: GoogleFonts.nunito(
                                                color: severityColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (allergy['category'] != null) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                allergy['category'],
                                                style: GoogleFonts.nunito(
                                                  color: const Color(0xFF4A9E9C),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (allergy['notes'] != null && allergy['notes'].isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          allergy['notes'],
                                          style: GoogleFonts.nunito(
                                            color: Colors.black,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Medication Management Section
              if (_medications.isEmpty) ...[
                // Show the full section only when no medications exist
                _buildEditableSection(
                  title: 'Medications',
                  isEditing: _isEditingSavedMedications,
                  onEditToggle: () => setState(() => _isEditingSavedMedications = !_isEditingSavedMedications),
                  onSave: () {
                    setState(() {
                      _isEditingSavedMedications = false;
                    });
                    _showSuccessSnackBar('Medication settings saved!');
                  },
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Manage your medications',
                      style: GoogleFonts.nunito(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 32,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No medications added yet',
                            style: GoogleFonts.nunito(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your medications to track expiry dates',
                            style: GoogleFonts.nunito(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAddMedicationDialog,
                              icon: const Icon(Icons.add),
                              label: Text(
                                'Add Medication',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A9E9C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Show medications prominently when they exist
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Medications',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 28,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildEditButton(
                                onTap: () {
                                  if (_isEditingSavedMedications) {
                                    _showAddMedicationDialog();
                                  } else {
                                    setState(() {
                                      _isEditingSavedMedications = true;
                                    });
                                  }
                                },
                                label: _isEditingSavedMedications ? 'Add' : 'Edit',
                                icon: _isEditingSavedMedications ? Icons.add : Icons.edit,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: _medications.map((medication) {
                            final daysUntilExpiry = medication.expiryDate.difference(DateTime.now()).inDays;
                            final isExpiringSoon = daysUntilExpiry <= 30;
                            final isExpired = daysUntilExpiry < 0;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border(
                                  bottom: _medications.indexOf(medication) < _medications.length - 1
                                      ? BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 0.5)
                                      : BorderSide.none,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minVerticalPadding: 0,
                                minLeadingWidth: 40,
                                horizontalTitleGap: 12,
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isExpired 
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : isExpiringSoon 
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.health_and_safety,
                                    color: isExpired 
                                      ? Colors.red
                                      : isExpiringSoon 
                                        ? Colors.orange
                                        : const Color(0xFF4A9E9C),
                                    size: 16,
                                  ),
                                ),
                                title: Text(
                                  medication.name,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: isExpired 
                                            ? Colors.red
                                            : isExpiringSoon 
                                              ? Colors.orange
                                              : Colors.black,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Expires: ${DateFormat('MMM dd, yyyy').format(medication.expiryDate)}',
                                          style: GoogleFonts.nunito(
                                            color: isExpired 
                                              ? Colors.red
                                              : isExpiringSoon 
                                                ? Colors.orange
                                                : Colors.black,
                                            fontWeight: isExpired || isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        medication.notes!,
                                        style: GoogleFonts.nunito(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (isExpired || isExpiringSoon) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isExpired 
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isExpired 
                                            ? 'EXPIRED'
                                            : 'Expires soon',
                                          style: GoogleFonts.nunito(
                                            color: isExpired ? Colors.red : Colors.orange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: _isEditingSavedMedications
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildIconActionButton(
                                          onTap: () => _showEditMedicationDialog(
                                            medication,
                                            _medications.indexOf(medication),
                                          ),
                                          icon: Icons.edit,
                                          color: const Color(0xFF4A9E9C),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildIconActionButton(
                                          onTap: () => _deleteMedication(medication),
                                          icon: Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ],
                                    )
                                  : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A9E9C),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
        currentIndex: 1, // Allergies is index 1 in the new order
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 21,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ScanLabelScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/my_allergies');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/emergency_contacts');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner, color: Color(0xFF1976D2)), // Scan blue
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety, color: Color(0xFF43A047)), // Allergies green
            label: 'Allergies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF4A9E9C)), // Home teal
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Color(0xFFE53935)), // Emergency red
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Color(0xFF8E24AA)), // Settings purple
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection({
    required String title,
    required bool isEditing,
    required VoidCallback onEditToggle,
    required VoidCallback onSave,
    VoidCallback? onCancel,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and buttons in a more responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  // Stack layout for smaller screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: _buildActionButtons(isEditing, onEditToggle, onSave, onCancel),
                      ),
                    ],
                  );
                } else {
                  // Row layout for larger screens
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ..._buildActionButtons(isEditing, onEditToggle, onSave, onCancel),
                    ],
                  );
                }
              },
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
    bool isEditing,
    VoidCallback onEditToggle,
    VoidCallback onSave,
    VoidCallback? onCancel,
  ) {
    if (isEditing) {
      return [
        Flexible(
          child: TextButton(
            onPressed: onCancel ?? onEditToggle,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 2,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ];
    } else {
      return [
        Flexible(child: _buildEditButton(onTap: onEditToggle)),
      ];
    }
  }

  Widget _buildEditButton({
    required VoidCallback onTap,
    String label = 'Edit',
    IconData icon = Icons.edit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A9E9C),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9E9C).withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: Colors.white, size: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool capitalizeWords = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: capitalizeWords 
          ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), 
             TextInputFormatter.withFunction((oldValue, newValue) {
               return TextEditingValue(
                 text: newValue.text.split(' ').map((word) {
                   if (word.isNotEmpty) {
                     return word[0].toUpperCase() + word.substring(1).toLowerCase();
                   }
                   return word;
                 }).join(' '),
                 selection: newValue.selection,
               );
             })]
          : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: GoogleFonts.nunito(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        style: GoogleFonts.nunito(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }
} 