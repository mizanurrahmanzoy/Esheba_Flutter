import 'package:esheba_fixian/screens/auth/choose_account_type_screen.dart';
import 'package:esheba_fixian/screens/auth/register_customer_screen.dart';
import 'package:esheba_fixian/screens/auth/register_provider_screen.dart';
import 'package:esheba_fixian/screens/premium/premium_screen.dart';
import 'package:esheba_fixian/screens/provider/create_service_screen.dart';
import 'package:esheba_fixian/screens/provider/provider_profile_screen.dart';
import 'package:esheba_fixian/screens/provider/provider_verification_upload_screen.dart';
import 'package:esheba_fixian/screens/user/user_edit_profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'screens/service_list_screen.dart';

import 'screens/service_list_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_bgHandler);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const EShebaApp());
}

class EShebaApp extends StatelessWidget {
  const EShebaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESheba Fixian',
      theme: ThemeData(primarySwatch: Colors.blue),

      // 🔥 SINGLE ENTRY POINT
      home: const AuthGate(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/choose-account': (_) => const ChooseAccountTypeScreen(),
        '/register-customer': (_) => const RegisterCustomerScreen(),
        '/register-provider': (_) => const RegisterProviderScreen(),
        '/provider-profile': (context) => const ProviderProfileScreen(),

        '/services': (context) => const ServiceListScreen(),

        '/services-user': (ctx) => const ServiceListUserScreen(),

        '/create-service': (context) => const CreateServiceScreen(),
        '/premium_upgrade': (context) => const PremiumScreen(),
        '/edit-profile': (context) => const UserEditProfileScreen(),
        '/provider-verification': (context) =>
            const ProviderVerificationUploadScreen(),
      },
    );
  }
}

Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

