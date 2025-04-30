import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../models/user.dart';
import 'user_controller.dart';
import 'dart:developer' as developer;


class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final isLoading = false.obs;
  final emailError = RxString('');
  final passwordError = RxString('');
  final isPasswordVisible = false.obs; // Added for password visibility toggle
  
  // Get the UserController instance
  final UserController userController = Get.find<UserController>();
  
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
  
  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  
  // Validate email as user types
  void validateEmail(String value) {
    if (value.isEmpty) {
      emailError.value = 'Email cannot be empty';
    } else if (!GetUtils.isEmail(value)) {
      emailError.value = 'Please enter a valid email';
    } else {
      emailError.value = '';
    }
  }
  
  // Validate password as user types
  void validatePassword(String value) {
    if (value.isEmpty) {
      passwordError.value = 'Password cannot be empty';
    } else if (value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
    } else {
      passwordError.value = '';
    }
  }
  
  bool validateInputs() {
    bool isValid = true;
    
    // Reset previous errors
    emailError.value = '';
    passwordError.value = '';
    
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
    
    return isValid;
  }
  
  Future<void> login() async {
    if (!validateInputs()) return;
    try {
      isLoading.value = true;
      // Ensure Isar is initialized (reuse SignupController's instance if possible)
      Isar isar;
      if (Isar.instanceNames.isNotEmpty) {
        isar = Isar.getInstance()!;
      } else {
        // Fallback: open Isar if not already open (shouldn't happen in normal flow)
        // You may want to refactor this to share instance properly
        throw Exception('Isar instance is not initialized.');
      }
      final email = emailController.text.trim();
      final password = passwordController.text;
      final user = await isar.userModels.filter()
        .emailEqualTo(email)
        .passwordEqualTo(password)
        .findFirst();
      if (user == null) {
        // Check if user exists with this email
        final userByEmail = await isar.userModels.filter().emailEqualTo(email).findFirst();
        if (userByEmail == null) {
          developer.log('Login failed: User not found for email $email', name: 'LoginController');
          Get.snackbar(
            'Login Error',
            'User does not exist. Please sign up first.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(10),
          );
        } else {
          developer.log('Login failed: Invalid password for $email', name: 'LoginController');
          Get.snackbar(
            'Login Error',
            'Invalid password. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(10),
          );
        }
      } else {
        developer.log('Login successful for user: name=${user.name}, email=${user.email}', name: 'LoginController');
        // Set the user in the UserController
        userController.setUser(user);
        
        // Navigate without arguments, state is managed by UserController
        Get.offAllNamed('/home'); 
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'LoginController', level: 1000);
      Get.snackbar(
        'Login Error',
        'Failed to login',
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
  
  void goToSignup() {
    Get.toNamed('/signup');
  }
}
