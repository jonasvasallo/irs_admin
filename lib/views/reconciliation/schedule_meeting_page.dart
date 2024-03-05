import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irs_admin/core/constants.dart';

class ScheduleMeetingPage extends StatefulWidget {
  const ScheduleMeetingPage({Key? key}) : super(key: key);

  @override
  _ScheduleMeetingPageState createState() => _ScheduleMeetingPageState();
}

class _ScheduleMeetingPageState extends State<ScheduleMeetingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conciliation Meetings"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Conciliations Scheduling",
                    style: subheading,
                  ),
                  StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('conciliations')
                          .snapshots(),
                      builder: (context, snapshot) {
                        List<DataRow> scheduledMediations = [];

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        if (!snapshot.hasData) {
                          return Text("No data available");
                        }

                        final schedules = snapshot.data?.docs.toList();

                        for (var schedule in schedules!) {
                          String myDate = "test";

                          if (schedule['time'] != null) {
                            Timestamp t = schedule['time'] as Timestamp;
                            DateTime date = t.toDate();
                            myDate =
                                DateFormat('dd/MM/yyyy,hh:mm').format(date);
                          }
                          final scheduleRow = DataRow(cells: [
                            DataCell(Text(schedule.id)),
                            DataCell(Text(myDate)),
                            DataCell(Text(schedule['subject'])),
                            DataCell(Text(schedule['info'])),
                            DataCell(
                              Row(
                                children: [
                                  TextButton(
                                      onPressed: () {},
                                      child: Icon(Icons.remove_red_eye)),
                                  TextButton(
                                      onPressed: () {},
                                      child: Icon(Icons.delete)),
                                ],
                              ),
                            ),
                          ]);
                        }
                        return DataTable(columns: [
                          DataColumn(label: Text("Schedule ID")),
                          DataColumn(label: Text("Scheduled Date")),
                          DataColumn(label: Text("Subject")),
                          DataColumn(label: Text("Action")),
                        ], rows: []);
                      })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
