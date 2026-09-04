# ADR-0002 — Flutter native, bukan WebView atau PWA

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/01](../01-overview.md), [ADR-0008](0008-offline-cache-dan-outbox.md)

## Konteks

`lms-app` sudah punya frontend siswa berbasis Inertia + React yang berjalan di
browser mobile. Pertanyaan wajar: kenapa tidak membungkusnya saja ke WebView,
atau menjadikannya PWA?

Repo `learn_mobile` sudah ada dan berisi hasil `flutter create`, jadi ada
kecenderungan awal ke Flutter. Tapi kecenderungan bukan alasan — keputusan ini
perlu dibenarkan dari kebutuhan.

Tiga kebutuhan yang tidak bisa dipenuhi web di konteks ini:

1. **Sinyal sekolah tidak stabil.** Siswa kehilangan draft dan tidak bisa membuka
   materi yang sudah pernah dibaca. Service worker bisa cache aset, tapi
   mengantre unggahan file besar dengan retry dan backoff jauh di luar
   kenyamanan Background Sync API — yang sampai hari ini masih tidak tersedia di
   Safari/iOS.
2. **Push notification.** Backend sudah menghasilkan notifikasi tugas dan nilai,
   tapi tidak ada kanal untuk mendorongnya ke HP. Web Push di iOS hanya jalan
   untuk PWA yang dipasang ke home screen — sesuatu yang tidak bisa diandalkan
   dilakukan siswa SMP/SMA.
3. **Ujian bertimer.** Tab browser mobile bisa di-*discard* OS kapan saja, dan
   *refresh* halaman di tengah ujian adalah kejadian rutin, bukan kasus tepi.

## Keputusan

Kami membangun aplikasi native dengan **Flutter** untuk Android dan iOS, memakai
API JSON ([ADR-0003](0003-api-json-v1-reuse-student-actions.md)) sebagai satu-satunya
sumber data. Tidak ada WebView untuk alur inti.

Flutter dipilih di atas React Native karena: satu tim kecil menangani dua
platform dengan satu bahasa, rendering konsisten di HP Android kelas bawah yang
jadi mayoritas pengguna, dan tidak ada ketergantungan pada bridge JavaScript
untuk layar ujian yang kritis. Kesamaan bahasa dengan frontend web (React) tidak
menolong di sini, karena tim web dan mobile berbeda orang.

## Alternatif yang dipertimbangkan

### WebView membungkus frontend Inertia
Paling murah dan paling cepat jadi. Ditolak: tidak menyelesaikan satu pun dari
tiga kebutuhan di atas. Upload file dari WebView rapuh, timer ujian tetap
sekarat saat tab di-*discard*, offline nol. Hasilnya "aplikasi KTP" — ada di
Play Store tapi tidak memberi nilai apa pun di atas membuka browser.

### PWA
Lebih baik dari WebView: bisa cache aset dan punya Background Sync di Android.
Ditolak karena iOS: Web Push hanya untuk PWA terpasang, Background Sync tidak
ada, dan penyimpanan bisa dibersihkan OS setelah beberapa minggu tidak dipakai —
yang berarti draft tugas siswa bisa hilang tanpa jejak.

### React Native
Layak secara teknis. Ditolak karena tidak ada keuntungan nyata untuk tim ini,
sementara Flutter memberi konsistensi rendering yang lebih baik di perangkat
kelas bawah dan repo-nya sudah ada.

### Native terpisah (Kotlin + Swift)
Kualitas terbaik per platform. Ditolak: dua basis kode untuk tim satu developer
mobile berarti fitur ujian ditulis dua kali — persis fitur yang paling tidak
boleh punya dua perilaku berbeda.

## Konsekuensi

**Positif**
- Offline, push, dan timer ujian bisa dikerjakan dengan benar.
- Satu basis kode untuk dua platform.
- Kontrol penuh atas perilaku saat aplikasi di-background — krusial untuk ujian.

**Negatif**
- Backend harus membangun lapisan API yang belum ada sama sekali
  ([docs/10](../10-backend-changes.md)) — ini pekerjaan nyata, bukan sekadar
  konfigurasi, dan memblokir semua fase lain.
- Dua permukaan klien (web + mobile) harus dijaga tetap konsisten. Mitigasi:
  keduanya memakai Action backend yang sama.
- Rilis lewat store berarti ada jeda, dan pengguna bisa tertinggal di versi lama.
  Karena itu [ADR-0013](0013-versioning-api-dan-force-update.md) ada.

**Kewajiban lanjutan**
- Folder `web/`, `linux/`, `macos/`, `windows/` bawaan `flutter create` dihapus —
  target itu tidak didukung dan hanya menambah kebingungan.

## Kapan keputusan ini perlu ditinjau ulang

Kalau iOS akhirnya mendukung Background Sync dan Web Push tanpa syarat instalasi,
**dan** kebutuhan ujian bertimer hilang dari scope, PWA layak dihitung ulang.
