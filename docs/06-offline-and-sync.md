# 06 — Offline & Sync

Keputusan dasar: [ADR-0008](adr/0008-offline-cache-dan-outbox.md).

Target realistis: **baca offline + kirim tertunda.** Bukan aplikasi yang
sepenuhnya bisa jalan tanpa jaringan.

## Klasifikasi data

| Data | Offline? | Strategi |
|------|----------|----------|
| Profil siswa | ✅ baca | cache, segarkan saat buka app |
| Dashboard (course, stats) | ✅ baca | stale-while-revalidate |
| To-do list | ✅ baca | stale-while-revalidate |
| Daftar & detail materi | ✅ baca | cache per materi |
| File lampiran | ✅ kalau sudah diunduh | disimpan permanen sampai dihapus siswa |
| Detail tugas | ✅ baca | cache |
| Draft jawaban tugas | ✅ tulis | lokal dulu, kirim lewat outbox |
| Kiriman tugas | ⚠️ tertunda | outbox + `idempotency_key` |
| Notifikasi | ✅ baca | cache halaman pertama |
| **Ujian (quiz)** | ❌ | wajib online. Lihat [07](07-exam-mode.md) |
| Heartbeat progress | ❌ | dibuang kalau tidak terkirim (lihat bawah) |

## Stale-while-revalidate

Pola baca standar:

1. Repository mengembalikan data cache **segera** kalau ada.
2. Bersamaan, memicu permintaan jaringan.
3. Sukses → simpan ke cache, emit ulang ke UI.
4. Gagal → data cache tetap dipakai, UI menampilkan penanda tidak mencolok
   ("Terakhir diperbarui 2 jam lalu").

Yang **tidak** boleh terjadi: layar error merah padahal data cache tersedia.
Siswa dengan sinyal buruk akan melihat error itu terus-menerus.

Umur cache yang dianggap layak tampil (batas lunak, bukan penghapusan):

| Data | Batas lunak |
|------|-------------|
| Dashboard, to-do | 15 menit |
| Detail course, materi | 6 jam |
| Detail tugas | 15 menit (deadline & status bisa berubah) |
| Profil | 24 jam |

Lewat batas itu, data **tetap ditampilkan** — hanya penandanya jadi lebih jelas.

## Cache basi vs data yang dicabut

Ini jebakan yang mudah terlewat: materi/tugas yang sudah di-*unpublish* guru atau
lewat `available_until` **tetap ada di cache lokal**. Siswa bisa membukanya,
lalu setiap aksi ke server gagal 404 tanpa penjelasan.

Aturannya:

- Saat refresh daftar berhasil, **hapus entri cache yang tidak ada lagi di
  respons**. Jangan hanya menggabungkan (merge) — penghapusan tidak akan pernah
  terlihat.
- Saat membuka detail dan server membalas `404`, hapus entri lokalnya dan
  tampilkan: "Materi ini sudah tidak tersedia."
- Jangan pernah menganggap keberadaan di cache sebagai izin akses.

## Outbox (antrian kirim)

Satu tabel Drift, diproses berurutan.

```
outbox_items
  id              uuid (= idempotency_key)
  kind            'assignment_submission' | 'exam_submission' | 'profile_photo'
  target_id       uuid  (assignment_id / exam_id)
  material_id     uuid
  payload_json    text  (content, link_url)
  file_paths      text  (JSON array path lokal)
  attempts        int
  status          'pending' | 'sending' | 'failed_permanent'
  last_error      text
  created_at      datetime
  next_attempt_at datetime
```

### Aturan

1. **`id` = `idempotency_key`** yang dikirim ke server. Dibuat sekali saat item
   masuk antrian, **tidak pernah berubah pada percobaan ulang**. Ini yang
   mencegah duplikasi saat request terkirim tapi responsnya hilang.
2. **File disalin ke direktori aplikasi** saat item dibuat. Jangan simpan URI
   dari `file_picker` — file di cache sistem bisa dihapus OS sebelum antrian
   sempat jalan.
3. **Serial, bukan paralel.** Satu item pada satu waktu. Upload paralel di
   jaringan lemah malah membuat semuanya timeout.
