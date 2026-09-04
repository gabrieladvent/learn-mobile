# ADR-0001 — Gunakan ADR untuk mencatat keputusan arsitektur

- **Status:** Accepted
- **Tanggal:** 2026-09-04

## Konteks

`learn_mobile` dimulai dari nol (`flutter create` polos) dan bergantung pada
backend `lms-app` yang dikembangkan tim lain. Beberapa keputusan awal akan sulit
diubah setelah kode tumbuh: pilihan state management, cara autentikasi, dan
sikap terhadap offline.

Repo `lms-app` sendiri sudah menunjukkan biaya dari keputusan yang tidak dicatat:
`docs/02-database-schema.md` menjelaskan skema yang tidak lagi cocok dengan
migrasi (`assignments` dan `exams` sudah pindah menempel ke `materials`), dan
tidak ada catatan kenapa perubahan itu terjadi. Siapa pun yang membaca doc itu
hari ini akan membangun asumsi yang salah.

Yang hilang bukan diagram atau spesifikasi — itu ada. Yang hilang adalah
**alasan**. Enam bulan lagi, orang yang melihat "kenapa timer ujian dihitung
dari server, padahal lebih ribet?" tidak punya tempat untuk menemukan jawabannya,
dan berpeluang besar "menyederhanakannya" jadi bug.

## Keputusan

Kami mencatat setiap keputusan arsitektur yang signifikan sebagai ADR di
`docs/adr/`, memakai format Michael Nygard yang disederhanakan. ADR bersifat
*append-only*: keputusan yang berubah ditulis sebagai ADR baru yang
men-*supersede* yang lama, bukan dengan mengedit yang lama.

Sebuah keputusan dianggap signifikan kalau memenuhi minimal satu:

- mahal untuk dibalik setelah kode tumbuh,
- memengaruhi lebih dari satu fitur,
- menolak alternatif yang tampak jelas lebih mudah,
- menyangkut keamanan, privasi, atau integritas nilai siswa.

## Alternatif yang dipertimbangkan

### Menulis semuanya di README / dokumen desain
Ditolak. Dokumen desain merekam keadaan *sekarang* dan ditimpa saat berubah —
justru alasan keputusannya yang hilang, persis seperti yang terjadi di doc
`lms-app`.

### Mengandalkan riwayat commit dan PR
Ditolak. Pesan commit menjelaskan perubahan kode, bukan alternatif yang ditolak.
Mencari alasan di ratusan PR bukan hal yang benar-benar dilakukan orang.

### Tidak mencatat sama sekali
Ditolak. Project ini akan dilanjutkan orang yang tidak hadir saat keputusan
dibuat — termasuk penulisnya sendiri enam bulan kemudian.

## Konsekuensi

**Positif**
- Alasan keputusan bertahan lebih lama dari ingatan dan dari orangnya.
- Diskusi ulang jadi lebih cepat: alternatif yang sudah ditolak tidak dibahas dua kali.
- Onboarding developer baru jauh lebih murah.

**Negatif**
- Overhead menulis di setiap keputusan besar.
- ADR yang tidak dirawat bisa jadi menyesatkan — persis penyakit yang mau
  dihindari. Mitigasi: status wajib diperbarui saat di-*supersede*.

**Kewajiban lanjutan**
- Review PR yang mengubah arah arsitektur harus menanyakan "ADR-nya mana?".

## Kapan keputusan ini perlu ditinjau ulang

Kalau tim menemukan ADR rutin ditulis setelah kode selesai (jadi formalitas,
bukan alat berpikir), formatnya perlu dievaluasi ulang.
