import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(const BestOfYouApp());
}

// ============================================================
// APP
// ============================================================

class BestOfYouApp extends StatelessWidget {
  const BestOfYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEStOfYou',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A5F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TreinoList(),
    );
  }
}

// ============================================================
// MODEL — Treino
// ============================================================

class Treino {
  int? _id;
  String _exercicio;
  int _series;
  int _repeticoes;
  double _carga;
  int _grupoMuscular; // 1=Peito 2=Costas 3=Pernas 4=Ombro 5=Biceps/Triceps
  String _data;

  Treino(this._exercicio, this._series, this._repeticoes, this._carga,
      this._grupoMuscular, this._data);

  Treino.withId(this._id, this._exercicio, this._series, this._repeticoes,
      this._carga, this._grupoMuscular, this._data);

  int? get id => _id;
  String get exercicio => _exercicio;
  int get series => _series;
  int get repeticoes => _repeticoes;
  double get carga => _carga;
  int get grupoMuscular => _grupoMuscular;
  String get data => _data;

  set exercicio(String value) {
    if (value.isNotEmpty && value.length <= 100) _exercicio = value;
  }
  set series(int value) {
    if (value > 0 && value <= 20) _series = value;
  }
  set repeticoes(int value) {
    if (value > 0 && value <= 100) _repeticoes = value;
  }
  set carga(double value) {
    if (value >= 0) _carga = value;
  }
  set grupoMuscular(int value) {
    if (value >= 1 && value <= 5) _grupoMuscular = value;
  }
  set data(String value) => _data = value;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'exercicio': _exercicio,
      'series': _series,
      'repeticoes': _repeticoes,
      'carga': _carga,
      'grupoMuscular': _grupoMuscular,
      'data': _data,
    };
    if (_id != null) map['id'] = _id;
    return map;
  }

  Treino.fromMap(Map<String, dynamic> map)
      : _id = map['id'],
        _exercicio = map['exercicio'],
        _series = map['series'],
        _repeticoes = map['repeticoes'],
        _carga = map['carga'],
        _grupoMuscular = map['grupoMuscular'],
        _data = map['data'];

  static String nomeGrupo(int grupo) {
    switch (grupo) {
      case 1: return 'Peito';
      case 2: return 'Costas';
      case 3: return 'Pernas';
      case 4: return 'Ombro';
      case 5: return 'Biceps/Triceps';
      default: return 'Outro';
    }
  }
}

// ============================================================
// DB HELPER — Singleton + CRUD SQLite
// ============================================================

class DbHelper {
  static const String tblTreino = 'treino';
  static const String colId = 'id';
  static const String colExercicio = 'exercicio';
  static const String colSeries = 'series';
  static const String colRepeticoes = 'repeticoes';
  static const String colCarga = 'carga';
  static const String colGrupo = 'grupoMuscular';
  static const String colData = 'data';

