class DashboardOverview {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final String growthText;
  final String completionRateText;
  final String period;
  final String updatedLabel;

  const DashboardOverview({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.growthText,
    required this.completionRateText,
    required this.period,
    this.updatedLabel = 'Updated just now',
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      growthText: json['growthText'] as String? ?? '+18% vs Oct',
      completionRateText:
          json['completionRateText'] as String? ?? '87% of orders',
      period: json['period'] as String? ?? 'This month',
      updatedLabel: json['updatedLabel'] as String? ?? 'Updated just now',
    );
  }

  Map<String, dynamic> toJson() => {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'growthText': growthText,
        'completionRateText': completionRateText,
        'period': period,
        'updatedLabel': updatedLabel,
      };
}

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isRead;
  final String targetRole;
  final String? orderNumber;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.isRead = false,
    this.targetRole = 'sell_lead',
    this.orderNumber,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      targetRole: json['targetRole'] as String? ?? 'sell_lead',
      orderNumber: json['orderNumber'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        subtitle: subtitle,
        timeAgo: timeAgo,
        isRead: isRead ?? this.isRead,
        targetRole: targetRole,
        orderNumber: orderNumber,
      );
}

class UserProfile {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String workspaceName;
  final String currency;

  const UserProfile({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.workspaceName,
    required this.currency,
  });
}

