SELECT  SUM(MINT_PRICE_ETH)                               AS total_eth_raised
       ,SUM(MINT_PRICE_USD)                               AS total_usd_raised
       ,SUM(MINT_PRICE_USD) * .45                         AS total_dev_earned
       ,SUM(MINT_PRICE_USD) * .55                         AS total_usd_profits
       ,SUM(MINT_PRICE_USD) * .15 * .5 * .65              AS opportunity_missed
       ,SUM(MINT_PRICE_USD) * .15 * .5 * .65 * 0.00002560 AS hourly_opportunity_missed
FROM ethereum.core.ez_nft_mints
WHERE nft_address IN ( LOWER('0x026234c69cdfa4dc0c7f01806df6b9d63e238b80'), LOWER('0x120305aace78052a967182b277f6392670ee9873'), LOWER('0x072d62047b03b9ee68596557aee848188422150b') )