import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/exchange_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/custom_button.dart';

class RatingReviewModal extends StatefulWidget {
  final ExchangeRequestModel request;
  final String partnerId;
  final String partnerName;

  const RatingReviewModal({
    super.key,
    required this.request,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<RatingReviewModal> createState() => _RatingReviewModalState();
}

class _RatingReviewModalState extends State<RatingReviewModal> {
  int _selectedStars = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      await reviewProvider.submitReview(
        requestId: widget.request.id,
        reviewerId: currentUser.id,
        revieweeId: widget.partnerId,
        stars: _selectedStars,
        comment: _commentController.text.trim(),
        reviewerName: currentUser.name,
        onUserUpdated: (updatedUser) {},
      );
    }

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you! Review submitted for ${widget.partnerName}.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Rate Study Session',
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'How was your skill exchange with ${widget.partnerName}?',
            style: AppTextStyles.bodyMediumSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Interactive Star Rating 1-5
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() => _selectedStars = starValue);
                },
                iconSize: 36,
                icon: Icon(
                  starValue <= _selectedStars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              );
            }),
          ),
          Center(
            child: Text(
              '$_selectedStars of 5 Stars',
              style: AppTextStyles.captionBold.copyWith(color: const Color(0xFFD97706)),
            ),
          ),
          const SizedBox(height: 20),

          // Feedback comment
          Text('Feedback (Optional)', style: AppTextStyles.subheading),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLength: 300,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share what you learned or what they taught well...',
            ),
          ),
          const SizedBox(height: 16),

          // Submit CTA
          CustomButton(
            text: 'Submit Review',
            onPressed: _handleSubmit,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
