// lib/screens/settings/department_list_page.dart
import 'package:flutter/material.dart';
import '../../models/department_model.dart';
import '../../services/api_service.dart';

class DepartmentListPage extends StatefulWidget {
  final int companyId;
  const DepartmentListPage({super.key, required this.companyId});

  @override
  State<DepartmentListPage> createState() => _DepartmentListPageState();
}

class _DepartmentListPageState extends State<DepartmentListPage> {
  late Future<List<Department>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchDepartmentsByCompany(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department List'), backgroundColor: Colors.blueGrey),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search Department',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Department>>(
              future: _future,
              builder: (_, s) {
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.hasError) return Center(child: Text('❌ ${s.error}'));
                final items = (s.data ?? []).where((d) =>
                d.name.toLowerCase().contains(_q) ||
                    (d.code ?? '').toLowerCase().contains(_q)
                ).toList();
                if (items.isEmpty) return const Center(child: Text('No departments found.'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = items[i];
                    return ListTile(
                      leading: const Icon(Icons.apartment, color: Colors.blue),
                      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: (d.code?.isNotEmpty ?? false) || (d.description?.isNotEmpty ?? false)
                          ? Text([d.code, d.description].whereType<String>().where((e) => e.isNotEmpty).join(' • '))
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
