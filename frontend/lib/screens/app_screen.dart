// lib/screens/app_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跬步千里'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              icon: Icons.fitness_center,
              title: '微运动推荐',
              subtitle: 'AI 智能推荐运动方案',
              color: Colors.blue,
              onTap: () => context.push('/motion_recommendation'),
            ),
            _buildMenuCard(
              context,
              icon: Icons.videocam,
              title: '视频指导',
              subtitle: '观看运动教学视频',
              color: Colors.orange,
              onTap: () => context.push('/video_player'),
            ),
            _buildMenuCard(
              context,
              icon: Icons.camera_alt,
              title: '姿态检测',
              subtitle: '实时检测运动姿态',
              color: Colors.green,
              onTap: () => context.push('/posture_detection'),
            ),
            _buildMenuCard(
              context,
              icon: Icons.bar_chart,
              title: '健康数据',
              subtitle: '查看运动统计数据',
              color: Colors.purple,
              onTap: () => context.push('/health_data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
