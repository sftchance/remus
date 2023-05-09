WITH daily_transfers AS
(
	SELECT  DISTINCT DATE_TRUNC('day',t.block_timestamp) AS date
	FROM polygon.core.ez_nft_transfers t
	WHERE nft_address = '{{organization_address}}'
	AND tokenid = {{token_id}} 
), daily_balances AS
(
	SELECT  DISTINCT t.nft_to_address
	       ,t.nft_address
	       ,d.date
	       ,t.tokenid
	       ,(
	SELECT  SUM(erc1155_value)
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = t.nft_address
	AND nft_to_address = t.nft_to_address
	AND tokenid = t.tokenid ) AS "In", (
	SELECT  COALESCE(SUM(erc1155_value),0)
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = t.nft_address
	AND nft_from_address = t.nft_to_address
	AND tokenid = t.tokenid ) AS "Out", ("In" - "Out") AS balance
	FROM polygon.core.ez_nft_transfers t
	CROSS JOIN daily_transfers d
	WHERE nft_address = '{{organization_address}}'
	AND tokenid = {{token_id}}
	AND DATE_TRUNC('day', block_timestamp) <= d.date
	HAVING balance > 0
), daily_holders AS
(
	SELECT  date
	       ,nft_address
	       ,tokenid
	       ,COUNT(DISTINCT nft_to_address) AS holders
	FROM daily_balances
	GROUP BY  date
	         ,nft_address
	         ,tokenid
)
SELECT  *
FROM daily_holders
ORDER BY date DESC;