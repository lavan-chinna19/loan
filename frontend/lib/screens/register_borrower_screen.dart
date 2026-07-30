import 'package:flutter/material.dart';
import '../localization.dart';
import '../api_service.dart';

class RegisterBorrowerScreen extends StatefulWidget {
  final LanguageNotifier languageNotifier;
  
  const RegisterBorrowerScreen({super.key, required this.languageNotifier});

  @override
  State<RegisterBorrowerScreen> createState() => _RegisterBorrowerScreenState();
}

class _RegisterBorrowerScreenState extends State<RegisterBorrowerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _teluguNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _teluguNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = {
      'first_name_en': _firstNameController.text.trim(),
      'last_name_en': _lastNameController.text.trim(),
      'name_te': _teluguNameController.text.trim().isEmpty ? null : _teluguNameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'alternative_phone': _altPhoneController.text.trim().isEmpty ? null : _altPhoneController.text.trim(),
      'address_en': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    };

    try {
      await ApiService.createBorrower(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.languageNotifier.isTelugu 
                  ? 'రుణగ్రహీత విజయవంతంగా నమోదు చేయబడ్డారు!' 
                  : 'Borrower registered successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ln = widget.languageNotifier;

    return Scaffold(
      appBar: AppBar(
        title: Text(ln.translate('register_borrower')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ln.isTelugu ? 'రుణగ్రహీత కొత్త ఖాతా వివరాలు' : 'Borrower Profile Information',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: ln.translate('first_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return ln.isTelugu ? 'మొదటి పేరు తప్పనిసరి' : 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: ln.translate('last_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return ln.isTelugu ? 'చివరి పేరు తప్పనిసరి' : 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Name in Telugu
              TextFormField(
                controller: _teluguNameController,
                decoration: InputDecoration(
                  labelText: ln.isTelugu ? 'తెలుగులో పేరు (ఐచ్ఛికం)' : 'Name in Telugu (Optional)',
                  prefixIcon: const Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: ln.translate('phone_number'),
                  prefixIcon: const Icon(Icons.phone),
                  counterText: "",
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return ln.isTelugu ? 'ఫోన్ నంబర్ తప్పనిసరి' : 'Phone number is required';
                  }
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                    return ln.isTelugu ? 'సరైన 10-అంకెల భారతీయ మొబైల్ నంబర్ ఇవ్వండి (6-9 తో ప్రారంభమవ్వాలి)' : 'Enter a valid 10-digit Indian mobile number (starting with 6-9)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Alt Phone
              TextFormField(
                controller: _altPhoneController,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: ln.translate('alternative_phone'),
                  prefixIcon: const Icon(Icons.phone_iphone),
                  counterText: "",
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                      return ln.isTelugu ? 'సరైన 10-అంకెల భారతీయ మొబైల్ నంబర్ ఇవ్వండి (6-9 తో ప్రారంభమవ్వాలి)' : 'Enter a valid 10-digit Indian mobile number (starting with 6-9)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: ln.translate('address'),
                  prefixIcon: const Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Text(ln.translate('submit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
