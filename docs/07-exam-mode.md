# 07 — Mode Ujian

Bagian paling berisiko di MVP. Kalau fitur lain gagal, siswa kesal; kalau ini
gagal, nilai siswa rusak dan sekolah kehilangan kepercayaan pada aplikasinya.

Keputusan dasar: [ADR-0009](adr/0009-timer-ujian-otoritatif-server.md).

## Dua mode

`exams.mode` menentukan alurnya:

| Mode | Alur | Risiko |
|------|------|--------|
| `submission` | unggah berkas jawaban, seperti tugas | rendah — sama seperti assignment |
| `online_quiz` | kerjakan soal bertimer di aplikasi | **tinggi** — sisa dokumen ini membahas ini |

## Prinsip

1. **Server memegang waktu.** Klien hanya menampilkan.
2. **Setiap jawaban disimpan ke server saat dibuat**, bukan saat submit.
   Kehilangan aplikasi ≠ kehilangan jawaban.
3. **Ujian butuh jaringan.** Tidak ada mode ujian offline.
4. **Aplikasi tidak menghakimi.** Kecurigaan kecurangan dilaporkan sebagai
   sinyal ke server, bukan dijadikan alasan aplikasi menghentikan ujian sendiri.
5. **Gagal ke arah yang aman bagi siswa.** Saat ragu, biarkan siswa lanjut
   mengerjakan dan catat kejadiannya. Memutus ujian karena hiccup jaringan
   adalah kerugian yang tidak bisa diperbaiki.

## Timer

Backend mengirim `expires_at` (= `started_at + duration_minutes`) dan
`server_time` di setiap `GET /exams/sessions/{id}`.

```dart
// saat sesi dimuat
final skew = serverTime.difference(DateTime.now());       // koreksi jam HP
final remainingAtLoad = expiresAt.difference(serverTime);
final ticker = Stopwatch()..start();                       // monotonik

Duration get remaining => remainingAtLoad - ticker.elapsed;
```

Kenapa `Stopwatch` dan bukan `DateTime.now()`:

- Siswa bisa mengubah jam HP. `DateTime.now()` ikut berubah, `Stopwatch` tidak.
- Perubahan zona waktu / DST tidak mengganggu hitungan.

Kenapa tetap perlu sinkronisasi ulang: `Stopwatch` **berhenti saat proses
di-suspend OS**. Aplikasi di background lebih dari beberapa menit akan
menghitung sisa waktu lebih banyak dari kenyataan.

**Aturan sinkronisasi ulang** — ambil ulang `server_time` saat:

- aplikasi kembali ke foreground,
- setiap ~60 detik selama ujian berjalan (bisa nebeng respons auto-save),
- sesaat sebelum menampilkan konfirmasi submit.

Kalau selisih hasil sinkronisasi > 5 detik, **koreksi ke nilai server** dengan
animasi halus, bukan lompatan mendadak yang membuat siswa panik.

Saat sisa waktu mencapai nol, klien mengirim `POST .../submit` dengan
`reason: "timeout"`. **Server tetap harus memvalidasi sendiri** — kalau klien
tidak pernah mengirimnya (app dibunuh), sesi yang lewat waktu harus tetap
tertutup dari sisi server. Klien tidak boleh jadi satu-satunya yang menutup ujian.

## Auto-save jawaban

- Pilihan ganda: kirim **segera** saat dipilih.
- Isian singkat & esai: debounce 2 detik setelah berhenti mengetik, plus kirim
  saat pindah soal dan saat aplikasi ke background.
- Endpoint idempoten — jawaban terakhir untuk satu soal menang.
- Rate limit server 120/menit; debounce di atas membuat kita jauh di bawahnya.

Indikator status per soal wajib terlihat: **tersimpan** / **menyimpan…** /
**belum tersimpan**. Peta soal memakai penanda yang sama, jadi siswa bisa
melihat sekilas mana yang belum aman.

Semua jawaban juga ditulis ke penyimpanan lokal sebagai jaring pengaman.
Saat sesi dibuka ulang, jawaban server yang menang; jawaban lokal yang lebih
baru dan belum terkirim ditawarkan untuk dikirim ulang.

## Gangguan jaringan saat ujian

Ini kejadian paling sering di sekolah, dan penanganannya menentukan apakah
fitur ini dipercaya.

| Durasi putus | Perilaku |
|--------------|----------|
| < 30 detik | banner kuning tipis "Koneksi tersendat", timer jalan terus, jawaban antre di memori |
| 30 dtk – 2 mnt | banner merah "Tidak ada koneksi. Jawabanmu tersimpan di perangkat.", retry tiap 5 detik |
| > 2 menit | dialog non-blokir: siswa boleh lanjut mengerjakan; semua jawaban antre |
| Kembali tersambung | flush antrian jawaban berurutan, sinkron ulang timer, banner hijau sebentar |

