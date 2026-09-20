import 'dart:async';

import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../models/alert.dart';

import '../widgets/status_card.dart';

import '../services/api_service.dart';

import 'alerts_screen.dart';
import 'location_screen.dart';
import 'login_screen.dart';
import 'family_member_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FamilyMember? member;

  List<Alert> alerts = [];

  String? username;

  bool isLoading = true;

  String? error;

  // =========================================================
  // NOTIFICATION / ALERT CHECKING
  // =========================================================

  Timer? _alertTimer;

  int? _latestAlertId;

  OverlayEntry? _notificationOverlay;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadHomeData();

    _startAlertChecking();
  }

  // =========================================================
  // LOAD DATA FROM DJANGO
  // =========================================================

  Future<void> _loadHomeData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final profile = await ApiService.getProfile();

      final familyMembers =
          await ApiService.getFamilyMembers();

      final loadedAlerts =
          await ApiService.getAlerts();

      // -------------------------------------------------------
      // Save the latest existing alert.
      //
      // This prevents old alerts from showing as new
      // notifications when the app starts.
      // -------------------------------------------------------

      if (loadedAlerts.isNotEmpty) {
        _latestAlertId = loadedAlerts.first.id;
      }

      if (!mounted) return;

      if (familyMembers.isEmpty) {
        setState(() {
          username = profile['username'];

          alerts = loadedAlerts;

          isLoading = false;

          error = 'No family members found.';
        });

        return;
      }

      final loadedMember =
          FamilyMember.fromJson(
        familyMembers[0],
      );

      setState(() {
        username = profile['username'];

        member = loadedMember;

        alerts = loadedAlerts;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();

        isLoading = false;
      });
    }
  }

  // =========================================================
  // START ALERT CHECKING
  // =========================================================

  void _startAlertChecking() {
    _alertTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        try {
          final newAlerts =
              await ApiService.getAlerts();

          if (!mounted || newAlerts.isEmpty) {
            return;
          }

          final latestAlert =
              newAlerts.first;

          // ---------------------------------------------------
          // FIRST CHECK
          //
          // If we don't have a previous alert ID yet,
          // just save the current one.
          //
          // We don't show a notification here because
          // this alert already existed before.
          // ---------------------------------------------------

          if (_latestAlertId == null) {
            _latestAlertId =
                latestAlert.id;

            if (mounted) {
              setState(() {
                alerts = newAlerts;
              });
            }

            return;
          }

          // ---------------------------------------------------
          // NEW ALERT DETECTED
          // ---------------------------------------------------

          if (latestAlert.id !=
              _latestAlertId) {
            _latestAlertId =
                latestAlert.id;

            if (!mounted) return;

            setState(() {
              alerts = newAlerts;
            });

            _showInAppNotification(
              latestAlert,
            );
          }
        } catch (e) {
          print(
            'Alert checking error: $e',
          );
        }
      },
    );
  }

  // =========================================================
  // SHOW IN-APP NOTIFICATION
  // =========================================================

  void _showInAppNotification(
    Alert alert,
  ) {
    final bool isDanger =
        alert.type == AlertType.danger;

    // Remove previous notification
    _notificationOverlay?.remove();
    _notificationOverlay = null;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _TopNotification(
          alert: alert,
          isDanger: isDanger,
          onClose: () {
            overlayEntry.remove();

            if (_notificationOverlay ==
                overlayEntry) {
              _notificationOverlay = null;
            }
          },
        );
      },
    );

    _notificationOverlay = overlayEntry;

    Overlay.of(context).insert(
      overlayEntry,
    );

    // Automatically remove after 4 seconds
    Future.delayed(
      const Duration(seconds: 4),
      () {
        if (_notificationOverlay ==
            overlayEntry) {
          overlayEntry.remove();

          _notificationOverlay = null;
        }
      },
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    // Stop checking alerts before leaving the screen.
    _alertTimer?.cancel();

    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
    );
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _refreshHome() async {
    await _loadHomeData();
  }

  // =========================================================
  // RECENT ACTIVITY CARD
  // =========================================================

  Widget _buildActivityCard(
    Alert alert,
  ) {
    final bool isDanger =
        alert.type == AlertType.danger;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.06),

            blurRadius: 8,

            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // =================================================
            // ICON
            // =================================================

            Container(
              width: 48,
              height: 48,

              decoration:
                  BoxDecoration(
                color: isDanger
                    ? Colors.red
                        .withOpacity(0.1)
                    : Colors.orange
                        .withOpacity(0.1),

                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                isDanger
                    ? Icons
                        .warning_amber_rounded
                    : Icons.support_agent,

                color: isDanger
                    ? Colors.red
                    : Colors.orange,

                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // =================================================
            // CONTENT
            // =================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // =================================================
                  // TITLE + TIME
                  // =================================================

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          isDanger
                              ? 'Danger Detected'
                              : 'Assistance Requested',

                          style:
                              const TextStyle(
                            fontSize: 15,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        alert.time,

                        style:
                            const TextStyle(
                          fontSize: 11,

                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // =================================================
                  // MESSAGE
                  // =================================================

                  Text(
                    alert.message,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 13,

                      color:
                          Colors.black87,

                      height: 1.3,
                    ),
                  ),

                  // =================================================
                  // DETAILS
                  // =================================================

                  if (alert.objectName !=
                          null ||
                      alert.distance !=
                          null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 9,
                      ),

                      child: Wrap(
                        spacing: 8,

                        runSpacing: 5,

                        children: [
                          // =================================================
                          // OBJECT NAME
                          // =================================================

                          if (alert.objectName !=
                                  null &&
                              alert.objectName!
                                  .isNotEmpty)
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .grey
                                    .withOpacity(
                                  0.1,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  7,
                                ),
                              ),

                              child: Text(
                                alert.objectName!,

                                style:
                                    const TextStyle(
                                  fontSize: 11,

                                  color:
                                      Colors.grey,

                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),
                            ),

                          // =================================================
                          // DISTANCE
                          // =================================================

                          if (alert.distance !=
                              null)
                            Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,

                              children: [
                                const Icon(
                                  Icons
                                      .near_me_outlined,

                                  size: 14,

                                  color:
                                      Colors.grey,
                                ),

                                const SizedBox(
                                  width: 3,
                                ),

                                Text(
                                  '${alert.distance!.toStringAsFixed(1)} m',

                                  style:
                                      const TextStyle(
                                    fontSize: 11,

                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                        ],
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

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _alertTimer?.cancel();

    _notificationOverlay?.remove();
    _notificationOverlay = null;

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      // =======================================================
      // APP BAR
      // =======================================================

      appBar: AppBar(
        title:
            const Text('Guidelight'),

        centerTitle: true,

        actions: [
          // =================================================
          // REFRESH
          // =================================================

          IconButton(
            icon:
                const Icon(Icons.refresh),

            tooltip: 'Refresh',

            onPressed:
                isLoading
                    ? null
                    : _refreshHome,
          ),

          // =================================================
          // LOGOUT
          // =================================================

          IconButton(
            icon:
                const Icon(Icons.logout),

            tooltip: 'Logout',

            onPressed:
                _logout,
          ),
        ],
      ),

      // =======================================================
      // BODY
      // =======================================================

      body: RefreshIndicator(
        onRefresh:
            _refreshHome,

        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          child: Padding(
            padding:
                const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // =================================================
                // GREETING
                // =================================================

                Text(
                  username != null
                      ? 'Hello $username 👋'
                      : 'Hello 👋',

                  style:
                      const TextStyle(
                    fontSize: 28,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Here is your family member status',

                  style:
                      TextStyle(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                // =================================================
                // STATUS
                // =================================================

                if (isLoading)
                  const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                else if (error != null)
                  Text(
                    error!,

                    style:
                        const TextStyle(
                      fontSize: 16,

                      color:
                          Colors.red,
                    ),
                  )
                else if (member != null)
                  StatusCard(
                    member:
                        member!,
                  ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // QUICK ACTIONS
                // =================================================

                const Text(
                  'Quick Actions',

                  style:
                      TextStyle(
                    fontSize: 20,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // ALERTS + LOCATION
                // =================================================

                Row(
                  children: [
                    // =============================================
                    // ALERTS
                    // =============================================

                    Expanded(
                      child: Card(
                        child:
                            InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const AlertsScreen(),
                              ),
                            );
                          },

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),

                          child:
                              const Padding(
                            padding:
                                EdgeInsets
                                    .all(
                              20,
                            ),

                            child:
                                Column(
                              children: [
                                Icon(
                                  Icons
                                      .notifications_outlined,

                                  size:
                                      35,
                                ),

                                SizedBox(
                                  height:
                                      10,
                                ),

                                Text(
                                  'Alerts',

                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    // =============================================
                    // LOCATION
                    // =============================================

                    Expanded(
                      child: Card(
                        child:
                            InkWell(
                          onTap:
                              member ==
                                      null
                                  ? null
                                  : () {
                                      Navigator
                                          .push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  LocationScreen(
                                            familyMemberId:
                                                member!.id,
                                          ),
                                        ),
                                      );
                                    },

                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),

                          child:
                              const Padding(
                            padding:
                                EdgeInsets
                                    .all(
                              20,
                            ),

                            child:
                                Column(
                              children: [
                                Icon(
                                  Icons
                                      .location_on_outlined,

                                  size:
                                      35,
                                ),

                                SizedBox(
                                  height:
                                      10,
                                ),

                                Text(
                                  'Location',

                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // =================================================
                // START TRACKING
                // =================================================

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        member == null
                            ? null
                            : () {
                                Navigator
                                    .push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const FamilyMemberTrackingScreen(),
                                  ),
                                );
                              },

                    icon:
                        const Icon(
                      Icons.my_location,
                    ),

                    label:
                        const Text(
                      'Start Tracking',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                // =================================================
                // RECENT ACTIVITY
                // =================================================

                const Text(
                  'Recent Activity',

                  style:
                      TextStyle(
                    fontSize: 20,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // ACTIVITY LIST
                // =================================================

                if (alerts.isEmpty)
                  const Center(
                    child:
                        Padding(
                      padding:
                          EdgeInsets.only(
                        bottom: 20,
                      ),

                      child: Text(
                        'No recent activity.',

                        style:
                            TextStyle(
                          color:
                              Colors.grey,

                          fontSize:
                              15,
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children:
                        alerts.map(
                      (alert) {
                        return _buildActivityCard(
                          alert,
                        );
                      },
                    ).toList(),
                  ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// TOP NOTIFICATION
// =============================================================

class _TopNotification extends StatefulWidget {
  final Alert alert;

  final bool isDanger;

  final VoidCallback onClose;

  const _TopNotification({
    required this.alert,
    required this.isDanger,
    required this.onClose,
  });

  @override
  State<_TopNotification> createState() =>
      _TopNotificationState();
}

class _TopNotificationState
    extends State<_TopNotification>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      duration:
          const Duration(
        milliseconds: 350,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin:
          const Offset(0, -1.5),

      end:
          Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,

        curve:
            Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Positioned(
      top:
          MediaQuery.of(context)
                  .padding
                  .top +
              10,

      left: 16,

      right: 16,

      child: SlideTransition(
        position:
            _slideAnimation,

        child: Material(
          color:
              Colors.transparent,

          child: Container(
            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(
                    0.12,
                  ),

                  blurRadius: 18,

                  offset:
                      const Offset(
                    0,
                    6,
                  ),
                ),
              ],
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==========================================
                // ICON
                // ==========================================

                Container(
                  width: 48,

                  height: 48,

                  decoration:
                      BoxDecoration(
                    color: widget.isDanger
                        ? Colors.red
                            .withOpacity(
                            0.10,
                          )
                        : Colors.orange
                            .withOpacity(
                            0.10,
                          ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      14,
                    ),
                  ),

                  child: Icon(
                    widget.isDanger
                        ? Icons
                            .warning_amber_rounded
                        : Icons
                            .notifications_active_outlined,

                    color: widget.isDanger
                        ? Colors.red
                        : Colors.orange,

                    size: 27,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                // ==========================================
                // TEXT
                // ==========================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.isDanger
                                  ? 'Danger Detected'
                                  : 'New Alert',

                              style:
                                  const TextStyle(
                                fontSize: 15,

                                fontWeight:
                                    FontWeight.bold,

                                color:
                                    Colors.black87,
                              ),
                            ),
                          ),

                          // ==================================
                          // CLOSE BUTTON
                          // ==================================

                          GestureDetector(
                            onTap:
                                widget.onClose,

                            child:
                                const Icon(
                              Icons.close,

                              size: 20,

                              color:
                                  Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        widget.alert.message,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 13,

                          color:
                              Colors.black54,

                          height: 1.3,
                        ),
                      ),

                      if (widget.alert.distance !=
                          null)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 7,
                          ),

                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .near_me_outlined,

                                size: 14,

                                color: Colors
                                    .grey
                                    .shade600,
                              ),

                              const SizedBox(
                                width: 4,
                              ),

                              Text(
                                '${widget.alert.distance!.toStringAsFixed(1)} m away',

                                style:
                                    TextStyle(
                                  fontSize: 11,

                                  color: Colors
                                      .grey
                                      .shade600,

                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}