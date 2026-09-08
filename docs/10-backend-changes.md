# 10 — Perubahan yang Dibutuhkan di `lms-app`

Dokumen ini ditujukan untuk tim backend. Isinya daftar pekerjaan konkret supaya
aplikasi mobile bisa dibangun, diurutkan berdasarkan ketergantungan.

Kabar baiknya: **sebagian besar logika sudah ada.** Semua `app/Actions/Student/*`
mengembalikan `array` polos dan tidak menyentuh Inertia. Yang kurang adalah
lapisan transport JSON + autentikasi token di depannya.

---

## 1. Lapisan API

**Buat `routes/api.php`** (belum ada) dan daftarkan di `bootstrap/app.php`
dengan prefix `api` serta middleware `api`.

Struktur yang disarankan:

```
app/Http/Controllers/Api/V1/Student/
├── AuthController.php
├── DashboardController.php
├── CourseController.php
├── MaterialController.php
├── AssignmentController.php
├── ExamController.php
├── ProgressController.php
├── ProfileController.php
├── NotificationController.php
└── DeviceController.php
```

Controller ini **memanggil Action yang sama** dengan controller web, lalu
membungkus hasilnya jadi JSON. Jangan menyalin logikanya — kalau logika
terduplikasi, web dan mobile akan menyimpang diam-diam.

```php
public function index(GetStudentDashboard $action): JsonResponse
{
    $student = $request->user();   // guard student, driver sanctum

    return response()->json(['data' => $action->handle($student)]);
}
```

---

## 2. Autentikasi token

`laravel/sanctum` **sudah ada** di `composer.json` — tinggal dikonfigurasi.

- [ ] Tambah guard di `config/auth.php`:
  ```php
  'student-api' => ['driver' => 'sanctum', 'provider' => 'students'],
  ```
- [ ] `Student` model pakai trait `HasApiTokens`.
- [ ] `POST /api/v1/auth/login`: pakai `AuthenticateStudent` untuk verifikasi,
      **tapi jangan panggil `Auth::guard('student')->login()` dan
      `session()->regenerate()`** — API tidak bersesi.

  Cara paling bersih: ekstrak bagian verifikasi kredensial dari
  `AuthenticateStudent` jadi method/kelas tersendiri (mis. `VerifyStudentCredentials`),
  lalu web memakai verifikasi + login sesi, API memakai verifikasi + terbitkan
  token. Pertahankan **dummy hash check** untuk mencegah user-enumeration lewat
  timing — itu perlindungan yang sudah benar dan mudah hilang saat refactor.

- [ ] Rate limit login sama dengan web: 5 percobaan/menit per `nisn|ip`.
- [ ] Kedaluwarsa token 30 hari sejak pemakaian terakhir
      (`sanctum.expiration` + pembaruan `last_used_at`).
- [ ] `PATCH /profile/password` sukses → cabut semua token siswa **kecuali** yang
      sedang dipakai, lalu terbitkan token baru untuk perangkat ini.

---

## 3. Middleware versi API

`EnsureStudentActive` dan `EnsureStudentPasswordChanged` sudah ada, tapi
outputnya berorientasi web (`redirect()`), dan cabang `expectsJson()`-nya hanya
`abort(403, '...')` — **tanpa kode mesin**.

Aplikasi mobile tidak bisa membedakan "harus ganti password" dari "kamu tidak
berhak" hanya dari string bahasa Indonesia, dan siswa akan terjebak di layar
error tanpa jalan keluar.

- [ ] Kembalikan JSON dengan `error.code` yang stabil:
      `password_change_required`, `account_inactive`.
- [ ] Whitelist untuk API: endpoint ganti password, logout, dan `/auth/me`.

---

## 4. Envelope response seragam

Semua response `/api/v1` — sukses maupun gagal — memakai satu envelope, sesuai
[ADR-0016](adr/0016-envelope-response-seragam.md):

```json
{ "response_code": "success", "response_message": "Berhasil", "response_data": { } }
{ "response_code": "validation_failed", "response_message": "...",
  "response_data": { "fields": { "nisn": ["..."] } } }
```

