# ADR-0006 — go_router untuk navigasi deklaratif

- **Status:** Proposed
- **Tanggal:** 2026-09-04
- **Terkait:** [ADR-0005](0005-state-management-riverpod.md), [docs/05](../05-screens-and-flows.md)

## Konteks

Navigasi aplikasi ini punya tiga tuntutan yang tidak semuanya remeh:

1. **Guard berlapis dan wajib.** Belum login → login. Password masih default →
   layar ganti password, **dan seluruh rute lain diblokir** (mencerminkan
   middleware backend). Versi terlalu lama → force update. Ketiganya harus
   dievaluasi ulang setiap kali state auth berubah, dari mana pun.
2. **Deep link dari push notification** ke objek bersarang, misalnya
   `/materials/{materialId}/assignments/{assignmentId}`.
3. **Rute bersarang mengikuti domain.** Tugas dan ujian menempel ke materi
   (`assignments.material_id`), jadi rute datar tidak mencerminkan datanya.

Ditambah satu kebutuhan khusus: layar ujian harus berada **di luar** shell
bottom-navigation, supaya tidak ada jalan navigasi yang menggoda saat siswa
sedang mengerjakan.

## Keputusan (usulan)

Kami memakai **`go_router`** dengan rute deklaratif, `ShellRoute` untuk bagian
ber-bottom-navigation, dan satu fungsi `redirect` terpusat untuk semua guard.
`refreshListenable` disambungkan ke state auth supaya perubahan sesi langsung
memicu evaluasi ulang rute.

## Alternatif yang dipertimbangkan

### `Navigator` 1.0 (`push`/`pop` imperatif)
Ditolak. Guard jadi tersebar sebagai `if` di `initState` tiap layar — pola yang
pasti bocor: satu layar yang lupa mengecek "harus ganti password" akan menabrak
403 backend dan menjebak siswa. Deep link harus dirakit manual.

### `Navigator` 2.0 langsung (RouterDelegate sendiri)
Ditolak. Kontrol penuh, tapi API-nya terkenal berat dan mudah salah. Kita akan
menulis ulang sebagian besar go_router dengan kualitas lebih rendah.

### `auto_route`
Kandidat serius. Rute terketik dari code generation menghilangkan kesalahan
string path, dan guard-nya per-rute yang rapi. Ditolak tipis: satu generator
lagi di atas Riverpod + freezed, dan `redirect` terpusat go_router lebih cocok
untuk guard yang **saling berurutan dan berlapis** seperti kasus kita — di
auto_route logikanya cenderung tersebar di beberapa guard class.

### Beam
Ditolak. Ekosistem lebih kecil, dan go_router adalah paket yang didukung tim
Flutter — untuk project yang akan diserahkan ke orang lain, itu bernilai.

## Konsekuensi

**Positif**
- Semua guard di satu tempat, mustahil terlewat di layar tertentu.
- Deep link notifikasi jadi pemetaan URL biasa.
- Rute mencerminkan hierarki domain, jadi lebih mudah dipahami.

**Negatif**
- Path berbasis string tanpa keamanan tipe. Mitigasi: konstanta rute terpusat,
  tidak ada string path yang ditulis langsung di widget.
- `redirect` terpusat bisa membengkak jadi rumit. Mitigasi: batasi hanya pada
  guard sesi/versi; navigasi lain diselesaikan lewat aksi biasa.

**Kewajiban lanjutan**
- Urutan guard ditulis eksplisit di [docs/05](../05-screens-and-flows.md) dan
  punya test — salah urutan berarti siswa bisa lolos dari layar ganti password.

## Kapan keputusan ini perlu ditinjau ulang

Kalau rute tumbuh melewati ~25 dan kesalahan path jadi sumber bug berulang,
`auto_route` layak dihitung ulang.
