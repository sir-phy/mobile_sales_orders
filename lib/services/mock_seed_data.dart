import '../models/models.dart';

const List<Customer> mockCustomers = [
  Customer(
    id: 'CUS-001',
    name: 'Acme Retail',
    contactName: 'Priya Sharma',
    phone: '+91 98765 43210',
    email: 'priya@acmeretail.in',
  ),
  Customer(
    id: 'CUS-002',
    name: 'Bright Office Co.',
    contactName: 'Rahul Verma',
    phone: '+91 99887 76655',
    email: 'rahul@brightoffice.in',
  ),
  Customer(
    id: 'CUS-003',
    name: 'Metro Supplies',
    contactName: 'Vikram Mehta',
    phone: '+91 98111 22334',
    email: 'vikram@metrosupplies.in',
  ),
  Customer(
    id: 'CUS-004',
    name: 'Nexus Trading',
    contactName: 'Anita Singh',
    phone: '+91 91234 56789',
    email: 'anita@nexustrading.in',
  ),
  Customer(
    id: 'CUS-005',
    name: 'Greenline Stores',
    contactName: 'Karan Patel',
    phone: '+91 97654 32109',
    email: 'karan@greenlinestores.in',
  ),
  Customer(
    id: 'CUS-006',
    name: 'Summit Tech Hub',
    contactName: 'Neha Nair',
    phone: '+91 96543 21098',
    email: 'neha@summittech.in',
  ),
];

const List<ProductCatalogItem> mockProductCatalog = [
  ProductCatalogItem(
    id: 'PRD-001',
    name: 'Wireless mouse',
    productCode: 'PRD-001',
    unitPrice: 850,
    category: 'Peripherals',
    stock: 142,
  ),
  ProductCatalogItem(
    id: 'PRD-002',
    name: 'Mechanical keyboard',
    productCode: 'PRD-002',
    unitPrice: 1500,
    category: 'Peripherals',
    stock: 64,
  ),
  ProductCatalogItem(
    id: 'PRD-003',
    name: 'USB-C multiport hub',
    productCode: 'PRD-003',
    unitPrice: 2200,
    category: 'Accessories',
    stock: 48,
  ),
  ProductCatalogItem(
    id: 'PRD-004',
    name: 'Laptop stand aluminum',
    productCode: 'PRD-004',
    unitPrice: 1450,
    category: 'Workspace',
    stock: 85,
  ),
  ProductCatalogItem(
    id: 'PRD-005',
    name: '27" IPS Monitor',
    productCode: 'PRD-005',
    unitPrice: 14800,
    category: 'Displays',
    stock: 19,
  ),
  ProductCatalogItem(
    id: 'PRD-006',
    name: 'HD Webcam 1080p',
    productCode: 'PRD-006',
    unitPrice: 2650,
    category: 'Video',
    stock: 37,
  ),
];

const List<AppNotification> mockSeedNotifications = [
  AppNotification(
    id: 'n1',
    title: 'Order SO-2026-0148 confirmed',
    subtitle: 'Acme Retail · \$7,170 ready for processing',
    timeAgo: '12m ago',
  ),
  AppNotification(
    id: 'n2',
    title: 'Pending approval: SO-2026-0145',
    subtitle: 'Nexus Trading order awaiting confirmation',
    timeAgo: '2h ago',
  ),
  AppNotification(
    id: 'n3',
    title: 'Monthly target reached 87%',
    subtitle: '216 completed orders this month',
    timeAgo: '1d ago',
    isRead: true,
  ),
];

const UserProfile mockDefaultProfile = UserProfile(
  name: 'Alex Morgan',
  role: 'Regional Sales Lead',
  email: 'alex@orderly.in',
  phone: '+91 98200 11223',
  workspaceName: 'Orderly Workspace',
  currency: 'USD (\$)',
);