`response_data` dihilangkan kalau tidak ada data.

⚠️ `response_code` berisi **kode mesin**, bukan HTTP status. HTTP status tetap
dikirim benar di header — envelope melengkapi, bukan menggantikan.

Implementasi: satu helper terpusat (`App\Http\Responses\ApiResponse`) plus satu
enum kode. **Tidak ada controller yang menyusun array envelope manual.**
Exception handler membungkus semua exception untuk request JSON, termasuk yang
dilempar framework.

Peta minimum: `ValidationException` → 422 `validation_failed`,
`AuthenticationException` → 401 `unauthenticated`,
`NotFoundHttpException` → 404 `not_found`,
`ThrottleRequestsException` → 429 `too_many_requests` (+ header `Retry-After`).

---

## 5. Penyesuaian payload

### Buang `url`
`GetStudentStats` dan `BuildStudentTodoList` menyisipkan hasil `route()` Laravel
(URL web) ke payload. Untuk API, hilangkan — URL web tidak berarti di aplikasi.

### Tambah `material_id`
Sebagai gantinya, `BuildStudentTodoList` harus menyertakan `material_id` di tiap
item. Klien butuh itu untuk menyusun rute bersarang
(`/materials/{material}/assignments/{assignment}`); tanpa itu, to-do list tidak
bisa diklik.

### `download_path`, bukan URL absolut
Payload file mengirim path relatif endpoint unduh, bukan URL bertanda tangan.

---

## 6. Unduh file untuk klien token

`ServesGuardedMedia` sudah benar: file di disk privat, distream lewat route
berautorisasi. Yang perlu:

- [ ] Route unduh versi API yang menerima Bearer token (bukan cookie sesi).
- [ ] Dukung header `Range` supaya unduhan besar bisa dilanjutkan di jaringan buruk.
- [ ] Kirim `Content-Length` dan `ETag` agar klien bisa mendeteksi perubahan.

---

## 7. Idempotency untuk endpoint submit

Baru — tidak ada padanannya di web, tapi **wajib** untuk antrian upload offline.
Tanpa ini, request yang terkirim tapi responsnya hilang akan dikirim ulang dan
bisa menimpa jawaban yang lebih baru.

Berlaku untuk: submit tugas, submit ujian mode `submission`.

- [ ] Terima `idempotency_key` (UUID) di body.
- [ ] Simpan `(student_id, key)` → ringkasan respons, TTL 24 jam (cache/tabel).
- [ ] Kunci yang sudah pernah dipakai → kembalikan respons tersimpan, jangan
      proses ulang.
- [ ] Kunci hilang → tolak `422`, jangan diam-diam jalan tanpa proteksi.

---

## 8. Ujian

- [ ] `GET /exams/sessions/{id}` sudah mengirim `expires_at` dan `server_time` —
      **pertahankan keduanya**, klien bergantung pada pasangan itu untuk timer.
- [ ] **Verifikasi ulang** bahwa `correct_answer` tidak ikut di payload soal
      sebelum `results_released_at` lewat. Ini kewajiban server; memfilter di
      klien tidak ada gunanya karena payload bisa dibaca lewat proxy.
- [x] **Penutupan sesi di sisi server** — ternyata **sudah ada** sejak sebelum
      pekerjaan mobile dimulai: `AutoSubmitExpiredExamSessionsCommand`
      (`exam:auto-submit-expired`), terjadwal tiap dua menit di
      `routes/console.php` dengan `withoutOverlapping()` + `onOneServer()`.
      Sesi dikunci baris, kedaluwarsa dihitung ulang dari `started_at + duration`,
      dan `submitted_at` dicatat pada **waktu kedaluwarsa sebenarnya** — bukan
      waktu job berjalan — lalu `submission_reason` diisi `auto_timeout`.
      Sudah punya 3 feature test. Tidak ada yang perlu dikerjakan.
