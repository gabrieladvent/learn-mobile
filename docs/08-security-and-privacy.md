# 08 — Keamanan & Privasi

Konteks yang menentukan seluruh dokumen ini: **penggunanya anak di bawah umur.**
Standarnya lebih tinggi dari aplikasi konsumen biasa, dan "kumpulkan dulu,
pikirkan nanti" bukan pilihan.

## Model ancaman

| Ancaman | Realistis? | Mitigasi |
|---------|-----------|----------|
| Siswa membaca token dari perangkatnya sendiri | ya, di HP root | secure storage; token hanya berkuasa sebagai siswa itu sendiri |
| Siswa memanipulasi timer ujian | **ya, motivasinya tinggi** | timer & penutupan otoritatif di server ([07](07-exam-mode.md)) |
| Siswa membaca payload API lewat proxy | ya, tidak sulit | jangan pernah kirim `correct_answer` sebelum rilis; jangan kirim data siswa lain |
| Siswa mengakses materi kelas lain | ya | otorisasi di server (enrollment check), bukan filter di klien |
| Password default mudah ditebak (tanggal lahir) | **ya, paling berbahaya** | paksa ganti saat login pertama |
| Token bocor lewat log / crash report | ya, sering terjadi | penyaring log; tidak ada `print` |
| Perangkat hilang / dipinjam | ya | logout jarak jauh lewat pencabutan token, sesi kedaluwarsa |
| MITM di WiFi sekolah | ya | HTTPS wajib, cleartext dimatikan |

Yang **bukan** target pertahanan: siswa mencontek dengan HP kedua atau buku.
Lihat batas jujur di [07](07-exam-mode.md).

## Autentikasi

Sanctum personal access token, guard `student`.
Detail: [ADR-0004](adr/0004-auth-sanctum-token-guard-student.md).

- Token disimpan **hanya** di `flutter_secure_storage`
  (Android Keystore / iOS Keychain). Tidak pernah di `shared_preferences`,
  tidak pernah di database aplikasi, tidak pernah di log.
- Satu token per perangkat, dengan `device_name` supaya bisa dicabut selektif.
- Masa berlaku: **30 hari sejak penggunaan terakhir**. Nilainya kompromi antara
  keamanan dan kenyataan bahwa siswa tidak hafal password barunya.
- `401` di mana pun → hapus token, bersihkan data sensitif, ke layar login.
  **Jangan** hapus outbox — jawaban tugas siswa bukan milik kita untuk dibuang.

### Ganti password mencabut token lain
Setelah `PATCH /profile/password` sukses, semua token siswa itu dicabut kecuali
yang sedang dipakai. Tanpa ini, mengganti password tidak benar-benar menutup
akses dari perangkat yang sudah telanjur login.

### Akun dinonaktifkan
`students.is_active = false` harus **langsung** memutus akses, bukan menunggu
token kedaluwarsa. Backend mengecek ini di setiap request (middleware
`EnsureStudentActive`); klien menangani `403 account_inactive` dengan logout
paksa dan pesan "Akunmu dinonaktifkan. Hubungi sekolah."

## Penyimpanan lokal

| Data | Tempat | Terenkripsi |
|------|--------|-------------|
| Token | secure storage | ✅ OS |
| Profil, dashboard, materi, tugas | Drift | ⚠️ tidak — lihat bawah |
| Draft jawaban tugas | Drift | ⚠️ tidak |
| Jawaban ujian (jaring pengaman) | secure storage / DB terenkripsi | ✅ wajib |
| Soal ujian | **memori saja** | — tidak dipersistenkan |
| File terunduh | direktori privat aplikasi | ✅ sandbox OS |

Cache konten pembelajaran sengaja tidak dienkripsi: isinya materi kelas yang
memang boleh dibaca siswa itu, dan enkripsi DB penuh menambah biaya kinerja di
HP kelas bawah tanpa menutup ancaman nyata. Yang dienkripsi adalah hal yang
kalau bocor merugikan: token dan jawaban ujian.

Saat logout: hapus token, cache konten, draft, jawaban ujian, dan file terunduh.
Perangkat sering dipakai bergantian antar saudara.

## Transport

- HTTPS wajib di semua flavor kecuali `dev` lokal.
- Android: `usesCleartextTraffic=false`; iOS: ATS tidak dilonggarkan.
- **Certificate pinning: tidak dipakai.** Biaya operasionalnya (rotasi
  sertifikat mematikan aplikasi terpasang) lebih besar dari manfaatnya untuk
  domain ini. Bisa ditinjau ulang kalau sekolah memakai jaringan dengan proxy
  TLS yang bermusuhan.
- Tidak ada rahasia yang ditanam di aplikasi. Build `prod` pakai
  `--obfuscate --split-debug-info`.

## Data pribadi yang diproses

