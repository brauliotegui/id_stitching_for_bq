{{ config(materialized='table') }}

SELECT
    rudder_id,
    edge as node,
    STRING_AGG(DISTINCT edge_label) AS labels,
    MAX(edge_timestamp) AS latest_timestamp
    
FROM 
    (
        SELECT
            rudder_id,
            edge_a AS edge,
            edge_a_label AS edge_label,
            edge_timestamp
        FROM {{ ref('edges') }}

        UNION DISTINCT

        SELECT
            rudder_id,
            edge_b AS edge,
            edge_b_label AS edge_label,
            edge_timestamp
        FROM {{ ref('edges') }}
    ) AS c

GROUP BY
    rudder_id,
    edge
ORDER BY rudder_id

/*

    Esse código é usado para criar uma tabela chamada "id_graph" que agrupa as arestas (edges) e seus rótulos (labels) 
    por identificadores (rudder_id) e arestas, e mantém a data e hora mais recente das arestas (edge_timestamp).

    Ele faz isso unindo as arestas do lado A e B e, em seguida, agrupando-as pelo identificador (rudder_id) e arestas. 
    Ele também usa a função listagg para concatenar os rótulos (edge_label) das arestas em uma única coluna de texto separada por vírgulas.

    A tabela "id_graph" armazena essas informações agrupadas para facilitar a visualização e análise das relações 
    entre os identificadores e as arestas, e as suas labels.


*/
