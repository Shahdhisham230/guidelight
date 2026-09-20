import 'package:flutter/material.dart';
import '../models/family_member.dart';

class StatusCard extends StatelessWidget {
  final FamilyMember member;

  const StatusCard({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(
                Icons.person,
                size: 30,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: member.isSafe
                            ? Colors.green
                            : Colors.red,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        member.isSafe ? 'Safe' : 'Danger',
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    member.deviceConnected
                        ? 'Device Connected'
                        : 'Device Disconnected',
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Last update: ${member.lastUpdate}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}