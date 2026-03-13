import 'dart:math' as math;

import 'package:dama/controller/user_progress_controller.dart';
import 'package:dama/models/session_model.dart';
import 'package:dama/models/training_model.dart';
import 'package:dama/services/api_service.dart';
import 'package:dama/services/local_storage_service.dart';
import 'package:dama/utils/constants.dart';
import 'package:dama/utils/theme_provider.dart';
import 'package:dama/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// CIRCULAR PROGRESS
// ─────────────────────────────────────────────────────────────
class _CircularProgress extends StatelessWidget {
  const _CircularProgress({
    required this.progress,
    this.size = 120,
    this.strokeWidth = 8,
  });

  final double progress;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: progress / 100,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              gradientColors: [kBlue, Colors.purple],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${progress.round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Complete',
                style: TextStyle(fontSize: 11, color: kGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradientColors,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final List<Color> gradientColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi * progress,
        colors: gradientColors,
      );
      final progressPaint =
          Paint()
            ..shader = gradient.createShader(rect)
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────
// STAT CARD  — fixed: Column wrapped in Expanded to prevent overflow
// ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDarkMode,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: kBlue),
          ),
          const SizedBox(width: 12),
          // ✅ Expanded prevents the text column from overflowing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16, // ✅ reduced from 22 to fit narrow cards
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: kGrey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SESSION CARD
// ─────────────────────────────────────────────────────────────
class _SessionCard extends StatefulWidget {
  const _SessionCard({
    required this.session,
    required this.isDarkMode,
    required this.onJoin,
    required this.onLeave,
    required this.isJoining,
    required this.isLeaving,
  });

  final TrainingSession session;
  final bool isDarkMode;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final bool isJoining;
  final bool isLeaving;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isExpanded = false;

  bool get _isLive => widget.session.status == 'ongoing';
  bool get _isCompleted => widget.session.status == 'completed';
  bool get _hasJoined => widget.session.isJoined == true;

  bool get _hasDetailsContent =>
      (widget.session.meetingUrl?.isNotEmpty ?? false) ||
      (widget.session.notes?.isNotEmpty ?? false) ||
      (widget.session.materials?.isNotEmpty ?? false) ||
      (widget.session.type?.isNotEmpty ?? false) ||
      (widget.session.meetingPlatform?.isNotEmpty ?? false) ||
      (widget.session.description?.isNotEmpty ?? false);

  bool get _hasDetails =>
      _isCompleted ? _hasDetailsContent : (_hasJoined && _hasDetailsContent);

  Color get _statusBg {
    if (_isLive) return Colors.green.withValues(alpha: 0.1);
    if (_isCompleted) return Colors.grey.withValues(alpha: 0.1);
    return Colors.blue.withValues(alpha: 0.1);
  }

  Color get _statusColor {
    if (_isLive) return Colors.green[700]!;
    if (_isCompleted) return Colors.grey[600]!;
    return Colors.blue[700]!;
  }

  String get _statusLabel {
    if (_isLive) return 'Live Now';
    if (_isCompleted) return 'Completed';
    return 'Upcoming';
  }

  Future<void> _launchUrl(String url) async {
    String resolvedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      resolvedUrl = 'https://$url';
    }
    final uri = Uri.parse(resolvedUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open link'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed:
                  () => Clipboard.setData(ClipboardData(text: resolvedUrl)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkCard : kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              _isLive
                  ? Colors.green.withValues(alpha: 0.4)
                  : (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
          width: _isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.15 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main row
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap:
                (_hasJoined || _isCompleted) && _hasDetails
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          _isCompleted
                              ? Colors.green.withValues(alpha: 0.1)
                              : !_hasJoined
                              ? Colors.grey.withValues(alpha: 0.15)
                              : _isLive
                              ? Colors.green.withValues(alpha: 0.2)
                              : kBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isCompleted
                          ? Icons.check_circle
                          : !_hasJoined
                          ? Icons.lock_clock
                          : _isLive
                          ? Icons.videocam
                          : Icons.play_arrow,
                      size: 22,
                      color:
                          _isCompleted
                              ? Colors.green[600]
                              : !_hasJoined
                              ? Colors.grey[500]
                              : _isLive
                              ? Colors.green[600]
                              : kBlue,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _statusBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLive)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (_isCompleted)
                                    const Icon(
                                      Icons.check_circle,
                                      size: 10,
                                      color: Colors.grey,
                                    ),
                                  if (!_isLive && !_isCompleted)
                                    const Icon(
                                      Icons.access_time,
                                      size: 10,
                                      color: Colors.blue,
                                    ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ✅ "Joined" badge — shown whenever isJoined is true
                            if (_hasJoined)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.check_circle,
                                      size: 10,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Joined',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.session.duration?.isNotEmpty ?? false)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 11,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.session.duration!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          widget.session.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                        ),

                        // Description
                        if ((_hasJoined || _isCompleted) &&
                            (widget.session.description?.isNotEmpty ??
                                false)) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.session.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else if (!_hasJoined && !_isCompleted) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Join this session to view details, meeting link, and resources',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color:
                                  isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                            ),
                          ),
                        ],

