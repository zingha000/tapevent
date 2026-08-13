import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/static_content.dart';

class StaticInfoScreen extends StatelessWidget {
  final String title;
  final String content;
  final String description;
  const StaticInfoScreen({
    super.key,
    required this.title,
    required this.content,
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageScaffoldColor,
      body: Stack(
        children: [
          // ===== Background saya =====
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_saya.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.35),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: context.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(height: 1, color: context.border),
                ),
                const SizedBox(height: 20),

                // ─── Content ───
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth - 40;
                      final innerWidth = cardWidth - 32;
                      final benchmarkHeight = _contentHeight(
                        context,
                        StaticContent.privacyPolicy,
                        innerWidth,
                      );
                      final maxCardHeight =
                          (benchmarkHeight + 32 + 24).clamp(
                            0.0,
                            constraints.maxHeight,
                          );
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: maxCardHeight,
                          ),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            padding: const EdgeInsets.all(16),
                            clipBehavior: Clip.antiAlias,
                            decoration: context.cardDecoration,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildContent(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<(int, String)> _parseLines(String text) {
    final result = <(int, String)>[];
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        result.add((3, ''));
      } else if (line.startsWith('# ')) {
        result.add((1, line.substring(2)));
      } else if (line.startsWith('- ')) {
        result.add((2, line.substring(2)));
      } else {
        result.add((0, line));
      }
    }
    return result;
  }

  List<Widget> _buildContent(BuildContext context) {
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.6,
      color: context.textPrimary,
    );
    final headerStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: context.textPrimary,
    );
    final children = <Widget>[];
    for (final (type, line) in _parseLines(content)) {
      switch (type) {
        case 3:
          children.add(const SizedBox(height: 6));
        case 1:
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(line, style: headerStyle),
            ),
          );
        case 2:
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: bodyStyle),
                  Expanded(child: Text(line, style: bodyStyle)),
                ],
              ),
            ),
          );
        case 0:
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: bodyStyle),
            ),
          );
      }
    }
    return children;
  }

  double _contentHeight(BuildContext context, String text, double width) {
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.6,
      color: context.textPrimary,
    );
    final headerStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: context.textPrimary,
    );
    double total = 0;
    for (final (type, line) in _parseLines(text)) {
      switch (type) {
        case 3:
          total += 6;
        case 1:
          total += 10;
          total += _textHeight(headerStyle, line, width);
          total += 4;
        case 2:
          final bulletHeight = _textHeight(bodyStyle, '•  ', width);
          final textHeight = _textHeight(bodyStyle, line, width);
          total += (bulletHeight > textHeight ? bulletHeight : textHeight) + 4;
        case 0:
          total += _textHeight(bodyStyle, line, width) + 4;
      }
    }
    return total;
  }

  double _textHeight(TextStyle style, String text, double width) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    return painter.height;
  }
}
