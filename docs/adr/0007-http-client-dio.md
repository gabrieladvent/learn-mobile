# ADR-0007 — Dio sebagai HTTP client

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [ADR-0016](0016-envelope-response-seragam.md), [ADR-0013](0013-versioning-api-dan-force-update.md)

## Konteks

Lapisan jaringan aplikasi ini harus menangani beberapa hal lintas-permintaan
yang kalau ditulis per-panggilan pasti akan tidak konsisten:

- menyisipkan `Authorization: Bearer` dan header versi klien di **setiap** request,
- menerjemahkan error HTTP jadi `AppFailure` bertipe di **satu** tempat,
- menangkap `401` dan `426` secara global untuk logout / force update,
- upload multipart dengan **progres** (siswa perlu tahu file 8 MB-nya sedang jalan),
- pembatalan request saat layar ditutup,
- timeout yang berbeda per jenis endpoint — auto-save ujian butuh timeout pendek
  dan agresif, upload butuh yang panjang.

## Keputusan

Kami memakai **`dio`** dengan tiga interceptor berurutan:

1. **AuthInterceptor** — sisipkan token, `X-Client-Version`, `X-Client-Platform`.
2. **ErrorInterceptor** — `DioException` → `AppFailure`; tangani `401`
   (logout), `403 password_change_required` (redirect), `426` (force update)
   secara global.
3. **LogInterceptor** — hanya di build non-produksi, dengan penyaring yang
   membuang token, password, dan NISN.

Timeout dasar: connect 10 dtk, receive 30 dtk. Auto-save ujian memakai override
5 dtk. Upload memakai override 5 menit.

## Alternatif yang dipertimbangkan

### Paket `http` resmi
Ditolak. Tidak punya interceptor, jadi header dan penanganan error harus
diulang di setiap pemanggilan — dan yang terlupa akan jadi bug halus. Tidak ada
progres upload maupun pembatalan.

### `chopper` / `retrofit` (client dari anotasi)
Menarik: definisi API terketik dan lebih sedikit kode manual. Ditolak untuk
sekarang — satu generator lagi, dan endpoint-nya hanya ~25 sehingga kode manual
masih terkelola. Bisa ditinjau ulang kalau backend menyediakan spesifikasi
OpenAPI, karena saat itu generator jadi jauh lebih berharga.

### `http` + pembungkus sendiri
Ditolak. Berarti menulis ulang interceptor, retry, dan progres upload dengan
kualitas lebih rendah dari paket yang sudah matang.

## Konsekuensi

**Positif**
- Kebijakan lintas-permintaan hidup di satu tempat dan tidak bisa terlewat.
- Progres upload dan pembatalan tersedia langsung.
- Mudah menyisipkan mock/interceptor palsu untuk test.

**Negatif**
- Dependency pihak ketiga di jalur paling kritis aplikasi. Diterima: Dio matang
  dan dipakai luas.
- Urutan interceptor punya arti dan mudah salah. Mitigasi: urutannya
  didokumentasikan di sini dan punya test.

**Kewajiban lanjutan**
- **Tidak ada retry otomatis untuk request non-idempoten.** Retry pada submit
  hanya boleh lewat outbox yang membawa `idempotency_key`
  ([ADR-0008](0008-offline-cache-dan-outbox.md)). Interceptor retry umum akan
  diam-diam menduplikasi kiriman tugas — jangan pasang.
- LogInterceptor **wajib mati** di rilis produksi; ini dicek saat review keamanan.

## Kapan keputusan ini perlu ditinjau ulang

Kalau backend menerbitkan spesifikasi OpenAPI, pertimbangkan `retrofit` di atas
Dio — bukan menggantinya.
