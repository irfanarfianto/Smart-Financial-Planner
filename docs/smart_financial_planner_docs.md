# TECHNICAL DESIGN DOCUMENT (TDD)

**Project:** Smart Financial Planner (SFP)
**Versi Dokumen:** 2.0 (Restructured)
**Tech Stack:** Mobile (Flutter/Kotlin) + Supabase (PostgreSQL)
**Konsep:** Dynamic Budgeting & Accounting Intelligence

## 1. Introduction

### 1.1 Latar Belakang
Aplikasi ini dirancang sebagai manajer keuangan pribadi yang memecahkan masalah pendapatan fluktuatif (tidak tetap). Berbeda dengan aplikasi budgeting konvensional yang statis, SFP menggunakan pendekatan **"Dynamic Allocation"** di mana setiap uang yang masuk akan otomatis dipecah ke pos-pos anggaran secara proporsional.

### 1.2 Glosarium Istilah
- **Dynamic Allocation:** Sistem pembagian otomatis berdasarkan persentase, bukan nominal tetap.
- **Safety Net Protocol:** Algoritma prioritas yang mengamankan biaya hidup dasar (Fixed Cost) sebelum mengalokasikan dana ke investasi atau tabungan.
- **OCR (Optical Character Recognition):** Teknologi untuk membaca teks dari gambar (struk belanja).
- **Burn Rate:** Kecepatan seseorang menghabiskan uangnya dalam periode tertentu.

## 2. Business Logic & Financial Models

Bagian ini menjelaskan aturan bisnis inti yang menjadi "jiwa" dari aplikasi. Sistem harus mendukung tiga model keuangan utama berikut ini:

### 2.1 Model Keuangan (The 3 Personas)

#### A. Growth Mode (60/30/10)
Cocok untuk profil yang mengutamakan keseimbangan hidup dan pengembangan diri.
- **60% Kebutuhan Hidup:** Gaya hidup sederhana tapi cukup.
- **30% Pengembangan & Investasi:** Dibagi rata untuk upgrade skill ("leher ke atas") dan investasi finansial.
- **10% Tabungan:** Disisihkan khusus untuk Dana Darurat.

#### B. Ambisius Builder (50/30/20)
Cocok untuk profil yang sedang mengejar modal usaha atau aset besar dalam waktu cepat.
- **50% Kebutuhan Hidup:** Gaya hidup sangat minimalis/hemat.
- **30% Modal Bisnis/Investasi:** Fokus mengejar modal project atau beli alat kerja produktif.
- **20% Tabungan:** Untuk dana darurat dan biaya upgrade skill.

#### C. Regenerasi Finansial (65/25/10)
Cocok untuk profil yang baru membangun kestabilan atau Generasi Sandwich.
- **65% Kebutuhan Hidup:** Mengcover kebutuhan pokok diri sendiri dan membantu keluarga.
- **25% Tabungan Produktif:** Disimpan di instrumen investasi resiko rendah/kecil.
- **10% Pengembangan:** Kursus atau dana darurat cadangan.

### 2.2 Safety Net Logic (Protokol Darurat)
Sistem tidak boleh buta terhadap nominal.
- **Aturan:** Jika `(Income * Persentase Kebutuhan) < Fixed Cost User`, maka abaikan persentase.
- **Tindakan:** Alokasikan Income sebanyak-banyaknya ke pos Kebutuhan sampai Fixed Cost terpenuhi. Baru sisanya (jika ada) dibagi ke Investasi/Tabungan.

## 3. System Architecture

### 3.1 High Level Diagram
```
[Mobile App]  <--Realtime Sync-->  [Supabase Client SDK]
     |                                     |
[ML Kit OCR]                        [Supabase Database (Postgres)]
     |                                     |
                                    [Trigger & Functions (PL/pgSQL)]
                                           |
                                    [Auto-Update Wallets]
                                           ^
                                           |
                                    [pg_cron & Edge Functions] (Scheduler)
```

### 3.2 Komponen Supabase
- **Auth:** Mengelola user (Email/Password atau Google Auth).
- **Database:** PostgreSQL untuk menyimpan data relasional.
- **Storage:** Bucket receipts untuk menyimpan foto struk.
- **Realtime:** Mengirim update saldo ke aplikasi mobile saat trigger database berjalan.

## 4. Database Schema (Supabase PostgreSQL)

Jalankan script SQL berikut di SQL Editor Supabase Anda.

### 4.1 Tabel Master & User
```sql
-- 1. Master Model Keuangan
CREATE TABLE public.financial_models (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    ratio_needs DECIMAL(3,2),
    ratio_invest DECIMAL(3,2),
    ratio_savings DECIMAL(3,2)
);

-- Seed Data
INSERT INTO public.financial_models (name, ratio_needs, ratio_invest, ratio_savings)
VALUES
('Growth Mode', 0.60, 0.30, 0.10),
('Ambisius Builder', 0.50, 0.30, 0.20),
('Regenerasi Finansial', 0.65, 0.25, 0.10);

-- 2. Profil User
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    fixed_cost_threshold DECIMAL DEFAULT 0, -- Safety Net Threshold
    active_model_id INT REFERENCES public.financial_models(id),
    daily_reminder_time TIME DEFAULT '20:00:00', -- User Configurable
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Device Tokens (Untuk Notifikasi FCM)
CREATE TABLE public.user_devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    fcm_token TEXT NOT NULL,
    device_name TEXT, -- Optional: "Samsung S23", "iPhone 13"
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);
```

