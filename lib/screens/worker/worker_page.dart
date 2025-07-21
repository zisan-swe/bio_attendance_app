import 'package:flutter/material.dart';
import 'worker_create_page.dart';

class WorkerPage extends StatefulWidget {
  @override
  _WorkerPageState createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  List<Map<String, String>> workers = [
    {'name': 'John Doe', 'worker_code': 'W001'},
    {'name': 'Jane Smith', 'worker_code': 'W002'},
  ];

  void _addWorker(Map<String, String> newWorker) {
    setState(() {
      workers.add(newWorker);
    });
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkerCreatePage()),
    );

    if (result != null && result is Map<String, String>) {
      _addWorker(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workers'),
      ),
      body: workers.isEmpty
          ? Center(child: Text('No workers added yet.'))
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text(worker['name'] ?? ''),
              subtitle: Text('Code: ${worker['worker_code']}'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: Icon(Icons.add),
        tooltip: 'Create Worker',
      ),
    );
  }
}
