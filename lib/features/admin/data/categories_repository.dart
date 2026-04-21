import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesRepository(),
);

class CategoriesRepositoryException implements Exception {
  const CategoriesRepositoryException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() =>
      'CategoriesRepositoryException(code: $code, message: $message)';
}

class CategoriesRepository {
  CategoriesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getCategories({
    bool includeInactive = true,
  }) async {
    try {
      final rows = includeInactive
          ? await _client.from('categories').select().order('display_order')
          : await _client
              .from('categories')
              .select()
              .eq('is_active', true)
              .order('display_order');
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> createCategory({
    required String nameAr,
    required String nameFr,
    required String icon,
    required String colorHex,
    int displayOrder = 0,
    bool isActive = true,
  }) async {
    try {
      return await _client
          .from('categories')
          .insert({
            'name_ar': nameAr.trim(),
            'name_fr': nameFr.trim(),
            'icon': icon.trim(),
            'color_hex': colorHex.trim(),
            'display_order': displayOrder,
            'is_active': isActive,
          })
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    String? nameAr,
    String? nameFr,
    String? icon,
    String? colorHex,
    int? displayOrder,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nameAr != null) updates['name_ar'] = nameAr.trim();
      if (nameFr != null) updates['name_fr'] = nameFr.trim();
      if (icon != null) updates['icon'] = icon.trim();
      if (colorHex != null) updates['color_hex'] = colorHex.trim();
      if (displayOrder != null) updates['display_order'] = displayOrder;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) {
        return await _client
            .from('categories')
            .select()
            .eq('id', categoryId)
            .single();
      }

      return await _client
          .from('categories')
          .update(updates)
          .eq('id', categoryId)
          .select()
          .single();
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _client.from('categories').delete().eq('id', categoryId);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    }
  }

  CategoriesRepositoryException _mapPostgrestError(PostgrestException error) {
    if (error.code == 'PGRST116') {
      return const CategoriesRepositoryException(
        code: 'NOT_FOUND',
        message: 'Categorie introuvable.',
      );
    }

    return CategoriesRepositoryException(
      code: error.code ?? 'DATABASE_ERROR',
      message: error.message,
      details: error,
    );
  }
}
