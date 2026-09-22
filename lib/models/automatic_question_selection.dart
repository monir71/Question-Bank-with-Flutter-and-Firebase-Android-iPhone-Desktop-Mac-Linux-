enum DifficultySelectionMode {
  any,
  custom,
}

class DifficultyDistribution {
  final int easy;
  final int medium;
  final int hard;

  const DifficultyDistribution({
    this.easy = 0,
    this.medium = 0,
    this.hard = 0,
  });

  int get total => easy + medium + hard;

  Map<String, dynamic> toMap() {
    return {
      'easy': easy,
      'medium': medium,
      'hard': hard,
    };
  }

  factory DifficultyDistribution.fromMap(
      Map<String, dynamic> map,
      ) {
    return DifficultyDistribution(
      easy: (map['easy'] as num?)?.toInt() ?? 0,
      medium: (map['medium'] as num?)?.toInt() ?? 0,
      hard: (map['hard'] as num?)?.toInt() ?? 0,
    );
  }

  DifficultyDistribution copyWith({
    int? easy,
    int? medium,
    int? hard,
  }) {
    return DifficultyDistribution(
      easy: easy ?? this.easy,
      medium: medium ?? this.medium,
      hard: hard ?? this.hard,
    );
  }
}

class AutomaticQuestionSelection {
  final int questionCount;
  final DifficultySelectionMode difficultyMode;
  final DifficultyDistribution difficultyDistribution;
  final bool randomizeSelection;

  const AutomaticQuestionSelection({
    required this.questionCount,
    this.difficultyMode = DifficultySelectionMode.any,
    this.difficultyDistribution =
    const DifficultyDistribution(),
    this.randomizeSelection = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionCount': questionCount,
      'difficultyMode': difficultyMode.name,
      'difficultyDistribution':
      difficultyDistribution.toMap(),
      'randomizeSelection': randomizeSelection,
    };
  }

  factory AutomaticQuestionSelection.fromMap(
      Map<String, dynamic> map,
      ) {
    final distributionData =
    map['difficultyDistribution'];

    return AutomaticQuestionSelection(
      questionCount:
      (map['questionCount'] as num?)?.toInt() ?? 0,
      difficultyMode:
      DifficultySelectionMode.values.firstWhere(
            (value) => value.name == map['difficultyMode'],
        orElse: () => DifficultySelectionMode.any,
      ),
      difficultyDistribution:
      distributionData is Map
          ? DifficultyDistribution.fromMap(
        Map<String, dynamic>.from(
          distributionData,
        ),
      )
          : const DifficultyDistribution(),
      randomizeSelection:
      map['randomizeSelection'] as bool? ?? true,
    );
  }

  AutomaticQuestionSelection copyWith({
    int? questionCount,
    DifficultySelectionMode? difficultyMode,
    DifficultyDistribution? difficultyDistribution,
    bool? randomizeSelection,
  }) {
    return AutomaticQuestionSelection(
      questionCount:
      questionCount ?? this.questionCount,
      difficultyMode:
      difficultyMode ?? this.difficultyMode,
      difficultyDistribution:
      difficultyDistribution ??
          this.difficultyDistribution,
      randomizeSelection:
      randomizeSelection ?? this.randomizeSelection,
    );
  }
}