import 'package:flutter/material.dart';

import '../../../appointment/domain/entities/appointment_entities.dart';

class DepartmentVisual {
  const DepartmentVisual({
    required this.label,
    required this.icon,
    required this.colors,
    required this.softColor,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color softColor;
}

DepartmentVisual departmentVisualFor(DepartmentEntity department) {
  return departmentVisualFromParts(
    id: department.id,
    name: department.name,
    fallbackLabel: department.name,
  );
}

DepartmentVisual departmentVisualFromParts({
  required String id,
  required String name,
  String? fallbackLabel,
}) {
  final source = _fold('$id $name');
  final known = _knownVisual(source, fallbackLabel ?? name);
  if (known != null) return known;

  final index =
      _stableHash(source.isEmpty ? (fallbackLabel ?? name) : source) %
      _generatedVisuals.length;
  final visual = _generatedVisuals[index];
  return DepartmentVisual(
    label: _cleanLabel(fallbackLabel ?? name),
    icon: visual.icon,
    colors: visual.colors,
    softColor: visual.softColor,
  );
}

DepartmentVisual? _knownVisual(String source, String label) {
  if (source.contains('tim') || source.contains('cardio')) {
    return _visual(
      label,
      Icons.favorite_rounded,
      0xFFEC5D5D,
      0xFFB91C1C,
      0xFFFFE8E8,
    );
  }
  if (source.contains('nhi') || source.contains('pedia')) {
    return _visual(
      label,
      Icons.child_care_rounded,
      0xFF60A5FA,
      0xFF2563EB,
      0xFFEAF3FF,
    );
  }
  if (source.contains('san') ||
      source.contains('phu') ||
      source.contains('obgyn') ||
      source.contains('thai')) {
    return _visual(
      label,
      Icons.pregnant_woman_rounded,
      0xFFF472B6,
      0xFFBE185D,
      0xFFFCE7F3,
    );
  }
  if (source.contains('mat') ||
      source.contains('nhan') ||
      source.contains('eye')) {
    return _visual(
      label,
      Icons.visibility_rounded,
      0xFF818CF8,
      0xFF4F46E5,
      0xFFEDEBFF,
    );
  }
  if (source.contains('da') ||
      source.contains('lieu') ||
      source.contains('derma')) {
    return _visual(
      label,
      Icons.spa_rounded,
      0xFF34D399,
      0xFF059669,
      0xFFE8FFF5,
    );
  }
  if (source.contains('tai') ||
      source.contains('mui') ||
      source.contains('hong') ||
      source.contains('ent')) {
    return _visual(
      label,
      Icons.hearing_rounded,
      0xFF2DD4BF,
      0xFF0F766E,
      0xFFE5FFFA,
    );
  }
  if (source.contains('rang') ||
      source.contains('ham') ||
      source.contains('dental')) {
    return _visual(
      label,
      Icons.medical_services_rounded,
      0xFF38BDF8,
      0xFF0369A1,
      0xFFE0F7FF,
    );
  }
  if (source.contains('xet') ||
      source.contains('nghiem') ||
      source.contains('lab')) {
    return _visual(
      label,
      Icons.biotech_rounded,
      0xFF2DD4BF,
      0xFF0F766E,
      0xFFE5FFFA,
    );
  }
  if (source.contains('noi') || source.contains('internal')) {
    return _visual(
      label,
      Icons.local_hospital_rounded,
      0xFF6366F1,
      0xFF3730A3,
      0xFFEDEBFF,
    );
  }
  if (source.contains('ngoai') || source.contains('surgery')) {
    return _visual(
      label,
      Icons.medical_information_rounded,
      0xFFF97316,
      0xFFC2410C,
      0xFFFFF0E6,
    );
  }
  return null;
}

DepartmentVisual _visual(
  String label,
  IconData icon,
  int start,
  int end,
  int soft,
) {
  return DepartmentVisual(
    label: _cleanLabel(label),
    icon: icon,
    colors: [Color(start), Color(end)],
    softColor: Color(soft),
  );
}

final List<DepartmentVisual> _generatedVisuals = [
  _visual('', Icons.local_hospital_rounded, 0xFF2563EB, 0xFF1E40AF, 0xFFEAF3FF),
  _visual(
    '',
    Icons.health_and_safety_rounded,
    0xFF14B8A6,
    0xFF0F766E,
    0xFFE5FFFA,
  ),
  _visual('', Icons.monitor_heart_rounded, 0xFFEF4444, 0xFFB91C1C, 0xFFFFE8E8),
  _visual('', Icons.psychology_rounded, 0xFF8B5CF6, 0xFF6D28D9, 0xFFF1EAFF),
  _visual('', Icons.healing_rounded, 0xFF22C55E, 0xFF15803D, 0xFFE8FFF0),
  _visual('', Icons.medication_rounded, 0xFFF59E0B, 0xFFD97706, 0xFFFFF4DB),
  _visual('', Icons.emergency_rounded, 0xFF06B6D4, 0xFF0E7490, 0xFFE0FAFF),
  _visual('', Icons.science_rounded, 0xFF64748B, 0xFF334155, 0xFFF1F5F9),
];

String _cleanLabel(String label) {
  final value = label.replaceFirst(
    RegExp(r'^Khoa\s+', caseSensitive: false),
    '',
  );
  return value.trim().isEmpty ? 'Chuyen khoa' : value.trim();
}

String _fold(String value) {
  const from =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  const to =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
  var result = value.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    result = result.replaceAll(from[i], to[i].toLowerCase());
  }
  return result;
}

int _stableHash(String value) {
  var hash = 0;
  for (final unit in value.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}
