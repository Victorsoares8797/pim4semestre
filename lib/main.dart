import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/data/http_repository.dart';
import 'src/domain/repository.dart';

void main() {
  const apiUrl = String.fromEnvironment(
    'BUILLON_API_URL',
    defaultValue: 'http://localhost:5080',
  );
  runApp(
    MyApp(
      repository: apiUrl.isEmpty
          ? null
          : HttpBuillonRepository(Uri.parse(apiUrl)),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});
  final BuillonRepository? repository;

  @override
  Widget build(BuildContext context) => BuillonApp(repository: repository);
}
