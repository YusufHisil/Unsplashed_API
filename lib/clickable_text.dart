import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClickableText extends StatelessWidget {
  const ClickableText({super.key, required this.text, required this.url});
  final String text;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          _launchURL(url);
        },
        child: Text(
          text,
          textAlign: TextAlign.start,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw ArgumentError('Could not launch${url.path}');
    }
  }
}
