WITH daily_records AS
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
		SELECT  block_timestamp::date                                        AS day
		       ,tx_hash
		       ,contract_address                                             AS org
		       ,CONCAT('0x',SUBSTR(topics [2] :: STRING,27,40))              AS from_address
		       ,CONCAT('0x',SUBSTR(topics [3] :: STRING,27,40))              AS to_address
		       ,CONCAT('0x',SUBSTR(topics [1] :: STRING,27,40))              AS OPERATOR
		       ,regexp_substr_all(SUBSTR(DATA,3,len(DATA)),'.{64}')          AS segmented_data
		       ,ethereum.public.udf_hex_to_int(segmented_data [0] :: STRING) AS id
		       ,ethereum.public.udf_hex_to_int(segmented_data [1] :: STRING) AS value_erc1155
		FROM polygon.core.fact_event_logs
		WHERE block_timestamp :: DATE > '2022-10-16' :: DATE
		AND contract_address IN (SELECT DISTINCT created_contracts
		FROM orgs) AND topics [0] :: STRING = '0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62'
	), mints AS
	(
		SELECT  day
		       ,tx_hash
		       ,org
		       ,to_address                    AS target
		       ,id
		       ,value_erc1155
		       ,CONCAT(org,'-',target,'-',id) AS unique_id
		FROM base_table
		WHERE from_address = '0x0000000000000000000000000000000000000000' 
	), burns AS
	(
		SELECT  day
		       ,tx_hash
		       ,org
		       ,from_address                  AS target
		       ,id
		       ,value_erc1155
		       ,CONCAT(org,'-',target,'-',id) AS unique_id
		FROM base_table
		WHERE to_address = '0x0000000000000000000000000000000000000000' 
	), transfers AS
	(
		SELECT  day
		       ,tx_hash
		       ,org
		       ,from_address                           AS target_decrease
		       ,to_address                             AS target_increase
		       ,id
		       ,value_erc1155
		       ,CONCAT(org,'-',target_decrease,'-',id) AS unique_id_decrease
		       ,CONCAT(org,'-',target_increase,'-',id) AS unique_id_increase
		FROM base_table
		WHERE from_address <> '0x0000000000000000000000000000000000000000'
		AND to_address <> '0x0000000000000000000000000000000000000000' 
	), increases AS
	(
		SELECT  day
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,1 AS action
		FROM mints
		UNION ALL
		SELECT  day
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
		SELECT  day
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,-1 AS action
		FROM burns
		UNION ALL
		SELECT  day
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
		SELECT  day
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,action
		FROM increases
		UNION ALL
		SELECT  day
		       ,tx_hash
		       ,org
		       ,target
		       ,id
		       ,value_erc1155
		       ,unique_id
		       ,action
		FROM decreases
	)
	SELECT  day
	       ,org
	       ,SUM(action) over (partition by org ORDER BY day asc rows BETWEEN unbounded preceding AND current row) AS members
	FROM all_records
), name_lookup AS
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
)
SELECT  day
       ,org_name
       ,MAX(members) AS members
       ,MAX(day)     AS last_change
FROM daily_records
LEFT JOIN name_lookup
ON daily_records.org = name_lookup.org_address
WHERE daily_records.org not IN ( '0xb59210cfb0d101367ee09678b0a823441b0fef8f' , '0x019cf6fcd5eb07b9fc2b920a9ab3350e87fad88b' , '0x1133bcdd1fc810b27d33cef6578d0fa94a49490b' , '0xb73ef77c74737f8c53cb8c9392f42feadf97a07d' , '0x9dd33ec09e190b8aab3739ddf90a37e55c0ccd02' , '0x624abe23ffcca47d46958099924a923484ee2977' , '0x70a04123de9df3c1bcaac7a8ff41d1a1496d8b0d' , '0x80466646e738c4d0a1ba96b49c954d4de7b7bbca' , '0xea685cc8cadb4be1230b276a9a82c3f472325797' , '0x1e1727c2208dad9eda19290b511c1080845ac777' , '0x6c8029c512c45a39c70e12615065836d45ef793f' , '0xf84dce073091d482928cc2f7bc06b6e38b727718' , '0xc15395c3ae6d3b4073749dd25e3b35c5afb5b434' , '0x17e615d3b6fb6d90f89863f19aa1d685e55f534e' , '0xf5af0fab7daa864cc739ec3c102196151c371c6b' , '0x1529db83e2f5b0401a089af74ac68a87cdab485f' , '0x7de7b0b93bf331f7841edd566d3524f75d936be1' , '0xa66949c2ec3727695a03a0e03724dc67e39e81a4' , '0x7ab3324f239bc13e9cfbb227ea999f32cb158d0e' , '0xc56b91c7161fd6ddc179bb95bd9c1edcbf184761' , '0x21c50310cdd5704c50642ad2ed18a6c86164cf34' , '0x4cb1f4c5264d6a8aa75ad574139c20577754c9bb' , '0x90ffdf48a1660a2759d82c1af78318f414b1a9b5' , '0x082a44a5a17394f2a842f3d22606b387a642e0a7' , '0xd047e4b2c6f7d5072bbea49ee560525ca7e05efc' , '0x45868c98cbb1708b487d70f0ded4a1ad20d8df9c' , '0xece4dbcd209450091a4ba12b9044dbf8b9106f3a' , '0xb57675e7ebdbe57e4d2cca8b1c7d114082b34dcb' , '0x9efc0aea7b907372fcced5a84c6e731788f992a4' )
GROUP BY  1
         ,2
HAVING current_date() - MAX(day) < 31
ORDER BY 3 desc