- [x] `POST .../submit` pada sesi yang sudah tersubmit → **`200`, bukan `409`**.
      Action-nya memang sudah idempoten, dan membalas error untuk pengulangan
      yang wajar justru memaksa klien memperlakukan error sebagai sukses.
      Lihat catatan di [03](03-api-contract.md).

---

## 9. Push notification

Empat notifikasi sudah ada (`StudentAssignmentPublished`, `StudentAssignmentGraded`,
`StudentExamPublished`, `StudentDeadlineReminder`) tapi hanya kanal `database`.

- [ ] Tabel `device_tokens`: `student_id`, `token`, `platform`, `app_version`,
      `last_used_at`; unik per `token`.
- [ ] `POST /devices`, `DELETE /devices/{token}`.
- [ ] Tambah kanal FCM ke keempat notifikasi. Payload memuat `type` dan ID objek
      untuk deep link — **jangan memuat isi sensitif** (nilai, jawaban) di body
      notifikasi, karena tampil di layar terkunci.
- [ ] Bersihkan token yang ditolak FCM (`UNREGISTERED`).
- [ ] Cabut token perangkat saat logout.

---

## 10. Versi klien & force update

Lihat [ADR-0013](adr/0013-versioning-api-dan-force-update.md).

- [x] Baca header `X-Client-Version` dan `X-Client-Platform`.
- [x] Middleware membandingkan dengan versi minimum di config; kalau di bawah →
      `426` dengan `code: client_too_old`.
- [x] Endpoint `GET /app-config` berisi versi minimum & terbaru.
- [ ] Flag pemeliharaan — ditunda sampai klien punya layar untuk menampilkannya.

Sudah masuk `development`: middleware `EnsureClientSupported`,
`GET /api/v1/app-config`, config `mobile_app.php`, dan 9 feature test.

Dua keputusan yang perlu diketahui saat review:

- **Gerbang versi gagal ke arah membolehkan.** Header tidak dikirim, versi tidak
  terbaca, atau `min_version` kosong → permintaan diteruskan. Ini mekanisme
  keselamatan untuk aplikasi resmi, bukan kontrol keamanan; klien yang sengaja
  menghilangkan header memang bisa melewatinya.
- **`/app-config` sengaja di luar gerbang itu**, supaya aplikasi yang sudah
  ditolak tetap bisa mengambil tautan tokonya.

---

## 11. Testing

- [ ] Feature test tiap endpoint: berhasil, tidak terautentikasi, tidak terdaftar
      di kelas, item belum publish, item kedaluwarsa.
- [ ] Test khusus: `correct_answer` tidak bocor sebelum rilis hasil.
- [ ] Test idempotency: kunci sama dua kali → satu submission.
- [ ] Test kontrak (snapshot bentuk JSON) supaya perubahan payload yang tidak
      disengaja langsung ketahuan sebelum merusak aplikasi di produksi.

---

## 12. Perbaikan dokumentasi

`lms-app/docs/02-database-schema.md` **stale** dan menyesatkan:

| Ditulis di doc | Kenyataan di migrasi |
|----------------|----------------------|
| `assignments.classroom_subject_id` | `assignments.material_id` |
| `exams.classroom_subject_id` | `exams.material_id` |
| `materials.type` enum, `materials.published_at` | `is_published`, `available_from`, `available_until`, `link_url` |
| exams tanpa `mode` | ada `mode` (`online_quiz`/`submission`), `results_released_at`, `max_score`, `allowed_file_types` |
| assignment_submissions tanpa `link_url`/`is_late`/`graded_at` | ketiganya ada |

- [ ] Perbarui doc backend agar cocok dengan migrasi.

---

## Ringkasan urutan

1. Guard Sanctum + login token *(memblokir semuanya)*
2. `routes/api.php` + controller pembungkus Action
3. Format error + kode middleware
4. Penyesuaian payload (`url` → `material_id`)
5. Unduh file via token
6. Idempotency submit
8. FCM + `device_tokens`
9. Force update
10. Test + perbaikan doc
