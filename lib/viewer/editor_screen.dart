import 'package:flutter/material.dart';
import 'rbxl_viewport.dart';

/// Pantalla del editor 3D. Por ahora arranca con demoParts (Baseplate +
/// una Part); cuando esté el parser .rbxlx, esto va a recibir las Parts
/// reales del place cargado en vez de demoParts.
class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor 3D (beta)'),
      ),
      body: RbxlViewport(parts: demoParts),
    );
  }
}
