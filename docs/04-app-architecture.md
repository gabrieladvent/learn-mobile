# 04 — Arsitektur Aplikasi

Keputusan yang mendasari dokumen ini:
[ADR-0005 (state management)](adr/0005-state-management-riverpod.md),
[ADR-0006 (navigasi)](adr/0006-navigasi-go-router.md),
[ADR-0007 (HTTP client)](adr/0007-http-client-dio.md).

## Prinsip

1. **Server adalah sumber kebenaran.** Klien tidak menegakkan aturan otorisasi
   atau visibility. Aturan bisnis yang diduplikasi di klien akan menyimpang dari
   server pada perubahan pertama.
2. **Feature-first, bukan layer-first.** Folder disusun per fitur, bukan per tipe
   file. Menambah fitur = menambah satu folder, bukan menyentuh lima folder.
3. **UI tidak pernah memanggil HTTP langsung.** Widget → provider → repository →
   data source. Batas ini yang membuat cache & offline bisa dipasang di satu
   tempat.
4. **Model API diketik.** Tidak ada `Map<String, dynamic>` yang lolos melewati
   lapisan repository.
5. **Satu jalur penanganan error.** Semua kegagalan jaringan diterjemahkan jadi
   `AppFailure` yang sama di interceptor, bukan ditangkap ad-hoc di tiap layar.

## Lapisan

```
┌─────────────────────────────────────────────┐
│ presentation   screen, widget, controller   │  Flutter + Riverpod
├─────────────────────────────────────────────┤
│ application    provider, use-case, state    │  orkestrasi, tanpa I/O langsung
├─────────────────────────────────────────────┤
│ domain         entity, value object, failure│  Dart murni, tanpa dependency
├─────────────────────────────────────────────┤
│ data           repository, remote, local    │  Dio, Drift/Isar, secure storage
└─────────────────────────────────────────────┘
```

Aturan ketergantungan: **hanya menunjuk ke bawah.** `domain` tidak boleh
meng-import apa pun dari `data` atau Flutter.

Repository adalah tempat kebijakan offline diputuskan — ia yang memilih antara
cache dan jaringan, dan yang menaruh kiriman ke outbox saat gagal. Provider di
atasnya tidak tahu-menahu soal itu.

## Struktur folder

```
lib/
├── main.dart
├── app/
│   ├── app.dart                 # MaterialApp.router + tema
│   ├── router.dart              # go_router + redirect guard
│   └── bootstrap.dart           # init DI, storage, error handler, FCM
├── core/
│   ├── config/                  # flavor, base URL, konstanta
│   ├── error/                   # AppFailure, mapper exception
│   ├── network/                 # Dio, interceptor auth/error/logging
│   ├── storage/                 # secure storage, database lokal
│   ├── sync/                    # outbox, konektivitas, scheduler
│   └── ui/                      # tema, komponen dipakai lintas fitur
├── features/
│   ├── auth/          { data/ domain/ application/ presentation/ }
│   ├── dashboard/
│   ├── course/
│   ├── material/
│   ├── assignment/
│   ├── exam/
│   ├── notification/
│   └── profile/
└── shared/                      # model & widget lintas fitur
```

Isi tiap fitur, contoh `assignment/`:

```
assignment/
├── data/
│   ├── assignment_api.dart          # panggilan HTTP mentah
│   ├── assignment_dao.dart          # baca/tulis cache lokal
│   └── assignment_repository.dart   # kebijakan cache + outbox
├── domain/
│   ├── assignment.dart              # entity (freezed)
│   └── submission.dart
├── application/
│   └── assignment_providers.dart    # Riverpod provider + controller
└── presentation/
    ├── assignment_detail_screen.dart
    └── widgets/
```

## Paket yang dipakai

| Kebutuhan | Paket | Alasan singkat |
|-----------|-------|----------------|
| State management | `flutter_riverpod` **3.x** + `riverpod_generator` | [ADR-0005](adr/0005-state-management-riverpod.md) |
| Navigasi | `go_router` | [ADR-0006](adr/0006-navigasi-go-router.md) |
| HTTP | `dio` | interceptor & upload progress — [ADR-0007](adr/0007-http-client-dio.md) |
| Model & union | `freezed` + `json_serializable` | immutability, `when` untuk state |
| DB lokal | `drift` | query terketik, migrasi jelas — [ADR-0008](adr/0008-offline-cache-dan-outbox.md) |
| Token storage | `flutter_secure_storage` | Keystore/Keychain — [ADR-0004](adr/0004-auth-sanctum-token-guard-student.md) |
| Konektivitas | `connectivity_plus` | pemicu flush outbox |
| Push | `firebase_messaging` | [ADR-0011](adr/0011-push-notification-fcm.md) |
| File | `file_picker`, `open_filex`, `path_provider` | pilih & buka lampiran |
| Crash & log | `sentry_flutter` | wajib untuk debug ujian di lapangan |
| Test | `mocktail`, `patrol` (E2E) | [ADR-0014](adr/0014-strategi-testing.md) |

