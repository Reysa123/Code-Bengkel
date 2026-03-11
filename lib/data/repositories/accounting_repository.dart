import 'package:bengkel/core/database/database_helper.dart';
import 'package:bengkel/data/models/jurnalumum.dart';
import 'package:intl/intl.dart';

class AccountingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<JurnalUmum>> getJurnalUmum({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final db = await _dbHelper.database;

    String where = '';
    List<dynamic> args = [];

    if (startDate != null && endDate != null) {
      where += 'tanggal BETWEEN ? AND ?';
      args.add(DateFormat('yyyy-MM-dd').format(startDate));
      args.add(DateFormat('yyyy-MM-dd').format(endDate));
    }

    if (search != null && search.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += '(keterangan LIKE ? OR kode_akun LIKE ? OR nama_akun LIKE ?)';
      args.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (where.isNotEmpty) where = 'WHERE $where';

    final result = await db.rawQuery('''
    SELECT * FROM jurnal_umum $where
    ORDER BY tanggal DESC, id_jurnal DESC
  ''', args);

    return result.map((e) => JurnalUmum.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> getNeracaSaldo({DateTime? untilDate}) async {
    final db = await _dbHelper.database;

    String where = '';
    List<dynamic> args = [];

    if (untilDate != null) {
      where = 'WHERE tanggal <= ?';
      args.add(DateFormat('yyyy-MM-dd').format(untilDate));
    }

    final result = await db.rawQuery('''
    SELECT 
      kode_akun,
      nama_akun,
      SUM(debit - kredit) AS saldo
    FROM jurnal_umum
    $where
    GROUP BY kode_akun
    HAVING saldo != 0
    ORDER BY kode_akun
  ''', args);

    double totalDebit = 0;
    double totalKredit = 0;

    for (var row in result) {
      final saldo = (row['saldo'] as num).toDouble();
      if (saldo > 0) {
        totalDebit += saldo;
      } else {
        totalKredit += saldo.abs();
      }
    }

    return {
      'data': result,
      'total_debit': totalDebit,
      'total_kredit': totalKredit,
    };
  }
}
