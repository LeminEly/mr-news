import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String appSupabaseUrl = _Env.appSupabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String appSupabaseAnonKey = _Env.appSupabaseAnonKey;
}

