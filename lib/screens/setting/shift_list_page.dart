import 'package:flutter/material.dart';
import '../../models/shift_model.dart';
import '../../services/api_service.dart';

class ShiftListPage extends StatefulWidget {
  final int companyId;
  const ShiftListPage({super.key, required this.companyId});

  @override
  State<ShiftListPage> createState() => _ShiftListPageState();
}

class _ShiftListPageState extends State<ShiftListPage> {
  late Future<List<Shift>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchShiftsByCompany(widget.companyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift List'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search shift by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Shift>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('❌ Error: ${snapshot.error}'));
                }

                final shifts = (snapshot.data ?? [])
                    .where((s) =>
                s.name.toLowerCase().contains(_query) ||
                    (s.description ?? '').toLowerCase().contains(_query))
                    .toList();

                if (shifts.isEmpty) {
                  return const Center(child: Text('No shifts found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final shift = shifts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled,
                            color: Colors.blueGrey),
                        title: Text(
                          shift.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (shift.startTime != null &&
                                shift.endTime != null)
                              Text(
                                  'Time: ${shift.startTime} - ${shift.endTime}'),
                            if (shift.description != null &&
                                shift.description!.isNotEmpty)
                              Text(shift.description!),
                          ],
                        ),
                      ),
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
