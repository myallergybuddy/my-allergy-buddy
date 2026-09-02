/// Shared Tree Nuts parent/child grouping for save, display, and scan matching.
///
/// Full group: only "Tree Nuts" is stored (all children implied).
/// Subset: "Tree Nuts" is stored plus each child that remains selected.
class TreeNutsGrouping {
  static const String parentName = 'Tree Nuts';

  static const List<String> children = [
    'Almond',
    'Cashew',
    'Hazelnut',
    'Pecan',
    'Walnut',
    'Brazil Nut',
    'Pistachio',
    'Macadamia',
    'Pine Nut',
    'Chestnut',
  ];

  static final Set<String> _childLookup = {
    for (final name in children) name.toLowerCase(),
  };

  static bool isParentName(String? name) {
    final lower = name?.toLowerCase().trim() ?? '';
    return lower == 'tree nuts' || lower == 'tree nut';
  }

  static bool isChildName(String? name) {
    return _childLookup.contains(name?.toLowerCase().trim() ?? '');
  }

  static List<String> namesOf(List<Map<String, dynamic>> allergies) {
    return allergies
        .map((allergy) => allergy['name']?.toString() ?? '')
        .toList();
  }

  static bool hasParent(Iterable<String> names) => names.any(isParentName);

  static bool hasStoredChildren(Iterable<String> names) =>
      names.any(isChildName);

  /// Parent is saved together with at least one specific nut.
  static bool isSubset(Iterable<String> names) =>
      hasParent(names) && hasStoredChildren(names);

  /// Profile and My Allergies: Tree Nuts plus remaining selected children.
  /// Deselected nuts are not in [allergies], so they stay hidden.
  static List<Map<String, dynamic>> forProfile(
    List<Map<String, dynamic>> allergies,
  ) {
    return forMyAllergies(allergies);
  }

  /// Show Tree Nuts plus remaining selected children (saved subset).
  static List<Map<String, dynamic>> forMyAllergies(
    List<Map<String, dynamic>> allergies,
  ) {
    final parent = <Map<String, dynamic>>[];
    final kids = <Map<String, dynamic>>[];
    final others = <Map<String, dynamic>>[];

    for (final allergy in allergies) {
      final name = allergy['name']?.toString() ?? '';
      if (isParentName(name)) {
        parent.add(allergy);
      } else if (isChildName(name)) {
        kids.add(allergy);
      } else {
        others.add(allergy);
      }
    }

    kids.sort((a, b) {
      final aIndex = _childIndex(a['name']?.toString() ?? '');
      final bIndex = _childIndex(b['name']?.toString() ?? '');
      return aIndex.compareTo(bIndex);
    });

    return [...parent, ...kids, ...others];
  }

  /// Persist parent + remaining children. Collapse to parent-only when every
  /// known tree nut is selected.
  static Map<String, String> normalizeSelection(Map<String, String> selected) {
    final result = Map<String, String>.from(selected);
    if (!result.containsKey(parentName)) {
      return result;
    }

    final storedChildren = children.where(result.containsKey).toList();
    if (storedChildren.length == children.length) {
      for (final child in children) {
        result.remove(child);
      }
    }
    return result;
  }

  static int _childIndex(String name) {
    final lower = name.toLowerCase();
    return children.indexWhere((child) => child.toLowerCase() == lower);
  }
}
