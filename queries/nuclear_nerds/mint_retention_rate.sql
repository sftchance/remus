WITH eth_collection AS
(
	SELECT  lower('0x0f78c6eee3c89ff37fd9ef96bd685830993636f2') AS nft_address
	       ,'Nerds'                                             AS nft_name
	UNION
	SELECT  LOWER('0x026234c69cdfa4dc0c7f01806df6b9d63e238b80')
	       ,'Marauders'
	UNION
	-- nuclear nerd marauders
	SELECT  LOWER('0x120305aace78052a967182b277f6392670ee9873')
	       ,'Box o Bad Guys'
	UNION
	-- nuclear nerd boxes
	SELECT  LOWER('0x072d62047b03b9ee68596557aee848188422150b')
	       ,'Serums' -- nuclear nerd serums
), nerds_minters AS
(
	SELECT  DISTINCT nft_to_address
	FROM ethereum.core.ez_nft_mints
	WHERE nft_address = '0x0f78c6eee3c89ff37fd9ef96bd685830993636f2' 
), marauders_minters AS
(
	SELECT  DISTINCT nft_to_address
	FROM ethereum.core.ez_nft_mints
	WHERE nft_address = '0x026234c69cdfa4dc0c7f01806df6b9d63e238b80' 
), box_o_bad_guys_minters AS
(
	SELECT  DISTINCT nft_to_address
	FROM ethereum.core.ez_nft_mints
	WHERE nft_address = '0x120305aace78052a967182b277f6392670ee9873' 
), serums_minters AS
(
	SELECT  DISTINCT nft_to_address
	FROM ethereum.core.ez_nft_mints
	WHERE nft_address = '0x072d62047b03b9ee68596557aee848188422150b' 
)
SELECT  100 * (COUNT(DISTINCT marauders_minters.nft_to_address) / COUNT(DISTINCT nerds_minters.nft_to_address))      AS marauders_retention_rate
       ,100 * (COUNT(DISTINCT box_o_bad_guys_minters.nft_to_address) / COUNT(DISTINCT nerds_minters.nft_to_address)) AS box_o_bad_guys_retention_rate
       ,100 * (COUNT(DISTINCT serums_minters.nft_to_address) / COUNT(DISTINCT nerds_minters.nft_to_address))         AS serums_retention_rate
FROM eth_collection
JOIN nerds_minters
ON TRUE
LEFT JOIN marauders_minters
ON nerds_minters.nft_to_address = marauders_minters.nft_to_address
LEFT JOIN box_o_bad_guys_minters
ON nerds_minters.nft_to_address = box_o_bad_guys_minters.nft_to_address
LEFT JOIN serums_minters
ON nerds_minters.nft_to_address = serums_minters.nft_to_address
GROUP BY  eth_collection.nft_name
LIMIT 1