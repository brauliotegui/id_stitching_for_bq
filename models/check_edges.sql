--Determines if there are still edges to match.

SELECT
    COUNT(*) AS rows_to_update,
    CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS consolidation_needed
FROM
    {{ ref('edges') }},
    (
        SELECT DISTINCT
            a.edge_a AS edge,
            CASE WHEN a.rudder_id < b.rudder_id THEN a.rudder_id ELSE b.rudder_id END AS first_rudder_id
        FROM {{ ref('edges') }} AS a
        INNER JOIN {{ ref('edges') }} AS b
            ON LOWER(a.edge_a) = LOWER(b.edge_b)
        WHERE a.rudder_id != b.rudder_id
    ) AS ea
WHERE
    (
        LOWER(edges.edge_a) = LOWER(ea.edge)
        OR LOWER(edges.edge_b) = LOWER(ea.edge)
    )
AND edges.rudder_id != ea.first_rudder_id

/*
    Esse script é usado para verificar se há arestas (edges) ainda para serem correspondidas. 
    Ele retorna a contagem de linhas que precisam ser atualizadas e se é necessário continuar a consolidação.

    Ele faz isso através de uma subquery que seleciona as arestas distintas e seus primeiros identificadores (rudder_id), 
    combinando as arestas do lado A e B. Em seguida, a query principal usa essa subquery para contar as arestas 
    que ainda precisam ser correspondidas e atualizadas.

    A query principal conta o número de linhas que precisam ser atualizadas e retorna 1 se a contagem for maior que 0, 
    indicando que a consolidação ainda é necessária. Caso contrário, ele retorna 0, indicando que a consolidação foi concluída.
*/
