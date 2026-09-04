# ADR-0012 — Pelacakan progress belajar yang terbatas dan transparan

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/08](../08-security-and-privacy.md), [ADR-0008](0008-offline-cache-dan-outbox.md)

## Konteks

Backend punya sistem pelacakan progress belajar yang cukup rinci: tabel
`learning_progress_events`, `learning_progress_sessions`,
`learning_progress_daily_rollups`, dengan tipe event `open`, `focus`, `blur`,
`heartbeat`, `idle`, `close` untuk materi, tugas, dan ujian.

Backend juga sudah memikirkan sisi etisnya — ada kolom `tracking_opt_out` di
students dan `tracking_disclosure_seen_at` di users, plus endpoint
`/progress/disclosure-seen`. Ini keputusan yang bagus dan harus dihormati, bukan
dilewati.

Batasan server yang relevan (`config/learning_progress.php`):
maks 50 event per request, payload maks 32 KB, dan **toleransi selisih jam maks
10 menit**.

Di mobile ada dua tekanan tambahan yang tidak ada di web:

1. **Baterai dan kuota.** Heartbeat yang terlalu rajin di HP kelas bawah terasa
   langsung oleh siswa.
2. **Kemudahan melacak lebih jauh.** Aplikasi native *bisa* melacak di
   background, bisa tahu aplikasi lain yang dibuka. Kemampuan itu bukan alasan
   untuk memakainya — penggunanya anak di bawah umur.

## Keputusan

Kami mengimplementasikan pelacakan progress dengan **batas yang eksplisit**:

**Yang dilacak:**
- Event `open` dan `close` saat layar materi/tugas/ujian dibuka dan ditutup.
- `focus`/`blur` saat aplikasi masuk/keluar foreground **selama layar itu aktif**.
- `heartbeat` tiap 30 detik selama layar aktif dan aplikasi di foreground.

**Yang tidak dilacak:**
- Apa pun saat aplikasi di background atau tertutup.
- Aplikasi lain yang dibuka siswa, penggunaan perangkat secara umum, lokasi.
- Isi apa pun — event hanya berisi jenis, waktu, dan ID objek. Bukan yang diketik.

**Transparansi:**
- Pemberitahuan tampil **sebelum event pertama dikirim**, sekali, dengan bahasa
  yang dimengerti siswa: apa yang dicatat, siapa yang melihat, untuk apa.
- Setelah dibaca, panggil `/progress/disclosure-seen`.
- Status pelacakan dan `tracking_opt_out` terlihat dan bisa diubah di layar profil.

**Menghormati opt-out di klien:**
Kalau `tracking_opt_out` bernilai true, aplikasi **tidak mengirim apa pun**.
Server memang akan membuangnya, tapi data yang tidak pernah meninggalkan
perangkat tidak bisa bocor di jalan.

**Tidak diantre saat offline:**
Buffer di memori, kirim tiap ~30 detik atau saat layar ditutup. Kalau gagal,
**buang**.

## Alternatif yang dipertimbangkan

### Melacak seagresif mungkin (termasuk background)
Ditolak. Secara teknis bisa, secara etis tidak untuk anak di bawah umur, dan
akan menabrak kebijakan Families di Play Store. Nilai analitik tambahannya kecil
dibanding risikonya.

### Mengantre heartbeat offline seperti submission
Ditolak, dan ini penting: server menolak event dengan selisih jam lebih dari
10 menit. Heartbeat yang mengantre lebih lama dari itu **pasti ditolak**. Antrian
hanya menghabiskan penyimpanan, baterai, dan kuota untuk data yang dibuang di
ujung. Kehilangan sebagian data analitik jauh lebih murah.

### Tidak melacak sama sekali di mobile
Ditolak. Guru memakai data ini untuk melihat siswa yang tertinggal, dan
menghilangkannya di mobile membuat laporannya bias — siswa yang lebih banyak
memakai HP akan terlihat "tidak belajar".

### Interval heartbeat lebih pendek (10 detik)
Ditolak. Presisi tambahannya tidak mengubah kesimpulan guru mana pun, sementara
biayanya (baterai, kuota, beban server) nyata di perangkat kelas bawah.

## Konsekuensi

**Positif**
- Guru mendapat data yang setara antara pengguna web dan mobile.
- Pemakaian baterai dan kuota tetap wajar.
- Sikap terhadap privasi anak jelas, tertulis, dan bisa diaudit.

**Negatif**
- Data mobile sedikit kurang lengkap dari web (tidak ada pelacakan background).
  Ini disengaja, dan guru perlu tahu bahwa angkanya adalah "waktu aktif di
  layar", bukan "waktu belajar".
- Event yang hilang saat offline tidak bisa dipulihkan.

**Kewajiban lanjutan**
- Layar ujian tetap mengirim `focus`/`blur` sebagai **sinyal untuk guru**, bukan
  sebagai pemicu otomatis. Aplikasi tidak menutup ujian karena siswa pindah
  aplikasi ([docs/07](../07-exam-mode.md)).
- Batasan server (50 event, 32 KB) dihormati klien; batch dipecah kalau perlu.

## Kapan keputusan ini perlu ditinjau ulang

Kalau sekolah atau orang tua meminta pelacakan lebih dalam, jawabannya bukan
menambah pelacakan diam-diam — melainkan diskusi kebijakan dengan persetujuan
wali, dan ADR baru yang mencatat hasilnya.
