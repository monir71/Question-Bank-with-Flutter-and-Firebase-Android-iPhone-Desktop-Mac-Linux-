import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/services/exam_attempt_service.dart';

import 'exam_attempt_screen.dart';

class ExamineeExamDetailsScreen extends StatefulWidget {
  final Exam exam;
  final Program? program;
  final List<Subject> subjects;

  const ExamineeExamDetailsScreen({
    super.key,
    required this.exam,
    required this.program,
    required this.subjects,
  });

  @override
  State<ExamineeExamDetailsScreen> createState() =>
      _ExamineeExamDetailsScreenState();
}

class _ExamineeExamDetailsScreenState
    extends State<ExamineeExamDetailsScreen> {
  final ExamAttemptService _attemptService =
  ExamAttemptService();

  bool _isStartingExam = false;

  String _formatMarks(double marks) {
    if (marks == marks.roundToDouble()) {
      return marks.toInt().toString();
    }

    return marks.toStringAsFixed(1);
  }

  String _formatPercentage(double percentage) {
    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toInt()}%';
    }

    return '${percentage.toStringAsFixed(1)}%';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$hours ${hours == 1 ? 'hour' : 'hours'} '
        '$remainingMinutes minutes';
  }

  Future<void> _startExam() async {
    if (_isStartingExam) {
      return;
    }

    final firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _showMessage(
        'You are not logged in. Please log in again.',
      );
      return;
    }

    if (widget.exam.questions.isEmpty) {
      _showMessage(
        'This exam does not have any questions yet.',
      );
      return;
    }

    setState(() {
      _isStartingExam = true;
    });

    try {
      final attempt =
      await _attemptService.createNewAttempt(
        exam: widget.exam,
        userId: firebaseUser.uid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isStartingExam = false;
      });

      _showAttemptCreatedMessage(attempt);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isStartingExam = false;
      });

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAttemptCreatedMessage(
      ExamAttempt attempt,
      ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          return ExamAttemptScreen(
            exam: widget.exam,
            attempt: attempt,
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.indigo,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: Colors.indigo,
              ),
              SizedBox(width: 9),
              Text(
                'Subjects',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (widget.subjects.isEmpty)
            Text(
              'All subjects',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.subjects.map((subject) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                    Colors.indigo.withValues(alpha: 0.07),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    subject.name,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.indigo,
              ),
              SizedBox(width: 9),
              Text(
                'Before You Start',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInstruction(
            icon: Icons.timer_outlined,
            text:
            'You will have ${_formatDuration(widget.exam.durationMinutes)} '
                'to complete this examination.',
          ),
          _buildInstruction(
            icon: Icons.quiz_outlined,
            text:
            'The examination contains '
                '${widget.exam.questionCount} questions.',
          ),
          _buildInstruction(
            icon: Icons.star_outline_rounded,
            text:
            'The total marks for this examination are '
                '${_formatMarks(widget.exam.totalMarks)}.',
          ),
          _buildInstruction(
            icon: Icons.flag_outlined,
            text:
            'The passing requirement is '
                '${_formatPercentage(widget.exam.passPercentage)}.',
          ),
          _buildInstruction(
            icon: Icons.shuffle_outlined,
            text: widget.exam.randomizeQuestions
                ? 'Questions may appear in a different order.'
                : 'Questions will appear in their configured order.',
          ),
          _buildInstruction(
            icon: Icons.list_alt_outlined,
            text: widget.exam.randomizeOptions
                ? 'Answer options may appear in a different order.'
                : 'Answer options will appear in their configured order.',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Once the examination begins, the timer '
                        'will start running.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
            _isStartingExam ? null : _startExam,
            icon: _isStartingExam
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(
              Icons.play_arrow_rounded,
            ),
            label: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                _isStartingExam
                    ? 'Starting Exam...'
                    : 'Start Exam',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _isStartingExam
              ? null
              : () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Text(
          'Exam Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1000,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade700,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color:
                                Colors.white.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  15,
                                ),
                              ),
                              child: const Icon(
                                Icons.assignment_rounded,
                                color: Colors.white,
                                size: 29,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    widget.exam.examName,
                                    style:
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.program !=
                                      null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.program!.name,
                                      style:
                                      const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                Colors.white.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (widget.exam.description
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            widget.exam.description,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder:
                        (context, constraints) {
                      final isWide =
                          constraints.maxWidth >= 700;

                      final cards = [
                        _buildInfoCard(
                          icon: Icons.quiz_outlined,
                          label: 'Questions',
                          value:
                          '${widget.exam.questionCount}',
                        ),
                        _buildInfoCard(
                          icon:
                          Icons.star_outline_rounded,
                          label: 'Total Marks',
                          value: _formatMarks(
                            widget.exam.totalMarks,
                          ),
                        ),
                        _buildInfoCard(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: _formatDuration(
                            widget.exam.durationMinutes,
                          ),
                        ),
                        _buildInfoCard(
                          icon: Icons.flag_outlined,
                          label: 'Pass Percentage',
                          value: _formatPercentage(
                            widget.exam.passPercentage,
                          ),
                        ),
                      ];

                      if (!isWide) {
                        return Column(
                          children: cards
                              .map(
                                (card) => Padding(
                              padding:
                              const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: card,
                            ),
                          )
                              .toList(),
                        );
                      }

                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 3.2,
                        children: cards,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSubjectsCard(),
                  const SizedBox(height: 20),
                  _buildInstructionsCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}