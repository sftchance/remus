SELECT  price
       ,hour
       ,token_address
FROM ethereum.core.fact_hourly_token_prices
WHERE token_address = LOWER('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48')
AND HOUR > DATEADD(HOUR, -72, CURRENT_TIMESTAMP())
ORDER BY hour DESC 