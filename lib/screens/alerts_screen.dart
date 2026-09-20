
import 'package:flutter/material.dart';

import '../models/alert.dart';
import '../services/api_service.dart';


class AlertsScreen extends StatefulWidget {

  const AlertsScreen({
    super.key,
  });

  @override
  State<AlertsScreen> createState() =>
      _AlertsScreenState();
}


class _AlertsScreenState
    extends State<AlertsScreen> {

  List<Alert> alerts = [];

  bool isLoading = true;

  String? errorMessage;


  @override
  void initState() {

    super.initState();

    loadAlerts();
  }


  Future<void> loadAlerts() async {

    try {

      final result =
          await ApiService.getAlerts();


      if (!mounted) return;


      setState(() {

        alerts = result;

        isLoading = false;
      });

    } catch (e) {

      if (!mounted) return;


      setState(() {

        errorMessage = e.toString();

        isLoading = false;
      });
    }
  }


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Alerts',
        ),
      ),


      body: buildBody(),
    );
  }


  Widget buildBody() {

    // ==========================================
    // Loading
    // ==========================================

    if (isLoading) {

      return const Center(
        child: CircularProgressIndicator(),
      );
    }


    // ==========================================
    // Error
    // ==========================================

    if (errorMessage != null) {

      return Center(

        child: Padding(

          padding:
              const EdgeInsets.all(20),

          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }


    // ==========================================
    // No Alerts
    // ==========================================

    if (alerts.isEmpty) {

      return const Center(

        child: Text(
          'No alerts found.',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }


    // ==========================================
    // Alerts List
    // ==========================================

    return ListView.builder(

      padding:
          const EdgeInsets.all(20),

      itemCount:
          alerts.length,


      itemBuilder:
          (context, index) {

        final alert =
            alerts[index];


        final isDanger =
            alert.type ==
                AlertType.danger;


        return Card(

          margin:
              const EdgeInsets.only(
            bottom: 16,
          ),


          child: Padding(

            padding:
                const EdgeInsets.all(20),


            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,


              children: [

                // ==================================
                // Alert Type
                // ==================================

                Row(

                  children: [

                    Icon(

                      isDanger

                          ? Icons
                              .warning_amber_rounded

                          : Icons
                              .notifications_active_outlined,

                      color: isDanger
                          ? Colors.red
                          : Colors.orange,

                      size: 30,
                    ),


                    const SizedBox(
                      width: 10,
                    ),


                    Text(

                      isDanger

                          ? 'Danger Detected'

                          : 'Assistance Request',


                      style:
                          const TextStyle(

                        fontSize: 18,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),


                const SizedBox(
                  height: 16,
                ),


                // ==================================
                // Object
                // ==================================

                if (isDanger &&
                    alert.objectName != null)

                  Text(

                    'Object: '
                    '${alert.objectName}',

                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),


                if (isDanger &&
                    alert.objectName != null)

                  const SizedBox(
                    height: 8,
                  ),


                // ==================================
                // Distance
                // ==================================

                if (isDanger &&
                    alert.distance != null)

                  Text(

                    'Distance: '
                    '${alert.distance} m',

                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),


                if (isDanger &&
                    alert.distance != null)

                  const SizedBox(
                    height: 12,
                  ),


                // ==================================
                // Message
                // ==================================

                Text(

                  alert.message,

                  style:
                      const TextStyle(
                    fontSize: 15,
                  ),
                ),


                const SizedBox(
                  height: 12,
                ),


                // ==================================
                // Time
                // ==================================

                Text(

                  alert.time,

                  style:
                      const TextStyle(

                    fontSize: 12,

                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

