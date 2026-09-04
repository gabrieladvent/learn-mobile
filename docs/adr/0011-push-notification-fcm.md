# ADR-0011 — FCM untuk push notification

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/08](../08-security-and-privacy.md), [docs/10](../10-backend-changes.md)

## Konteks

Backend sudah menghasilkan empat notifikasi untuk siswa:
`StudentAssignmentPublished`, `StudentAssignmentGraded`, `StudentExamPublished`,
`StudentDeadlineReminder`. Keempatnya hanya memakai kanal `database` — tersimpan
di tabel `notifications`, dan baru terlihat kalau siswa membuka aplikasinya
sendiri.

Untuk pengingat deadline, itu berarti fiturnya praktis tidak berfungsi: siswa
yang ingat membuka aplikasi biasanya juga ingat deadline-nya.

Tidak ada infrastruktur realtime di backend (tidak ada Reverb/Pusher di
`composer.json`).

## Keputusan

Kami memakai **Firebase Cloud Messaging** untuk Android dan iOS (FCM meneruskan
ke APNs). Backend menambahkan kanal FCM ke keempat notifikasi yang sudah ada,
dengan tabel `device_tokens` baru.

Aturan isi notifikasi:

- Payload memuat `type` dan ID objek untuk deep link.
- **Tidak memuat isi sensitif.** Judul tugas boleh; nilai, feedback, dan isi
  jawaban tidak. Notifikasi tampil di layar terkunci dan bisa dibaca siapa pun
  yang memegang HP itu — dan HP siswa sering dipegang orang lain.

  Contoh: "Nilai tugas Matematika sudah keluar" — bukan "Nilai kamu: 62".

Token FCM dicabut saat logout dan saat FCM melaporkan `UNREGISTERED`.

## Alternatif yang dipertimbangkan

### Polling berkala dari aplikasi
Ditolak. Boros baterai dan kuota, latensinya buruk, dan di iOS aplikasi di
background tidak dijamin dapat waktu eksekusi — jadi tidak berfungsi persis saat
dibutuhkan.

### WebSocket / Laravel Reverb
Ditolak. Butuh infrastruktur baru yang belum ada, koneksi persisten paling
rapuh di jaringan buruk, dan tidak menyelesaikan kasus utama: memberi tahu siswa
saat aplikasi **tertutup**.

### OneSignal atau layanan push pihak ketiga
Ditolak. Menambah pemroses data pihak ketiga untuk data anak di bawah umur,
dengan SDK yang mengumpulkan lebih banyak dari yang kita butuhkan. FCM sudah
diperlukan untuk menyentuh APNs, jadi menambahkan lapisan lain hanya menambah
permukaan privasi.

### Notifikasi lokal saja (dijadwalkan di perangkat)
Ditolak sebagai solusi utama — tidak bisa tahu tugas baru yang dibuat guru
setelah aplikasi terakhir dibuka. Tetap dipakai sebagai **pelengkap** untuk
pengingat deadline yang sudah diketahui perangkat, karena itu bekerja tanpa
jaringan.

## Konsekuensi

**Positif**
- Pengingat deadline akhirnya benar-benar berfungsi.
- Tidak ada infrastruktur baru yang perlu dioperasikan sendiri.
- Deep link membawa siswa langsung ke objek yang dimaksud.

**Negatif**
- Ketergantungan pada Google Play Services. Di perangkat tanpa GMS, push tidak
  jalan — aplikasi harus tetap berfungsi penuh tanpanya, dan tidak boleh
  memaksa atau memblokir.
- Menambah Firebase sebagai pemroses data. Dideklarasikan di Data Safety Play
  Store dan privasi App Store.
- Pengiriman tidak dijamin; FCM adalah *best effort*. Notifikasi **tidak boleh**
  jadi satu-satunya cara siswa tahu ada tugas — daftar in-app tetap sumber
  kebenaran.

**Kewajiban lanjutan**
- Izin notifikasi diminta **setelah** login pertama dengan penjelasan singkat,
  bukan langsung saat aplikasi pertama dibuka.
- Token FCM dicabut dari server saat logout; kalau tidak, siswa berikutnya yang
  memakai perangkat itu akan menerima notifikasi milik siswa sebelumnya.
- Tidak ada SDK Firebase lain yang ditambahkan (Analytics, Ads) tanpa ADR baru.

## Kapan keputusan ini perlu ditinjau ulang

Kalau sekolah memakai perangkat tanpa Google Play Services dalam jumlah berarti,
perlu jalur alternatif — kemungkinan besar notifikasi lokal + sinkronisasi
berkala saat aplikasi dibuka.
