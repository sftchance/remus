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
	       ,block_timestamp::date AS date
	       ,nft_name
	FROM ethereum.core.ez_nft_mints mnt
	JOIN eth_collection eth USING
	(nft_address
	)
), daily_count AS
(
	SELECT  nft_name
	       ,date
	       ,COUNT(tx_hash)                                                     AS count_mint
	       ,SUM(COUNT(tx_hash)) OVER (PARTITION BY nft_name ORDER BY date ASC) AS cumulative_count_mint
	FROM mint
	GROUP BY  nft_name
	         ,date
), date_range AS
(
	SELECT  DISTINCT date
	FROM daily_count
)
SELECT  date_range.date
       ,SUM(CASE WHEN daily_count.nft_name = 'Nerds' THEN daily_count.count_mint ELSE 0 END)                     AS Nerds
       ,SUM(CASE WHEN daily_count.nft_name = 'Marauders' THEN daily_count.count_mint ELSE 0 END)                 AS Marauders
       ,SUM(CASE WHEN daily_count.nft_name = 'Box o Bad Guys' THEN daily_count.count_mint ELSE 0 END)            AS Box_o_Bad_Guys
       ,SUM(CASE WHEN daily_count.nft_name = 'Serums' THEN daily_count.count_mint ELSE 0 END)                    AS Serums
       ,SUM(CASE WHEN daily_count.nft_name = 'Nerds' THEN daily_count.cumulative_count_mint ELSE 0 END)          AS Cumulative_Nerds
       ,SUM(CASE WHEN daily_count.nft_name = 'Marauders' THEN daily_count.cumulative_count_mint ELSE 0 END)      AS Cumulative_Marauders
       ,SUM(CASE WHEN daily_count.nft_name = 'Box o Bad Guys' THEN daily_count.cumulative_count_mint ELSE 0 END) AS Cumulative_Box_o_Bad_Guys
       ,SUM(CASE WHEN daily_count.nft_name = 'Serums' THEN daily_count.cumulative_count_mint ELSE 0 END)         AS Cumulative_Serums
FROM date_range
LEFT JOIN daily_count
ON daily_count.date = date_range.date
WHERE date_range.date > '2023-03-07'::date
GROUP BY  date_range.date
ORDER BY date_range.date ASC;