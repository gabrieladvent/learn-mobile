# 02 — Domain Model

Diverifikasi dari migrasi & model `lms-app` per 4 September 2026.

> **Peringatan:** `lms-app/docs/02-database-schema.md` sudah **stale** di beberapa
> tempat. Dokumen ini mengikuti migrasi yang benar-benar ada, bukan doc lama.
> Perbedaan yang penting ditandai dengan ⚠️.

## Hierarki inti

```
School
 └── Classroom            (rombel per tahun ajaran, punya wali kelas)
      ├── classroom_students  (pivot: siswa terdaftar di kelas)
      └── ClassroomSubject    ← di aplikasi ini disebut "Course" / Mata Pelajaran
           └── Material       (unit materi, punya urutan & topik)
                ├── Assignment  ⚠️ FK ke material_id
                └── Exam        ⚠️ FK ke material_id
```

⚠️ Titik yang paling sering salah: **`assignments` dan `exams` menempel ke
`materials`, bukan langsung ke `classroom_subjects`.** Doc lama di `lms-app`
menulis `classroom_subject_id` — itu keliru. Semua route siswa karenanya
bersarang: `materials/{material}/assignments/{assignment}`.

Konsekuensi untuk mobile: **tidak ada layar "semua tugas" yang berdiri sendiri di
level course.** Tugas selalu ditemukan lewat materi induknya, atau lewat to-do
list yang sudah meratakan (flatten) hierarki di backend.

## Entitas

### Student
Profil siswa, one-to-one dengan `users`.

| Kolom | Catatan untuk mobile |
|-------|----------------------|
| `id` (uuid) | PK semua tabel pakai UUID |
| `user_id` | akun auth-nya; `users.email` nullable untuk siswa |
| `nisn` | **kredensial login**, unik |
| `full_name`, `class`, `gender` | tampilan profil |
| `is_active` | kalau `false`, login ditolak dan sesi aktif diputus |
| `tracking_opt_out` | siswa menolak dilacak → heartbeat di-*drop* server |

Di `users`: `password_changed_at` **null berarti password masih default** →
aplikasi wajib mengarahkan ke layar ganti password.

### ClassroomSubject (Course)
Penugasan "guru X mengajar mapel Y di kelas Z". Inilah yang muncul sebagai kartu
mata pelajaran di beranda.

Field: `classroom_id`, `subject_id`, `teacher_id`, `academic_year`, `semester` (1|2).

Siswa bisa mem-*pin* course lewat tabel `student_pinned_courses`
(PK gabungan `student_id` + `classroom_subject_id`, plus `pinned_at`).
Course yang di-pin naik ke atas daftar.

### Material

| Kolom | Catatan |
|-------|---------|
| `title`, `description`, `topic`, `order` | `topic` dipakai untuk grouping di UI |
| `content` (longText) | isi materi teks |
| `link_url` | materi berupa tautan |
| `is_published`, `available_from`, `available_until` | ⚠️ aturan visibility, lihat bawah |

⚠️ Doc lama menyebut kolom `type` enum (`text`/`file`/`link`) dan `published_at`.
**Keduanya tidak ada.** Yang ada: `is_published` + jendela ketersediaan, dan
tipe materi disimpulkan dari isi. Backend sudah menyediakan flag turunan di
payload course: `has_content`, `has_files`, `has_link`. Aplikasi memakai flag itu,
**jangan menyimpulkan sendiri** — satu materi bisa punya ketiganya sekaligus.

File lampiran ditangani Spatie Media Library, collection `material_files`.

### Assignment

| Kolom | Catatan |
|-------|---------|
| `material_id` | ⚠️ induknya materi |
| `deadline` (datetime) | wajib |
| `max_score` | default 100 |
| `allowed_file_types` (json), `max_file_size_mb` (default 10) | **validasi ini harus dicerminkan di klien** supaya siswa tidak menunggu upload gagal |
| `accepts_late_submission` | sakelar per tugas: boleh dikumpulkan lewat deadline atau tidak |
| `is_published`, `available_from`, `available_until` | visibility sama seperti material |

Lampiran guru: collection `assignment_attachments`.

### Deadline lewat: dua perilaku berbeda

`accepts_late_submission` menentukan apa yang terjadi setelah `deadline`:

| Nilai | Perilaku server |
|-------|-----------------|
| `true` | pengumpulan **diterima**, lalu `is_late` diisi `true` |
| `false` | pengumpulan **ditolak** `422` |

Default untuk tugas baru adalah `true`. Tugas yang sudah ada sebelum fitur ini
di-backfill `false`, jadi jangan berasumsi semuanya seragam — **selalu baca
nilainya dari API.**

⚠️ Konsekuensi untuk UI: status `overdue` di kartu tugas **tidak berarti tugas
tertutup**. Kalau `accepts_late_submission` bernilai `true`, siswa masih bisa
mengumpulkan. Menyembunyikan tombol kirim hanya karena `is_overdue` akan
menghalangi siswa mengumpulkan tugas yang sebenarnya masih dibuka.

⚠️ `is_late` mengikuti `submitted_at`, dan keduanya ditimpa setiap kali siswa
menyunting. Jadi pengumpulan tepat waktu yang disunting setelah deadline akan
berubah menjadi terlambat. Ini konsisten — waktu yang tercatat memang waktu
penyuntingan terakhir — tapi perlu dijelaskan ke siswa sebelum ia menekan
"perbarui jawaban" setelah deadline.

**Ujian tidak punya konsep ini.** `exam_submissions` tidak memiliki `is_late`;
ujian memakai jendela `available_until` yang tegas — lewat itu, pengumpulan
ditutup, bukan ditandai terlambat.

### AssignmentSubmission

