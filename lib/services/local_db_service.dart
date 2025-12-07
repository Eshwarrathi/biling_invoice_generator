import 'package:hive/hive.dart';

class LocalDBService {
  // ---------------- ADD RECORD ----------------
  static Future<void> saveRecord(String boxName, Map<String, dynamic> record) async {
    final box = Hive.box(boxName);
    await box.add(record);
  }

  // ---------------- GET ALL RECORDS ----------------
  static List<Map<String, dynamic>> getAllRecords(String boxName) {
    final box = Hive.box(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---------------- UPDATE RECORD ----------------
  static Future<void> updateRecord(String boxName, int index, Map<String, dynamic> newData) async {
    final box = Hive.box(boxName);
    await box.putAt(index, newData);
  }

  // ---------------- DELETE RECORD ----------------
  static Future<void> deleteRecord(String boxName, int index) async {
    final box = Hive.box(boxName);
    await box.deleteAt(index);
  }


  // =========================================================
  // 🔥 NEW FUNCTIONS (added without changing original ones)
  // =========================================================

  // ---------------- SAVE RECORD WITH CUSTOM ID ----------------
  static Future<void> saveRecordWithId(String boxName, String id, Map<String, dynamic> data) async {
    final box = Hive.box(boxName);
    await box.put(id, data);
  }

  // ---------------- GET RECORD BY ID ----------------
  static Map<String, dynamic>? getRecordById(String boxName, String id) {
    final box = Hive.box(boxName);
    final data = box.get(id);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  // ---------------- UPDATE RECORD BY ID ----------------
  static Future<void> updateRecordById(String boxName, String id, Map<String, dynamic> data) async {
    final box = Hive.box(boxName);
    await box.put(id, data);
  }

  // ---------------- DELETE RECORD BY ID ----------------
  static Future<void> deleteRecordById(String boxName, String id) async {
    final box = Hive.box(boxName);
    await box.delete(id);
  }
}
