WITH balances AS
(
	SELECT  DISTINCT t.nft_to_address
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
	WHERE nft_address = '{{organization_address}}'
	AND tokenid = {{token_id}}
	HAVING balance > 0
	ORDER BY balance DESC
), holders AS
(
	SELECT  '{{ organization_address }}'   AS nft_address
	       ,{{ token_id }}                 AS tokenid
	       ,COUNT(DISTINCT nft_to_address) AS "Holders"
	FROM balances
)
SELECT  *
FROM holders