--Combines the results of those select statement to create a table containing edges (IDs) the first time it is run, and matches edges on subsequent runs.

{{ config(materialized='incremental', unique_key='original_rudder_id') }}

{% if not is_incremental() %}

    {% set sql_statements = dbt_utils.get_column_values(table=ref('queries'), column='sql_to_run') %}

    SELECT
        ROW_NUMBER() OVER (ORDER BY 1 DESC) AS  rudder_id,
        ROW_NUMBER() OVER (ORDER BY 1 DESC) AS  original_rudder_id,
        edge_a,
        edge_a_label,
        edge_b,
        edge_b_label,
        current_timestamp() AS edge_timestamp
    FROM (
        {{ ' UNION DISTINCT '.join(sql_statements) }}
    ) AS  s
    WHERE
        NOT LOWER(edge_a) in {{ var('ids-to-exclude') }}
        AND NOT LOWER(edge_b) in {{ var('ids-to-exclude') }}

{% else %}

    WITH
    cte_min_edge_1 AS  (
        SELECT
            edge,
            MIN(rudder_id) AS  first_row_id
        FROM (
            SELECT
                rudder_id,
                LOWER(edge_a) AS  edge
            FROM {{ this  }}
            UNION DISTINCT
            SELECT
                rudder_id,
                LOWER(edge_b) AS  edge
            FROM {{ this  }}
        ) AS c
        GROUP BY edge
    ),

    cte_min_edge_2 AS  (
        SELECT
            edge,
            MIN(rudder_id) AS  first_row_id
        FROM (
            SELECT
                LEAST(a.first_row_id, b.first_row_id) AS  rudder_id,
                LEAST(o.edge_a) AS  edge
            FROM {{ this  }} AS  o
            LEFT OUTER JOIN cte_min_edge_1 AS  a
                ON LOWER(o.edge_a) = a.edge
            LEFT OUTER JOIN cte_min_edge_1 AS  b
                ON LOWER(o.edge_b) = b.edge
            UNION DISTINCT
            SELECT
                LEAST(a.first_row_id, b.first_row_id) AS  rudder_id,
                LOWER(o.edge_b) AS  edge
            FROM {{ this  }} AS  o
            LEFT OUTER JOIN cte_min_edge_1 AS  a
                ON LOWER(o.edge_a) = a.edge
            LEFT OUTER JOIN cte_min_edge_1 AS  b
                ON LOWER(o.edge_b) = b.edge
        ) AS  g
        GROUP BY edge
    ),

    cte_min_edge_3 AS  (
        SELECT
            edge,
            MIN(rudder_id) AS  first_row_id
        FROM (
            SELECT
                LEAST(a.first_row_id, b.first_row_id) AS  rudder_id,
                LOWER(o.edge_a) AS  edge
            FROM {{ this  }} AS  o
            LEFT OUTER JOIN cte_min_edge_2 AS  a
                ON LOWER(o.edge_a) = a.edge
            LEFT OUTER JOIN cte_min_edge_2 AS  b
                ON LOWER(o.edge_b) = b.edge
            UNION DISTINCT
            SELECT
                LEAST(a.first_row_id, b.first_row_id) AS  rudder_id,
                LOWER(o.edge_b) AS  edge
            FROM {{ this  }} AS  o
            LEFT OUTER JOIN cte_min_edge_2 AS  a
                ON LOWER(o.edge_a) = a.edge
            LEFT OUTER JOIN cte_min_edge_2 AS  b
                ON LOWER(o.edge_b) = b.edge

        ) AS  h
        GROUP BY edge
    ),

    cte_new_id AS  (
        SELECT
            o.original_rudder_id,
            LEAST(a.first_row_id, b.first_row_id) AS  new_rudder_id
        FROM {{ this  }} AS  o
        LEFT OUTER JOIN cte_min_edge_3 AS  a
            ON LOWER(o.edge_a) = a.edge
        LEFT OUTER JOIN cte_min_edge_3 AS  b
            ON LOWER(o.edge_b) = b.edge
    )

    SELECT
        cte_new_id.new_rudder_id AS  rudder_id,
        e.original_rudder_id,
        e.edge_a,
        e.edge_a_label,
        e.edge_b,
        e.edge_b_label,
        current_timestamp() AS edge_timestamp
    FROM {{ this  }} AS  e
    INNER JOIN cte_new_id
        ON e.original_rudder_id = cte_new_id.original_rudder_id
    WHERE e.rudder_id != cte_new_id.new_rudder_id

{% endif %}

/*
    A tabela "edges.sql" tem as seguintes colunas:

    rudder_id: número da linha gerado pela tabela edges
    original_rudder_id: número da linha gerado pela tabela queries
    edge_a: valor do identificador único encontrado na tabela de origem
    edge_a_label: label do identificador único encontrado na tabela de origem
    edge_b: valor do identificador único mapeado
    edge_b_label: label do identificador único mapeado
    edge_timestamp: data e hora de quando a aresta foi criada

    Na primeira execução, ele seleciona os valores distintos das colunas "edge_a" e "edge_b" das tabelas selecionadas, 
    renomeando-os como "edge_a", "edge_a_label", "edge_b" e "edge_b_label" respectivamente, 
    e adiciona as colunas "rudder_id", "original_rudder_id" e "edge_timestamp"

    Na execução incremental, ele irá comparar as novas arestas com as arestas existentes 
    e irá manter a aresta com o menor "rudder_id" como a aresta válida.
*/
