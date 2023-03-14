select
  nft_to_address as minter_wallet,
  count(tokenid) as n_minted_nft,
  count(DISTINCT tx_hash) as n_mint_txns,
  sum(mint_price_eth) as total_eth_spent
from
  ethereum.core.ez_nft_mints
where
  nft_address = LOWER('0x026234c69cdfa4dc0c7f01806df6b9d63e238b80')
  OR nft_address = LOWER('0x120305aace78052a967182b277f6392670ee9873') 
  OR nft_address = LOWER('0x072d62047b03b9ee68596557aee848188422150b')
group by
  minter_wallet
having
  total_eth_spent > 0
order by
  total_eth_spent DESC
LIMIT
  100