| Data | Kenapa dibutuhkan | Catatan |
|------|-------------------|---------|
| NISN, nama, kelas | identitas & login | ⚠️ NISN adalah identitas nasional — **jangan pernah masuk log atau crash report** |
| Tanggal lahir | password awal | jangan tampilkan di UI lebih dari yang perlu |
| Foto profil | tampilan | opsional |
| Nilai, submission | inti LMS | |
| Waktu belajar & event fokus | analitik guru | paling sensitif — lihat bawah |
| Token FCM | notifikasi | dicabut saat logout |

**Tidak dikumpulkan:** lokasi, kontak, daftar aplikasi terpasang, kamera/mikrofon,
IMEI/identitas perangkat permanen.

## Pelacakan progress belajar

Backend merekam `open`, `focus`, `blur`, `heartbeat`, `idle`, `close` per materi,
tugas, dan ujian. Ini pengawasan terhadap anak, dan harus diperlakukan begitu.

Kewajiban aplikasi:

1. **Pemberitahuan sebelum data pertama dikirim.** Backend sudah menyediakan
   `tracking_disclosure_seen_at` dan endpoint `/progress/disclosure-seen`.
   Tampilkan penjelasan sekali, dengan bahasa yang dimengerti siswa: apa yang
   dicatat, siapa yang melihatnya, dan untuk apa.
2. **Hormati `tracking_opt_out`.** Kalau siswa memilih keluar, **jangan kirim
   apa pun** — jangan andalkan server yang membuang. Data yang tidak pernah
   dikirim tidak bisa bocor.
3. **Hanya saat aktif di layar terkait.** Tidak ada pelacakan di background,
   tidak ada pengumpulan saat aplikasi tertutup.
4. **Tidak ada isi.** Event hanya berisi jenis, waktu, dan ID objek — bukan apa
   yang diketik siswa.

Detail teknis: [ADR-0012](adr/0012-learning-progress-tracking-mobile.md).

## Logging & crash report

Penyaring wajib sebelum apa pun dikirim ke Sentry:

- Buang header `Authorization` dan `Cookie`.
- Buang field `password`, `password_confirmation`, `token`, `nisn`.
- Body request/response **tidak dikirim** untuk endpoint auth dan ujian.
- ID pengguna di Sentry memakai UUID siswa, **bukan NISN atau nama**.

Di build `prod`, log jaringan verbose dimatikan sepenuhnya.

## Konten tak tepercaya

`materials.content` ditulis guru lewat editor dan bisa memuat HTML.
Kalau dirender lewat WebView: JavaScript **mati**, navigasi eksternal diblokir,
tidak ada bridge ke kode native. Kalau dirender sebagai teks kaya: pakai parser
yang menyaring tag berbahaya.

`link_url` dari guru dibuka lewat browser eksternal, bukan WebView in-app, dan
tampilkan domainnya sebelum membuka.

Nama file lampiran juga tidak tepercaya — jangan pakai apa adanya sebagai path
penyimpanan (path traversal). Simpan dengan nama berbasis `media_id`, tampilkan
nama aslinya di UI.

## Perizinan aplikasi

Minimal, dan diminta saat dibutuhkan dengan penjelasan:

| Izin | Untuk | Kapan diminta |
|------|-------|---------------|
| Internet | semua | otomatis |
| Notifikasi (Android 13+, iOS) | push | setelah login pertama, dengan alasan |
| Baca file (pemilih) | lampiran tugas | saat menekan "pilih file" |
| Kamera | foto profil & jawaban tugas | opsional, saat dipakai |

Tidak meminta: lokasi, kontak, penyimpanan penuh, akses semua file.

## Distribusi & kepatuhan

- Play Store: isi **Data Safety** sesuai tabel di atas dengan jujur. Aplikasi
  masuk kategori pendidikan dengan audiens anak → kebijakan **Families**
  berlaku: tidak ada iklan bertarget, tidak ada SDK analitik iklan.
- App Store: `Age Rating` 4+, deklarasi privasi sesuai.
- Tidak ada SDK pihak ketiga selain Firebase Messaging dan Sentry. Setiap
  tambahan SDK harus lewat ADR baru.

## Checklist review keamanan

- [ ] Token tidak pernah muncul di log, Sentry, atau cache jaringan.
- [ ] NISN tidak pernah masuk telemetri.
- [ ] `correct_answer` tidak ada di payload sebelum hasil dirilis.
- [ ] Logout menghapus token, cache, draft, jawaban ujian, file, dan token FCM.
- [ ] Ganti password mencabut token perangkat lain.
- [ ] `403 account_inactive` memutus akses seketika.
- [ ] Tidak ada cleartext HTTP di build rilis.
- [ ] WebView (kalau dipakai) tanpa JavaScript.
- [ ] Pemberitahuan pelacakan tampil sebelum event pertama dikirim.
- [ ] `tracking_opt_out` benar-benar menghentikan pengiriman di sisi klien.
