# ADR-0015 — Format error API dengan kode mesin

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [ADR-0003](0003-api-json-v1-reuse-student-actions.md), [docs/03](../03-api-contract.md)

## Konteks

Backend hari ini mengembalikan error dalam beberapa bentuk berbeda: Inertia
mengubah `ValidationException` jadi redirect dengan session error, middleware
memakai `abort(403, 'pesan')`, dan beberapa controller mengembalikan
`response()->json(['message' => ...])`.

Bagi klien mobile, ini masalah nyata dan bukan soal estetika. Contoh paling
tajam ada di `EnsureStudentPasswordChanged`:

```php
abort(403, 'Ganti password default Anda terlebih dahulu.');
```

Dari sisi aplikasi, ini `403` dengan sebuah string bahasa Indonesia — persis
sama bentuknya dengan `403` karena siswa mencoba membuka materi kelas lain.
Padahal keduanya butuh perlakuan yang berlawanan: yang pertama harus mengarahkan
siswa ke layar ganti password, yang kedua harus menampilkan pesan generik.

Satu-satunya cara membedakannya tanpa kode mesin adalah **mencocokkan string
pesan** — yang akan rusak begitu ada yang memperbaiki typo di kalimat itu.

## Keputusan

Semua error dari `/api/v1` memakai satu bentuk dengan **kode mesin yang stabil**:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "NISN atau password salah.",
    "fields": { "nisn": ["NISN atau password salah."] }
  }
}
```

- `code` — string `snake_case` yang stabil, **untuk dibaca program**.
- `message` — bahasa Indonesia, **untuk dibaca siswa**.
- `fields` — hanya pada `validation_failed`.

Kode yang wajib ada:

| HTTP | `code` | Perlakuan klien |
|------|--------|-----------------|
| 401 | `unauthenticated` | logout |
| 403 | `password_change_required` | redirect ke ganti password |
| 403 | `account_inactive` | logout + pesan hubungi sekolah |
| 403 | `forbidden` | pesan generik |
| 404 | `not_found` | hapus dari cache, pesan generik |
| 409 | `conflict` | sinkronkan ulang state |
| 413 | `payload_too_large` | gagal permanen di outbox |
| 422 | `validation_failed` | tampilkan `fields` di form |
| 426 | `client_too_old` | layar force update |
| 429 | `too_many_requests` | hormati `Retry-After` |
| 500 | `server_error` | retry dengan backoff |

Klien memetakan `code` → `AppFailure` bertipe di satu interceptor
([ADR-0007](0007-http-client-dio.md)), dan **tidak pernah mencocokkan `message`**.

## Alternatif yang dipertimbangkan

### Mengandalkan HTTP status saja
Ditolak. Persis kasus di atas: satu status, beberapa arti yang butuh perlakuan
berbeda.

### Mencocokkan string pesan
Ditolak. Rapuh terhadap perubahan kata, mustahil dilokalkan, dan menciptakan
ketergantungan tak terlihat — memperbaiki typo di backend akan merusak aplikasi
tanpa ada yang menyadari sampai siswa terjebak.

### RFC 7807 (`application/problem+json`)
Standar dan bagus. Ditolak tipis: field `type` berupa URI menambah upacara tanpa
manfaat pada API internal satu konsumen. Bentuk di atas membawa informasi yang
sama dengan lebih sedikit basa-basi. Kalau kelak ada konsumen pihak ketiga,
migrasi ke 7807 tidak sulit.

### Kode error numerik (mis. `code: 1042`)
Ditolak. Tidak terbaca manusia, butuh tabel rujukan terpisah yang selalu basi,
dan membuat log jauh lebih sulit dibaca.

## Konsekuensi

**Positif**
- Klien bisa bereaksi tepat pada setiap kondisi, terutama tiga yang ditangani
  global: logout, redirect ganti password, force update.
- Pesan bisa diubah atau dilokalkan kapan saja tanpa merusak aplikasi.
- Log dan telemetri jadi bisa dikelompokkan per `code`.

**Negatif**
- Backend perlu handler error khusus untuk request JSON, ditambah penyesuaian
  di dua middleware yang ada.
- Daftar `code` harus dijaga tetap sinkron antara backend dan klien. Mitigasi:
  daftarnya di [docs/03](../03-api-contract.md) adalah rujukan tunggal, dan
  backend punya test yang menegaskan `code` untuk tiap kondisi.

**Kewajiban lanjutan**
- Menambah `code` baru berarti memperbarui [docs/03](../03-api-contract.md) dan
  `AppFailure` di klien. `code` yang tidak dikenal klien di-*fallback* ke
  `server_error` dengan pesan dari server — jangan sampai *crash*.
- `message` **tidak boleh** membocorkan detail internal (nama tabel, stack trace),
  dan **tidak boleh** membedakan "NISN tidak terdaftar" dari "password salah" —
  backend sengaja menyamakannya untuk mencegah enumerasi pengguna.

## Kapan keputusan ini perlu ditinjau ulang

Kalau API dibuka untuk konsumen pihak ketiga, pertimbangkan pindah ke RFC 7807.
