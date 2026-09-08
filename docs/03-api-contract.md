# 03 — Kontrak API `/api/v1`

Status: **belum ada di backend.** Dokumen ini adalah spesifikasi yang disepakati,
sekaligus daftar pekerjaan untuk tim backend (lihat [10](10-backend-changes.md)).

Dasar keputusan: [ADR-0003](adr/0003-api-json-v1-reuse-student-actions.md) —
endpoint API membungkus `app/Actions/Student/*` yang sudah ada. Semua Action itu
sudah mengembalikan `array` polos, jadi bentuk payload di bawah **bukan desain
baru**, melainkan cerminan dari apa yang sudah dipakai frontend Inertia hari ini.

## Aturan umum

| Aspek | Ketentuan |
|-------|-----------|
| Base URL | `https://<host>/api/v1` |
| Format | JSON, `Accept: application/json` wajib |
| Auth | `Authorization: Bearer <token>` (Sanctum personal access token, guard `student`) |
| Waktu | Semua timestamp **ISO 8601 dengan offset**, contoh `2026-09-04T13:05:00+07:00` |
| ID | UUID string |
| Bahasa pesan error | Indonesia (sama seperti web) |
| Header wajib klien | `X-Client-Version: <versionName>+<buildNumber>`, `X-Client-Platform: android\|ios` |

Header `X-Client-Version` dipakai untuk force-update — lihat
[ADR-0013](adr/0013-versioning-api-dan-force-update.md).

## Format response

Semua response — sukses maupun gagal — memakai **satu envelope yang sama**.
Lihat [ADR-0016](adr/0016-envelope-response-seragam.md).

**Dengan data:**

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": { }
}
```

**Tanpa data** (aksi yang tidak mengembalikan apa-apa, dan semua error):

```json
{
  "response_code": "success",
  "response_message": "Berhasil"
}
```

Untuk daftar berhalaman, `meta` masuk ke dalam `response_data`:

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "items": [ ],
    "meta": { "current_page": 1, "last_page": 3, "total": 42 }
  }
}
```

**Error:**

```json
{
  "response_code": "validation_failed",
  "response_message": "NISN atau password salah.",
  "response_data": { "fields": { "nisn": ["NISN atau password salah."] } }
}
```

### Aturan envelope

| Field | Isi |
|-------|-----|
| `response_code` | **kode mesin** `snake_case` yang stabil — untuk dibaca program |
| `response_message` | bahasa Indonesia — untuk dibaca siswa |
| `response_data` | payload; **dihilangkan** kalau tidak ada data |

⚠️ `response_code` memuat **kode mesin, bukan HTTP status**. Ini disengaja:
`403` bisa berarti "password masih default" (harus redirect ke ganti password)
atau "kamu tidak berhak" (pesan generik) — dua hal yang perlakuannya berlawanan.
Kalau `response_code` hanya berisi `"403"`, klien tidak bisa membedakannya dan
akan menjebak siswa di layar error tanpa jalan keluar.

HTTP status tetap dikirim dengan benar di header — envelope melengkapi, bukan
menggantikan.

Klien memetakan `response_code` → `AppFailure`, dan **tidak pernah mencocokkan
`response_message`**.

| HTTP | `response_code` | Arti | Aksi klien |
|------|--------|------|------------|
| 400 | `bad_request` | payload rusak | tampilkan pesan, jangan retry |
| 401 | `unauthenticated` | token invalid/dicabut | hapus token, ke layar login |
| 403 | `password_change_required` | password masih default | **paksa ke layar ganti password** |
| 403 | `account_inactive` | siswa dinonaktifkan | logout + pesan hubungi sekolah |
| 403 | `forbidden` | tidak berhak | pesan generik |
| 404 | `not_found` | tidak ada / tidak terdaftar di kelas | pesan generik, jangan bocorkan keberadaan |
| 409 | `conflict` | state bentrok (mis. kiriman dengan kunci sama masih diproses) | refresh state dari server |
| 413 | `payload_too_large` | file/batch kelalu besar | pesan + jangan retry |
| 422 | `validation_failed` | validasi gagal | tampilkan `fields` di form |
| 426 | `client_too_old` | versi app di bawah minimum | layar force update |
| 429 | `too_many_requests` | rate limit | hormati `Retry-After` |
| 500 | `server_error` | | retry dengan backoff |

⚠️ `403 password_change_required` dan `403 account_inactive` **harus dibedakan
dari `forbidden` biasa.** Kalau backend hanya mengirim 403 polos seperti sekarang
(`abort(403, 'Ganti password default...')`), aplikasi tidak bisa membedakan
"harus ganti password" dari "kamu memang tidak berhak" — dan akan menjebak siswa
di layar error tanpa jalan keluar. Ini alasan `code` wajib ada.

