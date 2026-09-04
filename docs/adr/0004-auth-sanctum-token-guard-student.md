# ADR-0004 — Autentikasi Sanctum token dengan guard `student`

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [ADR-0003](0003-api-json-v1-reuse-student-actions.md), [docs/08](../08-security-and-privacy.md)

## Konteks

Backend punya dua guard sesi: `web` (admin/guru) dan `student`. Siswa login
dengan **NISN + password**, bukan email — `users.email` bahkan nullable untuk
siswa. Password awal siswa adalah tanggal lahirnya, dan middleware
`EnsureStudentPasswordChanged` memaksa penggantian sebelum akses konten apa pun.

`laravel/sanctum` **sudah terpasang** di `composer.json` tapi belum dipakai
untuk apa pun.

Aplikasi mobile tidak punya sesi dan cookie. Ia butuh kredensial yang bertahan
antar restart, bisa dicabut dari server, dan tidak ikut terkirim otomatis ke
domain lain.

## Keputusan

Kami memakai **Sanctum personal access token** dengan provider `students`.
Guard baru `student-api` (driver `sanctum`, provider `students`) melayani
`/api/v1`. Satu token per perangkat, ditandai `device_name`.

Aturan yang menyertainya:

- Token disimpan **hanya** di `flutter_secure_storage` (Keystore/Keychain).
- Masa berlaku **30 hari sejak pemakaian terakhir**, diperbarui setiap request.
- Ganti password **mencabut semua token lain** milik siswa itu.
- `students.is_active = false` memutus akses seketika, tidak menunggu token habis.
- Verifikasi kredensial tetap memakai jalur `AuthenticateStudent` yang ada —
  termasuk **dummy hash check** untuk menyamakan waktu respons.

## Alternatif yang dipertimbangkan

### Sanctum SPA mode (cookie + CSRF)
Ditolak. Dirancang untuk SPA satu domain. Di aplikasi native berarti mengurus
cookie jar, `/sanctum/csrf-cookie`, dan masalah domain — kompleksitas tanpa
manfaat, dan cookie tidak dirancang untuk hidup berbulan-bulan di HP.

### JWT (tymon/php-open-source-saver)
Menarik karena tanpa state. Ditolak justru karena itu: **JWT tidak bisa dicabut**
tanpa membangun daftar blokir, yang mengembalikan state-nya. Kita butuh
pencabutan nyata untuk tiga kasus konkret — perangkat hilang, siswa
dinonaktifkan, dan ganti password. Menambah dependency baru padahal Sanctum
sudah ada juga tidak masuk akal.

### OAuth2 / Laravel Passport
Ditolak. Kompleksitas untuk masalah yang tidak kita punya: tidak ada klien pihak
ketiga, tidak ada delegasi izin.

### Access token pendek + refresh token
Lebih aman di atas kertas. Ditolak untuk MVP: menambah alur refresh dengan
kondisi balapan (beberapa request 401 bersamaan) di klien, sementara ancaman
yang ditutupnya kecil — token bocor dari perangkat siswa hanya memberi akses
sebagai siswa itu sendiri. Bisa ditinjau ulang.

## Konsekuensi

**Positif**
- Pencabutan token nyata, per perangkat, dari server.
- Tidak menambah dependency — Sanctum sudah ada.
- Model auth mobile terpisah bersih dari sesi web.

**Negatif**
- Setiap request menyentuh tabel `personal_access_tokens`. Pada skala satu
  sekolah, ini bukan masalah; kalau jadi masalah, cache `last_used_at`.
- Token 30 hari berarti perangkat yang hilang punya jendela akses sampai
  seseorang mencabutnya. Diterima: data yang terekspos adalah materi kelas dan
  nilai siswa itu sendiri, dan siswa bisa ganti password untuk mencabut.

**Kewajiban lanjutan**
- `AuthenticateStudent` saat ini menggabungkan verifikasi kredensial dengan
  login sesi + `session()->regenerate()`. Untuk API, bagian verifikasinya perlu
  diekstrak. **Dummy hash check wajib ikut terbawa** — itu perlindungan
  anti-enumerasi yang gampang hilang saat refactor.
- Klien wajib menangani `401` di mana pun dengan logout, tapi **tanpa menghapus
  outbox** — jawaban tugas siswa bukan milik kita untuk dibuang.

## Kapan keputusan ini perlu ditinjau ulang

Kalau LMS melayani banyak sekolah dalam satu instance dan butuh SSO, atau kalau
audit keamanan menuntut umur token pendek — saat itu refresh token layak dibangun.
