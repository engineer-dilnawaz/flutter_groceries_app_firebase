import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_groceries_app/data/categories.dart';
import 'package:flutter_groceries_app/models/grocery_item.dart';
import 'package:flutter_groceries_app/widgets/grocery_item.dart';
import 'package:flutter_groceries_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      'flutter-app-max-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shpping-list.json',
    );

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category =
          categories.entries
              .firstWhere(
                (element) => element.value.title == item.value['category'],
              )
              .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    // setState(() {
    //   _groceryItems = loadedItems;
    //   _isLoading = false;
    // });
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => NewItem()));
    // _loadItems();

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
      'flutter-app-max-default-rtdb.asia-southeast1.firebasedatabase.app',
      'shpping-list/${item.id}.json',
    );
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(
            '${item.name} couldn\'t be deleted. Please try again later!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.data!.isEmpty) {
            return Center(child: Text('No items added yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) {
              return Dismissible(
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                key: ValueKey(snapshot.data![index].id),
                child: GroceryListItem(
                  title: snapshot.data![index].name,
                  color: snapshot.data![index].category.color,
                  quantity: snapshot.data![index].quantity.toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
