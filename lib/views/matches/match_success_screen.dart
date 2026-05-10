import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/match.dart';
import '../widgets/success_screen.dart';

/// Success screen displayed after successfully joining a match
class MatchSuccessScreen extends StatelessWidget {
  final MatchWithDetails match;
  final double? amountPaid;

  const MatchSuccessScreen({
    super.key,
    required this.match,
    this.amountPaid,
  });

  String _formatPrice(double price) {
    if (price == 0) return 'Miễn phí';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)}đ';
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(parsed);
    } catch (e) {
      return date;
    }
  }

  String _formatTimeRange(String start, String end) {
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      title: 'Tham gia thành công! 🎉',
      subtitle: 'Bạn đã tham gia trận đấu thành công.\nHãy sẵn sàng để chơi!',
      referenceId: match.id,
      referenceLabel: 'Mã trận đấu',
      amount: amountPaid,
      formatPrice: _formatPrice,
      details: [
        SuccessDetailItem(
          icon: Icons.sports_tennis,
          label: 'Trận đấu',
          value: match.title,
        ),
        SuccessDetailItem(
          icon: Icons.location_on,
          label: 'Sân',
          value: match.court?.name ?? 'Không xác định',
        ),
        if (match.court?.addressFull != null)
          SuccessDetailItem(
            icon: Icons.map,
            label: 'Địa chỉ',
            value: match.court!.addressFull!,
          ),
        SuccessDetailItem(
          icon: Icons.calendar_today,
          label: 'Ngày',
          value: _formatDate(match.date),
        ),
        SuccessDetailItem(
          icon: Icons.access_time,
          label: 'Thời gian',
          value: _formatTimeRange(match.startTime, match.endTime),
        ),
        SuccessDetailItem(
          icon: Icons.person,
          label: 'Chủ trận',
          value: match.host?.displayName ?? 'Không xác định',
        ),
        SuccessDetailItem(
          icon: Icons.group,
          label: 'Số người chơi',
          value: '${match.totalPlayersCount}/${match.slotsNeeded} người',
        ),
      ],
      nextSteps: const [
        SuccessNextStep(
          icon: Icons.notifications_active_outlined,
          text: 'Bạn sẽ nhận được thông báo nhắc nhở trước trận đấu',
        ),
        SuccessNextStep(
          icon: Icons.location_on_outlined,
          text: 'Đến sân trước 10 phút để chuẩn bị',
        ),
        SuccessNextStep(
          icon: Icons.sports_tennis,
          text: 'Mang theo vợt cầu lông hoặc thuê tại sân',
        ),
      ],
      actions: [
        SuccessActionButton(
          label: 'Xem chi tiết',
          onPressed: () {
            // Pop back to match detail view
            Navigator.of(context).pop(true);
          },
          isPrimary: false,
        ),
        SuccessActionButton(
          label: 'Hoàn tất',
          onPressed: () {
            // Pop all and go back to main screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          isPrimary: true,
        ),
      ],
      onBack: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
