-- {{organization_address}} : 0x854de1bf96dfbe69fc46f1a888d26934ad47b77f
WITH transfers AS
(
	SELECT  day
	       ,tokenid
	       ,AMOUNT
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		       ,tokenid
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			       ,tokenid
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			       ,tokenid
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		         ,tokenid
		ORDER BY day
	)
	GROUP BY  day
	         ,tokenid
	         ,AMOUNT
	ORDER BY day ASC
)
SELECT  *
FROM transfers
--
WITH transfers AS
(
	SELECT  day
	       ,tokenid
	       ,AMOUNT
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		       ,tokenid
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			       ,tokenid
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			       ,tokenid
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		         ,tokenid
		ORDER BY day
	)
	GROUP BY  day
	         ,tokenid
	         ,AMOUNT
	ORDER BY day ASC
), balances AS
(
	SELECT  day
	       ,tokenid
	       ,SUM(AMOUNT) OVER (PARTITION BY tokenid ORDER BY day) AS balance
	FROM transfers
	ORDER BY day ASC
)
SELECT  *
FROM balances
--
WITH transfers AS
(
	SELECT  day
	       ,tokenid
	       ,AMOUNT
	       ,SUM( CASE WHEN action = 'mint' THEN AMOUNT ELSE 0 END ) AS mint
	       ,SUM( CASE WHEN action = 'burn' THEN AMOUNT ELSE 0 END ) AS burn
	FROM
	(
		SELECT  SUM(ERC1155_VALUE)                AS AMOUNT
		       ,DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
		       ,action
		       ,tokenid
		FROM
		(
			SELECT  BLOCK_TIMESTAMP
			       ,'mint' AS action
			       ,ERC1155_VALUE
			       ,tokenid
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_from_address = '0x0000000000000000000000000000000000000000' 
			UNION ALL
			SELECT  BLOCK_TIMESTAMP
			       ,'burn' AS action
			       ,-1 * ERC1155_VALUE
			       ,tokenid
			FROM polygon.core.ez_nft_transfers
			WHERE nft_address = LOWER('{{ organization_address }}')
			AND nft_to_address = '0x0000000000000000000000000000000000000000' 
		)
		GROUP BY  day
		         ,action
		         ,tokenid
		         ,ERC1155_VALUE
		ORDER BY day
	)
	GROUP BY  day
	         ,tokenid
	         ,AMOUNT
	ORDER BY day
), balances_re AS
(
	SELECT  day
	       ,tokenid
	       ,SUM(AMOUNT) OVER (PARTITION BY tokenid ORDER BY day) AS balance
	FROM transfers
	GROUP BY  day
	         ,tokenid
	         ,AMOUNT
	ORDER BY day
), balances AS
(
	SELECT  DISTINCT day
	       ,tokenid
	       ,balance
	FROM balances_re
	ORDER BY day
), badge_change AS
(
	SELECT  day
	       ,tokenid
	       ,balance
	       ,COALESCE(balance - LAG(balance,1) OVER (PARTITION BY tokenid ORDER BY day),balance)                      AS "Badges Change"
	       ,COALESCE(ROUND((balance - LAG(balance,1) OVER (PARTITION BY tokenid ORDER BY day)) / balance * 100,2),0) AS "Badges Change %"
	FROM balances
	ORDER BY day
), holders AS
(
	SELECT  DATE_TRUNC('day',BLOCK_TIMESTAMP) AS day
	       ,tokenid
	       ,COUNT(DISTINCT nft_to_address)    AS holders
	       ,COALESCE(COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (PARTITION BY tokenid ORDER BY day),COUNT(DISTINCT nft_to_address)) AS "Members Change"
	       ,COALESCE(ROUND((COUNT(DISTINCT nft_to_address) - LAG(COUNT(DISTINCT nft_to_address),1) OVER (PARTITION BY tokenid ORDER BY day)) / COUNT(DISTINCT nft_to_address) * 100,2),0) AS "Members Change %"
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = LOWER('{{ organization_address }}')
	GROUP BY  1
	         ,2
	ORDER BY 1
), organization_change AS
(
	SELECT  badge_change.day
	       ,'{{organization_address}}' AS "Organization"
	       ,badge_change.tokenid
	       ,badge_change.balance       AS "Badges"
	       ,badge_change."Badges Change"
	       ,badge_change."Badges Change %"
	       ,holders.holders            AS "Members"
	       ,holders."Members Change"
	       ,holders."Members Change %"
	FROM
	(
		SELECT  *
		       ,ROW_NUMBER() OVER (PARTITION BY tokenid ORDER BY day DESC) AS row_number
		FROM badge_change
	) badge_change
	JOIN
	(
		SELECT  *
		       ,ROW_NUMBER() OVER (PARTITION BY tokenid ORDER BY day DESC) AS row_number
		FROM holders
	) holders
	ON badge_change.tokenid = holders.tokenid AND badge_change.row_number = holders.row_number
	WHERE badge_change.row_number = 1 
)
SELECT  *
FROM organization_change