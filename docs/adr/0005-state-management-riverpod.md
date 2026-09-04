# ADR-0005 — Riverpod sebagai state management

- **Status:** Accepted (diketok 4 September 2026)
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/04](../04-app-architecture.md), [ADR-0006](0006-navigasi-go-router.md)

## Konteks

Aplikasi ini punya beberapa bentuk state yang berbeda sifatnya:

| Bentuk | Contoh | Sifat |
|--------|--------|-------|
| Sesi & auth | token, `must_change_password` | global, memengaruhi routing |
| Data server | dashboard, materi, tugas | async, perlu cache & refresh |
| State layar | isian form, soal aktif | lokal, sementara |
| Proses latar | outbox, konektivitas | global, hidup lintas layar |
| **Timer ujian** | sisa waktu, status auto-save | global-per-sesi, kritis, sensitif lifecycle |

Yang terakhir yang paling menentukan. Timer ujian harus bertahan saat navigasi
di dalam ujian, tidak boleh ter-reset karena widget di-*rebuild*, dan harus
bereaksi pada perubahan lifecycle aplikasi. State yang terikat pada `BuildContext`
akan menyulitkan ini.

Selain itu, sebagian besar layar adalah "ambil data, tampilkan, tangani
loading/error" — pola yang seharusnya tidak butuh banyak boilerplate.

## Keputusan

Kami memakai **Riverpod 2** dengan code generation (`riverpod_generator`),
`AsyncNotifier` untuk state yang mengambil data, dan `Notifier` untuk state
sinkron.

Alasan utamanya, berurutan:

1. **Provider tidak terikat `BuildContext`.** Timer ujian, outbox, dan pemantau
   konektivitas bisa hidup di luar pohon widget dan diuji tanpa Flutter binding.
2. **`AsyncValue` menangani loading/data/error secara bawaan.** Pola yang dipakai
   di hampir semua layar tidak perlu ditulis ulang tiap kali.
3. **`ref.invalidate` dan `keepAlive`** memberi kontrol refresh dan pembuangan
   cache yang cocok dengan pola stale-while-revalidate di
   [ADR-0008](0008-offline-cache-dan-outbox.md).
4. **Override provider di test** membuat penggantian repository jadi sepele —
   penting karena jalur ujian dan outbox wajib punya test.
5. Kesalahan penyusunan dependency tertangkap saat kompilasi, bukan saat runtime.

### Kenapa akhirnya Riverpod, bukan BLoC

Saat ADR ini ditulis, keputusannya digantungkan pada keakraban tim: "kalau tim
sudah terbiasa BLoC, pilih BLoC". Syarat itu ternyata tidak berlaku — repo
Flutter masih kosong dan tidak ada basis BLoC yang perlu dihormati. Tiga hal
yang menentukan:

1. **Volume kerja ada di layar biasa, bukan di ujian.** Empat dari lima kelompok
   fitur isinya "ambil, tampilkan, tangani loading/error". `AsyncValue`
   menyelesaikan pola itu tanpa kode tambahan; BLoC menuntut kelas event + state
   per layar untuk hasil yang sama.
2. **Tiga titik kritis butuh state di luar pohon widget.** Timer ujian, outbox,
   dan guard `go_router` semuanya harus hidup terlepas dari `BuildContext`.
3. **Pengembangnya satu orang.** Keunggulan utama BLoC — disiplin seragam saat
   banyak orang menyentuh kode yang sama — tidak berlaku di sini, sementara
   biaya boilerplate-nya tetap dibayar penuh.

## Alternatif yang dipertimbangkan

### BLoC (`flutter_bloc`)
Kandidat terkuat, dan **pilihan yang sepenuhnya sah**. Event/state eksplisit
menghasilkan jejak yang sangat jelas — berharga untuk mendiagnosis laporan
"jawaban ujian saya hilang". Ekosistem matang, pola tim besar sudah mapan.

Ditolak (tipis) karena: boilerplate event+state untuk layar yang hanya
"ambil dan tampilkan" jauh lebih banyak, dan `BlocProvider` tetap berbasis
`context` untuk akses — meski `Bloc` sendiri bisa hidup mandiri.

**Kalau tim sudah terbiasa BLoC, pilih BLoC.** Kerugian dari tim yang
canggung dengan tool barunya lebih besar daripada keunggulan Riverpod di sini.

### `provider` (paket lama)
Ditolak. Pendahulu Riverpod dari penulis yang sama; sudah tidak dikembangkan
aktif dan punya kelemahan yang justru diperbaiki Riverpod.

### GetX
Ditolak tegas. Menggabungkan state, DI, routing, dan util dalam satu paket
dengan banyak state global implisit. Sulit dites, sulit dilacak sumber
perubahannya, dan menyandera keseluruhan arsitektur pada satu paket.

### `setState` + `InheritedWidget` manual
Ditolak. Cukup untuk aplikasi kecil, tapi outbox dan timer ujian butuh state
yang hidup di luar pohon widget.

### `signals` / solusi baru lainnya
Ditolak untuk sekarang. Ergonomis, tapi ekosistem dan materi belajarnya belum
sebanding — dan project ini akan diserahkan ke orang lain.

## Konsekuensi

**Positif**
- Boilerplate minimal untuk mayoritas layar.
- State kritis (timer, outbox) bisa hidup dan dites di luar widget.
- Test jadi murah lewat override provider.

**Negatif**
- Kurva belajar nyata bagi yang terbiasa `setState` atau `provider`.
- Code generation berarti `build_runner` di alur kerja — perlu dijalankan dan
  hasilnya di-commit atau di-generate di CI.
- Riverpod terkenal "banyak cara untuk hal yang sama". Butuh disiplin konvensi
  supaya kode tetap seragam.

**Kewajiban lanjutan**
- Konvensi ditulis di [docs/04](../04-app-architecture.md) dan ditegakkan saat review.
- **Satu pendekatan saja.** Mencampur Riverpod dan BLoC di basis kode yang sama
  adalah hasil terburuk dari ADR ini — lebih buruk daripada memilih yang "kurang
  optimal" secara konsisten.
- **`ProviderObserver` wajib dipasang sejak Fase 1.** Ini menutup satu-satunya
  keunggulan BLoC yang benar-benar berarti di sini: jejak audit perubahan state.
  BLoC mencatat setiap transisi karena setiap perubahan punya nama; Riverpod
  tidak, jadi harus dibangun sendiri. Observer mencatat perubahan state jalur
  **ujian** dan **outbox** ke Sentry, supaya laporan "jawaban ujian saya hilang"
  bisa ditelusuri:

  ```
  answer(q3) → saving → saved 14:02:11
  connection lost → queued(q4) → submit failed (timeout)
  ```

  Tanpa observer ini, keputusan memilih Riverpod kehilangan penyeimbangnya.

## Kapan keputusan ini perlu ditinjau ulang

Kalau setelah Fase 2 terbukti waktu lebih banyak habis untuk berdebat pola
Riverpod daripada membangun fitur, tinjau ulang sebelum Fase 4 (ujian) dimulai —
jangan setelahnya. Mengganti state management di tengah fitur ujian adalah
skenario terburuk.
