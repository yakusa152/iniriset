# INIRISET Online — versi 1.0

Aplikasi web Next.js + Supabase untuk pemesanan layanan akademik, upload dokumen privat, invoice PDF, tracking, dan dashboard admin.

## 1. Buat project Supabase
1. Buka https://supabase.com dan buat project baru.
2. Buka SQL Editor, jalankan seluruh isi `supabase/schema.sql`.
3. Buka Project Settings → API. Salin Project URL dan anon/public key.
4. Authentication → URL Configuration: masukkan URL lokal dan URL Vercel setelah deploy.
5. Authentication → Providers → Email: atur verifikasi email sesuai kebutuhan.

## 2. Jalankan secara lokal
1. Install Node.js versi LTS.
2. Ekstrak ZIP, buka folder proyek di terminal.
3. Jalankan `npm install`.
4. Salin `.env.example` menjadi `.env.local`.
5. Isi `NEXT_PUBLIC_SUPABASE_URL` dan `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
6. Jalankan `npm run dev`, lalu buka http://localhost:3000.

## 3. Jadikan akun Anda admin
1. Daftar akun melalui `/daftar` pada aplikasi lokal atau setelah deploy.
2. Di Supabase → Authentication → Users, salin UUID akun Anda.
3. Jalankan di SQL Editor:
   `update public.profiles set role='admin' where id='UUID-AKUN-ANDA';`
4. Login kembali. Dashboard admin tersedia di `/dashboard`.

Jangan pernah memberi role admin melalui formulir publik. Hanya ubah role melalui Supabase SQL Editor sebagai pemilik project.

## 4. Deploy ke Vercel
1. Buat repository GitHub dan upload seluruh isi folder proyek.
2. Buka https://vercel.com → Add New → Project → import repository.
3. Tambahkan Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
4. Klik Deploy.
5. Salin domain Vercel, misalnya `iniriset.vercel.app`.
6. Tambahkan domain itu di Supabase → Authentication → URL Configuration (Site URL dan Redirect URLs).
7. Bagikan link domain tersebut ke pelanggan.

## 5. Alur penggunaan
- Pelanggan daftar/login → `/pesan` → pilih layanan → unggah file → kirim.
- Sistem menyimpan order dan nomor invoice di Supabase.
- Pelanggan melacak nomor invoice melalui `/tracking`.
- Pelanggan mengunduh PDF dari halaman invoice.
- Admin login melalui `/login`; setelah role admin diatur, diarahkan ke `/dashboard`.
- Admin dapat mengubah harga, status, dan konfirmasi pembayaran manual.
- File pelanggan disimpan di private Storage bucket. Admin mengaksesnya melalui signed URL yang berlaku 90 detik.

## Catatan keamanan dan batasan
- Jangan pernah memasukkan Supabase `service_role` key ke browser atau repository.
- RLS di database membatasi pelanggan melihat pesanan sendiri; admin mendapat akses sesuai role.
- Untuk produksi, aktifkan verifikasi email, gunakan password kuat dan MFA untuk admin.
- Pembayaran manual belum terintegrasi bank/QRIS; admin mencocokkan transfer di luar aplikasi lalu menandai lunas.
- Invoice PDF dibuat dari tampilan invoice di browser.
- Upload maksimum 10 MB dan bucket dibatasi tipe file. Uji tipe MIME dan ukuran file sesuai kebutuhan operasional.
- Tambahkan kebijakan privasi, ketentuan layanan, backup database, serta retensi/penghapusan dokumen pelanggan sebelum menerima data sensitif.
- Jangan gunakan layanan untuk menulis skripsi/tesis atas nama mahasiswa. INIRISET menyediakan konsultasi, analisis data, interpretasi, dan proofreading yang menjaga integritas akademik.

## Struktur
- `src/app` — halaman web dan dashboard
- `src/lib/supabase` — client/server Supabase
- `supabase/schema.sql` — database, RLS, dan storage policies
