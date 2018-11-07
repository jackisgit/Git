--制票交易表（ST_DAT_TK_PRODUCT），交易类型为01、02、03，05，判断逻辑卡号是否已经在卡账户表中。不存在写入卡账户表（ST_DAT_CARD_STATUS）。
INSERT INTO ST_DAT_CARD_STATUS
  SELECT SEQ_ST_DAT_CARD_STATUS.NEXTVAL,
         PRODUCT.CARD_LOGIC_ID,
         NULL CARD_FACE_ID,
         PRODUCT.CARD_PHYSICAL_ID,
         PRODUCT. DEAL_NO,
         PRODUCT.CARD_MAIN_ID,
         PRODUCT.CARD_SUB_ID,
         NULL SALE_DATETIME,
         PRODUCT. FOREGIFT,
         TK_FEE,
         NULL BEGIN_DATETIME,
         NULL END_DATETIME,
         NULL CURRENT_VALUE,
         NULL INTEGRAL,
         DEAL_TYPE,
         NULL MEDIUM_TYPE,
         NULL LAST_TRADE_TYPE,
         NULL LAST_TRADE_TIME,
         '0' TABLE_FLAG,
         TO_CHAR(SYSDATE, 'yyyyMMddHH24miss') DATETIME
    FROM (SELECT *
            FROM ST_DAT_TK_PRODUCT PRODUCT
           WHERE (PRODUCT.CARD_LOGIC_ID, PRODUCT.DEAL_DATETIME) IN
                 (SELECT CARD_LOGIC_ID, MAX(DEAL_DATETIME)
                    FROM ST_DAT_TK_PRODUCT
                   WHERE BALANCE_WATER_NO = '2018110101'
                     AND CARD_MAIN_ID IN ('02', '03', '04', '05', '07')
                     AND DEAL_TYPE IN ('01', '02', '03', '05')
                   GROUP BY CARD_LOGIC_ID)) PRODUCT
    LEFT JOIN ST_DAT_CARD_STATUS STATUS
      ON PRODUCT.CARD_LOGIC_ID = STATUS.CARD_LOGICAL_ID
   WHERE STATUS.CARD_LOGICAL_ID IS NULL;

--制票交易表（ST_DAT_TK_PRODUCT），交易类型为01、02、03，05，判断逻辑卡号是否已经在卡账户表中。如果逻辑卡号存在并且卡状态不为04，写入制票交易异常表（ST_ERR_TK_PRODUCT）
MERGE INTO ST_ERR_TK_PRODUCT A
USING (SELECT PRODUCT.ROW_ID,
              PRODUCT.DEVICE_ID,
              PRODUCT.DEAL_NO,
              PRODUCT.ORDER_ID,
              PRODUCT.DEAL_TYPE,
              PRODUCT.OPERATOR_ID,
              PRODUCT.REGISTER,
              PRODUCT.CARD_MAIN_ID,
              PRODUCT.CARD_SUB_ID,
              PRODUCT.SAM_LOGICAL_ID,
              PRODUCT.CARD_LOGIC_ID,
              PRODUCT.CARD_PHYSICAL_ID,
              PRODUCT.CARD_WHITE_COUNT,
              PRODUCT.TEST_FLAG,
              PRODUCT.TK_FEE,
              PRODUCT.FOREGIFT,
              PRODUCT.LOGOUT_COUNT,
              PRODUCT.VALIDITY_PERIOD,
              PRODUCT.DEAL_DATETIME,
              PRODUCT.STATE,
              PRODUCT.ACCOUNT_ID,
              PRODUCT.SAM_ID,
              PRODUCT.TK_BOX_ID,
              PRODUCT.BATCH_ID,
              PRODUCT.SQUAD_DAY,
              PRODUCT.BALANCE_WATER_NO,
              PRODUCT.FILE_ID,
              PRODUCT.FILE_NAME,
              '50' ERR_CODE,
              '0' BALANCE_FLAG,
              '制票历史交易表，交易类型为：01、02、03、05的逻辑卡号，在卡账户表中存在' ERR_MESSAGE
         FROM (SELECT *
                 FROM ST_DAT_TK_PRODUCT PRODUCT
                WHERE (PRODUCT.CARD_LOGIC_ID, PRODUCT.DEAL_DATETIME) IN
                      (SELECT CARD_LOGIC_ID, MAX(DEAL_DATETIME)
                         FROM ST_DAT_TK_PRODUCT
                        WHERE BALANCE_WATER_NO = '2018110101'
                          AND CARD_MAIN_ID IN ('02', '03', '04', '05', '07')
                          AND DEAL_TYPE IN ('01', '02', '03', '05')
                        GROUP BY CARD_LOGIC_ID)) PRODUCT
        INNER JOIN ST_DAT_CARD_STATUS STATUS
           ON PRODUCT.CARD_LOGIC_ID = STATUS.CARD_LOGICAL_ID
          AND STATUS.CARD_STATUS != '04') B
