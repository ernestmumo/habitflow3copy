import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'dart:developer' as developer;
import '../models/user.dart';

late final Isar isarInstance;

class SignupController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final isLoading = false.obs;
  final nameError = RxString('');
  final emailError = RxString('');
  final passwordError = RxString('');
  final confirmPasswordError = RxString('');
  
  // For password visibility toggle
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  
  // Get the auth service instance

  // Initialize Isar instance (should be called in main or via a service)
  Future<void> initIsar() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      isarInstance = await Isar.open([UserModelSchema], directory: dir.path);
      developer.log('Isar database opened at \\${dir.path}', name: 'SignupController');
    } else {
      isarInstance = Isar.getInstance()!;
      developer.log('Isar database already open', name: 'SignupController');
    }
  }

  // Debug: Fetch all users
  Future<void> logAllUsers() async {
    final users = await isarInstance.userModels.where().findAll();
    developer.log('Current users in DB: '
        + users.map((u) => '{id: ${u.id}, name: ${u.name}, email: ${u.email}}').join(', '),
        name: 'SignupController');
  }
  
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
  
  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  
  // Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }
  
  // Validate name field as user types
  void validateName(String value) {
    if (value.isEmpty) {
      nameError.value = 'Name cannot be empty';
    } else {
      nameError.value = '';
    }
  }
  
  // Validate email field as user types
  void validateEmail(String value) {
    if (value.isEmpty) {
      emailError.value = 'Email cannot be empty';
    } else if (!GetUtils.isEmail(value)) {
      emailError.value = 'Please enter a valid email';
    } else {
      emailError.value = '';
    }
  }
  
  // Validate password field as user types
  void validatePassword(String value) {
    if (value.isEmpty) {
      passwordError.value = 'Password cannot be empty';
    } else if (value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
    } else {
      passwordError.value = '';
      // Check confirm password when password changes
      validateConfirmPassword(confirmPasswordController.text);
    }
  }
  
  // Validate confirm password field as user types
  void validateConfirmPassword(String value) {
    if (value.isEmpty) {
      confirmPasswordError.value = 'Confirm password cannot be empty';
    } else if (value != passwordController.text) {
      confirmPasswordError.value = 'Passwords do not match';
    } else {
      confirmPasswordError.value = '';
    }
  }
  
  bool validateInputs() {
    bool isValid = true;
    
    // Reset previous errors
    nameError.value = '';
    emailError.value = '';
    passwordError.value = '';
    confirmPasswordError.value = '';
    
    // Validate name
    if (nameController.text.isEmpty) {
      nameError.value = 'Name cannot be empty';
      isValid = false;
    }
    
    // Validate email
    if (emailController.text.isEmpty) {
      emailError.value = 'Email cannot be empty';
      isValid = false;
    } else if (!GetUtils.isEmail(emailController.text)) {
      emailError.value = 'Please enter a valid email';
      isValid = false;
    }
    
    // Validate password
    if (passwordController.text.isEmpty) {
      passwordError.value = 'Password cannot be empty';
      isValid = false;
    } else if (passwordController.text.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    }
    
    // Validate confirm password
    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    } else if (confirmPasswordController.text != passwordController.text) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }
    
    return isValid;
  }
  
  Future<void> signup() async {
    if (!validateInputs()) return;
    await initIsar();
    try {
      isLoading.value = true;
      // Check if email already exists
      final existing = await isarInstance.userModels.filter().emailEqualTo(emailController.text.trim()).findFirst();
      if (existing != null) {
        developer.log('Email already registered: ${emailController.text.trim()}', name: 'SignupController');
        Get.snackbar(
          'Registration Error',
          'Email already registered. Please use a different email or login.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade700,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(10),
        );
        return;
      }
      // Store user in Isar
      final user = UserModel.create(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await isarInstance.writeTxn(() async {
        await isarInstance.userModels.put(user);
      });
      developer.log('User stored: name=${user.name}, email=${user.email}', name: 'SignupController');
      await logAllUsers(); // Log all users for debugging
      // Optionally, call your auth service as well
      // await _authService.register(...);
      // Navigate to login screen
      Get.offAllNamed('/login');
      Get.snackbar(
        'Success',
        'Account created successfully! Please login.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      developer.log('Signup error: $e', name: 'SignupController', level: 1000);
      Get.snackbar(
        'Registration Error',
        'Failed to create account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(10),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  void goToLogin() {
    Get.toNamed('/login');
  }
}