### 4.2 Tabel Transaksi & Dompet
```sql
-- 3. Dompet (Pos Anggaran)
CREATE TABLE public.wallets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category TEXT CHECK (category IN ('NEEDS', 'INVEST', 'SAVING')),
    current_balance DECIMAL DEFAULT 0,
    month_period VARCHAR(7) NOT NULL, -- Format "YYYY-MM"
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, category, month_period)
);

-- 4. Jurnal Transaksi
CREATE TABLE public.transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL NOT NULL,
    type TEXT CHECK (type IN ('INCOME', 'EXPENSE', 'TRANSFER')),
    category TEXT, -- Nullable jika INCOME
    description TEXT,
    receipt_url TEXT,
    transaction_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.3 Security Policies (Row Level Security)
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY; -- New
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Access Own Profile" ON profiles FOR ALL USING (auth.uid() = id);
CREATE POLICY "Manage Own Devices" ON user_devices FOR ALL USING (auth.uid() = user_id); -- New
CREATE POLICY "Access Own Wallets" ON wallets FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Access Own Tx" ON transactions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Read Models" ON financial_models FOR SELECT TO authenticated USING (true);
```

## 5. Backend Implementation (The Brain)

Logika otomatisasi yang berjalan di server (Database Trigger).

### 5.1 Function: Handle Income Allocation
```sql
CREATE OR REPLACE FUNCTION handle_new_income()
RETURNS TRIGGER AS $$
DECLARE
    u_model RECORD;
    u_profile RECORD;
    alloc_needs DECIMAL;
    alloc_invest DECIMAL;
    alloc_saving DECIMAL;
    current_month VARCHAR;
    remaining_income DECIMAL;
BEGIN
    IF NEW.type = 'INCOME' THEN
        current_month := TO_CHAR(NEW.transaction_date, 'YYYY-MM');
        SELECT * INTO u_profile FROM profiles WHERE id = NEW.user_id;
        SELECT * INTO u_model FROM financial_models WHERE id = u_profile.active_model_id;

        -- Hitung Alokasi Normal
        alloc_needs := NEW.amount * u_model.ratio_needs;

        -- SAFETY NET CHECK
        IF alloc_needs < u_profile.fixed_cost_threshold THEN
            -- Mode Darurat: Prioritaskan Kebutuhan
            IF NEW.amount >= u_profile.fixed_cost_threshold THEN
                alloc_needs := u_profile.fixed_cost_threshold;
            ELSE
                alloc_needs := NEW.amount;
            END IF;

            remaining_income := NEW.amount - alloc_needs;

            IF remaining_income > 0 THEN
                alloc_invest := remaining_income * 0.6;
                alloc_saving := remaining_income * 0.4;
            ELSE
                alloc_invest := 0;
                alloc_saving := 0;
            END IF;
        ELSE
            -- Mode Normal
            alloc_needs := NEW.amount * u_model.ratio_needs;
            alloc_invest := NEW.amount * u_model.ratio_invest;
            alloc_saving := NEW.amount * u_model.ratio_savings;
        END IF;

        -- Upsert Wallets (Needs, Invest, Saving)
        -- (Code block untuk INSERT/UPDATE wallet sama seperti versi sebelumnya)
        -- ... [Implementation omitted for brevity, refer to previous docs] ...

    END IF;

    -- Handle EXPENSE Logic
    IF NEW.type = 'EXPENSE' THEN
        current_month := TO_CHAR(NEW.transaction_date, 'YYYY-MM');
        UPDATE wallets
        SET current_balance = current_balance - NEW.amount
        WHERE user_id = NEW.user_id AND category = NEW.category AND month_period = current_month;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 5.2 Trigger Setup
```sql
CREATE TRIGGER trigger_financial_logic
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION handle_new_income();

### 5.3 Scheduled Jobs (Fitur Reminder)
Menggunakan **Supabase Edge Functions** yang dipanggil oleh `pg_cron` setiap jam.

**Logic Flow:**
1.  Cron jalan tiap jam (misal `0 * * * *`).
2.  Cari user yang `daily_reminder_time`-nya matching dengan jam sekarang.
3.  Cek tabel `transactions`: Apakah user ini ada input hari ini?
4.  Jika **TIDAK ADA**, kirim FCM Push Notification ke semua device user tersebut.
5.  Isi pesan: *"Belum ada catatan hari ini. Ada pengeluaran tunai yang lupa dicatat?"*

### 5.4 Utility Functions (Maintenance)
Fungsi untuk user yang ingin "Mulai dari Nol" atau keperluan testing.

