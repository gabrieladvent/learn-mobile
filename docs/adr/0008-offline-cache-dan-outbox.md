# ADR-0008 — Cache baca + outbox tulis, bukan offline-first penuh

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/06](../06-offline-and-sync.md), [ADR-0009](0009-timer-ujian-otoritatif-server.md)

## Konteks

Pengguna aplikasi ini adalah siswa di sekolah dengan WiFi penuh sesak dan sinyal
seluler tidak stabil. Dua keluhan yang paling merusak kepercayaan:

1. Membuka aplikasi tanpa sinyal → layar error, padahal materi yang mau dibaca
   sudah pernah dibuka kemarin.
2. Menekan "kumpulkan tugas" saat sinyal putus → jawaban hilang, dan siswa baru
   sadar setelah deadline lewat.

Godaannya adalah membangun offline-first penuh: seluruh data disinkronkan dua
arah dengan resolusi konflik. Tapi model datanya tidak menuntut itu — **satu
siswa hanya menulis submission miliknya sendiri**, dijamin unique constraint
`(assignment_id, student_id)`. Konflik multi-penulis praktis tidak ada.

Sementara itu, ujian bertimer **tidak boleh** offline sama sekali: waktu
dipegang server, dan mengizinkan pengerjaan offline berarti membuka pintu
manipulasi yang tidak bisa dideteksi.

## Keputusan

Kami membangun **cache baca + outbox tulis**, bukan sinkronisasi dua arah penuh.

- **Baca:** stale-while-revalidate. Cache di Drift ditampilkan segera, lalu
  disegarkan dari jaringan. Kegagalan jaringan **tidak** menghasilkan layar
  error selama ada data cache.
- **Tulis:** submission masuk tabel outbox dengan `idempotency_key`, dikirim
  serial dengan backoff eksponensial, dan diklasifikasikan antara gagal
  sementara vs permanen.
- **Ujian quiz:** tidak masuk skema ini sama sekali — wajib online.
- **Heartbeat progress:** sengaja **tidak** diantre (lihat konsekuensi).

Drift dipilih sebagai penyimpanan karena query terketik dan migrasi skema yang
eksplisit — cache ini akan berevolusi seiring payload API berubah, dan migrasi
diam-diam adalah sumber korupsi data.

## Alternatif yang dipertimbangkan

### Offline-first penuh dengan sinkronisasi dua arah
Ditolak. Kompleksitasnya (vektor versi, resolusi konflik, rekonsiliasi) tidak
dibayar oleh domain yang tidak punya penulis bersamaan. Risikonya justru
menambah bug pada data yang paling penting: jawaban siswa.

### Online-only
Ditolak. Gagal pada dua keluhan utama yang jadi alasan aplikasi ini dibuat
([ADR-0002](0002-flutter-native-bukan-webview.md)).

### Cache HTTP saja (`dio_cache_interceptor`)
Ditolak. Cukup untuk baca, tapi tidak menyelesaikan sisi tulis — dan sisi tulis
yang paling merugikan siswa kalau gagal. Juga tidak memberi kontrol atas
pembersihan entri yang sudah dicabut server.

### Menyimpan cache di `shared_preferences` / file JSON
Ditolak. Tidak bisa di-query, tidak punya migrasi, dan akan berantakan begitu
bentuk data berubah.

## Konsekuensi

**Positif**
- Aplikasi berguna di jaringan buruk tanpa membangun mesin sinkronisasi.
- Jawaban tugas tidak pernah hilang karena masalah jaringan.
- Kompleksitas terkonsentrasi di satu tempat (repository), bukan tersebar.

**Negatif**
- Cache bisa memuat materi yang sudah dicabut guru. Ditangani dengan menghapus
  entri yang hilang dari respons refresh, dan menghapus lokal saat server
  membalas `404`. **Keberadaan di cache tidak pernah berarti izin akses.**
- Outbox menambah state yang harus terlihat jelas di UI. Kalau siswa salah
  membaca "menunggu koneksi" sebagai "terkirim", dampaknya buruk — karena itu
  draft dan outbox harus dibedakan tegas di layar.
- Backend harus mendukung `idempotency_key` — pekerjaan baru yang tidak ada di web.

**Kewajiban lanjutan**
- **Heartbeat progress tidak diantre.** Server menolak event dengan selisih jam
  > 10 menit (`max_clock_drift_minutes`), jadi antrian offline hanya menghasilkan
  data yang pasti ditolak. Buffer di memori, kirim berkala, buang kalau gagal.
- Retry otomatis di lapisan HTTP dilarang untuk endpoint non-idempoten
  ([ADR-0007](0007-http-client-dio.md)) — hanya outbox yang boleh mengirim ulang.

## Kapan keputusan ini perlu ditinjau ulang

Kalau nanti ada fitur yang benar-benar punya penulis bersamaan (misalnya tugas
kelompok yang diedit beberapa siswa), sinkronisasi dua arah untuk fitur itu
perlu ADR tersendiri — bukan mengubah keputusan ini secara global.
