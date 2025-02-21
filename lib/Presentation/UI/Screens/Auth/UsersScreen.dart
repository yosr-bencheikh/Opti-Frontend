import 'package:flutter/material.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserController _controller = UserController(UserDataSource());
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await _controller.fetchUsers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(child: Text(_controller.error!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Prenom')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Region')),
                  DataColumn(label: Text('Genre')),
                  DataColumn(label: Text('imageUrl')),
                  DataColumn(label: Text('Action')),
                
                ],
                rows: _controller.users.map((user) {
                  return DataRow(cells: [
                    DataCell(Text(user.nom)),
                    DataCell(Text(user.prenom)),
                    DataCell(Text(user.email)),
                    DataCell(Text(user.date)),
                    DataCell(Text(user.phone)),
                    DataCell(Text(user.region)),
                    DataCell(Text(user.genre)),
                    DataCell(Text(user.imageUrl)),
                    
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteDialog(user),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(User user) async {
    final TextEditingController nomController = TextEditingController(text: user.nom);
    final TextEditingController emailController = TextEditingController(text: user.email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              user.nom = nomController.text;
              user.email = emailController.text;
              await _controller.updateUser(user);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(User user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.nom}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _controller.deleteUser(user.email);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}