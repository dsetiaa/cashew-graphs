// import 'package:flutter/material.dart';
//
// Widget _buildFilterControls() {
//   return Card(
//     margin: EdgeInsets.all(16),
//     child: Padding(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: TextButton.icon(
//                   icon: Icon(Icons.calendar_today),
//                   label: Text(_startDate == null
//                       ? 'Start Date'
//                       : DateFormat('MMM dd').format(_startDate!)),
//                   onPressed: () => _selectDate(true),
//                 ),
//               ),
//               SizedBox(width: 8),
//               Expanded(
//                 child: TextButton.icon(
//                   icon: Icon(Icons.calendar_today),
//                   label: Text(_endDate == null
//                       ? 'End Date'
//                       : DateFormat('MMM dd').format(_endDate!)),
//                   onPressed: () => _selectDate(false),
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               TextButton(
//                 child: Text('Last 7 Days'),
//                 onPressed: () => _applyDateFilter(
//                   DateTime.now().subtract(Duration(days: 7)),
//                   DateTime.now(),
//                 ),
//               ),
//               TextButton(
//                 child: Text('Last 30 Days'),
//                 onPressed: () => _applyDateFilter(
//                   DateTime.now().subtract(Duration(days: 30)),
//                   DateTime.now(),
//                 ),
//               ),
//               TextButton(
//                 child: Text('Clear'),
//                 onPressed: () => _applyDateFilter(null, null),
//               ),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }