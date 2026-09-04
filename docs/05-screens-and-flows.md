# 05 — Screen & Flow

## Peta navigasi

```
/splash
/login
/change-password        ← wajib kalau must_change_password = true
/                       ShellRoute dengan bottom navigation
 ├── /home              Beranda (course + stats)
 ├── /todo              To-do list
 ├── /notifications     Notifikasi
 └── /profile           Profil
/courses/:courseId
/courses/:courseId/materials/:materialId
/materials/:materialId/assignments/:assignmentId
/materials/:materialId/exams/:examId
/exams/sessions/:sessionId          ← layar ujian, TANPA bottom nav
/exams/sessions/:sessionId/result
/force-update
```

Rute ujian sengaja **di luar shell**: saat mengerjakan ujian, bottom navigation
disembunyikan supaya siswa tidak sengaja keluar dan agar tidak ada jalan
navigasi yang perlu diinterupsi.

## Guard di router

Dijalankan sebagai `redirect` go_router, urutannya penting:

1. **Belum ada token** → `/login` (kecuali sudah di `/login` atau `/splash`).
2. **`must_change_password`** → `/change-password`, dan **blokir semua rute lain**
   kecuali itu dan logout. Ini mencerminkan middleware backend; kalau klien tidak
   melakukannya, siswa akan menabrak 403 di setiap layar.
3. **`clientTooOld`** → `/force-update`, tidak bisa dilewati.
4. **Sesi ujian aktif** → saat cold start, kalau ada sesi berjalan yang belum
   submit, tawarkan "lanjutkan ujian". Jangan paksa redirect — siswa mungkin
   sengaja keluar karena ujiannya sudah lewat waktu.

## Daftar layar

### Splash
Validasi token lewat `GET /auth/me`. Kalau offline dan token ada, **lanjut masuk
dengan data cache** — jangan tahan siswa di splash karena tidak ada sinyal.

### Login
Field NISN (numerik) + password. Menampilkan sisa detik saat kena rate limit.
Pesan galat kredensial harus persis seperti dari server (`"NISN atau password
salah."`) — jangan pernah membedakan "NISN tidak terdaftar" dari "password
salah", karena backend sengaja menyamakannya untuk mencegah enumerasi.

### Ganti password (paksa)
Muncul otomatis setelah login pertama. Jelaskan alasannya dalam satu kalimat
("Password awalmu adalah tanggal lahir dan mudah ditebak"). Tidak ada tombol
"nanti saja".

Setelah sukses: token lama dicabut server, klien menyimpan token baru dan masuk
ke beranda.

### Beranda
- Sapaan + nama siswa, kelas, tahun ajaran, wali kelas.
- Kartu statistik: tugas tertunda, tugas selesai, ujian selesai, rata-rata nilai.
- Kartu "ujian terdekat" kalau `stats.upcoming_exam` ada.
- Daftar course; yang di-pin di atas (sudah diurutkan server). Tekan lama untuk
  pin/unpin, dengan optimistic update + rollback kalau gagal.
- Pull-to-refresh.

Empty state: siswa belum terdaftar di kelas mana pun → "Kamu belum terdaftar di
kelas. Hubungi wali kelasmu." Bukan spinner tak berujung.

### To-do
Tiga seksi: **Hari ini**, **Minggu ini**, **Nanti**. Tiap item menampilkan
`kind` (tugas/ujian), mata pelajaran, dan deadline/waktu mulai. Ketuk → detail.

Ujian dengan `state: upcoming` tidak bisa dibuka; tampilkan hitung mundur.

### Detail Course
Header info mapel + guru. Daftar materi **dikelompokkan per `topic`**, urut
`order`. Tiap baris menampilkan ikon berdasarkan `has_content` / `has_files` /
`has_link` dan lencana jumlah tugas/ujian.

### Detail Materi
Konten teks (render aman — lihat catatan HTML di bawah), tombol buka link,
daftar file untuk diunduh, lalu seksi tugas & ujian milik materi ini.

Layar ini memulai **sesi pelacakan progress** (`open` → `heartbeat` berkala →
`close`). Detail di [ADR-0012](adr/0012-learning-progress-tracking-mobile.md).

