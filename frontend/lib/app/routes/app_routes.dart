// 路由配置
import 'package:flutter/material.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/app_screen.dart';
import '../../screens/motion_recommendation_screen.dart';
import '../../screens/posture_detection_screen.dart';
import '../../screens/choose_part_of_body_screen.dart';
import '../../screens/video_player_screen.dart';
import '../../screens/user_center_screen.dart';
import '../../screens/user_info_screen.dart';
import '../../screens/preference_screen.dart';
import '../../screens/health_data_screen.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
GoRoute(
      path: '/app_screen',
      builder: (context, state) => const AppScreen(),
    ),
    GoRoute(
      path: '/motion_recommendation',
      builder: (context, state) {
        String? initialBodyPart;
        final extra = state.extra;
        if (extra is String) {
          initialBodyPart = extra;
        } else if (extra is Map) {
          initialBodyPart = extra['bodyPart']?.toString();
        }
        return MotionRecommendationScreen(initialBodyPart: initialBodyPart);
      },
    ),
    GoRoute(
      path: '/posture_detection',
      builder: (context, state) => const PostureDetectionScreen(),
    ),
    GoRoute(
      path: '/choose_part_of_body',
      builder: (context, state) => const ChoosePartOfBodyScreen(),
    ),
    GoRoute(
      path: '/preview/body_model',
      builder: (context, state) => const ChoosePartOfBodyScreen(),
    ),
    GoRoute(
      path: '/video_player',
      builder: (context, state) {
        final motionData = state.extra as Map<String, dynamic>?;
        return VideoPlayerScreen(motionData: motionData);
      },
    ),
    GoRoute(
      path: '/user_center',
      builder: (context, state) => const UserCenterScreen(),
    ),
    GoRoute(
      path: '/user_info',
      builder: (context, state) => const UserInfoScreen(),
    ),
    GoRoute(
      path: '/preference',
      builder: (context, state) => const PreferenceScreenSimple(),
    ),
    GoRoute(
      path: '/health_data',
      builder: (context, state) => const HealthDataScreen(),
    ),
  ],
);

