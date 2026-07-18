import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/models/review_model.dart';
import '../../../../common/models/business_model.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/review/review_bloc.dart';
import '../../../bloc/review/review_event.dart';

class AddReviewDialog extends StatefulWidget {
  final Business business;
  final Review? existingReview;

  const AddReviewDialog({super.key, required this.business, this.existingReview});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  double _rating = 0;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final bool isEditing = widget.existingReview != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Review' : 'Add Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Write your comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating == 0
              ? null
              : () {
                  if (user == null) return;
                  if (isEditing) {
                    final updatedReview = Review(
                      id: widget.existingReview!.id,
                      businessId: widget.business.id,
                      userId: user.uid,
                      userName: user.displayName ?? 'Anonymous',
                      userPhotoUrl: user.photoUrl,
                      rating: _rating,
                      comment: _commentController.text,
                      createdAt: widget.existingReview!.createdAt,
                      ownerReply: widget.existingReview!.ownerReply,
                    );
                    context.read<ReviewBloc>().add(ReviewUpdateRequested(
                          oldReview: widget.existingReview!,
                          newReview: updatedReview,
                        ));
                  } else {
                    final review = Review(
                      id: '',
                      businessId: widget.business.id,
                      userId: user.uid,
                      userName: user.displayName ?? 'Anonymous',
                      userPhotoUrl: user.photoUrl,
                      rating: _rating,
                      comment: _commentController.text,
                      createdAt: DateTime.now(),
                    );
                    context.read<ReviewBloc>().add(ReviewAddRequested(review));
                  }
                  Navigator.pop(context);
                },
          child: Text(isEditing ? 'Update' : 'Submit'),
        ),
      ],
    );
  }
}
