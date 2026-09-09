# 09 — Roadmap

Enam fase. Tiap fase menghasilkan sesuatu yang bisa diuji end-to-end — bukan
lapisan setengah jadi yang baru berguna di fase berikutnya.

Estimasi mengasumsikan **1 dev Flutter + 1 dev Laravel** bekerja paralel.
Angka ini kasar; perlakukan sebagai urutan besaran, bukan janji.

---

## Fase 0 — Fondasi API (backend) · ✅ SELESAI 4 September 2026

**Blokir semua fase lain.** Tanpa ini, aplikasi tidak punya sumber data.

Pekerjaan ada di `lms-app`, rinciannya di [10 — Perubahan Backend](10-backend-changes.md).

- [x] `routes/api.php` + Sanctum guard `student-api`
- [x] Endpoint auth (login/logout/me) dengan token
- [x] Kode error terstruktur (`password_change_required`, `account_inactive`, dst)
- [x] Bungkus Action yang sudah ada jadi endpoint JSON
- [x] Buang field `url` dari payload, tambahkan `material_id` di to-do
- [x] `idempotency_key` untuk endpoint submit
- [x] Pastikan `correct_answer` tersaring sebelum rilis hasil
- [x] Endpoint unduh file berautorisasi untuk klien token
- [x] Feature test untuk tiap endpoint

Dikerjakan dalam lima PR di `learning-management-system`:
#34 auth · #35 dashboard & to-do · #36 course & materi · #37 tugas + terima
keterlambatan · ujian (menyusul).

**Hasil akhir:** 138 test, 495 assertion, Pint bersih.

Tiga hal yang berbeda dari rencana awal, dan alasannya:

- **Penutupan sesi ujian di server sudah ada sejak awal**
  (`exam:auto-submit-expired`, terjadwal tiap dua menit, lengkap dengan 3 test).
  Checklist ini keliru mencantumkannya sebagai pekerjaan baru.
- **Submit ujian membalas `200`, bukan `409`**, saat sesi sudah tersubmit —
  lihat [03](03-api-contract.md).
- **Envelope response berubah** mengikuti konvensi organisasi
  ([ADR-0016](adr/0016-envelope-response-seragam.md)), menggantikan ADR-0015.

Satu perubahan produk juga ikut dikerjakan di luar rencana: tugas kini bisa
menerima pengumpulan terlambat lewat sakelar `accepts_late_submission`
per tugas — lihat [02](02-domain-model.md).

---

## Fase 1 — Kerangka aplikasi & Auth · ~1,5 minggu

- [x] Tambah dependency ke `pubspec.yaml` (masih kosong hari ini)
- [x] Flavor dev/staging/prod (`applicationId` terpisah per lingkungan) + `--dart-define`
- [x] Dio + interceptor auth/error/logging, mapper `AppFailure`
- [x] Secure storage untuk token
- [x] go_router + guard (belum login / harus ganti password / force update)
- [x] Tema, komponen dasar, ~~skeleton loader~~ (menyusul di Fase 2, saat ada
      daftar yang perlu ditunggu)
- [x] Layar: splash, login, ganti password paksa
- [x] Sentry + penyaring data sensitif ([ADR-0018](adr/0018-crash-reporting-sentry-dengan-penyaring-klien.md))
- [x] CI: `analyze` + `test`

**Selesai kalau:** siswa bisa login dengan NISN, dipaksa ganti password, dan
sampai di beranda kosong. Token bertahan setelah app ditutup.

### Observability & CI

- **CI** (`.github/workflows/ci.yml`) menjalankan `analyze` + `test` di setiap
  PR. Langkah `build_runner` WAJIB ada di dalamnya: `*.g.dart` dan
  `*.freezed.dart` sengaja tidak ikut ter-commit, jadi hasil checkout yang
  bersih tidak bisa dikompilasi tanpa langkah itu.
- **Sentry** mati secara bawaan; menyalakannya dengan
  `--dart-define=SENTRY_DSN=...`. Penyaring data sensitif berjalan di
  perangkat sebelum event dikirim, dan aturannya diuji di
  `test/core/observability/` — lihat [ADR-0018](adr/0018-crash-reporting-sentry-dengan-penyaring-klien.md).
