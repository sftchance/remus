WITH token_ids AS
(
	SELECT  DISTINCT tokenid
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = '{{organization_address}}' 
), balances AS
(
	SELECT  DISTINCT t.nft_address
	       ,t.tokenid
	       ,t.nft_to_address
	       ,(
	SELECT  SUM(erc1155_value)
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = t.nft_address
	AND nft_to_address = t.nft_to_address
	AND tokenid = t.tokenid ) AS "In", COALESCE( (
	SELECT  SUM(erc1155_value)
	FROM polygon.core.ez_nft_transfers
	WHERE nft_address = t.nft_address
	AND nft_from_address = t.nft_to_address
	AND tokenid = t.tokenid ), 0 ) AS "Out", ("In" - "Out") AS balance
	FROM polygon.core.ez_nft_transfers t
	WHERE nft_address = '{{organization_address}}'
	ORDER BY tokenid, balance DESC 
), holders AS
(
	SELECT  nft_address
	       ,tokenid
	       ,COUNT(DISTINCT nft_to_address) AS "Holders"
	FROM balances
	WHERE nft_to_address != '0x0000000000000000000000000000000000000000'
	GROUP BY  nft_address
	         ,tokenid
)
SELECT  *
FROM holders