# 09 — Roadmap

Enam fase. Tiap fase menghasilkan sesuatu yang bisa diuji end-to-end — bukan
lapisan setengah jadi yang baru berguna di fase berikutnya.

Estimasi mengasumsikan **1 dev Flutter + 1 dev Laravel** bekerja paralel.
Angka ini kasar; perlakukan sebagai urutan besaran, bukan janji.

---

## Fase 0 — Fondasi API (backend) · ~1–1,5 minggu

**Blokir semua fase lain.** Tanpa ini, aplikasi tidak punya sumber data.

Pekerjaan ada di `lms-app`, rinciannya di [10 — Perubahan Backend](10-backend-changes.md).

- [ ] `routes/api.php` + Sanctum guard `student`
- [ ] Endpoint auth (login/logout/me) dengan token
- [ ] Kode error terstruktur (`password_change_required`, `account_inactive`, dst)
- [ ] Bungkus Action yang sudah ada jadi endpoint JSON
- [ ] Buang field `url` dari payload, tambahkan `material_id` di to-do
- [ ] `idempotency_key` untuk endpoint submit
- [ ] Pastikan `correct_answer` tersaring sebelum rilis hasil
- [ ] Endpoint unduh file berautorisasi untuk klien token
- [ ] Feature test untuk tiap endpoint

**Selesai kalau:** seluruh endpoint di [03](03-api-contract.md) bisa dipanggil
dengan Bearer token dan lolos test.

---

## Fase 1 — Kerangka aplikasi & Auth · ~1,5 minggu

- [ ] Tambah dependency ke `pubspec.yaml` (masih kosong hari ini)
- [ ] Flavor dev/staging/prod + `--dart-define`
- [ ] Dio + interceptor auth/error/logging, mapper `AppFailure`
- [ ] Secure storage untuk token
- [ ] go_router + guard (belum login / harus ganti password / force update)
- [ ] Tema, komponen dasar, skeleton loader
- [ ] Layar: splash, login, ganti password paksa
- [ ] Sentry + penyaring data sensitif
- [ ] CI: `analyze` + `test` (folder `.github/` sudah ada, isinya perlu dicek)

**Selesai kalau:** siswa bisa login dengan NISN, dipaksa ganti password, dan
sampai di beranda kosong. Token bertahan setelah app ditutup.

---

## Fase 2 — Beranda, Course, Materi · ~2 minggu

- [ ] Beranda: stats, daftar course, pin/unpin optimistis
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
- [ ] Force update ([ADR-0013](adr/0013-versioning-api-dan-force-update.md))
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
