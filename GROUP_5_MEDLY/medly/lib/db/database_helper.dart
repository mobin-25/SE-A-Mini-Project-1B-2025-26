import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medly.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // ── Medicines ──────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        generic_name TEXT,
        brand_names TEXT,
        category TEXT,
        description TEXT,
        when_to_use TEXT,
        how_to_use TEXT,
        side_effects TEXT,
        warnings TEXT,
        storage_instructions TEXT,
        requires_prescription INTEGER DEFAULT 0,
        form TEXT,
        image_url TEXT
      )
    ''');

    // ── Diseases ───────────────────────────────────────
    await db.execute('''
      CREATE TABLE diseases (
        disease_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    // ── Symptoms ───────────────────────────────────────
    await db.execute('''
      CREATE TABLE symptoms (
        symptom_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // ── Disease_Symptom Mapping ────────────────────────
    await db.execute('''
      CREATE TABLE disease_symptoms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        disease_id INTEGER NOT NULL,
        symptom_id INTEGER NOT NULL,
        weight REAL DEFAULT 1.0,
        FOREIGN KEY (disease_id) REFERENCES diseases(disease_id),
        FOREIGN KEY (symptom_id) REFERENCES symptoms(symptom_id)
      )
    ''');

    // ── Medicine_Disease Mapping ───────────────────────
    await db.execute('''
      CREATE TABLE medicine_disease (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_id INTEGER NOT NULL,
        disease_id INTEGER NOT NULL,
        effectiveness_score REAL DEFAULT 1.0,
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id),
        FOREIGN KEY (disease_id) REFERENCES diseases(disease_id)
      )
    ''');

    // ── Drug Interactions ─────────────────────────────
    await db.execute('''
      CREATE TABLE drug_interactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine1_id INTEGER NOT NULL,
        medicine2_id INTEGER NOT NULL,
        severity TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (medicine1_id) REFERENCES medicines(medicine_id),
        FOREIGN KEY (medicine2_id) REFERENCES medicines(medicine_id)
      )
    ''');

    // ── Users ─────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER
      )
    ''');

    // ── Dosage Schedule ───────────────────────────────
    await db.execute('''
      CREATE TABLE dosage_schedule (
        schedule_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        medicine_id INTEGER NOT NULL,
        time TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        missed_count INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(user_id),
        FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
      )
    ''');

    // ── Pharmacies ──────────────────────────────────────
    await db.execute('''
      CREATE TABLE pharmacies (
        pharmacy_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    // ── Reminders ───────────────────────────────────────
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_name TEXT NOT NULL,
        dose TEXT,
        frequency TEXT,
        times TEXT,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── Prescriptions ─────────────────────────────────────
    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        doctor_name TEXT,
        date TEXT,
        medicines TEXT,
        notes TEXT,
        image_path TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // Seed sample data
    await _seedData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old medicines table and recreate with new schema
      await db.execute('DROP TABLE IF EXISTS medicines');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS medicines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          generic_name TEXT,
          brand_names TEXT,
          category TEXT,
          description TEXT,
          when_to_use TEXT,
          how_to_use TEXT,
          side_effects TEXT,
          warnings TEXT,
          storage_instructions TEXT,
          requires_prescription INTEGER DEFAULT 0,
          form TEXT,
          image_url TEXT
        )
      ''');
    }
  }

  Future<void> _seedData(Database db) async {
    // Seed medicines (new schema)
    await db.insert('medicines', {
      'name': 'Paracetamol',
      'generic_name': 'Acetaminophen',
      'brand_names': '["Crocin","Calpol","Dolo"]',
      'category': 'Analgesic / Antipyretic',
      'description': 'Relieves pain and reduces fever.',
      'when_to_use': 'Fever, headache, mild to moderate pain.',
      'how_to_use': '1–2 tablets every 4–6 hours, max 4g/day.',
      'side_effects': '["Nausea","Rash (rare)","Liver damage (overdose)"]',
      'warnings': '["Do not exceed 4g/day","Avoid with alcohol"]',
      'storage_instructions': 'Store below 25°C, away from moisture.',
      'requires_prescription': 0,
      'form': 'tablet',
    });
    await db.insert('medicines', {
      'name': 'Ibuprofen',
      'generic_name': 'Ibuprofen',
      'brand_names': '["Brufen","Advil"]',
      'category': 'NSAID',
      'description': 'Anti-inflammatory, relieves pain and fever.',
      'when_to_use': 'Inflammation, pain, fever.',
      'how_to_use': '1 tablet every 6–8 hours with food.',
      'side_effects': '["Stomach upset","Heartburn","Dizziness"]',
      'warnings': '["Take with food","Avoid in kidney disease"]',
      'storage_instructions': 'Store below 30°C.',
      'requires_prescription': 0,
      'form': 'tablet',
    });
    await db.insert('medicines', {
      'name': 'Amoxicillin',
      'generic_name': 'Amoxicillin',
      'brand_names': '["Amoxil","Trimox"]',
      'category': 'Antibiotic',
      'description': 'Broad-spectrum penicillin antibiotic.',
      'when_to_use': 'Bacterial infections.',
      'how_to_use': '1 capsule every 8 hours for 5–7 days.',
      'side_effects': '["Diarrhea","Nausea","Allergic reaction"]',
      'warnings': '["Complete full course","Avoid if penicillin-allergic"]',
      'storage_instructions': 'Store below 25°C.',
      'requires_prescription': 1,
      'form': 'capsule',
    });
    await db.insert('medicines', {
      'name': 'Cetirizine',
      'generic_name': 'Cetirizine HCl',
      'brand_names': '["Zyrtec","Alerid"]',
      'category': 'Antihistamine',
      'description': 'Relieves allergy symptoms.',
      'when_to_use': 'Hay fever, urticaria, allergic rhinitis.',
      'how_to_use': '1 tablet once daily.',
      'side_effects': '["Drowsiness","Dry mouth","Dizziness"]',
      'warnings': '["Avoid alcohol","May cause drowsiness"]',
      'storage_instructions': 'Store below 30°C.',
      'requires_prescription': 0,
      'form': 'tablet',
    });
    await db.insert('medicines', {
      'name': 'Omeprazole',
      'generic_name': 'Omeprazole',
      'brand_names': '["Prilosec","Omez"]',
      'category': 'Proton Pump Inhibitor',
      'description': 'Reduces stomach acid production.',
      'when_to_use': 'Acid reflux, GERD, peptic ulcer.',
      'how_to_use': '1 capsule before meals daily.',
      'side_effects': '["Headache","Nausea","Diarrhea"]',
      'warnings': '["Do not crush capsule","Long-term use: monitor bone density"]',
      'storage_instructions': 'Store below 25°C away from light.',
      'requires_prescription': 0,
      'form': 'capsule',
    });
    await db.insert('medicines', {
      'name': 'Cough Syrup',
      'generic_name': 'Dextromethorphan',
      'brand_names': '["Benadryl","Robitussin"]',
      'category': 'Antitussive',
      'description': 'Suppresses dry cough.',
      'when_to_use': 'Dry, irritating cough.',
      'how_to_use': '10ml every 6 hours.',
      'side_effects': '["Dizziness","Nausea","Drowsiness"]',
      'warnings': '["Do not exceed recommended dose","Avoid in children under 6"]',
      'storage_instructions': 'Store below 25°C.',
      'requires_prescription': 0,
      'form': 'syrup',
    });

    // Seed diseases
    await db.insert('diseases', {'name': 'Common Cold', 'description': 'Viral infection of the upper respiratory tract'});
    await db.insert('diseases', {'name': 'Flu', 'description': 'Influenza viral infection'});
    await db.insert('diseases', {'name': 'Allergy', 'description': 'Immune response to allergens'});
    await db.insert('diseases', {'name': 'Acid Reflux', 'description': 'Stomach acid flows back into the esophagus'});

    // Seed symptoms
    await db.insert('symptoms', {'name': 'Fever'});
    await db.insert('symptoms', {'name': 'Headache'});
    await db.insert('symptoms', {'name': 'Cough'});
    await db.insert('symptoms', {'name': 'Runny Nose'});
    await db.insert('symptoms', {'name': 'Sore Throat'});
    await db.insert('symptoms', {'name': 'Body Pain'});
    await db.insert('symptoms', {'name': 'Sneezing'});
    await db.insert('symptoms', {'name': 'Heartburn'});

    // Disease-Symptom mappings
    // Common Cold: runny nose(4), cough(3), sore throat(3), sneezing(2)
    await db.insert('disease_symptoms', {'disease_id': 1, 'symptom_id': 4, 'weight': 3.0});
    await db.insert('disease_symptoms', {'disease_id': 1, 'symptom_id': 3, 'weight': 2.0});
    await db.insert('disease_symptoms', {'disease_id': 1, 'symptom_id': 5, 'weight': 2.0});
    await db.insert('disease_symptoms', {'disease_id': 1, 'symptom_id': 7, 'weight': 1.5});
    // Flu: fever(5), body pain(4), headache(3), cough(2)
    await db.insert('disease_symptoms', {'disease_id': 2, 'symptom_id': 1, 'weight': 5.0});
    await db.insert('disease_symptoms', {'disease_id': 2, 'symptom_id': 6, 'weight': 4.0});
    await db.insert('disease_symptoms', {'disease_id': 2, 'symptom_id': 2, 'weight': 3.0});
    await db.insert('disease_symptoms', {'disease_id': 2, 'symptom_id': 3, 'weight': 2.0});
    // Allergy: sneezing(4), runny nose(4), itching(3)
    await db.insert('disease_symptoms', {'disease_id': 3, 'symptom_id': 7, 'weight': 4.0});
    await db.insert('disease_symptoms', {'disease_id': 3, 'symptom_id': 4, 'weight': 3.0});
    // Acid Reflux: heartburn(5)
    await db.insert('disease_symptoms', {'disease_id': 4, 'symptom_id': 8, 'weight': 5.0});

    // Medicine-Disease mappings
    await db.insert('medicine_disease', {'medicine_id': 1, 'disease_id': 2, 'effectiveness_score': 0.9}); // Paracetamol → Flu
    await db.insert('medicine_disease', {'medicine_id': 1, 'disease_id': 1, 'effectiveness_score': 0.7}); // Paracetamol → Cold
    await db.insert('medicine_disease', {'medicine_id': 2, 'disease_id': 2, 'effectiveness_score': 0.85}); // Ibuprofen → Flu
    await db.insert('medicine_disease', {'medicine_id': 4, 'disease_id': 3, 'effectiveness_score': 0.95}); // Cetirizine → Allergy
    await db.insert('medicine_disease', {'medicine_id': 5, 'disease_id': 4, 'effectiveness_score': 0.95}); // Omeprazole → Acid Reflux
    await db.insert('medicine_disease', {'medicine_id': 6, 'disease_id': 1, 'effectiveness_score': 0.8});  // Cough Syrup → Cold

    // Drug Interactions
    await db.insert('drug_interactions', {'medicine1_id': 1, 'medicine2_id': 2, 'severity': 'low', 'description': 'Minor interaction, monitor for stomach upset'});
    await db.insert('drug_interactions', {'medicine1_id': 2, 'medicine2_id': 3, 'severity': 'medium', 'description': 'May reduce antibiotic absorption'});

    // Pharmacies (sample Mumbai locations)
    await db.insert('pharmacies', {'name': 'Apollo Pharmacy', 'latitude': 19.0760, 'longitude': 72.8777});
    await db.insert('pharmacies', {'name': 'MedPlus Pharmacy', 'latitude': 19.0830, 'longitude': 72.8890});
    await db.insert('pharmacies', {'name': 'Wellness Forever', 'latitude': 19.0690, 'longitude': 72.8650});
    await db.insert('pharmacies', {'name': 'Guardian Pharmacy', 'latitude': 19.0920, 'longitude': 72.8600});

    // Default user
    await db.insert('users', {'name': 'Default User', 'age': 25});
  }

  // ── Generic CRUD ──────────────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawQuery(sql, args);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // ── Convenience API ───────────────────────────────────────────────────────

  /// Search medicines by name, generic name, or brand names (case-insensitive).
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    final db = await database;
    final q = '%${query.toLowerCase()}%';
    return await db.rawQuery('''
      SELECT * FROM medicines
      WHERE LOWER(name) LIKE ?
         OR LOWER(generic_name) LIKE ?
         OR LOWER(brand_names) LIKE ?
      LIMIT 20
    ''', [q, q, q]);
  }

  /// Insert a reminder. Lists (e.g. [times]) are auto-encoded to JSON.
  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    final data = Map<String, dynamic>.from(reminder);
    if (data['times'] is List) {
      data['times'] = jsonEncode(data['times']);
    }
    return await db.insert('reminders', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all active reminders. Decodes [times] back to a List.
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    final db = await database;
    final rows = await db.query('reminders',
        where: 'is_active = ?', whereArgs: [1], orderBy: 'id DESC');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      if (m['times'] is String) {
        try { m['times'] = jsonDecode(m['times'] as String); } catch (_) {}
      }
      return m;
    }).toList();
  }

  /// Insert a prescription. Lists (e.g. [medicines]) are auto-encoded to JSON.
  Future<int> insertPrescription(Map<String, dynamic> prescription) async {
    final db = await database;
    final data = Map<String, dynamic>.from(prescription);
    if (data['medicines'] is List) {
      data['medicines'] = jsonEncode(data['medicines']);
    }
    return await db.insert('prescriptions', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Check if two medicines have a known interaction.
  /// Returns the interaction row or null if none found.
  Future<Map<String, dynamic>?> checkInteraction(
      String medicine1, String medicine2) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT di.severity, di.description,
             m1.name AS medicine1, m2.name AS medicine2
      FROM drug_interactions di
      JOIN medicines m1 ON di.medicine1_id = m1.id
      JOIN medicines m2 ON di.medicine2_id = m2.id
      WHERE (LOWER(m1.name) = LOWER(?) AND LOWER(m2.name) = LOWER(?))
         OR (LOWER(m1.name) = LOWER(?) AND LOWER(m2.name) = LOWER(?))
    ''', [medicine1, medicine2, medicine2, medicine1]);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Print row counts for every table — handy for debugging.
  Future<void> printTableStats() async {
    final db = await database;
    const tables = [
      'medicines', 'diseases', 'symptoms', 'disease_symptoms',
      'medicine_disease', 'drug_interactions', 'users',
      'dosage_schedule', 'pharmacies', 'reminders', 'prescriptions',
    ];
    for (final t in tables) {
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $t'));
      // ignore: avoid_print
      print('[DB] $t: $count rows');
    }
  }
}