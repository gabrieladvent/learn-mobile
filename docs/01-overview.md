# 01 — Overview

## Kenapa aplikasi ini ada

LMS `lms-app` sudah punya dua permukaan: panel Filament untuk guru/admin, dan
frontend Inertia+React untuk siswa. Frontend siswa berjalan di browser desktop
maupun mobile, tapi tiga hal tidak bisa diselesaikan browser:

1. **Sinyal sekolah jelek.** Siswa kehilangan draft tugas saat koneksi putus, dan
   tidak bisa membuka materi yang sudah pernah dibuka.
2. **Tidak ada push notification.** Deadline tugas dan pengumuman nilai baru
   terlihat kalau siswa membuka situsnya sendiri. Tabel `notifications` sudah
   terisi di backend, tapi tidak ada kanal untuk mendorongnya ke HP.
3. **Ujian di browser mobile rapuh.** Tab ke-*kill* OS, halaman ke-*refresh*,
   timer berbasis klien gampang dimanipulasi.

Aplikasi mobile ini menyelesaikan ketiganya, dengan target siswa SMA/SMP yang
mayoritas hanya punya HP Android kelas menengah-bawah.

## Persona tunggal: Siswa

Aplikasi ini **khusus siswa**. Guru dan admin tetap di Filament — tidak ada
rencana menambahkan peran lain ke aplikasi mobile ini.

| Atribut | Nilai |
|---------|-------|
| Login | NISN + password (bukan email) |
| Password awal | tanggal lahir — **wajib diganti saat login pertama** |
| Perangkat | Android mayoritas, iOS minoritas |
| Kondisi jaringan | tidak stabil, sering 3G / WiFi sekolah penuh |
| Literasi digital | menengah — UI harus jelas, minim jargon |

Konsekuensi desain dari persona ini:

- Login pakai **NISN**, bukan email. Field `users.email` di backend malah
  nullable untuk siswa.
- Alur "ganti password default" adalah bagian dari onboarding, bukan pengaturan
  opsional. Backend memaksa lewat middleware `EnsureStudentPasswordChanged`;
  aplikasi harus menghormati itu, bukan mengakalinya.
- Ukuran APK dan pemakaian data harus ditekan. Lihat [ADR-0002](adr/0002-flutter-native-bukan-webview.md).

## Scope MVP

Empat kelompok fitur, semuanya masuk rilis pertama:

### 1. Auth & Beranda
- Login NISN + password, dengan rate limit yang sama seperti web (5 percobaan/menit).
- Paksa ganti password default sebelum akses konten apa pun.
- Beranda: daftar mata pelajaran (course), pin/unpin, statistik ringkas, to-do list.
- Profil: ganti password, ganti foto, lihat progress belajar.

### 2. Materi
- Daftar materi per mata pelajaran, dikelompokkan per topik.
- Baca materi tipe teks, buka link, unduh lampiran file.
- Rekam progress belajar (heartbeat) — lihat [ADR-0012](adr/0012-learning-progress-tracking-mobile.md).

### 3. Tugas
- Daftar & detail tugas, deadline, status terlambat.
- Kirim jawaban: teks, link, atau unggah file.
- Lihat nilai dan feedback guru, plus riwayat aktivitas submission.

### 4. Ujian
- Mode `online_quiz`: kerjakan soal bertimer, auto-save jawaban, lihat hasil
  kalau guru sudah merilisnya.
- Mode `submission`: unggah berkas jawaban seperti tugas.
- Timer **otoritatif di server**. Ini bagian paling berisiko di MVP dan punya
  dokumen sendiri: [07 — Mode Ujian](07-exam-mode.md).

### Lintas fitur
- Cache baca (dashboard, materi, tugas) supaya bisa dibuka offline.
- Antrian upload (outbox) supaya submit tugas tidak hilang saat jaringan putus.
- Push notification lewat FCM untuk tugas baru, pengingat deadline, dan nilai keluar.

## Non-goals

Ditulis eksplisit supaya tidak diam-diam masuk scope:

| Bukan target | Alasan |
|--------------|--------|
| Peran guru / admin / wali murid | Filament sudah menanganinya; menambah peran melipatgandakan permukaan izin |
| Registrasi mandiri | Backend sengaja mematikan `/register` — akun hanya dibuat lewat panel/import |
| Chat / forum diskusi | Backend belum punya modelnya sama sekali |
| Video conference / kelas live | Di luar domain LMS saat ini |
| Mengerjakan ujian sepenuhnya offline | Tidak bisa dijamin integritasnya. Lihat [07](07-exam-mode.md) |
| Anti-cheat tingkat proctoring (rekam kamera, kunci layar) | Butuh izin invasif; siswa di bawah umur; tidak sebanding dengan manfaatnya |
| Dukungan tablet & landscape khusus | Fase berikutnya; MVP portrait-first |
| Web/desktop build dari repo ini | Folder `web/`, `linux/`, `macos/`, `windows/` bawaan `flutter create` boleh dihapus |

## Definisi selesai untuk MVP

Rilis pertama dianggap selesai kalau seorang siswa bisa, dari HP-nya sendiri:

1. Login dengan NISN, mengganti password default, dan sampai di beranda.
2. Membuka mata pelajaran, membaca materi, dan mengunduh lampirannya.
3. Mengumpulkan tugas berisi file **dari kondisi jaringan yang sempat putus**,
   lalu melihat nilainya setelah guru menilai.
4. Mengerjakan kuis online sampai selesai, termasuk saat aplikasi sempat
   ter-*kill* di tengah pengerjaan.
5. Menerima push notification saat ada tugas baru.

Kriteria non-fungsional yang menyertainya ada di [09 — Roadmap](09-roadmap.md).
