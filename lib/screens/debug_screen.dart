import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _result = 'Tap button to test Django connection';
  bool _loading = false;
  
  Future<void> _testDjangoConnection() async {
    setState(() {
      _loading = true;
      _result = 'Testing Django connection...';
    });
    
    try {
      final response = await http.get(
        Uri.parse('http://208.109.215.53:3015/api/hospitals/?lat=37.7749&lng=-122.4194&radius=10'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      setState(() {
        _result = 'Status: \${response.statusCode}\\n'
                 'Headers: \${response.headers}\\n'
                 'Body length: \${response.body.length}\\n'
                 'First 500 chars: \${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: \$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Django Debug'),
        backgroundColor: Color(0xFF5DADE2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Connection Status Indicator
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _result.contains('200') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _result.contains('200') ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _result.contains('200') ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _result.contains('200') ? 'Django Backend Connected' : 'Django Backend Disconnected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _result.contains('200') ? Colors.green : Colors.red,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    _result.contains('200') ? Icons.check_circle : Icons.error,
                    color: _result.contains('200') ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            
            ElevatedButton(
              onPressed: _loading ? null : _testDjangoConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
                foregroundColor: Colors.white,
              ),
              child: _loading 
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Test Django Connection'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