---

## Konfigurasi aplikasi

### `GET /app-config`

Sudah ada di `lms-app` (branch `development`). Klien tetap memperlakukan
kegagalan endpoint ini sebagai "tidak ada info" dan berjalan normal — supaya
urutan rilis mobile dan backend tidak saling menyandera, dan supaya versi lama
yang beredar tidak rusak kalau endpoint ini suatu saat berubah.

Satu-satunya endpoint yang **tanpa autentikasi**: dipanggil saat cold start,
sebelum siswa login. Isinya tidak bergantung pada siapa yang memanggil.

Response:
```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "min_version": "1.4.0",
    "latest_version": "1.6.1",
    "store_url": "https://play.google.com/store/apps/details?id=..."
  }
}
```

| Field | Arti bagi klien |
|-------|-----------------|
| `min_version` | Di bawah ini → **layar force update**, sama seperti balasan `426` |
| `latest_version` | Di bawah ini → banner pembaruan opsional yang bisa ditutup |
| `store_url` | Tautan toko sesuai `X-Client-Platform` yang dikirim klien |

Server memilih `store_url` berdasarkan header `X-Client-Platform`, jadi klien
tidak perlu tahu ID aplikasi di masing-masing toko.

Semua field **boleh tidak ada**. Field yang hilang berarti "tidak ada batasan",
bukan error — klien tidak boleh mengunci siswa karena payload tidak lengkap.

Flag pemeliharaan yang disebut [ADR-0013](adr/0013-versioning-api-dan-force-update.md)
**belum** ada di kedua sisi. Pemeliharaan bukan keadaan yang selesai dengan
memperbarui aplikasi, jadi butuh layar dan perilakunya sendiri — dikerjakan saat
layarnya dirancang, bukan sebagai field yang tidak dibaca siapa pun.

---

## Auth

### `POST /auth/login`
Membungkus `AuthenticateStudent`, tapi menerbitkan token, bukan sesi.

Request:
```json
{ "nisn": "0051234567", "password": "20080517", "device_name": "Pixel 7a" }
```

Response `200`:
```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "token": "12|xxxxxxxxxxxxxxxxxxxx",
    "must_change_password": true,
    "student": {
      "id": "uuid", "full_name": "Budi Santoso", "nisn": "0051234567",
      "class": "X IPA 1", "photo_url": null,
      "tracking_opt_out": false, "tracking_disclosure_seen": false
    }
  }
}
```

- `422` kredensial salah — pesan seragam `"NISN atau password salah."`
  (backend sengaja menyamakan waktu respons pakai dummy hash untuk mencegah
  user-enumeration; **jangan bikin pesan yang membedakan** "NISN tidak ada").
- `429` rate limit 5 percobaan/menit per `nisn|ip`. Pesan sudah memuat sisa detik.
- `must_change_password` diturunkan dari `users.password_changed_at === null`.
  Kalau `true`, klien **wajib** langsung ke layar ganti password.

### `POST /auth/logout`
Mencabut token yang sedang dipakai saja (`currentAccessToken()->delete()`).
Response `204`.

### `GET /auth/me`
Profil siswa terkini + flag. Dipakai saat cold start untuk memvalidasi token
sebelum menampilkan data cache.

---

## Beranda

### `GET /dashboard`
Membungkus `GetStudentDashboard`.

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "courses": [{
      "id": "uuid", "subject_name": "Matematika", "subject_code": "MTK",
      "classroom_name": "X IPA 1", "teacher_name": "Ibu Sari",
      "semester": 1, "academic_year": "2025/2026", "is_pinned": true
    }],
    "stats": {
      "assignments_pending": 3, "assignments_completed": 12,
      "exams_completed": 2, "avg_score": 84.5,
      "upcoming_exam": {
        "id": "uuid", "title": "UH Bab 3", "subject_name": "Matematika",
        "starts_at": "2026-09-08T07:00:00+07:00", "duration_minutes": 60
      }
    },
    "meta": {
      "classroom_name": "X IPA 1", "academic_year": "2025/2026",
      "homeroom_teacher_name": "Ibu Sari", "semester": 1,
      "inspire": "..."
    }
  }
}
```

Course sudah **terurut dengan yang di-pin di atas** — klien tidak perlu mengurut ulang.

⚠️ Field `url` yang ada di payload web (hasil `route()` Laravel) **harus dibuang
dari response API.** URL web tidak berarti apa-apa di aplikasi; klien menyusun
rutenya sendiri dari `id`. Membiarkannya masuk bikin klien tergoda memakainya
dan menyeret ketergantungan ke struktur route web.

### `GET /todo`
Membungkus `BuildStudentTodoList`.

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "today": [{
      "kind": "assignment", "state": "pending", "id": "uuid",
      "title": "Latihan Soal Bab 2", "subject_name": "Matematika",
      "deadline": "2026-09-04T23:59:00+07:00",
      "starts_at": null, "available_from": null, "available_until": null,
      "is_today": true, "is_within_week": true,
      "material_id": "uuid"
    }],
    "this_week": [], "later": [], "count_this_week": 1
  }
}
```

