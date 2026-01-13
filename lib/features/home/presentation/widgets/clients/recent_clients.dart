import 'package:flutter/material.dart';

class RecentClients extends StatefulWidget {
  const RecentClients({super.key});

  @override
  State<RecentClients> createState() => _RecentClientsState();
}

class _RecentClientsState extends State<RecentClients> {
  bool _expanded = false; // за замовчуванням приховано

  @override
  Widget build(BuildContext context) {
    final recentChecks = [
      RecentCheck(
        tableNumber: 'T4',
        cashier: 'Leslie K.',
        itemsCount: 3,
        destination: 'Kitchen',
        isInProcess: false,
      ),
      RecentCheck(
        tableNumber: 'T2',
        cashier: 'Jacob J.',
        itemsCount: 5,
        destination: 'Kitchen',
        isInProcess: true,
      ),
      RecentCheck(
        tableNumber: 'T4',
        cashier: 'Cameron W.',
        itemsCount: 2,
        destination: 'Kitchen',
        isInProcess: true,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Відкладені чеки',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
                tooltip: _expanded ? 'Згорнути' : 'Розгорнути',
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentChecks.length,
                itemBuilder: (context, index) {
                  final check = recentChecks[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              check.tableNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              check.cashier,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${check.itemsCount} items',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              check.destination,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (check.isInProcess) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'In process',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class RecentCheck {
  final String tableNumber;
  final String cashier;
  final int itemsCount;
  final String destination;
  final bool isInProcess;

  RecentCheck({
    required this.tableNumber,
    required this.cashier,
    required this.itemsCount,
    required this.destination,
    required this.isInProcess,
  });
}
