import 'customer.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'sell_lead' | 'customer'
  final String phone;
  final String? customerId;
  final Customer? customer;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.customerId,
    this.customer,
  });

  bool get isSellLead => role == 'sell_lead';
  bool get isCustomer => role == 'customer';

  String get roleLabel => isSellLead ? 'Sell Lead' : 'Customer';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final custJson = json['customer'];
    return AuthUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      phone: json['phone'] as String? ?? '',
      customerId: json['customerId'] as String?,
      customer: custJson is Map<String, dynamic>
          ? Customer.fromJson(custJson)
          : null,
    );
  }
}

class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String? ?? '',
      user: AuthUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

