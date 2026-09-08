# ADR-0018 — Sentry untuk crash report, dengan penyaring wajib di sisi klien

- **Status:** Accepted
- **Tanggal:** 2026-09-08
- **Terkait:** [docs/08](../08-security-and-privacy.md), [docs/04](../04-app-architecture.md), [ADR-0014](0014-strategi-testing.md)

## Konteks

Sebagian bug hanya muncul di lapangan: WiFi sekolah yang padat, HP kelas bawah
dengan memori sempit, dan yang paling mahal — kegagalan di tengah ujian, yang
tidak bisa diulang dan tidak bisa diperbaiki setelah nilainya keluar. Tanpa
laporan otomatis, yang sampai ke kita hanya "aplikasinya error" tanpa jejak apa
pun.

Tapi crash report adalah jalan kebocoran data yang paling mudah terlewat,
justru karena isinya **dikumpulkan otomatis**. Tidak ada yang sengaja menulis
"kirim token siswa ke server pihak ketiga" — token itu ikut karena kebetulan ada
di header permintaan terakhir sebelum crash. Aplikasi ini memegang tiga hal yang
tidak boleh keluar dari perangkat:

| Data | Kenapa berbahaya |
|------|------------------|
| Token Sanctum | Kredensial. Siapa pun yang memegangnya bisa bertindak sebagai siswa itu |
| NISN | Identitas nasional siswa |
| Isi jawaban ujian | Bocor = nilai rusak, dan tidak bisa diperbaiki belakangan |

[docs/08](../08-security-and-privacy.md) sudah menetapkan aturannya. Yang belum
diputuskan: **di mana** penyaringan itu dijalankan, dan apa yang terjadi kalau
penyaringnya gagal.

## Keputusan

Kami memakai **`sentry_flutter`**, dengan penyaring yang berjalan **di
perangkat, sebelum event dikirim** — bukan mengandalkan penyaring sisi server
milik Sentry.

Empat aturan, seluruhnya diuji di `test/core/observability/`:

1. Header `Authorization` dan `Cookie` dibuang dari semua permintaan.
2. Field `password`, `password_confirmation`, `token`, `nisn` diganti penanda
   `[disaring]` di mana pun ia muncul, termasuk bersarang di dalam map dan list.
3. Body request/response **tidak dikirim sama sekali** untuk endpoint auth dan
   ujian — disaring atau tidak.
4. Identitas pengguna hanya `id` (UUID siswa). Nama, NISN, email, dan alamat IP
   dibuang, dan `sendDefaultPii` dimatikan eksplisit.

Dua keputusan pendukung:

**Event tidak pernah dibuang seluruhnya, hanya isinya.** Penyaring yang
mengembalikan `null` berarti kita kehilangan justru crash yang perlu diperbaiki.
Yang hilang harus datanya, bukan laporannya.

**Tanpa DSN, pelaporan mati.** Itu keadaan bawaan di dev: `SENTRY_DSN` masuk
lewat `--dart-define`, seperti `API_BASE_URL`. Pengembangan tidak boleh
bergantung pada layanan pihak ketiga, dan crash saat ngoding lebih berguna
dilihat langsung di konsol.

## Alternatif yang dipertimbangkan

### Mengandalkan Data Scrubber bawaan Sentry (sisi server)
Sentry bisa menyaring field sensitif setelah event diterima. Ditolak sebagai
mekanisme utama: datanya sudah **terlanjur meninggalkan perangkat dan melintasi
jaringan** sebelum disaring, dan aturannya diatur di dashboard — di luar repo,
tanpa riwayat, tanpa test, dan bisa diubah orang tanpa siapa pun tahu. Penyaring
sisi server tetap boleh dinyalakan sebagai lapis kedua, bukan lapis pertama.

### Firebase Crashlytics
Gratis dan sudah satu keluarga dengan FCM yang akan dipakai ([ADR-0011](0011-push-notification-fcm.md)).
Ditolak: pengelompokan error Dart-nya lebih lemah, breadcrumb-nya kurang kaya,
dan menambah ketergantungan pada Google di jalur yang tidak wajib. Sentry juga
punya kontrol `beforeSend` yang persis dibutuhkan aturan di atas.

### Tanpa crash reporting sama sekali
Paling aman secara privasi, dan sempat dipertimbangkan serius. Ditolak karena
memindahkan biayanya ke siswa: bug ujian yang tidak pernah terlihat akan terus
terjadi ke siswa berikutnya. Privasi dijaga dengan menyaring isinya, bukan
dengan menutup mata.