                        // Date/time
                        if (widget.session.startTime != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatSessionDate(widget.session.startTime!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  _buildActions(),
                ],
              ),
            ),
          ),

          // ── Expanded details
          if ((_hasJoined || _isCompleted) && _isExpanded && _hasDetails)
            _buildExpandedDetails(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildActions() {
    // Not joined, not completed → Join button
    if (!_hasJoined && !_isCompleted) {
      return SizedBox(
        width: 80,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          onPressed: widget.isJoining ? null : widget.onJoin,
          child:
              widget.isJoining
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text(
                    'Join',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      );
    }

    // Completed, not joined → expand toggle
    if (!_hasJoined && _isCompleted && _hasDetails) {
      return IconButton(
        icon: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: kGrey,
        ),
        onPressed: () => setState(() => _isExpanded = !_isExpanded),
      );
    }

    // Joined → contextual actions
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLive && (widget.session.meetingUrl?.isNotEmpty ?? false))
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.green),
            tooltip: 'Enter Class',
            onPressed: () => _launchUrl(widget.session.meetingUrl!),
          ),
        if (_isCompleted && (widget.session.recordingUrl?.isNotEmpty ?? false))
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: kBlue),
            tooltip: 'Replay',
            onPressed: () => _launchUrl(widget.session.recordingUrl!),
          ),
        if (!_isCompleted)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Leave',
            onPressed: widget.isLeaving ? null : widget.onLeave,
          ),
        if (_hasDetails)
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: kGrey,
            ),
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
          ),
      ],
    );
  }

  Widget _buildExpandedDetails(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((widget.session.meetingUrl?.isNotEmpty ?? false) ||
              (widget.session.meetingPlatform?.isNotEmpty ?? false)) ...[
            _sectionHeader(Icons.videocam, 'Class Details'),
            const SizedBox(height: 8),
            if (widget.session.meetingPlatform?.isNotEmpty ?? false)
              _detailRow(
                Icons.place,
                'Platform',
                widget.session.meetingPlatform!,
                isDarkMode,
              ),
            if (widget.session.meetingUrl?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: kGrey),
                    const SizedBox(width: 6),
                    const Text(
                      'Link: ',
                      style: TextStyle(fontSize: 13, color: kGrey),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _launchUrl(widget.session.meetingUrl!),
                        child: Text(
                          widget.session.meetingUrl!,
                          style: const TextStyle(fontSize: 13, color: kBlue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 12,
                        color: kBlue,
                      ),
                      label: const Text(
                        'Enter Class',
                        style: TextStyle(fontSize: 12, color: kBlue),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBlue),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _launchUrl(widget.session.meetingUrl!),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (widget.session.notes?.isNotEmpty ?? false) ...[
            _sectionHeader(Icons.chat_bubble_outline, 'Session Notes'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? kDarkThemeBg : kWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
              child: Text(
                widget.session.notes!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.session.materials?.isNotEmpty ?? false) ...[
            _sectionHeader(
              Icons.description,
              'Resources (${widget.session.materials!.length})',
            ),
            const SizedBox(height: 8),
            ...widget.session.materials!.map(
              (r) => _resourceTile(r, isDarkMode),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kBlue,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kGrey),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: kGrey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? kWhite : kBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourceTile(SessionResource resource, bool isDarkMode) {
    final ext = resource.url.split('.').last.toLowerCase();
    final isLink = resource.type == 'link';
    final isPdf = ext == 'pdf';

    return GestureDetector(
      onTap: () => _launchUrl(resource.url),
      child: Container(
        margin: const EdgeInsets.only(left: 20, bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode ? kDarkThemeBg : kWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isLink
                        ? Colors.green.withValues(alpha: 0.1)
                        : isPdf
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isLink
                    ? Icons.link
                    : isPdf
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
                size: 18,
                color:
                    isLink
                        ? Colors.green
                        : isPdf
                        ? Colors.red
                        : Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? kWhite : kBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isLink ? 'link' : ext.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: kGrey),
                  ),
                ],
              ),
            ),
            Icon(
              isLink || isPdf ? Icons.open_in_new : Icons.download,
              size: 16,
              color: kGrey,
            ),
          ],
        ),
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    }
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}

// ─────────────────────────────────────────────────────────────
// LOADING SKELETON
// ─────────────────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: isDarkMode ? kDarkCard : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                height: 70,
                margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkCard : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkCard : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TRAINING DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────
class TrainingDashboard extends StatefulWidget {
  const TrainingDashboard({super.key, required this.training});

  final TrainingModel training;

  @override
  State<TrainingDashboard> createState() => _TrainingDashboardState();
}

class _TrainingDashboardState extends State<TrainingDashboard> {
  final UserProgressController _progressController =
      Get.find<UserProgressController>();

  bool _isLoading = true;
  String? _error;
  List<TrainingSession> _sessions = [];
  double _progressPercent = 0;
  int _completedSessions = 0;
  int _totalSessions = 0;
  bool _isCertificateAvailable = false;
  bool _isViewCertLoading = false;

  String? _joiningSessionId;
  String? _leavingSessionId;

  // ✅ Persists joined state across re-fetches.
  // The API returns "Already in session" correctly but may not always
  // return isJoined: true on subsequent GET calls, so we track it locally.
  final Set<String> _locallyJoinedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await _progressController.fetchTrainingSessions(
        widget.training.id,
      );

      // ✅ Merge API isJoined with our locally-tracked joined IDs
      final mergedSessions =
          sessions.map((s) {
            if (_locallyJoinedSessionIds.contains(s.id)) {
              return s.copyWith(isJoined: true);
            }
            // Also seed the local set from what the API already knows
            if (s.isJoined == true) {
              _locallyJoinedSessionIds.add(s.id);
            }
            return s;
          }).toList();

      final completedCount =
          mergedSessions
              .where(
                (s) =>
                    s.status == 'completed' ||
                    (s.isJoined == true && s.status == 'ongoing'),
              )
              .length;
      final totalSessions = mergedSessions.length;
      final progressPercent =
          totalSessions > 0 ? (completedCount / totalSessions) * 100 : 0.0;

      setState(() {
        _sessions = mergedSessions;
        _totalSessions = totalSessions;
        _completedSessions = completedCount;
        _progressPercent = progressPercent;
        // Check if certificate is available based on:
        // 1. Certificate already issued, OR
        // 2. Training status is completed, OR
        // 3. Progress is 100% or more
        final trainingStatus = widget.training.status?.toLowerCase() ?? '';
        _isCertificateAvailable =
            widget.training.certificate?.issued == true ||
            trainingStatus == 'completed' ||
            _progressPercent >= 100;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      setState(() {
        _error = 'Failed to load training dashboard';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoinSession(TrainingSession session) async {
    setState(() => _joiningSessionId = session.id);
    try {
      final result = await _progressController.joinSession(
        widget.training.id,
        session.id,
      );

      // ✅ Treat both "success: true" and "Already in session" as joined
      final success = result['success'] == true;
      final alreadyJoined = (result['message'] ?? '')
          .toString()
          .toLowerCase()
          .contains('already');

      if (mounted) {
        final message =
            alreadyJoined
                ? 'Already checked in to ${session.title}'
                : success
                ? 'Joined ${session.title}'
                : result['message'] ?? 'Failed to join';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                (success || alreadyJoined) ? Colors.green : Colors.red,
          ),
        );

        if (success || alreadyJoined) {
          // ✅ Persist joined state locally so it survives re-fetches
          _locallyJoinedSessionIds.add(session.id);

          // Optimistically update the session list
          setState(() {
            _sessions =
                _sessions
                    .map(
                      (s) =>
                          s.id == session.id ? s.copyWith(isJoined: true) : s,
                    )
                    .toList();
          });

          // Launch meeting URL if provided
          if (result['meetingUrl'] != null) {
            _launchUrl(result['meetingUrl']);
          } else {
            await _fetchDashboardData();
          }
        }
      }
    } finally {
      if (mounted) setState(() => _joiningSessionId = null);
    }
  }

  Future<void> _handleLeaveSession(TrainingSession session) async {
    setState(() => _leavingSessionId = session.id);
    try {
      final result = await _progressController.leaveSession(
        widget.training.id,
        session.id,
      );
      final success = result['success'] == true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Left ${session.title}'
                  : result['message'] ?? 'Failed to leave',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );

        if (success) {
          // ✅ Remove from local joined tracking
          _locallyJoinedSessionIds.remove(session.id);

          setState(() {
            _sessions =
                _sessions
                    .map(
                      (s) =>
                          s.id == session.id ? s.copyWith(isJoined: false) : s,
                    )
                    .toList();
          });
        }
      }
    } finally {
      if (mounted) setState(() => _leavingSessionId = null);
    }
  }

  Future<void> _handleViewCertificate() async {
    setState(() => _isViewCertLoading = true);
    try {
      String? certNumber = widget.training.certificate?.certificateNumber;
      final userId = await StorageService.getData('userId');

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to view your certificate'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Try to get certificate number from multiple sources
      // Source 1: Training model certificate
      if (certNumber == null || certNumber.isEmpty) {
        debugPrint(
          '[Certificate] No certificate number in training model, trying to generate...',
        );
        try {
          final apiService = ApiService();
          final cert = await apiService.generateCertificate(
            widget.training.id,
            userId,
          );
          if (cert != null && cert.certificateNumber.isNotEmpty) {
            certNumber = cert.certificateNumber;
            debugPrint('[Certificate] Generated new certificate: $certNumber');
          }
        } catch (e) {
          debugPrint('[Certificate] Failed to generate certificate: $e');
        }
      }

      // Source 2: Fetch from user's certificates list
      if (certNumber == null || certNumber.isEmpty) {
        debugPrint(
          '[Certificate] Trying to fetch from user certificates list...',
        );
        try {
          final certs = await _progressController.fetchUserCertificates(userId);
          final found = certs.firstWhereOrNull(
            (c) => c.trainingId == widget.training.id,
          );
          if (found != null && found.certificateNumber.isNotEmpty) {
            certNumber = found.certificateNumber;
            debugPrint(
              '[Certificate] Found certificate in user list: $certNumber',
            );
          }
        } catch (e) {
          debugPrint('[Certificate] Failed to fetch user certificates: $e');
        }
      }

      // Open certificate if we have a number
      if (certNumber != null && certNumber.isNotEmpty && mounted) {
        final url = '$BASE_URL/certificates/download/$certNumber';
        debugPrint('[Certificate] Opening certificate URL: $url');
        final launched = await _launchUrl(url);

        if (launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate opened'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open certificate. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (mounted) {
        // Provide more specific error message based on training status
        final trainingStatus = widget.training.status?.toLowerCase() ?? '';
        final progress = _progressPercent.round();

        String message;
        if (trainingStatus != 'completed' && progress < 100) {
          message =
              'Complete all sessions to earn your certificate. Current progress: $progress%';
        } else if (trainingStatus == 'completed' || progress >= 100) {
          message =
              'Your certificate is being processed. Please try again in a few minutes.';
        } else {
          message =
              'Certificate not available yet. Complete all sessions to earn your certificate.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Certificate] Error in _handleViewCertificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isViewCertLoading = false);
    }
  }

  Future<bool> _launchUrl(String url) async {
    try {
      String resolved = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        resolved = 'https://$url';
      }
      final uri = Uri.parse(resolved);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDarkMode ? kDarkThemeBg : kBGColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopNavigationbar(title: widget.training.title),
          Expanded(
            child:
                _isLoading
                    ? _DashboardSkeleton(isDarkMode: isDarkMode)
                    : _error != null
                    ? _buildErrorState(isDarkMode)
                    : RefreshIndicator(
                      color: kWhite,
                      backgroundColor: kBlue,
                      onRefresh: _fetchDashboardData,
                      child: _buildContent(isDarkMode),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    final liveSessions = _sessions.where((s) => s.status == 'ongoing').toList();
    final upcomingSessions =
        _sessions.where((s) => s.status == 'scheduled').toList();
    final completedSessions =
        _sessions.where((s) => s.status == 'completed').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── HERO HEADER
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDarkMode
                      ? [kDarkCard, Colors.grey[900]!]
                      : [kWhite, Colors.blue.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CircularProgress(
                    progress: _progressPercent,
                    size: 110,
                    strokeWidth: 8,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (widget.training.category?.isNotEmpty ?? false)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: kBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  widget.training.category!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            _enrolledBadge(isDarkMode),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.training.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (widget.training.trainer != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: kBlue.withValues(alpha: 0.15),
                                child: Text(
                                  _initials(
                                    widget.training.trainer!.firstName,
                                    widget.training.trainer!.lastName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: kBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${widget.training.trainer!.firstName} ${widget.training.trainer!.lastName}'
                                          .trim(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? kWhite : kBlack,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'Instructor',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 350;
                  return Row(
                    children: [
                      if (liveSessions.isNotEmpty)
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                              ),
                              icon: const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                isNarrow ? 'Join Live' : 'Join Live Session',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed:
                                  () => _handleJoinSession(liveSessions.first),
                            ),
                          ),
                        ),
                      if (liveSessions.isNotEmpty) const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.menu_book,
                            size: 16,
                            color: isDarkMode ? kWhite : kBlack,
                          ),
                          label: Text(
                            isNarrow ? 'Details' : 'View Details',
                            style: TextStyle(
                              color: isDarkMode ? kWhite : kBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color:
                                  isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── STATS ROW  (2 cards — no overflow at any screen width)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.menu_book,
                value: '$_completedSessions/$_totalSessions',
                label: 'Sessions Done',
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events,
                value:
                    _progressPercent >= 100
                        ? '🎉'
                        : '${_progressPercent.round()}%',
                label: _progressPercent >= 100 ? 'Completed!' : 'Progress',
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── CERTIFICATE BANNER
        if (_isCertificateAvailable)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.08),
                  Colors.purple.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.2),
                        Colors.purple.withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 24,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎓 Certificate Earned!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? kWhite : kBlack,
                        ),
                      ),
                      const Text(
                        'Congratulations on completing this training.',
                        style: TextStyle(fontSize: 12, color: kGrey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  icon:
                      _isViewCertLoading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.white,
                          ),
                  label: const Text(
                    'View',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: _isViewCertLoading ? null : _handleViewCertificate,
                ),
              ],
            ),
          ),

        // ── LIVE SESSION ALERT
        if (liveSessions.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 350;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videocam,
                        size: 20,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isNarrow
                                ? 'Live Now!'
                                : 'Live Session in Progress!',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            liveSessions.first.title,
                            style: const TextStyle(fontSize: 13, color: kGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _handleJoinSession(liveSessions.first),
                      child: Text(
                        isNarrow ? 'Join' : 'Join Now',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],

        // ── SESSIONS LIST HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.school, size: 20, color: kBlue),
                const SizedBox(width: 8),
                Text(
                  'Course Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? kWhite : kBlack,
                  ),
                ),
              ],
            ),
            Text(
              '${_sessions.length} total',
              style: const TextStyle(fontSize: 13, color: kGrey),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── SESSIONS
        if (_sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkCard : kWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 48,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 12),
                const Text(
                  'No sessions scheduled yet.',
                  style: TextStyle(color: kGrey),
                ),
              ],
            ),
          )
        else ...[
          ...liveSessions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionCard(
                session: s,
                isDarkMode: isDarkMode,
                onJoin: () => _handleJoinSession(s),
                onLeave: () => _handleLeaveSession(s),
                isJoining: _joiningSessionId == s.id,
                isLeaving: _leavingSessionId == s.id,
              ),
            ),
          ),
          ...upcomingSessions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionCard(
                session: s,
                isDarkMode: isDarkMode,
                onJoin: () => _handleJoinSession(s),
                onLeave: () => _handleLeaveSession(s),
                isJoining: _joiningSessionId == s.id,
                isLeaving: _leavingSessionId == s.id,
              ),
            ),
          ),
          ...completedSessions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionCard(
                session: s,
                isDarkMode: isDarkMode,
                onJoin: () => _handleJoinSession(s),
                onLeave: () => _handleLeaveSession(s),
                isJoining: _joiningSessionId == s.id,
                isLeaving: _leavingSessionId == s.id,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _enrolledBadge(bool isDarkMode) {
    Color bg, textColor, borderColor;
    String label;
    IconData? icon;

    if (_progressPercent >= 100) {
      bg = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green[700]!;
      borderColor = Colors.green.withValues(alpha: 0.3);
      label = 'Completed';
      icon = Icons.check_circle;
    } else if (_progressPercent > 0) {
      bg = Colors.amber.withValues(alpha: 0.1);
      textColor = Colors.amber[700]!;
      borderColor = Colors.amber.withValues(alpha: 0.3);
      label = 'Active';
      icon = Icons.play_circle;
    } else {
      bg = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue[700]!;
      borderColor = Colors.blue.withValues(alpha: 0.3);
      label = 'Enrolled';
      icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Training not found',
              style: const TextStyle(fontSize: 14, color: kGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load this training. You may not be enrolled.',
              style: TextStyle(fontSize: 13, color: kGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
              label: const Text(
                'Back to My Trainings',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String first, String last) {
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
        .toUpperCase();
  }
}
