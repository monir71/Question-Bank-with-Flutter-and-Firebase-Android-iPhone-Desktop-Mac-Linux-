import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';
import 'package:questionbank/services/subject_service.dart';
import 'package:questionbank/services/topic_service.dart';

import 'add_topic_dialog.dart';
import 'edit_topic_dialog.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() =>
      _TopicsScreenState();
}

class _TopicsScreenState
    extends State<TopicsScreen> {
  final TopicService _topicService =
  TopicService();

  final SubjectService _subjectService =
  SubjectService();

  List<Topic> _topics = [];
  List<Subject> _subjects = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final results = await Future.wait([
        _topicService.getAllTopics(),
        _subjectService.getAllSubjects(),
      ]);

      final topics =
      results[0] as List<Topic>;

      final subjects =
      results[1] as List<Subject>;

      if (!mounted) {
        return;
      }

      setState(() {
        _topics = topics;
        _subjects = subjects;
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

  String _getSubjectName(
      String subjectId,
      ) {
    final subject = _subjects.firstWhere(
          (subject) =>
      subject.subjectId == subjectId,
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

  Future<void> _showAddTopicDialog() async {
    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AddTopicDialog(
          subjects: _subjects,
        );
      },
    );

    if (result == null) {
      return;
    }

    final topicId = FirebaseFirestore
        .instance
        .collection('topics')
        .doc()
        .id;

    final topic = Topic(
      topicId: topicId,
      subjectId:
      result['subjectId'] as String,
      name:
      result['name'] as String,
      isActive: true,
      sortOrder:
      result['sortOrder'] as int,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _topicService.createTopic(
        topic,
      );

      await _loadTopics();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Topic created successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create topic: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showEditTopicDialog(
      Topic topic,
      ) async {
    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditTopicDialog(
          topic: topic,
          subjects: _subjects,
        );
      },
    );

    if (result == null) {
      return;
    }

    final updatedTopic = Topic(
      topicId: topic.topicId,
      subjectId:
      result['subjectId'] as String,
      name:
      result['name'] as String,
      isActive: topic.isActive,
      sortOrder:
      result['sortOrder'] as int,
      createdAt: topic.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _topicService.updateTopic(
        updatedTopic,
      );

      await _loadTopics();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Topic updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update topic: $e',
          ),
        ),
      );
    }
  }

  Future<void> _toggleTopicStatus(
      Topic topic,
      ) async {
    final newStatus = !topic.isActive;

    try {
      await _topicService.updateTopicStatus(
        topicId: topic.topicId,
        isActive: newStatus,
      );

      await _loadTopics();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Topic activated successfully.'
                : 'Topic deactivated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update topic status: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Topics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _showAddTopicDialog,
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Add Topic',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Failed to load topics:\n$_errorMessage',
          textAlign:
          TextAlign.center,
        ),
      );
    }

    if (_topics.isEmpty) {
      return const Center(
        child: Text(
          'No topics found.',
        ),
      );
    }

    return _buildTopicsList();
  }

  Widget _buildTopicsList() {
    return Column(
      children: [
        _buildHeader(),

        const Divider(
          height: 1,
        ),

        Expanded(
          child: ListView.builder(
            itemCount:
            _topics.length,
            itemBuilder:
                (context, index) {
              final topic =
              _topics[index];

              return _buildTopicRow(
                topic,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: Text(
            'Topic',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 3,
          child: Text(
            'Subject',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 2,
          child: Text(
            'Order',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 2,
          child: Text(
            'Status',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 1,
          child: Text(
            'Action',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicRow(
      Topic topic,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              topic.name,
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              _getSubjectName(
                topic.subjectId,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              topic.sortOrder
                  .toString(),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  topic.isActive
                      ? Icons
                      .check_circle_outline
                      : Icons
                      .cancel_outlined,
                  size: 18,
                  color:
                  topic.isActive
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  topic.isActive
                      ? 'Active'
                      : 'Inactive',
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  tooltip: topic.isActive
                      ? 'Deactivate'
                      : 'Activate',
                  icon: Icon(
                    topic.isActive
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                    color: topic.isActive
                        ? Colors.green
                        : Colors.grey,
                  ),
                  onPressed: () {
                    _toggleTopicStatus(topic);
                  },
                ),

                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(
                    Icons.edit,
                  ),
                  onPressed: () {
                    _showEditTopicDialog(topic);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}