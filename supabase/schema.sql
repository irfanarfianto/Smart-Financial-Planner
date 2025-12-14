-- ==========================================
-- 1. TABLE: FINANCIAL MODELS (Master Data)
-- ==========================================
CREATE TABLE IF NOT EXISTS financial_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    ratio_needs DECIMAL(5,2) NOT NULL, -- e.g., 0.50
    ratio_invest DECIMAL(5,2) NOT NULL, -- e.g., 0.30
    ratio_savings DECIMAL(5,2) NOT NULL, -- e.g., 0.20
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS: Public Read Only
ALTER TABLE financial_models ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public models are viewable by everyone" ON financial_models FOR SELECT USING (true);


-- ==========================================
-- 2. TABLE: PROFILES (User Data Extension)
-- ==========================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(255),
    full_name VARCHAR(255),
    avatar_url TEXT,
    active_model_id UUID REFERENCES financial_models(id), -- Model keuangan yang dipilih
    daily_reminder_time TIME DEFAULT '20:00:00', -- Jam notifikasi (Local Time)
    fixed_cost_threshold DECIMAL(15,2) DEFAULT 0, -- Ambang batas biaya hidup tetap (Needs protection)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS: Users can view/edit their own profile
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);


-- ==========================================
-- 3. TABLE: WALLETS (Dompet)
-- ==========================================
-- Logic: Setiap bulan baru, sistem bisa membuat entry dompet baru atau akumulasi.
-- Skema ini menggunakan pendekatan "Monthly Bucket" agar history tercatat rapi.
-- Kategori wajib: 'NEEDS', 'INVEST', 'SAVING'
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL CHECK (category IN ('NEEDS', 'INVEST', 'SAVING')),
    current_balance DECIMAL(15,2) DEFAULT 0,
    month_period VARCHAR(7) NOT NULL, -- Format: 'YYYY-MM' (e.g., '2024-01')
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, category, month_period) -- Satu user, satu kategori per bulan
);

-- RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own wallets" ON wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wallets" ON wallets FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wallets" ON wallets FOR UPDATE USING (auth.uid() = user_id);


-- ==========================================
-- 4. TABLE: TRANSACTIONS (Pencatatan)
-- ==========================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(15,2) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('INCOME', 'EXPENSE', 'TRANSFER')), 
    category VARCHAR(50), -- Jika INCOME: null/source. Jika EXPENSE: 'NEEDS'/'INVEST'/'SAVING'
    description TEXT,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    receipt_url TEXT, -- Bukti foto
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ==========================================
-- 5. TABLE: USER DEVICES (FCM Tokens)
-- ==========================================
-- Stores FCM tokens for push notifications
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_name TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

-- RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own devices" ON user_devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own devices" ON user_devices FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own devices" ON user_devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own devices" ON user_devices FOR DELETE USING (auth.uid() = user_id);


-- ==========================================
-- 6. TABLE: NOTIFICATIONS (Inbox)
-- ==========================================
-- Stores history of notifications sent to users
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'SYSTEM', -- 'REMINDER', 'SYSTEM', 'PROMO'
    is_read BOOLEAN DEFAULT FALSE,
    data JSONB DEFAULT '{}', -- Extra data for deep linking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id); -- For marking as read
-- Insert policy: Usually only system/backend inserts notifications, but we can allow auth users if needed
-- For now, relying on Service Role for insertion via Edge Functions.


-- ==========================================
-- 7. FUNCTION & TRIGGER: AUTO ALLOCATION
-- ==========================================

-- Function: Handle Income Allocation & Expense Deduction (WITH SAFETY NET PROTOCOL)
CREATE OR REPLACE FUNCTION handle_new_transaction()
RETURNS TRIGGER AS $$
DECLARE
    u_model RECORD;
    u_profile RECORD;
    alloc_needs DECIMAL := 0;
    alloc_invest DECIMAL := 0;
    alloc_saving DECIMAL := 0;
    current_month VARCHAR;
    is_profile_valid BOOLEAN := FALSE;
    remaining_income DECIMAL := 0;
