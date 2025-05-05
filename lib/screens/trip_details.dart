import 'package:flutter/material.dart';
import '../models/travel_plan_model.dart';

class TripDetails extends StatefulWidget {
  final Travel travel;

  TripDetails({
    Key? super.key,
    required this.travel,
  });

  @override
  _TripDetailsState createState() => _TripDetailsState();
}

class _TripDetailsState extends State<TripDetails> {
  final _activityTitleController = TextEditingController();
  DateTime? _activityStartDate;
  DateTime? _activityEndDate;

  void _addActivity() {
    if (_activityTitleController.text.isNotEmpty &&
        _activityStartDate != null &&
        _activityEndDate != null) {
      setState(() {
        widget.travel.activities?.add(Activity(
          title: _activityTitleController.text,
          startDate: _activityStartDate!,
          endDate: _activityEndDate!,
        ));
      });
      _activityTitleController.clear();
      _activityStartDate = null;
      _activityEndDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.travel.name),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.travel.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Destination: ${widget.travel.location}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Start Date: ${widget.travel.startDate?.toLocal()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'End Date: ${widget.travel.endDate?.toLocal()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Itinerary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.travel.activities?.length ?? 0,
                itemBuilder: (context, index) {
                  final activity = widget.travel.activities![index];
                  return ListTile(
                    title: Text(activity.title),
                    subtitle: Text(
                        '${activity.startDate.toLocal()} - ${activity.endDate.toLocal()}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _activityTitleController,
              decoration: const InputDecoration(labelText: 'Activity Title'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _activityStartDate = picked;
                        });
                      }
                    },
                    child: Text(_activityStartDate == null
                        ? 'Select Start Date'
                        : _activityStartDate!.toLocal().toString()),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _activityEndDate = picked;
                        });
                      }
                    },
                    child: Text(_activityEndDate == null
                        ? 'Select End Date'
                        : _activityEndDate!.toLocal().toString()),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _addActivity,
              child: const Text('Add Activity'),
            ),
          ],
        ),
      ),
    );
  }
}