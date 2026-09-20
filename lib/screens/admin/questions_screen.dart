import 'package:flutter/material.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';
import 'package:questionbank/services/topic_service.dart';

import 'add_question_dialog.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() =>
      _QuestionsScreenState();
}

class _QuestionsScreenState
    extends State<QuestionsScreen> {
  final QuestionService _questionService =
  QuestionService();

  final ProgramService _programService =
  ProgramService();

  final SubjectService _subjectService =
  SubjectService();

  final TopicService _topicService =
  TopicService();

  List<Question> _questions = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];
  List<Topic> _topics = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final results = await Future.wait([
        _questionService.getAllQuestions(),
        _programService.getAllPrograms(),
        _subjectService.getAllSubjects(),
        _topicService.getAllTopics(),
      ]);

      final questions = results[0] as List<Question>;
      final programs = results[1] as List<Program>;
      final subjects = results[2] as List<Subject>;
      final topics = results[3] as List<Topic>;

      if (!mounted) {
        return;
      }

      setState(() {
        _questions = questions;
        _programs = programs;
        _subjects = subjects;
        _topics = topics;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getProgramName(String programId) {
    final program = _programs.firstWhere(
          (item) => item.programId == programId,
      orElse: () => Program(
        programId: '',
        learningAreaId: '',
        name: 'Unknown',
        parentProgramId: null,
        isActive: false,
        sortOrder: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    return program.name;
  }

  String _getSubjectName(String subjectId) {
    final subject = _subjects.firstWhere(
          (item) => item.subjectId == subjectId,
      orElse: () => Subject(
        subjectId: '',
        programId: '',
        name: 'Unknown',
        isActive: false,
        sortOrder: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    return subject.name;
  }

  String _getTopicName(String topicId) {
    final topic = _topics.firstWhere(
          (item) => item.topicId == topicId,
      orElse: () => Topic(
        topicId: '',
        subjectId: '',
        name: 'Unknown',
        isActive: false,
        sortOrder: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    return topic.name;
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Failed to load questions.\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            12,
          ),
          child: Row(
            children: [
              const Text(
                'Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AddQuestionDialog(
                        programs: _programs,
                        subjects: _subjects,
                        topics: _topics,
                      );
                    },
                  );
                },
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Add Question',
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(
                  label: Text('Question'),
                ),
                DataColumn(
                  label: Text('Program'),
                ),
                DataColumn(
                  label: Text('Subject'),
                ),
                DataColumn(
                  label: Text('Topic'),
                ),
                DataColumn(
                  label: Text('Type'),
                ),
                DataColumn(
                  label: Text('Difficulty'),
                ),
                DataColumn(
                  label: Text('Marks'),
                ),
                DataColumn(
                  label: Text('Status'),
                ),
                DataColumn(
                  label: Text('Action'),
                ),
              ],
              rows: _questions.map((question) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 300,
                        child: Text(
                          question.questionDescription,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _getProgramName(
                          question.programId,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _getSubjectName(
                          question.subjectId,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _getTopicName(
                          question.topicId,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        question.questionType.name,
                      ),
                    ),
                    DataCell(
                      Text(
                        question.difficulty.name,
                      ),
                    ),
                    DataCell(
                      Text(
                        question.marks.toString(),
                      ),
                    ),
                    DataCell(
                      Text(
                        question.status.name,
                      ),
                    ),
                    const DataCell(
                      Text('-'),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}