// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => '9Gaze';

  @override
  String get searchByNameHint => 'Cari berdasarkan nama...';

  @override
  String get newGaze => 'Tatapan Baru';

  @override
  String get gazeDetails => 'Detail Tatapan';

  @override
  String get gazeDetail => 'Detail Tatapan';

  @override
  String get gazeDetailName => 'Nama tatapan';

  @override
  String get notesOptional => 'Catatan (opsional)';

  @override
  String get created => 'Dibuat';

  @override
  String get createGaze => 'Buat Tatapan';

  @override
  String get updated => 'Diperbarui';

  @override
  String get updateGaze => 'Perbarui Tatapan';

  @override
  String get failedLoadGazes => 'Gagal memuat tatapan.';

  @override
  String get noGazeFound => 'Tatapan tidak ditemukan, coba cari nama lain';

  @override
  String get noGazeYet =>
      'Belum ada tatapan, buat dengan menekan tombol biru di bawah';

  @override
  String get deleteGazeTitle => 'Hapus tatapan?';

  @override
  String deleteGazeMessage(Object name) {
    return 'Ini akan menghapus \"$name\" secara permanen dan tidak bisa dibatalkan.';
  }

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String lastEdited(Object date) {
    return 'Terakhir diubah: $date';
  }

  @override
  String get back => 'Kembali';

  @override
  String get editGaze => 'Ubah tatapan';

  @override
  String get editReposition => 'Ubah Posisi';

  @override
  String get editRearrange => 'Ubah Susunan';

  @override
  String get editTexts => 'Ubah Teks';

  @override
  String get done => 'Selesai';

  @override
  String get save => 'Simpan';

  @override
  String get edit => 'Ubah';

  @override
  String get exporting => 'Mengekspor…';

  @override
  String get exportedSuccessfully => 'Berhasil diekspor';

  @override
  String get saveToGallery => 'Simpan ke Galeri';

  @override
  String get compactMode => 'Mode pendek?';

  @override
  String get dualPrimary => 'Dua tatapan tengah?';

  @override
  String get update => 'Perbarui';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String get reposition => 'Posisi';

  @override
  String get rearrange => 'Susunan';

  @override
  String get texts => 'Teks';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get addText => 'Tambah Teks';

  @override
  String get overlayTextHint => 'Teks overlay';

  @override
  String get dragMovePinchScale =>
      'Geser untuk pindah. Cubit teks terpilih untuk ubah skala.';

  @override
  String exportFailed(Object error) {
    return 'Ekspor gagal: $error';
  }

  @override
  String get tapToAdd => 'Ketuk untuk tambah';

  @override
  String get slotTopLeft => 'Kiri atas';

  @override
  String get slotTopCenter => 'Tengah atas';

  @override
  String get slotTopRight => 'Kanan atas';

  @override
  String get slotCenterLeft => 'Kiri tengah';

  @override
  String get slotCenter => 'Tengah';

  @override
  String get slotCenterRight => 'Kanan tengah';

  @override
  String get slotBottomLeft => 'Kiri bawah';

  @override
  String get slotBottomCenter => 'Tengah bawah';

  @override
  String get slotBottomRight => 'Kanan bawah';

  @override
  String get slotCenter2 => 'Tengah 2';

  @override
  String get discard => 'Buang';

  @override
  String get saving => 'Menyimpan…';

  @override
  String get pinchZoomDragTwist =>
      'Cubit untuk zoom · Ketuk dan gerakan jari untuk menggeser · Putar untuk rotasi';

  @override
  String get reset => 'Reset';

  @override
  String get recenter => 'Tengahkan';

  @override
  String get replace => 'Ganti';

  @override
  String get textDefault => 'Teks';
}
