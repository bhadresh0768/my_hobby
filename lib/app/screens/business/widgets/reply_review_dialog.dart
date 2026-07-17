import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/models/review_model.dart';
import '../../../bloc/review/review_bloc.dart';
import '../../../bloc/review/review_event.dart';

class ReplyReviewDialog extends StatefulWidget {
  final Review review;

  const ReplyReviewDialog({super.key, required this.review});

  @override
  State<ReplyReviewDialog> createState() => _ReplyReviewDialogState();
}

class _ReplyReviewDialogState extends State<ReplyReviewDialog> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _replyController.text = widget.review.ownerReply ?? '';
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reply to Review'),
      content: TextField(
        controller: _replyController,
        decoration: const InputDecoration(
          hintText: 'Write your reply...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ReviewBloc>().add(ReviewReplyAdded(
                  businessId: widget.review.businessId,
                  reviewId: widget.review.id,
                  reply: _replyController.text,
                ));
            Navigator.pop(context);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
