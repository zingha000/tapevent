# TapEvent — Catatan Progres

Status terkini ringkas.

## Selesai

- **Restyle UI Beranda** — kartu event fit-to-content, font Poppins, format tanggal Indonesia (`8 juni - 10 juni 2026`), border abu tipis (tanpa shadow), tombol "Lihat Detail" merah.
- **Card horizontal stabil** — hapus `Spacer`/`fill`/`height: double.infinity` yang menyebabkan konten hilang (bug runtime layout). Ada widget test: `test/card_layout_test.dart`.
- **Flash formulir pendaftaran** — tombol "Formulir Pendaftaran" tidak lagi muncul sesaat untuk event yang sudah didaftar; ada spinner saat cek status registrasi.
- **Warna merah kembali** — tombol Kelola (Dashboard), tombol Masuk/Daftar (`PrimaryButton`), dan navbar aktif.
- **Semua shadow → border abu tipis** — 28 titik (kartu, dialog, navbar, banner, badge) sudah diganti `Border.all(color: context.border, width: 1)`. `boxShadow` = 0.
- **Dark mode netral** — palet dark dari cokelat/maroon (`#1A1512` dll) menjadi abu netral (`#111111`, `#1E1E1E`, `#333333`).
- Ikon peserta — diganti avatar stack 3 bulatan; jumlah "X peserta" tetap.

## Catatan

- `boxShadow` sudah tidak ada; desain flat dengan border.
- Header merah (Beranda/Profil) dan gradient splash tetap brand color, sengaja.
- Analyze: hanya info/warning pre-existing (tidak ada error).
- Build web `--release` selalu sukses sebelum dikirim.

## Cara verifikasi

```
dart analyze lib
flutter test test\card_layout_test.dart
flutter build web --release
```