`kind`: `assignment` | `exam`. `state`: `pending` | `available` | `upcoming`.
⚠️ `material_id` menggantikan field `url` — klien butuh itu untuk menyusun
rute bersarang ke detail tugas/ujian.

### `POST /courses/{course}/pin` · `DELETE /courses/{course}/pin`
Response `204`. Idempoten — pin dua kali tidak error.

---

## Course & Materi

### `GET /courses/{course}`
Membungkus `GetStudentCourse`.

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "course": {
      "id": "uuid", "subject_name": "Matematika", "subject_code": "MTK",
      "classroom_name": "X IPA 1", "teacher_name": "Ibu Sari",
      "semester": 1, "academic_year": "2025/2026"
    },
    "materials": [{
      "id": "uuid", "title": "Bab 1 — Himpunan", "topic": "Aljabar",
      "description": "...", "order": 1,
      "available_from": "2026-08-01T00:00:00+07:00",
      "created_at": "2026-07-30T10:00:00+07:00",
      "has_files": true, "has_link": false, "has_content": true,
      "assignment_count": 1, "exam_count": 0
    }]
  }
}
```

Materi sudah terurut `order`. Kelompokkan per `topic` di UI.
`404` kalau siswa tidak terdaftar di kelas tersebut.

### `GET /courses/{course}/materials/{material}`
Membungkus `GetStudentMaterial`. Memuat `content`, `link_url`, daftar
`files[]`, serta ringkasan `assignments[]` dan `exams[]` milik materi itu.

Setiap file:
```json
{
  "id": "media-uuid", "name": "Modul Bab 1", "file_name": "modul-bab-1.pdf",
  "mime_type": "application/pdf", "size": 1048576, "extension": "pdf",
  "download_path": "/api/v1/materials/{material}/files/{media}/download"
}
```

⚠️ `download_path`, bukan URL absolut publik. File disimpan di **disk privat**
tanpa URL publik — satu-satunya jalan adalah endpoint berautorisasi. Lihat
[ADR-0010](adr/0010-akses-file-privat.md).

### `GET /materials/{material}/files/{media}/download`
Stream biner + `Content-Disposition: attachment`. Butuh Bearer token.
Backend mencatat unduhan ini sebagai proxy penyelesaian materi tipe file.

---

## Tugas

### `GET /materials/{material}/assignments/{assignment}`
Membungkus `GetStudentAssignment`.

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "course": { "id": "uuid", "subject_name": "...", "subject_code": "...",
                "classroom_name": "...", "teacher_name": "..." },
    "material": { "id": "uuid", "title": "...", "topic": "..." },
    "assignment": {
      "id": "uuid", "title": "...", "description": "...",
      "deadline": "2026-09-10T23:59:00+07:00",
      "max_score": 100.0,
      "allowed_file_types": ["pdf", "docx", "jpg", "png"],
      "max_file_size_mb": 10,
      "accepts_late_submission": true,
      "is_overdue": false, "status": "not_submitted",
      "attachments": [ { "id": "...", "file_name": "...", "download_path": "..." } ]
    },
    "submission": null,
    "activities": [
      { "id": "assignment-published", "title": "Tugas dipublikasikan",
        "description": "Guru memublikasikan tugas ini.",
        "occurred_at": "...", "variant": "system" }
    ]
  }
}
```

`submission` saat sudah ada:
```json
{
  "id": "uuid", "content": "...", "link_url": null,
  "submitted_at": "...", "is_late": false,
  "score": 88.0, "feedback": "Bagus, tapi nomor 3 kurang teliti.",
  "graded_at": "...",
  "files": [ { "id": "...", "file_name": "...", "download_path": "..." } ]
}
```

⚠️ `is_overdue: true` **tidak** berarti tugas tertutup. Selama
`accepts_late_submission` bernilai `true`, pengumpulan tetap diterima dan
ditandai `is_late`. Tombol kirim hanya boleh disembunyikan kalau
`is_overdue && !accepts_late_submission`.

