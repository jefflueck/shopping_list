import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:shopping_list/data/categories.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('shopping-list-24da1-default-rtdb.firebaseio.com',
        'shopping-list.json');
    final response = await http.get(url);
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> _loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      _loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = _loadedItems;
    });
  }

  void _addItem() async {
    await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    _loadItems();
  }

  void _deleteItem(String id) async {
    final url = Uri.https('shopping-list-24da1-default-rtdb.firebaseio.com',
        'shopping-list/$id.json');
    await http.delete(url);
    _loadItems();
  }

  void _clearList() async {
    final url = Uri.https('shopping-list-24da1-default-rtdb.firebaseio.com',
        'shopping-list.json');
    await http.delete(url);
    _loadItems();
  }

  void _undoItemDeletion(GroceryItem item) async {
    final url = Uri.https('shopping-list-24da1-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category.title,
      }),
    );

    if (response.statusCode != 200) {
      // Handle error
      return;
    }

    _loadItems(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          )
        ],
      ),
      body: _groceryItems.isEmpty
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'No items yet!',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _groceryItems.length,
              itemBuilder: (ctx, index) => Dismissible(
                key: ValueKey(_groceryItems[index].id),
                direction: DismissDirection.horizontal,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  final deletedItem = _groceryItems[index];
                  setState(() {
                    _groceryItems.removeAt(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Item deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            setState(() {
                              _groceryItems.insert(index, deletedItem);
                            });
                            _undoItemDeletion(deletedItem);
                          },
                        ),
                      ),
                    );
                  });
                  _deleteItem(deletedItem.id);
                },
                child: ListTile(
                  title: Text(_groceryItems[index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(_groceryItems[index].quantity.toString()),
                ),
              ),
            ),

      // dynamically add a button that clears the list of items if items exist with text 'Clear List' and trash can icon

      floatingActionButton: _groceryItems.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.delete),
              label: const Text('Clear List'),
              onPressed: () {
                setState(() {
                  _groceryItems.clear();
                  _clearList();
                });
              },
            ),
    );
  }
}
