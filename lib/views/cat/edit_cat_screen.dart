import 'dart:io';
import 'package:cat_app/views/auth/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditCatScreen extends StatefulWidget {
  final Map<String, dynamic> cat;

  const EditCatScreen({
    super.key,
    required this.cat,
  });

  @override
  State<EditCatScreen> createState() => _EditCatScreenState();
}

class _EditCatScreenState extends State<EditCatScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _colorController;

  File? _imageFile;
  final _imagePicker = ImagePicker();
  String? _gender;
  bool _isLoading = false;
  String? _currentImageUrl;

  final List<String> genderOptions = ['Male', 'Female'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing cat data
    _nameController = TextEditingController(text: widget.cat['name']);
    _breedController = TextEditingController(text: widget.cat['breed']);
    _ageController = TextEditingController(text: widget.cat['age'].toString());
    _colorController = TextEditingController(text: widget.cat['color']);
    _gender = widget.cat['gender'];
    _currentImageUrl = widget.cat['image_url'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateCat() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Create a map for the updated cat data
      final catData = {
        'name': _nameController.text.trim(),
        'breed': _breedController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'color': _colorController.text.trim(),
        'gender': _gender,
      };

      // If we have a new image, upload it to storage
      if (_imageFile != null) {
        final fileExtension = _imageFile!.path.split('.').last;
        final fileName = 'cat_${widget.cat['id']}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final filePath = 'cat-images/$userId/$fileName';

        // Upload the file
        await Supabase.instance.client.storage
            .from('cat-images')
            .upload(filePath, _imageFile!);

        // Update the cat data with the new image URL
        final imageUrl = Supabase.instance.client.storage
            .from('cat-images')
            .getPublicUrl(filePath);

        catData['image_url'] = imageUrl;
      }

      // Update the cat record in the database
      await Supabase.instance.client
          .from('cats')
          .update(catData)
          .eq('id', widget.cat['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cat updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating cat: ${e.toString()}'),
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
          "Edit Cat Details",
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildCatForm(context),
    );
  }

  Widget _buildCatForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cat Image Section
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
                        image: _imageFile != null
                            ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                            : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(_currentImageUrl!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                          ? Icon(
                        Icons.pets,
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
                  "Change Cat Picture",
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Cat Information Card
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
                        "Cat Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cat Name Field
                      _buildTextField(
                        label: "Cat Name",
                        controller: _nameController,
                        icon: Icons.pets,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter cat name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Breed Field
                      _buildTextField(
                        label: "Breed",
                        controller: _breedController,
                        icon: Icons.category,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter breed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age Field
                      _buildTextField(
                        label: "Age (in years)",
                        controller: _ageController,
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter age';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Color Field
                      _buildTextField(
                        label: "Color",
                        controller: _colorController,
                        icon: Icons.color_lens,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter color';
                          }
                          return null;
                        },
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

              const SizedBox(height: 40),

              // Update Button
              _buildUpdateButton(context),
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
    final isSelected = _gender == gender;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _gender = gender;
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

  Widget _buildUpdateButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateCat,
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
            Icon(Icons.save, size: 24),
            SizedBox(width: 8),
            Text(
              "Save Changes",
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