WITH orgs AS
(
	SELECT  CONCAT('0x',RIGHT(topics [1] :: STRING,40)) AS created_contracts
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
	AND contract_Address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
	AND origin_function_signature = '0x7b366213' 
)
SELECT  *
FROM orgs