⚠️ `content` berasal dari editor guru dan bisa memuat HTML. Jangan render lewat
WebView tanpa sanitasi, dan jangan aktifkan JavaScript di sana. Perlakukan
sebagai konten tak tepercaya.

### Detail Tugas
- Judul, deskripsi, deadline dengan hitung mundur, `max_score`.
- Lampiran guru (unduh).
- Form jawaban: teks, link, dan pemilih file. Validasi klien mengikuti
  `allowed_file_types` + `max_file_size_mb`.
- Kalau sudah dikumpulkan: tampilkan submission, penanda terlambat, nilai &
  feedback bila `graded_at` terisi.
- Linimasa `activities` dari API.

State pengiriman yang harus terlihat jelas: **draft lokal**, **mengantre kirim**,
**terkirim**, **gagal**. "Mengantre" bukan error — beri tahu bahwa jawaban aman
tersimpan dan akan dikirim saat ada sinyal.

### Detail Ujian
Percabangan berdasarkan `mode`:

- **`online_quiz`** → layar pengarahan: aturan, durasi, waktu mulai, tombol
  "Mulai Ujian" (aktif setelah `starts_at`). Konfirmasi sekali sebelum mulai,
  karena timer langsung berjalan dan tidak bisa dijeda.
- **`submission`** → form unggah, identik dengan tugas.

### Layar Ujian (quiz)
Layar paling kritis di aplikasi. Rinciannya di [07 — Mode Ujian](07-exam-mode.md).
Ringkasnya: timer dari server, satu soal per halaman + peta soal, auto-save tiap
jawaban, banner offline, dan konfirmasi ganda saat submit.

### Hasil Ujian
Hanya kalau `results_released` bernilai true. Kalau belum: "Hasil belum
dirilis guru." Jangan tampilkan skor mentah atau kunci jawaban dalam bentuk apa pun.

### Notifikasi
Daftar berhalaman (15/halaman), tandai dibaca per item atau semua. Ketuk →
navigasi ke objek terkait lewat data notifikasi.

### Profil
Foto (ubah), identitas, ringkasan progress belajar, ganti password, pengaturan
pelacakan (lihat ADR-0012), dan logout.

## Alur kritis

### Login pertama kali
```
Login (NISN+password) → 200, must_change_password=true
  → Ganti password (paksa) → sukses, token baru
  → Beranda
```

### Kumpul tugas saat sinyal putus
```
Isi jawaban → Kirim
  ├── online  → POST submit → sukses → tampilkan submission
  └── offline → simpan ke outbox + idempotency_key
                → banner "Menunggu koneksi"
                → koneksi kembali → kirim ulang → tampilkan submission
```
Kalau server membalas 422 saat flush (mis. deadline sudah lewat dan tugas
ditutup), item outbox ditandai gagal permanen dan siswa **diberi tahu secara
eksplisit** — jangan diam-diam dibuang.

### Ujian ter-*kill* di tengah jalan
```
Mengerjakan → app dimatikan OS
  → buka lagi → GET /exams/sessions/{id}
  → jawaban tersimpan dikembalikan, timer dihitung ulang dari expires_at
  → lanjut; kalau sudah lewat → submit otomatis (reason: timeout)
```

## Aturan UI

**Bahasa.** Indonesia, sapaan "kamu". Hindari jargon teknis di pesan error yang
dilihat siswa — "Koneksi terputus" bukan "Socket timeout".

**Loading.** Skeleton untuk daftar, bukan spinner layar penuh. Kalau ada data
cache, tampilkan itu dulu sambil menyegarkan di belakang.

**Empty state.** Setiap daftar wajib punya empty state dengan penjelasan dan
langkah lanjut, bukan cuma ilustrasi.

**Aksesibilitas.** Target sentuh minimal 48dp, kontras teks minimal 4.5:1,
dukung ukuran font sistem sampai 1.3×. Timer ujian tidak boleh **hanya**
dibedakan lewat warna saat waktu menipis — tambahkan ikon/teks.

**Destruktif.** Submit ujian dan logout butuh konfirmasi. Pin/unpin tidak.