`allowed_file_types` dan `max_file_size_mb` **wajib dipakai klien** untuk
memvalidasi sebelum upload — biar siswa tidak membuang kuota mengunggah file
yang pasti ditolak. Tetapi server tetap sumber kebenarannya; kalau server
menolak, tampilkan pesan servernya.

### `POST /materials/{material}/assignments/{assignment}/submit`
`multipart/form-data`:

| Field | Tipe | Catatan |
|-------|------|---------|
| `content` | string, nullable | jawaban teks |
| `link_url` | string, nullable | jawaban tautan |
| `files[]` | file[], nullable | dibatasi `allowed_file_types` & `max_file_size_mb` |
| `idempotency_key` | uuid | **wajib** — lihat catatan |

⚠️ `idempotency_key` adalah tambahan yang tidak ada di web. Alasannya: antrian
upload offline akan mengirim ulang request yang statusnya tidak diketahui
(request terkirim tapi respons hilang saat sinyal putus). Tanpa kunci ini,
kiriman bisa terduplikasi atau menimpa jawaban yang lebih baru. Backend
menyimpan kunci + hasilnya selama 24 jam dan mengembalikan hasil yang sama
untuk kunci yang sudah pernah dipakai. Detail: [06 — Offline & Sync](06-offline-and-sync.md).

Response `200` berisi objek `submission` yang sama seperti di atas.

---

## Ujian

Dua mode, dua alur. `exam.mode` menentukan mana yang dipakai.

### `GET /materials/{material}/exams/{exam}`
Membungkus `GetStudentExam`. Berisi metadata ujian, `mode`, `starts_at`,
`duration_minutes`, status sesi siswa (belum mulai / sedang berjalan / sudah
submit), dan `results_released` (boolean).

**Jangan pernah** mengharapkan `correct_answer` di sini.

### Mode `online_quiz`

#### `POST /materials/{material}/exams/{exam}/start`
Membungkus `StartExamSession`. **Idempoten**: kalau sesi sudah ada, dikembalikan
apa adanya tanpa me-reset `started_at`.

Response `200` → objek sesi (lihat di bawah).
`422` kalau `starts_at` belum lewat, atau mode-nya bukan `online_quiz`.

#### `GET /exams/sessions/{session}`
Membungkus `GetStudentExamSession`.

```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "session": {
      "id": "uuid", "started_at": "...",
      "expires_at": "2026-09-08T08:00:00+07:00",
      "submitted_at": null, "total_score": null
    },
    "exam": { "id": "uuid", "title": "...", "duration_minutes": 60 },
    "questions": [{
      "id": "uuid", "type": "multiple_choice", "question": "...",
      "options": ["A ...", "B ...", "C ...", "D ..."],
      "score": 10.0, "order": 1,
      "files": [ { "id": "...", "download_path": "..." } ]
    }],
    "answers": { "question-uuid": "A" },
    "results_released": false,
    "server_time": "2026-09-08T07:12:33+07:00"
  }
}
```

⚠️ **`expires_at` dan `server_time` adalah pasangan yang wajib dipakai bersama.**
Klien menghitung sisa waktu sebagai `expires_at - server_time`, lalu menjalankan
hitung mundur dari jam monotonik lokal — **bukan** dari jam dinding HP, yang bisa
diubah siswa. Lihat [ADR-0009](adr/0009-timer-ujian-otoritatif-server.md).

#### `POST /exams/sessions/{session}/answer`
Auto-save satu jawaban. Rate limit lebih longgar (120/menit).

```json
{ "exam_question_id": "uuid", "answer": "A" }
```
Response `204`. Aman dipanggil berulang untuk soal yang sama.

#### `POST /exams/sessions/{session}/submit`
Mengunci sesi. Tanpa body.

⚠️ **Idempoten, dan sengaja membalas `200` walau sesi sudah tersubmit** — bukan
`409`. Klien mengulang kiriman saat responsnya hilang di jaringan buruk; kalau
pengulangan itu dibalas error, siswa melihat layar merah untuk ujian yang
sebenarnya sudah aman terkumpul, dan klien harus punya logika khusus yang
memperlakukan sebuah error sebagai sukses.

`submitted_at` yang dikembalikan selalu waktu submit **pertama** — tidak bergeser
walau dikirim ulang berkali-kali.

```json
{
  "response_code": "success",
  "response_message": "Ujian berhasil dikumpulkan.",
  "response_data": {
    "session_id": "uuid",
    "submitted_at": "2026-09-08T07:58:12+07:00"
  }
}
```

#### `GET /exams/sessions/{session}/result`
`403` (atau `data.results_released = false`) selama `results_released_at` belum lewat.

### Mode `submission`

