import 'package:dama/utils/constants.dart';
import 'package:flutter/material.dart';

enum AlertVariant {
  success,  // Green
  error,    // Red
  warning,  // Orange/Yellow
  info,     // Blue
}

class ModernAlert extends StatefulWidget {
  final String title;
  final String description;
  final AlertVariant variant;
  final VoidCallback? onDismiss;
  final bool isDarkMode;

  const ModernAlert({
    super.key,
    required this.title,
    required this.description,
    this.variant = AlertVariant.info,
    this.onDismiss,
    required this.isDarkMode,
  });

  @override
  State<ModernAlert> createState() => _ModernAlertState();
}

class _ModernAlertState extends State<ModernAlert> {
  bool _isVisible = true;

  Color _getAlertColor() {
    switch (widget.variant) {
      case AlertVariant.success:
        return kGreen;
      case AlertVariant.error:
        return kRed;
      case AlertVariant.warning:
        return kYellow;
      case AlertVariant.info:
        return kBlue;
    }
  }

  IconData _getAlertIcon() {
    switch (widget.variant) {
      case AlertVariant.success:
        return Icons.check_circle_rounded;
      case AlertVariant.error:
        return Icons.error_rounded;
      case AlertVariant.warning:
        return Icons.warning_rounded;
      case AlertVariant.info:
        return Icons.info_rounded;
    }
  }

  Color _getBackgroundColor() {
    final alertColor = _getAlertColor();
    return widget.isDarkMode
        ? Color.lerp(kBlack, alertColor, 0.12)!
        : Color.lerp(kWhite, alertColor, 0.05)!;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    final alertColor = _getAlertColor();
    final bgColor = _getBackgroundColor();
    final textColor = widget.isDarkMode ? kWhite : kBlack;
    final descriptionColor = widget.isDarkMode
        ? Colors.grey[400]
        : Colors.grey[600];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: alertColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon (left aligned)
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 2),
                child: Icon(
                  _getAlertIcon(),
                  color: alertColor,
                  size: 20,
                ),
              ),
              // Content (title + description)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title (bold, medium weight)
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    // Description (smaller, muted)
                    if (widget.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: descriptionColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Close button (right side)
              GestureDetector(
                onTap: () {
                  setState(() => _isVisible = false);
                  widget.onDismiss?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.close_rounded,
                    color: descriptionColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alert provider for managing multiple alerts
class AlertProvider extends ChangeNotifier {
  final List<_AlertItem> _alerts = [];

  List<_AlertItem> get alerts => _alerts;

  void show({
    required String title,
    required String description,
    AlertVariant variant = AlertVariant.info,
  }) {
    final alert = _AlertItem(
      title: title,
      description: description,
      variant: variant,
    );

    _alerts.add(alert);
    notifyListeners();
  }

  void dismiss({required _AlertItem alert}) {
    _alerts.remove(alert);
    notifyListeners();
  }

  void dismissAll() {
    _alerts.clear();
    notifyListeners();
  }
}

class _AlertItem {
  final String title;
  final String description;
  final AlertVariant variant;

  _AlertItem({
    required this.title,
    required this.description,
    required this.variant,
  });
}

/// Widget to display alerts from provider
class AlertStack extends StatelessWidget {
  final AlertProvider alertProvider;
  final bool isDarkMode;

  const AlertStack({
    super.key,
    required this.alertProvider,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: alertProvider,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: alertProvider.alerts
              .map(
                (alert) => ModernAlert(
                  title: alert.title,
                  description: alert.description,
                  variant: alert.variant,
                  isDarkMode: isDarkMode,
                  onDismiss: () {
                    alertProvider.dismiss(alert: alert);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}
