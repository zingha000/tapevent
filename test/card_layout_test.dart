import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('horizontal card renders without exception',
      (WidgetTester tester) async {
    Widget card() {
      return GestureDetector(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 140, width: double.infinity),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Title text here',
                      style: TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tagline',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '8 juni - 10 juni 2026',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ORGANIZER',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(height: 1, width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Text(
                      '10 peserta',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Container(
                      width: 96,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('Lihat Detail')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 366,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 300,
                child: card(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Title text here'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
