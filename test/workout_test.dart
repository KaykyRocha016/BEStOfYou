import 'package:flutter_test/flutter_test.dart';
import 'package:gymlog/main.dart';

void main() {
  test('Workout converts to and from database map', () {
    final date = DateTime(2026, 6, 2);
    final workout = Workout(
      id: 1,
      title: 'Treino A',
      muscleGroup: 'Peito e triceps',
      workoutDate: date,
      durationMinutes: 60,
      exercises: 'Supino, crucifixo, triceps corda',
      maxLoadKg: 70,
      notes: 'Treino completo',
    );

    final copy = Workout.fromMap(workout.toMap());

    expect(copy.id, 1);
    expect(copy.title, 'Treino A');
    expect(copy.muscleGroup, 'Peito e triceps');
    expect(copy.workoutDate, date);
    expect(copy.durationMinutes, 60);
    expect(copy.exercises, 'Supino, crucifixo, triceps corda');
    expect(copy.maxLoadKg, 70);
    expect(copy.notes, 'Treino completo');
  });
}
