import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDatabaseFactory();
  runApp(const GymLogApp());
}

class GymLogApp extends StatelessWidget {
  const GymLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D7A66),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F4),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const WorkoutListPage(),
    );
  }
}

class Workout {
  const Workout({
    this.id,
    required this.title,
    required this.muscleGroup,
    required this.workoutDate,
    required this.durationMinutes,
    required this.exercises,
    required this.maxLoadKg,
    required this.notes,
  });

  final int? id;
  final String title;
  final String muscleGroup;
  final DateTime workoutDate;
  final int durationMinutes;
  final String exercises;
  final double maxLoadKg;
  final String notes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'muscle_group': muscleGroup,
      'workout_date': workoutDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'exercises': exercises,
      'max_load_kg': maxLoadKg,
      'notes': notes,
    };
  }

  factory Workout.fromMap(Map<String, Object?> map) {
    return Workout(
      id: map['id'] as int?,
      title: map['title'] as String,
      muscleGroup: map['muscle_group'] as String,
      workoutDate: DateTime.parse(map['workout_date'] as String),
      durationMinutes: map['duration_minutes'] as int,
      exercises: map['exercises'] as String,
      maxLoadKg: (map['max_load_kg'] as num).toDouble(),
      notes: map['notes'] as String,
    );
  }
}

class WorkoutDatabase {
  WorkoutDatabase._();

  static final WorkoutDatabase instance = WorkoutDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'gymlog.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            muscle_group TEXT NOT NULL,
            workout_date TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            exercises TEXT NOT NULL,
            max_load_kg REAL NOT NULL,
            notes TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final rows = await db.query(
      'workouts',
      orderBy: 'workout_date DESC, id DESC',
    );

    return rows.map(Workout.fromMap).toList();
  }

  Future<void> insertWorkout(Workout workout) async {
    final db = await database;
    await db.insert('workouts', workout.toMap());
  }

  Future<void> deleteWorkout(int id) async {
    final db = await database;
    await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class WorkoutListPage extends StatefulWidget {
  const WorkoutListPage({super.key});

  @override
  State<WorkoutListPage> createState() => _WorkoutListPageState();
}

class _WorkoutListPageState extends State<WorkoutListPage> {
  late Future<List<Workout>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    _workoutsFuture = WorkoutDatabase.instance.getWorkouts();
  }

  Future<void> _openCreatePage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WorkoutFormPage()),
    );

    if (created == true) {
      setState(_loadWorkouts);
    }
  }

  Future<void> _openDetailsPage(Workout workout) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailsPage(workout: workout),
      ),
    );

    if (deleted == true) {
      setState(_loadWorkouts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GymLog'),
        actions: [
          IconButton(
            tooltip: 'Novo treino',
            onPressed: _openCreatePage,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Workout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nao foi possivel carregar os treinos.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return EmptyWorkoutState(onCreate: _openCreatePage);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadWorkouts);
              await _workoutsFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return WorkoutCard(
                  workout: workout,
                  onTap: () => _openDetailsPage(workout),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePage,
        icon: const Icon(Icons.fitness_center),
        label: const Text('Registrar'),
      ),
    );
  }
}

class EmptyWorkoutState extends StatelessWidget {
  const EmptyWorkoutState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino registrado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione seu primeiro treino para acompanhar sua evolucao.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Novo treino'),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
  });

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(workout.workoutDate);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      workout.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${workout.muscleGroup} | $date',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip(
                    icon: Icons.timer_outlined,
                    label: '${workout.durationMinutes} min',
                  ),
                  InfoChip(
                    icon: Icons.scale_outlined,
                    label: '${workout.maxLoadKg.toStringAsFixed(1)} kg',
                  ),
                  InfoChip(
                    icon: Icons.list_alt_outlined,
                    label: workout.exercises,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class WorkoutFormPage extends StatefulWidget {
  const WorkoutFormPage({super.key});

  @override
  State<WorkoutFormPage> createState() => _WorkoutFormPageState();
}

class _WorkoutFormPageState extends State<WorkoutFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _durationController = TextEditingController();
  final _exercisesController = TextEditingController();
  final _maxLoadController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _muscleGroupController.dispose();
    _durationController.dispose();
    _exercisesController.dispose();
    _maxLoadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final workout = Workout(
      title: _titleController.text.trim(),
      muscleGroup: _muscleGroupController.text.trim(),
      workoutDate: _selectedDate,
      durationMinutes: int.parse(_durationController.text.trim()),
      exercises: _exercisesController.text.trim(),
      maxLoadKg:
          double.parse(_maxLoadController.text.trim().replaceAll(',', '.')),
      notes: _notesController.text.trim(),
    );

    await WorkoutDatabase.instance.insertWorkout(workout);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo treino')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome do treino',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _muscleGroupController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Grupo muscular',
                  prefixIcon: Icon(Icons.accessibility_new),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text('Data: $dateLabel'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Duracao em minutos',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: _positiveIntValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _exercisesController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Exercicios realizados',
                  prefixIcon: Icon(Icons.list_alt),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxLoadController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Maior carga usada (kg)',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
                validator: _positiveDoubleValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Observacoes',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _saveWorkout,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Salvando...' : 'Salvar treino'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }

    return null;
  }

  static String? _positiveIntValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Digite um numero inteiro maior que zero';
    }

    return null;
  }

  static String? _positiveDoubleValidator(String? value) {
    final normalized = value?.trim().replaceAll(',', '.') ?? '';
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return 'Digite um numero maior que zero';
    }

    return null;
  }
}

class WorkoutDetailsPage extends StatelessWidget {
  const WorkoutDetailsPage({super.key, required this.workout});

  final Workout workout;

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir treino?'),
          content: Text(
            'Deseja excluir "${workout.title}" do seu historico?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || workout.id == null) {
      return;
    }

    await WorkoutDatabase.instance.deleteWorkout(workout.id!);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Treino excluido com sucesso.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(workout.workoutDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do treino'),
        actions: [
          IconButton(
            tooltip: 'Excluir treino',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            workout.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${workout.muscleGroup} | $date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          DetailTile(
            icon: Icons.timer_outlined,
            label: 'Duracao',
            value: '${workout.durationMinutes} minutos',
          ),
          DetailTile(
            icon: Icons.scale_outlined,
            label: 'Maior carga',
            value: '${workout.maxLoadKg.toStringAsFixed(1)} kg',
          ),
          DetailTile(
            icon: Icons.list_alt,
            label: 'Exercicios',
            value: workout.exercises,
          ),
          DetailTile(
            icon: Icons.notes_outlined,
            label: 'Observacoes',
            value: workout.notes,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir treino'),
          ),
        ],
      ),
    );
  }
}

class DetailTile extends StatelessWidget {
  const DetailTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
