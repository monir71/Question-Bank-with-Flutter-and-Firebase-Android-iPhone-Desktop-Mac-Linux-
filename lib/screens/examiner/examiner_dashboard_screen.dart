import 'package:flutter/material.dart';

import 'examiner_result_assessment_screen.dart';
import 'examiner_results_screen.dart';

class ExaminerDashboardScreen extends StatefulWidget {
  const ExaminerDashboardScreen({super.key});

  @override
  State<ExaminerDashboardScreen> createState() =>
      _ExaminerDashboardScreenState();
}

class _ExaminerDashboardScreenState extends State<ExaminerDashboardScreen> {
  int _selectedMenuIndex = 0;

  final List<_ExaminerMenuItem> _menuItems = const [
    _ExaminerMenuItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      title: 'Dashboard',
    ),
    _ExaminerMenuItem(
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      title: 'Exam Results',
    ),
    _ExaminerMenuItem(
      icon: Icons.rate_review_outlined,
      selectedIcon: Icons.rate_review_rounded,
      title: 'Pending Assessment',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examiner Dashboard'),
        centerTitle: false,
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(theme),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final selected = _selectedMenuIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: theme.colorScheme.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedMenuIndex = index;
                        });

                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Question Bank',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.assignment_ind_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Examiner Portal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review exams and assess answers',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_selectedMenuIndex) {
      case 1:
        return _buildResultsPlaceholder(context);
      case 2:
        return _buildPendingAssessmentPlaceholder(context);
      case 0:
      default:
        return _buildDashboard(context);
    }
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(theme),
                  const SizedBox(height: 24),
                  Text(
                    'Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSummaryCards(context, isWide),
                  const SizedBox(height: 28),
                  _buildQuickActions(context, isWide),
                  const SizedBox(height: 28),
                  _buildInformationCard(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          final textSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Examiner',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review and assess examination results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Review submitted answers, assess written '
                'questions, and finalize candidate results.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          );

          final icon = Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 38,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [textSection, const SizedBox(height: 20), icon],
            );
          }

          return Row(
            children: [
              Expanded(child: textSection),
              const SizedBox(width: 24),
              icon,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, bool isWide) {
    final cards = [
      _SummaryCardData(
        icon: Icons.assignment_rounded,
        title: 'Total Results',
        value: '0',
        subtitle: 'Submitted exam results',
        color: Colors.indigo,
      ),
      _SummaryCardData(
        icon: Icons.pending_actions_rounded,
        title: 'Pending Assessment',
        value: '0',
        subtitle: 'Written questions pending',
        color: Colors.orange,
      ),
      _SummaryCardData(
        icon: Icons.check_circle_outline_rounded,
        title: 'Completed',
        value: '0',
        subtitle: 'Fully assessed results',
        color: Colors.green,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _buildSummaryCard(card),
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSummaryCard(card),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isWide) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        if (isWide)
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.assignment_rounded,
                  title: 'Exam Results',
                  subtitle: 'Review submitted exam results',
                  color: Colors.indigo,
                  onTap: () {
                    setState(() {
                      _selectedMenuIndex = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.rate_review_rounded,
                  title: 'Pending Assessment',
                  subtitle: 'Assess written answers',
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      _selectedMenuIndex = 2;
                    });
                  },
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildActionCard(
                context,
                icon: Icons.assignment_rounded,
                title: 'Exam Results',
                subtitle: 'Review submitted exam results',
                color: Colors.indigo,
                onTap: () {
                  setState(() {
                    _selectedMenuIndex = 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                icon: Icons.rate_review_rounded,
                title: 'Pending Assessment',
                subtitle: 'Assess written answers',
                color: Colors.orange,
                onTap: () {
                  setState(() {
                    _selectedMenuIndex = 2;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examiner Workspace',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use the assessment workspace to review '
                  'candidate answers and award marks for '
                  'questions that require manual assessment.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPlaceholder(
      BuildContext context,
      ) {
    return const ExaminerResultsScreen();
  }

  Widget _buildPendingAssessmentPlaceholder(BuildContext context) {
    return _buildComingSoonPage(
      context,
      icon: Icons.rate_review_rounded,
      title: 'Pending Assessment',
      description:
          'Written questions requiring examiner assessment '
          'will appear here.',
    );
  }

  Widget _buildComingSoonPage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 38, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExaminerMenuItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;

  const _ExaminerMenuItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
  });
}

class _SummaryCardData {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryCardData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}