ON (A.FILE_NAME = B.FILE_NAME AND A.CARD_LOGIC_ID = B.CARD_LOGIC_ID AND A.TK_FEE = B.TK_FEE AND A.DEAL_DATETIME = B.DEAL_DATETIME)

WHEN NOT MATCHED THEN
  INSERT
  VALUES
    (SEQ_ST_ERR_TK_PRODUCT.NEXTVAL,
     B.ROW_ID,
     B.DEVICE_ID,
     B.DEAL_NO,
     B.ORDER_ID,
     B.DEAL_TYPE,
     B.OPERATOR_ID,
     B.REGISTER,
     B.CARD_MAIN_ID,
     B.CARD_SUB_ID,
     B.SAM_LOGICAL_ID,
     B.CARD_LOGIC_ID,
     B.CARD_PHYSICAL_ID,
     B.CARD_WHITE_COUNT,
     B.TEST_FLAG,
     B.TK_FEE,
     B.FOREGIFT,
     B.LOGOUT_COUNT,
     B.VALIDITY_PERIOD,
     B.DEAL_DATETIME,
     B.STATE,
     B.ACCOUNT_ID,
     B.SAM_ID,
     B.TK_BOX_ID,
     B.BATCH_ID,
     B.SQUAD_DAY,
     B.BALANCE_WATER_NO,
     B.FILE_ID,
     B.FILE_NAME,
     B.ERR_CODE,
     B.BALANCE_FLAG,
     B.ERR_MESSAGE);

--制票交易表（ST_DAT_TK_PRODUCT），交易类型为01、02、03，05，判断逻辑卡号是否已经在卡账户表中。如果逻辑卡号存在，并且卡账户表存在的数据卡状态是04，更新到卡账户表（ST_DAT_CARD_STATUS）
MERGE INTO ST_DAT_CARD_STATUS A
USING (SELECT PRODUCT.CARD_LOGIC_ID,
              PRODUCT. DEAL_NO,
              PRODUCT.CARD_MAIN_ID,
              PRODUCT.CARD_SUB_ID,
              PRODUCT. FOREGIFT,
              TK_FEE,
              DEAL_TYPE,
              TO_CHAR(SYSDATE, 'yyyyMMddHH24miss') DATETIME
         FROM (SELECT *
                 FROM ST_DAT_TK_PRODUCT PRODUCT
                WHERE (PRODUCT.CARD_LOGIC_ID, PRODUCT.DEAL_DATETIME) IN
                      (SELECT CARD_LOGIC_ID, MAX(DEAL_DATETIME)
                         FROM ST_DAT_TK_PRODUCT
                        WHERE BALANCE_WATER_NO = '2018110101'
                          AND CARD_MAIN_ID IN ('02', '03', '04', '05', '07')
                          AND DEAL_TYPE IN ('01', '02', '03', '05')
                        GROUP BY CARD_LOGIC_ID)) PRODUCT) B
ON (B.CARD_LOGIC_ID = A.CARD_LOGICAL_ID)

WHEN MATCHED THEN
  UPDATE
     SET A.DEAL_NO      = B.DEAL_NO,
         A.CARD_MAIN_ID = B.CARD_MAIN_ID,
         A.CARD_SUB_ID  = B.CARD_SUB_ID,
         A.FOREGIFT     = B.FOREGIFT,
         A.CHARGE       = B.TK_FEE,
         A.CARD_STATUS  = B.DEAL_TYPE,
         A.DATETIME     = B.DATETIME
   WHERE CARD_LOGICAL_ID = B.CARD_LOGIC_ID
     AND A.CARD_STATUS = '04';

