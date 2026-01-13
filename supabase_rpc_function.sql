-- RPC функція для Supabase
-- Цю функцію потрібно створити в Supabase Dashboard -> SQL Editor

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

-- Надаємо права на виконання функції
GRANT EXECUTE ON FUNCTION get_nomenclatura_with_prices_and_barcodes() TO anon, authenticated;
