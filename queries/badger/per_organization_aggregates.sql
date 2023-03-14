WITH name_lookup AS
(
	WITH orgs AS
	(
		SELECT  *
		       ,regexp_substr_all(SUBSTR(input,11,len(input)),'.{64}') AS segmented_input
		FROM polygon.core.fact_traces
		WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
		AND type = 'CALL'
		AND from_address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6') -- deployer
		AND substr(input, 0, 10) = '0xb6dbcae5' 
	)
	SELECT  try_hex_decode_string(segmented_input[14]::string) AS org_name
	       ,to_address                                         AS org_address
	       ,block_timestamp                                    AS org_created_timestamp
	FROM orgs
), org_data AS
(
	WITH orgs AS
	(
		SELECT  CONCAT('0x',RIGHT(topics [1] :: STRING,40)) AS created_contracts
		FROM polygon.core.fact_event_logs
		WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
		AND contract_Address = LOWER('0x218b3c623ffb9c5e4dbb9142e6ca6f6559f1c2d6')
		AND origin_function_signature = '0x7b366213' 
	), base_table AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,contract_address                                               AS org
		       ,CONCAT('0x',SUBSTR(topics [2] :: STRING,27,40))                AS from_address
		       ,CONCAT('0x',SUBSTR(topics [3] :: STRING,27,40))                AS to_address
		       ,CONCAT('0x',SUBSTR(topics [1] :: STRING,27,40))                AS OPERATOR
		       ,regexp_substr_all(SUBSTR(DATA,3,len(DATA)),'.{64}')            AS segmented_data
		       ,ethereum.public.udf_hex_to_int( segmented_data [0] :: STRING ) AS id
		       ,ethereum.public.udf_hex_to_int( segmented_data [1] :: STRING ) AS value_erc1155
		FROM polygon.core.fact_event_logs
		WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
		AND contract_address IN ( SELECT DISTINCT created_contracts FROM orgs )
		AND topics [0] :: STRING = '0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62'
		ORDER BY block_timestamp ASC 
	), mints AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,to_address                      AS target
		       ,id
		       ,value_erc1155
		       ,CONCAT( org,'-',target,'-',id ) AS unique_id
		FROM base_table
		WHERE from_address = '0x0000000000000000000000000000000000000000' 
	), burns AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,from_address                    AS target
		       ,id
		       ,value_erc1155
		       ,CONCAT( org,'-',target,'-',id ) AS unique_id
		FROM base_table
		WHERE to_address = '0x0000000000000000000000000000000000000000' 
	), transfers AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,from_address                             AS target_decrease
		       ,to_address                               AS target_increase
		       ,id
		       ,value_erc1155
		       ,CONCAT( org,'-',target_decrease,'-',id ) AS unique_id_decrease
		       ,CONCAT( org,'-',target_increase,'-',id ) AS unique_id_increase
		FROM base_table
		WHERE from_address <> '0x0000000000000000000000000000000000000000'
		AND to_address <> '0x0000000000000000000000000000000000000000' 
	), increases AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,1 AS action
		FROM mints
		UNION ALL
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,target_increase    AS target
		       ,id
		       ,value_erc1155
		       ,unique_id_increase AS unique_id
		       ,1                  AS action
		FROM transfers
	), decreases AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,-1 AS action
		FROM burns
		UNION ALL
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,target_decrease    AS target
		       ,id
		       ,value_erc1155
		       ,unique_id_decrease AS unique_id
		       ,-1                 AS action
		FROM transfers
	), all_records AS
	(
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,action
		FROM increases
		UNION ALL
		SELECT  block_timestamp
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,action
		FROM decreases
	)
	SELECT  org                  AS "Organization Address"
	       ,target               AS "Member Address"
	       ,id                   AS "Token ID"
	       ,SUM(action)          AS "Balance"
	       ,MAX(block_timestamp) AS updated_at
	FROM all_records
	GROUP BY  1
	         ,2
	         ,3
)
SELECT  MAX(org_created_timestamp)                                                  AS "Created"
       ,org_name                                                                    AS "Organization"
       ,"Organization Address"
       ,COUNT(distinct "Token ID")::string                                          AS "Active Badge Types"
       ,COUNT(distinct (case WHEN "Balance" > 0 THEN "Member Address" end))::string AS "Members"
       ,COUNT(distinct (case WHEN "Balance" = 0 THEN "Member Address" end))::string AS "Ex Members"
       ,MAX(updated_at)                                                             AS "Last Member Change"
FROM org_data
LEFT JOIN name_lookup
ON org_data."Organization Address" = name_lookup.org_address
-- WHERE "Balance" > 0
GROUP BY  2
         ,3
ORDER BY "Last Member Change" desc