-- ================================================================
-- Налаштування Supabase Realtime для проекту Cash Register
-- ================================================================

-- Крок 1: Увімкнути Row Level Security для всіх таблиць
-- ========================================================

ALTER TABLE nomenklatura ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcodes ENABLE ROW LEVEL SECURITY;

-- Крок 2: Створити політики для доступу до даних
-- ================================================

-- Політики для таблиці nomenklatura
CREATE POLICY "Enable read access for all users" ON nomenklatura 
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for all users" ON nomenklatura 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for all users" ON nomenklatura 
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for all users" ON nomenklatura 
    FOR DELETE USING (true);

-- Політики для таблиці prices
CREATE POLICY "Enable read access for all users" ON prices 
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for all users" ON prices 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for all users" ON prices 
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for all users" ON prices 
    FOR DELETE USING (true);

-- Політики для таблиці barcodes
CREATE POLICY "Enable read access for all users" ON barcodes 
    FOR SELECT USING (true);

CREATE POLICY "Enable insert for all users" ON barcodes 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update for all users" ON barcodes 
    FOR UPDATE USING (true);

CREATE POLICY "Enable delete for all users" ON barcodes 
    FOR DELETE USING (true);

-- Крок 3: Увімкнути Realtime для таблиць
-- ======================================

-- Додати таблиці до realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE nomenklatura;
ALTER PUBLICATION supabase_realtime ADD TABLE prices;
ALTER PUBLICATION supabase_realtime ADD TABLE barcodes;

-- Крок 4: Перевірка налаштувань (опціонально)
-- =============================================

-- Перевірити які таблиці додані до realtime
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';

-- Перевірити політики RLS
SELECT schemaname, tablename, policyname, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('nomenklatura', 'prices', 'barcodes')
ORDER BY tablename, policyname;

-- Крок 5: Тестові дані для перевірки realtime (опціонально)
-- ==========================================================

-- Вставити тестовий запис для перевірки
-- УВАГА: Запускайте тільки якщо хочете протестувати!

/*
INSERT INTO nomenklatura (
    guid, name, article, unit_name, unit_guid, is_folder, description
) VALUES (
    'test-' || gen_random_uuid()::text,
    'Тестовий товар для Realtime',
    'TEST-001',
    'шт',
    '00000000-0000-0000-0000-000000000001',
    false,
    'Цей товар створений для тестування realtime функціональності'
);

-- Додати тестову ціну
INSERT INTO prices (nom_guid, price, created_at) 
SELECT guid, 100.50, NOW() 
FROM nomenklatura 
WHERE name = 'Тестовий товар для Realtime' 
LIMIT 1;

-- Додати тестовий штрих-код
INSERT INTO barcodes (nom_guid, barcode) 
SELECT guid, '1234567890123' 
FROM nomenklatura 
WHERE name = 'Тестовий товар для Realtime' 
LIMIT 1;
*/

-- Крок 6: Функції для тестування (опціонально)
-- =============================================

-- Функція для створення тестових змін
CREATE OR REPLACE FUNCTION test_realtime_changes()
RETURNS void AS $$
DECLARE
    test_guid text;
BEGIN
    -- Створити тестовий запис
    test_guid := 'realtime-test-' || extract(epoch from now())::text;
    
    INSERT INTO nomenklatura (
        guid, name, article, unit_name, unit_guid, is_folder, description
    ) VALUES (
        test_guid,
        'Realtime Test Item ' || extract(epoch from now())::text,
        'RT-' || extract(epoch from now())::text,
        'шт',
        '00000000-0000-0000-0000-000000000001',
        false,
        'Автоматично створений для тестування realtime'
    );
    
    -- Додати ціну
    INSERT INTO prices (nom_guid, price, created_at) 
    VALUES (test_guid, random() * 1000, NOW());
    
    -- Додати штрих-код  
    INSERT INTO barcodes (nom_guid, barcode) 
    VALUES (test_guid, (random() * 9999999999999)::bigint::text);
    
    -- Оновити через секунду
    PERFORM pg_sleep(1);
    
    UPDATE nomenklatura 
    SET description = 'ОНОВЛЕНО: ' || description 
    WHERE guid = test_guid;
    
    -- Видалити через ще секунду
    PERFORM pg_sleep(1);
    
    DELETE FROM nomenklatura WHERE guid = test_guid;
    
    RAISE NOTICE 'Realtime test completed for GUID: %', test_guid;
END;
$$ LANGUAGE plpgsql;

-- Крок 7: Корисні запити для моніторингу
-- ======================================

-- Перевірити підключені realtime клієнти (потребує доступу до системних таблиць)
-- SELECT * FROM pg_stat_activity WHERE application_name LIKE '%realtime%';

-- Перевірити налаштування publication
-- SELECT * FROM pg_publication WHERE pubname = 'supabase_realtime';

-- ================================================================
-- ІНСТРУКЦІЇ ПО ВИКОРИСТАННЮ:
-- ================================================================

/*
1. Виконайте цей скрипт у Supabase SQL Editor
2. Переконайтеся що всі команди виконались успішно
3. У Flutter додатку запустіть сторінку "Realtime Test"
4. Натисніть "Почати підписку"
5. В іншій вкладці виконайте: SELECT test_realtime_changes();
6. Перевірте що події з'явились у Flutter додатку

УВАГА: 
- Політики RLS налаштовані для повного доступу (true)
- В продакшені змініть політики згідно вашої логіки безпеки
- Тестова функція створює тимчасові дані
*/
