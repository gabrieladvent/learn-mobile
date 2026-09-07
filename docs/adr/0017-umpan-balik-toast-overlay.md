# ADR-0017 — Umpan balik sekilas lewat `Overlay`, bukan `SnackBar`

- **Status:** Accepted
- **Tanggal:** 2026-09-07
- **Terkait:** [ADR-0005](0005-state-management-riverpod.md), [ADR-0015](0015-format-error-api.md), [docs/05](../05-screens-and-flows.md)

## Konteks

Aplikasi ini punya tiga jenis kabar yang harus sampai ke siswa, dan ketiganya
sempat ditangani dengan cara yang berbeda-beda tanpa aturan:

| Jenis | Contoh | Sifat |
|-------|--------|-------|
| Kegagalan yang menempel pada satu input | NISN kosong, password kurang dari 8 karakter | Harus terlihat **di sebelah** input yang salah |
| Kegagalan yang tidak punya tempat menempel | Koneksi putus, server error, akun dinonaktifkan | Tidak ada input yang bisa ditandai |
| Kabar berhasil | "Password berhasil diganti" | Sekilas, tidak perlu ditindak |

Sebelumnya ada tiga mekanisme untuk itu: `FailureBanner` (kotak merah di dalam
kolom layar), `AppSnackBar` (pembungkus `ScaffoldMessenger`), dan `errorText`
bawaan `TextField`. Batas antar ketiganya tidak pernah ditulis, jadi layar yang
berbeda memilih berbeda untuk kasus yang sama.

Dua masalah nyata muncul dari situ:

1. **`FailureBanner` menggeser tata letak.** Ia lahir di dalam kolom, tepat di
   atas tombol. Siswa menekan "Masuk", banner muncul, tombolnya turun — dan di
   layar pendek, banner itu lahir di luar area yang terlihat. Siswa menekan
   tombol dua kali karena mengira tidak terjadi apa-apa.
2. **`SnackBar` muncul di bawah, tempat tombol utama berada.** Di layar login
   dan ganti password, pesannya menutupi tombol yang baru saja ditekan. `SnackBar`
   juga memakai `inverseSurface` — warna yang sengaja terbalik dari tema — jadi
   di mode gelap ia jadi kotak putih menyala.

## Keputusan

Kami memakai **satu mekanisme berbasis [`Overlay`]** — `AppToast` — untuk semua
umpan balik sekilas, dan menetapkan **satu aturan penempatan** berdasarkan asal
kegagalannya:

- **Kegagalan validasi per-field** (`ValidationFailure` dengan `fields`) tetap
  tampil sebagai `errorText` di bawah input yang bersangkutan. Ini satu-satunya
  kabar yang tahu persis ke mana harus menunjuk, dan ia harus bertahan di layar
  selama kesalahannya belum diperbaiki.
- **Semua kegagalan lain** muncul sebagai toast. Ia tidak menggeser apa pun,
  hilang sendiri setelah 3 detik, dan bisa diketuk untuk ditutup lebih cepat.
- **Kabar berhasil** juga toast, dengan warna dan ikon yang berbeda.

Toast muncul di **tengah atas**, memakai warna yang mengikuti tema (gelap ikut
gelap), dan hanya boleh ada **satu** di layar — pesan baru menggantikan yang
lama, tidak mengantre.

`FailureBanner` dan `AppSnackBar` dihapus.

## Alternatif yang dipertimbangkan

### Tetap memakai `ScaffoldMessenger` / `SnackBar`
Pilihan bawaan Flutter, gratis, dan sudah dikenal semua orang. Ditolak karena
dua alasan di atas: posisinya di bawah menutupi tombol utama di layar yang
paling sering dipakai, dan warnanya sengaja melawan tema. Keduanya bisa
ditambal (`behavior: floating`, `margin` besar, `backgroundColor` sendiri), tapi
tambalan itu harus diulang di setiap pemanggilan — dan yang terlupa akan
terlihat berbeda.

### `SnackBar` dengan posisi diubah lewat `SnackBarThemeData`
Lebih rapi dari menambal per pemanggilan, tapi `SnackBar` tetap hidup di dalam
`Scaffold`: posisinya terikat ke tata letak layar, dan ia ikut tergeser oleh
`bottomNavigationBar` atau papan ketik. Yang kami butuhkan justru pesan yang
**bebas dari tata letak layar**.

### Banner tetap (`MaterialBanner`) untuk semua kegagalan
Tidak hilang sendiri, jadi cocok untuk kabar yang harus ditindak. Ditolak
sebagai mekanisme utama karena masalah aslinya justru itu: kotak yang menggeser
tata letak tepat setelah siswa menekan tombol. Dipakai terbatas — banner
pembaruan opsional memang perlu bertahan sampai ditutup.

### Paket pihak ketiga (`another_flushbar`, `fluttertoast`, dan sejenisnya)
Ditolak. Yang dibutuhkan hanya satu widget di atas `Overlay` — sekitar 250 baris
yang seluruhnya bisa kami baca dan uji. Menambah ketergantungan yang harus
diikuti versinya untuk sesuatu sekecil ini tidak sepadan.

## Konsekuensi

**Positif**
- Satu aturan yang bisa dijawab tanpa berdebat: kegagalan per-field menempel di
  input, sisanya jadi toast.
- Pesan tidak pernah menggeser tata letak, jadi tombol tidak lari saat ditekan.
- Muncul di atas segalanya (`rootOverlay`), jadi tetap terlihat dari dalam
  dialog atau navigator bersarang.
- Warnanya mengikuti tema, dan jenis pesan dibedakan **ikon**, bukan hanya
  warna — sekitar 8% laki-laki kesulitan membedakan merah dan hijau.

**Negatif**
- Ini kode kami sendiri, jadi perbaikan Material di kemudian hari tidak ikut
  gratis. Perilaku yang tidak diuji tidak akan ada yang menambalkan.
- Toast **hilang sendiri**. Kabar yang benar-benar penting dan mudah terlewat
  tidak boleh hanya disampaikan lewat toast.
- Hanya satu pesan di layar. Dua kegagalan yang datang berdekatan berarti yang
  pertama tidak terbaca — ini disengaja, tapi berarti toast tidak cocok untuk
  hasil operasi massal.
- `AppToast` menyimpan entri yang sedang tampil di variabel **statis**, jadi
  ada satu keadaan global di dalamnya. Cukup untuk aplikasi berlayar tunggal
  seperti ini, dan akan perlu ditinjau kalau nanti ada beberapa `Overlay` hidup
  bersamaan.

**Netral / kewajiban lanjutan**
- Kegagalan yang membutuhkan tindakan siswa (mis. "kumpulan tugasmu belum
  terkirim") tidak boleh memakai toast — ia perlu tempat tetap di layar.
- Setiap layar baru yang menampilkan kegagalan wajib memisahkan
  `ValidationFailure` dari yang lain, seperti di `LoginScreen` dan
  `ChangePasswordScreen`.

## Kapan keputusan ini perlu ditinjau ulang

- Kalau aplikasi mulai punya beberapa `Overlay` hidup bersamaan (mis. mode ujian
  dengan navigator terpisah) — keadaan statis di `AppToast` perlu dipindah ke
  provider.
- Kalau muncul kebutuhan menampilkan antrean pesan, bukan satu pesan terakhir.
