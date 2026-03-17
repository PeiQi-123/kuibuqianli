# OpenCode Worklog - 2026-03-12

- Added `scripts/check_project_resources.ps1` to inspect project-related memory usage on Windows.
- Added `database/init/02_alter_user_table_add_profile_columns.sql` to align the `user` table with backend fields used by the current code.
- Updated `scripts/start_backend.bat` to force UTF-8 console startup on Windows.
- Updated `backend/src/main/java/com/kuibuqianli/config/JacksonConfig.java` to make backend responses use UTF-8 more consistently.
- Wired `frontend/lib/screens/motion_recommendation_screen.dart` to the real backend AI endpoint instead of the mock motion endpoint.
- Updated `ai-service/app/core/config.py` and `ai-service/app/services/motion_service.py` so the AI service proxies motion generation to the backend real AI flow.
- Updated `ai-service/app/api/endpoints/motion_generator.py` so:
  - `/api/motion/generate` uses the real AI flow,
  - Swagger examples are easier to understand,
  - `/api/motion/generate-easy` provides a beginner-friendly form-style testing endpoint.

Notes:

- Generated files, logs, caches, virtual environments, and build outputs were intentionally not included in the commit.
