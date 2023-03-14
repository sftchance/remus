WITH holders AS
(
	SELECT  EVENT_INPUTS:"to"::string      AS holder
	       ,EVENT_INPUTS:"tokenId"::string AS tokenid
	       ,block_number
	       ,tx_hash
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp::date > '2022-05-01'::date
	AND contract_address = lower('0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d')
	AND event_name = 'Transfer' qualify rank() OVER ( partition BY tokenid ORDER BY block_number DESC, event_index DESC ) = 1 
	UNION ALL
	SELECT  concat('0x',RIGHT(topics[2]::string,40))                             AS holder
	       ,ethereum.PUBLIC.udf_hex_to_int (RIGHT(topics[3]::string,42))::string AS tokenid
	       ,block_number
	       ,tx_hash
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp::date > '2022-05-01'::date
	AND contract_address = lower('0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d')
	AND origin_function_signature = '0x42842e0e'
	AND topics[0]::string = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' qualify rank() OVER ( partition BY tokenid ORDER BY block_number DESC, event_index DESC ) = 1 
), names AS
(
	SELECT  ( ethereum.PUBLIC.udf_hex_to_int (topics[1]::string) )::string                               AS tokenid
	       ,regexp_substr_all(substr(data,3,len(data)),'.{64}')                                          AS segmented_data
	       ,try_hex_decode_string( ( regexp_substr_all(substr(data,3,len(data)),'.{64}') ) [7]::string ) AS handle
	FROM polygon.core.fact_event_logs
	WHERE block_timestamp::date > '2022-05-01'
	AND contract_address = lower('0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d')
	AND topics[0]::string = '0x4e14f57cff7910416f2ef43cf05019b5a97a313de71fec9344be11b9b88fed12' 
)
SELECT  holders.tokenid
       ,replace(names.handle,chr(0),'') AS handle
       ,holders.holder
FROM holders
LEFT JOIN names
ON holders.tokenid::string = names.tokenid::string qualify rank() OVER ( partition BY holders.tokenid ORDER BY block_number DESC ) = 1 ORDER BY 1 DESC