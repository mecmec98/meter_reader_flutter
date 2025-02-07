import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  String iconPath;
  Color boxColor;

  CategoryModel({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];

    categories.add(
      CategoryModel(
        name: 'Test',
        iconPath: 'assets/icons/menu.svg',
        boxColor: Color.fromARGB(255, 215, 98, 192),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Test2',
        iconPath: 'assets/icons/person.svg',
        boxColor: Color.fromARGB(255, 98, 160, 215),
      ),
    );

    categories.add(
      CategoryModel(
        name: 'Tes3t',
        iconPath: 'assets/icons/search.svg',
        boxColor: Color.fromARGB(255, 98, 215, 123),
      ),
    );

    return categories;
  }
}
