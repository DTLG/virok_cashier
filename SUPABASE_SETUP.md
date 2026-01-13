# Налаштування Supabase для Cash Register

## Крок 1: Створення таблиць

Виконайте наступні SQL команди в Supabase Dashboard -> SQL Editor:

### Таблиця nomenklatura
```sql
CREATE TABLE IF NOT EXISTS nomenklatura (
    guid TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    unit TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Створюємо тригер для автоматичного оновлення updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_nomenklatura_updated_at BEFORE UPDATE
    ON nomenklatura FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Таблиця prices
```sql
CREATE TABLE IF NOT EXISTS prices (
    id SERIAL PRIMARY KEY,
    nom_guid TEXT NOT NULL REFERENCES nomenklatura(guid) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'UAH',
    valid_from TIMESTAMPTZ DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_prices_updated_at BEFORE UPDATE
    ON prices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Індекс для швидкого пошуку по nom_guid
CREATE INDEX IF NOT EXISTS idx_prices_nom_guid ON prices(nom_guid);
```

### Таблиця barcodes
```sql
CREATE TABLE IF NOT EXISTS barcodes (
    id SERIAL PRIMARY KEY,
    nom_guid TEXT NOT NULL REFERENCES nomenklatura(guid) ON DELETE CASCADE,
    barcode TEXT NOT NULL UNIQUE,
    barcode_type TEXT DEFAULT 'EAN13',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_barcodes_updated_at BEFORE UPDATE
    ON barcodes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Індекси для швидкого пошуку
CREATE INDEX IF NOT EXISTS idx_barcodes_nom_guid ON barcodes(nom_guid);
CREATE INDEX IF NOT EXISTS idx_barcodes_barcode ON barcodes(barcode);
```

## Крок 2: Створення RPC функції

Виконайте SQL з файлу `supabase_rpc_function.sql`:

```sql
CREATE OR REPLACE FUNCTION get_nomenclatura_with_prices_and_barcodes()
RETURNS TABLE (
  guid text,
  name text,
  description text,
  unit text,
  created_at timestamptz,
  updated_at timestamptz,
  prices json,
  barcodes json
)
LANGUAGE sql
AS $$
  SELECT 
    n.guid,
    n.name,
    n.description,
    n.unit,
    n.created_at,
    n.updated_at,
    COALESCE(
      json_agg(
        json_build_object(
          'id', p.id,
          'nom_guid', p.nom_guid,
          'price', p.price,
          'currency', p.currency,
          'valid_from', p.valid_from,
          'valid_to', p.valid_to,
          'created_at', p.created_at,
          'updated_at', p.updated_at
        )
      ) FILTER (WHERE p.nom_guid IS NOT NULL),
      '[]'::json
    ) as prices,
    COALESCE(
      json_agg(
        json_build_object(
          'id', b.id,
          'nom_guid', b.nom_guid,
          'barcode', b.barcode,
          'barcode_type', b.barcode_type,
          'created_at', b.created_at,
          'updated_at', b.updated_at
        )
      ) FILTER (WHERE b.nom_guid IS NOT NULL),
      '[]'::json
    ) as barcodes
  FROM nomenklatura n
  LEFT JOIN prices p ON n.guid = p.nom_guid
  LEFT JOIN barcodes b ON n.guid = b.nom_guid
  GROUP BY n.guid, n.name, n.description, n.unit, n.created_at, n.updated_at
  ORDER BY n.name;
$$;

GRANT EXECUTE ON FUNCTION get_nomenclatura_with_prices_and_barcodes() TO anon, authenticated;
```

## Крок 3: Додавання тестових даних

```sql
-- Додаємо тестову номенклатуру
INSERT INTO nomenklatura (guid, name, description, unit) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'Хліб білий', 'Хліб білий формовий', 'шт'),
('550e8400-e29b-41d4-a716-446655440002', 'Молоко', 'Молоко коров\'яче 2.5%', 'л'),
('550e8400-e29b-41d4-a716-446655440003', 'Яйця', 'Яйця курячі С1', 'десяток');

-- Додаємо ціни
INSERT INTO prices (nom_guid, price, currency) VALUES
('550e8400-e29b-41d4-a716-446655440001', 25.50, 'UAH'),
('550e8400-e29b-41d4-a716-446655440002', 35.00, 'UAH'),
('550e8400-e29b-41d4-a716-446655440003', 65.00, 'UAH');

-- Додаємо штрих-коди
INSERT INTO barcodes (nom_guid, barcode, barcode_type) VALUES
('550e8400-e29b-41d4-a716-446655440001', '4820001234567', 'EAN13'),
('550e8400-e29b-41d4-a716-446655440002', '4820001234574', 'EAN13'),
('550e8400-e29b-41d4-a716-446655440003', '4820001234581', 'EAN13');
```

## Крок 4: Налаштування RLS (Row Level Security)

```sql
-- Увімкнемо RLS
ALTER TABLE nomenklatura ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcodes ENABLE ROW LEVEL SECURITY;

-- Дозволимо читання всім
CREATE POLICY "Allow read access for all users" ON nomenklatura FOR SELECT USING (true);
CREATE POLICY "Allow read access for all users" ON prices FOR SELECT USING (true);
CREATE POLICY "Allow read access for all users" ON barcodes FOR SELECT USING (true);

-- Дозволимо запис аутентифікованим користувачам
CREATE POLICY "Allow insert for authenticated users" ON nomenklatura FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow update for authenticated users" ON nomenklatura FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow delete for authenticated users" ON nomenklatura FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow insert for authenticated users" ON prices FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow update for authenticated users" ON prices FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow delete for authenticated users" ON prices FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow insert for authenticated users" ON barcodes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow update for authenticated users" ON barcodes FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow delete for authenticated users" ON barcodes FOR DELETE TO authenticated USING (true);
```

## Перевірка

Після виконання всіх кроків, ви можете перевірити роботу функції:

```sql
SELECT * FROM get_nomenclatura_with_prices_and_barcodes();
```

Ця функція поверне номенклатуру з цінами та штрих-кодами у форматі JSON, готовому для використання в Flutter додатку.
