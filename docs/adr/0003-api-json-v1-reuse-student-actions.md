# ADR-0003 — API JSON `/api/v1` yang membungkus Student Actions

- **Status:** Accepted
- **Tanggal:** 2026-09-04
- **Terkait:** [ADR-0002](0002-flutter-native-bukan-webview.md), [docs/03](../03-api-contract.md), [docs/10](../10-backend-changes.md)

## Konteks

`lms-app` **tidak punya `routes/api.php`.** Seluruh permukaan siswa berjalan
lewat Inertia dengan autentikasi sesi.

Tapi backendnya beruntung sudah tersusun rapi: setiap controller siswa tipis dan
mendelegasikan ke `app/Actions/Student/*` — `GetStudentDashboard`,
`GetStudentCourse`, `GetStudentAssignment`, `StartExamSession`, dan seterusnya.
Semua Action itu mengembalikan `array` polos dan **tidak menyentuh Inertia sama
sekali**. Controller web hanya membungkusnya dengan `Inertia::render(...)`.

Artinya logika bisnis, otorisasi (cek enrollment), dan aturan visibility sudah
berada di lapisan yang netral terhadap transport. Yang belum ada hanyalah
pembungkus JSON dan autentikasi token di depannya.

## Keputusan

Kami menambahkan API JSON bervesi di `/api/v1` yang controllernya **memanggil
Action yang sama persis** dengan controller web, lalu membungkus hasilnya jadi
JSON. Tidak ada logika bisnis yang disalin atau ditulis ulang untuk mobile.

```php
// Web
return Inertia::render('Dashboard/Dashboard', $action->handle($student));

// API
return response()->json(['data' => $action->handle($student)]);
```

Konsekuensinya, bentuk payload di [docs/03](../03-api-contract.md) bukan desain
baru — ia cerminan dari apa yang sudah dipakai frontend web hari ini.

## Alternatif yang dipertimbangkan

### API terpisah dengan logika sendiri
Memberi kebebasan mendesain payload ideal untuk mobile. Ditolak: aturan
visibility (`is_published` + jendela `available_from`/`available_until` +
enrollment) dan aturan ujian akan ada di dua tempat. Setiap perubahan aturan
harus diingat di dua tempat, dan yang terlupa akan jadi celah otorisasi —
bukan sekadar bug tampilan.

### Reuse route web dengan `Accept: application/json`
Inertia bereaksi pada header `X-Inertia`, jadi secara teknis bisa dipaksa.
Ditolak: responsnya membawa bagasi Inertia (props halaman, versi aset,
redirect berbentuk 409), autentikasinya berbasis sesi + CSRF, dan setiap
perubahan halaman web akan mengubah payload mobile tanpa disadari siapa pun.

### GraphQL
Ditolak. Domainnya kecil dan bentuk kebutuhannya sudah pasti; biaya belajar dan
operasional tidak sebanding. Tidak ada masalah over-fetching yang nyata di sini.

### Backend-for-Frontend terpisah
Ditolak. Menambah satu layanan untuk dirawat demi keuntungan yang tidak ada pada
skala ini.

## Konsekuensi

**Positif**
- Aturan otorisasi hanya ada satu tempat. Perbaikan di Action otomatis berlaku
  untuk web dan mobile.
- Pekerjaan backend jadi jauh lebih kecil: transport + auth, bukan domain.
- Payload sudah terbukti dipakai frontend nyata, bukan spekulasi.

**Negatif**
- Payload dibentuk untuk kebutuhan web, kadang lebih gemuk dari yang mobile
  butuhkan. Diterima untuk MVP; optimasi per-endpoint bisa menyusul kalau
  pemakaian data terbukti bermasalah.
- Beberapa payload memuat field khas web (hasil `route()`) yang harus dibuang,
  dan menambah `material_id` sebagai gantinya. Perubahannya kecil tapi harus
  dilakukan sadar, bukan dibiarkan.
- Perubahan Action untuk kebutuhan web bisa merusak mobile tanpa sengaja.
  Mitigasi: test kontrak (snapshot bentuk JSON) di backend.

**Kewajiban lanjutan**
- Verifikasi ulang bahwa `correct_answer` tidak ikut ke payload siswa sebelum
  `results_released_at` lewat — di web ini mungkin tertutup oleh komponen React,
  tapi di API payload-nya terbaca langsung.

## Kapan keputusan ini perlu ditinjau ulang

Kalau kebutuhan mobile dan web menyimpang jauh (misalnya mobile butuh payload
jauh lebih ramping karena data mahal), pertimbangkan menambah parameter
`fields`/`include` di endpoint yang bermasalah — bukan langsung membuat API kedua.
