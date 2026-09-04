# Architecture Decision Records

Catatan keputusan arsitektur untuk `learn_mobile`. Alasan formatnya ada di
[ADR-0001](0001-gunakan-adr.md).

## Cara pakai

- Keputusan baru → salin [`0000-template.md`](0000-template.md), nomor berikutnya.
- **Jangan edit ADR yang sudah `Accepted`** kecuali untuk memperbaiki typo atau
  menambah tautan. Kalau keputusannya berubah, tulis ADR baru yang
  men-*supersede* yang lama, dan ubah status yang lama jadi `Superseded by ADR-XXXX`.
- ADR mencatat **kenapa**, bukan **bagaimana**. Detail implementasi tempatnya di
  [`docs/`](../README.md).

## Status

`Proposed` → diusulkan, belum diketok · `Accepted` → berlaku ·
`Superseded` → digantikan · `Deprecated` → tidak berlaku, tanpa pengganti

## Daftar

| # | Judul | Status |
|---|-------|--------|
| [0001](0001-gunakan-adr.md) | Gunakan ADR untuk mencatat keputusan arsitektur | Accepted |
| [0002](0002-flutter-native-bukan-webview.md) | Flutter native, bukan WebView atau PWA | Accepted |
| [0003](0003-api-json-v1-reuse-student-actions.md) | API JSON `/api/v1` yang membungkus Student Actions | Accepted |
| [0004](0004-auth-sanctum-token-guard-student.md) | Autentikasi Sanctum token dengan guard `student` | Accepted |
| [0005](0005-state-management-riverpod.md) | Riverpod sebagai state management | Accepted |
| [0006](0006-navigasi-go-router.md) | go_router untuk navigasi deklaratif | Accepted |
| [0007](0007-http-client-dio.md) | Dio sebagai HTTP client | Accepted |
| [0008](0008-offline-cache-dan-outbox.md) | Cache baca + outbox tulis, bukan offline-first penuh | Accepted |
| [0009](0009-timer-ujian-otoritatif-server.md) | Timer ujian otoritatif di server | Accepted |
| [0010](0010-akses-file-privat.md) | File lewat endpoint berautorisasi, bukan URL publik | Accepted |
| [0011](0011-push-notification-fcm.md) | FCM untuk push notification | Accepted |
| [0012](0012-learning-progress-tracking-mobile.md) | Pelacakan progress belajar terbatas & transparan | Accepted |
| [0013](0013-versioning-api-dan-force-update.md) | Versi API di path + mekanisme force update | Accepted |
| [0014](0014-strategi-testing.md) | Strategi testing berbasis risiko | Accepted |
| [0015](0015-format-error-api.md) | Format error API dengan kode mesin | ~~Superseded by 0016~~ |
| [0016](0016-envelope-response-seragam.md) | Envelope response seragam `response_code`/`response_message`/`response_data` | Accepted |

Seluruh ADR berstatus `Accepted`, kecuali ADR-0015 yang digantikan ADR-0016.
