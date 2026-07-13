enum WeeklyActionType {
  scheduleFocusWindow,  // book protected time
  reduceOneTrigger,     // lower budget or flag one distraction for firm treatment
  moveTaskToEnergy,     // reschedule / re-energy a hard task
}

class WeeklyAction {
  final String id;
  final WeeklyActionType type;
  final String description;
  final String? targetApp;
  final int? startHour;
  final int? endHour;
  final int? weekday; // 1-7
  final String? taskId;

  const WeeklyAction({
    required this.id,
    required this.type,
    required this.description,
    this.targetApp,
    this.startHour,
    this.endHour,
    this.weekday,
    this.taskId,
  });
}
