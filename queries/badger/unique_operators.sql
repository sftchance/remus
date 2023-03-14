SELECT  COUNT(distinct origin_from_address)         AS "Unique Operators"
       ,COUNT(distinct right(topics[1]::string,40)) AS "Organizations"
FROM polygon.core.fact_event_logs
WHERE block_timestamp::date > '2022-10-16'::date
AND contract_Address = lower('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
AND origin_function_signature = '0x7b366213'