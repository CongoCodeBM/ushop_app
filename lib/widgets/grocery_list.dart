import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ushop_app/constants/url_strings.dart';
import 'package:ushop_app/data/categories.dart';
import 'package:ushop_app/models/grocery_item.dart';
import 'package:ushop_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  //late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
   // _loadedItems = _loadItems();
  }

  //Future<List<GroceryItem>> _loadItems() async {
  void _loadItems() async {
    final url = Uri.https(
        realtTimeDbStringUrl, realTimeDbStringJSONpart); 

   try {
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      print("The response code:  ${response.statusCode}");
      //throw Exception("Failed to load items. Try again later.");
        setState(() {
            _error = "Something went wrong. Please try again later.";
          });
    }

    if (response.body == "null") {
      //this logic is backend specific: it is "null" for Firebase. Could be 404 ...
      setState(() {
        _isLoading = false;
      });
      return;
      //return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (categItem) => categItem.value.title == item.value["category"])
          .value;
        loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value["name"],
          quantity: item.value["quantity"],
          category: category,
        ));
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    //return loadedItems;
    } catch (error) {
      setState(() {
          _error = "Something went wrong. Please try again later.";
        });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https("ushop-b5aa5-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");

    http.delete(url);

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      //optinal: show error message
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text(
        "No items added yet.",
      ),
    );
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
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
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Groceries",
        ),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
      // body: FutureBuilder(
      //   future: _loadedItems,
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(
      //         child: CircularProgressIndicator(),
      //       );
      //     }

      //     if (snapshot.hasError) {
      //       return Center(
      //         child: Text(snapshot.error.toString()),
      //       );
      //     }

      //     if (snapshot.data!.isEmpty) {
      //       return const Center(
      //         child: Text("No items added yet."),
      //       );
      //     }

      //     return ListView.builder(
      //       itemCount: snapshot.data!.length,
      //       itemBuilder: (ctx, index) => Dismissible(
      //         onDismissed: (direction) {
      //           _removeItem(snapshot.data![index]);
      //         },
      //         key: ValueKey(snapshot.data![index].id),
      //         child: ListTile(
      //           title: Text(snapshot.data![index].name),
      //           leading: Container(
      //             width: 24,
      //             height: 24,
      //             color: snapshot.data![index].category.color,
      //           ),
      //           trailing: Text(snapshot.data![index].quantity.toString()),
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}
