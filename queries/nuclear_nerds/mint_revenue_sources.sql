SELECT  nft_to_address          AS minter_wallet
       ,COUNT(tokenid)          AS n_minted_nft
       ,COUNT(DISTINCT tx_hash) AS n_mint_txns
       ,SUM(mint_price_eth)     AS total_eth_spent
FROM ethereum.core.ez_nft_mints
WHERE nft_address = LOWER('0x026234c69cdfa4dc0c7f01806df6b9d63e238b80') OR nft_address = LOWER('0x120305aace78052a967182b277f6392670ee9873') OR nft_address = LOWER('0x072d62047b03b9ee68596557aee848188422150b')
GROUP BY  minter_wallet
HAVING total_eth_spent > 0
ORDER BY total_eth_spent DESC
LIMIT 100