#### `POST /materials/{material}/exams/{exam}/submit-submission`
Sama persis polanya dengan submit tugas, termasuk `idempotency_key`.

---

## Progress belajar

### `POST /progress/heartbeat`
Membungkus `RecordLearningProgress`. Batch event.

```json
{
  "session_id": "uuid-v4-dibuat-klien",
  "trackable_type": "material",
  "trackable_id": "uuid",
  "events": [
    { "type": "open", "at": "2026-09-04T13:00:00+07:00" },
    { "type": "heartbeat", "at": "2026-09-04T13:00:30+07:00" }
  ]
}
```

Batasan server (dari `config/learning_progress.php`): maks **50 event** per
request, payload maks **32 KB**, toleransi selisih jam maks **10 menit**.
Response `204`. Kalau siswa `tracking_opt_out`, server diam-diam membuang data
dan tetap membalas `204`.

⚠️ Toleransi 10 menit itu jebakan untuk klien offline: event yang mengantre
lebih lama dari itu akan **ditolak**. Jangan simpan heartbeat lama untuk dikirim
belakangan — buang saja. Alasan lengkap di [ADR-0012](adr/0012-learning-progress-tracking-mobile.md).

### `POST /progress/disclosure-seen`
Menandai siswa sudah melihat pemberitahuan pelacakan. `204`.

---

## Profil & Notifikasi

### `PATCH /profile/password`
```json
{ "current_password": "...", "password": "...", "password_confirmation": "..." }
```
Sukses juga mengisi `password_changed_at` → flag `must_change_password` jadi `false`.

⚠️ Setelah ganti password, **cabut semua token lain** milik siswa itu dan
terbitkan token baru untuk perangkat ini. Kalau tidak, perangkat lain yang
sempat login dengan password lama tetap punya akses.

### `POST /profile/photo` · `GET /profile/progress`
Upload foto (multipart) dan laporan progress belajar (`GetStudentProgress`).

### `GET /notifications`
Sudah berbentuk JSON di web dan bisa dipakai apa adanya:
```json
{
  "response_code": "success",
  "response_message": "Berhasil",
  "response_data": {
    "items": [ { "id": "...", "data": {...}, "read_at": null, "created_at": "..." } ],
    "meta": { "current_page": 1, "last_page": 2, "total": 23 }
  }
}
```
15 item per halaman.

### `POST /notifications/{id}/read` · `POST /notifications/read-all`

### `POST /devices` · `DELETE /devices/{token}`
Registrasi & pencabutan token FCM. Baru; belum ada padanannya di web.
Lihat [ADR-0011](adr/0011-push-notification-fcm.md).

```json
{ "token": "fcm-token", "platform": "android", "app_version": "1.0.0+1" }
```

---

## Ringkasan endpoint

| Method | Path | Action backend |
|--------|------|----------------|
| POST | `/auth/login` | `AuthenticateStudent` (+ token) |
| POST | `/auth/logout` | cabut token |
| GET | `/auth/me` | — |
| GET | `/dashboard` | `GetStudentDashboard` |
| GET | `/todo` | `BuildStudentTodoList` |
| POST/DELETE | `/courses/{course}/pin` | pin/unpin |
| GET | `/courses/{course}` | `GetStudentCourse` |
| GET | `/courses/{course}/materials/{material}` | `GetStudentMaterial` |
| GET | `/materials/{material}/files/{media}/download` | stream privat |
| GET | `/materials/{material}/assignments/{assignment}` | `GetStudentAssignment` |
| POST | `/materials/{material}/assignments/{assignment}/submit` | `SubmitStudentAssignment` |
| GET | `/materials/{material}/exams/{exam}` | `GetStudentExam` |
| POST | `/materials/{material}/exams/{exam}/start` | `StartExamSession` |
| POST | `/materials/{material}/exams/{exam}/submit-submission` | `SubmitExamSubmission` |
| GET | `/exams/sessions/{session}` | `GetStudentExamSession` |
| POST | `/exams/sessions/{session}/answer` | `SaveExamAnswer` |
| POST | `/exams/sessions/{session}/submit` | `SubmitExamSession` |
| GET | `/exams/sessions/{session}/result` | `GetStudentExamSession` |
| POST | `/progress/heartbeat` | `RecordLearningProgress` |
| POST | `/progress/disclosure-seen` | — |
| PATCH | `/profile/password` | — |
| POST | `/profile/photo` | — |
| GET | `/profile/progress` | `GetStudentProgress` |
| GET | `/notifications` | — |
| POST | `/notifications/{id}/read`, `/read-all` | — |
| POST/DELETE | `/devices` | **baru** |
