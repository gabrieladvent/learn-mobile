# ADR-0010 — File lewat endpoint berautorisasi, bukan URL publik

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/08](../08-security-and-privacy.md), [docs/06](../06-offline-and-sync.md)

## Konteks

File di LMS ini dikelola Spatie Media Library dalam beberapa koleksi:
`material_files`, `assignment_attachments`, `submission_files`, `question_files`.

Backend **sudah** membuat keputusan yang benar: file disimpan di disk privat
tanpa URL publik, dan disajikan lewat trait `ServesGuardedMedia` melalui route
yang memverifikasi kepemilikan/enrollment. Komentarnya eksplisit — "File tidak
lagi punya URL publik (`getUrl()`)".

Pertanyaan untuk mobile: apakah tetap begitu, atau memakai URL bertanda tangan
sementara (signed URL) yang lebih mudah dikonsumsi klien?

Yang dipertaruhkan nyata. `submission_files` berisi jawaban siswa,
`question_files` berisi soal ujian yang belum dikerjakan siswa lain. URL yang
bocor ke riwayat browser, log proxy, atau tangkapan layar grup WhatsApp adalah
kebocoran permanen.

## Keputusan

Aplikasi mobile mengunduh file **hanya** lewat endpoint berautorisasi dengan
Bearer token. API mengirim `download_path` (path relatif), bukan URL absolut,
apalagi URL publik.

```json
{ "id": "media-uuid", "file_name": "modul.pdf",
  "download_path": "/api/v1/materials/{material}/files/{media}/download" }
```

Tambahan untuk mobile:
- Dukungan header `Range` supaya unduhan besar bisa dilanjutkan di jaringan buruk.
- `Content-Length` dan `ETag` supaya klien bisa mendeteksi file berubah.
- File disimpan di direktori privat aplikasi, diindeks per `media_id`.

## Alternatif yang dipertimbangkan

### Signed URL berumur pendek (mis. 15 menit)
Menarik: bisa dilempar ke downloader mana pun tanpa header auth, dan bisa
di-*offload* ke CDN. Ditolak untuk sekarang karena:
- URL yang valid bisa dibagikan ke siapa pun selama masa berlakunya — untuk soal
  ujian, 15 menit sudah lebih dari cukup untuk menyebar ke satu angkatan.
- Menambah jalur otorisasi kedua yang harus dijaga konsisten dengan yang pertama.
- Backend sudah punya jalur berautorisasi yang bekerja; menambah yang kedua
  adalah biaya tanpa kebutuhan yang mendesak.

### URL publik di disk publik
Ditolak tegas. Berarti jawaban siswa dan soal ujian bisa diakses siapa pun yang
menebak atau menemukan URL-nya.

### Mengirim file sebagai base64 di payload JSON
Ditolak. Membengkakkan payload ~33%, tidak bisa distream, dan menghabiskan
memori di HP kelas bawah untuk file 10 MB.

## Konsekuensi

**Positif**
- Otorisasi ditegakkan pada setiap unduhan, per siswa, tanpa jalur alternatif.
- Backend bisa mencatat unduhan (sudah dipakai sebagai proxy penyelesaian materi
  tipe file).
- Tidak ada URL yang bisa dibagikan dan tetap valid.

**Negatif**
- Semua trafik file melewati server aplikasi — tidak bisa di-*offload* ke CDN.
  Pada skala satu sekolah ini baik-baik saja; kalau jadi masalah, jawabannya
  adalah signed URL berumur sangat pendek untuk koleksi non-sensitif saja
  (`material_files`), **bukan** untuk `question_files` atau `submission_files`.
- Klien tidak bisa memakai downloader sistem; harus memakai Dio dengan header auth.
- Setiap unduhan ulang butuh token yang masih valid — file yang sudah tersimpan
  lokal tetap bisa dibuka offline, tapi unduhan baru tidak.

**Kewajiban lanjutan**
- **Nama file dari server tidak tepercaya.** Simpan dengan nama berbasis
  `media_id` untuk menghindari path traversal; tampilkan nama aslinya hanya di UI.
- File soal ujian (`question_files`) dihapus dari penyimpanan lokal setelah sesi
  ujian selesai.
- Semua file lokal dihapus saat logout — perangkat sering dipakai bergantian
  antar saudara.

## Kapan keputusan ini perlu ditinjau ulang

Kalau biaya bandwidth server jadi masalah nyata, pertimbangkan signed URL pendek
khusus `material_files`. Koleksi yang memuat soal dan jawaban tidak masuk
pertimbangan itu.