**Yang tidak boleh dilakukan:** menendang siswa keluar dari layar ujian karena
offline, atau memblokir input sampai koneksi kembali. Waktu ujian terus berjalan
di server — memblokir input berarti mencuri waktu ujian siswa karena masalah
yang bukan salahnya.

Kalau saat submit ternyata masih offline: simpan niat submit, terus retry, dan
tahan siswa di layar dengan pesan jelas. Jangan katakan "terkirim" sebelum
server mengonfirmasi.

## Aplikasi ter-*kill* / restart

```
Buka app → deteksi sesi ujian aktif (belum submitted_at)
  → GET /exams/sessions/{id}
  → hitung sisa waktu dari expires_at & server_time
  ├── masih ada waktu → tawarkan "Lanjutkan ujian"
  └── sudah lewat     → submit dengan reason "timeout", tampilkan hasil/konfirmasi
```

Karena `StartExamSession` idempoten dan tidak me-reset `started_at`, memanggil
"mulai" lagi aman — siswa tidak mendapat waktu tambahan.

## Integritas: yang kita lakukan dan tidak

**Dilakukan:**
- Timer dan penutupan sesi otoritatif di server.
- `shuffle_questions` dihormati (urutan dari server, jangan diacak ulang di klien).
- Catat event `blur`/`focus` lewat pelacakan progress yang sudah ada, sebagai
  **data untuk guru**, bukan pemicu otomatis.
- Nonaktifkan screenshot di layar ujian (`FLAG_SECURE` di Android) — murah,
  meski mudah dilewati.
- Kunci orientasi ke portrait, cegah layar mati selama ujian.

**Tidak dilakukan (non-goal):**
- Kiosk mode / mengunci HP siswa.
- Akses kamera atau mikrofon untuk proctoring.
- Deteksi root/jailbreak sebagai penghalang masuk.
- Menutup ujian otomatis karena siswa pindah aplikasi.

Alasannya: pengguna adalah anak di bawah umur, izin-izin itu invasif, dan
semuanya bisa dilewati dengan HP kedua. Biayanya nyata, manfaatnya ilusi. Kalau
sekolah butuh ujian berisiko tinggi, jawabannya adalah ujian terawasi di ruang
kelas — bukan fitur di aplikasi ini.

⚠️ **Batas yang harus jujur disampaikan ke sekolah:** aplikasi ini tidak bisa
mencegah siswa membuka buku, mencari jawaban di HP lain, atau bekerja sama.
Yang bisa dijamin hanyalah bahwa waktu dan skor tidak bisa dimanipulasi dari
sisi klien. Jangan menjual lebih dari itu.

## Kerahasiaan soal & kunci jawaban

- `correct_answer` **tidak boleh ada di payload** sebelum `results_released_at`
  lewat. Ini kewajiban backend, tapi klien harus mengeceknya di review —
  memfilter di UI tidak ada gunanya, payload tetap bisa dibaca lewat proxy.
- Soal dan jawaban **tidak disimpan** di cache persisten yang tidak terenkripsi.
  Simpan di memori; jawaban lokal jaring pengaman ditulis ke penyimpanan
  terenkripsi dan dihapus setelah submit.
- File soal (`question_files`) diunduh lewat endpoint berautorisasi dan dihapus
  dari penyimpanan setelah sesi selesai.

## Hasil ujian

Tampilkan hanya kalau `results_released` true. Sebelum itu: "Hasil belum
dirilis guru." Untuk soal esai yang belum dinilai, tampilkan "Menunggu
penilaian", bukan nilai 0 — perbedaan ini penting bagi siswa.

## Checklist sebelum rilis fitur ujian

- [ ] Timer benar setelah app di-background 10 menit.
- [ ] Timer tidak berubah saat jam HP dimajukan/dimundurkan.
- [ ] App di-*force stop* di tengah ujian → jawaban utuh, waktu benar.
- [ ] Mode pesawat 3 menit → jawaban tidak hilang, timer tetap akurat setelah kembali.
- [ ] Tekan "Mulai" berkali-kali → satu sesi, `started_at` tidak berubah.
- [ ] Tekan submit dua kali → satu submission, `409` ditangani mulus.
- [ ] Sesi lewat waktu tanpa klien aktif → tertutup dari sisi server.
- [ ] `correct_answer` diverifikasi tidak ada di payload sebelum rilis hasil.
- [ ] Uji lapangan di WiFi sekolah sungguhan, bukan hanya emulator.