  DbHelper._internal();
  static final DbHelper _dbHelper = DbHelper._internal();
  factory DbHelper() => _dbHelper;

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initializeDb();
    return _db!;
  }

  Future<Database> _initializeDb() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/bestofyou.db';
    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute('''
      CREATE TABLE $tblTreino(
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colExercicio TEXT NOT NULL,
        $colSeries INTEGER NOT NULL,
        $colRepeticoes INTEGER NOT NULL,
        $colCarga REAL NOT NULL,
        $colGrupo INTEGER NOT NULL,
        $colData TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTreino(Treino treino) async {
    Database db = await this.db;
    return await db.insert(tblTreino, treino.toMap());
  }

  Future<List<Map<String, dynamic>>> getTreinos() async {
    Database db = await this.db;
    return await db.rawQuery(
        'SELECT * FROM $tblTreino ORDER BY $colGrupo ASC, $colData DESC');
  }

  Future<int> getCount() async {
    Database db = await this.db;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tblTreino')) ??
        0;
  }

  Future<int> updateTreino(Treino treino) async {
    Database db = await this.db;
    return await db.update(tblTreino, treino.toMap(),
        where: '$colId = ?', whereArgs: [treino.id]);
  }

  Future<int> deleteTreino(int id) async {
    Database db = await this.db;
    return await db.rawDelete('DELETE FROM $tblTreino WHERE $colId = $id');
  }
}

// ============================================================
// TELA 1 — Lista de Treinos (tela principal)
// ============================================================

class TreinoList extends StatefulWidget {
  const TreinoList({super.key});

  @override
  State<TreinoList> createState() => _TreinoListState();
}

class _TreinoListState extends State<TreinoList> {
  final DbHelper helper = DbHelper();
  List<Treino>? treinos;
  int count = 0;

  void getData() {
    final dbFuture = helper.getTreinos();
    dbFuture.then((result) {
      List<Treino> treinoList = [];
      count = result.length;
      for (int i = 0; i < count; i++) {
        treinoList.add(Treino.fromMap(result[i]));
      }
      setState(() {
        treinos = treinoList;
      });
    });
  }

  Color getColor(int grupo) {
    switch (grupo) {
      case 1: return Colors.red.shade400;
      case 2: return Colors.blue.shade400;
      case 3: return Colors.green.shade400;
      case 4: return Colors.orange.shade400;
      case 5: return Colors.purple.shade400;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    treinos ??= [];
    if (treinos!.isEmpty) getData();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'BEStOfYou',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '$count treinos',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          )
        ],
      ),
      body: count == 0
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Nenhum treino registrado',
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Toque no + para adicionar seu primeiro treino',
              style: TextStyle(color: Colors.white24, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: count,
        itemBuilder: (context, index) {
          final t = treinos![index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFF1A2E45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: getColor(t.grupoMuscular),
                child: Text(
                  t.grupoMuscular.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                t.exercicio,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      _infoChip(Icons.repeat,
                          '${t.series}x${t.repeticoes}'),
                      _infoChip(Icons.fitness_center, '${t.carga} kg'),
                      _infoChip(Icons.label_outline,
                          Treino.nomeGrupo(t.grupoMuscular)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.data.length > 10 ? t.data.substring(0, 10) : t.data,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TreinoForm(treino: t)),
                );
                getData();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3A7BD5),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TreinoForm()),
          );
          getData();
        },
        tooltip: 'Novo treino',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// ============================================================
// TELA 2 e 3 — Formulário (inserção e detalhes/exclusão)
// ============================================================

class TreinoForm extends StatefulWidget {
  final Treino? treino;
  const TreinoForm({super.key, this.treino});

  @override
  State<TreinoForm> createState() => _TreinoFormState();
}

class _TreinoFormState extends State<TreinoForm> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper helper = DbHelper();

  final _exercicioCtrl = TextEditingController();
  final _seriesCtrl = TextEditingController();
  final _repeticoesCtrl = TextEditingController();
  final _cargaCtrl = TextEditingController();
  int _grupoSelecionado = 1;

  bool get isEditing => widget.treino != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _exercicioCtrl.text = widget.treino!.exercicio;
      _seriesCtrl.text = widget.treino!.series.toString();
      _repeticoesCtrl.text = widget.treino!.repeticoes.toString();
      _cargaCtrl.text = widget.treino!.carga.toString();
      _grupoSelecionado = widget.treino!.grupoMuscular;
    }
  }

  @override
  void dispose() {
    _exercicioCtrl.dispose();
    _seriesCtrl.dispose();
    _repeticoesCtrl.dispose();
    _cargaCtrl.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final data = DateTime.now().toString();

    if (isEditing) {
      final t = widget.treino!;
      t.exercicio = _exercicioCtrl.text;
      t.series = int.parse(_seriesCtrl.text);
      t.repeticoes = int.parse(_repeticoesCtrl.text);
      t.carga = double.parse(_cargaCtrl.text.replaceAll(',', '.'));
      t.grupoMuscular = _grupoSelecionado;
      t.data = data;
      helper.updateTreino(t).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treino atualizado!')));
        Navigator.pop(context);
      });
    } else {
      final novo = Treino(
        _exercicioCtrl.text,
        int.parse(_seriesCtrl.text),
        int.parse(_repeticoesCtrl.text),
        double.parse(_cargaCtrl.text.replaceAll(',', '.')),
        _grupoSelecionado,
        data,
      );
      helper.insertTreino(novo).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treino adicionado!')));
        Navigator.pop(context);
      });
    }
  }

  void _confirmarExclusao() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E45),
        title: const Text('Excluir treino?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja excluir "${widget.treino!.exercicio}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () {
              helper.deleteTreino(widget.treino!.id!).then((_) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Treino excluído.')));
              });
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Detalhes do Treino' : 'Novo Treino',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.8),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: isEditing
            ? [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Excluir treino',
            onPressed: _confirmarExclusao,
          )
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Exercício'),
              _field(
                controller: _exercicioCtrl,
                hint: 'Ex: Supino Reto',
                icon: Icons.fitness_center,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Informe o exercício' : null,
              ),
              const SizedBox(height: 20),
              _label('Grupo Muscular'),
              _grupoSelector(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Séries'),
                        _field(
                          controller: _seriesCtrl,
                          hint: 'Ex: 4',
                          icon: Icons.repeat,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Obrigatório';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Repetições'),
                        _field(
                          controller: _repeticoesCtrl,
                          hint: 'Ex: 12',
                          icon: Icons.format_list_numbered,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Obrigatório';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _label('Carga (kg)'),
              _field(
                controller: _cargaCtrl,
                hint: 'Ex: 60.5',
                icon: Icons.monitor_weight_outlined,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a carga';
                  final d = double.tryParse(v.replaceAll(',', '.'));
                  if (d == null || d < 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A7BD5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _salvar,
                  icon: Icon(
                    isEditing
                        ? Icons.save_outlined
                        : Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    isEditing ? 'Salvar Alterações' : 'Adicionar Treino',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A2E45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.orange),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      validator: validator,
    );
  }

  Widget _grupoSelector() {
    final grupos = {
      1: 'Peito',
      2: 'Costas',
      3: 'Pernas',
      4: 'Ombro',
      5: 'Biceps/Triceps',
    };
    final cores = {
      1: Colors.red.shade400,
      2: Colors.blue.shade400,
      3: Colors.green.shade400,
      4: Colors.orange.shade400,
      5: Colors.purple.shade400,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: grupos.entries.map((entry) {
        final sel = _grupoSelecionado == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _grupoSelecionado = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: sel ? cores[entry.key] : const Color(0xFF1A2E45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? cores[entry.key]! : Colors.white12,
              ),
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                color: sel ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
