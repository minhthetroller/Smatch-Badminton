import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../core/theme/app_theme.dart';
import '../../models/court.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/match_view_model.dart';
import '../../view_models/search_view_model.dart';

/// Form screen for creating a new match
class CreateMatchView extends StatefulWidget {
  const CreateMatchView({super.key});

  @override
  State<CreateMatchView> createState() => _CreateMatchViewState();
}

class _CreateMatchViewState extends State<CreateMatchView> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _slotsController = TextEditingController(text: '3');

  // Form state
  Court? _selectedCourt;
  SkillLevel _skillLevel = SkillLevel.tb;
  ShuttleType _shuttleType = ShuttleType.tc77;
  PlayerFormat _playerFormat = PlayerFormat.doubleMale;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  bool _isPrivate = false;
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Match',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Court Selection
            _buildSectionTitle('Court *'),
            const SizedBox(height: 8),
            _buildCourtSelector(),
            const SizedBox(height: 20),

            // Match Title
            _buildSectionTitle('Match Title *'),
            const SizedBox(height: 8),
            _buildTitleField(),
            const SizedBox(height: 20),

            // Description
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            _buildDescriptionField(),
            const SizedBox(height: 20),

            // Images
            _buildSectionTitle('Images (Optional, up to 3)'),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 20),

            // Date and Time
            _buildSectionTitle('Date & Time *'),
            const SizedBox(height: 8),
            _buildDateTimeSection(),
            const SizedBox(height: 20),

            // Skill Level
            _buildSectionTitle('Skill Level *'),
            const SizedBox(height: 8),
            _buildSkillLevelSelector(),
            const SizedBox(height: 20),

            // Player Format
            _buildSectionTitle('Player Format *'),
            const SizedBox(height: 8),
            _buildPlayerFormatSelector(),
            const SizedBox(height: 20),

            // Shuttle Type
            _buildSectionTitle('Shuttle Type *'),
            const SizedBox(height: 8),
            _buildShuttleTypeSelector(),
            const SizedBox(height: 20),

            // Price and Slots
            _buildSectionTitle('Price & Slots *'),
            const SizedBox(height: 8),
            _buildPriceSlotsRow(),
            const SizedBox(height: 20),

            // Privacy Toggle
            _buildPrivacyToggle(),
            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildCourtSelector() {
    return InkWell(
      onTap: _showCourtSearchSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedCourt == null ? Colors.grey.shade300 : AppTheme.primaryColor,
            width: _selectedCourt == null ? 1 : 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: _selectedCourt == null ? Colors.grey : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCourt?.name ?? 'Select a court',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedCourt == null ? AppTheme.textHint : AppTheme.textPrimary,
                    ),
                  ),
                  if (_selectedCourt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _selectedCourt!.fullAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  void _showCourtSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourtSearchSheet(
        onCourtSelected: (court) {
          setState(() => _selectedCourt = court);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: _inputDecoration(
        hintText: 'e.g., Đánh giao lưu cuối tuần',
        prefixIcon: Icons.title,
      ),
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        if (value.trim().length < 5) {
          return 'Title must be at least 5 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: _inputDecoration(
        hintText: 'Add details about your match...',
        prefixIcon: Icons.description,
      ),
      maxLines: 3,
      maxLength: 2000,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      children: [
        // Date picker
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Time pickers row
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(isStartTime: true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_startTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _pickTime(isStartTime: false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(_endTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillLevelSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SkillLevel.values.map((level) {
        final isSelected = _skillLevel == level;
        return ChoiceChip(
          label: Text(level.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _skillLevel = level);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerFormatSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlayerFormat.values.map((format) {
        final isSelected = _playerFormat == format;
        return ChoiceChip(
          label: Text(format.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _playerFormat = format);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShuttleTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ShuttleType.values.map((type) {
        final isSelected = _shuttleType == type;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _shuttleType = type);
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSlotsRow() {
    return Row(
      children: [
        // Price field
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _priceController,
            decoration: _inputDecoration(
              hintText: 'Price (VND)',
              prefixIcon: Icons.attach_money,
              suffixText: 'đ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsSeparatorFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final price = int.tryParse(value.replaceAll('.', ''));
              if (price == null || price < 0) {
                return 'Invalid price';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // Slots field
        Expanded(
          child: TextFormField(
            controller: _slotsController,
            decoration: _inputDecoration(
              hintText: 'Slots',
              prefixIcon: Icons.people,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              final slots = int.tryParse(value);
              if (slots == null || slots < 1) {
                return 'Min 1';
              }
              if (slots > 10) {
                return 'Max 10';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            _isPrivate ? Icons.lock : Icons.lock_open,
            color: _isPrivate ? Colors.orange : AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Private Match',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPrivate
                      ? 'Players need your approval to join'
                      : 'Anyone can join immediately',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (value) => setState(() => _isPrivate = value),
            activeTrackColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image thumbnails
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_selectedImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_selectedImages.isNotEmpty) const SizedBox(height: 12),
        
        // Add image buttons
        if (_selectedImages.length < 3)
          Row(
            children: [
              // Camera button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Gallery button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        
        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${_selectedImages.length}/3 images selected',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        
        // Validate file size (5MB max)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _selectedImages.add(file);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Create Match',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppTheme.textSecondary),
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStartTime}) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Auto-adjust end time if start time is after end time
          if (_timeToMinutes(picked) >= _timeToMinutes(_endTime)) {
            _endTime = TimeOfDay(
              hour: (picked.hour + 2) % 24,
              minute: picked.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitForm() async {
    // Validate court selection
    if (_selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a court'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate time range
    if (_timeToMinutes(_startTime) >= _timeToMinutes(_endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Minimum 1 hour duration
    final duration = _timeToMinutes(_endTime) - _timeToMinutes(_startTime);
    if (duration < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match duration must be at least 1 hour'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Capture context-dependent objects before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Refresh auth token before creating match to avoid expired token errors
      final authVM = context.read<AuthViewModel>();
      final matchVM = context.read<MatchViewModel>();

      if (authVM.isAnonymous) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Please sign in to create a match.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final token = await authVM.refreshAuthToken();
      
      if (token == null) {
        throw Exception('Failed to refresh authentication. Please sign in again.');
      }

      final request = CreateMatchRequest(
        courtId: _selectedCourt!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        skillLevel: _skillLevel,
        shuttleType: _shuttleType,
        playerFormat: _playerFormat,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        isPrivate: _isPrivate,
        price: int.parse(_priceController.text.replaceAll('.', '')),
        slotsNeeded: int.parse(_slotsController.text),
      );
      
      // Use different methods based on whether images are selected
      final MatchWithDetails? match;
      if (_selectedImages.isNotEmpty) {
        match = await matchVM.createMatchWithImages(request, _selectedImages);
      } else {
        match = await matchVM.createMatch(request);
      }

      if (!mounted) return;
      if (match != null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Match created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop(match);
      }
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : e.toString();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to create match: $message'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

/// Thousands separator formatter for price input
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) return oldValue;

    final formatter = NumberFormat('#,###', 'vi_VN');
    final formatted = formatter.format(number).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Bottom sheet for searching and selecting a court
class _CourtSearchSheet extends StatefulWidget {
  final Function(Court) onCourtSelected;

  const _CourtSearchSheet({required this.onCourtSelected});

  @override
  State<_CourtSearchSheet> createState() => _CourtSearchSheetState();
}

class _CourtSearchSheetState extends State<_CourtSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Select Court',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search courts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  context.read<SearchViewModel>().searchAutocomplete(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Results
          Expanded(
            child: Consumer<SearchViewModel>(
              builder: (context, searchVM, _) {
                if (searchVM.isLoadingAutocomplete) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                if (searchVM.autocompleteSuggestions.isEmpty) {
                  return Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Type to search for courts'
                          : 'No courts found',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: searchVM.autocompleteSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = searchVM.autocompleteSuggestions[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Icon(Icons.sports_tennis, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        suggestion.text,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: suggestion.address != null
                          ? Text(
                              suggestion.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                      onTap: () {
                        // Create a Court from suggestion
                        final court = Court(
                          id: suggestion.id,
                          name: suggestion.text,
                          addressStreet: suggestion.address,
                        );
                        widget.onCourtSelected(court);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