List<OrderItem> createMockSeedOrders() => [
      OrderItem(
        orderNumber: 'SO-2026-0148',
        customerName: 'Acme Retail',
        customer: mockCustomers[0],
        date: '11 Nov 2026',
        time: '10:42 AM',
        createdAt: DateTime(2026, 11, 11, 10, 42),
        items: [
          ProductItem(id: '1', name: 'Wireless mouse', productCode: 'PRD-001', unitPrice: 850, quantity: 4, discount: 170),
          ProductItem(id: '2', name: 'Mechanical keyboard', productCode: 'PRD-002', unitPrice: 1500, quantity: 3, discount: 560),
        ],
        amount: 7170,
        status: 'Confirmed',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0147',
        customerName: 'Bright Office Co.',
        customer: mockCustomers[1],
        date: '10 Nov 2026',
        time: '04:15 PM',
        createdAt: DateTime(2026, 11, 10, 16, 15),
        items: [
          ProductItem(id: '3', name: 'USB-C multiport hub', productCode: 'PRD-003', unitPrice: 2200, quantity: 4, discount: 350),
          ProductItem(id: '4', name: 'Laptop stand aluminum', productCode: 'PRD-004', unitPrice: 1450, quantity: 3, discount: 350),
        ],
        amount: 12450,
        status: 'Confirmed',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0145',
        customerName: 'Nexus Trading',
        customer: mockCustomers[3],
        date: '09 Nov 2026',
        time: '02:20 PM',
        createdAt: DateTime(2026, 11, 9, 14, 20),
        items: [
          ProductItem(id: '5', name: 'HD Webcam 1080p', productCode: 'PRD-006', unitPrice: 2650, quantity: 2, discount: 180),
          ProductItem(id: '6', name: 'Mechanical keyboard', productCode: 'PRD-002', unitPrice: 1500, quantity: 2, discount: 0),
          ProductItem(id: '7', name: 'Wireless mouse', productCode: 'PRD-001', unitPrice: 850, quantity: 1, discount: 350),
        ],
        amount: 8620,
        status: 'Pending',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0139',
        customerName: 'Greenline Stores',
        customer: mockCustomers[4],
        date: '28 Oct 2026',
        time: '11:05 AM',
        createdAt: DateTime(2026, 10, 28, 11, 5),
        items: [
          ProductItem(id: '8', name: 'Mechanical keyboard', productCode: 'PRD-002', unitPrice: 1500, quantity: 2, discount: 150),
        ],
        amount: 2850,
        status: 'Cancelled',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0146',
        customerName: 'Metro Supplies',
        customer: mockCustomers[2],
        date: '09 Nov 2026',
        time: '11:30 AM',
        createdAt: DateTime(2026, 11, 9, 11, 30),
        items: [
          ProductItem(id: '9', name: 'USB-C multiport hub', productCode: 'PRD-003', unitPrice: 2200, quantity: 2, discount: 200),
          ProductItem(id: '10', name: 'Wireless mouse', productCode: 'PRD-001', unitPrice: 850, quantity: 1, discount: 250),
        ],
        amount: 4800,
        status: 'Confirmed',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0138',
        customerName: 'Summit Tech Hub',
        customer: mockCustomers[5],
        date: '25 Oct 2026',
        time: '03:50 PM',
        createdAt: DateTime(2026, 10, 25, 15, 50),
        items: [
          ProductItem(id: '11', name: '27" IPS Monitor', productCode: 'PRD-005', unitPrice: 14800, quantity: 1, discount: 800),
        ],
        amount: 14000,
        status: 'Confirmed',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0137',
        customerName: 'Acme Retail',
        customer: mockCustomers[0],
        date: '22 Oct 2026',
        time: '09:15 AM',
        createdAt: DateTime(2026, 10, 22, 9, 15),
        items: [
          ProductItem(id: '12', name: 'Laptop stand aluminum', productCode: 'PRD-004', unitPrice: 1450, quantity: 4, discount: 200),
        ],
        amount: 5600,
        status: 'Pending',
      ),
      OrderItem(
        orderNumber: 'SO-2026-0136',
        customerName: 'Bright Office Co.',
        customer: mockCustomers[1],
        date: '19 Oct 2026',
        time: '05:10 PM',
        createdAt: DateTime(2026, 10, 19, 17, 10),
        items: [
          ProductItem(id: '13', name: 'Wireless mouse', productCode: 'PRD-001', unitPrice: 850, quantity: 6, discount: 100),
        ],
        amount: 5000,
        status: 'Confirmed',
      ),
    ];

