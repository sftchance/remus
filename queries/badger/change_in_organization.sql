-- {{organization_address}} : 0x854de1bf96dfbe69fc46f1a888d26934ad47b77f
--
WITH transfers AS
(
	SELECT  day
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	       ,SUM(AMOUNT) OVER (ORDER BY day)                         AS balance
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		ORDER BY day
	)
	GROUP BY  day
	         ,AMOUNT
	ORDER BY day
)
SELECT  *
FROM transfers
--
WITH transfers AS
(
	SELECT  day
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	       ,SUM(AMOUNT) OVER (ORDER BY day)                         AS balance
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		ORDER BY day
	)
	GROUP BY  day
	         ,AMOUNT
	ORDER BY day
), change AS
(
	SELECT  day
	       ,balance
	       ,COALESCE(balance - LAG(balance,1) OVER (ORDER BY day),0)                                                       AS "Badges Change"
	       ,COALESCE(ROUND(100 * (balance - LAG(balance,1) OVER (ORDER BY day)) / LAG(balance,1) OVER (ORDER BY day),4),0) AS "Badge Change %"
	FROM transfers
	ORDER BY transfers.day
)
SELECT  *
FROM change
--
WITH transfers AS
(
	SELECT  day
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	       ,SUM(AMOUNT) OVER (ORDER BY day)                         AS balance
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		ORDER BY day
	)
	GROUP BY  day
	         ,AMOUNT
	ORDER BY day
), badge_change AS
(
	SELECT  day
	       ,balance
	       ,COALESCE(balance - LAG(balance,1) OVER (ORDER BY day),balance)                                                   AS "Badges Change"
	       ,COALESCE(ROUND(100 * (balance - LAG(balance,1) OVER (ORDER BY day)) / LAG(balance,1) OVER (ORDER BY day),4),100) AS "Badges Change %"
	FROM transfers
	ORDER BY transfers.day
), holders AS
(
	SELECT  DATE_TRUNC('day',BLOCK_TIMESTAMP)                                                                                                    AS day
	       ,COUNT(DISTINCT nft_to_address)                                                                                                       AS holders
	       ,COALESCE(COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (ORDER BY day ),COUNT(DISTINCT nft_to_address)) AS "Members Change"
	       ,COALESCE(ROUND(100 * (COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (ORDER BY day )) / LAG(COUNT(DISTINCT nft_to_address),1) OVER (ORDER BY day ),4),100) AS "Members Change %"
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = LOWER('{{ organization_address }}')
	GROUP BY  1
	ORDER BY day
), organization_change AS
(
	SELECT  '{{organization_address}}' AS "Organization"
	       ,badge_change.balance       AS "Badges"
	       ,badge_change."Badges Change"
	       ,badge_change."Badges Change %"
	       ,holders.holders            AS "Members"
	       ,holders."Members Change"
	       ,holders."Members Change %"
	FROM badge_change
	JOIN holders
	ON holders.day = badge_change.day
	ORDER BY badge_change.day DESC
	LIMIT 1
)
SELECT  *
FROM organization_change
--
-- instead of USING _organization_address I want to use orgs AS the source of addresses
WITH orgs AS
(
	SELECT  CONCAT('0x',RIGHT(topics [1] :: STRING,40)) AS organization
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
	AND contract_Address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
	AND origin_function_signature = '0x7b366213' 
), transfers AS
(
	SELECT  day
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	       ,SUM(AMOUNT) OVER (ORDER BY day)                         AS balance
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		ORDER BY day
	)
	GROUP BY  day
	         ,AMOUNT
	ORDER BY day
), badge_change AS
(
	SELECT  day
	       ,balance
	       ,COALESCE(balance - LAG(balance,1) OVER (ORDER BY day),balance)                                                   AS "Badges Change"
	       ,COALESCE(ROUND(100 * (balance - LAG(balance,1) OVER (ORDER BY day)) / LAG(balance,1) OVER (ORDER BY day),4),100) AS "Badges Change %"
	FROM transfers
	ORDER BY transfers.day
), holders AS
(
	SELECT  DATE_TRUNC('day',BLOCK_TIMESTAMP)                                                                                                    AS day
	       ,COUNT(DISTINCT nft_to_address)                                                                                                       AS holders
	       ,COALESCE(COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (ORDER BY day ),COUNT(DISTINCT nft_to_address)) AS "Members Change"
	       ,COALESCE(ROUND(100 * (COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (ORDER BY day )) / LAG(COUNT(DISTINCT nft_to_address),1) OVER (ORDER BY day ),4),100) AS "Members Change %"
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = LOWER('{{ organization_address }}')
	GROUP BY  1
	ORDER BY day
), organization_change AS
(
	SELECT  badge_change.day
	       ,'{{organization_address}}' AS "Organization"
	       ,badge_change.balance       AS "Badges"
	       ,badge_change."Badges Change"
	       ,badge_change."Badges Change %"
	       ,holders.holders            AS "Members"
	       ,holders."Members Change"
	       ,holders."Members Change %"
	FROM badge_change
	JOIN holders
	ON holders.day = badge_change.day
	ORDER BY badge_change.day DESC
	LIMIT 1
)
SELECT  *
FROM organization_change
--
WITH orgs AS
(
	SELECT  CONCAT('0x',RIGHT(topics [1] :: STRING,40)) AS organization
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
	AND contract_Address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
	AND origin_function_signature = '0x7b366213' 
), transfers AS
(
	SELECT  day
	       ,nft_address
	       ,SUM(CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END) AS mint
	       ,SUM(CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END) AS burn
	       ,SUM(AMOUNT)                                           AS AMOUNT
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		       ,nft_address
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			       ,nft_address
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address IN (SELECT organization
			FROM orgs) AND nft_from_address = '0x0000000000000000000000000000000000000000'
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			       ,nft_address
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address IN (SELECT organization
			FROM orgs) AND nft_to_address = '0x0000000000000000000000000000000000000000'
		)
		GROUP BY  day
		         ,action
		         ,nft_address
		ORDER BY day
	)
	GROUP BY  day
	         ,nft_address
	         ,AMOUNT
	ORDER BY day
)
SELECT  *
FROM transfers
--
WITH orgs AS
(
	SELECT  CONCAT('0x',RIGHT(topics [1] :: STRING,40)) AS organization
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
	AND contract_Address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
	AND origin_function_signature = '0x7b366213' 
), transfers AS
(
	SELECT  day
	       ,nft_address
	       ,SUM(CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END) AS mint
	       ,SUM(CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END) AS burn
	       ,SUM(AMOUNT)                                           AS balance
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		       ,nft_address
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			       ,nft_address
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address IN (SELECT organization
			FROM orgs) AND nft_from_address = '0x0000000000000000000000000000000000000000'
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			       ,nft_address
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address IN (SELECT organization
			FROM orgs) AND nft_to_address = '0x0000000000000000000000000000000000000000'
		)
		GROUP BY  day
		         ,action
		         ,nft_address
		ORDER BY day
	)
	GROUP BY  day
	         ,nft_address
	         ,AMOUNT
	ORDER BY day
), badge_change AS
(
	SELECT  day
	       ,nft_address
	       ,balance
	       ,COALESCE(balance - LAG(balance,1) OVER (PARTITION BY nft_address ORDER BY day),balance) AS "Badges Change"
	       ,COALESCE(ROUND(100 * (balance - LAG(balance,1) OVER (PARTITION BY nft_address ORDER BY day)) / LAG(balance,1) OVER (PARTITION BY nft_address ORDER BY day),4),100) AS "Badges Change %"
	FROM transfers
	ORDER BY transfers.day
)
SELECT  *
FROM badge_change
--
WITH orgs AS
(
	SELECT  CONCAT('0x',RIGHT(topics [1] :: STRING,40)) AS organization
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
	AND contract_Address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
	AND origin_function_signature = '0x7b366213' 
), transfers AS
(
	SELECT  day
	       ,AMOUNT
	       ,nft_address
	       ,SUM(CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END) AS mint
	       ,SUM(CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END) AS burn
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		       ,nft_address
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			       ,nft_address
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address IN (SELECT organization
			FROM orgs) AND nft_from_address = '0x0000000000000000000000000000000000000000'
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			       ,nft_address
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address IN (SELECT organization
			FROM orgs) AND nft_to_address = '0x0000000000000000000000000000000000000000'
		)
		GROUP BY  day
		         ,action
		         ,nft_address
		ORDER BY day
	) AS subquery
	GROUP BY  day
	         ,nft_address
	         ,AMOUNT
	ORDER BY day
), balances_re AS
(
	SELECT  day
	       ,nft_address
	       ,SUM(AMOUNT) OVER (PARTITION BY nft_address ORDER BY day) AS balance
	FROM transfers
	GROUP BY  day
	         ,nft_address
	         ,AMOUNT
	ORDER BY day
), balances AS
(
	SELECT  DISTINCT day
	       ,nft_address
	       ,balance
	FROM balances_re
	ORDER BY day
), badge_change_re AS
(
	SELECT  day
	       ,nft_address
	       ,balance
	       ,COALESCE(balance - LAG(balance,1) OVER (PARTITION BY nft_address ORDER BY day),balance) AS "Badges Change"
	       ,COALESCE( CASE WHEN balance = 0 THEN 0 ELSE ROUND((balance - LAG(balance,1) OVER (PARTITION BY nft_address ORDER BY day)) / balance * 100,2) END,0 ) AS "Badges Change %"
	FROM balances
	ORDER BY day
), badge_change AS
(
	SELECT  *
	       ,ROW_NUMBER() OVER (PARTITION BY nft_address ORDER BY day DESC) AS rn
	FROM badge_change_re
	ORDER BY day DESC
), holders AS (
	SELECT  DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
           ,nft_address	       
           ,tokenid
	       ,COUNT(DISTINCT nft_to_address)    AS holders
	       ,COALESCE(COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (PARTITION BY tokenid ORDER BY day),COUNT(DISTINCT nft_to_address)) AS "Members Change"
           ,COALESCE( CASE WHEN COUNT(DISTINCT nft_to_address) = 0 THEN 0 ELSE ROUND((COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (PARTITION BY tokenid ORDER BY day)) / COUNT(DISTINCT nft_to_address) * 100,2) END,0 ) AS "Members Change %"
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address IN (SELECT organization
			FROM orgs)
	GROUP BY  1
	         ,2
             ,3
	ORDER BY 1
), organization_change AS
(
	SELECT  day
	       ,nft_address
	       ,balance
	       ,"Badges Change"
	       ,"Badges Change %"
	FROM badge_change
	WHERE rn = 1
	ORDER BY day DESC 
)
SELECT  *
FROM organization_change