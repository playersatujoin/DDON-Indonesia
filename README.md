# Dragon's Dogma Online — Bahasa Indonesia

Patch terjemahan untuk mengikuti cerita DDON: **subtitle, percakapan karakter/NPC, dan quest**. Suara karakter tetap seperti aslinya.

> **Status:** ZIP sedang diunggah. Tunggu sampai `DDON-Indonesia-v1.0.0.zip` muncul di bagian Assets pada halaman Releases.

## Unduh

**[Buka halaman unduhan](https://github.com/playersatujoin/DDON-Indonesia/releases/latest)** dan pilih **`DDON-Indonesia-v1.0.0.zip`** (sekitar 1,34 GB).

Jangan memilih **Source code** atau **Code → Download ZIP** karena keduanya hanya berisi dokumentasi dan skrip, tanpa patch game.

## Cara pasang — drag and drop

**Tidak perlu menjalankan skrip atau memasukkan API key.** Gunakan client English yang sesuai dengan versi dasar patch ini.

1. **Tutup game dan launcher.** Cadangkan folder `nativePC` game Anda ke lokasi terpisah sebelum mengganti file.
2. **Ekstrak ZIP**, lalu buka folder `patch` di dalam hasil ekstraksi.
3. **Tarik atau salin folder `nativePC`** dari `patch` ke folder game yang berisi `DDO.exe`.
4. Pilih **Replace the files in the destination / Ganti file di tujuan** ketika diminta. Setelah penyalinan selesai, jalankan game seperti biasa.

```text
Dari hasil ekstraksi:               Ke folder game:
patch/                             Dragon's Dogma Online/
└── nativePC/        ──────────►    ├── DDO.exe
                                   └── nativePC/
```

**Gabungkan dengan folder yang sudah ada. Jangan hapus `nativePC` game dan jangan menaruh folder `patch` di dalam game.** Patch hanya membawa sebagian file game.

Client atau patch English yang berbeda belum tentu cocok. Mod lain yang mengubah file ARC yang sama akan ikut tertimpa. Jika ragu tentang kecocokan, gunakan pemeriksaan otomatis pada pilihan installer di bawah sebelum menyalin.

## Kembali ke English

Tutup game dan launcher, lalu salin kembali file yang diganti dari cadangan milik Anda. Jika ada mod atau pembaruan yang dipasang setelah terjemahan, periksa perubahan tersebut sebelum memulihkan cadangan. [Panduan pemulihan manual lengkap](Panduan-Pemasangan-Manual.txt).

<details>
<summary><strong>Pilihan lain: installer dengan pemeriksaan dan cadangan otomatis</strong></summary>

Cara ini opsional. Installer memeriksa kecocokan client, mencadangkan file asli, memasang patch, dan memverifikasi hasilnya. Sediakan sekitar 5 GB tambahan untuk ZIP, hasil ekstraksi, dan cadangan installer; cadangan seluruh folder `nativePC` secara manual bisa jauh lebih besar.

Buka PowerShell di folder hasil ekstraksi yang berisi `Pasang-Terjemahan.ps1`. Ganti lokasi game sesuai komputer Anda.

Periksa dulu tanpa memasang:

```powershell
.\Pasang-Terjemahan.ps1 -GamePath "D:\Dragon's Dogma Online" -CheckOnly
```

Setelah muncul **Pemeriksaan berhasil**, pasang:

```powershell
.\Pasang-Terjemahan.ps1 -GamePath "D:\Dragon's Dogma Online"
```

Cadangan dibuat dalam `<folder-game>\DDON-Indonesia-backup\`. Simpan folder paket dan cadangan Anda.

Untuk memulihkan pemasangan yang dilakukan melalui installer:

```powershell
.\Pulihkan-English.ps1 -GamePath "D:\Dragon's Dogma Online" -CheckOnly
.\Pulihkan-English.ps1 -GamePath "D:\Dragon's Dogma Online"
```

Jalankan perintah kedua hanya setelah pemeriksaan berhasil. Cadangan dari cara drag-and-drop dipulihkan secara manual, bukan dengan skrip ini.

Jika kebijakan PowerShell melarang skrip, gunakan cara drag-and-drop. Panduan lebih lengkap tersedia di [Panduan-Pemasangan.txt](Panduan-Pemasangan.txt).

</details>

<details>
<summary><strong>Memeriksa unduhan dan memperbarui patch</strong></summary>

Untuk memeriksa integritas unduhan, cocokkan hasil perintah berikut dengan `SHA256SUMS.txt` pada halaman Releases:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath '.\DDON-Indonesia-v1.0.0.zip'
```

`manifest.json` mencatat ukuran dan hash ARC asli serta hasil terjemahan. Installer memakai daftar ini untuk memeriksa kecocokan.

Untuk memperbarui patch, pulihkan English menggunakan cadangan versi lama, lalu pasang paket baru yang cocok. Jangan mencampur `manifest.json`, skrip, dan isi `patch` dari rilis berbeda. Updater game dapat mengganti file terjemahan.

</details>

## Isi dan status terjemahan

Versi `v1.0.0` memakai revisi `quality-review-v2`: **55.376 entri terjemahan dalam 3.777 arsip ARC**, mencakup 4.396 subtitle, 23.042 percakapan, 15.067 teks NPC, dan 12.871 teks/tujuan quest.

Seluruh 56.230 entri dalam inventaris yang ditargetkan telah diproses; 854 entri dipertahankan. Ini bukan jaminan semua teks pada setiap versi client/server sudah tercakup.

Arsip UI umum asli dipertahankan setelah masalah pemuatan font dan ikon; **89 label menu layanan NPC masih menggunakan teks asli**. Pengujian ulang seluruh tampilan di dalam game belum selesai. Mod ultrawide dan perubahan resolusi tidak termasuk.

## Ada masalah?

**[Laporkan melalui Issues](https://github.com/playersatujoin/DDON-Indonesia/issues)** dengan nama quest/NPC, teks atau pesan error, dan tangkapan layar. Untuk kalimat yang janggal, tambahkan konteks adegannya. Jika game gagal berjalan setelah pemasangan, tutup game dan pulihkan cadangan English terlebih dahulu.

Proyek komunitas ini tidak berafiliasi dengan Capcom. Nama Dragon's Dogma Online dan aset game merupakan milik pemegang hak masing-masing. Patch memerlukan instalasi game yang sudah dimiliki pemain.
