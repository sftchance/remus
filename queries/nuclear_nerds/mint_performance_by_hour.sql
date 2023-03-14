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
), mint AS
(
	SELECT  mnt.tx_hash
	       ,block_timestamp AS mint_time
	       ,nft_name
	FROM ethereum.core.ez_nft_mints mnt
	JOIN eth_collection eth USING
	(nft_address
	)
), first_mint AS
(
	SELECT  nft_name
	       ,MIN(mint_time) AS first_mint_time
	FROM mint
	GROUP BY  nft_name
), mint_with_hours AS
(
	SELECT  nft_name
	       ,DATEDIFF(hour,first_mint_time,mint_time)                                         AS hours_since_first_mint
	       ,COUNT(tx_hash)                                                                   AS count_mint
	       ,SUM(COUNT(tx_hash)) OVER (PARTITION BY nft_name ORDER BY hours_since_first_mint) AS cumulative_count_mint
	FROM mint
	JOIN first_mint USING
	(nft_name
	)
	GROUP BY  nft_name
	         ,hours_since_first_mint
), hours AS
(
	SELECT  DISTINCT hours_since_first_mint
	FROM mint_with_hours
)
SELECT  hours.hours_since_first_mint
       ,nerds.cumulative_count_mint          AS nerds
       ,marauders.cumulative_count_mint      AS marauders
       ,box_o_bad_guys.cumulative_count_mint AS box_o_bad_guys
       ,serums.cumulative_count_mint         AS serums
FROM hours
LEFT JOIN mint_with_hours AS nerds
ON nerds.hours_since_first_mint = hours.hours_since_first_mint AND nerds.nft_name = 'Nerds'
LEFT JOIN mint_with_hours AS marauders
ON marauders.hours_since_first_mint = hours.hours_since_first_mint AND marauders.nft_name = 'Marauders'
LEFT JOIN mint_with_hours AS box_o_bad_guys
ON box_o_bad_guys.hours_since_first_mint = hours.hours_since_first_mint AND box_o_bad_guys.nft_name = 'Box o Bad Guys'
LEFT JOIN mint_with_hours AS serums
ON serums.hours_since_first_mint = hours.hours_since_first_mint AND serums.nft_name = 'Serums'
ORDER BY hours.hours_since_first_mint ASC;