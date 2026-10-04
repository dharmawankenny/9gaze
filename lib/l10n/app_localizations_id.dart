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
  String get saveToGallery => 'Ekspor ke Galeri';

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
  String get exportVerb => 'Ekspor';

  @override
  String get exportDone => 'Diekspor';

  @override
  String get textDefault => 'Teks';

  @override
  String get onboardingWelcomeTitle => 'Selamat datang di 9Gaze';

  @override
  String get onboardingWelcomeBody =>
      'Impor foto gerakan mata dari galeri dan susun menjadi grid 3×3 berlabel yang rapi. Penjajaran otomatis mengatur bingkai; Anda bisa menyesuaikan slot mana pun. Ekspor satu gambar komposit jika sudah selesai.';

  @override
  String get onboardingNext => 'Lanjut';

  @override
  String get onboardingGotIt => 'Mengerti';

  @override
  String get onboardingSkipTour => 'Lewati tur';

  @override
  String get onboardingSkipConfirmTitle => 'Lewati tur?';

  @override
  String get onboardingSkipConfirmBody =>
      'Anda bisa memulai ulang tutorial kapan saja dari menu pengaturan.';

  @override
  String get onboardingHomeEmptyTitle => 'Grid tersimpan Anda';

  @override
  String get onboardingHomeEmptyBody =>
      'Setiap tatapan yang Anda buat muncul di sini. Belum ada. Ketuk tombol biru di bawah untuk memulai grid berlabel pertama.';

  @override
  String get onboardingHomeCreateTitle => 'Buat tatapan';

  @override
  String get onboardingHomeCreateBody =>
      'Ketuk Tatapan Baru untuk memberi nama grid dan mulai mengimpor foto.';

  @override
  String get onboardingCreateNameTitle => 'Nama tatapan ini';

  @override
  String get onboardingCreateNameBody =>
      'Hanya nama yang wajib. Pilih nama yang mudah dikenali di daftar.';

  @override
  String get onboardingCreateNotesTitle => 'Catatan (opsional)';

  @override
  String get onboardingCreateNotesBody =>
      'Catatan opsional untuk referensi Anda, misalnya label sesi atau tanggal.';

  @override
  String get onboardingCreateSubmitTitle => 'Buka grid Anda';

  @override
  String get onboardingCreateSubmitBody =>
      'Ketuk Buat Tatapan. Berikutnya Anda menetapkan foto ke setiap slot berlabel.';

  @override
  String get onboardingDetailSlotsTitle => 'Sembilan slot berlabel';

  @override
  String get onboardingDetailSlotsBody =>
      'Setiap slot sesuai arah tatapan. Ketuk slot untuk mengimpor satu foto dari galeri. Pilih beberapa foto sekaligus dan 9Gaze mengisi slot kosong berurutan.';

  @override
  String get onboardingDetailPickTitle => 'Impor dari galeri';

  @override
  String get onboardingDetailPickBody =>
      'Ketuk slot (tengah adalah pilihan awal yang baik) dan pilih satu atau beberapa foto. Tidak perlu kamera di aplikasi.';

  @override
  String get onboardingDetailAutoAlignTitle => 'Penjajaran mata otomatis';

  @override
  String get onboardingDetailAutoAlignBody =>
      '9Gaze mendeteksi mata di setiap foto, menengahkan secara vertikal, dan menyesuaikan gambar ke batas horizontal slot agar setiap sel terlihat konsisten.';

  @override
  String get onboardingDetailFineTuneTitle => 'Penyesuaian manual';

  @override
  String get onboardingDetailFineTuneBody =>
      'Penjajaran otomatis tidak selalu pas di setiap foto. Buka slot untuk kontrol penuh, atau gunakan Ubah di layar ini untuk menggeser posisi di grid.';

  @override
  String get onboardingDetailLayoutTitle => 'Opsi tata letak';

  @override
  String get onboardingDetailLayoutBody =>
      'Mode pendek memakai sel slot yang lebih rendah. Dua tatapan tengah membelah slot tengah menjadi atas dan bawah. Hanya satu opsi tata letak yang aktif.';

  @override
  String get onboardingDetailInfoTitle => 'Detail tatapan';

  @override
  String get onboardingDetailInfoBody =>
      'Nama dan catatan grid ini ada di sini. Ketuk Perbarui untuk mengubahnya kapan saja.';

  @override
  String get onboardingDetailTapSlotTitle => 'Sesuaikan slot ini';

  @override
  String get onboardingDetailTapSlotBody =>
      'Ketuk slot yang baru Anda isi. Di layar berikutnya Anda bisa mengatur posisi, zoom, dan rotasi.';

  @override
  String get onboardingSlotGesturesTitle => 'Atur bingkai';

  @override
  String get onboardingSlotGesturesBody =>
      'Cubit untuk zoom, geser untuk pindah, putar untuk rotasi. Coba penyesuaian kecil jika penjajaran otomatis perlu dibetulkan.';

  @override
  String get onboardingSlotUndoTitle => 'Undo dan redo';

  @override
  String get onboardingSlotUndoBody =>
      'Ketuk Undo untuk mundur, lalu Redo jika ingin mengembalikan perubahan.';

  @override
  String get onboardingSlotResetTitle => 'Reset dan tengahkan';

  @override
  String get onboardingSlotResetBody =>
      'Ketuk Reset untuk menghapus edit sesi ini, lalu Tengahkan untuk menjajarkan mata lagi.';

  @override
  String get onboardingSlotToolsTitle => 'Ganti dan ekspor';

  @override
  String get onboardingSlotToolsBody =>
      'Ganti mengimpor foto lain untuk slot ini. Ekspor menyimpan slot ini ke galeri. Ketuk Lanjut jika sudah siap.';

  @override
  String get onboardingSlotSaveTitle => 'Simpan slot ini';

  @override
  String get onboardingSlotSaveBody =>
      'Ketuk Simpan untuk kembali ke grid tatapan Anda.';

  @override
  String get onboardingDetailEditTitle => 'Ubah seluruh grid';

  @override
  String get onboardingDetailEditBody =>
      'Ketuk Ubah (kanan atas) untuk menggeser slot, menukar foto, atau menambah teks overlay.';

  @override
  String get onboardingDetailEditMenuTitle => 'Tiga cara mengubah';

  @override
  String get onboardingDetailEditMenuBody =>
      'Posisi menyesuaikan gambar tiap slot. Susunan menukar foto antar slot. Teks menambah label di grid komposit.';

  @override
  String get onboardingDetailRepositionTitle => 'Posisi';

  @override
  String get onboardingDetailRepositionBody =>
      'Sesuaikan bingkai slot mana pun, lalu ketuk Simpan. Undo dan Redo juga tersedia di sini.';

  @override
  String get onboardingDetailRearrangeTitle => 'Susunan';

  @override
  String get onboardingDetailRearrangeBody =>
      'Seret satu slot ke slot lain untuk menukar foto. Ketuk Simpan jika urutannya sudah benar.';

  @override
  String get onboardingDetailTextTitle => 'Tambah teks';

  @override
  String get onboardingDetailTextBody =>
      'Ketuk Tambah Teks, lalu pindahkan, ubah skala, dan gaya label Anda. Ketuk Simpan, lalu keluar dari mode ubah.';

  @override
  String get onboardingDetailTextDoneTitle => 'Pengeditan selesai';

  @override
  String get onboardingDetailTextDoneBody =>
      'Ketuk Selesai untuk keluar dari mode ubah.';

  @override
  String get onboardingDetailPickRepositionTitle => 'Buka posisi';

  @override
  String get onboardingDetailPickRepositionBody =>
      'Ketuk Posisi untuk mengatur foto di tiap slot.';

  @override
  String get onboardingDetailPickRearrangeTitle => 'Buka susunan';

  @override
  String get onboardingDetailPickRearrangeBody =>
      'Ketuk Susunan untuk menukar foto antar slot.';

  @override
  String get onboardingDetailPickTextTitle => 'Buka teks';

  @override
  String get onboardingDetailPickTextBody =>
      'Ketuk Teks untuk menambah label di grid.';

  @override
  String get onboardingDetailExportTitle => 'Ekspor grid Anda';

  @override
  String get onboardingDetailExportBody =>
      'Ketuk Ekspor ke Galeri untuk menyimpan grid 3×3 jadi satu gambar di perpustakaan foto. Siap dibagikan dalam hitungan detik.';

  @override
  String get onboardingCompleteTitle => 'Anda siap';

  @override
  String get onboardingCompleteBody =>
      'Itu alur lengkapnya: impor, tetapkan slot, penjajaran otomatis, sesuaikan, ekspor. Semua tetap di perangkat Anda. Ada pertanyaan? Email 9gaze@atelierkensa.com.';

  @override
  String get settings => 'Pengaturan';

  @override
  String get restartTutorial => 'Ulangi tutorial';

  @override
  String get aboutApp => 'Tentang Aplikasi';

  @override
  String get aboutAppBody =>
      'Impor foto gerakan mata, susun dalam grid berlabel, dan ekspor satu gambar komposit. Semua tetap di perangkat Anda.';

  @override
  String aboutVersion(String version) {
    return 'Versi $version';
  }

  @override
  String get settingsBackups => 'Cadangan';

  @override
  String get settingsExportData => 'Ekspor data';

  @override
  String get settingsImportData => 'Impor data';

  @override
  String get settingsExportBody =>
      'Simpan tatapan, foto, dan thumbnail ke satu file .9gaze.';

  @override
  String get settingsImportBody =>
      'Ganti semua tatapan di perangkat ini dengan file cadangan.';

  @override
  String get settingsStorage => 'Penyimpanan';

  @override
  String get settingsPhotos => 'Foto dan thumbnail';

  @override
  String get settingsDatabase => 'Basis data';

  @override
  String get settingsTotalUsage => 'Total pemakaian';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsRestartBody => 'Ulangi tutorial dari layar utama.';

  @override
  String get settingsImportConfirmTitle => 'Ganti semua data?';

  @override
  String get settingsImportConfirmBody =>
      'Impor ini mengganti setiap tatapan, foto, dan thumbnail di perangkat ini. Tindakan ini tidak bisa dibatalkan.';

  @override
  String get settingsImportConfirmAction => 'Ganti data';

  @override
  String get settingsExportSuccess => 'Cadangan tersimpan.';

  @override
  String get settingsImportSuccess => 'Data dipulihkan dari cadangan.';

  @override
  String get settingsBackupFailed => 'Cadangan tidak bisa diselesaikan.';

  @override
  String get settingsBackupUnsupported =>
      'File ini bukan cadangan 9Gaze yang didukung.';

  @override
  String get settingsBackupUnreadable => 'Cadangan tidak bisa dibaca.';

  @override
  String get onboardingHomeCreateReturningTitle => 'Jalankan tutorial lagi';

  @override
  String get onboardingHomeCreateReturningBody =>
      'Tatapan tersimpan Anda ada di daftar di bawah. Ketuk Tatapan Baru untuk mengulang impor dan ekspor, atau buka tatapan yang ada untuk berlatih mengedit.';
}
