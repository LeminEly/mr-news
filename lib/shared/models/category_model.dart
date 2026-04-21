import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required String id,
    required String nameAr,
    required String nameFr,
    required String icon,
    required String colorHex,
    required int displayOrder,
    required bool isActive,
    required DateTime createdAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}

extension CategoryModelX on CategoryModel {
  String name(String locale) => locale == 'ar' ? nameAr : nameFr;
}
