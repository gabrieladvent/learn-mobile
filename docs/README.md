# learn_mobile — Dokumentasi

Aplikasi mobile **khusus siswa** untuk LMS. Backend & panel guru ada di repo terpisah
(`lms-app` — Laravel 12 + Filament 3). Repo ini hanya berisi klien Flutter.

## Cara baca dokumen ini

Urutannya sengaja: dari "apa yang dibangun" → "kontrak dengan backend" → "gimana
kodenya disusun" → "risiko & fase".

| # | Dokumen | Isi | Baca kalau kamu… |
|---|---------|-----|------------------|
| 01 | [Overview](01-overview.md) | Tujuan produk, persona, scope & non-goals | baru gabung ke project |
| 02 | [Domain Model](02-domain-model.md) | Entitas, hierarki, enum, aturan visibility | mau paham data LMS-nya |
| 03 | [Kontrak API](03-api-contract.md) | Endpoint `/api/v1`, request/response, error | ngoding fitur apa pun |
| 04 | [Arsitektur Aplikasi](04-app-architecture.md) | Layer, struktur folder, konvensi | mau nambah fitur baru |
| 05 | [Screen & Flow](05-screens-and-flows.md) | Daftar layar, navigasi, state kosong/error | ngerjain UI |
| 06 | [Offline & Sync](06-offline-and-sync.md) | Caching, outbox upload, konflik | ngerjain data layer |
| 07 | [Mode Ujian](07-exam-mode.md) | Spesifikasi ujian di HP — bagian paling berisiko | ngerjain fitur ujian |
| 08 | [Keamanan & Privasi](08-security-and-privacy.md) | Token, storage, tracking, data minor | review keamanan |
| 09 | [Roadmap](09-roadmap.md) | Fase rilis + checklist per fase | planning / estimasi |
| 10 | [Perubahan Backend](10-backend-changes.md) | Yang harus ditambah di `lms-app` | tim backend |

## Architecture Decision Records

Keputusan arsitektur dicatat di [`docs/adr/`](adr/README.md). Kalau kamu mau
mengubah salah satu keputusan, jangan edit ADR lama — buat ADR baru yang
men-*supersede* yang lama. Alasannya ada di [ADR-0001](adr/0001-gunakan-adr.md).

## Status project

Per **4 September 2026**: repo Flutter masih hasil `flutter create` polos
(`lib/main.dart` + `test/widget_test.dart`, tanpa dependency tambahan).
Backend `lms-app` **belum punya `routes/api.php`** — student frontend yang ada
sekarang berbasis Inertia + session. Fase 0 di [roadmap](09-roadmap.md) menutup
gap itu.

## Konvensi penulisan

- Bahasa dokumen: **Indonesia**, konsisten dengan docs di `lms-app`.
- Istilah domain dibiarkan Inggris (`classroom`, `material`, `assignment`,
  `exam`, `submission`) supaya nyambung dengan nama tabel & kelas di backend.
- Setiap klaim tentang backend di dokumen ini diverifikasi langsung dari kode
  `lms-app` per 4 September 2026. Kalau backend berubah, dokumen ini ikut basi —
  perlakukan kode sebagai sumber kebenaran, lalu perbarui dokumen.
