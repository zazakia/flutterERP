// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

void main() {
  runApp(const ItemManagerApp());
}

// Item model class
class Item {
  String id;
  String name;
  String description;
  double price;
  int quantity;
  DateTime createdAt;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.createdAt,
  });

  double get totalValue => price * quantity;
}

class ItemManagerApp extends StatelessWidget {
  const ItemManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brayan Lee\'s Products',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ItemManagerHomePage(title: 'Brayan Lee\'s Products'),
    );
  }
}

class ItemManagerHomePage extends StatefulWidget {
  const ItemManagerHomePage({super.key, required this.title});

  final String title;

  @override
  State<ItemManagerHomePage> createState() => _ItemManagerHomePageState();
}

class _ItemManagerHomePageState extends State<ItemManagerHomePage> {
  List<Item> items = [];
  String searchQuery = '';

  void _addItem() {
    _showItemDialog();
  }

  void _editItem(int index) {
    _showItemDialog(item: items[index], index: index);
  }

  void _deleteItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _showItemDialog({Item? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(text: item?.description ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                final newItem = Item(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                  price: double.parse(priceController.text),
                  quantity: int.parse(quantityController.text),
                  createdAt: item?.createdAt ?? DateTime.now(),
                );

                setState(() {
                  if (item == null) {
                    items.add(newItem);
                  } else if (index != null) {
                    items[index] = newItem;
                  }
                });
                Navigator.of(context).pop();
              }
            },
            child: Text(item == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  List<Item> get filteredItems {
    if (searchQuery.isEmpty) return items;
    return items.where((item) =>
      item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      item.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  double get totalValue {
    return filteredItems.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search items...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items: ${filteredItems.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Total Value: \$${totalValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
              ? const Center(
                  child: Text('No items found. Add some items to get started!'),
                )
              : ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.description),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${item.price.toStringAsFixed(2)}'),
                            Text('Qty: ${item.quantity}'),
                            Text(
                              '\$${item.totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        onTap: () => _editItem(items.indexOf(item)),
                        onLongPress: () => _deleteItem(items.indexOf(item)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
