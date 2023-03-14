WITH m_price AS
(select hour, price AS p
	FROM ethereum.core.fact_hourly_token_prices
	WHERE hour > date_trunc('hour', '2022-10-15'::date)
	AND symbol = 'MATIC' 
), org_costs AS
(select contract_address AS "Organization Address", logs.tx_hash, CASE WHEN logs.origin_function_signature IN ('0x2d68a3e0', '0xefa43559') THEN 'Mint Badge' WHEN logs.origin_function_signature = '0x7b366213' THEN 'Create Org' WHEN logs.origin_function_signature = '0x990e4c51' THEN 'Revoke Badge' WHEN logs.origin_function_signature = '0x78677a8d' THEN 'Create Badge' WHEN logs.origin_function_signature = '0x45863a19' THEN 'Adjust Managers' else logs.origin_function_signature end AS "Action", MAX(tx_fee*m_price.p) AS gas
	FROM polygon.core.fact_event_logs logs
	LEFT JOIN polygon.core.fact_transactions transactions
	ON logs.tx_hash = transactions.tx_hash
	LEFT JOIN m_price
	ON date_trunc('hour', logs.block_timestamp) = m_price.hour
	WHERE logs.block_timestamp::date > '2022-10-16'::date
	AND transactions.block_timestamp::date > '2022-10-16'::date
	AND contract_Address IN (select distinct concat('0x', right(topics[1]::string, 40)) AS org_addr
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp::date > '2022-10-16'::date
	AND contract_Address = lower('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
	AND origin_function_signature = '0x7b366213')
	GROUP BY  1
	         ,2
	         ,3
	ORDER BY 4 desc --
	UNION ALL
)
SELECT  SUM(gas) AS "Total Costs ($)"
FROM org_costs
WHERE "Action" != '0xf242432a'