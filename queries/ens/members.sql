SELECT  OWNER
       ,REPLACE(EMAIL,chr(0),'')                                                                                                                    AS EMAIL
       ,ENS_NAME
       ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(GITHUB,'https',''),'http',''),'github.com',''),':',''),'/',''),'@',''),chr(0),'')   AS GITHUB
       ,REPLACE(REDDIT,chr(0),'')                                                                                                                   AS REDDIT
       ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TELEGRAM,'https',''),'http',''),'t.me',''),':',''),'/',''),'@',''),'#',''),chr(0),'') AS TELEGRAM
       ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TWITTER,'https',''),'http',''),'twitter.com',''),':',''),'/',''),'@',''),chr(0),'') AS TWITTER
       ,TOKENID
FROM crosschain.core.ez_ens
WHERE ( GITHUB IS NOT NULL OR TWITTER IS NOT NULL OR TELEGRAM IS NOT NULL )