--制票交易表（st_dat_tk_product），交易类型为（DEAL_TYPE）04，判断逻辑卡号是否已经在卡账户表中,存在更新
MERGE INTO ST_DAT_CARD_STATUS A
USING (SELECT PRODUCT.CARD_LOGIC_ID,
              PRODUCT. DEAL_NO,
              PRODUCT.CARD_MAIN_ID,
              PRODUCT.CARD_SUB_ID,
              PRODUCT. FOREGIFT,
              TK_FEE,
              DEAL_TYPE,
              TO_CHAR(SYSDATE, 'yyyyMMddHH24miss') DATETIME
         FROM (SELECT *
                 FROM ST_DAT_TK_PRODUCT PRODUCT
                WHERE (PRODUCT.CARD_LOGIC_ID, PRODUCT.DEAL_DATETIME) IN
                      (SELECT CARD_LOGIC_ID, MAX(DEAL_DATETIME)
                         FROM ST_DAT_TK_PRODUCT
                        WHERE BALANCE_WATER_NO = '2018012501'
                          AND CARD_MAIN_ID IN ('02', '03', '04', '05', '07')
                          AND DEAL_TYPE = '04'
                        GROUP BY CARD_LOGIC_ID)) PRODUCT) B
ON (B.CARD_LOGIC_ID = A.CARD_LOGICAL_ID)
WHEN MATCHED THEN
  UPDATE
     SET A.DEAL_NO      = B.DEAL_NO,
         A.CARD_MAIN_ID = B.CARD_MAIN_ID,
         A.CARD_SUB_ID  = B.CARD_SUB_ID,
         A.FOREGIFT     = B.FOREGIFT,
         A.CHARGE       = B.TK_FEE,
         A.CARD_STATUS  = B.DEAL_TYPE,
         A.DATETIME     = B.DATETIME
   WHERE A.CARD_LOGICAL_ID = B.CARD_LOGIC_ID;

--制票交易表（st_dat_tk_product），交易类型为（DEAL_TYPE）04,断逻辑卡号是否已经在卡账户表中,不存在插入制票交易异常表（ST_ERR_TK_PRODUCT）
MERGE INTO ST_ERR_TK_PRODUCT A
USING (SELECT 
         PRODUCT.ROW_ID,
         PRODUCT.DEVICE_ID,
         PRODUCT.DEAL_NO,
         PRODUCT.ORDER_ID,
         PRODUCT.DEAL_TYPE,
         PRODUCT.OPERATOR_ID,
         PRODUCT.REGISTER,
         PRODUCT.CARD_MAIN_ID,
         PRODUCT.CARD_SUB_ID,
         PRODUCT.SAM_LOGICAL_ID,
         PRODUCT.CARD_LOGIC_ID,
         PRODUCT.CARD_PHYSICAL_ID,
         PRODUCT.CARD_WHITE_COUNT,
         PRODUCT.TEST_FLAG,
         PRODUCT.TK_FEE,
         PRODUCT.FOREGIFT,
         PRODUCT.LOGOUT_COUNT,
         PRODUCT.VALIDITY_PERIOD,
         PRODUCT.DEAL_DATETIME,
         PRODUCT.STATE,
         PRODUCT.ACCOUNT_ID,
         PRODUCT.SAM_ID,
         PRODUCT.TK_BOX_ID,
         PRODUCT.BATCH_ID,
         PRODUCT.SQUAD_DAY,
         PRODUCT.BALANCE_WATER_NO,
         PRODUCT.FILE_ID,
         PRODUCT.FILE_NAME,
         '51' ERR_CODE,
         '0' BALANCE_FLAG,
         '制票历史交易表，交易类型为：04的逻辑卡号，在卡账户表中不存在' ERR_MESSAGE
    FROM (SELECT *
            FROM ST_DAT_TK_PRODUCT PRODUCT
           WHERE (PRODUCT.CARD_LOGIC_ID, PRODUCT.DEAL_DATETIME) IN
                 (SELECT CARD_LOGIC_ID, MAX(DEAL_DATETIME)
                    FROM ST_DAT_TK_PRODUCT
                   WHERE BALANCE_WATER_NO = '2018110101'
                     AND CARD_MAIN_ID IN ('02', '03', '04', '05', '07')
                     AND DEAL_TYPE = '04'
                   GROUP BY CARD_LOGIC_ID)) PRODUCT
    LEFT JOIN ST_DAT_CARD_STATUS STATUS
      ON PRODUCT.CARD_LOGIC_ID = STATUS.CARD_LOGICAL_ID
   WHERE STATUS.CARD_LOGICAL_ID IS NULL) B
