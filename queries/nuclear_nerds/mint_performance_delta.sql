WITH eth_collection AS
(
	SELECT  LOWER('0x0f78c6eee3c89ff37fd9ef96bd685830993636f2') AS nft_address
	       ,'Nerds'                                             AS nft_name
	UNION
	SELECT  LOWER('0x026234c69cdfa4dc0c7f01806df6b9d63e238b80')
	       ,'Marauders'
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
), nerds_data AS
(
	SELECT  hours.hours_since_first_mint
	       ,COALESCE(nerds.cumulative_count_mint,0) AS cumulative_count_mint
	FROM hours
	LEFT JOIN mint_with_hours AS nerds
	ON nerds.hours_since_first_mint = hours.hours_since_first_mint AND nerds.nft_name = 'Nerds'
	ORDER BY hours.hours_since_first_mint ASC
), marauders_data AS
(
	SELECT  hours.hours_since_first_mint
	       ,COALESCE(marauders.cumulative_count_mint,0) AS cumulative_count_mint
	FROM hours
	LEFT JOIN mint_with_hours AS marauders
	ON marauders.hours_since_first_mint = hours.hours_since_first_mint AND marauders.nft_name = 'Marauders'
	ORDER BY hours.hours_since_first_mint ASC
)
SELECT  nerds_data.hours_since_first_mint
       ,nerds_data.cumulative_count_mint                                                                                              AS nerds
       ,marauders_data.cumulative_count_mint                                                                                          AS marauders
       ,-(nerds_data.cumulative_count_mint - marauders_data.cumulative_count_mint) / NULLIF(nerds_data.cumulative_count_mint,0) * 100 AS performance_delta
FROM nerds_data
JOIN marauders_data
ON marauders_data.hours_since_first_mint = nerds_data.hours_since_first_mint
ORDER BY nerds_data.hours_since_first_mint ASC;