import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Admin dashboard for viewing and managing Firestore records.
/// We load documents in chunks (pagination) so large collections don't freeze the app.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Let's grab 10 items at a time to keep things snappy and save on database reads.
  static const _pageSize = 10;
  
  // Mapping the raw database collection IDs to friendly display names for the dropdown.
  final Map<String, String> _collectionMap = {
    'survey_responses': 'collected data',
    'users': 'our members',
    'voters_2024': 'members in our system',
  };

  // Default to the survey responses collection on startup
  String _currentCollectionId = 'survey_responses';
  
  // Search related variables
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _searchField = 'documentId'; // Default to searching by ID
  
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _documents = [];
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageStarts = [];
  
  bool _isLoading = true;
  bool _hasNextPage = false;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Kick off the initial data fetch when the screen opens
    _loadPage();
    
    // Listen to search text changes to show/hide the clear button
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns the specific fields you can search by, depending on which collection is currently selected.
  List<String> _getSearchFields() {
    switch (_currentCollectionId) {
      case 'survey_responses':
        return ['documentId', 'houseNumber', 'nic', 'fullName'];
      case 'users':
        return ['documentId', 'name', 'email', 'nic'];
      case 'voters_2024':
        return ['documentId', 'name', 'nic', 'houseNumber'];
      default:
        return ['documentId'];
    }
  }

  /// Fetches a page of data from Firestore. 
  /// If [startAfter] is provided, it fetches the next batch starting after that document.
  Future<void> _loadPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(_currentCollectionId);

      // Apply the search filter if the user has typed something
      if (_searchQuery.isNotEmpty) {
        if (_searchField == 'documentId') {
          // Firestore trick for searching string prefixes
          query = query
              .where(FieldPath.documentId, isGreaterThanOrEqualTo: _searchQuery)
              .where(FieldPath.documentId, isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        } else {
          query = query
              .where(_searchField, isGreaterThanOrEqualTo: _searchQuery)
              .where(_searchField, isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        }
      } else {
        // Only apply default ordering if we aren't searching 
        // (to avoid Firestore index requirements on every field)
        query = query.orderBy(FieldPath.documentId);
      }
          
      query = query.limit(_pageSize + 1);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      final snapshot = await query.get();
      if (!mounted) return;
      
      setState(() {
        // If we got more than our page size, we know there's another page
        _hasNextPage = snapshot.docs.length > _pageSize;
        // Keep only the requested amount (drop that extra item we used for checking)
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

  /// Triggers when the user presses the search button or hits enter on the keyboard
  void _executeSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _pageStarts.clear(); // Reset pagination because we are loading new search results
    });
    _loadPage();
  }

  /// Switches the active collection when the user picks a new option from the dropdown
  void _changeCollection(String newCollectionId) {
    if (newCollectionId == _currentCollectionId) return; // Already on this collection
    
    setState(() {
      _currentCollectionId = newCollectionId;
      _pageStarts.clear(); // Reset pagination history
      
      // Reset search bar state for the new collection
      _searchController.clear();
      _searchQuery = '';
      _searchField = 'documentId'; 
    });
    _loadPage();
  }

  /// Moves to the next page of records
  Future<void> _nextPage() async {
    if (!_hasNextPage || _documents.isEmpty) return;
    
    // Remember where this page started so we can go backward later
    final start = _documents.last;
    _pageStarts.add(start);
    await _loadPage(startAfter: start);
  }

  /// Moves back to the previous page of records
  Future<void> _previousPage() async {
    if (_pageStarts.isEmpty) return;
    
    _pageStarts.removeLast(); // Toss out the current page marker
    await _loadPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
  }

  /// Tries to find a human-readable name/title inside the document.
  String _recordTitle(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final possibleNameFields = ['houseNumber', 'fullName', 'name', 'nic', 'email'];
    
    for (final field in possibleNameFields) {
      final value = data[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return '$value';
      }
    }
    return document.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Clean, light grey background
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The blue profile header section at the top
          _buildHeader(),

          // The dropdown selector for picking which database table to view
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentCollectionId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2C3E50)),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _collectionMap.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (newId) {
                          if (newId != null) _changeCollection(newId);
                        },
                ),
              ),
            ),
          ),

          // Sub-header with a refresh button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Database Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _loadPage,
                  icon: const Icon(Icons.refresh, color: Color(0xFF2187EA)),
                ),
              ],
            ),
          ),

          // --- NEW SEARCH BAR COMPONENT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // Field selector dropdown (e.g., search by ID, search by Name)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _searchField,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2187EA), size: 20),
                        style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 13),
                        items: _getSearchFields().map((field) {
                          // Clean up the text for the user interface
                          String displayName = field == 'documentId' ? 'ID' : field.toUpperCase();
                          return DropdownMenuItem(value: field, child: Text(displayName));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _searchField = val);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search ${_collectionMap[_currentCollectionId]}...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onSubmitted: (_) => _executeSearch(),
                    ),
                  ),
                  
                  // Clear button
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _executeSearch(); // Refresh list to show everything again
                      },
                    ),
                    
                  // Search Submit Button
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF2187EA)),
                    onPressed: _executeSearch,
                  ),
                ],
              ),
            ),
          ),

          // The main scrollable grid showing the actual data cards
          Expanded(child: _buildContent()),

          // Pagination controls at the bottom
          _buildPagination(),
        ],
      ),

      // Standard bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF2187EA),
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF2187EA),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Vihanga Manodhya',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'System Administrator',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2187EA)));
    }
    
    // Show an error card if the Firestore query failed
    if (_error != null) {
      final friendlyName = _collectionMap[_currentCollectionId] ?? _currentCollectionId;
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, spreadRadius: 2)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Unable to load "$friendlyName"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3F2FD),
                    foregroundColor: const Color(0xFF2187EA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _loadPage,
                  child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    
    // Handle the scenario where the collection is empty (or search yielded no results)
    if (_documents.isEmpty) {
      return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('No records found.',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ));
    }

    // Success! Show the grid of data.
    return RefreshIndicator(
      onRefresh: _loadPage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85, 
            ),
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              return _buildDocumentCard(_documents[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            // Open the editor screen for this specific document
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminDocumentScreen(
                  collection: _currentCollectionId,
                  documentId: document.id,
                ),
              ),
            );
            if (mounted) {
              _loadPage(startAfter: _pageStarts.isEmpty ? null : _pageStarts.last);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insert_drive_file_outlined, size: 38, color: Color(0xFF2187EA)),
                const SizedBox(height: 12),
                Text(
                  _recordTitle(document),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  document.id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Color(0xFF2187EA),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _isLoading || _pageStarts.isEmpty ? null : _previousPage,
                icon: const Icon(Icons.chevron_left, color: Color(0xFF2C3E50)),
                disabledColor: Colors.grey.shade300,
              ),
              Expanded(
                child: Text(
                  'Page ${_pageStarts.length + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isLoading || !_hasNextPage ? null : _nextPage,
                icon: const Icon(Icons.chevron_right, color: Color(0xFF2C3E50)),
                disabledColor: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      );
}

// -----------------------------------------------------------------------------
// Admin Document Screen (No changes needed here, keeping it intact)
// -----------------------------------------------------------------------------

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
    _reference = FirebaseFirestore.instance.collection(widget.collection).doc(widget.documentId);
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
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2187EA),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Edit Record', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2187EA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                  ),
                ),
              ),
      );

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2187EA)));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF2C3E50))),
        ),
      );
    }
    
    final draft = _draft!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Text('Collection: ${widget.collection}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SelectableText('Document ID: ${widget.documentId}', style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 16)),
        const SizedBox(height: 24),
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: ExpansionTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: ExpansionTile(
          title: Text('$label (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      return SwitchListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: value as bool,
        activeColor: const Color(0xFF2187EA),
        onChanged: onChanged,
      );
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
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: initialValue.length > 60 ? 4 : 1,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2187EA)),
        ),
      ),
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