| Kolom | Catatan |
|-------|---------|
| unik `(assignment_id, student_id)` | satu siswa satu submission — **submit ulang = update, bukan insert baru** |
| `content` | jawaban teks |
| `link_url` (2048) | jawaban berupa tautan |
| `submitted_at` | null = draft belum terkirim |
| `score`, `feedback`, `graded_at` | terisi setelah guru menilai |
| `is_late` | dihitung server saat submit: `submitted_at > deadline` |

Lampiran siswa: collection `submission_files`.

Karena `is_late` dan `graded_at` ditentukan server, **klien tidak boleh menghitung
status terlambat sendiri untuk ditampilkan sebagai fakta** — pakai nilai dari API.
Perkiraan lokal hanya boleh untuk peringatan sebelum submit ("deadline lewat 2 jam
lalu, pengumpulan akan ditandai terlambat").

### Exam

| Kolom | Catatan |
|-------|---------|
| `material_id` | ⚠️ induknya materi |
| `mode` | `online_quiz` \| `submission` — **dua alur UI yang sama sekali berbeda** |
| `starts_at` | ujian tidak bisa dimulai sebelum ini |
| `duration_minutes` | dasar perhitungan timer |
| `shuffle_questions` | urutan soal diacak per sesi |
| `max_score`, `allowed_file_types`, `max_file_size_mb` | |
| `status` | `draft` \| `published` \| `closed` |
| `is_published`, `available_from`, `available_until` | visibility |
| `results_released_at` | ⚠️ **hasil & kunci jawaban hanya boleh tampil kalau ini terisi dan sudah lewat** |

### ExamQuestion
`type` (`multiple_choice` \| `short_answer` \| `essay`), `question`, `options` (json),
`correct_answer`, `score`, `order`. Lampiran soal: collection `question_files`.

⚠️ **`correct_answer` tidak boleh pernah dikirim ke aplikasi siswa sebelum
`results_released_at` lewat.** Ini bukan sekadar aturan UI — kalau ada di payload,
siswa bisa membacanya lewat proxy. Lihat [08 — Keamanan](08-security-and-privacy.md).

### ExamSession
Sesi pengerjaan, unik per `(exam_id, student_id)`.
`started_at`, `submitted_at`, `total_score`, `submission_reason`
(`manual` | otomatis saat waktu habis).

Batas waktu **dihitung server** sebagai `started_at + duration_minutes`; backend
sudah mengirim `expires_at` dan `server_time` di payload sesi. Lihat
[ADR-0009](adr/0009-timer-ujian-otoritatif-server.md).

### ExamAnswer
`exam_session_id`, `exam_question_id`, `answer`, `score`, `feedback`.
Auto-save menulis ke sini; endpoint-nya punya rate limit lebih longgar (120/menit).

### ExamSubmission
Untuk `mode = submission`. Unik per `(exam_id, student_id)`, isinya `content`,
`link_url`, `submitted_at`, `score`, `feedback` — polanya sama persis dengan
AssignmentSubmission.

### Learning Progress
Tiga tabel: `learning_progress_events` (mentah), `learning_progress_sessions`
(agregat per sesi), `learning_progress_daily_rollups` (harian).

Tipe event: `open`, `focus`, `blur`, `heartbeat`, `idle`, `close`.
Trackable: `material`, `assignment`, `exam`.

Ini punya implikasi privasi dan baterai yang serius di mobile — dibahas di
[ADR-0012](adr/0012-learning-progress-tracking-mobile.md).

### Notification
Tabel `notifications` standar Laravel. Jenis yang sudah ada di backend:
`StudentAssignmentPublished`, `StudentAssignmentGraded`, `StudentExamPublished`,
`StudentDeadlineReminder`.

Keempatnya saat ini hanya kanal `database`. Menambah kanal FCM adalah pekerjaan
backend — lihat [10 — Perubahan Backend](10-backend-changes.md).

## Aturan visibility (berlaku untuk material, assignment, exam)

Sebuah item terlihat oleh siswa **hanya jika ketiganya benar**:

1. `is_published = true`
2. `available_from` null **atau** sudah lewat
3. `available_until` null **atau** belum lewat

Ditambah: siswa harus terdaftar di `classroom` yang memiliki `classroom_subject`
tersebut.

**Aturan ini ditegakkan di server dan tidak boleh diduplikasi sebagai logika
otorisasi di klien.** Aplikasi hanya menampilkan apa yang dikirim API. Kalau
klien ikut memfilter, kita punya dua sumber kebenaran yang pasti berbeda saat
salah satunya berubah.

Ada satu implikasi yang mudah terlewat: **item bisa hilang di tengah sesi**
(guru mencabut publikasi, atau `available_until` lewat saat aplikasi terbuka).
Cache lokal karenanya bisa memuat item yang sudah tidak boleh diakses — lihat
penanganannya di [06 — Offline & Sync](06-offline-and-sync.md).

## Aturan bisnis yang wajib dihormati klien

| Aturan | Ditegakkan di | Kewajiban klien |
|--------|---------------|-----------------|
| Password default harus diganti | middleware backend | arahkan ke layar ganti password; jangan cache 403-nya sebagai error umum |
| Siswa nonaktif tidak boleh akses | middleware backend | tangani 403 → logout paksa + pesan jelas |
| Satu submission per siswa per tugas | unique constraint DB | UI "kirim ulang" = update |
| Sesi ujian idempoten | unique + `lockForUpdate` | tombol "mulai" boleh ditekan berkali-kali, hasilnya sesi yang sama |
| Hasil ujian hanya setelah dirilis | payload backend | jangan tampilkan skor kalau field-nya null |
| Rate limit login 5/menit per NISN+IP | backend | tampilkan sisa detik dari pesan error, jangan retry otomatis |
