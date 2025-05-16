# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-dontwarn io.supabase.**
-dontwarn com.supabase.**

# Firebase (추가 필요시)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**

# 모든 직렬화 모델 클래스 (예: DTO, 모델 클래스)
-keep class com.pingpong.gnu.app.models.** { *; }
-keep class com.pingpong.gnu.app.dto.** { *; }

# Play 라이브러리 관련 규칙 (분할된 모듈용)
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-dontwarn com.google.android.play.core.**
