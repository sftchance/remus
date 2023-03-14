-- NET FLOW
WITH flows AS
(
	SELECT  *
	       ,SUM(USDC) OVER ( ORDER BY hour ) AS hourly_flow
	FROM
	(
		SELECT  SUM(RAW_AMOUNT / 1e6)              AS USDC
		       ,DATE_TRUNC('hour',BLOCK_TIMESTAMP) AS hour
		       ,'mint'                             AS action
		FROM ethereum.core.ez_token_transfers
		WHERE contract_address = LOWER('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')
		AND from_address = '0x0000000000000000000000000000000000000000'
		AND BLOCK_TIMESTAMP > DATEADD(HOUR, -72, CURRENT_TIMESTAMP())
		GROUP BY  hour
		         ,action
		UNION ALL
		SELECT  -1 * SUM(RAW_AMOUNT / 1e6)         AS USDC
		       ,DATE_TRUNC('hour',BLOCK_TIMESTAMP) AS hour
		       ,'burn'                             AS action
		FROM ethereum.core.ez_token_transfers
		WHERE contract_address = LOWER('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')
		AND to_address = '0x0000000000000000000000000000000000000000'
		AND BLOCK_TIMESTAMP > DATEADD(HOUR, -72, CURRENT_TIMESTAMP())
		GROUP BY  hour
		         ,action
	)
	GROUP BY  hour
	         ,USDC
	         ,action
	ORDER BY hour
)
SELECT  hour
       ,MAX(hourly_flow) AS hourly_flow
FROM flows
GROUP BY  hour
ORDER BY hour DESC
-- USDC PRICE
SELECT  price
       ,hour
       ,token_address
FROM ethereum.core.fact_hourly_token_prices
WHERE token_address = LOWER('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48')
AND HOUR > DATEADD(HOUR, -72, CURRENT_TIMESTAMP())
ORDER BY hour DESC
-- USDC PRICE OFF PEG
SELECT  *
       ,price - 1 AS diff
       ,0         AS "$1"
FROM ethereum.core.fact_hourly_token_prices
WHERE token_address = LOWER('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48')
AND HOUR > DATEADD(HOUR, -72, CURRENT_TIMESTAMP())
ORDER BY hour DESC
-- MINTS-AND-BURNS
SELECT  hour
       ,SUM( CASE WHEN action = 'mint' THEN USDC ELSE 0 END ) AS mint
       ,SUM( CASE WHEN action = 'burn' THEN USDC ELSE 0 END ) AS burn
FROM
(
	SELECT  SUM(RAW_AMOUNT / 1e6)              AS USDC
	       ,DATE_TRUNC('hour',BLOCK_TIMESTAMP) AS hour
	       ,action
	FROM
	(
		SELECT  BLOCK_TIMESTAMP
		       ,'mint' AS action
		       ,RAW_AMOUNT
		FROM ethereum.core.ez_token_transfers
		WHERE contract_address = LOWER('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')
		AND from_address = '0x0000000000000000000000000000000000000000'
		AND BLOCK_TIMESTAMP > DATEADD(HOUR, -72, CURRENT_TIMESTAMP()) 
		UNION ALL
		SELECT  BLOCK_TIMESTAMP
		       ,'burn' AS action
		       ,-1 * RAW_AMOUNT
		FROM ethereum.core.ez_token_transfers
		WHERE contract_address = LOWER('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48')
		AND to_address = '0x0000000000000000000000000000000000000000'
		AND BLOCK_TIMESTAMP > DATEADD(HOUR, -72, CURRENT_TIMESTAMP()) 
	)
	GROUP BY  hour
	         ,action
)
GROUP BY  hour
ORDER BY hour