### Logger sendiri yang mengirim ke backend `lms-app`
Tidak menambah pihak ketiga, dan datanya tidak pernah keluar dari infrastruktur
sekolah. Ditolak untuk MVP: berarti membangun sendiri pengelompokan error,
simbolikasi stack trace, retensi, dan dasbornya — pekerjaan berbulan-bulan yang
tidak ada hubungannya dengan belajar-mengajar. Layak ditinjau ulang kalau ada
kebijakan sekolah yang melarang data keluar sama sekali.

## Konsekuensi

**Positif**
- Bug lapangan — terutama di alur ujian — punya jejak yang bisa ditelusuri ke
  versi rilis tertentu.
- Aturan privasinya **hidup sebagai kode dan test**, bukan sebagai paragraf di
  dokumen yang bisa dilupakan.
- Mati secara bawaan, jadi tidak ada laporan yang bocor dari laptop pengembang
  atau dari fork orang lain.

**Negatif**
- Penyaringnya buatan sendiri, jadi **ia hanya tahu field yang sudah kita
  daftarkan**. Field sensitif baru yang lupa didaftarkan akan lolos — dan
  lolosnya diam-diam, tanpa error.
- Laporan jadi kurang kaya. Body permintaan auth dan ujian tidak ada, padahal
  di situlah sebagian bug paling sulit berada. Ini pertukaran yang disengaja.
- Menambah SDK pihak ketiga ke dalam aplikasi yang dipakai anak sekolah, dengan
  permukaan serangan dan ukuran aplikasi yang ikut bertambah.

**Netral / kewajiban lanjutan**
- Setiap field sensitif baru **wajib** ditambahkan ke daftar penyaring beserta
  test-nya. Menambah field ke API tanpa memeriksa daftar ini adalah cara paling
  mungkin janji privasi ini rusak.
- `SentryUser` tidak boleh pernah diisi nama atau NISN. Penyaring sudah
  membuangnya sebagai lapis kedua, tapi lapis pertama tetap tanggung jawab
  pemanggil.
- Sebelum DSN dinyalakan di `prod`: sepakati masa retensi di Sentry, dan
  cantumkan keberadaannya di dokumen privasi Play/App Store.
- Build `prod` wajib `--obfuscate --split-debug-info`, jadi simbol perlu
  diunggah supaya stack trace-nya terbaca.
- **Peringatan Kotlin Gradle Plugin (KGP) saat build Android.** Flutter
  memperingatkan bahwa `sentry_flutter` memasang KGP, dan bahwa Flutter versi
  mendatang akan menolak build semacam itu. Duduk perkaranya:

  - `sentry_flutter` sejak 9.28.0 **sudah** mendukung built-in Kotlin AGP 9 —
    ia hanya memasang KGP kalau AGP < 9 atau `android.builtInKotlin=false`.
  - Proyek ini memakai AGP 9.1, dan `android/gradle.properties` diubah ke
    `android.builtInKotlin=true` (template Flutter mengisinya `false`). Jadi
    KGP **tidak benar-benar dipasang**; build debug dan release sama-sama lolos.
  - Peringatannya tetap muncul karena Flutter mendeteksi lewat **regex atas
    teks `build.gradle`**, bukan keadaan runtime (`FlutterPluginUtils.kt` —
    mereka sengaja begitu, karena evaluasi runtime menimbulkan masalah urutan
    di Gradle). String `apply plugin: 'kotlin-android'` tetap ada di dalam
    `if` yang tidak pernah jalan, dan regex tidak bisa membedakannya.

  Artinya peringatan ini **positif palsu** untuk proyek kita. Yang tersisa hanya
  bisa diselesaikan di hulu, dan risikonya nyata: kalau Flutter menjadikannya
  kegagalan tanpa mengubah cara deteksi, build kita gagal meski KGP tidak
  dipasang. Versi Flutter dipatok di CI, jadi kenaikan versi selalu jadi
  keputusan sadar — bukan kejutan di tengah rilis.

## Kapan keputusan ini perlu ditinjau ulang

- Kalau kita mulai mengirim log terstruktur (bukan hanya crash) — permukaan
  datanya berubah, dan aturan penyaringnya perlu ditulis ulang.
- Kalau ada kebijakan sekolah atau dinas yang melarang data siswa keluar dari
  infrastruktur sendiri.
- Kalau muncul jenis data sensitif baru, misalnya rekaman suara atau lokasi.
