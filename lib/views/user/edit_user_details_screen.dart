import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'user_dashboard.dart';

class EditUserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditUserDetailsScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditUserDetailsScreen> createState() => _EditUserDetailsScreenState();
}

class _EditUserDetailsScreenState extends State<EditUserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();

  String _selectedGender = 'Male';
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data - with robust type checking
    _nameController.text = widget.userData['name']?.toString() ?? '';
    _emailController.text = widget.userData['email']?.toString() ?? '';
    _phoneController.text = widget.userData['number']?.toString() ?? '';

    // Handle age with special care since it might be an int in the database
    final age = widget.userData['age'];
    _ageController.text = age != null ? age.toString() : '';

    _addressController.text = widget.userData['address']?.toString() ?? '';
    _cityController.text = widget.userData['city']?.toString() ?? '';
    _regionController.text = widget.userData['region']?.toString() ?? '';
    _selectedGender = widget.userData['gender']?.toString() ?? 'Male';
    _currentImageUrl = widget.userData['profile_image_url']?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress image to reduce size
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _currentImageUrl;

    try {
      final userId = supabase.auth.currentUser!.id;
      final fileExt = path.extension(_selectedImage!.path);
      final fileName = 'profile_$userId$fileExt';

      // Upload to Supabase Storage
      await supabase.storage
          .from('profile_images')
          .upload(fileName, _selectedImage!, fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final imageUrl = supabase.storage
          .from('profile_images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if selected and get URL
      final imageUrl = await _uploadImage();

      // Prepare data for update
      final userId = widget.userData['user_id'] ?? supabase.auth.currentUser!.id;
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'number': _phoneController.text,
        'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        'gender': _selectedGender,
        'address': _addressController.text,
        'city': _cityController.text,
        'region': _regionController.text,
      };

      // Add image URL to data if available
      if (imageUrl != null) {
        userData['profile_image_url'] = imageUrl;
      }

      // Update user data in Supabase
      await supabase
          .from('profiles')
          .update(userData)
          .eq('user_id', userId);

      if (mounted) {
        Navigator.pop(context, userData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          "Edit Your Profile",
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildProfileForm(context),
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: _selectedImage != null
                            ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                            : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(_currentImageUrl!),
                          fit: BoxFit.cover,
                        )
                            : null),
                      ),
                      child: (_selectedImage == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                          ? Icon(
                        Icons.person,
                        size: 60,
                        color: colors.onPrimaryContainer,
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                            border: Border.all(
                              color: colors.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: colors.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Upload Profile Picture",
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Personal Information Card
              Card(
                color: colors.surfaceContainerHighest.brighten(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Full Name Field
                      _buildTextField(
                        label: "Full Name",
                        controller: _nameController,
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      _buildTextField(
                        label: "Email",
                        controller: _emailController,
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age Field
                      _buildTextField(
                        label: "Age",
                        controller: _ageController,
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number Field
                      _buildTextField(
                        label: "Phone Number",
                        controller: _phoneController,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Gender Selection
                      Text(
                        "Gender",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: colors.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildGenderOption(context, "Male", Icons.male),
                          const SizedBox(width: 16),
                          _buildGenderOption(context, "Female", Icons.female),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address Card
              Card(
                color: colors.surfaceContainerHighest.brighten(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Address Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Street Address
                      _buildTextField(
                        label: "Street Address",
                        controller: _addressController,
                        icon: Icons.home,
                      ),
                      const SizedBox(height: 16),

                      // City
                      _buildTextField(
                        label: "City",
                        controller: _cityController,
                        icon: Icons.location_city,
                      ),
                      const SizedBox(height: 16),

                      // Region
                      _buildTextField(
                        label: "Region/State/Province",
                        controller: _regionController,
                        icon: Icons.map,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              _buildSaveButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colors = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colors.onSurface.withOpacity(0.7),
        ),
        prefixIcon: Icon(
          icon,
          color: colors.primary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderOption(BuildContext context, String gender, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = _selectedGender == gender;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = gender;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withOpacity(0.1) : colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.7),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.onSurface,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveUserData,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 5,
          shadowColor: colors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 24),
            SizedBox(width: 8),
            Text(
              "Save Profile",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}