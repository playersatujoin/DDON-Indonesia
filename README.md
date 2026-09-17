# Dragon's Dogma Online — Bahasa Indonesia

Terjemahan komunitas untuk membantu pemain mengikuti cerita **Dragon's Dogma Online (DDON)**: subtitle, percakapan karakter dan NPC, serta teks dan tujuan quest.

> **Status distribusi:** dokumentasi dan skrip sudah tersedia. ZIP terjemahan `v1.0.0` sedang menunggu unggahan ke Releases; belum ada unduhan patch game di repository ini. Panduan di bawah berlaku setelah lampiran ZIP tersedia.

**[Unduh paket terjemahan di Releases](https://github.com/playersatujoin/DDON-Indonesia/releases/latest)** · [Laporkan masalah](https://github.com/playersatujoin/DDON-Indonesia/issues)

Pilih lampiran **`DDON-Indonesia-v1.0.0.zip`** pada halaman rilis. Tombol **Code → Download ZIP** dan tautan **Source code** hanya mengunduh dokumentasi, manifest, dan skrip; file terjemahan game ada dalam lampiran rilis.

## Cakupan dan status

Rilis awal `v1.0.0` memakai revisi terjemahan `quality-review-v2`.

| Bagian | Entri terjemahan |
| --- | ---: |
| Subtitle | 4.396 |
| Percakapan | 23.042 |
| Teks NPC | 15.067 |
| Teks dan tujuan quest | 12.871 |
| **Total** | **55.376** |

Seluruh 56.230 entri dalam inventaris teks yang ditargetkan telah diproses; 854 entri dipertahankan. Angka ini menggambarkan inventaris paket, bukan jaminan bahwa setiap teks yang mungkin muncul di semua server sudah tercakup. Paket berisi 3.777 arsip ARC.

Terjemahan telah melalui peninjauan bahasa dan pemeriksaan struktur file. Arsip UI umum `nativePC/rom/ui/gui_cmn.arc` dipertahankan dalam bentuk aslinya setelah ditemukan masalah pemuatan font dan ikon. Karena itu, 89 label menu layanan NPC masih menggunakan teks asli.

**Pengujian ulang seluruh tampilan di dalam game belum selesai.** Hasil pemeriksaan file tidak menjamin seluruh subtitle, pemenggalan baris, dan tata letak sudah sempurna pada setiap komputer. Silakan laporkan masalah beserta konteksnya.

## Persyaratan dan kompatibilitas

- Windows dengan DDON yang sudah dapat dijalankan menggunakan patch English.
- File client yang sesuai dengan versi dasar paket ini. **Nama server atau nomor versi saja belum cukup:** installer mencocokkan ukuran dan SHA-256 setiap ARC dengan `manifest.json`.
- Sekitar 5 GB ruang kosong tambahan untuk ZIP, hasil ekstraksi, dan cadangan. Cadangan dibuat pada drive tempat game berada.
- Tutup game, launcher, dan updater selama pemeriksaan, pemasangan, atau pemulihan.

Tidak perlu API key, DeepSeek, ChatGPT, atau biaya layanan terjemahan untuk menggunakan patch. Paket ini mengganti teks; suara karakter tidak diubah. Pengaturan resolusi dan mod ultrawide tidak termasuk dalam paket.

Mod lain yang mengubah ARC yang sama dapat bertabrakan dengan terjemahan. Jika installer mendeteksi file berbeda, pulihkan versi English yang sesuai atau mod sebelumnya terlebih dahulu. Jangan memaksa menimpa file yang tidak cocok.

## Pemasangan dengan installer — disarankan

Installer memeriksa paket dan client, membuat cadangan file asli, memasang patch, lalu memeriksa hasilnya.

1. Unduh **`DDON-Indonesia-v1.0.0.zip`** dan **`SHA256SUMS.txt`** dari [halaman rilis](https://github.com/playersatujoin/DDON-Indonesia/releases/latest).
2. Untuk memeriksa unduhan, buka PowerShell di folder unduhan dan jalankan:

   ```powershell
   Get-FileHash -Algorithm SHA256 -LiteralPath '.\DDON-Indonesia-v1.0.0.zip'
   ```

   Cocokkan hasilnya dengan nilai dalam `SHA256SUMS.txt`. Jika berbeda, unduh ulang sebelum melanjutkan.

3. Ekstrak ZIP ke folder biasa yang dapat Anda tulisi, misalnya `C:\Games\DDON-Indonesia-v1.0.0`. Jangan menjalankan skrip langsung dari dalam ZIP. Pertahankan susunan file hasil ekstraksi.
4. Tutup game dan launcher. Buka PowerShell di folder hasil ekstraksi yang berisi `Pasang-Terjemahan.ps1`.
5. Periksa kecocokan tanpa memasang:

   ```powershell
   .\Pasang-Terjemahan.ps1 -GamePath "D:\Dragon's Dogma Online" -CheckOnly
   ```

   Ganti lokasi tersebut dengan folder game Anda, yaitu folder yang berisi `DDO.exe` dan `nativePC`. Tunggu sampai muncul **Pemeriksaan berhasil**. Jika gagal, baca pesannya dan jangan lanjutkan pemasangan.

6. Setelah pemeriksaan berhasil, pasang:

   ```powershell
   .\Pasang-Terjemahan.ps1 -GamePath "D:\Dragon's Dogma Online"
   ```

7. Tunggu pesan **Terjemahan terpasang**, lalu jalankan game seperti biasa.

Cadangan disimpan dalam `<folder-game>\DDON-Indonesia-backup\`. Simpan folder cadangan dan folder paket yang dipakai memasang sampai Anda tidak lagi memerlukan pemulihan. Setiap pemain membuat cadangannya sendiri.

Jika Windows memblokir file unduhan, periksa sumber dan checksum terlebih dahulu, kemudian gunakan **Properties → Unblock** bila opsi tersebut tersedia. Bila kebijakan PowerShell tetap melarang skrip, gunakan panduan manual di bawah; installer tidak mengubah kebijakan keamanan komputer.

## Pemasangan manual — salin folder

Cara salin folder dapat digunakan **setelah versi client cocok dan file asli sudah dicadangkan**. Untuk pemeriksaan hash dan langkah pemulihan terperinci, baca [Panduan-Pemasangan-Manual.txt](Panduan-Pemasangan-Manual.txt).

1. Tutup game dan launcher.
2. Cadangkan folder `nativePC` game Anda ke lokasi terpisah. Cadangan seluruh folder membutuhkan ruang sesuai ukuran folder tersebut, yang bisa jauh lebih besar daripada cadangan installer.
3. Dari hasil ekstraksi, buka **`patch`**, lalu salin folder **`nativePC`** di dalamnya.
4. Tempelkan ke folder game yang berisi `DDO.exe`. Gabungkan folder dan ganti hanya file patch yang sudah diperiksa dan dicadangkan.

Susunan yang benar:

```text
Dragon's Dogma Online/
├── DDO.exe
└── nativePC/
    └── rom/
        └── ...file ARC dari patch...
```

Jangan menaruh folder `patch` sebagai subfolder game. Jangan menghapus `nativePC` yang lama: patch hanya membawa sebagian file yang dibutuhkan game. Pemasangan manual tidak membuat catatan cadangan otomatis untuk `Pulihkan-English.ps1`.

## Kembali ke English

**Jika memasang dengan installer:** tutup game dan launcher, lalu jalankan dari folder paket yang digunakan memasang:

```powershell
.\Pulihkan-English.ps1 -GamePath "D:\Dragon's Dogma Online" -CheckOnly
.\Pulihkan-English.ps1 -GamePath "D:\Dragon's Dogma Online"
```

Jalankan perintah kedua hanya setelah pemeriksaan berhasil. Jika penunjuk cadangan hilang, skrip juga menerima `-BackupPath` yang menunjuk folder sesi cadangan berisi `backup-manifest.json`.

**Jika memasang manual:** pulihkan file ARC yang diganti menggunakan cadangan Anda sendiri. Ikuti [panduan pemulihan manual](Panduan-Pemasangan-Manual.txt). Jangan menimpa mod atau pembaruan lain yang dipasang setelah terjemahan tanpa memeriksa perubahan tersebut.

## Memperbarui patch

Pulihkan English menggunakan paket dan cadangan versi lama, lalu pasang paket baru setelah pemeriksaan kecocokan berhasil. Jangan mencampur `manifest.json`, skrip, dan isi `patch` dari rilis yang berbeda. Setelah updater game mengganti file, periksa lagi kecocokan sebelum memasang ulang.

## Masalah umum

| Masalah | Langkah yang disarankan |
| --- | --- |
| Hash atau ukuran file tidak cocok | Client, patch English, atau mod berbeda. Hentikan pemasangan; simpan file tersebut dan cocokkan versi dasarnya. |
| File sudah ditambal tanpa cadangan yang cocok | Pulihkan patch sebelumnya dengan paket/cadangan yang memasangnya, lalu ulangi pemeriksaan. |
| `Failed open file` untuk font atau ikon | Tutup game; periksa ekstraksi dan `gui_cmn.arc` terhadap manifest. Pulihkan English jika perlu, lalu laporkan pesan error lengkap. |
| Teks tetap English | Pastikan folder tujuan benar dan launcher tidak mengganti file. Beberapa label UI memang dipertahankan; sertakan tangkapan layar untuk teks cerita yang terlewat. |
| Skrip tidak dapat dijalankan | Periksa apakah paket sudah diekstrak dan file unduhan diblokir Windows. Gunakan panduan manual bila kebijakan PowerShell melarang skrip. |
| Bahasa terasa janggal atau subtitle terpotong | Kirim teks, tangkapan layar, nama quest/NPC, serta kejadian sebelum dan sesudahnya melalui Issues. |

## Isi lampiran ZIP

```text
DDON-Indonesia-v1.0.0/
├── README.md
├── CHANGELOG.md
├── manifest.json
├── Pasang-Terjemahan.ps1
├── Pulihkan-English.ps1
├── DDON-Indonesia.Common.ps1
├── Panduan-Pemasangan.txt
├── Panduan-Pemasangan-Manual.txt
└── patch/
    └── nativePC/rom/...
```

`manifest.json` memuat daftar ARC beserta hash file dasar dan hasil terjemahan. Cadangan pribadi, catatan pemasangan komputer pembuat, pengaturan API, dan file login tidak disertakan.

## Laporan dan kontribusi

Buka [Issues](https://github.com/playersatujoin/DDON-Indonesia/issues) untuk laporan bug atau usulan kalimat. Cantumkan versi patch, quest/NPC, teks yang tampil, dan konteks adegan. Untuk error teknis, tambahkan pesan error dan daftar mod yang digunakan. Jangan menyertakan kredensial atau data akun.

Proyek komunitas ini tidak berafiliasi dengan atau disponsori oleh Capcom. Nama Dragon's Dogma Online dan aset game merupakan milik pemegang hak masing-masing. Paket ini memerlukan instalasi game yang sudah dimiliki pemain.
