import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:questionbank/models/app_user.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/screens/admin/pending_question_assess_screen.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/services/user_service.dart';

class QuestionFromOthersScreen extends StatefulWidget {
  const QuestionFromOthersScreen({super.key});

  @override
  State<QuestionFromOthersScreen> createState() =>
      _QuestionFromOthersScreenState();
}

class _QuestionFromOthersScreenState
    extends State<QuestionFromOthersScreen> {
  final QuestionService _questionService = QuestionService();
  final UserService _userService = UserService();

  List<Question> _allQuestions = [];
  List<AppUser> _users = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _statusFilter = 'All';
  String _sortOrder = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('No authenticated user found.');
      }

      final results = await Future.wait([
        _questionService.getQuestionsFromOthers(currentUser.uid),
        _userService.getAllUsers(),
      ]);

      if (!mounted) return;

      setState(() {
        _allQuestions = results[0] as List<Question>;
        _users = results[1] as List<AppUser>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Question> get _filteredQuestions {
    List<Question> questions = List<Question>.from(_allQuestions);

    switch (_statusFilter) {
      case 'Pending':
        questions = questions
            .where(
              (question) =>
          question.status == QuestionStatus.pending,
        )
            .toList();
        break;

      case 'Approved':
        questions = questions
            .where(
              (question) =>
          question.status == QuestionStatus.approved,
        )
            .toList();
        break;

      case 'Rejected':
        questions = questions
            .where(
              (question) =>
          question.status == QuestionStatus.rejected,
        )
            .toList();
        break;

      case 'All':
      default:
        break;
    }

    questions.sort(
          (a, b) {
        if (_sortOrder == 'Newest') {
          return b.createdAt.compareTo(a.createdAt);
        } else {
          return a.createdAt.compareTo(b.createdAt);
        }
      },
    );

    return questions;
  }

  AppUser? _findCreator(String userId) {
    for (final user in _users) {
      if (user.userId == userId) {
        return user;
      }
    }

    return null;
  }

  int _countByStatus(QuestionStatus status) {
    return _allQuestions
        .where((question) => question.status == status)
        .length;
  }

  String _statusText(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return 'Pending';
      case QuestionStatus.approved:
        return 'Approved';
      case QuestionStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return Colors.orange;
      case QuestionStatus.approved:
        return Colors.green;
      case QuestionStatus.rejected:
        return Colors.red;
    }
  }

  String _questionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.multiple:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.written:
        return 'Written';
    }
  }

  String _difficultyText(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitterInfo(AppUser? user, Question question) {
    final displayName =
    user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : user?.username.trim().isNotEmpty == true
        ? user!.username.trim()
        : 'Unknown user';

    final phone =
    user?.mobileNumber?.trim().isNotEmpty == true
        ? user!.mobileNumber!.trim()
        : 'Not available';

    final email =
    user?.email.trim().isNotEmpty == true
        ? user!.email.trim()
        : 'Not available';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: 'Submitted by: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: displayName,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: 'Phone: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: phone,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: 'Email: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: email,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (user == null) ...[
            const SizedBox(height: 6),
            Text(
              'User profile could not be found.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final creator = _findCreator(question.createdBy);
    final statusColor = _statusColor(question.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question description
            Text(
              question.questionDescription,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Status / type / difficulty / marks
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(question.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.category_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _questionTypeText(question.questionType),
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.speed_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _difficultyText(question.difficulty),
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.star_outline,
                    size: 16,
                  ),
                  label: Text(
                    '${question.marks} marks',
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _formatDate(question.createdAt),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Creator information
            _buildSubmitterInfo(
              creator,
              question,
            ),

            const SizedBox(height: 14),

            // Assess button for pending questions
            if (question.status == QuestionStatus.pending)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PendingQuestionAssessScreen(
                              question: question,
                            ),
                      ),
                    );

                    if (mounted) {
                      _loadData();
                    }
                  },
                  icon: const Icon(
                    Icons.rate_review_outlined,
                  ),
                  label: const Text(
                    'Assess',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: _statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: 'Pending',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: 'Approved',
                    child: Text('Approved'),
                  ),
                  DropdownMenuItem(
                    value: 'Rejected',
                    child: Text('Rejected'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
            ),

            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                initialValue: _sortOrder,
                decoration: const InputDecoration(
                  labelText: 'Sort',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Newest',
                    child: Text('Newest first'),
                  ),
                  DropdownMenuItem(
                    value: 'Oldest',
                    child: Text('Oldest first'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _sortOrder = value;
                  });
                },
              ),
            ),

            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _filteredQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Questions from Others',
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'All Questions',
                                count: _allQuestions.length,
                                icon: Icons.help_outline,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Pending',
                                count: _countByStatus(
                                  QuestionStatus.pending,
                                ),
                                icon:
                                Icons.pending_actions,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Approved',
                                count: _countByStatus(
                                  QuestionStatus.approved,
                                ),
                                icon:
                                Icons.check_circle_outline,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Rejected',
                                count: _countByStatus(
                                  QuestionStatus.rejected,
                                ),
                                icon:
                                Icons.cancel_outlined,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title: 'All Questions',
                                    count:
                                    _allQuestions.length,
                                    icon:
                                    Icons.help_outline,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title: 'Pending',
                                    count:
                                    _countByStatus(
                                      QuestionStatus
                                          .pending,
                                    ),
                                    icon: Icons
                                        .pending_actions,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title: 'Approved',
                                    count:
                                    _countByStatus(
                                      QuestionStatus
                                          .approved,
                                    ),
                                    icon: Icons
                                        .check_circle_outline,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title: 'Rejected',
                                    count:
                                    _countByStatus(
                                      QuestionStatus
                                          .rejected,
                                    ),
                                    icon:
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      _buildFilters(),

                      const SizedBox(height: 20),

                      if (questions.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons
                                        .question_mark_outlined,
                                    size: 48,
                                    color:
                                    Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No questions found.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...questions.map(
                          _buildQuestionCard,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}