import 'package:flutter/material.dart';
import 'services/database_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _databaseService = DatabaseService.instance;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Kayıt işlemi başlatılıyor...');
      print('Kullanıcı adı: ${_usernameController.text}');
      print('Email: ${_emailController.text}');

      final success = await _databaseService.registerUser(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt başarılı! Giriş yapabilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kayıt sayfasından çık
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu kullanıcı adı veya email zaten kullanılıyor.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Kayıt hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt sırasında bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıt Ol'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir kullanıcı adı girin';
                  }
                  if (value.length < 3) {
                    return 'Kullanıcı adı en az 3 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir email adresi girin';
                  }
                  if (!value.contains('@')) {
                    return 'Geçerli bir email adresi girin';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir şifre girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi tekrar girin';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Kayıt Ol'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Giriş sayfasına dön
                },
                child: Text('Zaten hesabınız var mı? Giriş yapın'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 