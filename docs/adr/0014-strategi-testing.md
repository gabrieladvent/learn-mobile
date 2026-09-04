# ADR-0014 — Strategi testing berbasis risiko

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [docs/06](../06-offline-and-sync.md), [docs/07](../07-exam-mode.md)

## Konteks

Tim kecil, dan waktu testing terbatas. Menargetkan coverage tinggi secara merata
akan menghabiskan waktu pada bagian yang murah kalau rusak (tata letak kartu di
beranda) dan tetap meninggalkan lubang di bagian yang mahal kalau rusak.

Konsekuensi kegagalan sangat tidak merata di aplikasi ini:

| Kalau rusak | Dampak | Bisa diperbaiki setelahnya? |
|-------------|--------|------------------------------|
| Tata letak beranda | siswa terganggu | ya, mudah |
| Cache basi tampil | siswa bingung | ya |
| Submission terduplikasi/hilang | **nilai siswa salah** | kadang, dengan intervensi guru |
| Timer ujian salah | **nilai siswa rusak** | **tidak** |
| Jawaban ujian hilang | **nilai siswa rusak** | **tidak** |

Dua baris terakhir yang menentukan strategi ini.

## Keputusan

Kami menargetkan testing **berdasarkan konsekuensi kegagalan**, bukan angka
coverage merata.

**Wajib punya test menyeluruh (mendekati 100% jalur):**
- Perhitungan timer ujian, termasuk manipulasi jam dan suspend OS.
- Outbox: idempotency, backoff, klasifikasi gagal permanen vs sementara.
- Auto-save jawaban ujian dan pemulihan sesi.
- Guard router (belum login / harus ganti password / force update) dan urutannya.
- Pemetaan `AppFailure` dari setiap kode error API.

**Test wajar (jalur bahagia + kasus tepi utama):**
- Repository: kebijakan cache, pembersihan entri yang dicabut server.
- Parsing model dari payload API.
- Controller/notifier tiap fitur.

**Test ringan (asap saja):**
- Widget presentasional, tata letak, tema.

**Target coverage keseluruhan > 60%**, tapi angka itu **konsekuensi**, bukan
tujuan. PR yang menaikkan coverage dengan menguji getter tidak diterima; PR yang
menambah satu test untuk kondisi balapan di outbox diterima meski angkanya tidak
bergerak.

**Piramida:**
- **Unit** (mayoritas) — logika murni: timer, outbox, mapper, parsing. Cepat,
  jalan di setiap commit.
- **Widget** — layar dengan provider yang di-override; fokus pada state kosong,
  loading, error, dan indikator status kiriman.
- **Integrasi/E2E** (sedikit, `patrol`) — hanya untuk alur yang melintasi banyak
  lapisan: login → ganti password → beranda; kumpul tugas offline → online;
  ujian dengan app di-*kill* dan jaringan putus.

**Test manual yang tidak bisa diotomatiskan** — didokumentasikan sebagai
checklist di [docs/07](../07-exam-mode.md), dijalankan sebelum tiap rilis:
mode pesawat sungguhan, jam perangkat diubah, `force stop` di tengah ujian, dan
**uji lapangan di WiFi sekolah nyata**.

Backend punya kewajiban terpisah: test kontrak (snapshot bentuk JSON) supaya
perubahan payload yang tidak disengaja ketahuan sebelum merusak aplikasi
([docs/10](../10-backend-changes.md)).

## Alternatif yang dipertimbangkan

### Target coverage tinggi merata (mis. 80%)
Ditolak. Mendorong penulisan test yang mudah, bukan yang penting, dan memberi
rasa aman palsu. Coverage 80% yang tidak menyentuh kondisi balapan outbox tidak
melindungi apa pun yang berharga.

### Hanya test manual
Ditolak. Skenario ujian (app di-*kill*, jaringan putus, jam diubah) terlalu
melelahkan untuk diulang manual setiap rilis — jadi dalam praktiknya tidak akan
diulang, dan regresi lolos.

### E2E-heavy
Ditolak. Lambat, rapuh, dan mahal dirawat. Dipakai hemat untuk alur yang benar-
benar melintasi banyak lapisan.

### TDD ketat
Ditolak sebagai keharusan. Dianjurkan untuk logika timer dan outbox — di situ
menulis test dulu benar-benar membantu memikirkan kasus tepi. Tidak dipaksakan
untuk kode UI.

## Konsekuensi

**Positif**
- Usaha testing terkonsentrasi di tempat kegagalannya tidak bisa diperbaiki.
- Test suite tetap cepat, jadi benar-benar dijalankan.

**Negatif**
- Bug UI akan lolos ke produksi lebih sering. Diterima secara sadar — bisa
  diperbaiki di rilis berikutnya.
- "Berbasis risiko" butuh penilaian, dan penilaian bisa keliru. Mitigasi: daftar
  area wajib di atas ditulis eksplisit, bukan diserahkan ke selera per-PR.

**Kewajiban lanjutan**
- CI menjalankan `flutter analyze` + `flutter test` di setiap PR.
- PR yang menyentuh timer ujian atau outbox **wajib** menyertakan test. Ini
  diperiksa saat review, bukan diharapkan.

## Kapan keputusan ini perlu ditinjau ulang

Kalau bug UI mulai lolos cukup sering sampai mengganggu kepercayaan siswa,
naikkan porsi test widget — bukan naikkan target angka coverage.
