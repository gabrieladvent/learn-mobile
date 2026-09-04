# learn_mobile

Aplikasi mobile **khusus siswa** untuk LMS, dibangun dengan Flutter.

Panel guru/admin dan backend ada di repo terpisah: `lms-app`
(Laravel 12 + Filament 3). Repo ini hanya berisi klien mobile.

## Dokumentasi

📖 **[Mulai dari `docs/README.md`](docs/README.md)**

| | |
|---|---|
| Apa yang dibangun & tidak | [docs/01 — Overview](docs/01-overview.md) |
| Model data LMS | [docs/02 — Domain Model](docs/02-domain-model.md) |
| Kontrak `/api/v1` | [docs/03 — API Contract](docs/03-api-contract.md) |
| Struktur kode | [docs/04 — Arsitektur](docs/04-app-architecture.md) |
| Layar & navigasi | [docs/05 — Screen & Flow](docs/05-screens-and-flows.md) |
| Offline & antrian upload | [docs/06 — Offline & Sync](docs/06-offline-and-sync.md) |
| Ujian (paling berisiko) | [docs/07 — Mode Ujian](docs/07-exam-mode.md) |
| Keamanan & privasi | [docs/08 — Keamanan](docs/08-security-and-privacy.md) |
| Fase & estimasi | [docs/09 — Roadmap](docs/09-roadmap.md) |
| Pekerjaan tim backend | [docs/10 — Perubahan Backend](docs/10-backend-changes.md) |

Keputusan arsitektur beserta alasannya: **[docs/adr/](docs/adr/README.md)**

## Status

Repo masih kosong — hasil `flutter create` polos. Pengerjaan diblokir oleh
**Fase 0** ([roadmap](docs/09-roadmap.md)): backend `lms-app` belum punya
`routes/api.php`.

## Mulai bekerja

```bash
flutter pub get
flutter run --flavor dev --dart-define=API_BASE_URL=https://lms.test/api/v1
```

```bash
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

Flavor: `dev`, `staging`, `prod`. Konfigurasi lewat `--dart-define`, bukan file
yang ikut ter-commit. Detail di [docs/04](docs/04-app-architecture.md#flavor--konfigurasi).

## Sebelum menambah fitur

1. Baca [docs/04](docs/04-app-architecture.md) untuk struktur folder & konvensi.
2. Cek [docs/adr/](docs/adr/README.md) — mungkin keputusannya sudah pernah dibahas.
3. Kalau mengubah arah arsitektur, tulis ADR baru; jangan edit yang lama.
4. PR yang menyentuh **timer ujian** atau **outbox** wajib menyertakan test
   ([ADR-0014](docs/adr/0014-strategi-testing.md)).
