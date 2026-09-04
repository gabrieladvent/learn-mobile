# ADR-0016 — Envelope response seragam `response_code` / `response_message` / `response_data`

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Supersedes:** [ADR-0015](0015-format-error-api.md)
- **Terkait:** [ADR-0007](0007-http-client-dio.md), [docs/03](../03-api-contract.md)

## Konteks

[ADR-0015](0015-format-error-api.md) memutuskan dua bentuk berbeda: sukses
dibungkus `{ "data": ... }`, error dibungkus `{ "error": { code, message, fields } }`.

Tim menetapkan konvensi organisasi yang berbeda: **satu envelope untuk semua
response**, sukses maupun gagal, dengan dua varian:

```json
{ "response_code": "", "response_message": "", "response_data": {} }
{ "response_code": "", "response_message": "" }
```

Konvensi ini berlaku lintas layanan di organisasi, jadi konsistensi antar-proyek
bernilai lebih tinggi daripada preferensi bentuk di satu proyek. Ini keputusan
yang sah dan tidak perlu dibantah — yang perlu dijaga adalah **properti teknis
yang membuat ADR-0015 ada sejak awal jangan ikut hilang**.

Properti itu: klien harus bisa membedakan dua kondisi yang berbagi HTTP status
yang sama tapi butuh perlakuan berlawanan. Contoh konkret dari
`EnsureStudentPasswordChanged`:

```php
abort(403, 'Ganti password default Anda terlebih dahulu.');
```

Dari sisi aplikasi ini `403` dengan sebuah kalimat — bentuknya identik dengan
`403` karena siswa membuka materi kelas lain. Yang pertama harus mengarahkan ke
layar ganti password; yang kedua harus menampilkan pesan generik. Tanpa kode
mesin, satu-satunya cara membedakan adalah mencocokkan string — yang rusak
begitu ada yang memperbaiki typo di kalimat itu.

## Keputusan

Kami memakai envelope seragam untuk seluruh `/api/v1`:

| Field | Isi | Wajib |
|-------|-----|-------|
| `response_code` | **kode mesin** `snake_case` yang stabil | ya |
| `response_message` | kalimat bahasa Indonesia untuk siswa | ya |
| `response_data` | payload | **dihilangkan** kalau tidak ada data |

**`response_code` memuat kode mesin, bukan HTTP status.** Ini bagian paling
penting dari keputusan ini. Nilainya sama persis dengan daftar `code` yang sudah
disepakati di ADR-0015 — hanya pindah posisi ke level atas envelope:

`success`, `bad_request`, `unauthenticated`, `password_change_required`,
`account_inactive`, `forbidden`, `not_found`, `conflict`, `payload_too_large`,
`validation_failed`, `client_too_old`, `too_many_requests`, `server_error`.

HTTP status tetap dikirim dengan benar di header. Envelope **melengkapi** status,
bukan menggantikannya — `200 OK` untuk semua response adalah anti-pola yang
merusak caching, monitoring, dan retry di lapisan HTTP.

Detail turunannya:

- Error validasi menaruh detail per-field di `response_data.fields`.
- Daftar berhalaman menaruh `items` dan `meta` di dalam `response_data`.
- Klien memetakan `response_code` → `AppFailure`, dan **tidak pernah mencocokkan
  `response_message`**.
- `response_code` yang tidak dikenal klien di-*fallback* ke `server_error`
  dengan pesan dari server — jangan sampai *crash*.

## Alternatif yang dipertimbangkan

### Mempertahankan ADR-0015 (`data` / `error` terpisah)
Ditolak. Konvensi organisasi lebih diutamakan, dan bentuk terpisah tidak memberi
keunggulan teknis yang cukup untuk melawan konsistensi lintas layanan.

### `response_code` berisi HTTP status sebagai string (`"200"`, `"403"`)
**Ditolak, dan ini penolakan yang paling penting di ADR ini.** Bentuknya rapi,
tapi mengembalikan persis masalah yang membuat ADR-0015 ditulis: dua kondisi
`403` yang berbeda jadi tak terbedakan, dan siswa terjebak di layar error tanpa
jalan keluar. Kalau konvensi organisasi kelak mewajibkan status numerik di field
ini, solusinya adalah **menambah** field kode mesin, bukan menghapusnya.

### `response_code` numerik bisnis (`"1042"`)
Ditolak. Tidak terbaca manusia, butuh tabel rujukan terpisah yang selalu basi,
dan membuat log jauh lebih sulit dibaca.

### Selalu mengirim `response_data` (`null` atau `{}` kalau kosong)
Ditolak tipis. Bentuk dua-varian sudah ditetapkan tim. Klien menangani field yang
absen dengan aman, jadi tidak ada biaya nyata.

### Selalu `200 OK` dengan status asli di dalam envelope
Ditolak tegas. Merusak penanganan error bawaan Dio, caching HTTP, monitoring
uptime, dan membuat setiap response harus di-parse dulu sebelum diketahui gagal
atau tidak.

## Konsekuensi

**Positif**
- Konsisten dengan layanan lain di organisasi.
- Satu bentuk untuk di-parse klien, sukses maupun gagal.
- Properti kunci ADR-0015 (kode mesin stabil) tetap utuh.

**Negatif**
- Payload sedikit lebih gemuk untuk response sukses.
- Setiap response harus melewati helper pembungkus. Kalau ada controller yang
  lupa memakainya, bentuknya jadi tidak konsisten — mitigasi: helper terpusat
  plus test kontrak.
- ADR-0015 dan seluruh contoh di [docs/03](../03-api-contract.md) harus
  diperbarui. Sudah dilakukan bersamaan dengan ADR ini.

**Kewajiban lanjutan**
- Backend menyediakan satu helper (`ApiResponse`) dan satu enum kode. Tidak ada
  controller yang menyusun array envelope secara manual.
- Exception handler membungkus **semua** exception untuk request JSON — termasuk
  yang dilempar framework, bukan hanya yang dilempar kode kita.
- `response_message` tidak boleh membocorkan detail internal, dan tidak boleh
  membedakan "NISN tidak terdaftar" dari "password salah" — backend sengaja
  menyamakannya untuk mencegah enumerasi pengguna.

## Kapan keputusan ini perlu ditinjau ulang

Kalau konvensi organisasi berubah lagi, atau kalau API dibuka untuk konsumen
pihak ketiga yang mengharapkan bentuk standar (RFC 7807).
