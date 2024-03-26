// ignore_for_file: avoid_print, use_key_in_widget_constructors, avoid_function_literals_in_foreach_calls, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'dart:async';
import '../models/stock-list.dart';
import '../models/stock.dart';
import '../services/stock-service.dart';
import '../services/db-service.dart';

class HomeView extends StatefulWidget {
  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  final StockService _stockService = StockService();
  final SQFliteDbService _databaseService = SQFliteDbService();
  List<Stock> _stockList = [];
  String _stockSymbol = "";

  @override
  void initState() {
    super.initState();
    getOrCreateDbAndDisplayAllStocksInDb();
  }

  void getOrCreateDbAndDisplayAllStocksInDb() async {
    await _databaseService.getOrCreateDatabaseHandle();
    _stockList = await _databaseService.getAllStocksFromDb();
    await _databaseService.printAllStocksInDbToConsole();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Ticker'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            child: const Text(
              'Delete All Records and Db',
            ),
            onPressed: () async {
              await _databaseService.deleteDb();
              await _databaseService.getOrCreateDatabaseHandle();
              _stockList = await _databaseService.getAllStocksFromDb();
              await _databaseService.printAllStocksInDbToConsole();
              setState(() {});
            },
          ),
          ElevatedButton(
            child: const Text(
              'Add Stock',
            ),
            onPressed: () {
              inputStock();
            },
          ),
          Expanded(
            child: StockList(stocks: _stockList),
          ),
        ],
      ),
    );
  }

  Future<void> inputStock() async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Input Stock Symbol'),
            contentPadding: const EdgeInsets.all(5.0),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: "Symbol"),
              onChanged: (String value) {
                _stockSymbol = value;
              },
            ),
            actions: <Widget>[
              TextButton(
                child: const Text("Add Stock"),
                onPressed: () async {
                  if (_stockSymbol.isNotEmpty) {
                    print('User entered Symbol: $_stockSymbol');
                    try {
                      final companyInfo =
                          await _stockService.getCompanyInfo(_stockSymbol);
                      final stockQuote =
                          await _stockService.getQuote(_stockSymbol);
                      if (companyInfo != null && stockQuote != null) {
                        final symbol = companyInfo['symbol'] as String? ??
                            'N/A'; 
                        final name = companyInfo['companyName'] as String? ??
                            'N/A'; 
                        final price = stockQuote['latestPrice']?.toString() ??
                            'N/A'; 
                        final stock = Stock(
                          symbol: symbol,
                          name: name,
                          price: price,
                        );
                        await _databaseService.insertStock(stock);
                        _stockList =
                            await _databaseService.getAllStocksFromDb();
                        setState(() {});
                      } else {
                        print('Failed to get stock info or quote.');
                      }
                    } catch (e) {
                      print('Error in inputStock: $e');
                    }
                  }

                  _stockSymbol = "";
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }
}
