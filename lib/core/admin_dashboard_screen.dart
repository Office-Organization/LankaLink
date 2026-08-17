import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// An admin-only browser for the Firestore collections used by LankaLink.
/// Each record opens on its own page so large survey documents remain readable.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _pageSize = 10;
  static const _collections = ['survey_responses', 'users', 'voters_2024'];

  String _collection = 'survey_responses';
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _documents = [];
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageStarts = [];
  bool _isLoading = true;
  bool _hasNextPage = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(_collection)
          .orderBy(FieldPath.documentId)
          .limit(_pageSize + 1);
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      final snapshot = await query.get();
      if (!mounted) return;
      setState(() {
        _hasNextPage = snapshot.docs.length > _pageSize;
        _documents = snapshot.docs.take(_pageSize).toList();
      });
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeCollection(String collection) {
    if (collection == _collection) return;
    setState(() {
      _collection = collection;
      _pageStarts.clear();
    });
    _loadPage();
  }

  Future<void> _nextPage() async {
    if (!_hasNextPage || _documents.isEmpty) return;
    final start = _documents.last;
    _pageStarts.add(start);
    await _loadPage(startAfter: start);
  }

  Future<void> _previousPage() async {
    if (_pageStarts.isEmpty) return;
    _pageStarts.removeLast();
    await _loadPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
  }

  String _recordTitle(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    for (final field in ['houseNumber', 'fullName', 'name', 'nic', 'email']) {
      final value = data[field];
      if (value != null && value.toString().trim().isNotEmpty) return '$value';
    }
    return document.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Data Manager'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadPage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: DropdownButtonFormField<String>(
              value: _collection,
              decoration: const InputDecoration(
                labelText: 'Firestore collection',
                prefixIcon: Icon(Icons.storage_outlined),
              ),
              items: _collections
                  .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (name) {
                      if (name != null) _changeCollection(name);
                    },
            ),
          ),
          Expanded(child: _buildContent()),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Unable to load $_collection', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadPage, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_documents.isEmpty) return Center(child: Text('No records in $_collection.'));
    return RefreshIndicator(
      onRefresh: _loadPage,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _documents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final document = _documents[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(_recordTitle(document)),
              subtitle: Text(
                'Document ID: ${document.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminDocumentScreen(
                      collection: _collection,
                      documentId: document.id,
                    ),
                  ),
                );
                if (mounted) {
                  _loadPage(
                    startAfter: _pageStarts.isEmpty ? null : _pageStarts.last,
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _isLoading || _pageStarts.isEmpty ? null : _previousPage,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Expanded(
            child: Text(
              'Page ${_pageStarts.length + 1}',
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton.icon(
            onPressed: _isLoading || !_hasNextPage ? null : _nextPage,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    ),
  );
}

class AdminDocumentScreen extends StatefulWidget {
  const AdminDocumentScreen({
    required this.collection,
    required this.documentId,
    super.key,
  });

  final String collection;
  final String documentId;

  @override
  State<AdminDocumentScreen> createState() => _AdminDocumentScreenState();
}

class _AdminDocumentScreenState extends State<AdminDocumentScreen> {
  late final DocumentReference<Map<String, dynamic>> _reference;
  Map<String, dynamic>? _draft;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reference = FirebaseFirestore.instance
        .collection(widget.collection)
        .doc(widget.documentId);
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await _reference.get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('This document no longer exists.');
      }
      if (mounted) setState(() => _draft = _copyMap(snapshot.data()!));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() => _isSaving = true);
    try {
      await _reference.set(_draft!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to save record.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This permanently removes the Firestore document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSaving = true);
    try {
      await _reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to delete record.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit Record'),
      actions: [
        IconButton(
          tooltip: 'Delete record',
          onPressed: _isSaving || _isLoading ? null : _delete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
    body: _buildBody(),
    bottomNavigationBar: _draft == null
        ? null
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save changes'),
              ),
            ),
          ),
  );

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final draft = _draft!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text('Collection: ${widget.collection}'),
        const SizedBox(height: 4),
        SelectableText('Document ID: ${widget.documentId}'),
        const SizedBox(height: 16),
        ...draft.entries.map(
          (entry) => _ValueEditor(
            label: entry.key,
            value: entry.value,
            onChanged: (value) => draft[entry.key] = value,
          ),
        ),
      ],
    );
  }
}

class _ValueEditor extends StatelessWidget {
  const _ValueEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value as Map);
      return Card(
        child: ExpansionTile(
          title: Text(label),
          children: map.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ValueEditor(
                    label: entry.key,
                    value: entry.value,
                    onChanged: (newValue) {
                      map[entry.key] = newValue;
                      onChanged(map);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    if (value is List) {
      final list = List<dynamic>.from(value as List);
      return Card(
        child: ExpansionTile(
          title: Text('$label (${list.length})'),
          children: List.generate(
            list.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _ValueEditor(
                label: '#${index + 1}',
                value: list[index],
                onChanged: (newValue) {
                  list[index] = newValue;
                  onChanged(list);
                },
              ),
            ),
          ),
        ),
      );
    }
    if (value is bool) {
      return SwitchListTile(title: Text(label), value: value as bool, onChanged: onChanged);
    }
    if (value is Timestamp) {
      return _textField(
        initialValue: (value as Timestamp).toDate().toIso8601String(),
        helper: 'Date/time (ISO 8601)',
        onChanged: (text) {
          final date = DateTime.tryParse(text);
          if (date != null) onChanged(Timestamp.fromDate(date));
        },
      );
    }
    if (value is DocumentReference || value is GeoPoint) {
      return ListTile(title: Text(label), subtitle: SelectableText('$value'));
    }
    return _textField(
      initialValue: value?.toString() ?? '',
      helper: value == null ? 'Empty value saves as null' : null,
      onChanged: (text) => onChanged(_parseValue(text, value)),
    );
  }

  Widget _textField({
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: initialValue.length > 60 ? 4 : 1,
      decoration: InputDecoration(labelText: label, helperText: helper),
      onChanged: onChanged,
    ),
  );

  dynamic _parseValue(String text, dynamic originalValue) {
    if (text.isEmpty && originalValue == null) return null;
    if (originalValue is int) return int.tryParse(text) ?? originalValue;
    if (originalValue is double) return double.tryParse(text) ?? originalValue;
    return text;
  }
}

Map<String, dynamic> _copyMap(Map<String, dynamic> source) =>
    source.map((key, value) => MapEntry(key, _copyValue(value)));

dynamic _copyValue(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), _copyValue(item)));
  }
  if (value is List) return value.map(_copyValue).toList();
  return value;
}