⚠️ **Riverpod yang terpasang adalah 3.x, bukan 2.x.** Beberapa API berbeda dari
mayoritas tutorial yang beredar:

| Riverpod 2 (banyak tutorial) | Riverpod 3 (yang kita pakai) |
|------------------------------|------------------------------|
| `asyncValue.valueOrNull` | `asyncValue.value` |
| `FooRef` (tiap provider punya tipe Ref sendiri) | `Ref` saja |
| `ProviderObserver.didUpdateProvider(provider, prev, next, container)` | `didUpdateProvider(ProviderObserverContext, prev, next)` |

⚠️ `riverpod_lint` + `custom_lint` **belum dipasang** — versinya belum mendukung
Riverpod 3.4.3 dan membuat resolusi dependency gagal. Coba lagi nanti; sampai
saat itu, konvensi di bawah ditegakkan lewat review, bukan lewat linter.

**File hasil code generation (`*.g.dart`, `*.freezed.dart`) tidak di-commit**
supaya diff PR hanya berisi kode yang ditulis manusia. Setelah clone, atau
setiap kali mengubah model/provider:

```bash
dart run build_runner build          # sekali jalan
dart run build_runner watch          # otomatis saat file berubah
```

`pubspec.yaml` saat ini masih kosong dari semua ini — menambahkannya adalah
langkah pertama Fase 1.

## Konvensi

**Penamaan.** File `snake_case.dart`. Kelas `PascalCase`. Provider berakhiran
peran: `dashboardControllerProvider`, `assignmentRepositoryProvider`.

**Model.** Semua respons API punya kelas `freezed` dengan `fromJson`. Nama field
mengikuti API (`snake_case` di JSON → `camelCase` di Dart lewat
`@JsonKey(name:)` atau `field_rename`). Jangan mengganti nama konsep di
perjalanan — `classroom_subject` tetap `ClassroomSubject`, bukan `Subject`,
supaya bisa dilacak balik ke backend.

**State layar.** Pakai `AsyncValue` bawaan Riverpod, bukan enum status buatan
sendiri. Layar merender tiga cabang: `data`, `loading`, `error` — dan untuk data
dari cache, tambahan penanda "data mungkin basi" (lihat [06](06-offline-and-sync.md)).

**Error.** Interceptor Dio menerjemahkan `DioException` → `AppFailure` bertipe:

```dart
sealed class AppFailure {
  const factory AppFailure.network() = NetworkFailure;          // offline / timeout
  const factory AppFailure.unauthenticated() = Unauthenticated; // 401
  const factory AppFailure.passwordChangeRequired() = PasswordChangeRequired;
  const factory AppFailure.accountInactive() = AccountInactive;
  const factory AppFailure.forbidden(String message) = Forbidden;
  const factory AppFailure.notFound(String message) = NotFound;
  const factory AppFailure.conflict(String message) = Conflict;
  const factory AppFailure.validation(Map<String, List<String>> fields, String message) = ValidationFailure;
  const factory AppFailure.clientTooOld() = ClientTooOld;
  const factory AppFailure.rateLimited(Duration retryAfter) = RateLimited;
  const factory AppFailure.server(String message) = ServerFailure;
}
```

Tiga di antaranya ditangani global, bukan per layar:
`unauthenticated` → logout, `passwordChangeRequired` → redirect,
`clientTooOld` → layar force update.

**Waktu.** Semua `DateTime` dari API di-parse sebagai UTC lalu ditampilkan di
zona lokal. Untuk timer ujian, **jangan pakai `DateTime.now()`** — pakai
`Stopwatch`/`Ticker` monotonik dengan titik acuan dari server. Alasannya di
[ADR-0009](adr/0009-timer-ujian-otoritatif-server.md).

**Logging.** Tidak boleh ada `print`. Pakai logger terpusat yang **menyaring
token, password, dan NISN** sebelum dikirim ke Sentry.

## Flavor & konfigurasi

Tiga flavor: `dev`, `staging`, `prod`. Base URL dan DSN Sentry lewat
`--dart-define`, bukan file yang ikut ter-commit.

```
flutter run --flavor dev --dart-define=API_BASE_URL=https://lms.test/api/v1
```

Build `prod` wajib: `--obfuscate --split-debug-info`.

## Yang sengaja tidak dipakai

| Ditolak | Alasan |
|---------|--------|
| `GetX` | menggabungkan DI, routing, dan state jadi satu; sulit dites dan dilacak |
| `shared_preferences` untuk token | tidak terenkripsi |
| `http` polos | tidak ada interceptor; retry & refresh jadi tersebar |
| Clean Architecture penuh (usecase per aksi) | boilerplate tidak sebanding untuk tim kecil; lapisan repository sudah cukup |
| Generator kode dari OpenAPI | backend belum punya spesifikasi OpenAPI; bisa ditinjau ulang setelah Fase 0 |
