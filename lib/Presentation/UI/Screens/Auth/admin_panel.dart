import 'package:flutter/material.dart';

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<Widget> _screens = [
    DashboardScreen(),
    UsersScreen(),
    ProductsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (MediaQuery.of(context).size.width < 1100) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 1100;

    return Scaffold(
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: Color(0xFF1E88E5),
              title: Text('Admin Panel'),
              leading: IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    _isDrawerOpen = !_isDrawerOpen;
                  });
                },
              ),
            )
          : null,
      drawer: isSmallScreen
          ? NavigationDrawer(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen)
            NavigationDrawer(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
            ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildStatsGrid(),
          SizedBox(height: 30),
          Text(
            'Recent Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _buildDataTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Container(
              width: 250,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1E88E5)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                ),
              ),
            ),
            SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.notifications, color: Color(0xFF1E88E5)),
              onPressed: () {},
            ),
            SizedBox(width: 10),
            Builder(
              builder: (context) => GestureDetector(
                onTapDown: (TapDownDetails details) async {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final Offset position = renderBox.localToGlobal(Offset.zero);

                  String? selectedValue = await showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      position.dx,
                      position.dy +
                          renderBox.size.height, // Position below the avatar
                      position.dx + renderBox.size.width,
                      position.dy + renderBox.size.height + 50,
                    ),
                    items: [
                      PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Log Out'),
                        ),
                      ),
                    ],
                  );

                  // Ensure the menu was not dismissed without selection
                  if (selectedValue != null) {
                    if (selectedValue == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsScreen()),
                      );
                    } else if (selectedValue == 'logout') {
                      // Handle logout logic here
                    }
                  }
                },
                child: CircleAvatar(
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150'),
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final stats = [
              {'title': 'Total Users', 'value': '2,345', 'color': Colors.blue},
              {'title': 'Revenue', 'value': '\$34,543', 'color': Colors.green},
              {'title': 'Orders', 'value': '1,234', 'color': Colors.orange},
              {'title': 'Products', 'value': '567', 'color': Colors.purple},
            ][index];
            return Card(
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stats['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.trending_up, color: Colors.white),
                    ),
                    SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stats['title'] as String,
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          stats['value'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 3,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: DataTable(
            columns: [
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Action')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Status')),
            ],
            rows: List.generate(5, (index) {
              return DataRow(cells: [
                DataCell(Text('User ${index + 1}')),
                DataCell(Text('Performed action ${index + 1}')),
                DataCell(Text('2024-02-${10 + index}')),
                DataCell(
                  Chip(
                    label: Text('Completed'),
                    backgroundColor: Colors.green[100],
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const NavigationDrawer({super.key, 
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Color(0xFF1E88E5),
      child: Column(
        children: [
          SizedBox(height: 40),
          Text(
            'Admin Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          ...['Dashboard', 'Users', 'Products', 'Settings'].asMap().entries.map(
            (entry) {
              final index = entry.key;
              final title = entry.value;
              return ListTile(
                leading: Icon(
                  _getIcon(index),
                  color: selectedIndex == index ? Colors.white : Colors.white70,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color:
                        selectedIndex == index ? Colors.white : Colors.white70,
                    fontWeight: selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () => onItemSelected(index),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.people;
      case 2:
        return Icons.shopping_bag;
      case 3:
        return Icons.settings;
      default:
        return Icons.error;
    }
  }
}

class UsersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> users = List.generate(
    10,
    (index) => {
      'id': index + 1,
      'name': 'User ${index + 1}',
      'email': 'user${index + 1}@example.com',
      'role': index % 2 == 0 ? 'Admin' : 'User',
      'status': index % 3 == 0 ? 'Active' : 'Inactive',
    },
  );

  UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users.map((user) {
                  return DataRow(cells: [
                    DataCell(Text('#${user['id']}')),
                    DataCell(Text(user['name'])),
                    DataCell(Text(user['email'])),
                    DataCell(Text(user['role'])),
                    DataCell(
                      Chip(
                        label: Text(user['status']),
                        backgroundColor: user['status'] == 'Active'
                            ? Colors.green[100]
                            : Colors.grey[300],
                      ),
                    ),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditUserDialog(user: {}),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {},
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
}

class ProductsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> products = List.generate(
    10,
    (index) => {
      'id': index + 1,
      'name': 'Product ${index + 1}',
      'price': (index + 1) * 10.99,
      'stock': (index + 1) * 5,
      'category': index % 2 == 0 ? 'Electronics' : 'Clothing',
    },
  );

  ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: products.map((product) {
                  return DataRow(cells: [
                    DataCell(Text('#${product['id']}')),
                    DataCell(Text(product['name'])),
                    DataCell(Text('\$${product['price']}')),
                    DataCell(Text('${product['stock']}')),
                    DataCell(Text(product['category'])),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditProductDialog(
                                product: {},
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {},
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
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _darkMode = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    title: Text('Email Notifications'),
                    subtitle: Text('Receive email updates and alerts'),
                    trailing: Switch(
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                      },
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Dark Mode'),
                    subtitle: Text('Enable dark theme'),
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                      },
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Language'),
                    subtitle: Text('Select your preferred language'),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: ['English', 'French', 'Spanish', 'German']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedLanguage = newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E88E5),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditUserDialog({super.key, required this.user});

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController roleController;
  late TextEditingController statusController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['name']);
    emailController = TextEditingController(text: widget.user['email']);
    roleController = TextEditingController(text: widget.user['role']);
    statusController = TextEditingController(text: widget.user['status']);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: roleController,
              decoration: InputDecoration(labelText: 'Role'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: statusController,
              decoration: InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Implement save logic here
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E88E5)),
          child: Text('Save'),
        ),
      ],
    );
  }
}

class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  const EditProductDialog({super.key, required this.product});

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    priceController =
        TextEditingController(text: widget.product['price'].toString());
    stockController =
        TextEditingController(text: widget.product['stock'].toString());
    categoryController =
        TextEditingController(text: widget.product['category']);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: stockController,
              decoration: InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Implement save logic here
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1E88E5)),
          child: Text('Save'),
        ),
      ],
    );
  }
}
