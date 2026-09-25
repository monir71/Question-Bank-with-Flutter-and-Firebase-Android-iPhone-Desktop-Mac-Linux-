import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:questionbank/models/app_user.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/services/user_service.dart';

class PendingQuestionAssessScreen extends StatefulWidget {
  final Question question;

  const PendingQuestionAssessScreen({
    super.key,
    required this.question,
  });

  @override
  State<PendingQuestionAssessScreen> createState() =>
      _PendingQuestionAssessScreenState();
}

class _PendingQuestionAssessScreenState
    extends State<PendingQuestionAssessScreen> {
  final QuestionService _questionService =
  QuestionService();

  final UserService _userService =
  UserService();

  late Question _question;

  AppUser? _submitter;

  List<Question> _submitterQuestions = [];

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;

  late TextEditingController _questionController;
  late TextEditingController _marksController;

  final List<TextEditingController> _optionControllers = [];

  String _selectedDifficulty = 'medium';

  @override
  void initState() {
    super.initState();

    _question = widget.question;

    _questionController =
        TextEditingController(
          text: _question.questionDescription,
        );

    _marksController =
        TextEditingController(
          text: _question.marks
              .toString()
              .replaceAll('.0', ''),
        );

    _selectedDifficulty =
        _question.difficulty.name;

    _createOptionControllers();

    _loadSubmitterData();
  }

  // ---------------------------------------------------------------------------
  // OPTION CONTROLLERS
  // ---------------------------------------------------------------------------

  void _createOptionControllers() {
    for (final controller
    in _optionControllers) {
      controller.dispose();
    }

    _optionControllers.clear();

    for (final option in _question.options) {
      _optionControllers.add(
        TextEditingController(
          text: option.optionText,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD SUBMITTER
  // ---------------------------------------------------------------------------

  Future<void> _loadSubmitterData() async {
    try {
      final users =
      await _userService.getAllUsers();

      final submitter = users.firstWhere(
            (user) =>
        user.userId ==
            _question.createdBy,
        orElse: () => throw Exception(
          'Submitter information was not found.',
        ),
      );

      final questions =
      await _questionService
          .getQuestionsByCreator(
        _question.createdBy,
      );

      if (!mounted) return;

      setState(() {
        _submitter = submitter;
        _submitterQuestions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to load submitter information.\n$e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // QUESTION STATUS
  // ---------------------------------------------------------------------------

  String _statusLabel(
      QuestionStatus status,
      ) {
    switch (status) {
      case QuestionStatus.pending:
        return 'Pending';

      case QuestionStatus.approved:
        return 'Approved';

      case QuestionStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(
      QuestionStatus status,
      ) {
    switch (status) {
      case QuestionStatus.pending:
        return Colors.orange.shade700;

      case QuestionStatus.approved:
        return Colors.green.shade700;

      case QuestionStatus.rejected:
        return Colors.red.shade700;
    }
  }

  Color _statusBackground(
      QuestionStatus status,
      ) {
    switch (status) {
      case QuestionStatus.pending:
        return Colors.orange.shade50;

      case QuestionStatus.approved:
        return Colors.green.shade50;

      case QuestionStatus.rejected:
        return Colors.red.shade50;
    }
  }

  // ---------------------------------------------------------------------------
  // QUESTION TYPE
  // ---------------------------------------------------------------------------

  String _questionTypeLabel(
      QuestionType type,
      ) {
    switch (type) {
      case QuestionType.multiple:
        return 'Multiple Choice';

      case QuestionType.trueFalse:
        return 'True / False';

      case QuestionType.written:
        return 'Written';
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD UPDATED QUESTION
  // ---------------------------------------------------------------------------

  Question _buildUpdatedQuestion() {
    final options = <QuestionOption>[];

    for (int i = 0;
    i < _optionControllers.length;
    i++) {
      final oldOption = _question.options[i];

      options.add(
        QuestionOption(
          optionId: oldOption.optionId,
          optionText:
          _optionControllers[i].text.trim(),
        ),
      );
    }

    final marks =
        double.tryParse(
          _marksController.text.trim(),
        ) ??
            _question.marks;

    final difficulty =
    DifficultyLevel.values.firstWhere(
          (value) =>
      value.name ==
          _selectedDifficulty,
      orElse: () =>
      DifficultyLevel.medium,
    );

    return Question(
      questionId: _question.questionId,
      questionDescription:
      _questionController.text.trim(),
      programId: _question.programId,
      subjectId: _question.subjectId,
      topicId: _question.topicId,
      questionType: _question.questionType,
      difficulty: difficulty,
      options: options,
      correctAnswers:
      _question.correctAnswers,
      writtenAssessment:
      _question.writtenAssessment,
      marks: marks,
      createdBy: _question.createdBy,
      status: _question.status,
      approvedBy: _question.approvedBy,
      approvedAt: _question.approvedAt,
      createdAt: _question.createdAt,
      updatedAt: _question.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE CORRECTION
  // ---------------------------------------------------------------------------

  Future<bool> _saveCorrection({
    bool showMessage = true,
  }) async {
    if (_isSaving) return false;

    final description =
    _questionController.text.trim();

    if (description.isEmpty) {
      _showMessage(
        'Question description cannot be empty.',
        isError: true,
      );
      return false;
    }

    final marks =
    double.tryParse(
      _marksController.text.trim(),
    );

    if (marks == null || marks <= 0) {
      _showMessage(
        'Please enter valid marks greater than zero.',
        isError: true,
      );
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedQuestion =
      _buildUpdatedQuestion();

      await _questionService
          .updatePendingQuestion(
        updatedQuestion,
      );

      if (!mounted) return false;

      setState(() {
        _question = updatedQuestion;
      });

      if (showMessage) {
        _showMessage(
          'Question correction saved successfully.',
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Failed to save correction.\n$e',
          isError: true,
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // APPROVE
  // ---------------------------------------------------------------------------

  Future<void> _approveQuestion() async {
    final confirmed =
    await _showConfirmationDialog(
      title: 'Approve Question',
      message:
      'The question will be approved and '
          'made available for use.',
      confirmText: 'Approve',
    );

    if (!confirmed) return;

    final saved =
    await _saveCorrection(
      showMessage: false,
    );

    if (!saved) return;

    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _showMessage(
        'No authenticated admin user found.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _questionService.approveQuestion(
        questionId: _question.questionId,
        adminUserId: firebaseUser.uid,
      );

      if (!mounted) return;

      _showMessage(
        'Question corrected and approved successfully.',
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Failed to approve question.\n$e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // REJECT
  // ---------------------------------------------------------------------------

  Future<void> _rejectQuestion() async {
    final confirmed =
    await _showConfirmationDialog(
      title: 'Reject Question',
      message:
      'Are you sure you want to reject '
          'this question?',
      confirmText: 'Reject',
      destructive: true,
    );

    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _questionService.rejectQuestion(
        _question.questionId,
      );

      if (!mounted) return;

      _showMessage(
        'Question rejected successfully.',
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Failed to reject question.\n$e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIVATE / DEACTIVATE USER
  // ---------------------------------------------------------------------------

  Future<void> _toggleSubmitterStatus() async {
    final user = _submitter;

    if (user == null) return;

    final newStatus = !user.isActive;

    final confirmed =
    await _showConfirmationDialog(
      title: newStatus
          ? 'Activate User'
          : 'Deactivate User',
      message: newStatus
          ? 'This user will be allowed to use '
          'the system again.'
          : 'This user will be deactivated. '
          'They will no longer be able to '
          'use the system normally.',
      confirmText:
      newStatus ? 'Activate' : 'Deactivate',
      destructive: !newStatus,
    );

    if (!confirmed) return;

    try {
      await _userService.updateUser(
        userId: user.userId,
        username: user.username,
        displayName: user.displayName,
        mobileNumber: user.mobileNumber,
        role: user.role,
        isActive: newStatus,
      );

      if (!mounted) return;

      setState(() {
        _submitter = AppUser(
          userId: user.userId,
          username: user.username,
          email: user.email,
          displayName: user.displayName,
          mobileNumber: user.mobileNumber,
          photoUrl: user.photoUrl,
          role: user.role,
          isActive: newStatus,
          createdAt: user.createdAt,
        );
      });

      _showMessage(
        newStatus
            ? 'User activated successfully.'
            : 'User deactivated successfully.',
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Failed to update user status.\n$e',
          isError: true,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CONFIRMATION DIALOG
  // ---------------------------------------------------------------------------

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) async {
    final result =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                backgroundColor:
                Colors.red.shade700,
              )
                  : null,
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red.shade700 : null,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // QUESTION INFORMATION
  // ---------------------------------------------------------------------------

  Widget _buildQuestionInformation() {
    return Card(
      elevation: 1.5,
      shadowColor:
      Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.help_outline_rounded,
              title: 'Question',
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: _questionController,
              maxLines: 7,
              decoration:
              InputDecoration(
                labelText:
                'Question description',
                alignLabelWithHint: true,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            LayoutBuilder(
              builder:
                  (context, constraints) {
                final compact =
                    constraints.maxWidth <
                        550;

                final difficulty =
                DropdownButtonFormField<
                    String>(
                  initialValue:
                  _selectedDifficulty,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Difficulty',
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'easy',
                      child: Text('Easy'),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child:
                      Text('Medium'),
                    ),
                    DropdownMenuItem(
                      value: 'hard',
                      child: Text('Hard'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedDifficulty =
                          value;
                    });
                  },
                );

                final marks =
                TextFormField(
                  controller:
                  _marksController,
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                  decoration:
                  InputDecoration(
                    labelText: 'Marks',
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    children: [
                      difficulty,
                      const SizedBox(
                        height: 12,
                      ),
                      marks,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: difficulty,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    SizedBox(
                      width: 180,
                      child: marks,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPTIONS
  // ---------------------------------------------------------------------------

  Widget _buildOptionsSection() {
    if (_question.questionType ==
        QuestionType.written) {
      return _buildWrittenAssessment();
    }

    return Card(
      elevation: 1.5,
      shadowColor:
      Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon:
              Icons.format_list_bulleted_rounded,
              title: 'Answer Options',
            ),

            const SizedBox(height: 16),

            ...List.generate(
              _optionControllers.length,
                  (index) {
                final option =
                _question.options[index];

                final isCorrect =
                _question.correctAnswers
                    .contains(
                  option.optionId,
                );

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 42,
                        alignment:
                        Alignment.center,
                        decoration:
                        BoxDecoration(
                          color:
                          isCorrect
                              ? Colors
                              .green
                              .shade50
                              : Colors
                              .grey
                              .shade100,
                          borderRadius:
                          BorderRadius
                              .circular(
                            9,
                          ),
                        ),
                        child: Text(
                          String.fromCharCode(
                            65 + index,
                          ),
                          style: TextStyle(
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            isCorrect
                                ? Colors
                                .green
                                .shade800
                                : Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child:
                        TextFormField(
                          controller:
                          _optionControllers[
                          index],
                          minLines: 1,
                          maxLines: 3,
                          decoration:
                          InputDecoration(
                            labelText:
                            'Option ${String.fromCharCode(65 + index)}',
                            suffixIcon:
                            isCorrect
                                ? Tooltip(
                              message:
                              'Correct answer',
                              child:
                              Icon(
                                Icons
                                    .check_circle,
                                color: Colors
                                    .green
                                    .shade700,
                              ),
                            )
                                : null,
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (_question.correctAnswers
                .isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Current correct answer(s): '
                    '${_question.correctAnswers.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Colors.green.shade700,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WRITTEN ASSESSMENT
  // ---------------------------------------------------------------------------

  Widget _buildWrittenAssessment() {
    final assessment =
        _question.writtenAssessment;

    if (assessment == null) {
      return Card(
        elevation: 1.5,
        child: Padding(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                icon:
                Icons.edit_note_rounded,
                title:
                'Written Assessment',
              ),
              const SizedBox(height: 12),
              Text(
                'No written assessment '
                    'configuration has been defined.',
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1.5,
      shadowColor:
      Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon:
              Icons.edit_note_rounded,
              title:
              'Written Assessment',
            ),

            const SizedBox(height: 16),

            _buildDetailRow(
              'Assessment type',
              assessment
                  .assessmentType.name,
            ),

            const SizedBox(height: 12),

            const Text(
              'Reference Answer',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(14),
              decoration:
              BoxDecoration(
                color:
                Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
                border: Border.all(
                  color:
                  Colors.grey.shade200,
                ),
              ),
              child: Text(
                assessment.referenceAnswer
                    .isEmpty
                    ? 'No reference answer.'
                    : assessment
                    .referenceAnswer,
                style: const TextStyle(
                  height: 1.5,
                ),
              ),
            ),

            if (assessment
                .criteria.isNotEmpty) ...[
              const SizedBox(height: 18),

              const Text(
                'Assessment Criteria',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              ...assessment.criteria
                  .map(
                    (criterion) =>
                    Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .check_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              criterion
                                  .criterion,
                            ),
                          ),
                          Text(
                            '${criterion.marks} marks',
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMITTER INFORMATION
  // ---------------------------------------------------------------------------

  Widget _buildSubmitterSection() {
    final user = _submitter;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final pending =
        _submitterQuestions
            .where(
              (question) =>
          question.status ==
              QuestionStatus.pending,
        )
            .length;

    final approved =
        _submitterQuestions
            .where(
              (question) =>
          question.status ==
              QuestionStatus.approved,
        )
            .length;

    final rejected =
        _submitterQuestions
            .where(
              (question) =>
          question.status ==
              QuestionStatus.rejected,
        )
            .length;

    return Card(
      elevation: 1.5,
      shadowColor:
      Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon:
              Icons.person_outline_rounded,
              title:
              'Submitted By',
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                  Colors.blue.shade50,
                  child: Icon(
                    Icons.person_rounded,
                    size: 32,
                    color:
                    Colors.blue.shade800,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        user.displayName,
                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildActiveBadge(
                  user.isActive,
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 14),

            _buildDetailRow(
              'Email',
              user.email.isEmpty
                  ? 'Not available'
                  : user.email,
            ),

            const SizedBox(height: 10),

            _buildDetailRow(
              'Mobile',
              user.mobileNumber ??
                  'Not available',
            ),

            const SizedBox(height: 18),

            const Text(
              'Question History',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child:
                  _buildHistoryCount(
                    'Pending',
                    pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                  _buildHistoryCount(
                    'Approved',
                    approved,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                  _buildHistoryCount(
                    'Rejected',
                    rejected,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                _toggleSubmitterStatus,
                icon: Icon(
                  user.isActive
                      ? Icons
                      .person_off_outlined
                      : Icons
                      .person_add_alt_1_outlined,
                ),
                label: Text(
                  user.isActive
                      ? 'Deactivate Examinee'
                      : 'Activate Examinee',
                ),
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  user.isActive
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                  side: BorderSide(
                    color: user.isActive
                        ? Colors.red.shade300
                        : Colors.green.shade300,
                  ),
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBadge(
      bool isActive,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive
              ? Colors.green.shade700
              : Colors.red.shade700,
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHistoryCount(
      String label,
      int count,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius:
            BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade800,
            size: 21,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 13,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACTION BAR
  // ---------------------------------------------------------------------------

  Widget _buildActionBar() {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        24,
        14,
        24,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 10,
            offset:
            const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final compact =
                constraints.maxWidth <
                    650;

            final saveButton =
            OutlinedButton.icon(
              onPressed:
              _isSaving
                  ? null
                  : () =>
                  _saveCorrection(),
              icon: const Icon(
                Icons.save_outlined,
              ),
              label:
              const Text('Save Correction'),
            );

            final rejectButton =
            OutlinedButton.icon(
              onPressed:
              _isSaving
                  ? null
                  : _rejectQuestion,
              icon: const Icon(
                Icons.close_rounded,
              ),
              label:
              const Text('Reject'),
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                Colors.red.shade700,
                side: BorderSide(
                  color:
                  Colors.red.shade300,
                ),
              ),
            );

            final approveButton =
            FilledButton.icon(
              onPressed:
              _isSaving
                  ? null
                  : _approveQuestion,
              icon: const Icon(
                Icons.check_rounded,
              ),
              label:
              const Text(
                'Correct & Approve',
              ),
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Colors.green.shade700,
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  saveButton,
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                        rejectButton,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                        approveButton,
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                saveButton,

                const Spacer(),

                rejectButton,

                const SizedBox(
                  width: 10,
                ),

                approveButton,
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING / ERROR
  // ---------------------------------------------------------------------------

  Widget _buildLoading() {
    return const Center(
      child:
      CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(32),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color:
              Colors.red.shade400,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Unable to load question details',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w600,
              ),
              textAlign:
              TextAlign.center,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            FilledButton.icon(
              onPressed:
              _loadSubmitterData,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Colors.grey.shade50,

      appBar: AppBar(
        title: const Text(
          'Pending Question Assess',
          style: TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),
        backgroundColor:
        Colors.white,
        foregroundColor:
        Colors.blue.shade900,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,

        actions: [
          if (!_isLoading)
            Padding(
              padding:
              const EdgeInsets.only(
                right: 16,
              ),
              child: Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  _statusBackground(
                    _question.status,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  _statusLabel(
                    _question.status,
                  ),
                  style: TextStyle(
                    color:
                    _statusColor(
                      _question.status,
                    ),
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : Column(
        children: [
          Expanded(
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets
                  .fromLTRB(
                24,
                24,
                24,
                120,
              ),
              child:
              LayoutBuilder(
                builder: (
                    context,
                    constraints,
                    ) {
                  final wide =
                      constraints
                          .maxWidth >=
                          950;

                  final questionColumn =
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                    children: [
                      _buildQuestionInformation(),

                      const SizedBox(
                        height: 16,
                      ),

                      _buildOptionsSection(),
                    ],
                  );

                  final userColumn =
                  _buildSubmitterSection();

                  if (wide) {
                    return Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Expanded(
                          flex: 3,
                          child:
                          questionColumn,
                        ),

                        const SizedBox(
                          width: 18,
                        ),

                        Expanded(
                          flex: 2,
                          child:
                          userColumn,
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                    children: [
                      questionColumn,

                      const SizedBox(
                        height: 18,
                      ),

                      userColumn,
                    ],
                  );
                },
              ),
            ),
          ),

          _buildActionBar(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();

    for (final controller
    in _optionControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}