```sql
CREATE OR REPLACE FUNCTION reset_my_data()
RETURNS VOID AS $$
BEGIN
    DELETE FROM transactions WHERE user_id = auth.uid();
    DELETE FROM wallets WHERE user_id = auth.uid();
    -- Profile tetap ada, tapi reset threshold jika perlu
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```
```

## 6. Frontend Specifications (Mobile App)

### 6.1 User Flow
- **Onboarding:** User wajib memilih salah satu dari 3 Model (Growth/Ambisius/Regenerasi) yang dijelaskan di Bab 2.
- **Dashboard:** Menampilkan 3 kartu saldo yang ter-sync realtime.
- **Input Income:** Form sederhana (Nominal & Keterangan). User tidak perlu hitung manual.
- **Tools:** Akses ke fitur OCR dan Analisis.

### 6.2 Client-Side Logic (Fitur Cerdas)
- **Decision Maker:** Mengecek saldo Needs dikurangi harga barang. Jika sisa < 10% (Buffer), sarankan "JANGAN BELI".
- **Burn Rate Calculator:** (Total Pengeluaran / Hari Berjalan). Estimasi sisa hari bertahan hidup.
- **Smart Reminders & Habit Building:**
  - **Daily Cash Check-in:** Notifikasi harian (default 20:00, bisa diatur user) jika tidak ada input manual hari itu (khusus untuk menangkap pengeluaran tunai yang sering terlupa).

### 6.3 UI Guidelines (Saran Tema)
Untuk membantu user membedakan mode yang aktif:
- **Growth Mode:** Dominasi warna Hijau Alam (Pertumbuhan/Seimbang).
- **Ambisius Builder:** Dominasi warna Biru Navy/Gelap (Profesional/Serius).
- **Regenerasi Finansial:** Dominasi warna Oranye/Earth Tone (Hangat/Keluarga).

## 7. Non-Functional Requirements (NFR)

### 7.1 Security & Privacy
- **Data Isolation:** Menggunakan RLS (Row Level Security) Supabase adalah mandatori.

### 7.2 Offline Capabilities
- Aplikasi harus menggunakan fitur offline persistence dari Supabase SDK. User tetap bisa input transaksi saat sinyal hilang; data akan di-sync saat online.

### 7.3 Scalability
- Trigger database dirancang efisien. Namun, batasi query history transaksi maksimal 3 bulan terakhir di sisi client untuk menjaga performa aplikasi mobile.

## 8. Testing Strategy

### 8.1 Unit Testing (Backend Logic)
- **Test Case 1 (Normal):** Input Income 1 Juta dengan mode Growth. Hasil: Needs 600rb, Invest 300rb, Saving 100rb.
- **Test Case 2 (Safety Net):** Input Income 500rb dengan Fixed Cost 800rb. Hasil: Needs 500rb (100%), Invest 0, Saving 0.

### 8.2 Integration Testing
- **Flow OCR:** Upload foto -> ML Kit parse teks -> Auto-fill Form -> Submit -> Saldo Berkurang.
- **Flow Realtime:** Buka aplikasi di 2 HP berbeda dengan akun sama. Input di HP A, pastikan HP B update dalam < 2 detik.

## 9. Roadmap

**Fase 1: Pondasi (Minggu 1)**
- Setup Supabase & Project Flutter.
- Auth & Onboarding (Pilih Model).

**Fase 2: Core Transaction (Minggu 2)**
- Dashboard Realtime.
- Input Income & Expense.
- Implementasi Backend Trigger.

**Fase 3: Automation (Minggu 3)**
- Google ML Kit (OCR Struk).
- Upload Storage.

**Fase 4: Intelligence (Minggu 4)**
- Analisis Keuangan & UI Polishing.

## 10. Appendix: Code Snippets

### Menyimpan Transaksi (Flutter)
```dart
Future<void> addIncome(double amount, String note) async {
  await Supabase.instance.client.from('transactions').insert({
    'user_id': Supabase.instance.client.auth.currentUser!.id,
    'amount': amount,
    'type': 'INCOME',
    'description': note,
    'transaction_date': DateTime.now().toIso8601String(),
  });
}
```

### Realtime Listener
```dart
Supabase.instance.client
  .from('wallets')
  .stream(primaryKey: ['id'])
  .eq('user_id', myUserId)
  .listen((data) {
    // Update UI
  });

### 10.2 Recommended Flutter Packages
Berikut adalah daftar library kunci untuk mempercepat fase development:

| Kategori | Package | Kegunaan |
| :--- | :--- | :--- |
| **Core** | `supabase_flutter` | Auth, Build SDK, Realtime. |
| **State Mgt** | `flutter_bloc` / `provider` | Mengelola state aplikasi (rekomendasi: Bloc). |
| **Navigation** | `go_router` | Routing antar halaman (mendukung Deep Link). |
| **UI/Charts** | `fl_chart` | Membuat grafik keuangan di Dashboard. |
| **Format** | `intl` | Format mata uang (Rp) dan tanggal. |
| **OCR** | `google_mlkit_text_recognition` | Membaca struk belanja (on-device). |
| **Media** | `image_picker` | Ambil foto struk dari kamera/galeri. |

```