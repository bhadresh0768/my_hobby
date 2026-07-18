import 'package:flutter/material.dart';

class ExpandableDescription extends StatefulWidget {
  final String description;
  final int maxLines;
  final TextStyle? style;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.maxLines = 3,
    this.style,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.description, style: widget.style);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        if (!tp.didExceedMaxLines) {
          return Text(widget.description, style: widget.style);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: widget.style,
            ),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  _isExpanded ? "Read Less" : "Read More",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
