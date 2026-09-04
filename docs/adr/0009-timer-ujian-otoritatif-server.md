# ADR-0009 — Timer ujian otoritatif di server

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/07](../07-exam-mode.md), [ADR-0008](0008-offline-cache-dan-outbox.md)

## Konteks

Ujian `online_quiz` punya `duration_minutes` dan sesi per siswa dengan
`started_at`. Batas waktu = `started_at + duration_minutes`.

Siswa punya motivasi kuat dan sarana mudah untuk memanipulasi waktu: mengubah
jam HP, mematikan aplikasi lalu membukanya lagi, atau memutus jaringan berharap
timer berhenti. Ini bukan ancaman teoretis — ini hal pertama yang dicoba anak
yang paham HP.

Di sisi lain, jaringan sekolah memang buruk. Kalau aplikasi bersikap keras
(memutus ujian saat offline), siswa jujur akan dirugikan oleh masalah yang bukan
salahnya. Dua tekanan ini harus diseimbangkan.

Backend sudah menyediakan bahan yang tepat: `GetStudentExamSession` mengirim
`expires_at` **dan** `server_time` di setiap respons.

## Keputusan

Waktu ujian **sepenuhnya ditentukan server**. Klien hanya menampilkan, dan
menghitung sisa waktu dari pasangan `expires_at` + `server_time`:

```dart
final remainingAtLoad = expiresAt.difference(serverTime);
final ticker = Stopwatch()..start();       // monotonik
Duration get remaining => remainingAtLoad - ticker.elapsed;
```

Tiga aturan turunannya:

1. **Jangan pakai `DateTime.now()` untuk hitung mundur.** Jam dinding HP bisa
   diubah siswa; `Stopwatch` monotonik tidak.
2. **Sinkronisasi ulang** saat aplikasi kembali foreground, tiap ~60 detik
   (nebeng respons auto-save), dan sebelum konfirmasi submit. `Stopwatch` berhenti
   saat proses di-suspend OS, jadi tanpa ini aplikasi di background akan
   menghitung sisa waktu lebih banyak dari kenyataan. Selisih > 5 detik dikoreksi
   ke nilai server dengan animasi halus, bukan lompatan mendadak.
3. **Server menutup sesi yang lewat waktu sendiri**, lewat scheduled job. Klien
   mengirim submit `reason: "timeout"` sebagai jalur normal, tapi tidak boleh
   jadi satu-satunya — aplikasi yang dibunuh tidak akan pernah mengirimnya.

Setiap jawaban disimpan ke server saat dibuat (auto-save), bukan saat submit.
Sesi yang tertutup karena waktu habis tetap membawa semua jawaban yang sudah
tersimpan.

## Alternatif yang dipertimbangkan

### Hitung mundur dari jam perangkat
Ditolak. Mengubah jam HP mundur satu jam memberi siswa satu jam tambahan. Ini
bukan celah sulit — ini dua ketukan di Pengaturan.

### Timer klien dengan validasi server hanya saat submit
Ditolak setengah. Server memang harus memvalidasi saat submit, dan itu tetap
dilakukan. Tapi kalau klien menampilkan sisa 10 menit sementara server sudah
menutup ujian, siswa mengerjakan 10 menit yang lalu dibuang — pengalaman yang
jauh lebih buruk daripada timer yang akurat sejak awal.

### Timer via WebSocket dari server
Akurat dan realtime. Ditolak: backend belum punya infrastruktur WebSocket sama
sekali (tidak ada Reverb/Pusher di `composer.json`), dan koneksi persisten justru
paling rapuh di jaringan yang jadi masalah utama kita. Polling `server_time`
nebeng request yang sudah ada memberi 95% manfaatnya dengan 5% biayanya.

### Mengizinkan ujian dikerjakan offline lalu disinkronkan
Ditolak. Tidak ada cara memverifikasi kapan jawaban sebenarnya dibuat. Ini
membuka manipulasi yang tidak bisa dideteksi, pada data yang paling penting
konsekuensinya.

## Konsekuensi

**Positif**
- Waktu ujian tidak bisa dimanipulasi dari klien.
- Sesi pulih dengan benar setelah aplikasi ter-*kill*.
- Sesi tidak menggantung terbuka kalau perangkat siswa mati.

**Negatif**
- Ujian **wajib online**. Siswa tanpa sinyal sama sekali tidak bisa mulai ujian.
  Diterima: ini konsekuensi jujur, dan sekolah perlu tahu.
- Sinkronisasi ulang menambah request. Kecil, dan sebagian besar bisa nebeng
  respons auto-save.
- Butuh scheduled job baru di backend untuk menutup sesi kedaluwarsa.

**Kewajiban lanjutan**
- Saat offline di tengah ujian, **jangan blokir input dan jangan tendang siswa
  keluar**. Waktu terus berjalan di server; memblokir input berarti mencuri waktu
  ujian karena masalah jaringan. Jawaban diantre di memori dan di-flush saat
  koneksi kembali.
- `StartExamSession` sudah idempoten dan tidak me-reset `started_at` — sifat ini
  **wajib dipertahankan**. Kalau hilang, siswa bisa mendapat waktu tambahan
  dengan menekan "mulai" berulang kali.

## Kapan keputusan ini perlu ditinjau ulang

Kalau backend kelak punya infrastruktur realtime untuk kebutuhan lain, timer via
WebSocket bisa dihitung ulang sebagai peningkatan — bukan sebagai pengganti
otoritas server.