BEGIN
    -- Ambil Bulan Transaksi (Format YYYY-MM)
    current_month := TO_CHAR(NEW.transaction_date, 'YYYY-MM');

    -- LOGIKA PEMASUKAN (INCOME)
    IF NEW.type = 'INCOME' THEN
        -- Cek Profil User
        SELECT * INTO u_profile FROM profiles WHERE id = NEW.user_id;

        -- Cek apakah user punya Financial Model
        IF u_profile.active_model_id IS NOT NULL THEN
             SELECT * INTO u_model FROM financial_models WHERE id = u_profile.active_model_id;
             IF FOUND THEN
                is_profile_valid := TRUE;
             END IF;
        END IF;

        IF is_profile_valid THEN
            -- HITUNG ALOKASI NORMAL BERDASARKAN MODEL
            alloc_needs := NEW.amount * u_model.ratio_needs;
            alloc_invest := NEW.amount * u_model.ratio_invest;
            alloc_saving := NEW.amount * u_model.ratio_savings;

            -- ========================================
            -- SAFETY NET PROTOCOL
            -- ========================================
            -- Jika alokasi needs < fixed_cost_threshold, prioritaskan needs dulu
            IF u_profile.fixed_cost_threshold > 0 AND alloc_needs < u_profile.fixed_cost_threshold THEN
                -- MODE DARURAT: Prioritaskan Kebutuhan Dasar
                
                -- Jika income cukup untuk cover fixed cost
                IF NEW.amount >= u_profile.fixed_cost_threshold THEN
                    alloc_needs := u_profile.fixed_cost_threshold;
                ELSE
                    -- Income tidak cukup, alokasikan semua ke needs
                    alloc_needs := NEW.amount;
                END IF;

                -- Hitung sisa income setelah needs terpenuhi
                remaining_income := NEW.amount - alloc_needs;

                -- Bagi sisa income ke invest & saving (60/40)
                IF remaining_income > 0 THEN
                    alloc_invest := remaining_income * 0.6;
                    alloc_saving := remaining_income * 0.4;
                ELSE
                    alloc_invest := 0;
                    alloc_saving := 0;
                END IF;
            END IF;
            -- ========================================
            -- END SAFETY NET PROTOCOL
            -- ========================================

        ELSE
            -- FALLBACK DEFAULT (50/30/20) JIKA MODEL ERROR/KOSONG
            alloc_needs := NEW.amount * 0.50;
            alloc_invest := NEW.amount * 0.30;
            alloc_saving := NEW.amount * 0.20;
        END IF;

        -- === SIMPAN KE DOMPET (UPSERT) ===
        
        -- 1. NEEDS
        INSERT INTO wallets (user_id, category, current_balance, month_period)
        VALUES (NEW.user_id, 'NEEDS', alloc_needs, current_month)
        ON CONFLICT (user_id, category, month_period)
        DO UPDATE SET current_balance = wallets.current_balance + EXCLUDED.current_balance, updated_at = NOW();

        -- 2. INVEST
        INSERT INTO wallets (user_id, category, current_balance, month_period)
        VALUES (NEW.user_id, 'INVEST', alloc_invest, current_month)
        ON CONFLICT (user_id, category, month_period)
        DO UPDATE SET current_balance = wallets.current_balance + EXCLUDED.current_balance, updated_at = NOW();

        -- 3. SAVING
        INSERT INTO wallets (user_id, category, current_balance, month_period)
        VALUES (NEW.user_id, 'SAVING', alloc_saving, current_month)
        ON CONFLICT (user_id, category, month_period)
        DO UPDATE SET current_balance = wallets.current_balance + EXCLUDED.current_balance, updated_at = NOW();

    -- LOGIKA PENGELUARAN (EXPENSE)
    ELSIF NEW.type = 'EXPENSE' THEN
        UPDATE wallets
        SET current_balance = current_balance - NEW.amount, updated_at = NOW()
        WHERE user_id = NEW.user_id 
          AND category = NEW.category 
          AND month_period = current_month;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
DROP TRIGGER IF EXISTS trigger_financial_logic ON transactions;
CREATE TRIGGER trigger_financial_logic
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION handle_new_transaction();

-- ==========================================
-- 8. SEED DATA (Financial Models)
-- ==========================================
-- Run this if financial_models table is empty
INSERT INTO financial_models (name, description, ratio_needs, ratio_invest, ratio_savings)
SELECT 'Growth Mode', 'Agresif berinvestasi untuk masa depan.', 0.50, 0.30, 0.20
WHERE NOT EXISTS (SELECT 1 FROM financial_models WHERE name = 'Growth Mode');

INSERT INTO financial_models (name, description, ratio_needs, ratio_invest, ratio_savings)
SELECT 'Stability Mode', 'Fokus pada keamanan dan dana darurat.', 0.50, 0.20, 0.30
WHERE NOT EXISTS (SELECT 1 FROM financial_models WHERE name = 'Stability Mode');

INSERT INTO financial_models (name, description, ratio_needs, ratio_invest, ratio_savings)
SELECT 'Balanced Mode', 'Seimbang antara kebutuhan dan tabungan.', 0.60, 0.20, 0.20
WHERE NOT EXISTS (SELECT 1 FROM financial_models WHERE name = 'Balanced Mode');