ON (A.FILE_NAME = B.FILE_NAME AND A.CARD_LOGIC_ID = B.CARD_LOGIC_ID AND A.TK_FEE = B.TK_FEE AND A.DEAL_DATETIME = B.DEAL_DATETIME)

WHEN NOT MATCHED THEN
  INSERT
  VALUES
    (SEQ_ST_ERR_TK_PRODUCT.NEXTVAL,
     B.ROW_ID,
     B.DEVICE_ID,
     B.DEAL_NO,
     B.ORDER_ID,
     B.DEAL_TYPE,
     B.OPERATOR_ID,
     B.REGISTER,
     B.CARD_MAIN_ID,
     B.CARD_SUB_ID,
     B.SAM_LOGICAL_ID,
     B.CARD_LOGIC_ID,
     B.CARD_PHYSICAL_ID,
     B.CARD_WHITE_COUNT,
     B.TEST_FLAG,
     B.TK_FEE,
     B.FOREGIFT,
     B.LOGOUT_COUNT,
     B.VALIDITY_PERIOD,
     B.DEAL_DATETIME,
     B.STATE,
     B.ACCOUNT_ID,
     B.SAM_ID,
     B.TK_BOX_ID,
     B.BATCH_ID,
     B.SQUAD_DAY,
     B.BALANCE_WATER_NO,
     B.FILE_ID,
     B.FILE_NAME,
     B.ERR_CODE,
     B.BALANCE_FLAG,
     B.ERR_MESSAGE);


--制票交易表（st_dat_tk_product），交易类型为（DEAL_TYPE）06，09,票卡类型不为0100的,插入制票交易异常表（ST_ERR_TK_PRODUCT）
MERGE INTO ST_ERR_TK_PRODUCT A
USING (SELECT ROW_ID,
              DEVICE_ID,
              DEAL_NO,
              ORDER_ID,
              DEAL_TYPE,
              OPERATOR_ID,
              REGISTER,
              CARD_MAIN_ID,
              CARD_SUB_ID,
              SAM_LOGICAL_ID,
              CARD_LOGIC_ID,
              CARD_PHYSICAL_ID,
              CARD_WHITE_COUNT,
              TEST_FLAG,
              TK_FEE,
              FOREGIFT,
              LOGOUT_COUNT,
              VALIDITY_PERIOD,
              DEAL_DATETIME,
              STATE,
              ACCOUNT_ID,
              SAM_ID,
              TK_BOX_ID,
              BATCH_ID,
              SQUAD_DAY,
              BALANCE_WATER_NO,
              FILE_ID,
              FILE_NAME,
              '52' ERR_CODE,
              '0' BALANCE_FLAG,
              '制票历史交易表，交易类型为：06、09，票卡类型为0100的数据' ERR_MESSAGE
         FROM ST_DAT_TK_PRODUCT
        WHERE BALANCE_WATER_NO = '2018103101'
          AND CARD_MAIN_ID != '01'
          AND CARD_SUB_ID != '00'
          AND DEAL_TYPE IN ('06', '09')) B
ON (A.FILE_NAME = B.FILE_NAME AND A.CARD_LOGIC_ID = B.CARD_LOGIC_ID AND A.TK_FEE = B.TK_FEE AND A.DEAL_DATETIME = B.DEAL_DATETIME)

WHEN NOT MATCHED THEN
  INSERT
  VALUES
    (SEQ_ST_ERR_TK_PRODUCT.NEXTVAL,
     B.ROW_ID,
     B.DEVICE_ID,
     B.DEAL_NO,
     B.ORDER_ID,
     B.DEAL_TYPE,
     B.OPERATOR_ID,
     B.REGISTER,
     B.CARD_MAIN_ID,
     B.CARD_SUB_ID,
     B.SAM_LOGICAL_ID,
     B.CARD_LOGIC_ID,
     B.CARD_PHYSICAL_ID,
     B.CARD_WHITE_COUNT,
     B.TEST_FLAG,
     B.TK_FEE,
     B.FOREGIFT,
     B.LOGOUT_COUNT,
     B.VALIDITY_PERIOD,
     B.DEAL_DATETIME,
     B.STATE,
     B.ACCOUNT_ID,
     B.SAM_ID,
     B.TK_BOX_ID,
     B.BATCH_ID,
     B.SQUAD_DAY,
     B.BALANCE_WATER_NO,
     B.FILE_ID,
     B.FILE_NAME,
     B.ERR_CODE,
     B.BALANCE_FLAG,
     B.ERR_MESSAGE);
