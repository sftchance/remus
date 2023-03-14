SELECT  block_timestamp
       ,contract_address                AS "Organization Address"
       ,origin_from_address             AS "Badge Creator"
       ,MAX(event_inputs:"_id"::string) AS "Token ID"
FROM polygon.core.fact_event_logs
WHERE block_timestamp::date > '2022-10-16'::date
AND contract_Address IN (select distinct concat('0x', right(topics[1]::string, 40)) AS org_addr
FROM polygon.core.fact_event_logs
WHERE block_timestamp::date > '2022-10-16'::date
AND contract_Address = lower('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
AND origin_function_signature = '0x7b366213') AND origin_function_signature = '0x78677a8d'
GROUP BY  1
         ,2
         ,3
ORDER BY 1 desc