- **Sentry ditandai UUID siswa** saat login dan dibersihkan saat logout,
  disambungkan lewat `ref.listen` di `LearnApp` — bukan di dalam
  `AuthController`, supaya lapisan auth tidak perlu mengenal Sentry.
- **Flavor sungguhan**, bukan sekadar `--dart-define`: `dev`, `staging`, dan
  `prod` punya `applicationId` sendiri (`lms.student.dev` dan seterusnya), jadi
  build uji bisa terpasang berdampingan dengan aplikasi siswa. `applicationId`
  bawaan template (`com.example.learn_mobile`) diganti — Play Store menolak
  awalan `com.example`, dan nilainya tidak bisa diubah setelah terbit.
  Konsekuensinya `flutter run` sekarang **wajib** memakai `--flavor`.
- Cara unggah simbol untuk build `prod` ter-*obfuscate* ada di
  [04](04-app-architecture.md#simbol-untuk-build-ter-obfuscate). Belum
  diotomatiskan di CI karena butuh token Sentry sebagai secret repo.

### Force update ([ADR-0013](adr/0013-versioning-api-dan-force-update.md))

Dikerjakan lebih awal dari rencana — ADR-0013 menaruhnya di Fase 5, tapi
setengah mekanismenya (header versi klien, pemetaan kode `client_too_old`)
sudah ikut terbawa saat lapisan jaringan dibuat, dan setengah mekanisme adalah
keadaan yang menyesatkan: `426` diterjemahkan tapi tidak ada yang menindaknya.

- [x] Versi asli aplikasi di header `X-Client-Version` (sebelumnya nilai mati
      `1.0.0+1`, yang membuat force update tidak akan pernah terpicu)
- [x] `426` mengunci seluruh aplikasi lewat guard router, bukan per layar
- [x] Layar force update yang tidak bisa dilewati, tetap berguna tanpa
      `store_url`
- [x] `GET /app-config` saat cold start: mengunci sebelum siswa sempat login,
      dan banner pembaruan opsional yang bisa ditutup
- [x] Gagal ke arah aman — endpoint belum ada di backend dan siswa bisa offline,
      jadi setiap kegagalan pemeriksaan diperlakukan sebagai "tidak ada info"

Sisi backend sudah masuk `development` di `lms-app`: middleware `426`,
`GET /app-config`, dan 9 feature test — lihat [10 §10](10-backend-changes.md).
Kontraknya ada di [03](03-api-contract.md).

Yang sengaja belum dikerjakan: flag pemeliharaan. Itu bukan keadaan yang selesai
dengan memperbarui aplikasi, jadi butuh layar dan perilakunya sendiri.

---

## Fase 2 — Beranda, Course, Materi · ~2 minggu

- [~] Beranda: stats & daftar course **selesai**; pin/unpin optimistis menyusul
- [ ] To-do list tiga seksi
- [ ] Detail course dengan pengelompokan per topik
- [ ] Detail materi: teks, link, daftar file
- [ ] Unduh file + halaman kelola unduhan
- [ ] Cache Drift + stale-while-revalidate ([06](06-offline-and-sync.md))
- [ ] Pembersihan entri cache yang sudah dicabut server
- [ ] Profil: lihat, ganti foto, ganti password, logout

**Selesai kalau:** siswa bisa menjelajah semua materinya, dan membuka aplikasi
dalam mode pesawat masih menampilkan konten yang pernah dibuka.

---

## Fase 3 — Tugas & Outbox · ~2 minggu

- [ ] Detail tugas, deadline, lampiran guru
- [ ] Form jawaban: teks, link, file (validasi tipe & ukuran dari server)
- [ ] Draft lokal otomatis
- [ ] Outbox: antrian, backoff, klasifikasi gagal permanen
- [ ] Status pengiriman yang jelas di UI
- [ ] Tampilan nilai, feedback, linimasa aktivitas
- [ ] Uji skenario offline di [06](06-offline-and-sync.md)

**Selesai kalau:** tugas berisi file bisa dikumpulkan dari mode pesawat, terkirim
otomatis saat sinyal kembali, **tepat satu submission**.

---

## Fase 4 — Ujian · ~2,5–3 minggu

Fase terpanjang dan paling berisiko. Jangan dipadatkan.

- [ ] Detail ujian, percabangan `online_quiz` vs `submission`
- [ ] Mode `submission` (reuse jalur outbox dari Fase 3)
- [ ] Layar ujian: satu soal per halaman, peta soal, timer
- [ ] Timer monotonik + sinkronisasi ulang server
- [ ] Auto-save per jawaban + indikator status
- [ ] Penanganan offline saat ujian (banner bertingkat, antrian jawaban)
- [ ] Pemulihan sesi setelah app ter-*kill*
- [ ] Auto-submit saat waktu habis (klien **dan** server)
- [ ] `FLAG_SECURE`, kunci portrait, cegah layar mati
- [ ] Layar hasil dengan penghormatan `results_released_at`
- [ ] Seluruh checklist di [07](07-exam-mode.md) hijau
- [ ] **Uji lapangan di WiFi sekolah sungguhan**

**Selesai kalau:** semua checklist ujian lolos, termasuk uji lapangan.

---

## Fase 5 — Notifikasi & Rilis · ~1,5 minggu

- [ ] Backend: kanal FCM untuk 4 notifikasi yang sudah ada + tabel `device_tokens`
- [ ] Registrasi/pencabutan token FCM, izin notifikasi
- [ ] Deep link dari notifikasi ke objek terkait
- [ ] Daftar notifikasi in-app + tandai dibaca
- [x] Force update ([ADR-0013](adr/0013-versioning-api-dan-force-update.md)) —
      sisi klien sudah selesai di Fase 1; sisa pekerjaannya ada di backend
- [ ] Ikon, splash, nama aplikasi, screenshot store
- [ ] Data Safety (Play) & privasi (App Store)
- [ ] Uji beta tertutup dengan **satu kelas nyata**
- [ ] Rilis produksi bertahap

**Selesai kalau:** siswa menerima push tugas baru dan ketukannya membuka tugas
yang benar.

---

## Setelah MVP

Diurutkan berdasarkan nilai, bukan kemudahan:

1. **Kalender & pengingat lokal** — jadwal deadline dalam satu tampilan.
2. **Pencarian** materi & tugas lintas mata pelajaran.
3. **Mode gelap.**
4. **Rapor progress yang lebih kaya** dari `learning_progress_daily_rollups`.
5. **Dukungan tablet & landscape.**
6. **Aksesibilitas lanjutan** — audit screen reader menyeluruh.
7. **Multi-sekolah** kalau backend jadi melayani banyak `School` dalam satu instance.

## Kriteria non-fungsional (berlaku sejak Fase 2)

| Aspek | Target |
|-------|--------|
| Cold start → beranda tampil | < 2,5 dtk di perangkat kelas bawah |
| Ukuran APK (rilis, split ABI) | < 25 MB |
| Perangkat minimum | Android 8.0 (API 26), iOS 13 |
| Crash-free session | > 99,5% |
| Pemakaian data buka beranda | < 200 KB tanpa file |
| Coverage test unit + widget | > 60%, dengan jalur ujian & outbox wajib tertutup |

## Risiko

| Risiko | Dampak | Penanganan |
|--------|--------|------------|
| Fase 0 molor | semua tersumbat | mulai Fase 1 pakai mock server dari [03](03-api-contract.md) |
| Ujian di jaringan buruk | nilai siswa rusak, kepercayaan hilang | Fase 4 diberi waktu longgar + uji lapangan wajib |
| Doc backend stale menyesatkan | salah asumsi struktur data | dokumen ini mengikuti migrasi, bukan doc lama |
| Ekspektasi anti-cheat berlebihan dari sekolah | kecewa saat rilis | batas kemampuan dinyatakan tertulis di [07](07-exam-mode.md) |
| Backend berubah tanpa memberi tahu mobile | app rusak di produksi | versi `/api/v1` + kontrak tertulis + test kontrak |
