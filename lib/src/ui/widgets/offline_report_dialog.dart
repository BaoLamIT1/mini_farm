import 'package:flutter/material.dart';

import '../../core/engine/farm_engine.dart';
import '../strings/farm_strings.dart';

Future<void> showOfflineReportDialog(BuildContext context, OfflineReport report) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(FarmStrings.offlineTitle),
      content: Text(
        report.hoursAway >= 1
            ? 'Bạn đi vắng ${report.hoursAway} giờ — ${report.readyCount} cây đã chín!'
            : '${report.readyCount} cây đã chín trong lúc bạn đi vắng!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(FarmStrings.offlineOk),
        ),
      ],
    ),
  );
}
