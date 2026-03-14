

class JurnalUmum {
  final int? idJurnal;
  final String tanggal;
  final String? noReferensi;
  final String keterangan;
  final String kodeAkun;
  final String? namaAkun;
  final double debit;
  final double kredit;
  final int? idTransaksi;
  final String? dibuatOleh;
  final String? createdAt;

  JurnalUmum({
    this.idJurnal,
    required this.tanggal,
    this.noReferensi,
    required this.keterangan,
    required this.kodeAkun,
    this.namaAkun,
    this.debit = 0.0,
    this.kredit = 0.0,
    this.idTransaksi,
    this.dibuatOleh,
    this.createdAt,
  });

  // Mengonversi Map dari Database ke objek JurnalUmum
  factory JurnalUmum.fromMap(Map<String, dynamic> map) {
    return JurnalUmum(
      idJurnal: map['id_jurnal'],
      tanggal: map['tanggal'],
      noReferensi: map['no_referensi'],
      keterangan: map['keterangan'],
      kodeAkun: map['kode_akun'],
      namaAkun: map['nama_akun'],
      debit: (map['debit'] as num).toDouble(),
      kredit: (map['kredit'] as num).toDouble(),
      idTransaksi: map['id_transaksi'],
      dibuatOleh: map['dibuat_oleh'],
      createdAt: map['created_at'],
    );
  }

  // Mengonversi objek JurnalUmum ke Map untuk disimpan di Database
  Map<String, dynamic> toMap() {
    return {
      'id_jurnal': idJurnal,
      'tanggal': tanggal,
      'no_referensi': noReferensi,
      'keterangan': keterangan,
      'kode_akun': kodeAkun,
      'nama_akun': namaAkun,
      'debit': debit,
      'kredit': kredit,
      'id_transaksi': idTransaksi,
      'dibuat_oleh': dibuatOleh,
      // 'created_at' biasanya diisi otomatis oleh database SQLite sesuai skema kamu
    };
  }

  // Opsional: Untuk mempermudah debugging
  @override
  String toString() {
    return 'JurnalUmum(id: $idJurnal, akun: $kodeAkun, D: $debit, K: $kredit)';
  }
}
