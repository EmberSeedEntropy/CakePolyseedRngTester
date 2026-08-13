import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const CakeRngTester());

class CakeRngTester extends StatelessWidget {
  const CakeRngTester({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cake Polyseed RNG Tester',
      theme: ThemeData.dark(useMaterial3: true),
      home: const RngHome(),
    );
  }
}

class RngHome extends StatefulWidget {
  const RngHome({super.key});

  @override
  State<RngHome> createState() => _RngHomeState();
}

class _RngHomeState extends State<RngHome> {
  static const int count = 10000;
  static const int digitsPerLine = 10;

  final _controller = TextEditingController();

  bool _busy = false;
  String _status = 'Ready';

  /*
   * CAKE / POLYSEED ENTROPY SOURCE
   *
   * Cake Wallet 6.4.0 uses Polyseed 0.0.7 for the Monero
   * 16-word Polyseed path.
   *
   * Polyseed obtains random bytes using:
   *
   *     Random.secure().nextInt(256)
   *
   * We use the same secure random byte mechanism here.
   *
   * The 0-9 output is ONLY a diagnostic representation.
   * It is not Polyseed's native representation.
   */

  final Random _secureRandom = Random.secure();

  int _nextSecureByte() {
    return _secureRandom.nextInt(256);
  }

  /*
   * Convert the secure byte stream to unbiased decimal digits.
   *
   * Lower four bits produce values 0-15.
   *
   * 0-9  = accepted
   * 10-15 = rejected
   *
   * This avoids modulo bias.
   */
  int _nextUnbiasedDigit() {
    while (true) {
      final byte = _nextSecureByte();
      final candidate = byte & 0x0F;

      if (candidate < 10) {
        return candidate;
      }
    }
  }

  /*
   * Generate exactly 10,000 digits.
   *
   * Newlines are presentation only:
   * 10 digits per line.
   *
   * The underlying sequence is unchanged.
   */
  String _generate() {
    final output = StringBuffer();

    for (var i = 0; i < count; i++) {
      output.write(_nextUnbiasedDigit());

      if ((i + 1) % digitsPerLine == 0 && i + 1 < count) {
        output.write('\n');
      }
    }

    return output.toString();
  }

  Future<void> _generateDigits() async {
    setState(() {
      _busy = true;
      _status = 'Generating 10,000 digits…';
    });

    await Future<void>.delayed(Duration.zero);

    try {
      final text = _generate();

      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: text.length,
        ),
      );

      setState(() {
        _status = '10,000 digits generated';
        _busy = false;
      });
    } catch (_) {
      setState(() {
        _status = 'Secure random generation failed';
        _busy = false;
      });
    }
  }

  Future<void> _copy() async {
    if (_controller.text.isEmpty) return;

    /*
     * IMPORTANT:
     * Copy the formatted output exactly as displayed.
     * The diagnostic can therefore receive the digits
     * directly, with the line breaks acting only as
     * separators.
     */
    await Clipboard.setData(
      ClipboardData(text: _controller.text),
    );

    setState(() {
      _status = 'Copied 10,000 digits';
    });
  }

  void _clear() {
    _controller.clear();

    setState(() {
      _status = 'Cleared';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _controller.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cake Polyseed RNG Tester'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cake Wallet 6.4.0 • Monero • Polyseed 16-word path',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Uses the same secure random byte mechanism as '
                'Polyseed 0.0.7, then converts the output to '
                'unbiased 0–9 digits for Ember Diagnostics.',
                style: TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _generateDigits,
                      child: const Text('GENERATE 10,000'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: hasData ? _copy : null,
                      child: const Text('COPY'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: hasData ? _clear : null,
                      child: const Text('CLEAR'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              Text(
                _status,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 9),

              Expanded(
                child: TextField(
                  controller: _controller,
                  readOnly: true,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Generated digits appear here',
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
