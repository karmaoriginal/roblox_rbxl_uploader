// lib/viewer/rbxl_viewport.dart
//
// Viewport 3D editable, MVP para el editor tipo "Studio Lite".
// Muestra Parts (bloques) como cubos, permite orbitar la cámara con el dedo,
// seleccionar una Part y moverla con botones (sin gizmo de arrastre todavía).
//
// Ya integrado en este proyecto: dependencias en pubspec.yaml, Flutter GPU
// activado en AndroidManifest.xml, y accesible desde el botón "Abrir editor
// 3D (beta)" en la pantalla principal (ver lib/viewer/editor_screen.dart).
// Requiere Flutter 3.47+.
//
// NOTA sobre color: PhysicallyBasedMaterial.baseColorFactor asume la
// convención glTF (vm.Vector4 con r,g,b,a en 0..1). flutter_scene está en
// pre-1.0 y puede cambiar de versión a versión — si el autocompletado de tu
// IDE no encuentra `baseColorFactor` en tu versión instalada, buscá el
// nombre correcto ahí (probablemente algo muy similar) y ajustá esa línea.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Modelo mínimo de una Part de Roblox (tipo Block).
class RbxPart {
  RbxPart({
    required this.id,
    required this.name,
    required this.position,
    required this.size,
    required this.color,
  });

  final String id;
  final String name;
  vm.Vector3 position;
  final vm.Vector3 size;
  final Color color;
}

class RbxlViewport extends StatefulWidget {
  const RbxlViewport({super.key, required this.parts});

  final List<RbxPart> parts;

  @override
  State<RbxlViewport> createState() => _RbxlViewportState();
}

class _RbxlViewportState extends State<RbxlViewport> {
  final Scene _scene = Scene();
  final Map<String, Node> _nodes = {};
  bool _ready = false;
  String? _selectedId;

  // Cámara orbital (coordenadas esféricas alrededor de _target).
  double _yaw = -0.9;
  double _pitch = 0.5;
  double _distance = 24;
  final vm.Vector3 _target = vm.Vector3(0, 2, 0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Scene.initializeStaticResources();
    for (final part in widget.parts) {
      _addPartNode(part);
    }
    if (mounted) setState(() => _ready = true);
  }

  void _addPartNode(RbxPart part) {
    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(
        part.color.red / 255,
        part.color.green / 255,
        part.color.blue / 255,
        1,
      );
    final node = Node(mesh: Mesh(CuboidGeometry(part.size), material))
      ..position = part.position;
    _scene.add(node);
    _nodes[part.id] = node;
  }

  RbxPart? get _selectedPart {
    if (_selectedId == null) return null;
    for (final p in widget.parts) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  void _moveSelected(vm.Vector3 delta) {
    final part = _selectedPart;
    if (part == null) return;
    setState(() {
      part.position = part.position + delta;
      _nodes[part.id]?.position = part.position;
    });
  }

  vm.Vector3 get _cameraPosition {
    final x = _target.x + _distance * math.cos(_pitch) * math.sin(_yaw);
    final y = _target.y + _distance * math.sin(_pitch);
    final z = _target.z + _distance * math.cos(_pitch) * math.cos(_yaw);
    return vm.Vector3(x, y, z);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // Un dedo: orbita (rota la cámara). Pellizcar: zoom.
            onScaleUpdate: (details) {
              setState(() {
                _yaw -= details.focalPointDelta.dx * 0.01;
                _pitch = (_pitch + details.focalPointDelta.dy * 0.01)
                    .clamp(-1.4, 1.4);
                _distance = (_distance / details.scale).clamp(4, 80);
              });
            },
            child: SceneView(
              _scene,
              camera: PerspectiveCamera(
                position: _cameraPosition,
                target: _target,
              ),
            ),
          ),
        ),
        _buildSelector(),
        if (_selectedPart != null) _buildTransformControls(),
      ],
    );
  }

  Widget _buildSelector() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: widget.parts.map((part) {
          final selected = part.id == _selectedId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(part.name),
              selected: selected,
              onSelected: (_) => setState(() => _selectedId = part.id),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransformControls() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          _axisButtons('X', vm.Vector3(1, 0, 0)),
          _axisButtons('Y', vm.Vector3(0, 1, 0)),
          _axisButtons('Z', vm.Vector3(0, 0, 1)),
        ],
      ),
    );
  }

  Widget _axisButtons(String label, vm.Vector3 axis) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _moveSelected(axis * -0.5),
        ),
        Text(label),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _moveSelected(axis * 0.5),
        ),
      ],
    );
  }
}

/// Ejemplo de datos iniciales, tipo un place nuevo de Roblox
/// (un Baseplate grande + una Part chica encima). Usalo para probar:
///   RbxlViewport(parts: demoParts)
final List<RbxPart> demoParts = [
  RbxPart(
    id: 'baseplate',
    name: 'Baseplate',
    position: vm.Vector3(0, 0, 0),
    size: vm.Vector3(20, 1, 20),
    color: const Color(0xFF3A7D3A),
  ),
  RbxPart(
    id: 'part1',
    name: 'Part',
    position: vm.Vector3(0, 2, 0),
    size: vm.Vector3(2, 2, 2),
    color: const Color(0xFFB0AFA8),
  ),
];
