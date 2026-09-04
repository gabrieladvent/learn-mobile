# ADR-0013 — Versi API di path + mekanisme force update

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [ADR-0003](0003-api-json-v1-reuse-student-actions.md), [ADR-0015](0015-format-error-api.md)

## Konteks

Berbeda dari web, aplikasi mobile **tidak bisa dipaksa diperbarui secara
instan**. Setelah rilis, akan selalu ada siswa yang menjalankan versi lama —
kadang berbulan-bulan, karena pembaruan otomatis mati atau penyimpanan penuh.

Sementara itu backend akan terus berubah, dan sebagian perubahan tidak bisa
dihindari. Dua kasus yang benar-benar berbahaya:

1. Perubahan kontrak yang merusak (misalnya field yang dihapus) membuat aplikasi
   lama *crash* atau menampilkan data salah.
2. Bug pada alur ujian di versi lama merusak nilai siswa — dan itu tidak bisa
   diperbaiki belakangan.

Kasus kedua yang membuat force update bukan kemewahan.

## Keputusan

**Versi di path: `/api/v1`.** Perubahan yang merusak kontrak berarti `/api/v2`,
dengan `v1` tetap dilayani sampai pemakaiannya turun ke ambang yang disepakati.

**Setiap request membawa versi klien:**
```
X-Client-Version: 1.4.2+37
X-Client-Platform: android
```

**Backend menolak klien yang terlalu lama** dengan `426 Upgrade Required`:
```json
{ "error": { "code": "client_too_old",
             "message": "Versi aplikasi kamu sudah terlalu lama...",
             "min_version": "1.4.0", "store_url": "https://..." } }
```

Klien menampilkan layar force update yang tidak bisa dilewati.

**Endpoint `GET /app-config`** memberi versi minimum, versi terbaru, dan flag
pemeliharaan — dipanggil saat cold start supaya aplikasi bisa menampilkan
pembaruan opsional (dismissable) dan pesan pemeliharaan.

**Kebijakan kapan force update dipakai:**

| Situasi | Tindakan |
|---------|----------|
| Bug yang merusak data/nilai siswa | **force update** |
| Celah keamanan | **force update** |
| Perubahan kontrak yang merusak | naikkan `min_version` setelah `v2` siap |
| Fitur baru, perbaikan UI | pembaruan opsional, tidak memaksa |

Force update adalah tindakan yang mengunci siswa keluar dari materinya sendiri.
Ambangnya harus tinggi, dan aturan di atas adalah ambangnya.

## Alternatif yang dipertimbangkan

### Versi lewat header (`Accept: application/vnd.lms.v1+json`)
Lebih "benar" secara REST. Ditolak: lebih sulit di-debug, tidak bisa dibuka di
browser, dan tidak memberi manfaat nyata pada skala ini.

### Tanpa versi sama sekali
Ditolak. Setiap perubahan payload jadi taruhan bahwa tidak ada aplikasi lama
yang bergantung padanya — taruhan yang pasti kalah suatu saat.

### Selalu kompatibel mundur, tidak pernah force update
Ideal, tapi ditolak sebagai kebijakan absolut. Kalau ada bug yang merusak nilai
ujian siswa di versi lama, membiarkannya jalan demi kemurnian kompatibilitas
adalah pilihan yang salah.

### In-app update (Play Core)
Ditolak untuk MVP sebagai mekanisme utama — hanya ada di Android, dan kita tetap
butuh penolakan sisi server sebagai jaring pengaman. Bisa ditambahkan nanti
sebagai pengalaman yang lebih mulus di atas mekanisme ini.

## Konsekuensi

**Positif**
- Ada jalan keluar dari bug kritis di versi lama.
- Perubahan yang merusak punya jalur yang jelas dan tidak mengejutkan.
- Server tahu sebaran versi klien — berguna untuk memutuskan kapan `v1` bisa
  dipensiunkan.

**Negatif**
- Force update **memblokir siswa dari materinya sendiri**. Kalau dipakai
  sembarangan, ini kerugian nyata bagi siswa yang tidak salah apa-apa. Karena itu
  ada kebijakan ambang di atas.
- Menjaga dua versi API saat transisi berarti kerja ganda di backend.
- Layar force update harus berfungsi meski hampir semua endpoint lain ditolak —
  ia tidak boleh bergantung pada data yang tidak bisa diambil.

**Kewajiban lanjutan**
- Klien menangani `426` di interceptor global ([ADR-0007](0007-http-client-dio.md)),
  bukan per layar.
- Sebelum menaikkan `min_version`, periksa sebaran versi aktif. Menaikkannya
  saat masih banyak siswa di versi lama, tepat menjelang ujian, adalah insiden.

## Kapan keputusan ini perlu ditinjau ulang

Kalau `v2` benar-benar dibutuhkan, kebijakan masa hidup `v1` (berapa lama
dilayani, ambang pemakaian untuk mematikannya) perlu ADR tersendiri.
