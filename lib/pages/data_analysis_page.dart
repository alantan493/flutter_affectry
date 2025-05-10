// data_analysis_page.dart

import 'package:flutter/material.dart';

class DataAnalysisPage extends StatelessWidget {
  const DataAnalysisPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Analysis'),
      ),
      body: Center(
        child: Text(
          'Data Analysis Page',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}