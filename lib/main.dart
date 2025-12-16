import 'package:esheba_fixian/screens/provider/create_service_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/provider_register_screen.dart';

import 'screens/request_list_screen.dart';
import 'screens/service_list_screen.dart';
import 'screens/bid_screen.dart';
import 'screens/request_detail_screen.dart';
import 'screens/service_list_user.dart';
import 'screens/my_orders_user.dart';
import 'screens/provider/orders_provider_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



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
        '/provider-register': (context) => const ProviderRegisterScreen(),

        '/requests': (context) => const RequestListScreen(isUser: true),
        '/services': (context) => const ServiceListScreen(),

        '/bid': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map;
          return BidScreen(requestId: args['requestId']);
        },

        '/request-detail': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map;
          return RequestDetailScreen(requestId: args['requestId']);
        },

        '/services-user': (ctx) => const ServiceListUserScreen(),
        '/my-orders': (ctx) => const MyOrdersUserScreen(),
        '/provider-orders': (ctx) => const ProviderOrdersScreen(),
        '/create-service': (context) => const CreateServiceScreen(),
      },
    );
  }
}