4. **Backoff eksponensial**: 5s, 15s, 1m, 5m, 15m, lalu tiap 30m. Maks 12 kali
   percobaan.
5. **Pemicu flush**: aplikasi jadi foreground, konektivitas kembali, atau timer
   `next_attempt_at`.

### Klasifikasi kegagalan

| Respons | Tindakan |
|---------|----------|
| Sukses `2xx` | hapus item, perbarui cache dengan submission dari server |
| `401` | hentikan antrian, logout — jangan buang antriannya |
| `403 password_change_required` | hentikan, arahkan ke ganti password, antrian tetap utuh |
| `409` sudah ada | anggap sukses (idempoten), ambil state terbaru |
| `413`, `422` | **gagal permanen** — beri tahu siswa, jangan retry |
| `429` | hormati `Retry-After` |
| `5xx`, timeout, offline | retry dengan backoff |

Membedakan gagal permanen dari sementara itu penting. Kalau semua kegagalan
di-retry, item yang ditolak karena "deadline sudah lewat" akan mengulang selamanya
sambil menghabiskan baterai — dan siswa mengira tugasnya terkirim.

### Yang terlihat oleh siswa

Kartu status di detail tugas dan satu banner global. Kondisinya:

- **Tersimpan, menunggu koneksi** — netral, bukan merah.
- **Mengirim…** — dengan progres upload.
- **Terkirim** — dengan waktu, dari `submitted_at` server.
- **Gagal dikirim** — merah, dengan alasan dan tombol coba lagi.

Jangan pernah menampilkan "Terkirim" sebelum server mengonfirmasi.

## Draft lokal

Isian tugas disimpan otomatis ke lokal saat siswa mengetik (debounce ~1 detik).
Draft **bukan** outbox — dia tidak akan pernah terkirim sampai siswa menekan
kirim. Bedakan keduanya di UI dengan jelas; kebingungan di sini berarti siswa
mengira tugasnya sudah dikumpulkan padahal masih draft.

Draft dihapus setelah submission dikonfirmasi server.

## File terunduh

Disimpan di direktori aplikasi, diindeks per `media_id`, dengan checksum ukuran
untuk deteksi perubahan. Kebijakan:

- Tidak dihapus otomatis oleh cache eviction — siswa mengunduh justru untuk
  dibaca offline.
- Ada halaman "Kelola unduhan" di profil dengan total ukuran dan tombol hapus.
- Batas lunak 500 MB; lewat itu, sarankan siswa membersihkan.

## Heartbeat progress: sengaja tidak di-antre

Server menolak event dengan selisih jam lebih dari **10 menit**
(`max_clock_drift_minutes`). Heartbeat yang mengantre lebih lama dari itu akan
ditolak — jadi mengantrekannya hanya membuang penyimpanan dan baterai untuk
data yang pasti gagal.

Kebijakan: buffer di memori, kirim tiap ~30 detik atau saat layar ditutup.
Kalau gagal, **buang**. Kehilangan sebagian data analitik jauh lebih murah
daripada kompleksitas antrian yang hasilnya ditolak server.

## Penanganan konflik

Model data membuat konflik jarang: satu submission per siswa per tugas, dan
hanya siswa itu yang menulisnya. Yang mungkin terjadi:

| Skenario | Penanganan |
|----------|------------|
| Kirim dari HP saat versi lebih baru sudah ada di server | server menang; beri tahu siswa versinya diperbarui |
| Guru menutup tugas saat item masih di antrian | `422` → gagal permanen + pesan jelas |
| Dua perangkat mengantre kiriman berbeda | yang tiba terakhir menang; ini konsisten dengan perilaku web |

Kami **tidak** membangun resolusi konflik tiga arah. Untuk domain ini, biayanya
tidak sebanding.

## Cara mengetesnya

Wajib ada di test plan ([ADR-0014](adr/0014-strategi-testing.md)):

1. Kirim tugas dalam mode pesawat → nyalakan jaringan → tepat satu submission.
2. Matikan jaringan **tepat setelah request terkirim** → retry → tetap satu
   submission (uji idempotency).
3. Buka materi yang di-*unpublish* setelah di-cache → pesan "tidak tersedia",
   entri terhapus.
4. Isi outbox, lalu cabut token dari server → antrian berhenti, tidak hilang.
