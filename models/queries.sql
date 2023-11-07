WITH columns AS (
    SELECT
        column_name AS cn,
        table_catalog || '.' || table_schema || '.' || table_name AS tn
    FROM `grupo-coutinho.rudderstack.INFORMATION_SCHEMA.COLUMNS`
    WHERE
        LOWER(column_name) IN {{ var('id-columns') }}
        AND NOT LOWER(table_name) LIKE 'snapshot_%'
        AND NOT LOWER(table_name) LIKE 'sync_data_%'
        AND NOT LOWER(table_name) LIKE 'failed_records_%'
)

SELECT
    'SELECT DISTINCT '
    || a.cn
    || ' AS  edge_a, '
    || a.cn
    || ' AS  edge_a_label, '
    || b.cn
    || ' AS  edge_b, '
    || b.cn
    || ' AS  edge_b_label FROM '
    || a.tn
    || ' WHERE ('
    || a.cn
    || ') IS NOT NULL AND ('
    || b.cn
    || ') IS NOT NULL ' AS sql_to_run
FROM columns AS a
INNER JOIN columns AS b ON a.tn = b.tn AND a.cn > b.cn
