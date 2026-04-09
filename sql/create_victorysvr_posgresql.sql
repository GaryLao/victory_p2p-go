--start----------------------------------------云端服务器victorysvr------------------------------------------------------------------------
CREATE TABLE report_sum_data (  --aa
  id serial not null,
  report_name text,           --报表名称
  report_arrname text,        --数组变量名称
  report_arrdata text,        --数组内容

  reserve3 timestamp not null,

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (id)
);
create index report_sum_data_idx on report_sum_data (USER_ID,SHOPID,reserve3,report_name,report_arrname);

CREATE TABLE lock_qry
(
  ID serial,
  dbname varchar,
  stime timestamp DEFAULT date_trunc('second', NOW()),
  etime timestamp,
  query text,

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/

  PRIMARY KEY (id)
);

CREATE TABLE resv_data_upload  /*用于第三方预订账单同步，例如：“易订”*/
(
  ID BIGSERIAL NOT NULL,
  status integer,    --1:预订 2:入座 3:结账 4:退订 6:换台
  upload_data json,  --
  new_data json,     --新值
  
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/
  
  CONSTRAINT resv_data_upload_pkey PRIMARY KEY (id)
);

CREATE TABLE whole_checks_audit  --门店稽核看板
(
  RESERVE3 TIMESTAMP NOT NULL,          --稽核的日期
  audited integer DEFAULT 0 NOT NULL,   --是否已稽核 0=否 1=是
  cloud_total NUMERIC(15,3) DEFAULT 0,  --云端金额
  cloud_counts integer DEFAULT 0,       --云端账单数量
  shop_total NUMERIC(15,3) DEFAULT 0,   --门店金额
  shop_counts integer DEFAULT 0,        --门店账单数量

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  info_history json,         --记录历史账单统计 [{"datetime":"2022-08-01 01:01:01","cloud_total":0.00,"cloud_counts":0.00,"shop_total":0.00,"shop_counts":0.00}]  --lzm add 2022-08-10 05:24:47
  isbackup integer,          --是否已备份到backup表（目前只备份60天内的数据）  --lzm add 2022-08-10 05:24:53

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,RESERVE3)
);

CREATE TABLE whole_checks_odoo_orders  --根据门店销售单创建odoo销售单的记录表  --lzm add 2021-11-04 19:53:29
(
  RESERVE3 TIMESTAMP NOT NULL,             --账单日期
  status integer default 0,                --创建odoo账单状态 0=没创建 1=创建成功
  cloud_total NUMERIC(15,3) DEFAULT 0,     --创建odoo账单时的云端金额（用于判断是否需要更新销售单）
  cloud_counts integer DEFAULT 0,          --创建odoo账单时的云端账单数量（用于判断是否需要更新销售单）
  order_total json,                        --创建odoo账单的账单金额（用于判断是否需要更新销售单）     {"sale": 0.00, "scrapped": 0.00, "try": 0.00}
  order_itemcounts json,                   --创建odoo账单的账单商品行数（用于判断是否需要更新销售单） {"sale": 0.00, "scrapped": 0.00, "try": 0.00}
  order_itemqty json,                      --创建odoo账单的账单商品数量（用于判断是否需要更新销售单） {"sale": 0.00, "scrapped": 0.00, "try": 0.00}
  order_interface text,                    --创建odoo账单的接口信息
  order_data json,                         --创建odoo账单的数据      {}
  order_olddata json,                      --旧的创建odoo账单的数据  []

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,RESERVE3)
);

--start---------------------------------用于老板报表--------------------------------------------

CREATE TABLE whole_checks_report_time  --门店统计报表数据 --lzm add 2022-03-26 17:41:12
(
  id bigserial,
  RESERVE3 TIMESTAMP NOT NULL,              --日期

  time_0  numeric(15, 3)[],                 --时段0 [应收金额,实收金额,账单数量,就餐人数,折扣金额,品种折让金额,套餐折让金额]
  time_1  numeric(15, 3)[],                 --时段1
  time_2  numeric(15, 3)[],                 --时段2
  time_3  numeric(15, 3)[],                 --时段3
  time_4  numeric(15, 3)[],                 --时段4
  time_5  numeric(15, 3)[],                 --时段5
  time_6  numeric(15, 3)[],                 --时段6
  time_7  numeric(15, 3)[],                 --时段7
  time_8  numeric(15, 3)[],                 --时段8
  time_9  numeric(15, 3)[],                 --时段9
  time_10 numeric(15, 3)[],                 --时段10
  time_11 numeric(15, 3)[],                 --时段11
  time_12 numeric(15, 3)[],                 --时段12
  time_13 numeric(15, 3)[],                 --时段13
  time_14 numeric(15, 3)[],                 --时段14
  time_15 numeric(15, 3)[],                 --时段15
  time_16 numeric(15, 3)[],                 --时段16
  time_17 numeric(15, 3)[],                 --时段17
  time_18 numeric(15, 3)[],                 --时段18
  time_19 numeric(15, 3)[],                 --时段19
  time_20 numeric(15, 3)[],                 --时段20
  time_21 numeric(15, 3)[],                 --时段21
  time_22 numeric(15, 3)[],                 --时段22
  time_23 numeric(15, 3)[],                 --时段23
  
  --subtotal NUMERIC(15,3) DEFAULT 0,         --应收金额
  --ftotal NUMERIC(15,3) DEFAULT 0,           --实收金额
  --counts integer DEFAULT 0,                 --账单数量
  --partysize integer DEFAULT 0,              --就餐人数
  --amtdiscount NUMERIC(15,3) DEFAULT 0,      --直接折扣金额
  --presentdiscount NUMERIC(15,3) DEFAULT 0,  --普通品种折让金额
  --tcdiscount NUMERIC(15,3) DEFAULT 0,       --套餐折让金额

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,RESERVE3)
);

CREATE TABLE whole_checks_report_anomaly  --门店账单异常报表数据 --lzm add 2022-03-26 17:41:12
(
  RESERVE3 TIMESTAMP NOT NULL,              --日期

  counts integer DEFAULT 0,                 --账单异常数量
  amounts numeric(15, 3) default 0,         --实际减少金额

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,RESERVE3)
);

CREATE TABLE whole_checks_report_itemanomaly  --门店品种异常报表数据 --lzm add 2022-03-26 17:41:12
(
  RESERVE3 TIMESTAMP NOT NULL,              --日期

  voidchecks_counts integer DEFAULT 0,      --退单数量
  voiditem_counts integer DEFAULT 0,        --退菜数量
  changeitem_counts integer DEFAULT 0,      --改价品种数量
  present_counts integer DEFAULT 0,         --赠送数量
  loss_counts integer DEFAULT 0,            --损耗数量

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,RESERVE3)
);
--end-----------------------------------用于老板报表--------------------------------------------

--start---------------------------------用于厨房KDS划单和绩效--------------------------------------------
CREATE TABLE kichen_performance
(
  ID bigserial,
  
  DOCGLOBALNUM INTEGER,                   --全局唯一打印编号,每个打印单一个编号
  PRINTDOCBILLNUM VARCHAR(100),           --对应的顾客帐单编号 GUID
  
  dept_code varchar(100),                 --档口(部门)(逻辑打印机)号
  dept_name varchar(100),                 --档口(部门)(逻辑打印机)名称
  emp_code varchar(40),                   --员工号
  emp_name varchar(40),                   --员工名称
  empclass_code varchar(40),              --员工类别号
  empclass_name varchar(40),              --员工类别名称
  
  --duration_value numeric(15,2),          --时长  
  duration_stime timestamp,               --开始时间
  duration_etime timestamp,               --结束时间
  
  insert_time timestamp default now(),    --插入时间
  modify_time timestamp default now(),    --更新时间
  
  --menuitemid text,                      --品种编号
  --menuitemname text,                    --品种名称
  --menuitemqty numeric(15,2),            --品种数量
  --menuitemamounts numeric(15,2),        --品种金额
  menuitems json,                         --品种json记录 
                                          /*[{
                                            "id":"品种编号", 
                                            "checkid":"单号", 
                                            "lineid":"行号", 
                                            "koutcode":"对应chkdetail的koutcode", 
                                            "orgname":"原始名称", 
                                            "aname":"名称", 
                                            "qty": "数量", 
                                            "amounts":"金额",
                                            "kickback":"提成金额"
                                          }, ...]
                                          */
  
  checkid integer,                        --单号
  reserve3 timestamp,                     --账单归属日期
  koutcode integer,                       --对应chkdetail的koutcode
  
  primary key (id)
);

CREATE TABLE kichen_screen_rec           --划单记录
(
  ID bigserial,
  bill_no varchar(50),                   --账单号
  terminal_code varchar(20),             --终端号
  terminal_flag varchar(20),             --终端标记
  IsSend varchar(20),                    --是否已发送  0=否 1=是
  IsOper varchar(20),                    --是否已操作  0=否 1=是
  isPrint varchar(20),                   --是否已打印  0=否 1=是
  dishes_qty numeric(15,2),              --点单数量
  out_qty numeric(15,2),                 --已划单的数量
  send_times int,                        --发送时间
  oper_times int,                        --操作时间
  input_time datetime,                   --当前记录的时间
  station_code varchar(20),              --基站编号
  station_name varchar(20),              --基站名称
  offline_times int,                     --离线时间
  IsSend_Upload int,                     --
  IsOper_Upload int,                     --
  query_time datetime,                   --
  send_time datetime,                    --
  send_cgtime datetime,                  --
  
  primary key (id)
);
--end-----------------------------------用于厨房KDS划单和绩效--------------------------------------------

CREATE TABLE erp_purchasetemplate        /*门店下单模版 lzm add 2019-06-13 02:21:24*/
(
  id integer not null,                     /*ID*/
  act_code VARCHAR(40) NOT NULL,           /*模板编号*/
  act_name VARCHAR(200) NOT NULL,          /*模板名称*/
  --voucher_itemName VARCHAR(200) NOT NULL,       /*品种名称*/
  --voucher_type VARCHAR(40) NOT NULL,            /*模板类型*/
  --original_price NUMERIC(15,3) DEFAULT 0,       /*品种原价*/
  act_timetype integer default 0,          /*时段类型 0=连续 1=间隔*/
  act_use integer default 1,               /*是否启用模板(1=启用，0=停用)*/
  act_date_start varchar default '',       /*模板开始日期*/
  act_date_end varchar default '',         /*模板结束日期*/
  act_time_start varchar default '',       /*模板开始时间*/
  act_time_end varchar default '',         /*模板结束时间*/
  act_vip integer default 0,               /*会员专属 0=否 1=是*/
  act_week varchar(40) default '',         /*星期限定 (格式:1,2,3,4,5,6,7 多个时用逗号","分隔) */
  act_describe varchar(200) default '',    /*模板描述*/
  act_memo varchar(200) default '',        /*模板备注*/
  act_type integer default 0,              /*模板类型 0=ERP下单 1=蛋糕下单 2=盘点 3=月饼 4=生产入库 5=调货*/
  act_rule json,                           /*模板规则
  {
      "rule_mooncake": {
          "ordernum": {
              "limit": {
                  "min": "",  --月饼的订购单号：最小号码
                  "max": ""   --月饼的订购单号：最大号码
              }
          },
          "roundoff":{
              "limit":{
                  "max": ""   --去零头的上限
              }
          },
          "stock":{
              "date":{
                  "min": "",  --存量统计的开始日期
                  "max": ""   --存量统计的结束日期
              }
          }
      }
  }
                                           */

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',
  sale_type VARCHAR(60) DEFAULT '',        /*销售类型 lzm add 2020-08-03 20:45:06*/

  PRIMARY KEY (id)
);

CREATE TABLE erp_purchasetemplate_shops /*门店下单模板-关联门店*/
(
  id integer not null,
  act_id integer not null,               /*营销模板的ID*/
  shopcode varchar(40),                  /*特卖门店编号*/
  shopname varchar(100),                 /*特卖门店名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',     --act_id模板所属的token

  PRIMARY KEY (id)
);

CREATE TABLE erp_purchasetemplate_miclass
(
  "id" int4 NOT NULL,  --填入的是 webmiclass_id
  "sortorder" int4 DEFAULT 0,
  "pmiclassid" int4,    --对应父类的webmiclass_id
  "miclasstype" int4 DEFAULT 0,
  "miclassname" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "miclassnameen" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "picturefile" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "picturefilemobile" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "miclassdescription" text COLLATE "pg_catalog"."default" DEFAULT ''::text,
  "user_id" int4 NOT NULL,
  "shopid" varchar(40) COLLATE "pg_catalog"."default" NOT NULL DEFAULT ''::character varying,
  "showsize_pic" int4 NOT NULL DEFAULT 0,    --首页图片显示尺寸 0=小 1=中 2=大 lzm add 2019-02-24 16:12:32

  act_id integer not null,               --门店下单模板的ID
  token varchar(60) DEFAULT '',          --act_id模板所属的token
  "webmiclass_id" int4,                  --类别ID

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/
  micvisibled integer DEFAULT 1,                --是否显示
  parentmiclass integer DEFAULT 0,              --顶层类别id
  odoo_company_id integer DEFAULT 0,            --配送中心id
  odoo_company_name VARCHAR(250) DEFAULT '',    --配送中心名称
  odoo_warehouse_id integer DEFAULT 0,          --配送中心仓库id（一个配送中心可以对应多个仓库）
  odoo_warehouse_name VARCHAR(250) DEFAULT '',  --配送中心仓库名称（一个配送中心可以对应多个仓库）

  sale_type VARCHAR(60) DEFAULT '',        /*销售类型 lzm add 2020-08-03 20:45:06*/

  PRIMARY KEY ("id","webmiclass_id","user_id","shopid","act_id")
);
ALTER TABLE "public"."erp_purchasetemplate_miclass" 
  DROP CONSTRAINT "erp_purchasetemplate_miclass_pkey",
  ALTER COLUMN "webmiclass_id" SET NOT NULL,
  ADD CONSTRAINT "erp_purchasetemplate_miclass_pkey" PRIMARY KEY ("id", "webmiclass_id", "user_id", "shopid");

--delete from erp_purchasetemplate_miclass where user_id=293 and act_id=7;
  insert into erp_purchasetemplate_miclass(
    id
    ,webmiclass_id
    ,user_id
    ,shopid
    ,token
    ,act_id
    ,miclassname
    ,sortorder
    ,pmiclassid
    ,parentmiclass
    ,micvisibled
    
    ,odoo_company_id,odoo_warehouse_id,odoo_company_name,odoo_warehouse_name
    )    
    select 
      id
      ,webmiclass_id
      ,user_id
      ,shopid
      ,'josxrn1539671593'
      ,7
      ,miclassname
      ,sortorder
      ,pmiclassid
      ,parentmiclass
      ,micvisibled
      
      ,odoo_company_id,odoo_warehouse_id,odoo_company_name,odoo_warehouse_name    
    from erp_purchasetemplate_miclass
    where user_id=293 and act_id=2;


CREATE TABLE erp_purchasetemplate_midetail
(
  "id" int4 NOT NULL,         --填入的是odoo的 product_id
  "webmiclass_id" int4 NOT NULL,
  "miclassname" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "sortorder" int4 DEFAULT 0,
  "miname" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "minameen" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "mitype" int4 DEFAULT 0,
  "miprice" numeric(15,6) DEFAULT 0,
  "picturefilesmall" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "picturefilebig" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "picturefilesmallmobile" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "picturefilebigmobile" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "micountwords" int4 DEFAULT 0,
  "mipinyin" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "miunitname" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "midescription" text COLLATE "pg_catalog"."default" DEFAULT ''::text,
  "balanceprice" varchar(250) COLLATE "pg_catalog"."default" DEFAULT ''::character varying,
  "balanceisfix" int4 DEFAULT 0,
  "groupid" int4 DEFAULT 0,
  "ishot" int4 DEFAULT 0,       --热卖
  "isspecials" int4 DEFAULT 0,  --特价
  "user_id" int4 NOT NULL,
  "shopid" varchar(40) COLLATE "pg_catalog"."default" NOT NULL DEFAULT ''::character varying,
  "isopen" int4 DEFAULT 1,
  "nodiscount" int4 NOT NULL DEFAULT 1,
  "web_tag" int4 NOT NULL DEFAULT 1,        --微信预下单品种 0=否 1=是 lzm add 2019-01-09 23:43:19
  "webchat_tag" int4 NOT NULL DEFAULT 1,    --微信点单品种 0=否 1=是 lzm add 2019-01-09 23:43:19
--  "showsize_smallmobile" int4 NOT NULL DEFAULT 0,    --小图显示尺寸 0=小 1=中 2=大 lzm add 2019-02-14 00:12:34
--  "showsize_bigmobile" int4 NOT NULL DEFAULT 0,      --大图显示尺寸 0=小 1=中 2=大 lzm add 2019-02-14 00:12:34
  "showsize_pic" int4 NOT NULL DEFAULT 0,    --首页图片显示尺寸 0=小 1=中 2=大 lzm add 2019-02-24 16:12:32
  "isrecommend" int4 DEFAULT 0,      --商家推荐 lzm add 2019-02-25 23:26:59
  "levelrecommend" int4 DEFAULT 0,   --推荐指数 lzm add 2019-02-25 23:26:59
  "titlerecommend" VARCHAR(20) DEFAULT '',  --特卖标题 lzm add 2019-02-28 18:50:37

  act_id integer not null,               --门店下单模板的ID
  token varchar(60) DEFAULT '',          --act_id模板所属的token
  odoo_code text,                        --OdooERP的商品default_code
  uom_id integer,                        --单位id
  product_id integer,                    --odoo的产品id
  product_tmpl_id integer,               --odoo的产品模板id

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  week1_shipping_days integer default 0,  --星期一下单多少天后发货 0或空=未指定
  week2_shipping_days integer default 0,  --星期二下单多少天后发货 0或空=未指定
  week3_shipping_days integer default 0,  --星期三下单多少天后发货 0或空=未指定
  week4_shipping_days integer default 0,  --星期四下单多少天后发货 0或空=未指定
  week5_shipping_days integer default 0,  --星期五下单多少天后发货 0或空=未指定
  week6_shipping_days integer default 0,  --星期六下单多少天后发货 0或空=未指定
  week7_shipping_days integer default 0,  --星期日下单多少天后发货 0或空=未指定
  mi_week varchar(40) default '',         /*星期限定 (格式:1,2,3,4,5,6,7 多个时用逗号","分隔) */

  uom_reference_id integer,               --基本单位id，用于查看uom_id是否基本计量单位  --lzm add 2020-06-14 05:12:40
  micost numeric(15,6) DEFAULT 0,         --成本 --lzm add 2020-06-30 18:11:49
  mistock numeric(15,6) DEFAULT NULL,     --存量 --lzm add 2020-09-09 15:15:18

  midetail_min_qty numeric(15,6) DEFAULT NULL,       --最小下单量，如果为NULL从Odoo获取最小下单数量 --lzm add 2020-12-29 16:56:13
  midetail_multipl_qty varchar(40) DEFAULT NULL,     --下单倍数，如果为NULL从Odoo获取下单倍数 --lzm add 2021-10-28 14:24:49
  midetail_max_qty numeric(15,6) DEFAULT NULL,       --最高下单量，如果为NULL从Odoo获取order_qty_max_times最高下单数量 --lzm add 2024-01-23 13:56:43

  PRIMARY KEY ("id","webmiclass_id","user_id","shopid","act_id")
);
ALTER TABLE "public"."erp_purchasetemplate_midetail" 
  DROP CONSTRAINT "erp_purchasetemplate_midetail_pkey",
  ADD CONSTRAINT "erp_purchasetemplate_midetail_pkey" PRIMARY KEY ("id", "webmiclass_id", "user_id", "shopid");

alter table erp_purchasetemplate_midetail add week1_shipping_days integer default 0;  --星期一下单多少天后发货
alter table erp_purchasetemplate_midetail add week2_shipping_days integer default 0;  --星期二下单多少天后发货
alter table erp_purchasetemplate_midetail add week3_shipping_days integer default 0;  --星期三下单多少天后发货
alter table erp_purchasetemplate_midetail add week4_shipping_days integer default 0;  --星期四下单多少天后发货
alter table erp_purchasetemplate_midetail add week5_shipping_days integer default 0;  --星期五下单多少天后发货
alter table erp_purchasetemplate_midetail add week6_shipping_days integer default 0;  --星期六下单多少天后发货
alter table erp_purchasetemplate_midetail add week7_shipping_days integer default 0;  --星期日下单多少天后发货

--delete from erp_purchasetemplate_midetail where user_id=293 and act_id=7;
  insert into erp_purchasetemplate_midetail(
    id
    ,webmiclass_id
    ,user_id
    ,shopid
    ,token
    ,act_id
    ,miclassname
    ,sortorder

    ,miname
    ,mitype
    ,miprice
    ,odoo_code
    ,uom_id
    ,miunitname
    ,product_id
    ,product_tmpl_id
    
    )    
    select 
      id
      ,webmiclass_id
      ,user_id
      ,shopid
      ,'josxrn1539671593'
      ,7
      ,miclassname
      ,sortorder

      ,miname
      ,mitype
      ,miprice
      ,odoo_code
      ,uom_id
      ,miunitname
      ,product_id
      ,product_tmpl_id

    from erp_purchasetemplate_midetail
    where user_id=293 and act_id=2;


--只用于400服务器
CREATE TABLE stocknum_order_product_queue(  --账单最后一个商品队列（用于判断是否账单的最后一个商品） --lzm add 2022-08-31 08:57:08
  ID    SERIAL,
  user_id INTEGER DEFAULT 0 NOT NULL,
  shopid  VARCHAR(40) DEFAULT '' NOT NULL,          --店编号
  shopguid VARCHAR(200),
  webbills_id integer default 0,
  product_id integer default 0,                     --商品id
  insert_date timestamp default now(),              --插入时间
  done_date timestamp,                              --完成时间
  state varchar(20),                                --状态 空或''=没处理 done=已处理完成
  extinfo json,

  PRIMARY KEY (id)
);
CREATE INDEX stocknum_order_product_queue_product_id_idx on stocknum_order_product_queue (user_id, shopid, product_id);
CREATE INDEX stocknum_order_product_queue_state_idx on stocknum_order_product_queue (user_id, shopid, state);

DROP Table erpcommon;
CREATE TABLE erpcommon
(
  ID    SERIAL,
  user_id INTEGER DEFAULT 0 NOT NULL,

  common_url text,                --erp的服务器的地址，如果不是80端口，则要包含端口
  common_db text,                 --数据库名称
  common_username text,           --odoo登录的用户名
  common_password text,           --odoo登录的密码

  common_odoo_billname text,      --在erp产生的账单的名称前缀
  common_login_name text,         --总部的工作人员的登录名称（目前没有使用）
  common_categ_name text,         --产品分类名称
  common_unit_categ_name text,    --计量单位分类名称

  common_odoo_ict_name text,      --ICT单据中使用，在erp产生的账单的名称前缀（ICT）

  common_dbip VARCHAR(40),        --数据库ip地址 --lzm add 2020-06-17 17:23:42
  common_dbport integer,          --数据库端口 --lzm add 2020-06-17 17:23:42
  common_dbuser VARCHAR(40),      --数据库登陆用户 --lzm add 2020-06-17 17:23:42
  common_dbpwd VARCHAR(40),       --数据库登陆密码 --lzm add 2020-06-17 17:23:42

  mooncake_warehouse_id integer DEFAULT 0,  --月饼的仓库id --lzm add 2020-08-04 12:35:01

  PRIMARY KEY (ID)
);
--insert into erpcommon(user_id,common_url,common_db,common_username,common_password,common_odoo_billname,common_login_name,common_categ_name,common_unit_categ_name) 
--  values('293','https://erp.4080518.com','yperp','yproot','ypqazQAZ','POS/','yproot','POS','POS');

insert into erpcommon(user_id,common_url,common_db,common_username,common_password,common_odoo_billname,common_login_name,common_categ_name,common_unit_categ_name,common_odoo_ict_name) 
  values('293','https://erp.4080518.com','yperp','yippeewave@gmail.com','ypqazQAZ9009','POS','yippeewave@gmail.com','POS','POS','ICT');

INSERT INTO "erpcommon"("id", "user_id", "common_url", "common_db", "common_username", "common_password", "common_odoo_billname", "common_login_name", "common_categ_name", "common_unit_categ_name", "common_odoo_ict_name") 
    VALUES (1, 293, 'http://bluebird.4080518.com', 'ypbluebird', '001@bluebird.com', '123456', 'POS', '', 'POS', 'POS', 'ICT');


DROP Table erpconfig;
CREATE TABLE erpconfig
(
  ID    SERIAL,
  user_id INTEGER DEFAULT 0 NOT NULL,
  --token text default '',
  --wecha_id text default '',
  shopid  VARCHAR(40) DEFAULT '' NOT NULL,                        /*店编号*/
  shopguid VARCHAR(200) DEFAULT '' NOT NULL, 

  shop_warehouse_name           text, --仓库名称---门店
  shop_warehouse_location_name  text, --仓库库位---门店
  shop_login_name               text, --分店的工作人员，在erp中的登录用户名（目前没有使用）
  shop_partner_name             text, --销售单中使用，销售单的客户名
  shop_source_name              text, --ICT单据中使用，公司间调拨的源店名-----加工中心
  shop_destination_name         text, --ICT单据中使用，公司间调拨的目标店名---门店
  
  categ_id                      text, --产品的分类id(自动从erp获取)
  weight                        text, --缺省重量(自动从erp获取)
  location_id                   text, --仓库位置id(自动从erp获取)
  location_dest_id              text, --客户位置id(自动从erp获取)
  picking_type_id               text, --单据的类型id(自动从erp获取)
  uom_id                        text, --单位的id（产品定义中缺省的计量单位）(自动从erp获取)
  uom_po_id                     text, --单位的id（产品定义中缺省的计量单位-购买时的计量单位）(自动从erp获取)
  product_uom                   text, --单位的id(单据的明细商品的定义中)(自动从erp获取)

  shop_warehouse_id             integer DEFAULT 0, --仓库id---门店
  shop_warehouse_location_id    integer DEFAULT 0, --仓库库存的位置id---门店
  shop_login_id                 integer DEFAULT 0, --分店的工作人员id，在erp中的登录用户名（目前没有使用）
  shop_partner_id               integer DEFAULT 0, --销售单中使用，销售单的客户名id
  shop_source_id                integer DEFAULT 0, --ICT单据中使用，公司间调拨的源公司id-----加工中心-company_id
  shop_destination_id           integer DEFAULT 0, --ICT单据中使用，公司间调拨的目标公司id---门店-company_id

  shop_role_name                text,              --用户角色名称---门店
  shop_role_id                  integer DEFAULT 0, --用户角色id  ---门店

  not_inv_stock_to_zero         integer default 0, --没有盘点的商品系统自动在凌晨设置库存为零 --lzm add 2021-11-30 19:13:40
  shop_mo_need_check            integer default 0, --生产入库单需要检测原材料的库存 --lzm add 2022-02-14 14:54:05
  shop_erporders_invisible      integer default 0, --在400平台的ERP库存订单管理隐藏 --lzm add 2022-02-20 03:24:30
  deduct_inv_from_shopchecks    integer default 0, --根据门店销售单扣Odoo库存 --lzm add 2022-06-08 19:55:14

  PRIMARY KEY (ID)
);

insert into erpconfig(USER_ID,SHOPID,SHOPGUID,shop_warehouse_name,shop_warehouse_location_name,shop_login_name,shop_partner_name,shop_source_name,shop_destination_name) 
  values(293,'002','天母蓝鸟烘焙塘厦仟百汇店_HB-TXQBHD1_HAMTCB340150000','ZC','库存','2528303388@qq.com','','','');

insert into erpconfig(USER_ID,SHOPID,SHOPGUID,shop_warehouse_name,shop_warehouse_location_name,shop_login_name,shop_partner_name,shop_source_name,shop_destination_name) 
  values(293,'003','天母蓝鸟烘焙南城彩怡店_HB-NCCYD1_HIGHX1611XT50744','ZC','库存','133002898@qq.com','','','');

--end---------------------------------------云端服务器victorysvr----------------------------------------------------------------------

CREATE TABLE web_midetail_stock /*品种的沽清信息 用于web点单 和 [限制负库存销售时，可以负库存销售的品种沽清 lzm add 2023-04-16 02:00:36]*/
(
  menuitemid integer NOT NULL,
  stocknum numeric(15,3) DEFAULT 0,  /*存量*/

--  STOCKORI NUMERIC(15,3) DEFAULT 0,  /*存量原始值 lzm add 2016-03-01*/
--  STOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),        /*库存时间 lzm add 2016-03-01*/
--  WEBCHAT_SYNCSTOCKNUM NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量 lzm add 2016-03-01*/
--  WEBCHAT_SYNCSTOCKORI NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量原始值 lzm add 2016-03-01*/
--  WEBCHAT_SYNCSTOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()), /*Web订餐(微信) 同步库存时间 lzm add 2016-03-01*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  CONSTRAINT web_midetail_stock_pkey PRIMARY KEY (menuitemid)
);

CREATE TABLE webbills
(
  id serial NOT NULL,
  shopuuid varchar(250) NOT NULL,
  billuuid varchar(250) NOT NULL,
  email varchar(250) NOT NULL,                          /*
                                                          billtype=1 餐台预订时: --lzm add 2023-12-17 18:37:35
                                                            {
                                                              "provider": "zhidianfan"  --"zhidianfan":代表易订网
                                                            }
                                                            
                                                          billtype=6 (美团外卖)时: 接口类型 --lzm add 2021-05-17 02:54:12
                                                            空 或 meituan = 美团官方接口,
                                                            candao = 餐道接口

                                                          billtype=7 (ERP下单)时: 
                                                            otorder = 加单
                                                          
                                                          billtype=20（web message）时 --lzm add 2021-12-01 14:50:29
                                                            {
                                                              "substype":"1=呼叫服务员 2=斟茶倒水 3=前店后厂的生产入库通知 4=商城订单打印",
                                                              "print":1,
                                                              "sendmsg":0
                                                            }
                                                        */
  address varchar(250) DEFAULT '',                      --顾客地址（微外卖）；美团外卖：收货人地址
  telphone varchar(250) DEFAULT '',                     --顾客电话（微外卖）；美团外卖：收货人电话
  mobilephone varchar(250) DEFAULT '',                  --顾客手机（微外卖）；美团外卖：骑手电话
  "name" varchar(250) DEFAULT '',                       --顾客姓名（微外卖）；美团外卖：收货人姓名；蛋糕顾客姓名
  "password" varchar(250) DEFAULT '',                   --楼面通员工登录账号 001@132[shopid@empid]  --lzm modify 2025-08-21 19:12:13
  gender varchar(250) DEFAULT '',                       --性别 1=男 0=女 美团外卖：退款信息类型notifyType：apply=发起退款；agree=确认退款；reject=驳回退款；cancelRefund=用户取消退款申请；cancelRefundComplaint=取消退款申诉
  addressid varchar(250) DEFAULT '',                    --其它：地址id； 美团外卖：1-用户已提交订单；2-可推送到App方平台也可推送到商家；4-商家已确认；6-已配送；8-已完成；9-已取消
  partysize varchar(250) DEFAULT '',                    --人数
                                                        --billtype=7 (ERP)  时：提交的次数

  bookingtime varchar(250) NOT NULL,                    --预订时间
  needinvoice varchar(250) DEFAULT '',                  --是否开发票；美团外卖：是否需要发票，0-不需要， 1-需要
  othercomment varchar(250) DEFAULT '',                 --顾客其它备注（微外卖、微信点餐的账单备注）；美团外卖：备注;
  otherphone varchar(250) DEFAULT '',                   --顾客其它电话（微外卖）；美团外卖：配送员电话
  invoicetitle varchar(250) DEFAULT '',                 --发票抬头；美团外卖：发票抬头
  billtotal varchar(250) DEFAULT '',                    --账单合计（品种小计-折扣+服务费后的金额）；美团外卖：订单总价，用户实际支付金额
  webbookingdeliveryfee varchar(250) DEFAULT '',        --小费金额（没有用到）
  webbookingdeliveryneedfee varchar(250) DEFAULT '',    --是否需要小费（没有用到）
  webcouponid varchar(250) DEFAULT '',                  --优惠券card_id
  webcouponnumber varchar(250) DEFAULT '',              --优惠券号码
  webcouponcouponname varchar(250) DEFAULT '',          --优惠券名称
  webcoupondiscountdefine varchar(250) DEFAULT '',      --优惠券付款的金额

  status varchar(250) DEFAULT '0',                      /*【用于门店PC上传处理状态】
                                                          -1=新账单
                                                          0或空=待处理（门店没接单）
                                                          1=正在处理（门店已接单）
                                                          2=已完成（已制作完成）
                                                          3=无效订单
                                                          4=超时没有处理
                                                        */

  intime timestamp without time zone DEFAULT date_trunc('second', now()),   --下单时间；美团外卖：推送时间
  toktime timestamp without time zone,                  --门店拉单时间 或 ERP提交成功的时间
  USER_ID INTEGER,                                      --集团登陆帐号ID
  tablecount varchar(250) DEFAULT '',                   --预订的桌台数量；美团外卖：菜品份数；堂食：0=先付款 1=后付款（门店POS手动清台） 2=后付款 的流程（门店"自动"清台）；
  acomment varchar(250) DEFAULT '',                     --预订的留言信息；
                                                        --billtype=4 (会员卡充值)：充值场景(outer_str)内容: 'qrc_shop'；
                                                        --billtype=6 (美团外卖)：取消原因；
                                                        --billtype=8 (蛋糕)：祝福语；
                                                        --billtype=10(抢购优惠券活动)：记录营销活动 MIDETAIL_CampaignActivity 的id，格式： act=id
                                                        --billtype=20(web message)：打印抬头
  billtype varchar(250) DEFAULT '',                     /*添加新类型时需要修改W:\Workspaces\YPWechatCMS\Apache24\htdocs\prnqrcpay_svr\webbills_notify.py的dblisten()
  
                                                          0:外卖订单                   --需要检查并设置超时
                                                          1:餐台预订
                                                          2:堂食即点单-扫码点餐(现金支付)        --需要检查并设置超时
                                                          3:暂无用途【之前:堂食即点单-扫码点餐(微信支付宝支付)】  --需要检查并设置超时
                                                          4:微信会员卡在线充值
                                                          5:堂食即点单-扫码点餐(微信支付宝和会员卡金额支付)【之前:码上付(微信支付宝支付)】     --需要检查并设置超时
                                                          6:美团外卖                   --需要检查并设置超时
                                                          7:ERPOrders(ERP下单)
                                                          8:ERP蛋糕下单
                                                          9:ERP盘点下单
                                                          10:抢购优惠券活动  --lzm add 2020-04-20 05:43:45
                                                          11:ERP月饼下单    --lzm add 2020-06-03 04:44:03
                                                          12:ERP生产入库    --lzm add 2021-11-30 01:57:30
                                                          13:ERP调货        --lzm add 2022-02-07 11:50:56
                                                          14:ERP领料        --lzm add 2022-08-22 02:19:17
                                                          15:ERP出库        --lzm add 2022-10-26 00:44:03
                                                          16:ERP入库        --lzm add 2022-10-26 00:44:07
                                                          20:web message   --lzm add 2021-12-01 14:19:02
                                                          21:商城订单       --lzm add 2022-09-20 21:44:06
                                                          22:自提           --需要检查并设置超时 --lzm add 2023-04-28 14:58:22
                                                          23:楼面通月饼订单    --lzm add 2025-08-16 19:19:38
                                                          24:YPOS[还没做，先保留]  --lzm add 2025-09-05 19:30:54
                                                          */
  fromuser varchar(250) DEFAULT '',                     --微信openid；美团外卖：事件类型 1:订单处理 2;退款处理 3:配送处理
  touser varchar(250) DEFAULT '',                       --集团登陆帐号token；
  confirmcode varchar(50) DEFAULT '',                   --校验码；美团外卖：订单Id
  tablename varchar(50) DEFAULT '',                     /*美团外卖：门店当天的订单流水号, 每天流水号从1开始; 
                                                          
                                                          billtype=7 (ERP)  时：正常单：tablename=erporders_sale   
                                                                                暂存单：tablename=erporders_savetemp  
                                                                                被删除的暂存单：tablename=erporders_savetemp_canceled
                                                          billtype=8 (蛋糕)  时：正常单：tablename=erporders_sale
                                                          billtype=9 (盘点)  时：正常单：tablename=erporders_sale --lzm add 2020-06-03 04:46:02
                                                          billtype=10 (抢购) 时：正常单：tablename=act_privilege_sale  --lzm add 2020-04-20 05:43:53
                                                          billtype=11（月饼）时：正常单：tablename=erporders_sale --lzm add 2020-06-03 04:46:02
                                                        */
  invalidreason varchar(200) DEFAULT '',                --作废原因
  ordertime varchar(50) DEFAULT '',                     --预订时间
  shopid  varchar(40) DEFAULT '',                       --门店编号
  wxordernum text DEFAULT '',                           --账单下单编号（用于支付宝微信的订单号）
  consumerAccount text default '',                      --顾客信息
  tofraction varchar(50) default '',                    --进位差额；美团外卖：配送费
  subtotal varchar(50) default '',                      --账单小计（品种金额的合计不包括折扣和服务费）
  wxcard_code text default '',                          --微信会员卡号
  token text default '',                                --集团登陆帐号token
  wecha_id text default '',                             --微信openid
  priceactually text default '',                        --付款金额
                                                          --billtype=9:盘点 保存Odoo返回的处理信息
                                                          --billtype=12:生产入库 保存Odoo返回的处理信息

  pricegive text default '',                            --送的金额
  card_id text default '',                              --微信会员card_id
  confirmaddto text default '',                         --是否已成功累计积分或成功充值到卡（避免重复记录） 0或空=否 1=成功； 
                                                          --美团外卖：订单展示Id
                                                          --billtype=7 (ERP)  时：1=已处理
                                                          --billtype=9:盘点 0=没处理 1=已处理
                                                          --billtype=12:生产入库 0=没处理 1=已处理
  mccode text,                                          --用于socket门店推送的uuid lzm add 2018-04-11 03:16:24
  hqbillguid text,                                      --lzm add 2018-04-30 16:05:28 
                                                          --当billtype=20:web message 相关连的生产入库单，例如： [3851721]生产入库单

  meituan_developerid text,                             --美团开发者ID lzm add 2018-07-23 03:55:49
  meituan_epoiid text,                                  --美团门店ID lzm add 2018-07-23 03:55:49
  meituan_sign text,                                    --美团数字签名 lzm add 2018-07-23 03:55:49
  meituan_order json,                                   --美团订单明细 lzm add 2018-07-23 03:55:49
  meituan_shipping json,                                --美团配送状态 lzm add 2018-07-24 01:22:36
  meituan_orderrefund json,                             --美团全部退款信息 lzm add 2018-07-24 01:22:36
  meituan_partorderrefund json,                         --美团部分退款信息 lzm add 2018-07-24 01:22:36

  sendedmsg integer default 0,                          --是否已发送通知 lzm add 2019-04-11 07:03:41

  source_warehouse_id integer default 0,                --ERP下单 发出仓 lzm add 2019-08-05 17:20:48
  destination_warehouse_id integer default 0,           --ERP下单 收到仓 lzm add 2019-08-05 17:20:52

  terminalid text,                                      --终端设备码

--  memberScoreCard_id varchar(250) DEFAULT '',         --积分兑换的会员卡card_id
--  memberScoreCardCode varchar(250) DEFAULT '',        --积分兑换的会员卡号
--  memberScoreCardTitle varchar(250) DEFAULT '',       --积分兑换的会员卡名称
--  memberScoreExchangePay varchar(250) DEFAULT '',     --积分兑换的金额
--  memberScorePay varchar(250) DEFAULT '',             --要兑换的积分

  bookingshopfrom varchar(40) default '',               --蛋糕：母店编号 例如 001
  delytime timestamp,                                   --蛋糕配送出车时间
  delydriver json,                                      --蛋糕配送车辆和司机信息{"licenseplate":"","driver":"","mobile":""}
  process_sortorder integer default 0,                  --用于odoo创建申购单，处理顺序，避免数据有错误导致之后的无法处理  --lzm add 2020-03-29 02:46:19
  preceived_status text default '',                     --用于odoo收货，0或空=没进行收货处理 1=正在处理 2=已完成 --lzm add 2020-03-29 01:53:32
  preceived_sortorder integer default 0,                --用于odoo收货，处理顺序，避免数据有错误导致之后的无法处理  --lzm add 2020-03-29 02:46:19

  createtime timestamp without time zone DEFAULT date_trunc('second', now()),   --创建时间  --lzm add 2020-04-07 13:21:14
  modifytime timestamp without time zone DEFAULT date_trunc('second', now()),   --修改时间  --lzm add 2020-04-13 14:17:23

  preceived_type text default '',                       --用于odoo收货，''或空=人工收货 auto=自动收货 --lzm add 2020-03-29 01:53:32
  mooncakeinfo json,                                    /*
                                                        billtype=9 (月饼)            时：用于保存盘点订单的信息  --lzm add 2022-01-17 00:20:59
                                                        billtype=11 (月饼)           时：用于保存月饼订单的信息  --lzm add 2020-06-24 05:24:24
                                                        billtype=12 (生产入库)       时：用于保存订单扩展的信息  --lzm add 2022-01-14 00:20:11
                                                        billtype=23 (楼面通月饼订单)  时：{"discountdefine":"6=6折 0.05=9.5折 5%=9.5折"}  --lzm add 2025-08-20 21:19:34
                                                        */
  
  auto_sendedmsg integer default 0,                     --是否已自动发送通知 0=否 1=是 -1=系统繁忙，此时请开发者稍后再试 lzm add 2020-09-18 03:54:47
  auto_sendedres TEXT DEFAULT '',                       --自动发送信息的返回结果 lzm add 2020-09-18 03:54:47
  wxordernum_old text,                                  --之前的支付订单号 lzm add 2023-02-11 01:45:08


  CONSTRAINT webbills_pkey PRIMARY KEY (id)
);
create UNIQUE index webbills_billuuid_idx on webbills (billuuid)
create UNIQUE index webbills_confirmcode_idx on webbills (user_id,shopid,billtype,date_trunc('day', createtime),confirmcode) WHERE (confirmcode IS NOT NULL AND confirmcode <> '');

alter table webbills add preceived_type text default '';

alter table whole_webbills add process_sortorder integer default 0;
alter table whole_webbills add preceived_status text default '';
alter table whole_webbills add preceived_sortorder integer default 0;
alter table whole_webbills add createtime timestamp without time zone DEFAULT date_trunc('second', now());
alter table whole_webbills add modifytime timestamp without time zone DEFAULT date_trunc('second', now());
alter table whole_webbills add preceived_type text default '';


CREATE TABLE webbilldetail
(
  id serial NOT NULL,
  webbills_id integer NOT NULL,
  shopuuid varchar(250) NOT NULL,
  billuuid varchar(250) NOT NULL,
  menuitemid integer NOT NULL,
  miunitname varchar(250) DEFAULT '',
  midescription varchar(250) DEFAULT '',
  miclassid integer DEFAULT 0,
  miclassname varchar(250) DEFAULT '',
  counts numeric(15,3) DEFAULT 0,
  miprice numeric(15,3) DEFAULT 0,
  subtotal numeric(15,3) DEFAULT 0,
  couponnumber varchar(250) DEFAULT '',
  discountdefine varchar(250) DEFAULT '',   --这里记录的是折扣名称
  discounttotal numeric(15,3) DEFAULT 0,
  total numeric(15,3) DEFAULT 0,
  miname varchar(250) DEFAULT '',
  mitype integer DEFAULT 0,
  plineid integer DEFAULT 0,
  groupid integer DEFAULT 0,
  USER_ID INTEGER,
  shopid  varchar(40) DEFAULT '',
  lineid integer DEFAULT 0,           --行号
  lineid_parent integer DEFAULT 0,    --母亲行号，用于套餐

  miunitid integer DEFAULT 0,                       --odoo  单位编号id
  odoo_company_id integer DEFAULT 0,                --odoo  加个中心ID
  odoo_company_name VARCHAR(250) DEFAULT '',        --odoo  加工中心名称
  odoo_warehouse_id integer DEFAULT 0,              --odoo  加个中心对应的仓库ID
  odoo_warehouse_name VARCHAR(250) DEFAULT '',      --odoo  加个中心对应的仓库名称
  odoo_intime_planned timestamp without time zone,  --odoo  预收货时间 lzm add 2019-08-05 17:20:52  --default date_trunc('second', now())

  qty_received numeric(15,3) default 0,             /*
                                                    billtype=7 (ERPOrders)：ERP收货数量；
                                                    billtype=8 (蛋糕)：蛋糕收货数量
                                                    */
  reason_undelivered varchar(250),                  /*
                                                    billtype=7 (ERPOrders)：没收原因；
                                                    billtype=8 (蛋糕)：蛋糕被总店取消的原因 或 蛋糕被门店拒收的原因；
                                                    */
  status varchar(40),                               /*蛋糕订单的状态：
                                                        draft=草稿
                                                        NULL或空字符串=待接單,--------------流程0
                                                        canceled=訂單取消(填寫取消原因)-----流程0.1
                                                        accept=已接單（预留）
                                                        waitprove=待审批（预留）
                                                        proved=已审批（预留）
                                                        production=生產中------------------流程1------打印小票
                                                        prodcomplete=生成完成--------------流程2------输入技师编号
                                                        waitdeliver=待配送（预留）
                                                        delivery=已送貨--------------------流程3------打印小票
                                                        shop_fulfilled=已收貨(門店)
                                                        shop_reject=異常拒收(門店,填寫拒收原因)
                                                        overtime=逾期

                                                      billtype=7 (ERPOrders)：
                                                        stock_picking_notfound=收货单没有该商品
                                                    */
  qty_reject numeric(15,3) default 0,               --拒收数量
  worker varchar(100),                              --蛋糕技师
  wcomptime timestamp,                              --蛋糕完成时间
  delytime timestamp,                               --蛋糕配送出车时间
  delydriver json,                                  --蛋糕配送车辆和司机信息{"licenseplate":"","driver":"","mobile":""}
  process_status text default '',                   --用于odoo创建申购单，是否已处理成功 0或空=否 1=成功 --lzm add 2020-03-29 01:53:32
  process_sortorder integer default 0,              --用于odoo创建申购单，处理顺序，避免数据有错误导致之后的无法处理  --lzm add 2020-03-29 02:46:19
  preceived_status text default '',                 --用于odoo收货，是否已处理成功 0或空=没进行收货处理 1=正在处理 2=已完成 --lzm add 2020-03-29 01:53:32
  preceived_sortorder integer default 0,            --用于odoo收货，处理顺序，避免数据有错误导致之后的无法处理  --lzm add 2020-03-29 02:46:19

  createtime timestamp without time zone DEFAULT date_trunc('second', now()),   --创建时间  --lzm add 2020-04-07 13:21:14
  modifytime timestamp without time zone DEFAULT date_trunc('second', now()),   --修改时间  --lzm add 2020-04-13 14:17:23

  qty_received_auto numeric(15,3) default 0,            /* 自动收货数量  lzm add 2020-04-24 20:58:18 */
  qty_received_autodt timestamp without time zone,      /* 自动收货时间  lzm add 2020-04-24 20:58:18 */
  qty_received_manual numeric(15,3) default 0,          /* 人工收货数量  lzm add 2020-04-24 20:58:18 */
  qty_received_manualdt timestamp without time zone,    /* 人工收货时间  lzm add 2020-04-24 20:58:18 */

  micost numeric(15,6) DEFAULT 0,                    --成本 lzm add 2020-07-01 03:08:03
  sale_type VARCHAR(60) DEFAULT '',                  --销售类型 lzm add 2020-08-03 21:39:14

  miservicename varchar(250) DEFAULT '',           --服务费名称  --lzm add 2021-01-28 13:21:13
  miservicecarge numeric(15,3) DEFAULT 0,          --服务费金额  --lzm add 2021-01-28 13:21:13
  
  miname_org varchar(250) DEFAULT '',              --品种原始名称（没包含附加信息）  --lzm add 2025-11-23 12:15:15
  minameen varchar(250) DEFAULT '',                --品种英文名称  --lzm add 2025-11-23 12:15:15
  midiscountname_en varchar(250) DEFAULT '',         --折扣英文名称  --lzm add 2025-11-23 12:14:30
  miservicename_en varchar(250) DEFAULT '',        --服务费英文名称  --lzm add 2025-11-23 12:14:34

  CONSTRAINT webbilldetail_pkey PRIMARY KEY (id)
);
alter table webbilldetail add qty_received numeric(15,3) default 0;
alter table webbilldetail add reason_undelivered varchar(250);
alter table webbilldetail add status varchar(40);
alter table webbilldetail add qty_reject numeric(15,3) default 0;
alter table webbilldetail add worker varchar(100);
alter table webbilldetail add wcomptime timestamp;
alter table webbilldetail add delytime timestamp;
alter table webbilldetail add delydriver json;

alter table whole_webbilldetail add qty_received numeric(15,3) default 0;
alter table whole_webbilldetail add reason_undelivered varchar(250);
alter table whole_webbilldetail add status varchar(40);
alter table whole_webbilldetail add qty_reject numeric(15,3) default 0;
alter table whole_webbilldetail add worker varchar(100);
alter table whole_webbilldetail add wcomptime timestamp;
alter table whole_webbilldetail add delytime timestamp;
alter table whole_webbilldetail add delydriver json;

alter table webbills add bookingshopfrom varchar(40) default '';
alter table webbills add delytime timestamp;
alter table webbills add delydriver json;
alter table whole_webbills add bookingshopfrom varchar(40) default '';
alter table whole_webbills add delytime timestamp;
alter table whole_webbills add delydriver json;

alter table whole_webbilldetail add process_status text default '';
alter table whole_webbilldetail add process_sortorder integer default 0;
alter table whole_webbilldetail add preceived_status text default '';
alter table whole_webbilldetail add preceived_sortorder integer default 0;
alter table whole_webbilldetail add createtime timestamp without time zone DEFAULT date_trunc('second', now());
alter table whole_webbilldetail add modifytime timestamp without time zone DEFAULT date_trunc('second', now());
alter table whole_webbilldetail add qty_received_auto numeric(15,3) default 0;
alter table whole_webbilldetail add qty_received_autodt timestamp without time zone;
alter table whole_webbilldetail add qty_received_manual numeric(15,3) default 0;
alter table whole_webbilldetail add qty_received_manualdt timestamp without time zone;

alter table webbilldetail add sale_type VARCHAR(60) DEFAULT ''
alter table whole_webbilldetail add sale_type VARCHAR(60) DEFAULT ''

alter table webbilldetail add miservicename varchar(250) DEFAULT '';
alter table webbilldetail add miservicecarge numeric(15,3) DEFAULT 0;
alter table whole_webbilldetail add miservicename varchar(250) DEFAULT '';
alter table whole_webbilldetail add miservicecarge numeric(15,3) DEFAULT 0;

alter table webbilldetail drop miname_org;
alter table webbilldetail drop minameen;
alter table webbilldetail drop discountname_en;
alter table webbilldetail drop miservicename_en;
alter table whole_webbilldetail drop miname_org;
alter table whole_webbilldetail drop minameen;
alter table whole_webbilldetail drop discountname_en;
alter table whole_webbilldetail drop miservicename_en;
alter table webbilldetail add miname_org varchar(250) DEFAULT '';
alter table webbilldetail add minameen varchar(250) DEFAULT '';
alter table webbilldetail add midiscountname_en varchar(250) DEFAULT '';
alter table webbilldetail add miservicename_en varchar(250) DEFAULT '';
alter table whole_webbilldetail add miname_org varchar(250) DEFAULT '';
alter table whole_webbilldetail add minameen varchar(250) DEFAULT '';
alter table whole_webbilldetail add midiscountname_en varchar(250) DEFAULT '';
alter table whole_webbilldetail add miservicename_en varchar(250) DEFAULT '';

create index webbilldetail_id_idx on webbilldetail(id);

--select tablecount,bookingshopfrom,bookingtime,status,* from webbills where user_id=293 and billtype='8'
select status,reason_undelivered,worker,wcomptime,wd.qty_received,* from webbilldetail wd where webbills_id in (select id from webbills where user_id=293 and billtype='8' and bookingshopfrom='017' ) order by webbills_id,id
select wd.status,wd.reason_undelivered,wd.worker,wd.receied,wb.delytime,wb.delydriver,wb.bookingtime,wd.miname from webbills wb left join webbilldetail wd on (wb.id=wd.webbills_id) where wb.user_id=293 and wb.billtype='8' and wb.bookingshopfrom='017' order by wd.webbills_id,wd.id

CREATE TABLE webbillpayment
(
  id serial NOT NULL,
  webbills_id integer NOT NULL,
  shopuuid varchar(250) NOT NULL,
  billuuid varchar(250) NOT NULL,
  paymediatype integer default 0,       --0=现金 1=微信付款 2=支付宝付款 3=会员卡积分付款 4=会员卡金额付款 5=优惠券付款 6=KPay
  paymedianame varchar(40) default '',  --付款名称
  payamount numeric(15,3) default 0,    --金额
  SCPAYCLASS   VARCHAR(200),            /*支付类型
                                            讯联
                                                    PURC:下单支付
                                                    VOID:撤销
                                                    REFD:退款
                                                    INQY:查询
                                                    PAUT:预下单
                                                    VERI:卡券核销
                                            翼富
                                                    PURC:下单支付
                                                    VOID:撤销
                                                    INQY:查询
                                                    CLOS:关闭订单
                                            智能设备
                                                    SIGN:签到
                                        */
  SCPAYCHANNEL VARCHAR(200),            /*支付渠道
                                            讯联
                                                    ALP:支付宝支付
                                                    WXP:微信支付
                                            翼富
                                                    ALP:支付宝支付
                                                    WXP:微信支付
                                                    APP:苹果付
                                                    SXP:三星付
                                                    UNP:银联
                                                    OTP:第三方支付
                                                    WXALP:微信或支付宝自动识别
                                            智能设备
                                                    BBPOS 香港的智能支付设备                                                      
                                                    KPAY 香港的智能支付设备                                                      
                                        */
  SCPAYORDERNO VARCHAR(200),            --支付订单号 orderNum
  SCPAYBARCODE VARCHAR(200),            --支付条码 用于扫码支付 KPay: 保存managedOrderNo
  SCPAYSTATUS  INTEGER,                 /* 当paymediatype=1和2和6时 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=其它错误
                                        */
  USER_ID INTEGER,
  shopid  varchar(40) DEFAULT '',
  SCPAYCHANNELCODE VARCHAR(200),             /*支付渠道交易号 KPay:保存orderNo 【用于讯联-支付宝微信支付】 lzm add 2016-2-2*/

  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',   /*IC卡号 
                                                当paymediatype=3和4时 ICINFO_ICCARDNO 和 TRANSACTIONID 有填内容代表会员卡支付成功
                                             */
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型:
                                               0=VIP卡消费(IC卡或磁卡)
                                               1=VIP卡充值(IC卡或磁卡)
                                               2=修改IC卡消费金额
                                               3=积分累计记录 //lzm modify 2015-10-15【由于之前是:3=其它付款方式，所以不能根据该记录判断是否为"积分累计"记录】
                                               4=积分扣除记录 和 积分付款消费(对应TENDERMEDIA的RESERVE3的1)  //lzm modify 2015-10-15
                                               5=积分换礼品记录 //lzm modify 2015-10-15
                                               6=VIP卡积分折现付款(磁卡)
                                               7=VIP卡直接修改总积分  //lzm add 2011-08-02
                                               8=VIP卡直接修改可用积分  //lzm add 2011-08-02
                                               9=VIP卡积分折现 //lzm add 2011-08-04
                                               12=VIP卡挂失后退款 lzm add 2012-07-6
                                               13=VIP卡挂失后换新卡-新卡 lzm add 2012-07-6
                                               14=VIP卡消费还款(IC卡或磁卡) //lzm add 2013-12-02
                                               15=VIP卡挂失后换新卡-旧卡 lzm add 2015/5/22 星期五
                                               16=实体卡绑定微信会员卡 lzm add 2018-10-12 14:58:29
                                               100=消费日结标记 lzm add 2012-07-12

                                               111:澳门通-售卡 lzm add 2013-02-26
                                               112:澳门通-充值 lzm add 2013-02-26
                                               113:澳门通-扣值 lzm add 2013-02-26
                                               114:澳门通-结算 lzm add 2013-02-26

                                               999:其它付款方式(IC卡和磁卡积分付款、现金付款等) lzm add 2015-10-19
                                               */
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*IC卡消费或充值的金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*IC卡余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF  NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD  NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW  NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*修改为：微信卡包名称_微信卡种名称_微信卡包编号 lzm modify 2019-01-07 12:31:28，之前是【相关的品种英文名称("积分换礼品")的礼品英文名称】*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,  /*之前的卡累总积分(目前只对磁卡生效) lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,  /*增加的累总积分 lzm add 【2011-08-02】*/

  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     7=微信礼品卡 //lzm add 2019-04-20 06:30:04 用于区分LQNUMBER是礼品卡还是优惠券
                                                     8=优惠券 //lzm add 2019-04-20 06:30:04 用于区分LQNUMBER是礼品卡还是优惠券
                                                  */
  LQNUMBER VARCHAR(40),                           --礼券编号
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 用于微信会员卡、优惠券 lzm add 2016-05-25 13:28:37*/
  
  payment_result json,                            --用于保存KPay的查询结果  --lzm add 2025-10-16 17:16:54
  
  CONSTRAINT webbillpayment_pkey PRIMARY KEY (id)
);
alter table webbillpayment add payment_result json;
alter table whole_webbillpayment add payment_result json;

CREATE TABLE webbillpayback
(
  id serial NOT NULL,
  webbills_id integer NOT NULL,
  shopuuid varchar(250) NOT NULL,
  billuuid varchar(250) NOT NULL,
  busicd varchar(250), --交易类型（如未用到不需关注）
                       /*
                       交易类型
                       PURC:下单支付
                       VOID:撤销
                       REFD:退款
                       INQY:查询
                       PAUT:预下单
                       VERI:卡券核销
                       CANC:取消，对成功支付订单进行撤销，对未成功支付订单进行关闭订单
                       SIGN:签到           //KPay
                       TIPA:小费调整       //KPay
                       TIPC:小费调整撤销    //KPay
                       */
  channelOrderNum varchar(250), --渠道订单号 KPay:保存orderNo（如未用到不需关注）
  chcd varchar(250), --交易渠道, ALP:支付宝支付  WXP:微信支付 WXALP:微信和支付宝 KPAY:KPay 空格:代表不指定渠道
  errorDetail varchar(250), --错误描述
  goodsInfo text, --原样返回
  inscd varchar(250), --机构号  KPay:保存managedOrderNo
  mchntid varchar(250), --商户号
  orderNum varchar(250), --订单号
  respcd varchar(250), --应答码，00代表成功；
  txamt varchar(250), --订单金额，12位定长，单位分，不足12位左补0
  txndir varchar(250), --交易方向，A为应答（如未用到不需关注）
  consumerAccount varchar(250), --支付用户对应的用户标识
  sign varchar(250), --签名，用于验签
  intime timestamp without time zone DEFAULT date_trunc('second', now()),  --单据生成时间

  USER_ID INTEGER,
  shopid  varchar(40) DEFAULT '',
  items text default '', --支付金额组成 json字符串 lzm add 2017-03-25 01:38:27
  
  CONSTRAINT webbillpayback_pkey PRIMARY KEY (id)
);

CREATE TABLE sms_send_record /*短信发送记录 lzm add 2013-12-12*/
(
  ID SERIAL NOT NULL,
  MOBILELIST  VARCHAR(240) NOT NULL,    /*需要发送的手机列表(目前只支持一个)
                                        当sendchannel=3: wechat_id
                                        */
  CONTENT     VARCHAR(240) NOT NULL,    /*发送内容*/
  SENDLEVEL   INTEGER DEFAULT 6,        /*发送级别 0=代表最高级别*/
  SENDCHANNEL INTEGER DEFAULT 0,        /*发送渠道 0=WebService 1=HTTP 2=短信猫发 3=Wechat公众号信息*/

  SENDECODE   VARCHAR(40),              /*发送的企业代码
                                        当sendchannel=3: token
                                        */
  INTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),  /*本记录生成时间*/
  SENDTIME    TIMESTAMP,                /*发送时间*/
  STATUS      INTEGER DEFAULT 0,        /*发送状态 0=新记录需要发送 1=发送成功 2=发送超时 3=发送失败需要重新发送 4=发送失败不需要重新发送 */
  MEMO        VARCHAR(100),             /*备注*/
  ERRORID     INTEGER,                  /*错误代码 <0=代表发送失败的返回代码 */
  ERRORSTR    VARCHAR(100),             /*错误信息:文字表述*/
  CLASSNAME   VARCHAR(40),              /*发送类别名称 文字表示*/
  CLASSCAPTION   VARCHAR(40),           /*发送类别显示名 文字表示*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  transactionid text,              --唯一编号  --lzm add 2022-08-11 00:04:56

  PRIMARY KEY (ID)
);
alter table sms_send_record add  USER_ID INTEGER DEFAULT 0;
alter table sms_send_record add  SHOPID  VARCHAR(40) DEFAULT '';
alter table sms_send_record add  SHOPGUID VARCHAR(200) DEFAULT '';
alter table sms_send_record add  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW());
alter table sms_send_record add  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW());
alter table sms_send_record add  MODIFYUSER VARCHAR(40);
alter table sms_send_record add  transactionid text;
create unique index sms_send_record_transactionid on sms_send_record(transactionid);

CREATE TABLE sms_send_template /*短信发送模版 lzm add 2013-12-12*/
(
  SMSTNAME       VARCHAR(100) NOT NULL,   /*模版名*/
  SMSTALIAS      VARCHAR(100),            /*模版别名*/
  SMSTCONTENT    VARCHAR(240) NOT NULL,   /*模版内容*/
  SMSTMEMO       VARCHAR(100),            /*备注*/
  SMSTALIAS_LANGUAGE       VARCHAR(100),  /*模版别名英文*/
  SMSTCONTENT_LANGUAGE    VARCHAR(240),   /*模版内容英文*/
  ID             INTEGER NOT NULL,        /**/
  PRIMARY KEY (SMSTNAME)
);

CREATE TABLE data_definition  /*i9版本 总部系统需要用到的变量表 lzm add 2010-12-06*/
(
  id serial NOT NULL,
  definition_name VARCHAR(50) DEFAULT '',
  definition_val VARCHAR(50) DEFAULT '',

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  CONSTRAINT data_definition_pkey PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id)
);
/*
1;"AGEDNESS";"1191"             //老年人
2;"MIDDLE_AGE";"1192"           //中年人
3;"CALLAN";"1193"               //青年人
4;"MALE";"1194"                 //男人
5;"FEMALE";"1195"               //女人
6;"WEATHER";"''"                //天气
7;"PRESENT";"赠送"              //赠送字符串
8;"WASTE";"损耗"                //损耗字符串
9;"BILLTIME";"ENDTIME"          //账单时间 ENDTIME以结单计  STARTTIME以开单计
10;"SPLITTIME";"3"              //账单延迟时间
11;"SHOPCODE";"''"              //店编号
12;"SHOPNAME";"localhost"       //店名称
13;"REPORT_IS_DAYORCASHIERSHIFT";"CASHIERSHIFT"     //'DAY'=以日统计  'CASHIERSHIFT'=以班次统计
14;"YEAR_REPORTNAME";"年报表"                       //报表抬头名称
15;"MONTH_REPORTNAME";"月报表"                      //报表抬头名称
16;"DAY_REPORTNAME";"日报表"                        //报表抬头名称
17;"DAY_CASHIERSHIFT_REPORTNAME";"班次报表"         //报表抬头名称
18;"CONFIGURATION_SERVER";"localhost"               //没有使用
49;"LOCALSERVER_IP";"127.0.0.1"                     //系统文件传输python自动设置
50;"SERVER_IP";"localhost"                          //系统文件传输python自动设置
51;"YIPPEE_ROOT";"D:\yippee_root"                   //系统文件传输python自动设置
52;"TRANSFERMODE";"server"                          //系统文件传输python自动设置
*/

create table temp1
(
  id serial,
  inserttime timestamp,
  primary key (id)
);

CREATE TABLE tp_company_staff
(
    id integer NOT NULL,
    companyid integer NOT NULL DEFAULT 0,
    token varchar(30) NOT NULL DEFAULT '',
    name varchar(30) NOT NULL DEFAULT '',
    username varchar(20) NOT NULL DEFAULT '',
    password varchar(40) NOT NULL DEFAULT '',
    tel varchar(40) NOT NULL DEFAULT '',
    "time" integer NOT NULL DEFAULT 0,
    func varchar(5000) NOT NULL DEFAULT '',
    pcorwap varchar(255) NOT NULL DEFAULT '',
    wecha_id varchar(30) NOT NULL DEFAULT '',
    shopids text,
    usertypeid integer DEFAULT 0,
    pos_isfreeprice integer DEFAULT 0,
    canrefund integer DEFAULT 0,
    USER_ID INTEGER DEFAULT 0,
    SHOPID VARCHAR(40) DEFAULT '',
    discount_upperlimit varchar(20),
    CONSTRAINT tp_company_staff_pkey PRIMARY KEY (id)
);

CREATE TABLE terminal_info(
  id serial,
  terminal_c_diskpartnum varchar(250),     --C:\盘分区序列号
  terminal_c_diskserial varchar(250),      --C:\硬盘序列号

  terminal_regserial varchar(250),     --注册序列号
  terminal_regcode varchar(250),       --注册码

  terminal_systeminfo varchar(250),    --操作系统信息
  terminal_netinfo varchar(250),       --网卡信息
  terminal_ip varchar(250),            --IP地址
  terminal_hostname varchar(250),      --电脑名称
  terminal_shopname varchar(250),      --店名称
  terminal_shopid varchar(250),        --店编号
  terminal_pcid varchar(250),          --机器编号
  terminal_shoptype varchar(250),      --门店类型（0=无 1=快餐 2=西餐 3=茶餐厅 4=海鲜酒楼 5=普通酒楼 6=酒吧 7=茶铺 8=面包店）
  terminal_shopuseto varchar(250),     --本机用途（点单、总部报表、查看报表）
  terminal_terminalcode varchar(250),  --终端设备码
  terminal_updatatohq varchar(250),    --是否勾选上传总部
  terminal_filedir varchar(250),       --程序所在文件夹
  terminal_mainsvrip varchar(250),     --收银服务器IP
  terminal_datasvrip varchar(250),     --数据库服务器IP

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  CONSTRAINT terminal_info_pkey PRIMARY KEY (id)
);

/*start***************************************排队系统相关表格**************************************/
CREATE TABLE QUEUESYS_QUEUE  /*排队列表*/
(
  QSQSECTIONID    INTEGER NOT NULL,            /*区域*/
  QSQTIMEID       INTEGER NOT NULL,            /*时段*/
  QSQPARTYID      INTEGER NOT NULL DEFAULT 1,  /*座位数 1=1号卡位 2=2号卡位 3=3号卡位 4=4号卡位*/
  QSQNUMBER       INTEGER NOT NULL,            /*排队编号*/
  QSQPARTYSIZE    INTEGER NOT NULL,            /*人数*/
  QSQSTATUS       INTEGER NOT NULL DEFAULT 0,  /*0=等候中 1=入座 2=跳过*/
  QSQINTIME       TIMESTAMP DEFAULT date_trunc('second', NOW()),     /*产生时间*/
  QSQPCID         VARCHAR(40),                 /*终端号*/
  QSQGPID         INTEGER NOT NULL DEFAULT 0,  /*组编号*/
--  QSQINUSE        INTEGER DEFAULT 1,           /*是否正在使用 0=否 1=是 用于一天可能需要多次从1开始*/
  QSQSMOKING      INTEGER DEFAULT 0,           /*是否吸烟区 0=否 1=是*/
  PRIMARY KEY (QSQGPID, QSQSECTIONID, QSQTIMEID, QSQPARTYID, QSQNUMBER)
);

CREATE TABLE QUEUESYS_SECTIONS /*排队的区域*/
(
  QSQSECTIONID    INTEGER NOT NULL,
  QSQSNAME        VARCHAR(40) NOT NULL,
  QSQPS1          VARCHAR(40),           /*A区的前导字*/
  QSQPS2          VARCHAR(40),           /*B区的前导字*/
  QSQPS3          VARCHAR(40),           /*C区的前导字*/
  QSQPS4          VARCHAR(40),           /*C区的前导字*/
  PRIMARY KEY (QSQSECTIONID)
);

CREATE TABLE QUEUESYS_TIME /*排队的时段*/
(
  QSQTIMEID       INTEGER NOT NULL,
  QSQTNAME        VARCHAR(40) NOT NULL,
  PRIMARY KEY (QSQTIMEID)
);
/*end*****************************************排队系统相关表格**************************************/


/*start***************************************后台相关表格**************************************/
CREATE TABLE UPDATEPACK  /*用于门店的更新包*/
(
  UPID            INTEGER NOT NULL,           /*编号*/
  UPFILEID        INTEGER NOT NULL,           /*文件编号
                                              1=YIPPEE程序更新包
                                              */
  UPFILENAME      VARCHAR(100) NOT NULL,      /*文件名称*/
  UPFILEVER       VARCHAR(10) DEFAULT '7.0',  /*文件版本号*/
  UPFILEDATANUM   INTEGER DEFAULT 1,          /*文件内容编号（一个文件可以拆分成多个包）*/
  UPFILEDATA      BYTEA,                      /*文件内容*/
  PRIMARY KEY (UPID)
);

CREATE TABLE TABLEMDSTATUS  /* */
(
  TABLENAME  VARCHAR(40) NOT NULL,  /*表名称*/
  MDTIME     TIMESTAMP NOT NULL,    /*修改时间*/
  PROCESS    INTEGER DEFAULT 0,     /*处理进程 0=新的更新 1=已处理*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TABLENAME)
);

CREATE TABLE SHOPIDTRANSTATE  /*门店即时传输状态*/
(
  SHOPID  VARCHAR(10) NOT NULL,    /*商店编号*/
  SHOPDATE TIMESTAMP NOT NULL,     /*时间以天为单位*/
  STNAME   VARCHAR(40) NOT NULL,   /*状态名*/
  STVALUE  VARCHAR(240),           /*状态值*/
  PRIMARY KEY (SHOPID,SHOPDATE,STNAME)
);

CREATE TABLE SHOPIDPARAM  /*需要传到门店bosClient.exe的参数*/
(
  SHOPID  VARCHAR(10) NOT NULL,    /*商店编号*/
  SPNAME   VARCHAR(40) NOT NULL,   /*参数名*/
  SPVALUE  VARCHAR(240),           /*参数值*/
  PRIMARY KEY (SHOPID,SPNAME)
);

CREATE TABLE REMOTECNFDATA  /*远程门店品种界面等的配置数据*/
(
  SHOPID       VARCHAR(10) NOT NULL,       /*商店编号*/
  CNFDATE      TIMESTAMP NOT NULL,         /*日期*/
  CNFTYPE      INTEGER DEFAULT NULL,       /*类型
                                           对于接收工具:
                                               0=接收远程门店配置数据进来,
                                               1=把配置数据传送到远程门店
                                           对于Client.exe:
                                               0=启动时接收进数据库,
                                               1=***保留***
                                           对于BKServer.exe
                                               0=***保留***,
                                               1=从数据库移交出来后填入这个表并设置CNFTYPE=1
                                           */
  CNFDATA1     BYTEA,                      /*数据1*/
  REPLACEFCNFS VARCHAR(254) DEFAULT NULL,  /*需要覆盖的配置文件，多个时用;分隔*/
  ZIPTYPE      INTEGER DEFAULT 0,   /*0=VCLZip后直接保存到数据库
                                      1=先VCLZip 后Mime保存到数据库
                                    */
  PRIMARY KEY (SHOPID,CNFDATE)
);

/*
ENDOFTIME
TDSTATUS
TDOTHERSVR

以上3个标志位:
  在门店:由bosClient内的TransferData_CheckEndOfTime函数设置
  在总部:由A服务器的bosServer设置"ENDOFTIME" 由B服务器的bosClient设置"TDSTATUS"和"TDOTHERSVR"

*/
/*
添加SHOPENDOFTIME数据的代码的地方:
  1.bosClient的TransferData_CheckDataTranSatus函数
  2.Client.exe的CreateEndOfTimeTag函数
  3.总部的B服务器CreateEndOfTime
*/
CREATE TABLE SHOPENDOFTIME  /*商店销售数据结束传送完成标志 和 班次打印 表(根据SHIFTTIMEPERIOD的数据产生)*/
(
  SHOPID         VARCHAR(10) NOT NULL,
  SHOPDATE       TIMESTAMP NOT NULL,
  SHOPNAME       VARCHAR(40),
  ENDOFTIME      INTEGER DEFAULT 0,     /*该天班次的数据是否已结束营业日：
                                          对于门店:    (0=没结束营业 1=已结束营业 2=已结束营业但:超时门店上传A服务器失败     )-->由门店自己控制该标志
                                          对于A服务器: (0=没接收完成 1=已接收完毕 2=已接收完毕但:超时门店上传A服务器失败     )-->由门店控制该标志
                                          对于B服务器: (0=没接收完成 1=已接收完毕 2=已接收完毕但:超时门店上传A服务器失败     )-->由B服务器自己控制该标志*/
  TDSTATUS       INTEGER DEFAULT 0,     /* ********停用*********该"ENDOFTIME=1的标记"是否已上传另一服务器：0=没 1=已上传*/
  SUMWHOLEDAY    INTEGER DEFAULT 0,     /*当前总部服务器是否已进行按日数据整理 0=没, 1=已整理*/
  TDOTHERSVR     INTEGER DEFAULT 0,     /*该天班次的数据是否已全部上传另一服务器
                                          对于门店:    (0=没上传 1=已经上传 2=已经上传但:超时门店上传A服务器失败   )-->由门店自己控制该标志
                                          对于A服务器: (0=没上传 1=已经上传 2=已经上传但:超时门店上传A服务器失败   )-->由B服务器控制该标志
                                          对于B服务器: (0=没上传 1=已经上传 2=已经上传但:超时门店上传A服务器失败   )-->  */
  SHOPPARTYID    INTEGER DEFAULT 0,     /*班次编号*/
  HAVEPRINTED    INTEGER DEFAULT 0,     /*用于门店: 已产生报表 0=没产生 1=已产生*/
  DATADELETED    INTEGER DEFAULT 0,     /*用于门店: 该班次数据是否已被删除 0=没删除 1=已删除 2=该班无数据 【在Client.exe的AutoPrintReport函数内设置】*/
  ADDENDTAGTIME  TIMESTAMP,             /*添加结束段营业标志的时间*/
  SHOPPARTNAME   VARCHAR(40),           /*班次名称*/
  SHOPPARTSTIME  VARCHAR(40),           /*班次开始时间*/
  SHOPPARTETIME  VARCHAR(40),           /*班次结束时间*/
  SHOPPARTNODATA INTEGER DEFAULT 0,     /*该班次无数据 0=有数据 1=无数据*/
  ADDTDSVRTIME   TIMESTAMP,             /*添加TDOTHERSVR的时间*/
  ENDOFMEMO      VARCHAR(200),          /*备注*/
  PRIMARY KEY (SHOPID,SHOPDATE,SHOPPARTYID)
);

CREATE TABLE AUTOREPORTSPACE  /*自动打印后保存的报表*/
(
  ARSID           INTEGER,            /*顺序号*/
  ARSSHOPID       VARCHAR(10),        /*门店编号*/
  ARSDATE         TIMESTAMP,          /*日期*/
  ARSCASHIERSHIFT INTEGER,            /*班次*/
  ARSREPORTNAME   VARCHAR(40),        /*报表名称*/
  ARSCONTENT      BYTEA,              /*报表内容*/
  ARSMODALNAME    VARCHAR(30),        /*打印模板文件名称*/
  ARSPRNCOUNT     INTEGER DEFAULT 0,  /*打印次数*/
  PRIMARY KEY (ARSID)
);

CREATE TABLE SHOPSMONTHSUM  /*商店销售月汇总*/
(
  SHOPID        VARCHAR(10) NOT NULL,
  SHOPDATE      TIMESTAMP NOT NULL,
  SHOPNAME      VARCHAR(40),
  FTOTAL        NUMERIC(15,3) DEFAULT 0,  /*营业额*/
  PEOPLES       INTEGER DEFAULT 0,        /*人数*/
  AVERAGEPEOPLE NUMERIC(15,3) DEFAULT 0,  /*人均*/
  PERIODOFTIME1 NUMERIC(15,3) DEFAULT 0,  /*时段1*/
  PERIODOFTIME2 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME3 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME4 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME5 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME6 NUMERIC(15,3) DEFAULT 0,  /*时段6*/
  DINMODE1      NUMERIC(15,3) DEFAULT 0,  /*用餐方式1*/
  DINMODE2      NUMERIC(15,3) DEFAULT 0,
  DINMODE3      NUMERIC(15,3) DEFAULT 0,
  DINMODE4      NUMERIC(15,3) DEFAULT 0,
  DINMODE5      NUMERIC(15,3) DEFAULT 0,
  DINMODE6      NUMERIC(15,3) DEFAULT 0,
  DINMODE7      NUMERIC(15,3) DEFAULT 0,
  DINMODE8      NUMERIC(15,3) DEFAULT 0,
  DINMODE9      NUMERIC(15,3) DEFAULT 0,
  DINMODE10     NUMERIC(15,3) DEFAULT 0,  /*用餐方式10*/
  PAYMENT1      NUMERIC(15,3) DEFAULT 0,  /*付款方式1*/
  PAYMENT2      NUMERIC(15,3) DEFAULT 0,
  PAYMENT3      NUMERIC(15,3) DEFAULT 0,
  PAYMENT4      NUMERIC(15,3) DEFAULT 0,
  PAYMENT5      NUMERIC(15,3) DEFAULT 0,
  PAYMENT6      NUMERIC(15,3) DEFAULT 0,
  PAYMENT7      NUMERIC(15,3) DEFAULT 0,
  PAYMENT8      NUMERIC(15,3) DEFAULT 0,
  PAYMENT9      NUMERIC(15,3) DEFAULT 0,
  PAYMENT10     NUMERIC(15,3) DEFAULT 0,
  PAYMENT11     NUMERIC(15,3) DEFAULT 0,
  PAYMENT12     NUMERIC(15,3) DEFAULT 0,
  PAYMENT13     NUMERIC(15,3) DEFAULT 0,
  PAYMENT14     NUMERIC(15,3) DEFAULT 0,
  PAYMENT15     NUMERIC(15,3) DEFAULT 0,
  PAYMENT16     NUMERIC(15,3) DEFAULT 0,
  PAYMENT17     NUMERIC(15,3) DEFAULT 0,
  PAYMENT18     NUMERIC(15,3) DEFAULT 0,
  PAYMENT19     NUMERIC(15,3) DEFAULT 0,
  PAYMENT20     NUMERIC(15,3) DEFAULT 0,  /*付款方式20*/
  DEPARTMENT1   NUMERIC(15,3) DEFAULT 0,  /*部门1*/
  DEPARTMENT2   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT3   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT4   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT5   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT6   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT7   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT8   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT9   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT10  NUMERIC(15,3) DEFAULT 0,  /*部门10*/
  FAMILGID1     NUMERIC(15,3) DEFAULT 0,  /*辅助分类1*/
  FAMILGID2     NUMERIC(15,3) DEFAULT 0,
  FAMILGID3     NUMERIC(15,3) DEFAULT 0,
  FAMILGID4     NUMERIC(15,3) DEFAULT 0,
  FAMILGID5     NUMERIC(15,3) DEFAULT 0,
  FAMILGID6     NUMERIC(15,3) DEFAULT 0,
  FAMILGID7     NUMERIC(15,3) DEFAULT 0,
  FAMILGID8     NUMERIC(15,3) DEFAULT 0,
  FAMILGID9     NUMERIC(15,3) DEFAULT 0,
  FAMILGID10    NUMERIC(15,3) DEFAULT 0,  /*辅助分类10*/
  DAYS          INTEGER DEFAULT 31,       /*日数*/
  AVERAGEDAY    NUMERIC(15,3) DEFAULT 0,  /*日均营业额*/
  PRIMARY KEY (SHOPID,SHOPDATE)
);

CREATE TABLE SHOPSDAYSUM  /*商店销售日汇总*/
(
  SHOPID       VARCHAR(10) NOT NULL,
  SHOPDATE     TIMESTAMP NOT NULL,
  SHOPNAME     VARCHAR(40),
  FTOTAL       NUMERIC(15,3) DEFAULT 0,   /*营业额*/
  PEOPLES    INTEGER DEFAULT 0,           /*人数*/
  AVERAGEPEOPLE NUMERIC(15,3) DEFAULT 0,  /*人均*/
  PERIODOFTIME1 NUMERIC(15,3) DEFAULT 0,  /*时段1*/
  PERIODOFTIME2 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME3 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME4 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME5 NUMERIC(15,3) DEFAULT 0,
  PERIODOFTIME6 NUMERIC(15,3) DEFAULT 0,  /*时段6*/
  DINMODE1      NUMERIC(15,3) DEFAULT 0,  /*用餐方式1*/
  DINMODE2      NUMERIC(15,3) DEFAULT 0,
  DINMODE3      NUMERIC(15,3) DEFAULT 0,
  DINMODE4      NUMERIC(15,3) DEFAULT 0,
  DINMODE5      NUMERIC(15,3) DEFAULT 0,
  DINMODE6      NUMERIC(15,3) DEFAULT 0,
  DINMODE7      NUMERIC(15,3) DEFAULT 0,
  DINMODE8      NUMERIC(15,3) DEFAULT 0,
  DINMODE9      NUMERIC(15,3) DEFAULT 0,
  DINMODE10     NUMERIC(15,3) DEFAULT 0,  /*用餐方式10*/
  PAYMENT1      NUMERIC(15,3) DEFAULT 0,  /*付款方式1*/
  PAYMENT2      NUMERIC(15,3) DEFAULT 0,
  PAYMENT3      NUMERIC(15,3) DEFAULT 0,
  PAYMENT4      NUMERIC(15,3) DEFAULT 0,
  PAYMENT5      NUMERIC(15,3) DEFAULT 0,
  PAYMENT6      NUMERIC(15,3) DEFAULT 0,
  PAYMENT7      NUMERIC(15,3) DEFAULT 0,
  PAYMENT8      NUMERIC(15,3) DEFAULT 0,
  PAYMENT9      NUMERIC(15,3) DEFAULT 0,
  PAYMENT10     NUMERIC(15,3) DEFAULT 0,
  PAYMENT11     NUMERIC(15,3) DEFAULT 0,
  PAYMENT12     NUMERIC(15,3) DEFAULT 0,
  PAYMENT13     NUMERIC(15,3) DEFAULT 0,
  PAYMENT14     NUMERIC(15,3) DEFAULT 0,
  PAYMENT15     NUMERIC(15,3) DEFAULT 0,
  PAYMENT16     NUMERIC(15,3) DEFAULT 0,
  PAYMENT17     NUMERIC(15,3) DEFAULT 0,
  PAYMENT18     NUMERIC(15,3) DEFAULT 0,
  PAYMENT19     NUMERIC(15,3) DEFAULT 0,
  PAYMENT20     NUMERIC(15,3) DEFAULT 0,  /*付款方式20*/
  DEPARTMENT1   NUMERIC(15,3) DEFAULT 0,  /*部门1*/
  DEPARTMENT2   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT3   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT4   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT5   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT6   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT7   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT8   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT9   NUMERIC(15,3) DEFAULT 0,
  DEPARTMENT10  NUMERIC(15,3) DEFAULT 0,  /*部门10*/
  FAMILGID1     NUMERIC(15,3) DEFAULT 0,  /*辅助分类1*/
  FAMILGID2     NUMERIC(15,3) DEFAULT 0,
  FAMILGID3     NUMERIC(15,3) DEFAULT 0,
  FAMILGID4     NUMERIC(15,3) DEFAULT 0,
  FAMILGID5     NUMERIC(15,3) DEFAULT 0,
  FAMILGID6     NUMERIC(15,3) DEFAULT 0,
  FAMILGID7     NUMERIC(15,3) DEFAULT 0,
  FAMILGID8     NUMERIC(15,3) DEFAULT 0,
  FAMILGID9     NUMERIC(15,3) DEFAULT 0,
  FAMILGID10    NUMERIC(15,3) DEFAULT 0,  /*辅助分类10*/
  PRIMARY KEY (SHOPID,SHOPDATE)
);

CREATE TABLE SHOPS31DAYSUM  /*商店销售汇总*/
(
  SHOPID       VARCHAR(10) NOT NULL,
  SHOPDATE     TIMESTAMP NOT NULL,
  SHOPNAME     VARCHAR(40),
  DAY1         NUMERIC(15,3) DEFAULT 0,
  DAY2         NUMERIC(15,3) DEFAULT 0,
  DAY3         NUMERIC(15,3) DEFAULT 0,
  DAY4         NUMERIC(15,3) DEFAULT 0,
  DAY5         NUMERIC(15,3) DEFAULT 0,
  DAY6         NUMERIC(15,3) DEFAULT 0,
  DAY7         NUMERIC(15,3) DEFAULT 0,
  DAY8         NUMERIC(15,3) DEFAULT 0,
  DAY9         NUMERIC(15,3) DEFAULT 0,
  DAY10        NUMERIC(15,3) DEFAULT 0,
  DAY11        NUMERIC(15,3) DEFAULT 0,
  DAY12        NUMERIC(15,3) DEFAULT 0,
  DAY13        NUMERIC(15,3) DEFAULT 0,
  DAY14        NUMERIC(15,3) DEFAULT 0,
  DAY15        NUMERIC(15,3) DEFAULT 0,
  DAY16        NUMERIC(15,3) DEFAULT 0,
  DAY17        NUMERIC(15,3) DEFAULT 0,
  DAY18        NUMERIC(15,3) DEFAULT 0,
  DAY19        NUMERIC(15,3) DEFAULT 0,
  DAY20        NUMERIC(15,3) DEFAULT 0,
  DAY21        NUMERIC(15,3) DEFAULT 0,
  DAY22        NUMERIC(15,3) DEFAULT 0,
  DAY23        NUMERIC(15,3) DEFAULT 0,
  DAY24        NUMERIC(15,3) DEFAULT 0,
  DAY25        NUMERIC(15,3) DEFAULT 0,
  DAY26        NUMERIC(15,3) DEFAULT 0,
  DAY27        NUMERIC(15,3) DEFAULT 0,
  DAY28        NUMERIC(15,3) DEFAULT 0,
  DAY29        NUMERIC(15,3) DEFAULT 0,
  DAY30        NUMERIC(15,3) DEFAULT 0,
  DAY31        NUMERIC(15,3) DEFAULT 0,
  CASHIERSHIFT INTEGER DEFAULT 0,         /*班次*/
  PRIMARY KEY (SHOPID,SHOPDATE,CASHIERSHIFT)
);

CREATE TABLE TRANSFERDATA  /*保存门店的上传数据表*/
(
  TDID         INTEGER NOT NULL,
  PCID         VARCHAR(40) NOT NULL,
  Y            INTEGER NOT NULL,
  M            INTEGER NOT NULL,
  D            INTEGER NOT NULL,
  RESERVE3     VARCHAR(20) NOT NULL,
  CHECKID      INTEGER,
  TDSTATUS     INTEGER DEFAULT 0,   /*数据状态: -10=数据接收失败, 0=保留, 1=上传完成可以导出, 2=已经导出完成可以删除*/
  PREFIXTABLE  VARCHAR(20) NOT NULL, /*空 或 WHOLE_ 或 SUM_ = 上传销售数据(DATA1=CHECKS,DATA2=CHKDETAIL,DATA3=CHECKRST,DATA4=ICCARD_CONSUME_INFO,DATA5=ABUYER)
                                       PACK 或 PACK WHOLE_ 或 PACK SUM_ = 上传销售数据(DATA1=没压缩的数据包,DATA2=压缩的数据包)
                                       ENDOFTIME=已完成上传RESERVE3指定日期的数据
                                       CNFFROMREMOTE=从远端传过来的配置数据(DATA1=传过来的压缩配置数据)
                                       CNFTOREMOTE=需要发送到远端的配置数据(DATA1=要传到远端的压缩配置数据)
                                     */
  DATA1        BYTEA,
  DATA2        BYTEA,
  DATA3        BYTEA,
  DATA4        BYTEA,
  DATA5        BYTEA,
  DATA6        BYTEA,
  DATA7        BYTEA,
  DATA8        BYTEA,
  DATA9        BYTEA,
  DATA10       BYTEA,
  ZIPTYPE      INTEGER DEFAULT 0, /*
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  4=gZipCompress
                                  10=经过MIME64编码
                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                  */
  SHOPID       VARCHAR(10) DEFAULT NULL,
  CLIENTIP     INET DEFAULT inet_client_addr(),
  SHOPNAME     VARCHAR(100),
  PACKTYPE     INTEGER DEFAULT 0, /*0 =WHOLE_ 或 SUM_ 单条上传销售数据(DATA1=CHECKS,DATA2=CHKDETAIL,DATA3=CHECKRST,DATA4=ICCARD_CONSUME_INFO,DATA5=ABUYER)
                                    1 =PACK 或 PACK WHOLE_ 或 PACK SUM_ = 上传销售数据(DATA1=没压缩的数据包,DATA2=压缩的数据包)
                                    2 =ENDOFTIME=已完成上传RESERVE3指定日期的数据
                                    3 =CNFFROMREMOTE=从远端传过来的配置数据(DATA1=传过来的压缩配置数据)
                                    4 =CNFTOREMOTE=需要发送到远端的配置数据(DATA1=要传到远端的压缩配置数据)
                                  */
  RECORDCOUNT  INTEGER,           /*打包的记录数据*/
  SERIALNUM    VARCHAR(40),        /*硬盘序列号*/
  WHOLEDAYFTOTAL    NUMERIC(15,3),     /*该店该天的帐单合计*/
  CASHIERSHIFT INTEGER DEFAULT 0, /*班次*/
  PRIMARY KEY (TDID)
);

CREATE TABLE TRANSFERDATA_BUFFER  /*门店上传到远端服务器的打包缓存区表*/
(
  TDID         INTEGER NOT NULL,
  PCID         VARCHAR(40) NOT NULL,
  Y            INTEGER NOT NULL,
  M            INTEGER NOT NULL,
  D            INTEGER NOT NULL,
  RESERVE3     VARCHAR(20) NOT NULL,
  CHECKID      INTEGER,
  TDSTATUS     INTEGER DEFAULT 0,    /*Buffer数据状态: -10=远端数据接收失败, 0=需要上传, 1=上传完成*/
  PREFIXTABLE  VARCHAR(20) NOT NULL, /*空 或 WHOLE_ 或 SUM_ = 上传销售数据(DATA1=CHECKS,DATA2=CHKDETAIL,DATA3=CHECKRST,DATA4=ICCARD_CONSUME_INFO,DATA5=ABUYER)
                                       PACK 或 PACK-WHOLE_ 或 PACK-SUM_ = 上传销售数据(DATA1=没压缩的数据包,DATA2=压缩的数据包)
                                       ENDOFTIME=已完成上传RESERVE3指定日期的数据
                                       CNFFROMREMOTE=从远端传过来的配置数据(DATA1=传过来的压缩配置数据)
                                       CNFTOREMOTE=需要发送到远端的配置数据(DATA1=要传到远端的压缩配置数据)
                                     */
  DATA1        BYTEA,
  DATA2        BYTEA,
  DATA3        BYTEA,
  DATA4        BYTEA,
  DATA5        BYTEA,
  DATA6        BYTEA,
  DATA7        BYTEA,
  DATA8        BYTEA,
  DATA9        BYTEA,
  DATA10       BYTEA,
  ZIPTYPE      INTEGER DEFAULT 0, /*
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  4=gZipCompress
                                  10=经过MIME64编码
                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                  */
  SHOPID       VARCHAR(10) DEFAULT NULL,
  CLIENTIP     INET DEFAULT inet_client_addr(),
  SHOPNAME     VARCHAR(100),
  PACKTYPE     INTEGER DEFAULT 0, /*0 =WHOLE_ 或 SUM_ 单条上传销售数据(DATA1=CHECKS,DATA2=CHKDETAIL,DATA3=CHECKRST,DATA4=ICCARD_CONSUME_INFO,DATA5=ABUYER)
                                    1 =PACK 或 PACKWHOLE_ 或 PACKSUM_ = 成批上传销售数据(DATA1=没压缩的数据包,DATA2=压缩的数据包)
                                    2 =ENDOFTIME=已完成上传RESERVE3指定日期的数据
                                    3 =CNFFROMREMOTE=从远端传过来的配置数据(DATA1=传过来的压缩配置数据)
                                    4 =CNFTOREMOTE=需要发送到远端的配置数据(DATA1=要传到远端的压缩配置数据)
                                  */
  RECORDCOUNT  INTEGER,           /*打包的记录数据*/
  SERIALNUM    VARCHAR(40),        /*硬盘序列号*/
  WHOLEDAYFTOTAL    NUMERIC(15,3),     /*该店该天的帐单合计*/
  CASHIERSHIFT INTEGER DEFAULT 0, /*班次*/
  PRIMARY KEY (TDID)
);

CREATE TABLE TRANDATA_BUF_CHECKIDS  /*上传远端服务器数据包对应CHECKID*/
(
  TDID         INTEGER NOT NULL,       /*TRANSFERDATA_BUFFER的TDID*/
  PCID         VARCHAR(40) NOT NULL,
  Y            INTEGER NOT NULL,
  M            INTEGER NOT NULL,
  D            INTEGER NOT NULL,
  RESERVE3     VARCHAR(20) NOT NULL,
  CHECKID      INTEGER NOT NULL,
  CASHIERSHIFT INTEGER DEFAULT 0,   /*班次*/
  PRIMARY KEY (TDID,PCID,Y,M,D,CHECKID)
);
/*end****************************************后台相关表格**************************************/

CREATE TABLE SMS_SENDOUTBOX  /*短信发送记录 lzm add 2011-01-09*/
(
  SMSID     SERIAL,         /**/
  SMSTIME   TIMESTAMP,      /*发送时间*/
  SMSTEL    VARCHAR(40),    /*手机号码*/
  SMSMSG    VARCHAR(254),   /*发送内容*/
  SMSSTAUS  VARCHAR(20),    /*发送状态字符串表示 "发送成功","发送失败","待发送"*/
  SMSOUTS   INTEGER,        /*发送状态 0=发送成功 1=发送失败 2=待发送*/
  SMSOPNAME VARCHAR(40),    /*操作员名称*/
  PRIMARY KEY (SMSID)
);

CREATE TABLE PHONENUM_QUEUE  /*历史来电的号码*/
(
  PNID      INTEGER NOT NULL,
  PCID      VARCHAR(40) NOT NULL,
  PHONENUM  VARCHAR(40),
  CALLTIME  VARCHAR(40),
  CALLOK    INTEGER,                /*是否接听 0=否 1=是 lzm add 2010-12-08*/
  CALLTYPE  VARCHAR(100),           /*来电内容 lzm add 2010-12-08*/
  CALLTYPE_LANGUAGE  VARCHAR(100),  /*来电内容_英文 lzm add 2010-12-08*/
  BUYERNAME VARCHAR(200),           /*客户名称 lzm add 2010-12-08*/
  BUYERTYPE VARCHAR(100),           /*客户类型 lzm add 2010-12-08*/
  BUYERTYPE_LANGUAGE VARCHAR(100),  /*客户类型_英文 lzm add 2010-12-08*/
  EMPNAME   VARCHAR(100),           /*操作员 lzm add 2010-12-08*/
  INTIME    TIMESTAMP DEFAULT date_trunc('second', NOW()),  /*来电时间 lzm add 2011-01-10*/
  CUSTOMINPUT INTEGER DEFAULT 1,      /*手动输入号码 0=电话来电 1=手动输入 lzm add 2011-01-10*/
  PRIMARY KEY (PNID,PCID)
);

CREATE TABLE SCHEDULED_TASKS /*计划任务*/
(
  STID  INTEGER NOT NULL,
  NAME  VARCHAR(40),         /*计划名词*/
  NAME_LANGUAGE VARCHAR(40), /*英文名称*/
  SDAY  VARCHAR(40),         /*日(格式:20080101,20080301 多个时用逗号","分隔)*/
  SWEEK  VARCHAR(40),        /*星期(格式:1,2,3,4,5,6,7 多个时用逗号","分隔)*/
  SMONTH  VARCHAR(40),       /*月份(格式:1,7,12 多个时用逗号","分隔)*/
  STIME VARCHAR(40),         /*时间*/
  EMPNAME  VARCHAR(40),      /*编写人*/
  BEFORESTIME VARCHAR(40),   /*上次运行时间*/
  BEFORERESULT VARCHAR(40),  /*上次运行结果*/
  PRIMARY KEY (STID)
);

CREATE TABLE VIPDISCOUNT  /*会员积分对应的折扣*/
(
  VSEMPLASSID     INTEGER NOT NULL,      /*会员类别编号*/
  VSLINEID        INTEGER NOT NULL,      /*折扣行编号*/
  VSQ             INTEGER NOT NULL,      /*积分数*/
  VSDISCOUNT      VARCHAR(10) NOT NULL,  /*折扣  10=10元,10%=9折*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,VSEMPLASSID,VSLINEID)
);

CREATE TABLE GRIDCOLSETUP  /*表格列设置*/
(
  GCID          INTEGER NOT NULL,
  GCGRIDID      VARCHAR(254) NOT NULL,
  GCFIELDNAME   VARCHAR(60),
  GCSYSNAME     VARCHAR(60),
  GCUSERNAME    VARCHAR(60),
  GCCAPTION     VARCHAR(100),
  GCWIDTH       INTEGER DEFAULT 10,
  GCVISIBLE     INTEGER DEFAULT 1,
  GCCOLORDER    INTEGER DEFAULT 0,

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,GCID)
);

CREATE TABLE CHECKIDHISTORY   /*记录已产生的帐单编号, 用于多次结束营业日*/
(
  ID         INTEGER NOT NULL,
  RESERVE3   TIMESTAMP,  /*日期*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID,RESERVE3)
);

CREATE TABLE MIWITHMI_CLASSSORT  /*有多个相同优惠类别时,那个优先*/
(
  MWMCID           SERIAL,
  MWMCLASSID       INTEGER NOT NULL,   /*(停用)类别id*/
  MWMCSORTCLASSID  INTEGER NOT NULL,   /*排列类别id*/
  MWMCSORTORDER    INTEGER DEFAULT 0,
  MWMCSORTCONDITION     INTEGER DEFAULT 0,  /*有两个相同类别品种时,那个优先.0=最低价优先,1=最高价优先*/
  MWMCLASSID_CHAR  VARCHAR(40),        /*类别ID*/
  MWMCNOTE         VARCHAR(40),        /*撞餐类别说明*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MWMCID)
);

CREATE TABLE MIWITHMI  /*(作废)多个品种优惠价格*/
(
  MWMID        SERIAL,
  MWMPRICE     NUMERIC(10,2) DEFAULT 0,  /*价格*/
  MWMCLASS1    INTEGER NOT NULL,         /*品种类别1*/
  MWMCLASS2    INTEGER NOT NULL,         /*品种类别2*/
  PRIMARY KEY (MWMID)
);

CREATE TABLE WORKTIME  /*员工上班表*/
(
  WTID         INTEGER NOT NULL,
  WTEMPID      INTEGER NOT NULL,
  WTEMPNAME    VARCHAR(40),
  WTSTARTTIME  TIMESTAMP,
  WTENDTIME    TIMESTAMP,
  WTSTPID      INTEGER,       /*班次编号*/
  WTSTPNAME    VARCHAR(40),   /*班次名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,WTID)
);

CREATE TABLE GENERATOR  /*编号*/
(
  GENERATORID   SERIAL,
  GENERATORNAME VARCHAR(40) NOT NULL ,
  VAL   NUMERIC(10,0) DEFAULT 0 NOT NULL ,
  VALCHAR       VARCHAR(40) DEFAULT '',
  VALTIME       TIMESTAMP,

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,GENERATORID)
);

CREATE TABLE EXCEPTION  /*错误信息，interbase*/
(
  EXCEPTIONID   SERIAL,
  EXCEPTIONNAME VARCHAR(100) NOT NULL ,
  VAL   VARCHAR(200) DEFAULT '' NULL ,
 PRIMARY KEY (EXCEPTIONID)
);

CREATE TABLE NOTCLOSEDBILLS /*记录当前没有结帐的单据*/
(
  CHECKID  INTEGER NOT NULL,
  STATUS   INTEGER DEFAULT 0 NOT NULL,  /*0=需要更新,1=需要删除*/
  INSERTTIME  TIMESTAMP,
  PRIMARY KEY (CHECKID)
);

CREATE TABLE UNTOUCHICCARDREG   /*记录进行登记IC卡逻辑号的卡信息*/
(
  ID    SERIAL,                 /**/
  CARDID        VARCHAR(40),    /**/
  CARDNUM       VARCHAR(40),    /**/
  TM    TIMESTAMP,              /**/
  EMPID INTEGER,                /**/
  EMPNAME       VARCHAR(40),    /**/
  PRIMARY KEY (ID)
);

CREATE TABLE CHECKIDLOG
(
  ID    INTEGER NOT NULL,
  PRIMARY KEY (ID)
);

/*停用*/
CREATE TABLE MENUITEMEXTEND     /*品种的扩展属性(已停用)*/
(
  MENUITEMID    VARCHAR(40),  /*MIDETAIL菜式编号-MENUITEMID*/
  MENUITEMNAME  VARCHAR(40),  /* 菜名-MENUITEMNAME,可填可不填  */
  RESERVE02     VARCHAR(40),  /*  */
  RESERVE03     VARCHAR(40),  /*  选择1*/
  RESERVE04     VARCHAR(40),  /*  选择2*/
  RESERVE05     VARCHAR(40),  /*  选择3*/
  RESERVE06     VARCHAR(40),  /*  选择4*/
  RESERVE07     VARCHAR(40),  /*  价格  */
  RESERVE08     VARCHAR(40),  /*  数量  */
  RESERVE09     VARCHAR(40),  /*  (时间编号) = TIMEPERIOD.TPID(SPID)*/
  RESERVE10     VARCHAR(40),  /*  条码 */
  RESERVE11     VARCHAR(40),  /*  用餐方式*/
  RESERVE12     VARCHAR(40),  /*  打印机*/
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
 PRIMARY KEY (MENUITEMID)
);

CREATE TABLE HANDCARD  /*手牌*/
(
  HANDCARDNUM  VARCHAR(40) NOT NULL,   /*手牌编号, 注意:要大小字母*/
  HANDCARDCAPTION  VARCHAR(40),        /*手牌标题*/
  HANDCARDSTATE  VARCHAR(10),          /*手牌现在的状态, LCLAID=15*/
  HANDCARDSTIME  TIMESTAMP,         /*开始使用时间*/
  HANDCARDCLOSETIME  TIMESTAMP,     /*最近一次消费的时间*/
  PRIMARY KEY (HANDCARDNUM)
);


CREATE TABLE ICCARDBLACKLIST  /*VIP黑名单*/
(
  ICCARDNO    VARCHAR(40) NOT NULL,

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  MEMO VARCHAR(100),                    /*备注 lzm add 2012-06-15*/
  TYPEID      INTEGER DEFAULT 0,        /*黑名单类型 0=黑名单 1=挂失 2=作废 lzm add 2012-07-03*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ICCARDNO)
);


CREATE TABLE ARTIFICER_ORDER  /*技师排队表*/
(
  AFORDERCLASS  INTEGER DEFAULT 0 NOT NULL,   /*所属队列的类别*/
  AFSTATE  INTEGER DEFAULT 10 NOT NULL,        /*状态(9=接到信息将要上钟;10=闲置,正在等待上钟;11=正在上钟)*/
  AFORDERID  INTEGER DEFAULT 0 NOT NULL,      /*队列排列ID*/
  AFORDERDATETIME TIMESTAMP NOT NULL,
  /*  AFORDERTIMESTAMP  TIMESTAMP NOT NULL,        /*队列排列时间顺序*/*/
  AFTEMPORDER integer DEFAULT 0 NOT NULL,          /*用于同一时间AFORDERTIMESTAMP时的排序*/
  EMPID  integer NOT NULL,       /*技师ID*/
  CALLTIME  TIMESTAMP,           /*呼叫上钟时的时间,
                                   在该时间后的一段时间该技师还没有去上钟则系统自动重新安排其他技师服务该客户
                                 */
  ATABLESID  INTEGER,            /*要服务的台号ID*/
  ATABLESNAME  VARCHAR(20),         /*要服务的台号名称*/
  CHECKID  INTEGER,              /*要服务的单据号*/
  CHKDETAIL_LINEID  INTEGER,     /*要服务的单据详细行号*/
  PRIMARY KEY (AFORDERCLASS, AFSTATE, AFORDERID, AFORDERDATETIME, AFTEMPORDER)
);
/*
delete from artificer_order;

insert into artificer_order values(0,9,0,'2004-04-22 01:01:01',0,1,'2004-04-22 02:01:02',1,'南海神尼1',1,1);
insert into artificer_order values(0,10,0,'2004-04-22 01:02:01',0,111,'2004-04-22 02:02:02',1,'南海神尼2',1,1);
insert into artificer_order values(0,9,0,'2004-04-22 01:03:01',0,112,'2004-04-22 02:03:02',1,'南海神尼3',1,1);
insert into artificer_order values(0,10,0,'2004-04-22 01:04:01',0,113,'2004-04-22 02:04:02',1,'南海神尼4',1,1);

commit;
*/



CREATE TABLE STOCKTIME  /*期初库存*/
(
  THETIME  TIMESTAMP NOT NULL,        /*期初日期时间*/
  THENUM  VARCHAR(20) NOT NULL,          /*期初编号*/
  MENUITEMID  INTEGER NOT NULL,       /*品种编号*/
  MENUITEMNAME  VARCHAR(100),            /*品种名称*/
  COUNTS  NUMERIC(15, 3),    /*数量*/
  COST  NUMERIC(15, 3),      /*成本*/
  FINISHED INTEGER DEFAULT 0,        /*0或空:正在处理,1:已处理完毕是正式的期初库存*/
  PRIMARY KEY (THETIME,THENUM,MENUITEMID)
);


CREATE TABLE STOCKTIME_HISTORY  /*历史期初库存*/
(
  THETIME  TIMESTAMP NOT NULL,        /*期初日期时间*/
  THENUM  VARCHAR(20) NOT NULL,          /*期初/期末(begin/end) 编号*/
  MENUITEMID  INTEGER NOT NULL,       /*品种编号*/
  MENUITEMNAME  VARCHAR(100),            /*品种名称*/
  COUNTS  NUMERIC(15, 3),    /*数量*/
  COST  NUMERIC(15, 3),      /*成本*/
  FINISHED INTEGER DEFAULT 0,        /*0或空:正在处理,1:已处理完毕是正式的期初库存*/
  PRIMARY KEY (THETIME,THENUM,MENUITEMID)
);

/*下拉项
1=颜色,
2=尺寸大小
3=客户类型
4=证件类型
5=国籍
6=籍贯
7=称谓(先生,女士,夫人,小姐)
8=护照类型
9=签证类型
10=房间(台号)状态
11=房间(台号)楼层
12=房间(台号)类别
13=房间(台号)类型
14=性别
15=手牌的状态
16=单据是否有效
17=品种类别
18=收银员班次
19=取消原因
20=是否
21=付款类型
22=预定类型
23=所属宾客
*/
CREATE TABLE LISTCLASS  /*下拉项 */
(
  LCLAID   INTEGER NOT NULL,
  CAPTION  VARCHAR(40),
  CAPTION_LANGUAGE  VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,LCLAID)
);


CREATE TABLE LISTCONTENT  /*下拉内容*/
(
  LCLAID    INTEGER NOT NULL,
  LCONID    INTEGER NOT NULL,
  CONTENTS  VARCHAR(40),        /*下拉内容*/
  SHUTCUTKEY  VARCHAR(40),      /*下拉内容的缩写. 例如LCLAID=5时 代表该国家的简称*/
  OTHERINFO  VARCHAR(40),       /*下拉内容的相关信息
                              当:LCLAID=10时 0=不能进入该台,空和1=允许进入该台
                             */
  CONTENTS_LANGUAGE VARCHAR(40), /*英语*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY(USER_ID,SHOPID,SHOPGUID,LCLAID,LCONID)
);

/* Table: REPORTTEMP, Owner: SYSDBA */

CREATE TABLE REPORTTEMP
(
  RPID          INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  COL01         VARCHAR(200),
  COL02         VARCHAR(200),
  COL03         VARCHAR(200),
  COL04         VARCHAR(200),
  COL05         VARCHAR(200),
  COL06         VARCHAR(200),
  COL07         VARCHAR(200),
  COL08         VARCHAR(200),
  COL09         VARCHAR(200),
  COL10         VARCHAR(200),
  COL11         VARCHAR(200),
  COL12         VARCHAR(200),
  COL13         VARCHAR(200),
  COL14         VARCHAR(200),
  COL15         VARCHAR(200),
  COL16         VARCHAR(200),
  COL17         VARCHAR(200),
  COL18         VARCHAR(200),
  COL19         VARCHAR(200),
  COL20         VARCHAR(200),
  PRIMARY KEY (RPID,LINEID)
);

/* Table: MATERIAL, Owner: SYSDBA */
/*原材料*/
CREATE TABLE MATERIAL  /*停用---------已被进销存的品种表代替*/
(
  MTID          INTEGER NOT NULL,
  MTNAME        VARCHAR(100) NOT NULL,
  MTUNITENAME   VARCHAR(10) DEFAULT '',      /*"单位1"名称*/
  MTAMOUNT      NUMERIC(15, 3) DEFAULT 0,    /*#########停用*/
  MTAMOUNTPRICE NUMERIC(15, 3) DEFAULT 0,    /*#########停用*/
  SORTID        INTEGER DEFAULT 0,           /*排列顺序*/
  MTCOUNTS      NUMERIC(15, 3) DEFAULT 0,    /*数量*/
  MTCOUNTSPRICE NUMERIC(15, 3) DEFAULT 0,    /*数量价格*/
  MT2UNITENAME   VARCHAR(10) DEFAULT '',     /*"单位2"名称*/
  MT2RATIOMT1   NUMERIC(15, 5) DEFAULT 0,    /*1个"单位2"=多少个"单位1"*/
  MTUSERCODE    VARCHAR(50) DEFAULT NULL,    /*商品编号*/
  MTSHORTNAME   VARCHAR(20) DEFAULT NULL,    /*简称*/
  PINYIN        VARCHAR(20) DEFAULT NULL,    /*拼音*/
  MODEL         VARCHAR(30) DEFAULT NULL,    /*型号*/
  SPEC          VARCHAR(30) DEFAULT NULL,    /*规格*/
  AREA          VARCHAR(30) DEFAULT NULL,    /*地区*/
  MTSORT        VARCHAR(30) DEFAULT NULL,    /*分类*/
  BARCODE       VARCHAR(50) DEFAULT NULL,    /*条码*/
  MTPURCH       NUMERIC(15, 3) DEFAULT 0,    /*进货价*/
  CONSTPRICE    NUMERIC(15, 3) DEFAULT 0,    /*成本价*/
  PRICE1        NUMERIC(15, 3) DEFAULT 0,    /*预设价格1*/
  PRICE2        NUMERIC(15, 3) DEFAULT 0,    /*预设价格2*/
  PRICE3        NUMERIC(15, 3) DEFAULT 0,    /*预设价格3*/
  PRICE4        NUMERIC(15, 3) DEFAULT 0,    /*预设价格4*/
  UP_LIMIT      NUMERIC(15, 3) DEFAULT 0,    /*库存上限*/
  DOWN_LIMIT    NUMERIC(15, 3) DEFAULT 0,    /*库存下限*/
  MEMO          TEXT DEFAULT NULL,           /*备注*/
  MTUSE         INTEGER DEFAULT 1,           /*是否使用*/
  MTMODE        INTEGER DEFAULT 0,           /**/
  TREEPARENT    INTEGER DEFAULT 0,
  MTLEVEL       VARCHAR(50) DEFAULT NULL,
  SEEDCOUNT     INTEGER DEFAULT 0,
  PARENTID      INTEGER DEFAULT 0,
  ROOTID        INTEGER DEFAULT 0,
  PRIMARY KEY (MTID)
);

/* Table: COMMONLYWORDS, Owner: SYSDBA */

CREATE TABLE COMMONLYWORDS  /*常用词 lzm add 2009-08-20*/
(
  CWCLASSID  INTEGER NOT NULL,          /*类别编号 1=品种名称查找 2=附加信息 3=自定义品种 4=单位.公司名称 5=地址 6=其它 7=提现*/
  CWWORDS    VARCHAR(100) NOT NULL,      /*常用词或字*/
  CWUSECOUNT INTEGER NOT NULL,          /*使用次数*/
  PRIMARY KEY (CWCLASSID,CWWORDS)
);

/* Table: ABUYER, Owner: SYSDBA */

/*
语言
客户类型(散客,团队,会议,长包公司,永久帐户)
证据类型(身份证,驾驶执照...)
证据号码
;地址
;邮编
国籍
籍贯
生日/出生日期
;性别
称谓(先生,女士,夫人,小姐)
护照类型
护照号码
签证类型
签证有效期
会员类型
会员号码
会员期限
;电话
传真
EMAIL
职务
公司
满意房间
房间服务
特殊要求
*/
CREATE TABLE ABUYER
(
  ABID  SERIAL,
  BUYERID       VARCHAR(40) DEFAULT '' NOT NULL,
  BUYERNAME     VARCHAR(200),          /*姓名*/
  BUYERADDRESS  VARCHAR(200),          /*地址*/
  BUYERTEL      VARCHAR(100),          /*手机*/
  BUYERSEX      VARCHAR(10),           /*性别*/
  BUYERZIP      VARCHAR(20),           /*邮编*/

  BUYERLANG     VARCHAR(40),           /*语言*/
  BUYERFAX     VARCHAR(40),            /*传真*/
  BUYEREMAIL   VARCHAR(40),            /*EMAIL*/
  BUYERPOSITION  VARCHAR(40),          /*职务*/
  BUYERCOMPAY  VARCHAR(40),            /*单位.公司名称*/
  BUYERTYPEID     VARCHAR(10),         /*客户类型编号(A卡,B卡,C卡,D卡,E卡,散客,团队,会议,长包公司,永久帐户...)*/
  BUYERCERTIFICATEID  VARCHAR(10),     /*证件类型编号(身份证,驾驶执照...)*/
  BUYERCERTIFICATENUM  VARCHAR(50),    /*证件号码*/
  BUYERNATIONALITYID  VARCHAR(10),     /*国籍编号(中国,美国,德国...)*/
  BUYERNATIVEPLACEID  VARCHAR(10),     /*籍贯编号(广州,北京,上海,成都...)*/
  BUYERBIRTHDAY  TIMESTAMP,            /*生日.出生日期*/
  BUYERTITLEID    VARCHAR(10),         /*称谓编号(先生,女士,夫人,小姐...)*/
  BUYERPASSPORTTYPEID  VARCHAR(10),    /*护照类型编号(...)*/
  BUYERPASSPORTNUM  VARCHAR(50),       /*护照号码*/
  BUYERVISATYPEID  VARCHAR(10),        /*签证类型编号(...)*/
  BUYERVISAVALIDDAY  TIMESTAMP,        /*签证有效日期*/
  BUYERIMAGEDIR  VARCHAR(50),          /*照片路径*/

  BUYERDEPUTY  VARCHAR(20),            /*企业代表人*/
  BUYERLIKEROOM  VARCHAR(50),          /*满意房间*/
  BUYERSERVICE  VARCHAR(100),          /*房间服务*/
  BUYERSPECIALNEED  VARCHAR(200),      /*特殊要求*/
  BUYERCONFERCON  VARCHAR(254),        /*协议内容*/
  BUYERNOTE1  VARCHAR(200),            /*备注*/
  BUYERISCONFER  INTEGER,              /*是否协议单位 0=否,1=是*/
  BUYERCLASS  INTEGER,                 /*所属宾客 0=内宾,1=外宾(1001=欧美 1002=亚洲),2=香港,3=台湾*/
  BUYERWRITEMAN  VARCHAR(200),         /*签单人*/
  BUYERCODE  VARCHAR(20),              /*会员代码*/
  BUYERPINYIN  VARCHAR(20),            /*拼音*/
  LASTCONSUMEDATE TIMESTAMP,           /*最后消费日期*/
  --BUYERROWSTATUS INTEGER DEFAULT 0,  /*数据状态: 0=新记录, 1=已同步*/

  ADDEMPNAME  VARCHAR(40),             /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,               /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),             /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),             /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,               /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),             /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),             /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,               /*同步时间VER7.2.0 X3*/

  --IDVALUE     VARCHAR(40),             /*卡号 lzm add 2010-05-07*/
  BUYERTEL1   varchar(100),            /*电话1 lzm add 2010-12-08*/
  BUYERTEL2   varchar(100),            /*电话2 lzm add 2010-12-08*/
  BUYERTEL3   varchar(100),            /*电话3 lzm add 2010-12-08*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY(USER_ID,SHOPID,SHOPGUID,ABID)
);

/*
alter table ABUYER drop BUYERTYPEID;
alter table ABUYER drop BUYERCERTIFICATEID;
alter table ABUYER drop BUYERCERTIFICATENUM;
alter table ABUYER drop BUYERNATIONALITYID;
alter table ABUYER drop BUYERNATIVEPLACEID;
alter table ABUYER drop BUYERBIRTHDAY;
alter table ABUYER drop BUYERTITLEID;
alter table ABUYER drop BUYERPASSPORTTYPEID;
alter table ABUYER drop BUYERPASSPORTNUM;
alter table ABUYER drop BUYERVISATYPEID;
alter table ABUYER drop BUYERVISAVALIDDAY;
alter table ABUYER drop BUYERVIPID;
*/

/* Table: ACCLEVEL, Owner: SYSDBA */

CREATE TABLE ACCLEVEL /**/
(
  ACCESSLEVEL   INTEGER NOT NULL,
  FUNCNUMBER    INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
 PRIMARY KEY (ACCESSLEVEL, FUNCNUMBER)
);

/* Table: APRINTERS, Owner: SYSDBA */

CREATE TABLE APRINTERS
(
  PRINTERID     INTEGER NOT NULL,
  LOGICPRNNAME  VARCHAR(100), /*逻辑打印机名称*/
  PHYICPRNNAME  VARCHAR(100), /*系统打印机名称 OPOS(OPOSCOM1 OPOSCOM2 ..)*/
  RESERVE01     VARCHAR(40),  /*打印机所在的机器IP*/
  RESERVE02     VARCHAR(40),  /*打印机类型*/
  RESERVE03     VARCHAR(40),  /*打印方法:0=通过打印驱动程序 1=通过打印驱动程序发控制码打印 3=通过串并口直接打印  (作废->:0=driverrawprint,1=drivercodeprint,2=driverdocprint,3=oposprint)*/
  RESERVE04     VARCHAR(40),  /*候选1(曾经停用)*/
  RESERVE05     VARCHAR(40),  /*分单打印时的总单:一个品种一张单 0=否 1=是                      【之前：候选2(停用)】*/
  RESERVE06     VARCHAR(40),  /*上菜不需要打印分单 0=否 1=是 //lzm modiry 2013-01-15                     【之前：候选3(停用)】*/
  RESERVE07     text,         /*其它设置 --lzm add 2023-08-02 04:28:08                         【之前：候选4(停用)】
                                {
                                  "kichen_performance_print": "0=无 1=打印绩效条码 2=打印绩效二维码",
                                  "kichen_performance_cut": "0=不切纸 1=半切纸 2=全切纸"
                                }
                              */
  RESERVE08     VARCHAR(40),  /*打印失败的逻辑打印机跳单顺序
                                多个时用","分隔
                              */
  RESERVE09     VARCHAR(200), /*总单打印机 多个时用逗号","分隔*/
  RESERVE10     VARCHAR(40),  /*单据抬头*/
  RESERVE11     VARCHAR(40),  /*打印机所在的机器名称(用于判断是否是本机) 空代表本地打印 */
  RESERVE12     VARCHAR(40),  /*打印端口(LPT1:,COM1)*/
  TOASPRINT     INTEGER DEFAULT 0, /*分单或总单打印(ToAllSinglePrint),0=总单打印,1=分单打印,2=先总单后分单,3=先分单后总单*/
  COMPARAM      VARCHAR(40),  /*串口参数*/
  TPPRINT       INTEGER DEFAULT 0, /*总单品种打印方法: 0=合并打印 1=按逻辑打印机分开打印*/
  TCALONEPRNINTP   INTEGER DEFAULT 0, /*总单的套餐需要单独打印: 0=不需要 1=需要单独打印*/
  PRNSTATUS     INTEGER,      /*打印机状态*/
  LABELPARAM    VARCHAR(200), /*标签打印机参数，用逗号分隔参数.*/
  TOTALPAGEM    INTEGER DEFAULT 3,    /*总单打印机的打印方式
                                        0=不打印
                                        1=打印到本打印机
                                        2=打印到台号指定的总单打印机
                                        3=打印到RESERVE09指定的打印机
                                      */
  WORKTYPE      INTEGER DEFAULT 0,    /*工作方式 0=需要打印 1=该打印机停止打印*/
  BITMAPFONT    INTEGER DEFAULT 0,    /*按位图方式打印所有文字*/

  PCOPYSINALL   INTEGER DEFAULT 1,    /*总单打印份数 lzm add 2009-08-01*/
  PCOPYSINSIN   INTEGER DEFAULT 1,    /*分单打印份数 lzm add 2009-08-01*/
  NEEDCHGTLE    INTEGER DEFAULT 0,    /*是否需要转台单 lzm add 2010-06-29 */
  HASTENPRN     VARCHAR(200),         /*催单打印机 lzm add 2010-08-19*/
  BEEPBEEP      INTEGER DEFAULT 0,    /*来单蜂鸣提醒 lzm add 2010-09-29*/
  VOIDOTHERPRN  VARCHAR(200),         /*取消单逻辑打印机 lzm add 2010-11-03*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  KICHENPRINTER INTEGER DEFAULT 0,          /*是否出品打印机，目前用于上菜操作的厨房打印 lzm add 2018-10-23 03:37:25*/
  QJPRINTER VARCHAR(100) DEFAULT '',        /*上菜时厨房需要打印的打印机，空=跟出品打印机 非空=指定的逻辑打印机,多个是用逗号分隔  lzm add 2018-10-23 03:39:06*/
  
  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,PRINTERID)
);

CREATE TABLE ATABLESECTIONS  /*区域名称*/
(
  SECNUM      SERIAL,
  SECID       VARCHAR(10) DEFAULT '',
  SECNAME     VARCHAR(40),
  SECNAME_LANGUAGE  VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,SECNUM)
);

/* Table: ATABLES, Owner: SYSDBA */

CREATE TABLE ATABLES
(
  ATABLESID     INTEGER NOT NULL,
  ATABLESNUM    INTEGER,                /* not use again */
  SEATCOUNT     INTEGER,                /* 容许最大人数*/
  TABLEUSED     INTEGER DEFAULT 0,      /* 0空闲， 1被占用  newadd  2预订,3合桌(被合并到的,核心的),4拆台,5维修,6清洁,7预订,8过夜*/
  RESERVE01     VARCHAR(40),            /* 台号名称 use to remember the table name 不能有重复*/
  RESERVE02     VARCHAR(40),            /* 如为合桌或拆台,则记录是从那个台号合桌或拆台,格式:拆+台号,并+台号，如为预定则记录'Book'*/
  RESERVE03     VARCHAR(40),            /* 餐区,即台号分区显示*/
  RESERVE04     VARCHAR(40),            /* aTOUCHSCRLINEID*/
  RESERVE05     VARCHAR(40),            /* aTSCHID */
  SMSTABLEID    VARCHAR(10),            /* 短信点菜的台号编号*/
  SORTORDER     INTEGER DEFAULT 0,      /* 排列序号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '', /* 要打印到的逻辑打印机*/

  BUILDINGNUM   VARCHAR(20),            /*楼号,那栋楼*/
  FLOORNUM      VARCHAR(20),            /*楼层*/
  ATABLECLASS   VARCHAR(20),            /*类别(房间,台号,厅,计时房间或椅号,散客区)*/
  ATABLETYPE    VARCHAR(20),            /*类型(标准,单人,双人,三人,四人,五人,普通套房,豪华套房)*/
  BEGINORDER    VARCHAR(40),            /*开房或台时要执行的命令*/
  BEGINMENUITEM VARCHAR(40),            /*开房或台时要消费的品种*/
  MINPRICE_MENUITEMID  VARCHAR(40),     /*最低消费对应的品种编号*/
  TABLEPRICE    NUMERIC(15, 3) DEFAULT 0,        /*房间价格                         100元  */
  COMPUTETIME   INTEGER DEFAULT 0,               /*房价计算时间(分钟)               60分钟:代表每小时100元   */
  UNITTIME      INTEGER DEFAULT 0,               /*房价最小单位(分钟)要小于计算时间 30分钟:代表半小时一计    */
  MINPRICE_NOTT INTEGER DEFAULT 0,         /*最低消费是否包括特价品种(T:) 0＝否，1＝是*/
  MINPRICE_MAN  INTEGER DEFAULT 0,         /*最低消费按人数算 0＝否，1＝是*/
  THETABLE_IST  INTEGER DEFAULT 0,         /*房价特价不打折 0＝否，1＝是*/
  THETABLE_ISF  INTEGER DEFAULT 0,         /*房价免服务费 0＝否，1＝是*/
  MINPRICE_NOTTABLE  INTEGER DEFAULT 0,    /*最低消费是否包括房价 0＝否，1＝是*/
  NEEDSUBTABLEID INTEGER DEFAULT 1,        /*同台多单时需要录入子台号*/
  UNITEATABLEID  VARCHAR(40),              /*合并台号的ID，用于并台*/
  TBLPRICE_MENUITEMID VARCHAR(40),         /*房价对应的品种编号*/
  TBLTOTALPAGEPRN  VARCHAR(40),            /*总单打印机*/
  ADDPARTYNUM   INTEGER DEFAULT 0,         /*允许搭台的数量. >1才会在前台弹出搭台窗口,例如6=(A,B,C,D,E,F)*/
  TRUNTOPRINT   VARCHAR(240),              /*打印机转向设置(一行设置一个打印机的转向) 例如:一楼厨房=二楼厨房 */
  TABLECOLOR    VARCHAR(40),               /*台号的颜色 空:还原颜色的正常显示 lzm add 2010-06-06*/
  WEB_TAG      INTEGER DEFAULT 0,          /*需要同步到 web_atables lzm add 2011-03-30*/

  FWFMC VARCHAR(40),   /*服务费名称---->根据简单设置表的服务费名称得到相应的服务费率>>>用在Android 手机 lzm add 2011-09-23*/

  COMMISSIONVALUE NUMERIC(15, 3) DEFAULT 0,  /*帮订人的提成起始金额 lzm add 2011-10-12*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/


  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ATABLESID)
);

/* Table: BTNFUNC, Owner: SYSDBA */

CREATE TABLE BTNFUNC
(
  BCID  INTEGER NOT NULL,
  ANUMBER       INTEGER NOT NULL,
  FUNCNUMBER    INTEGER,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
 PRIMARY KEY (BCID, ANUMBER)
);

/* Table: DINMODES, Owner: SYSDBA */

CREATE TABLE DINMODES
(
  MODEID        INTEGER NOT NULL,
  MODENAME      VARCHAR(100),       /*名称*/
  PERDISCOUNT   NUMERIC(15, 3),     /*折扣(停用)*/
  PERSERCHARGE  NUMERIC(15, 3),     /*服务费*/
  KICHENPRINTCOLOR      INTEGER DEFAULT 0, /**/
  RESERVE01     VARCHAR(40),        /*开单时自动点菜[菜式编号{数量}]..[]*/
  RESERVE02     VARCHAR(40),        /*开单时自动执行的命令[BCID,ANUMBER{界面编号}{按钮参数}]...[]*/
  RESERVE03     VARCHAR(40),        /* 单据类型,要结合RESERVE04:
                                       空和0=【RESERVE04="－"时为:销售单(餐饮的"堂吃"属于销售单)】,【RESERVE04="＋"时为:销售退单】;
                                       1=【RESERVE04="＋"时为:进货单】,【RESERVE04="－"时为:进货退单】;
                                       2=【盘点单,同时RESERVE04="=="】,【RESERVE04="=＋"时为:报益单】,【RESERVE04="=－"时为:报损单】;
                                       3=【RESERVE04="=＋"时为:退料单】,【RESERVE04="=－"时为:领料单】;

                                    */
  RESERVE04     VARCHAR(40),        /* 该单的品种为正数或负数 +:正数,-:负数,nil:不参与计算,空:负数,=:与库存一致*/
  RESERVE05     VARCHAR(40),        /* 预留 历史:停用->(点品种时要执行的命令[])*/
  MUSTCLASS1    VARCHAR(100),       /*必须点的品种类别1(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS2    VARCHAR(100),       /*必须点的品种类别2(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS3    VARCHAR(100),       /*必须点的品种类别3(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS4    VARCHAR(100),       /*必须点的品种类别4(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  DMNEEDTABLE   INTEGER DEFAULT 1,  /*可以不录入台号 0=否,1=是*/
  DMNOTPERPAPER INTEGER DEFAULT 0,  /*不需要入单纸 lzm add 2010-05-15*/
  GENIDTYPE     INTEGER DEFAULT 0,  /*单号的产生方式 0=跟系统 1=顺序号 2=随机号 3=人工单号 lzm add 2011-05-23*/
  NOTPERPAPER   INTEGER DEFAULT 0,  /*不要厨房分单 0=否 1=是 lzm add 2012-07-10*/
  NOTSUMPAPER   INTEGER DEFAULT 0,  /*不要厨房总单 0=否 1=是 lzm add 2012-07-09*/
  NOTVOIDPAPER  INTEGER DEFAULT 0,  /*不需要退单纸 lzm add 2012-08-08*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MODEID)
);

/* Table: DISCOUNT, Owner: SYSDBA */

CREATE TABLE DISCOUNT  /*折扣*/
(
  DISCOUNTID    INTEGER NOT NULL,
  DISCOUNTNAME  VARCHAR(40),
  DISCOUNTTYPE  INTEGER,         /*0=百分比, 1=金额*/
  PERDISCOUNT   NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTDISCOUNT   NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  LIDU  INTEGER,           /*
                             = 0; //整单打折
                             = 1; //行打折
                             = 2; //下一菜式要打折
                             = 3; //取消打折
                             = 4; //整单品种打折 (之前:不用授权的VIP卡打折)

                             //可以有5种不同的VIP折扣
                             = 11; //A卡折扣
                             = 12; //B卡折扣
                             = 13; //C卡折扣
                             = 14; //D卡折扣
                             = 15; //E卡折扣
                           */
  BCID  INTEGER,
  ANUMBER       INTEGER,
  RESERVE01     VARCHAR(40),   /* 是否优惠卡(即：是否可以打折)   0和空:非优惠卡,1:优惠卡 */
  RESERVE02     VARCHAR(40),   /*计算的方式 1=开新单计，2＝即时计*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  HOLIDAY       VARCHAR(40),     /*假期*/
  TIMEPERIOD    VARCHAR(40),     /*时段*/
  DINMODES      VARCHAR(40),     /*用餐方式编号*/
  WEEK          VARCHAR(40),     /*星期*/

  DISCOUNT_LEVEL INTEGER,   /*折扣级别>>>用在Android 手机 lzm add 2011-09-23*/
  REPORT_TYPE VARCHAR(40),   /*折扣类型 赠送 招待(现在没有使用这个域值)>>>用在Android 手机 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,DISCOUNTID)
);

CREATE TABLE HELPBOOKPOSITION /*帮订人职位信息 lzm add 用于酒吧预订时输入帮订人 2011-10-12*/
(
  ID INTEGER NOT NULL,
  HBPPOSITION   VARCHAR(40) NOT NULL,       /*职位名称*/
  SPLITTIME     VARCHAR(40) NOT NULL,       /*分割点时间,格式 HH:NN 例如 20:00*/
  BEFORVALUE    VARCHAR(40) NOT NULL,       /*分隔时间前提成值 0或空=无提成 10%=提成10% 10=提成10元*/
  AFTERVALUE    VARCHAR(40) NOT NULL,       /*分隔时间后提成值 0或空=无提成 10%=提成10% 10=提成10元*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);

CREATE TABLE HELPBOOKPEOPLE  /*帮订人(帮忙预订人) lzm add 用于酒吧预订时输入帮订人 2011-10-12*/
(
  ID INTEGER NOT NULL,
  HBPNAME       VARCHAR(40) NOT NULL,   /*员工名称*/
  HBPPOSITION   VARCHAR(40) NOT NULL,   /*职位名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);

/* Table: LEVELCLASS, Owner: SYSDBA */

CREATE TABLE LEVELCLASS  /*员工级别权限设置 lzm add 2010-06-13*/
(
  LEVELID        INTEGER NOT NULL,               /**/
  DISCOUNT       NUMERIC(15,3) DEFAULT 0,        /*允许的最高折扣 0.1=9折扣*/
  AMTDISCOUNT    NUMERIC(15,3) DEFAULT 0,        /*允许的最高的折扣金额(用于直接金额折扣)*/
  PRESENTRANGE   VARCHAR(20) DEFAULT '',         /*允许的赠送金额范围 10,100,0-100*/
  PRESENTDAY     NUMERIC(15,3) DEFAULT 0,        /*一天的赠送上限*/
  PRESENTWEEK    NUMERIC(15,3) DEFAULT 0,        /*一星期的赠送上限*/
  PRESENTMONTH   NUMERIC(15,3) DEFAULT 0,        /*一个月的赠送上限*/
  SIGNBILLDAY    NUMERIC(15,3) DEFAULT 0,        /*一天的积签上限*/
  SIGNBILLWEEK   NUMERIC(15,3) DEFAULT 0,        /*一星期的积签上限*/
  SIGNBILLMONTH  NUMERIC(15,3) DEFAULT 0,        /*一个月的积签上限*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,LEVELID)
);

/* Table: EMPCLASS, Owner: SYSDBA */

CREATE TABLE EMPCLASS
(
  EMPCLASSID    INTEGER NOT NULL, /*会员EMPCLASSID=1..10000 VIP卡EMPCLASSID=10001..10005  lzm modify 分开接收员工和会员信息 2012-4-23*/
  EMPCLASSNAME  VARCHAR(40),   /*类别名称*/
  TSID  INTEGER,               /*登录到的界面编号*/
  ACCESSLEVEL   INTEGER,       /*
                               0-Admin管理权限,
                               1-Normal普通权限,
                               2-cFreeRight,
                               3-咨客开单,
                               4-桑那钟房,
                               5-技师,
                               6-客房管理员
                               7-服务员或吧女,用于推销酒水或其它品种的提成
                               8-划单员
                               9-厨房绩效

                               等于以下值时，对应Discount表的:LIDU(凹度):可以知道该用户的折扣率
                               11=A卡
                               12=B卡
                               13=C卡
                               14=D卡
                               15=E卡
                               */
  RESERVE01     VARCHAR(40),   /*员工类型,-1=隐藏该用户,0=员工,1=VIP*/
  RESERVE02     VARCHAR(40),   /*普通、银、金卡、白金卡： Money
                               亦可作该卡的最低金额
                               */
  RESERVE03     VARCHAR(40),   /*卡的明细类型
                               0=普通员工磁卡
                               1=高级员工磁卡（有打折功能）
                               2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                               3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                               4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                               6=微信会员卡 //lzm add 2016-05-28 10:22:20
                               */
  RESERVE04     TEXT,           /*YPOS的权限 lzm add 2018-12-04 03:14:40【之前是：2=管理库存权限,】
                                  jb = {
                                    shopname:"",                      --店名
                                    loginuserdiscount_upperlimit:"",  --折扣上限   例如:10% 代表只能进行0%到10%的折扣
                                    loginuser_ql_discount_upperlimit; --例如:10 代表只能进行0到10的去零
                                    loginuserStorage:"",              --是否启用联机的库存管理   ""或0  不进过服务器    1使用服务器处理库存
                                    loginuserType:"",                 --5：系统管理员 4：老板   3：经理  2：财务人员  1：部长  0:普通业务员
                                    loginuserIsFreePrice:"",          --0:不启用   1:启用改价格功能
                                    loginuserMode:"",                 --0:没有PC    1:经过互联网下服务器PC    2:直接通过局域网连接PC
                                    jb:""                             --改为“员工类别” --lzm modify 2023-11-19 21:53:48 【之前是：--折扣级别  0是缺省级别，数字越高，级别越高】
                                  }
                                */
  RESERVE05     VARCHAR(40),    /*要登录的界面,多个界面时用分号(";")分隔*/
  SMSTABLEID    VARCHAR(10),    /*短信台号*/
  BEFOREORDER   VARCHAR(100),   /*登陆时要执行的命令*/
  PCID          VARCHAR(40) DEFAULT '',  /*空=门店员工信息和门店VIP卡信息 */
  GRANTSTR      VARCHAR(200),            /*用户权限,拥有的权限用逗号分割
                                           [
                                           位置1:领料单是否允许修改单价 0=否1=是
                                           位置2:退料单是否允许修改单价 0=否1=是
                                           位置3:直拨单的供应商编号对应的单价是否允许修改
                                                (格式:  01;02=1 代表:只允许编号为01或02的供应商修改单价
                                                        01=1    代表:只允许编号为01的供应商时修改单价)
                                           位置4:进货单的供应商编号对应的单价是否允许修改
                                                (格式:  01;02=1 代表:只允许编号为01或02的供应商修改单价
                                                        01=1    代表:只允许编号为01的供应商时修改单价)
                                           ]*/
  MUSTWORKON    INTEGER DEFAULT 0,       /*必须上班才能登陆 0=否 1=是*/
  AFTERPRNBILLSCID  VARCHAR(40),         /*印整单后点击台号进入的界面*/

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  OPENBILLSCID  VARCHAR(40),            /*如果该单有内容则点击台号进入的界面*/
  MIDETAILSCID  VARCHAR(40),            /*该类员工使用的品种界面用逗号分割 500,600,1000,700*/

  LEVELID       INTEGER DEFAULT 0,      /*权限级别 对应授权级别表"LEVELCLASS"的LEVELID lzm add 2010-06-13*/
  AFTERTBLSCID  VARCHAR(40),            /*点击台号后进入的界面 lzm add 2010-07-26*/
  PHONECALLAUTO INTEGER DEFAULT 0,      /*自动弹出来电显示窗口的停留时间 0=不弹出来电窗口 -1=不自动关闭 lzm add 2010-12-21*/
  PRESENTITEM   INTEGER DEFAULT 0,      /*招待 0=不限制招待 >1=需要限制招待的份数(根据PRESENT_MICLASS_EMPCLASET和PRESENT_MIDETAIL_EMPCLASET限制招待的数量) lzm add 2011-06-14*/
  PRESENTCTYPE  INTEGER DEFAULT 0,      /*招待的周期 0=按日计算 1=按周计算 2=按月计算 lzm add 2011-06-14*/

  PRESENTINUSE  INTEGER DEFAULT 0,      /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/
  STOCKALARM    INTEGER DEFAULT 0,      /*是否弹出库存警报 0=否 1=启用 lzm add 2011-12-26*/

  PRESENTAMOUNT  NUMERIC(15, 3),        /*限制招待的金额 0或空=不限制 lzm add 2013-09-02*/

  USER_ID INTEGER DEFAULT 0,        /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',   /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRESENTLIMIT VARCHAR(20),         /*账单的招待上限 100=招待不能超过100元 10%=招待不能账单金额10% lzm add 2015-09-28*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPCLASSID,PCID)
);

/* Table: EMPLOYEES, Owner: SYSDBA */

CREATE TABLE EMPLOYEES /*EMPLOYEES与ABUYER是多对一的关系 通过BUYERID联系(即：一个人可以有多个VIP卡)*/
(
  EMPID INTEGER NOT NULL,       /*会员EMPID=1..10000 VIP卡EMPID>=10001 lzm modify 分开接收员工和会员信息 2012-4-23*/
  FIRSTNAME     VARCHAR(100),    /*姓名1*/
  LASTNAME      VARCHAR(100),    /*姓名2*/
  IDVALUE       VARCHAR(40),    /*卡号(即:密码)*/
  EMPCLASSID    INTEGER,
  RESERVE01     VARCHAR(40),    /*有效期  PeriodOfValidity 例如:20110101*/
  RESERVE02     VARCHAR(40),    /*地址 Address */
  RESERVE03     VARCHAR(40),    /*联系电话 Tel*/
  RESERVE04     VARCHAR(40),    /*邮编 ZipCode*/
  RESERVE05     VARCHAR(40),    /* ***lzm 作废 2013-05-24*** 用于积分 VIP卡消费累计总金额,即开卡以来的消费金额*/
  RESERVE11     VARCHAR(40),    /*用于积分 可用积分(或会员券)*/
  RESERVE12     VARCHAR(40),    /* ***lzm 作废 2013-05-24*** 用于积分 已经计算的VIP卡消费总额,即多少钱已兑换成积分(或会员券)*/
  RESERVE13     VARCHAR(40),    /*改为VIP的品种存量 之前:磁卡：剩余的 Money  */
  RESERVE14     VARCHAR(40),    /*会员卡的金额 Money*/
  RESERVE15     VARCHAR(40),    /*手机Mobile*/
  RESERVE16     VARCHAR(40),    /*传真Fax*/
  RESERVE17     VARCHAR(40),    /*公司名company*/
  RESERVE18     VARCHAR(40),    /*公司职务CoHeadship*/
  RESERVE19     VARCHAR(40),    /*台商会分会名ASSN*/
  RESERVE20     VARCHAR(40),    /*分会职务ASSNHeadship*/
  RESERVE21     VARCHAR(40),    /*人士Degree*/
  RESERVE22     VARCHAR(40),    /*生日Birthday */
  RESERVE23     VARCHAR(40),    /*语言   cn  en     */
  RESERVE24     VARCHAR(40),    /*UserCode 用户编号,比如技师的编号等*/
  RESERVE25     VARCHAR(40),    /*最后充值日期 lzm modify 2013-04-17*/
  BUYDATE       VARCHAR(10),    /*购卡日期*/
  ORDERID       INTEGER DEFAULT 0,     /*排列编号*/
  BUYERID       VARCHAR(40),    /*对应ABUYER的BUYERID  EMPLOYEES与ABUYER是多对一的关系(即：一个人可以有多个VIP卡)*/
  EMPPASSWORD   VARCHAR(128),   /*用户自己定义的密码*/
  LASTCONSUMEDATE  TIMESTAMP,   /*最后消费日期*/
  PCID          VARCHAR(40) DEFAULT '', /*空=门店员工信息和门店VIP卡信息(以前的总部系统用于区分总部员工和门店员工) */
  NOTADDINTERNAL   INTEGER DEFAULT 0,  /*不需要继续累积消费积分 0=需要继续累计 1=不需要继续累计*/
  JXCUSERID     VARCHAR(40),    /*改为仓库配送的客户或供应商名称 lzm modify 2011-12-13 (之前:进销存的用户ID)*/
  JXCPASSWORD   VARCHAR(40),    /*仓库的密码*/

  treeparent    INTEGER DEFAULT -1, /**/
  wage          NUMERIC DEFAULT 0,  /*基本工资*/
  dept          VARCHAR(20),        /*部门*/
  learning      VARCHAR(20),        /*学历名称*/
  isdeliver     INTEGER DEFAULT 0,  /* ***保留***(暂时被程序固定为1) 1=进销存高级用户 0=普通用户 (即之前的:是否配送中心员工) 就是进销存管理的员工管理的Admin*/
  comedate      TIMESTAMP,          /*入职时间*/
  sex           VARCHAR(10),        /*男女*/
  place         VARCHAR(30),        /*籍贯*/

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  TBLNAME     VARCHAR(40),              /*对应到的台号名称,用于现在用户只能操作的台号 lzm add 2010-08-13*/

  WEB_TAG      INTEGER DEFAULT 0,       /*需要同步到web_sysuser lzm add 2011-03-30*/

  DISCOUNT_LEVEL INTEGER,        /*员工或者会员的折扣级别---->根据折扣表得到该会员能够拥有的折扣>>>用在Android 手机 lzm add 2011-09-23*/
  TAX_DEFINE VARCHAR(40),        /*根据简单设置表的税率名称得到相应的税率>>>用在Android 手机 lzm add 2011-09-23*/

  PRESENTITEM   INTEGER DEFAULT NULL,  /*招待 空=跟类别设置 0=不限制招待 >1=需要限制招待的份数 lzm add 2011-06-14*/
  PRESENTCTYPE  INTEGER DEFAULT NULL,  /*招待的周期 空=跟类别设置 0=按日计算 1=按周计算 2=按月计算 lzm add 2011-06-14*/

  POINTSTODAY  NUMERIC(15,3) DEFAULT 0.0,       /*用于积分 今天的积分(用于积分次日生效的算法) lzm add 2011-07-10*/
  POINTSTOTAL   NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 累计总积分 lzm add 2011-07-05*/
  MONEYFPOINTS  NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 上月积分已折现金额(可当付款使用) lzm add 2011-07-05*/
  POINTSADDTIME TIMESTAMP,                      /*用于积分 最后获得积分的时间(用于上月积分需要兑换为现金的算法) lzm add 2011-07-11*/
  MONEYFPOINTSTIME TIMESTAMP,                   /*用于积分 上次积分折现的时间(用于上月积分需要兑换为现金的算法) lzm add 2011-07-11*/
  POINTSISUSED  NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 已兑换的积分 lzm add 2011-07-18*/
  --CANTRUNPOINTS NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 现在可折现的积分(用于上月积分需要兑换为现金的算法) lzm add 2011-08-04*/

  PRESENTINUSE  INTEGER DEFAULT 0,     /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  AUDITLEVEL  INTEGER DEFAULT 1,       /*仓库审核级别 1=一级审核(入单员就是一级审核员) lzm add 2011-10-30*/
  STOCKDEPOT  VARCHAR(40),             /*仓库编号(空:全部),用于限制用户只能操作的仓库 lzm add 2011-11-2*/

  WPOS_SN  VARCHAR(40),                /*点菜机的序列号 lzm add 2012-02-25*/
  CARDSTATE     INTEGER DEFAULT 0,     /*VIP卡的状态 0=在用 1=挂失 2=作废 3=黑名单 lzm add 2012-07-05*/
  RETURNBACK    INTEGER DEFAULT 0,     /*VIP卡已退款 0=否 1=是 lzm add 2012-07-05*/
  EXCHANGENEWCARD  VARCHAR(50),        /*VIP卡换卡,补卡对应的新卡号 lzm add 2012-07-05*/

  PRESENTAMOUNT  NUMERIC(15, 3),       /*限制招待的金额 空=跟类别设置 0=不限制 lzm add 2013-09-02*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRESENTLIMIT VARCHAR(20),                 /*账单的招待上限 lzm add 2015-09-28*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPID,PCID)
);

CREATE TABLE PRESENT_MICLASS_EMPCLASET  /*员工类别,可招待的品种类别和数量 lzm add 2011-06-14*/
(
  EMPCLASSID    INTEGER NOT NULL,     /*员工类别编号*/
  MICLASSID     INTEGER NOT NULL,     /*品种类别编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPCLASSID, MICLASSID)
);

CREATE TABLE PRESENT_MIDETAIL_EMPCLASET  /*员工类别,可招待的品种和数量 lzm add 2011-06-14*/
(
  EMPCLASSID    INTEGER NOT NULL,     /*员工类别编号*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPCLASSID, MENUITEMID)
);

CREATE TABLE PRESENT_MICLASS_EMPSET  /*员工,可招待的品种类别和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MICLASSID     INTEGER NOT NULL,     /*品种类别编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPID, MICLASSID)
);

CREATE TABLE PRESENT_MIDETAIL_EMPET  /*员工,可招待的品种和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPID, MENUITEMID)
);

CREATE TABLE PRESENT_MIDETAIL_EMPRUN  /*员工曾经已招待的品种和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  SALEDATE      TIMESTAMP NOT NULL,   /*销售日期*/
  APRESENTCOUNT INTEGER,              /*已招待数量*/

  APRESENTAMOUNT NUMERIC(15, 3),      /*已招待金额 lzm add 2013-09-02*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,EMPID, MENUITEMID, SALEDATE)
);


/* Table: FAMILYGROUP, Owner: SYSDBA */

CREATE TABLE FAMILYGROUP /*报表辅助分类1*/
(
  FGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,FGID)
);

/* Table: MAINMENUCLASS, Owner: SYSDBA */

CREATE TABLE MAINMENUCLASS
(
  MAINMENUCLASSID       INTEGER NOT NULL,
  MAINMENUCLASSNAME     VARCHAR(40),
  SORTORDER     INTEGER,
  TOUCHSCRID    INTEGER,
  TOUCHSCRLINEID        INTEGER,
  SIMPLENAME    VARCHAR(20),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
 PRIMARY KEY (MAINMENUCLASSID)
);

/* Table: MAJORGROUP, Owner: SYSDBA */

CREATE TABLE MAJORGROUP /*报表辅助分类2*/
(
  MGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MGID)
);

/* Table: MENUDETAIL, Owner: SYSDBA */

CREATE TABLE MENUDETAIL
(
  MENUITEMID    INTEGER NOT NULL,
  MAINMENUCLASSID       INTEGER,
  SUBMENUCLASSID        INTEGER,
  MENUITEMNAME  VARCHAR(40),
  LOGICPRNNAME  VARCHAR(100),
  BCID  INTEGER,
  ANUMBER       INTEGER,
  FAMILGID      INTEGER,
  MAJORGID      INTEGER,
  MIPRICE       NUMERIC(15, 3),
  PREPCOST      NUMERIC(15, 3),
  AMTDISCOUNT   NUMERIC(15, 3),
  SORTORDER     INTEGER,
  TOUCHSCRID    INTEGER,
  TOUCHSCRLINEID        INTEGER,
  SIMPLENAME    VARCHAR(20),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
 PRIMARY KEY (MENUITEMID)
);

CREATE TABLE DEPARTMENTINFO  /*部门信息 与仓库公用*/
(
  DEPARTMENTID INTEGER NOT NULL,
  DEPARTMENTNAME  VARCHAR(40),
  DEPARTMENTNAME_LANGUAGE  VARCHAR(40),
  DEPTUSERCODE VARCHAR(30),             /*部门的用户编号 lzm add 2009-08-29*/
  DEPT2DEPOTID INTEGER DEFAULT 0,       /*与部门挂钩的仓库编号ID lzm add 2009-09-09*/
  LOGICPRNNAME VARCHAR(40),             /*部门对应的打印机 用于wpos的部门信息通知 lzm add 2011-10-10*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,DEPARTMENTID)
);

alter table DEPARTMENTINFO add id serial;
alter table DEPARTMENTINFO add treeparent smallint DEFAULT 0;
alter table DEPARTMENTINFO add "level" character varying(50);
alter table DEPARTMENTINFO add seedcount integer DEFAULT 0;
alter table DEPARTMENTINFO add parentid integer DEFAULT 0;
alter table DEPARTMENTINFO add rootid integer DEFAULT 0;
alter table DEPARTMENTINFO add pinyin character varying(20);
alter table DEPARTMENTINFO add shortname character varying(20);
alter table DEPARTMENTINFO add "explain" character varying(100);
alter table DEPARTMENTINFO add memo text;
alter table DEPARTMENTINFO add "mode" smallint DEFAULT 0;

CREATE TABLE DEPARTMENT_KICKBACK --部门提成设置，通过品种所属部门进行提成的计算 --lzm add 2019-07-10 03:22:33
(
  ID                 SERIAL,
  DEPARTMENTID       INTEGER,                     --部门ID
  DEPARTMENTNAME     VARCHAR(40),                 --部门名称
  DISCOUNT_RATIO_S   NUMERIC(15, 3),              --折扣开始区间，例如：0.4=6折 0.35=65折 0.2=8折 0.15=85折
  DISCOUNT_RATIO_E   NUMERIC(15, 3),              --折扣结束区间，例如：0.4=6折 0.35=65折 0.2=8折 0.15=85折
  KICKBACK_RATIO     VARCHAR(20),                 --提成比例，例如：5% 7% 9%
  INVOICE            INTEGER DEFAULT 0,           --是否开票：0=否 1=是

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);

/* Table: MICLASS, Owner: SYSDBA */

CREATE TABLE MICLASS
(
  MICLASSID     INTEGER NOT NULL,
  MICLASSNAME   VARCHAR(100),
  MICLASSDISCOUNT       NUMERIC(15, 3) default 0,  /*类别折扣率%*/
  RESERVE01     VARCHAR(40),  /*按钮模板编号*/
  RESERVE02     VARCHAR(40),  /*关联界面或类别1*/
  RESERVE03     VARCHAR(40),  /*子类或品种的按钮模板编号*/
  --lzm modify 2023-12-31 23:12:08
  --RESERVE04     VARCHAR(40),
  RESERVE04     text,        /*扩展1   --lzm modify 2023-12-31 23:19:24
                             {
                              "limit_timeperiod":"",      --时段限制，时间段编号对应MITIMEPERIOD的MITID
                              "limit_week":"",            --星期限制，填入 1=星期一，2=星期二，6=星期六，7=星期日
                              "limit_holiday":""          --节假日限制，假日段编号对应MIHOLIDAY的MIHID
                              "table_section":"MALL;B;E"  --可以显示该类别的区域台号，空=全部区域的台号都可以显示该类别【多个时用分号;分割】  --lzm add 2024-02-06 00:54:15
                              "ypos_ext_f": {"is_print_lable":"true","net_ip":"192.168.0.201","next_screen":""} --记录YPOS上传的ext_f信息  --lzm add 2024-06-22 06:08:12 
                             }
                             */
  RESERVE05     VARCHAR(40),
  SORTORDER     INTEGER default 0,
  TOUCHSCRID    INTEGER,
  TOUCHSCRLINEID        INTEGER,
  SIMPLENAME    VARCHAR(100),
  PARENTMICLASS INTEGER,     /*根类别编号*/
  MICLASSNAME_LANGUAGE  VARCHAR(100),
  SIMPLENAME_LANGUAGE   VARCHAR(100),
  TS_TSCHROW    INTEGER,     /*父类别2编号*/
  TS_TSCHCOL    INTEGER,     /*类别属性 0或空=品种类别 1=附加信息*/
  TS_TSCHHEIGHT INTEGER,     /*是否系统保留 0或空=否 1=是*/
  TS_TSCHWIDTH  INTEGER,
  TS_TLEGEND    VARCHAR(100),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(100),
  TS_TSCHFONT   VARCHAR(40) DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,
  TS_TSNEXTSCR  INTEGER,                 /*子类别所在的界面*/
  TS_BALANCEPRICE       NUMERIC(15, 3),
  TS_TSCHCOLOR  VARCHAR(20),
  TS_TSCHFONTCOLOR      VARCHAR(20),
  TS_RESERVE01  VARCHAR(40),    /*不需授权用户类别 lzm add 2010-05-14*/
  TS_RESERVE02  VARCHAR(40),    /*需授权的状态 lzm add 2010-05-14*/
  TS_RESERVE03  VARCHAR(40),    
  TS_RESERVE04  VARCHAR(40),
  TS_RESERVE05  VARCHAR(40),
  PICTUREFILE VARCHAR(240),        /*图片文件名称(包括路径)*/
  SUBMITSCHID  INTEGER DEFAULT 0,  /*子品种所在的界面    ****之前:该类别下的类别或品种所在的界面*/
  MICVISIBLED  INTEGER DEFAULT 1,  /*是否可见
                                     [二进制000x] 电脑端                      x位置二进制0000=否 0001=是  十进制0=否 1=是
                                     [二进制00x0] 固定用于判断是否启用新格式    x位置二进制0000=否 0010=是  十进制0=否 2=是    --lzm add 2023-08-27 06:07:29
                                     [二进制0x00] YPOS                        x位置二进制0000=否 0100=是  十进制0=否 4=是    --lzm add 2023-08-27 06:07:29
                                     -------------------------------------
                                     例如：
                                     二进制0010 = 十进制2 = YPOS隐藏+电脑端隐藏
                                     二进制0110 = 十进制6 = YPOS显示+电脑端隐藏
                                     二进制0011 = 十进制3 = YPOS隐藏+电脑端显示（只是电脑端显示）
                                     二进制0111 = 十进制7 = YPOS显示+电脑端显示
                                   */
  MAXINPUTMI   INTEGER DEFAULT 1,  /*最多允许键入该类别品种的次数 注意:只对附加信息生效*/
  MININPUTMI   INTEGER DEFAULT 1,  /*最少允许键入该类别品种的次数 注意:只对附加信息生效*/
  CANREPEATEINPUT  INTEGER DEFAULT 0,  /*是否可以重复录入相同的品种,0=false,1=true*/
  WEB_TAG      INTEGER DEFAULT 0,  /*是否需要同步到Web点餐 lzm add 2016-01-22【之前为 需要同步到web_miclass lzm add 2011-03-30】*/
  WEB_NAME     VARCHAR(100),       /*在web_miclass的别名 lzm add 2011-03-30*/
  WEB_FILE     VARCHAR(240),       /*在web_miclass的picturefile lzm add 2011-03-30*/
  WEB_FILE_MOBILE  VARCHAR(240),   /*在web_miclass的picturefile_mobile lzm add 2011-03-30*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MICLASSID)
);

/* Table: MIDETAIL, Owner: SYSDBA */

CREATE TABLE MIDETAIL
(
  MENUITEMID    INTEGER NOT NULL,
  MICLASSID     INTEGER DEFAULT 0, 
  MENUITEMNAME  VARCHAR(100),   /*品种名称*/
  LOGICPRNNAME  VARCHAR(100),   /*逻辑打印机*/
  BCID          INTEGER,
  ANUMBER       INTEGER,
  FAMILGID      INTEGER,        /*辅助分类1*/
  MAJORGID      INTEGER,        /*辅助分类2*/
  MIPRICE       NUMERIC(15, 3), /*价格*/
  PREPCOST      NUMERIC(15, 3) default 0,  /*厨房提成金额 --lzm modify 2023-09-10 17:43:21【之前是：成本(????好像没使用????)】*/
  AMTDISCOUNT   NUMERIC(15, 3) default 0,  /*品种折扣额$*/
  RESERVE01     VARCHAR(40),    /* 是否时价 0:否,1:时价 */
  RESERVE02     VARCHAR(40),    /* 0:eatin  1:delivery  2:takeout  3:eatin for employees*/
  RESERVE03     VARCHAR(40),    /* 优惠价类别,用于两个品种相撞的价格*/
  RESERVE04     VARCHAR(40),    /* 菜式种类
                                   0-普通主菜
                                   1-配菜
                                   2-饮料
                                   3-套餐
                                   4-说明信息
                                   5-其他,
                                   6-小费,
                                   7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                   8-普通服务项
                                   9-最低消费
                                  10-Open品种
                                  11-IC卡充值
                                  12-其它类型品种
                                  13-礼品(需要用会员券汇换)
                                  14-品种连接
                                  15-类别连接
                                  16-
                                  17-
                                  18-手写单 lzm add 2010-03-12
                                  19-后一品种当做法(拼上做法)【同时需要设置附加消息ISINFOMENUITEM=1】（下一个点的品种B作为当前品种A的附加消息）
                                  20-后一品种合并厨打(拼上品种)【同时需要设置附加消息ISINFOMENUITEM=1】（下一个点的品种B在打印厨房单时与当前品种A合并一起打印）
                                  21-茶位等（数量跟随账单的人数变化而变化，前提需要设置对应参数）
                                  22-差价(系统保留)
                                  23-直接修改总积分(系统保留)  //lzm add 2011-08-02
                                  24-直接修改可用积分(系统保留)  //lzm add 2011-08-02
                                  25-积分折现操作(系统保留) //lzm add 2011-08-04
                                  26-VIP卡挂失后退款(系统保留) //lzm add 2012-07-06
                                  27-VIP卡挂失后换卡(系统保留) //lzm add 2012-07-06
                                  28-分[X]席(系统保留) //lzm add 【2012-11-07】
                                  29-计量单位 lzm add 2012-11-17
                                  30-蛋糕 lzm add 2018-06-23 17:10:21
                                  33-与前一品种合并厨打（厨房单与上一品种合并打印）  --lzm add 2024-3-27 00:26:42
                                  34-多份价格品种(YPOS)  --lzm add 2025-06-26 01:19:06 用于在存储过程wpos_command()提取midetail的品种不需要再过滤品种名称里面的分号;因为在这里需要用分号;分隔添加多语言
                                */
  RESERVE05     VARCHAR(40),    /*jaja  【估清】菜式的数量  2001-4-17  -1和空=不限数量 >=0代表现存的品种数量*/
  SORTORDER     INTEGER default 0,      /*排序*/
  TOUCHSCRID    INTEGER,                /*不需要厨房划单 0=需要划单 1=不需要划单 lzm modify 2010-01-16*/
  TOUCHSCRLINEID        INTEGER,        /*不需要打折(与T:有相同的作用,但T:可以不计入最低消费,而这个需要计入最低消费)  lzm modify 2010-01-16*/
  SIMPLENAME    VARCHAR(100),           /*简称*/
  BARCODE       VARCHAR(40),            /*条码*/
  CODE          VARCHAR(40),            /*外卖品种编码，例如：美团外卖的品种编码 lzm modify 2018-08-17 02:26:53*/
  NEEDADDTOTG   INTEGER DEFAULT 0,      /*是否在报表中出现*/
  COST          NUMERIC(15, 3),         /*成本*/
  KICKBACK      NUMERIC(15, 3),         /*员工提成*/
  MENUITEMNAME_LANGUAGE VARCHAR(100),   /*英语名称*/
  SIMPLENAME_LANGUAGE   VARCHAR(100),   /*简称(一般用于厨房的打印)*/
  ISINFOMENUITEM        INTEGER,        /*是否是附加信息 0或空=否 1=是 */
  BALANCEPRICE  NUMERIC(15, 3),         /*差价*/
  TS_TSCHROW    VARCHAR(40), --INTEGER, /*OtherCode其它ERP编码 例如SAP的物料ItemCode*/
  TS_TSCHCOL    INTEGER,                /*是否隐藏该品种 0或空=不隐藏 1=隐藏*/
  TS_TSCHHEIGHT INTEGER,                /*是否系统保留 0或空=否 1=是*/
  TS_TSCHWIDTH  INTEGER,                /*附加信息价格是否根据数量变化而变化 0=根据数量变化 1=固定加格 lzm add 2009-07-26*/
  TS_TLEGEND    VARCHAR(240),           /*odoo的ERP编码 odoocode lzm modify 2019-05-15 04:39:31 
    TS_TLEGEND='' or TS_TLEGEND=NULL 代表根据门店参数决定是否扣库存
    {"default_code":"", "uom_id":"", "negative":"[yes:允许负库存销售]", "link":"[custom:需要指定Odoo编码]", "presales":"[是否能用于预订单 0或空:否 1:是]"}
                                        */
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(240),
  TS_TSCHFONT   VARCHAR(40) DEFAULT 'Arial', --DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,        /*无需积分 0或空=否 1=是 lzm modify 2009-08-11*/
  TS_TSNEXTSCR  INTEGER,                /*对应原材料表Ware的ID编号 lzm modify 2009-08-04*/
  TS_BALANCEPRICE       NUMERIC(15, 3), /*扣除的积分 lzm modify 2010-08-23*/
  TS_TSCHCOLOR  VARCHAR(20),            /*单位2缺省数量 lzm modify 2009-10-10*/
  TS_TSCHFONTCOLOR      VARCHAR(20),    /*是否允许修改时价价格 0或空=跟系统设置 1=允许修改 2=不允许修改 lzm modify 2011-05-04*/
  TS_RESERVE01  VARCHAR(40),     /*计量单位 例如:笼*/
  TS_RESERVE02  VARCHAR(40),     /*辅助单位 例如:颗*/
  TS_RESERVE03  VARCHAR(40),     /*单位比例 例如:4    (代表1笼=4颗牛肉丸)*/
  TS_RESERVE04  VARCHAR(40),     /*账单显示的单位 0=计量单位 1=辅助单位*/
  TS_RESERVE05  VARCHAR(40),     /*计量单位2  例如:条(用于记录海鲜的条数等) lzm add 2009-08-31*/
  NEXTMICLASSID INTEGER,         /*(负数代表类别,整数代表品种或条码)点了该品种后跳动的下一个类别,或
                                     品种编号(如果是品种编号则:指明下一个要消费的品种)
                                     或品种条码(如果是品种条码则:指明下一个要消费的品种)
                                     【注意：如果该品种属于计时的服务项目，则要“开始计时”时才执行以上的动作】
                                 */
  BALANCETYPE  INTEGER,          /*差价的类型 0:直接加减 1:按百分比加减 2=补差价(即:+品种价格减去该差价的值)
                                   3=乘上指定数值 lzm add 2010-10-03*/

  MIFAMOUSBRAND VARCHAR(20),     /*品牌*/
  MICLASSNAME   VARCHAR(20),     /*所属的品种类别名称*/
  MISIZE        VARCHAR(20),     /*尺寸 大中小餐具的属性,用于在前台统计大中小的数量 lzm modify 2012-11-17*/
  MICOLOR       VARCHAR(20),     /*颜色*/
  MIBATCHPRICE  NUMERIC(15, 3),  /*批发价*/
  MISTOCKALARM_UP  INTEGER,      /*库存警告上限*/
  MISTOCKALARM_DOWN  INTEGER,    /*库存警告下限*/
  MITYPENUM     VARCHAR(20),     /*品种型号，服装*/
  MIPRICE_SUM_UNIT NUMERIC(15, 3) DEFAULT 0,        /*时长     品种价格MIPRICE的总单位数量或时长(即:单位价格=MIPRICE_SUM_UNIT / MIPRICE)【价格时长(分钟)】*/
  MIPRICE_DEFAULTUNIT NUMERIC(15, 3) DEFAULT 0,     /*缺省时长 品种价格MIPRICE的缺省数量或时长【服务时长(分钟)】*/
  MI_MASSAGE_ADDTIME INTEGER DEFAULT 0,             /*属于按摩加钟,加钟时取上次按摩的技师*/
  MIISGROUP INTEGER DEFAULT 0,         /*属于组品种(即:在一个帐单内点该品种时其它和该帐单属于同一组编号也自动添加该品种)*/
  BEFOREORDER VARCHAR(40),             /*点击该品种前要执行的命令(这个只能执行指定的命令)*/
  AFTERORDER VARCHAR(40),              /*点击该品种后要执行的命令*/
  NEEDAFEMPID INTEGER DEFAULT 0,       /*是否需要技师 0=不需，1=需要*/
  PICTUREFILE VARCHAR(240),            /*图片文件名称(包括路径)*/
  DEPARTMENTID INTEGER,                /*所属部门编号*/
  MICOUNTWORDS INTEGER,                /*笔划*/
  MIPINYIN   VARCHAR(20),              /*其它名称信息,例如:拼音*/
  DIRECTDEC     INTEGER DEFAULT 0,     /*直接扣减库存 0=否, 1=是*/
  NOTINVOICE   INTEGER DEFAULT 0,      /*不需要在票据中出现(不需在账单打印)*/
  AREASQM    NUMERIC(15, 4) DEFAULT 0, /*面积(平方米)*/
  AREAITEM   INTEGER DEFAULT 0,        /*按面积计算*/
  NOSERTOTALPAPER INTEGER DEFAULT 0,   /*不需要入单纸*/
  COSTPERTCENT VARCHAR(10),            /*用于 计算"附加信息"的"成本"的单位百分比，成本(原材料) 金额或百分比*/
  ABCID VARCHAR(20),                   /* ***20100615停止使用(用存储过程代替)***(A+B送C的类别编号  lzm add 【2009-05-06】)*/
  NEEDKEXTCODE INTEGER DEFAULT 0,      /*录入品种时需要录入辅助号(木夹号)*/
  ABC_DISCOUNT_MATCH_NUM VARCHAR(40),  /* ***20100917停止使用(用促销组合代替)*** 用于ABC优惠 '1':表示类型A  '2':表示类型B  '3':表示类型C  lzm add 2010-09-02*/
  WEB_TAG      INTEGER DEFAULT 0,      /*修改为：微信预下单品种【之前是：需要同步到web_midetail lzm add 2011-03-30】*/
  WEB_FILE_S     VARCHAR(240),         /*小图,在web_midetail的 picturefilesmall lzm add 2011-03-30*/
  WEB_FILE_B     VARCHAR(240),         /*大图,在web_midetail的 picturefilebig lzm add 2011-03-30*/
  WEB_FILE_S_MOBILE  VARCHAR(240),     /*微信点餐 手机小图,在web_midetail的 picturefilesmallmobile （宽:345 x 高:272 单位：像素 = 1.261） lzm add 2011-03-30*/
  WEB_FILE_B_MOBILE  VARCHAR(240),     /*微信点餐 手机大图,在web_midetail的 picturefilebigmobile （宽:710 x 高:563 单位：像素 = 1.261） lzm add 2011-03-30*/
  WEB_GROUPID     INTEGER DEFAULT 0,   /*附加信息的组号,在web_midetail的groupid lzm add 2011-03-30*/
  WEB_ISHOT       INTEGER DEFAULT 0,   /*热销菜,在web_midetail的isHot lzm add 2011-03-30*/
  WEB_ISSPECIALS  INTEGER DEFAULT 0,   /*特价菜,在web_midetail的isSpecials lzm add 2011-03-30*/
  WEB_MIDESCRIPTION  VARCHAR(240),     /*品种的详细描述,在web_midetail的midescription lzm add 2011-03-30*/
  
  CLASSTYPE  VARCHAR(40) DEFAULT '',   /*酒吧：所属归类 例如:啤酒 红酒 洋酒 lzm add 2011-08-09*/
  VC_RATE  INTEGER DEFAULT 1,          /*酒吧：退换的单位比率 lzm add 2011-08-09
                                          如果该品种是"扎"则"单位比率"应该填入"12"
                                          如果该品种是"半扎"则"单位比率"应该填入"6"
                                       */
  VC_ITEM  INTEGER DEFAULT 0,          /*酒吧：退换的品种编号 lzm add 2011-08-09*/

  INFOCOMPUTTYPE  INTEGER DEFAULT 0,   /*附加信息计算方法 0=原价计算 1=放在最后计算 2=修改价格的补差价(放在终极计算) lzm add 2011-08-11*/

  XGDJ TEXT,            /*【之前是：是否允许修改单价>>>用在Android 手机 --lzm add 2011-09-23】
                          【在同步到YPOS时用 TS_TSCHFONTCOLOR(是否允许修改时价)代替XGDJ】
                          拓展信息：lzm modify 2022-08-13 03:39:42
                            {
                              "need_amount_balance": "当前品种是否需要计算折让成本 0=否 1=是",
                              "use_miclass_webinfo": "当前品种跟随类别的web口味 0=否 1=是",
                              "station_kickback": [{"厨房":"","检菜":"","出餐":""}]  --厨房岗位提成 --lzm add 2023-11-17 00:34:27
                              "hide_order_finditem": "前台品种查找时隐藏 0=否 1=是",  --lzm add 2024-1-25 19:18:59
                              "hide_amounts_in_totalbill": "埋单纸隐藏金额，用于剔除美团品种金额统计 0=否 1=是",  --lzm add 2024-4-2 23:47:10
                              "mooncakeitem": "月饼品种 0=否 1=是",  --lzm add 2025-08-13 04:54:57
                              "btn_moduleid":"按钮模板ID"  --lzm add 2025-09-25 04:05:48
                            }
                        */
  YJ TEXT,              /*【之前是：是否原价>>>用在Android 手机 --lzm add 2011-09-23(说明信息如果出现百分比的说明信息，是按照原价计算，还是按照其他说明信息合计之后的总价的百分比来计算)】
                          【在同步到YPOS时用 INFOCOMPUTTYPE(附加信息计算方法) 代替YJ】
                          拓展信息：lzm modify 2022-08-13 03:39:42
                            {
                              "ypos_zjm": {"barcode":"","zjm":"","cake_produce_miniue":"0","erp_code":""}  --记录YPOS上传的zjm信息  --lzm add 2024-06-22 06:08:12
                              "ypos_ext_f": {"auto_order_notwith_people":"0","auto_order_with_people":"0","is_print_lable":"1","is_suite":"0","is_use_scancode":"1","kc":"","need_kc":"0","not_is_suite":"1"}  --记录YPOS上传的ext_f信息  --lzm add 2024-06-22 06:08:12
                            }
                        */
  GZBH VARCHAR(40),     /*指向规则表的规则编号>>>用在Android 手机 lzm add 2011-09-23*/
  SYSCODE VARCHAR(40) DEFAULT '0',     /*>>>用在Android 手机 lzm add 2011-09-23
                              SYSCODE在  菜式类别id=1时，
                                1:1食
                                2:2食
                                3:3食
                                4:4食
                                5:5食
                                6:6食
                                7:7食
                                8:8食
                                9:9食
                                10:10食

                                11:赠送
                                12:招待

                                20:席数  --现在没有实现 syscode=20的席数功能

                              SYSCODE在  菜式类别id=2时(客人要求)，
                                取值只会等于0，表示普通syscode,而这个miclassid=2的菜式就是客人要求的菜式品种
                                0:普通
                              */
  WCONFIRM INTEGER DEFAULT 0,        /*是否需要重量确认 2012-2-22*/
  TEMPDISH INTEGER DEFAULT 0,        /*"临时菜"，用于: YP318, BL600, 是否可以作为临时菜编号 2012-2-22*/

  OTHERPRICEID VARCHAR(40) DEFAULT NULL,      /*所属价格分类 lzm add 2012-4-19*/
  STOCKCOUNTSORI NUMERIC(15, 3) DEFAULT -1,   /*用于Web订餐(微信) 同步存量，存量的原始值(即:设置的开始库存量) lzm add 2012-04-23*/
  WEBCHAT_TAG      INTEGER DEFAULT 0,         /*需要同步到 Web订餐(微信) lzm add 2014/3/13*/

  USER_ID INTEGER DEFAULT 0,         /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',    /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '',  /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  STOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),        /*用于Web订餐(微信) 同步存量，库存时间 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKNUM NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKORI NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量原始值(即:设置的开始库存量) lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()), /*Web订餐(微信) 同步库存时间 lzm add 2016-03-01*/

  TAKEAWAY_TAG INTEGER DEFAULT 0,            /*外卖 外卖品种 lzm add 2018-07-30 06:57:38*/
  BOXNUM INTEGER DEFAULT 0,                  /*外卖 打包盒数量 lzm add 2018-07-30 06:57:38*/
  BOXPRICE NUMERIC(15,3) DEFAULT 0,          /*外卖 打包盒单价 lzm add 2018-07-30 06:57:38*/
  MINORDERCOUNT INTEGER DEFAULT 0,           /*外卖 最小数量 lzm add 2018-07-30 06:57:38*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MENUITEMID)
);
ALTER TABLE "public"."midetail" 
  ALTER COLUMN "ts_tlegend" TYPE varchar(240) COLLATE "pg_catalog"."default",
  ALTER COLUMN "ts_tlegend_otherlanguage" TYPE varchar(240) COLLATE "pg_catalog"."default";
ALTER TABLE "public"."new_midetail" 
  ALTER COLUMN "ts_tlegend" TYPE varchar(240) COLLATE "pg_catalog"."default",
  ALTER COLUMN "ts_tlegend_otherlanguage" TYPE varchar(240) COLLATE "pg_catalog"."default";
ALTER TABLE "public"."hq_issue_midetail" 
  ALTER COLUMN "ts_tlegend" TYPE varchar(240) COLLATE "pg_catalog"."default",
  ALTER COLUMN "ts_tlegend_otherlanguage" TYPE varchar(240) COLLATE "pg_catalog"."default";
ALTER TABLE "public"."midetail" ALTER COLUMN NEEDADDTOTG SET DEFAULT 0;
ALTER TABLE "public"."new_midetail" ALTER COLUMN NEEDADDTOTG SET DEFAULT 0;
ALTER TABLE "public"."hq_issue_midetail" ALTER COLUMN NEEDADDTOTG SET DEFAULT 0;

/* Table: TCSL, Owner: SYSDBA */

CREATE TABLE TCSL   /*套餐选择  一个套餐组合为一条记录*/
(
  TCSLID        INTEGER NOT NULL,
  MENUITEMID    INTEGER NOT NULL,         /*对应的套餐品种编号*/
  SORTID        INTEGER,                  /*排序编号*/
  TCSLCOUNT     INTEGER,                  /*可选品种的数量*/
  TCSLLIMITPRICE        NUMERIC(15, 3),   /*价格上限*/
  TOUCHSCRID    INTEGER,
  COST          NUMERIC(15, 3),     /*成本*/
  KICKBACK      NUMERIC(15, 3),     /*提成*/
  PRICE         NUMERIC(15, 3),     /*在套餐中所占的价格*/
  CANREPEAT     INTEGER DEFAULT 0,  /*是否可以重复键入*/
  MAXINCOUNT    INTEGER DEFAULT 1,  /*最多可以键入的次数*/
  MININCOUNT    INTEGER DEFAULT 1,  /*最少可以键入的次数*/
  HAVEINCOUNT   INTEGER DEFAULT 0,  /*记录已选择的次数*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  TCSLNAME  VARCHAR(40),        /*名称 lzm add 2023-01-02 10:32:36*/
  TCSLMEMO  VARCHAR(100),       /*备注 lzm add 2023-01-02 10:32:41*/
  TCSL_EXTCOL JSON,             /*扩展信息 lzm add 2023-01-02 10:33:17
                                {  //留以后扩展用
                                }
                                */

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TCSLID)
);
alter table TCSL add TCSLNAME VARCHAR(40);
alter table TCSL add TCSLMEMO VARCHAR(100);
alter table TCSL add TCSL_EXTCOL JSON;
alter table NEW_TCSL add TCSLNAME VARCHAR(40);
alter table NEW_TCSL add TCSLMEMO VARCHAR(100);
alter table NEW_TCSL add TCSL_EXTCOL JSON;
alter table HQ_ISSUE_TCSL add TCSLNAME VARCHAR(40);
alter table HQ_ISSUE_TCSL add TCSLMEMO VARCHAR(100);
alter table HQ_ISSUE_TCSL add TCSL_EXTCOL JSON;


/* Table: TCSL_DETAIL, Owner: SYSDBA */

CREATE TABLE TCSL_DETAIL   /*套餐选择详细*/
(
  CONTAINERID   INTEGER NOT NULL,
  TCSLID        INTEGER NOT NULL,  /*对应的套餐选择*/
  MENUITEMID    INTEGER,           /*可选项对应的品种编号*/
  RESERVE11     VARCHAR(40),       --价格 lzm add 2018-11-25 01:40:21
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  TOUCHSCRLINEID        INTEGER,
  TS_TSCHROW    INTEGER,
  TS_TSCHCOL    INTEGER,
  TS_TSCHHEIGHT INTEGER,
  TS_TSCHWIDTH  INTEGER,
  TS_TLEGEND    VARCHAR(100),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(100),
  TS_TSCHFONT   VARCHAR(40) DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,
  TS_TSNEXTSCR  INTEGER,
  TS_BALANCEPRICE       NUMERIC(15, 3),
  TS_TSCHCOLOR  VARCHAR(20),
  TS_TSCHFONTCOLOR      VARCHAR(20),
  TS_RESERVE01  VARCHAR(40),
  TS_RESERVE02  VARCHAR(40),
  TS_RESERVE03  VARCHAR(40),
  TS_RESERVE04  VARCHAR(40),
  TS_RESERVE05  VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,CONTAINERID)
);

CREATE TABLE MIPARINTERS  /*品种需要多份打印的打印信息表*/
(
  MIPRNID       SERIAL,
  MENUITEMID    INTEGER NOT NULL,
  PRINTCOUNT    INTEGER DEFAULT 0,
  LOGICPRNNAME  VARCHAR(100),
  HOLIDAY       VARCHAR(40),     /*假期*/
  TIMEPERIOD    VARCHAR(40),     /*时段*/
  DINMODES      VARCHAR(40),     /*用餐方式编号*/
  WEEK          VARCHAR(40),     /*星期*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MIPRNID)
);

CREATE TABLE WEB_GROUP /*附加信息所属组信息 lzm add 2011-08-10*/
(
  WEB_GROUPID    INTEGER NOT NULL,   /*组号 0,1,2,3,4.... */
  WEB_GROUPNAME  VARCHAR(40),        /*名称*/
  WEB_GROUPMEMO  VARCHAR(100),       /*备注*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  MENUITEMID INTEGER DEFAULT 0,   /*品种编号(负数代表类别miclassid)  //lzm add 2022-12-31 11:36:09 */
  WEB_EXTCOL JSON,      /*扩展信息  //lzm add 2022-12-31 11:36:09
                        { 
                          "canrepeat": "0",   //是否可以重复键入
                          "maxincount": "1"   //最多可以键入的次数
                          "minincount": "1"   //最少可以键入的次数
                        }
                        */

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MENUITEMID,WEB_GROUPID)
);
alter table WEB_GROUP add MENUITEMID INTEGER NOT NULL DEFAULT 0;
alter table NEW_WEB_GROUP add MENUITEMID INTEGER NOT NULL DEFAULT 0;
alter table HQ_ISSUE_WEB_GROUP add MENUITEMID INTEGER NOT NULL DEFAULT 0;
alter table WEB_GROUP add WEB_EXTCOL JSON;
alter table NEW_WEB_GROUP add WEB_EXTCOL JSON;
alter table HQ_ISSUE_WEB_GROUP add WEB_EXTCOL JSON;

alter table WEB_GROUP alter MENUITEMID set DEFAULT 0;
update WEB_GROUP set MENUITEMID=0 where MENUITEMID is null;
alter table WEB_GROUP alter MENUITEMID set NOT NULL;
alter table WEB_GROUP drop constraint web_group_pkey;
alter table WEB_GROUP add constraint web_group_pkey primary key(USER_ID,SHOPID,SHOPGUID,MENUITEMID,WEB_GROUPID);

CREATE TABLE WEB_MI_INFO  /*品种拥有的附加信息*/
(
  MENUITEMID INTEGER NOT NULL,  /*品种编号*/
  INFOITEMID INTEGER NOT NULL,  /*附加信息编号 -- 1=附加信息*/
  INFOLINEID INTEGER NOT NULL,  /*行号*/

  USER_ID INTEGER DEFAULT 0,        /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',   /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  INFOCLASSNAME VARCHAR(40) DEFAULT '',  /*用于保存扩展信息，例如{3}代表需要加价3元,{-3}代表减3元 lzm modify 2023-06-11 03:59:35【之前为：分类名称 lzm add 2018-08-06 16:10:58】*/
  WEB_GROUPID    INTEGER,           /*组号 0,1,2,3,4.... lzm add 2022-12-31 11:08:38*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID, MENUITEMID, INFOITEMID, INFOLINEID)
);
alter table WEB_MI_INFO add WEB_GROUPID INTEGER;
alter table NEW_WEB_MI_INFO add WEB_GROUPID INTEGER;
alter table HQ_ISSUE_WEB_MI_INFO add WEB_GROUPID INTEGER;

CREATE TABLE MIHOLIDAY  /*(品种,服务费)的假期*/
(
  MIHID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  SDAY  VARCHAR(40),  /*开始日期*/
  EDAY  VARCHAR(40),  /*结束日期*/
  GROUPID  VARCHAR(10),  /*所属的组编号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MIHID)
);

CREATE TABLE MITIMEPERIOD /*(品种,服务费,折扣)的时段*/
(
  MITID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME VARCHAR(40),  /*开始时间*/
  ETIME VARCHAR(40),  /*结束时间*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MITID)
);

CREATE TABLE BUYSLGIVESL  /*满量优惠(买几送几)*/
(
  SGID          INTEGER NOT NULL,
  SGMENUITEMID  VARCHAR(20) NOT NULL,     /*品种编号*/
  SGBUYSEVERAL  NUMERIC(15,3),   /*满额量(买几)*/
  SGGIVESEVERAL NUMERIC(15,3),   /*折扣量(送几)*/
  SGHOLIDAY     VARCHAR(40),     /*假期(非日期[2018-01-01 2018-02-02]代表从假期表提取)*/
  SGWEEK        VARCHAR(40),     /*星期(多个时用,分割)*/
  SGTIMEPERIOD  VARCHAR(40),     /*时段(非时间[00:00:00 23:59:59]代表从假期表提取)*/
  SGDISCOUNT    VARCHAR(40) DEFAULT '',     /*折扣金额(空或''代表-100%) ==> 10%（即：价格=10%） 10（即：价格=10元） -10%（即：减去10%） -10（即：减去10元）lzm add 2018-07-01 16:21:45*/
  SGVIP         VARCHAR(40) DEFAULT '',     /*会员卡种(多个时用,分割) lzm add 2018-07-01 16:21:41*/
  SGSHOPIDS     VARCHAR(40) DEFAULT '',     /*适合门店(多个时用,分割) lzm add 2018-07-01 16:24:10*/
  SGNAME        VARCHAR(40) DEFAULT '',     /*活动名称(从MIDETAIL_CampaignActivity来) lzm add 2018-07-01 16:32:55*/
  SGFROM        INTEGER DEFAULT 0,          /*来源 0=品种管理 1=来自营销活动*/
  SGMENUITEMNAME VARCHAR(100),              /*品种名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  SGDISCOUNTFROM INTEGER DEFAULT 0,  /*满量特卖-单价控管(即：当混搭的品种有不同价格时对那个品种进行打折) 0=低价 1=高价 lzm add 2018-11-06 20:52:13*/
  SGPRIORITY INTEGER DEFAULT 0,      /*活动的优先级别，数字越大级别越高，比如：2级大于1级 lzm add 2018-11-10 21:22:52*/
  SGACTID INTEGER DEFAULT 0,         /*活动ID lzm add 2018-11-12 04:17:11*/
  SGACTCODE VARCHAR(40) DEFAULT '',  /*活动编号 lzm add 2018-11-12 04:17:16*/
  SGACTTYPE INTEGER DEFAULT 0,       /*活动类型 lzm add 2018-11-15 05:21:24*/
  SGINFOITEMS TEXT DEFAULT '',       /*活动对应的附加信息 多个时用逗号分隔 lzm add 2018-11-26 03:10:47*/

  SGPOINTSRATE integer default 0,    /*积分倍增活动 的积分倍数 lzm add 2019-11-19 16:44:23*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,SGID)
);

/* Table: MIMAKEUP, Owner: SYSDBA */

CREATE TABLE MIMAKEUP  /*品种的原材料构成*/
(
  MENUITEMID    INTEGER NOT NULL,             /*品种编号*/
  MTID          VARCHAR(30) NOT NULL,         /*原材料用户编号，对应进销存原材料的UserCode*/
  AMOUNT        NUMERIC(15, 3) DEFAULT 0,     /*销售单价*/
  MMCOUNTS      NUMERIC(15, 3) DEFAULT 0,     /*数量*/
  UNIT          VARCHAR(30),                  /*单位1*/
  LINEID        INTEGER DEFAULT 0,            /*行号*/
  UNITOTHERCOUNTS  NUMERIC(15, 3) DEFAULT 0,  /*单位2数量*/
  DEPOTID       INTEGER DEFAULT 0,            /*仓库编号*/
  WAREID        INTEGER DEFAULT NULL,         /*原材料ID编号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/
  warename      VARCHAR(30) DEFAULT '',     /*品种名称 lzm add 2016-10-15 16:58:11*/
  depotname     VARCHAR(30) DEFAULT '',     /*仓库名称 lzm add 2016-10-15 16:58:15*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MENUITEMID,MTID)
);

CREATE TABLE MIDETAIL_NEXTMICLASS   /*品种对应的下一类别*/
(
  NMMENUITEMID  INTEGER NOT NULL,     /*品种编号*/
  NMLINEID      INTEGER NOT NULL,     /*顺序编号*/
  NMMICLASS     INTEGER DEFAULT 0,    /*候选类别编号*/
  NMCANREPEAT   INTEGER DEFAULT 1,    /*是否允许重复选择相同的品种*/
  NMMAXCOUNT    INTEGER DEFAULT 1,    /*最多选择次数*/
  NMMINCOUNT    INTEGER DEFAULT 1,    /*最少选择次数*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,NMMENUITEMID,NMLINEID)
);

CREATE TABLE MIDETAIL_SPLITPRICE   /*品种对应的大单分账*/
(
  SPMENUITEMID  INTEGER NOT NULL,          /*品种编号*/
  SPLINEID      INTEGER NOT NULL,          /*顺序编号*/
  SPITEMID      INTEGER DEFAULT 0,         /*分账的品种编号*/
  SPITEMNAME    VARCHAR(100),              /*分账的品种名称*/
  SPITEMPRICE   NUMERIC(15,3) DEFAULT 0,   /*分账的品种价格*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,SPMENUITEMID,SPLINEID)
);

CREATE TABLE MIDETAIL_STOCK_ERP   /*品种对应的ERP(Odoo)存量*/ /*lzm add 2021-11-16 04:03:10*/
(
  MENUITEMID  INTEGER NOT NULL,            /*品种编号  当menuitemid-1时： STOCKNUM=0.000代表可以负库存销售， STOCKNUM=1.000代表不可以负库存销售*/
  STOCKNUM numeric(15,3) DEFAULT 0,        /*存量数量*/
  STOCKTIME timestamp default null,        /*存量的时间*/
  PRODUCT_ID integer default 0,            /*ERP商品的id*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MENUITEMID)
);
--用于 INSERT INTO [TABLE] ON CONFLICT (USER_ID, SHOPID, MENUITEMID) DO UPDATE SET --lzm add 2022-09-07 01:00:46 
create unique index MIDETAIL_STOCK_ERP_user_id_shopid_menuitemid_idx on MIDETAIL_STOCK_ERP(user_id,shopid,shopguid,menuitemid);
create unique index HQ_ISSUE_MIDETAIL_STOCK_ERP_user_id_shopid_menuitemid_idx on HQ_ISSUE_MIDETAIL_STOCK_ERP(user_id,shopid,shopguid,menuitemid);
create unique index HQ_ISSUE_SHOP_CNF_user_id_shopid_dataid_idx on HQ_ISSUE_SHOP_CNF(user_id,shopid,shopguid,dataid);

CREATE TABLE MIDETAIL_CampaignActivity /*品种对应的营销活动 lzm add 2017-07-25 19:14:56*/
(
  id integer not null,                     /*ID*/
  act_code VARCHAR(40) NOT NULL,           /*活动编号*/
  act_name VARCHAR(200) NOT NULL,          /*活动名称*/
  --voucher_itemName VARCHAR(200) NOT NULL,       /*品种名称*/
  --voucher_type VARCHAR(40) NOT NULL,            /*活动类型*/
  --original_price NUMERIC(15,3) DEFAULT 0,       /*品种原价*/
  act_timetype integer default 0,          /*时段类型 0=连续 1=间隔*/
  act_use integer default 1,               /*是否启用活动(1=启用，0=停用)*/
  act_date_start varchar default '',       /*活动开始日期*/
  act_date_end varchar default '',         /*活动结束日期*/
  act_time_start varchar default '',       /*活动开始时间*/
  act_time_end varchar default '',         /*活动结束时间*/
  act_vip integer default 0,               /*会员专属 0=否 1=是*/
  act_week varchar(40) default '',         /*星期限定 (格式:1,2,3,4,5,6,7 多个时用逗号","分隔) */
  act_describe varchar(200) default '',    /*活动描述*/
  act_memo varchar(200) default '',        /*活动备注*/
  act_type integer default 0,              /*活动类型 
                                              注意：1.需要添加到门店的root/PythonCode/hq/hq_GetShopConfigData.py 查找关键字 act_type
                                                    2.需要添加到门店存储过程send_campaignactivity_to_buyslgivesl 查找关键字 act_type
                                               0=满量特卖活动 
                                               1=折扣特卖活动(每个品种都有自己的折扣和单价) 
                                               2=送券优惠活动 
                                               3=积分倍增活动 
                                               4=积分清零活动
                                               5=加收服务费活动  --lzm add 2021-01-22 16:56:22
                                               6=全场折扣活动  --lzm add 2021-01-30 17:31:49
                                               7=价格变更活动（目前只适用线下门店POS端）  --lzm add 2024-02-02 00:07:28
                                           */
  act_fullgive_mode integer default 0,     /*满量特卖方式 0=满减*/

  act_fullgive_fullcount integer default 0,           /*满量特卖-满额数量*/
  act_fullgive_discountcount integer default 0,       /*满量特卖-折扣数量*/
  act_fullgive_discountamount varchar(40) default '', /*满量特卖-折扣 10%(价格=10%) 10(价格=10元) -10%(减去10%) -10(减去10元)*/

  act_fullgive_discountfrom integer default 0,        /*满量特卖-单价控管(即：当混搭的品种有不同价格时对那个品种进行打折) 
                                                      0=低价优先（满量与优惠是相同的品种） 
                                                      1=高价优先（满量与优惠是相同的品种） 
                                                      2=特卖套餐（根据“优惠品种”对指定品种的数量进行折扣） --优惠品种设置在"MIDETAIL_CampaignActivity_givemenuitems"
                                                      3=红绿配（满量与优惠分别是不同的品种）  --优惠品种设置在"MIDETAIL_CampaignActivity_givemenuitems"
                                                      4=买啥优惠啥（买品种A，只能优惠品种A）
                                                      */

  act_card_id varchar(40) default '',      /*对应的卡券card_id lzm add 2018-07-09 09:32:17*/

  act_rule json,                           /* 
    {
      --act_type 为"2=送券优惠活动"生效，表示送券活动规则
      "rule_givecoupons": [{
        "ruleid": "2",                          //规则ID  2=关联实体卡时送优惠券
                                                          3=关注公众时送优惠券
                                                          4=充值送优惠券 
                                                          5=完善资料送券 
                                                          6=会员生日送券 
                                                          7=会员筛选送券 
                                                          8=会员消费满送券 
                                                          9=抢购优惠券活动  --lzm add 2020-04-17 17:22:35
                                                          10=激活微信会员卡送券

        "tri_opencard": "0",                    --关联实体卡时送优惠券 0或空=否 1=是 (opencard, inaccounts, recharge 只能3选一)
        "tri_inaccounts": "0",                  --关注公众时送优惠券 0或空=否 1=是 (opencard, inaccounts, recharge 只能3选一)
        "tri_rechargerange": "100",             --充值送优惠券，充值金额的值达到多少才送优惠券 0或空=否 >1=代表充值金额 (opencard, inaccounts, recharge 只能3选一)
        "tri_completeuserdata": "0",            --完善资料送券
        "tri_consumefull": "",                  --消费满送券，账单消费满多少送优惠券 0或空=不送 >1=代表消费满的金额

        "tri_filter_user": "USER_FILTER_ALL",        --USER_FILTER_ALL 所有用户, 
                                                       VIP_FILTER_ALL 全部会员, 
                                                       VIP_FILTER_OLD 老会员, 
                                                       VIP_FILTER_ACTIVE 活跃会员, 
                                                       VIP_FILTER_QUIET 沉寂会员, 
                                                       VIP_FILTER_CUSTOMCARD 指定会员卡

        "tri_filter_consumedaterange": "20180101,20180301",  --消费期间
        "tri_filter_consumesum": "100.00",                   --消费总金额
        "tri_filter_consumecount": "60",                     --消费次数
        "tri_filter_birthdaterange": "0201,0601",            --生日期间
        "tri_filter_gender": "1",                            --用户的性别，值为1时是男性，值为2时是女性，值为0时是未知
        "tri_filter_shopid": "'001','002'",                  --消费的门店，例如：'001','002'...'003'  --lzm add 2020-03-18 13:50:37
        "tri_filter_cardid": "6,9,52",                       --消费的会员卡cardid  --lzm add 2020-03-19 08:27:13
        "tri_p_price": "9.9",                                --抢购价  --lzm add 2020-04-18 06:09:18
        "tri_p_orig": "100",                                 --抢购原价  --lzm add 2020-04-18 06:09:18
        "tri_p_info": "100优惠券一张",                       --抢购说明  --lzm add 2020-04-18 06:09:18

        "date_type": "DATE_TYPE_BIRTHDAY_TERM", --送券时间类型 DATE_TYPE_BIRTHDAY_TERM 生日发送, DATE_TYPE_MONTH_TERM 每月发送, DATE_TYPE_FIX_TERM 固定天数发送
        "date_birthdayterm": "5",               --datetype为 DATE_TYPE_BIRTHDAY_TERM 时专用，表示生日前多少天送优惠券。提示:该范围内的天数都可以触发（单位为天）
        "date_monthterm": "1",                  --datetype为 DATE_TYPE_MONTH_TERM 时专用，表示每个月的第几天送优惠券
        "date_fixterm": "0",                    --datetype为 DATE_TYPE_FIX_TERM 时专用，表示多少天后发送，马上发送填0（单位为天）

        "act_mall400pro": "0",                  --是否商城活动 --lzm add 2021-10-09 01:11:47
        "tri_filter_vipcards": ["cardno1","cardno2","cardno3"],      --当 tri_filter_user = VIP_FILTER_CUSTOMCARD 时，指定的会员卡号列表  --lzm add 2021-10-11 12:20:14

        "coupons": [{"coupon_id":"001", "counts":1}],   --赠送的优惠券
      }],
      -----------------------------------------------
      "rule_vip", [{
        "use_score": "0"                        --是否扣会员积分 0或空=否 1=是  --lzm add 2020-07-20 12:53:04
      }],

      -----------------------------------------------
      "rule_score_clear": [{                               --积分清零活动的设置
        "clear_before_date": "2019-12-31"，                  --清除这个日期和之前的积分
        "clear_send_msg_days": ["5", "15", "20", "30"],      --提前多少天通知，多个时用逗号分隔
        "clear_send_msg_dates": ["20200100", "20200115", "20200120", "20200130"],            --通知日期
      }],

      -----------------------------------------------
      "rule_service_charge": [{              --加收服务费
        "fee": "10%",                        --10=收取10元服务费，10%=收取折后金额10%服务费
        "modenames": "堂食;外面;外带",       --用餐方式名称
        "computype": "1",                    --计算方式 1=开新单计 2=即时计
      }],

      -----------------------------------------------
      "rule_full_discount": [{               --全场折扣
        "fee": "10%",                        --10=扣减10元折扣，10%=扣减10%折扣
        "modenames": "堂食;外面;外带",       --用餐方式名称
        "computype": "1",                    --计算方式 1=开新单计 2=即时计
      }],
      
      -----------------------------------------------
      "rule_params": [{                      --其它参数 --lzm add 2023-07-06 06:24:40
        "computype": "1",                    --计算方式 1=开新单计 2=即时计
      }],
      
      -----------------------------------------------
      "rule_table_section": "D,E",           --台号区域 --lzm add 2024-02-02 12:31:41
      
    }
                                           */

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',
  act_priority integer default 0,     /*活动的优先级别，数字越大级别越高，比如：2级大于1级 lzm add 2018-11-10 21:22:52*/
  act_points_rate integer default 0,  /*积分倍增活动 的积分倍数 lzm add 2019-11-11 01:29:34*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id)
);
alter table MIDETAIL_CampaignActivity add act_card_id varchar(40) default '';

CREATE TABLE MIDETAIL_CampaignActivity_menuclass /*没做 品种对应的营销活动-关联类别*/
(
  id integer not null,
  act_id integer not null,               /*营销活动的ID*/
  menuclassname varchar(100),            /*类别名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id,act_id)
);

insert into MIDETAIL_CampaignActivity_menuitems select * from tb100 where id<5;
CREATE TABLE MIDETAIL_CampaignActivity_menuitems /*品种对应的营销活动-关联品种*/
(
  id integer not null,
  act_id integer not null,               /*营销活动的ID*/
  menuitemname varchar(100),             /*特卖品种名称*/
  menuitemunit varchar(40),              /*特卖品种单位*/
  menuitemdiscount varchar(40),          /*特卖折扣 5% */
  menuitemprice numeric(15,3),           /*特卖金额(用于会员价)*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',
  
  MENUITEMID INTEGER,                   --用于骏丰南沙店相同品种名称存在2个类别（分别用于午餐和晚餐不同时段） --lzm add 2024-02-02 17:53:53
  MIPRICE_ORIGINAL varchar(40),         --原价  --lzm add 2024-02-02 19:04:30
  MEMO varchar(240),                    --备注  --lzm add 2024-02-02 19:04:30
  mi4dname json,                        --多份价格名称 [{"TBID":"", "PRICE":""}, ...]  --lzm add 2024-3-29 23:02:10

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id,act_id)
);

CREATE TABLE MIDETAIL_CampaignActivity_givemenuitems /*品种对应的营销活动-送的品种 lzm 2019-06-07 06:16:39*/
(
  id integer not null,
  act_id integer not null,               /*营销活动的ID*/
  menuitemname varchar(100),             /*优惠品种名称*/
  menuitemunit varchar(40),              /*优惠品种单位*/
  menuitemdiscount varchar(40),          /*优惠折扣 5% */
  menuitemprice numeric(15,3),           /*优惠金额(用于会员价)*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',
  menuitemcounts integer default 1,      /*优惠的数量*/
  menuitemid integer default 0,          /*品种编号(门店下载时与门店的品种名称进行匹配查到menuitemid并填入这里) 用于门店*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id,act_id)
);

CREATE TABLE MIDETAIL_CampaignActivity_infoitems /*品种对应的营销活动-关联附加信息*/
(
  id integer not null,
  act_id integer not null,               /*营销活动的ID*/
  menuitemname varchar(100),             /*附加信息名称*/
  menuitemunit varchar(40),              /**/
  menuitemdiscount varchar(40),          /**/
  menuitemprice numeric(15,3),           /**/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id,act_id)
);

CREATE TABLE MIDETAIL_CampaignActivity_shops /*品种对应的营销活动-关联门店*/
(
  id integer not null,
  act_id integer not null,               /*营销活动的ID*/
  shopcode varchar(40),                  /*特卖门店编号*/
  shopname varchar(100),                 /*特卖门店名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id,act_id)
);

CREATE TABLE MIDETAIL_CampaignActivity_vip /*品种对应的营销活动-关联会员卡种*/
(
  id integer not null,
  act_id integer not null,          /*营销活动的ID*/
  cardid integer,                   /*会员卡cardid(不是微信卡的card_id)*/
  vipid varchar(40),                /*会员卡种ID*/
  vipname varchar(100),             /*会员卡种名称*/
  vipusercode varchar(40),          /*会员卡种用户编号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  token varchar(60) DEFAULT '',

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,id,act_id)
);

CREATE TABLE MIDETAIL_GIVEITEM   /****20100615停止使用(用存储过程代替)***(A+B送C lzm add 【2009-05-05】)*/
(
  GIITEMA       VARCHAR(20) NOT NULL,     /*A品种编号*/
  GIITEMB       VARCHAR(20) NOT NULL,     /*B品种编号*/
  GIITEMC       VARCHAR(20) NOT NULL,     /*C品种编号*/
  PRIMARY KEY (GIITEMA,GIITEMB)
);

/* Table: PRINTPOOL, Owner: SYSDBA */

CREATE TABLE PRINTPOOL
(
  PRINTPOOLID   INTEGER NOT NULL,
  COUNTS        INTEGER,
  MENUITEMID    INTEGER,
  MIDETAILNAME  VARCHAR(100),
  EXTENDNAME    VARCHAR(100),
  ATABLES       VARCHAR(40),
  LOGICPRNNAME  VARCHAR(40),
  PRINTTAG      INTEGER DEFAULT 0,
  ATIME TIMESTAMP,
  MIDETAILNAME_LANGUAGE VARCHAR(100),
  EXTENDNAME_LANGUAGE   VARCHAR(100),
 PRIMARY KEY (PRINTPOOLID)
);

/* Table: SERVICEAUTO, Owner: SYSDBA */

CREATE TABLE SERVICEAUTO  /*服务费*/
(
  SAID          INTEGER NOT NULL,
  SANAME        VARCHAR(40),     /*服务费的名称*/
  SATYPE        INTEGER,         /*0=百分比 , 1=金额 */
  PERSAPRICE    NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTSAPRICE    NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  SAHOLIDAY     VARCHAR(40),     /*假期*/
  SATIMEPERIOD  VARCHAR(40),     /*时段*/
  SADINMODES    VARCHAR(40),     /*用餐方式编号*/
  SAWEEK        VARCHAR(40),     /*星期*/
  SACOMPUTTYPE  VARCHAR(10),     /*计算方式 1=开新单计, 2＝即时计*/
  LIDU  INTEGER,           /*
                             = 0; //对账单中的当前品种添加服务费
                             = 1; //代表对账单中的当前的品种添加服务费
                             = 2; //下一菜式要收服务费
                             = 3; //取消2方式定义的服务费
                             = 4; //对账单中的所有的菜项添加服务费
                           */
  BCID          INTEGER,
  ANUMBER       INTEGER,

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,SAID)
);

/* Table: SERCHARGE, Owner: SYSDBA */

CREATE TABLE SERCHARGE /*服务费(停用)*/
(
  SERCHGID      INTEGER NOT NULL,
  SERCHGNAME    VARCHAR(40),     /*服务费的名称*/
  SERCHGTYPE    INTEGER,         /*0=百分比 , 1=金额 */
  PERSERCHG     NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTSERCHG     NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  BCID  INTEGER,
  ANUMBER       INTEGER,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  LIDU  INTEGER,           /*
                             = 0; //对账单中的当前品种添加服务费
                             = 1; //代表对账单中的当前的品种添加服务费
                             = 2; //下一菜式要收服务费
                             = 3; //取消2方式定义的服务费
                             = 4; //对账单中的所有的菜项添加服务费
                           */
 PRIMARY KEY (SERCHGID)
);

/* Table: SERVICEPERIOD, Owner: SYSDBA */

CREATE TABLE SERVICEPERIOD   /*服务时段(停用)*/
(
  SPID  INTEGER NOT NULL,
  NAME  VARCHAR(40),         /*名称*/
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  RESERVE01     VARCHAR(40), /*开始时间*/
  RESERVE02     VARCHAR(40), /*结束时间*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
 PRIMARY KEY (SPID)
);

/* Table: SUBMENUCLASS, Owner: SYSDBA */

CREATE TABLE SUBMENUCLASS
(
  SUBMENUCLASSID        INTEGER NOT NULL,
  MAINMENUCLASSID       INTEGER,
  SUBMENUCLASSNAME      VARCHAR(40),
  SORTORDER     INTEGER,
  TOUCHSCRID    INTEGER,
  TOUCHSCRLINEID        INTEGER,
  SIMPLENAME    VARCHAR(20),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
 PRIMARY KEY (SUBMENUCLASSID)
);

/* Table: SYSTEMPARA, Owner: SYSDBA */

CREATE TABLE SYSTEMPARA    /*系统参数*/
(
  ID    SERIAL,
  NAME  VARCHAR(240),
  VAL   TEXT, /*old varchar(40), alter table SYSTEMPARA alter VAL type VARCHAR(240)*/
  RESERVE01     VARCHAR(40),  /*Section*/
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MDTIME        TIMESTAMP,    /*数据修改时间*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);

CREATE TABLE SYSTEMPARA_400    /*400上设置的系统参数*/ /*lzm add 2021-11-18 12:46:28*/
(
  ID    SERIAL,
  NAME  VARCHAR(240),
  VAL   TEXT, /*old varchar(40), alter table SYSTEMPARA alter VAL type VARCHAR(240)*/
  RESERVE01     VARCHAR(40),  /*Section*/
  RESERVE02     VARCHAR(40),  /*file=更新到文件root\data\SystemPara.ini db=更新到SYSTEMPARA表*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MDTIME        TIMESTAMP,    /*数据修改时间*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);

/* Table: TABLE1, Owner: SYSDBA */

CREATE TABLE TABLE1     /*   菜式4维表(扩展价格表)   */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),    /* MIDETAIL菜式编号-MENUITEMID  */
  RESERVE02     VARCHAR(40),    /* 更改为扩展信息: 计量单位#11其它保留位置#9菜名简称 --lzm modify 2024-01-31 12:55:51【之前：菜名-MENUITEMNAME,可填可不填】*/
  RESERVE03     VARCHAR(40),    /*  1维 = 填入TABLE4中1维的行编号line id=table4.RESERVE02 and table4.RESERVE01='1'(TABLE4只是用于记录名称)*/
  RESERVE04     VARCHAR(40),    /*  2维 = 填入TABLE4中2维的行编号line id=table4.RESERVE02 and table4.RESERVE01='2'(TABLE4只是用于记录名称)*/
  RESERVE05     VARCHAR(40),    /*  3维 = 填入TABLE4中3维的行编号line id=table4.RESERVE02 and table4.RESERVE01='3'(TABLE4只是用于记录名称)*/
  RESERVE06     VARCHAR(40),    /*  4维 = 填入TABLE4中4维的行编号line id=table4.RESERVE02 and table4.RESERVE01='4'(TABLE4只是用于记录名称)*/
  RESERVE07     VARCHAR(40),    /*  价格  */
  RESERVE08     VARCHAR(40),    /*  数量（沽清存量）  */
  RESERVE09     VARCHAR(40),    /*  时间段编号对应MITIMEPERIOD的MITID【之前为：(时间维) = TIMEPERIOD.TPID(SPID)】*/
  RESERVE10     VARCHAR(40),    /*  条码 */
  RESERVE11     VARCHAR(40),    /*  打印机*/
  RESERVE12     VARCHAR(40),    /*  用餐方式编号 = DINMODES.MODEID*/
  RESERVE13     VARCHAR(40),    /*  排列编号*/
  RESERVE14     VARCHAR(40),    /*  其它类型, 1=会员价*/
  RESERVE15     VARCHAR(200),   /*  外卖品种编码，例如：美团外卖的品种编码 lzm modify 2018-08-21 13:42:24*/
  RESERVE16     VARCHAR(40),    /*  假日段编号对应MIHOLIDAY的MIHID*/
  RESERVE17     VARCHAR(40),    /*  星期*/
  PRE_CLASS     VARCHAR(40),    /*  优惠价格类型(撞优惠类别)*/
  T1COST        VARCHAR(20),    /* 成本(注解:PDA点菜时不录入该值,在提交到服务端时根据选择的价格重新提取T1COST) lzm add 2010-06-09 */
  T1KICKBACK    VARCHAR(20),    /* 提成(注解:PDA点菜时不录入该值,在提交到服务端时根据选择的价格重新提取T1KICKBACK) lzm add 2010-06-09 */

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TBID)
);
alter table table1 alter column RESERVE02 type varchar(200);
alter table new_table1 alter column RESERVE02 type varchar(200);
alter table hq_table1 alter column RESERVE02 type varchar(200);


/* Table: TABLE2, Owner: SYSDBA */

CREATE TABLE TABLE2       /*   原料表(停用)    */
(
  TBID  INTEGER NOT NULL,    /* 原料编号  */
  RESERVE01     VARCHAR(40), /* 价格 */
  RESERVE02     VARCHAR(40), /* 库存数量*/
  RESERVE03     VARCHAR(40), /* 名称  */
  RESERVE04     VARCHAR(40), /* 条码 */
  RESERVE05     VARCHAR(40), /*  单位 */
  RESERVE06     VARCHAR(40), /* 对应所属原料类别编号,与TABLE8关联*/
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
 PRIMARY KEY (TBID)
);

/* Table: TABLE3, Owner: SYSDBA */

CREATE TABLE TABLE3        /*  菜式原料关系表(停用)  */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*  菜式编号 ,外键 */
  RESERVE02     VARCHAR(40),  /*  1维  */
  RESERVE03     VARCHAR(40),  /*  2维  */
  RESERVE04     VARCHAR(40),  /*  3维  */
  RESERVE05     VARCHAR(40),  /*  4维  */
  RESERVE06     VARCHAR(40),  /*   原料编号,外键  */
  RESERVE07     VARCHAR(40),  /*   原料数量*/
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
 PRIMARY KEY (TBID)
);

/* Table: TABLE4, Owner: SYSDBA */
/* （例如 1维有:大,中,小 2维有:冷,热 就记录在该表内）*/

CREATE TABLE TABLE4    /*记录TABLE1的四个维的数据(即：本餐饮系统拥有的四维数据定义)*/
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),   /*1:一维;2:二维;3:三维;4:四维 */
  RESERVE02     VARCHAR(40),   /*各维的内容编号line id*/
  RESERVE03     VARCHAR(40),   /*名称 */
  RESERVE04     VARCHAR(40),   /*名称(英文)   */
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TBID)
);

/* Table: TABLE5, Owner: SYSDBA */

CREATE TABLE TABLE5       /*记录ATABLES表中的预定台号的信息  */
(
  TBID  SERIAL,
  RESERVE01     VARCHAR(40), /* 台号*/
  RESERVE02     VARCHAR(40), /* 预定的先生或小姐贵姓或单位  */
  RESERVE03     VARCHAR(40), /* 预定 开始用餐日期  年月日yyyymmdd */
  RESERVE04     VARCHAR(40), /* 预定 开始用餐时间  hh:nn:ss  */
  RESERVE05     VARCHAR(40), /* 定金*/
  RESERVE06     VARCHAR(40), /* 记录当前落定的操作时间 yyyymmdd hh:nn*/
  RESERVE07     VARCHAR(40), /* 在[Tbook-v62,Tbook+v63]时间段内,记录预定人开单的标记:1  非预定人开单的标记:2; */
  RESERVE08     VARCHAR(40), /* 操作员*/
  RESERVE09     VARCHAR(40), /* (检测:过了v63时间,自动放弃预定台号,)标记为1--表示该记录不可用;0---可用*/
  RESERVE10     VARCHAR(40), /* 单位*/
  RESERVE11     VARCHAR(40), /* 电话*/
  RESERVE12     VARCHAR(40), /* 附加信息*/
  RESERVE13     VARCHAR(40), /* 记录ABUYER的BUYERID 预订对应的客户信息 */
  RESERVE14     VARCHAR(40), /* 人数 --lzm add 2023-12-22 05:35:36 */
  RESERVE15     VARCHAR(200), /*insert 临时记录CreateStrGuid*/
 PRIMARY KEY (TBID)
);

/* Table: TABLE6, Owner: SYSDBA */

CREATE TABLE TABLE6  /* 会员卡 VIP 积分管理 */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*累积消费额*/
  RESERVE02     VARCHAR(40),  /*会员券*/
  RESERVE03     VARCHAR(40),  /*对应VIP类别编号*/
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TBID)
);

/* Table: TABLE7, Owner: SYSDBA */

CREATE TABLE TABLE7  /* 前台界面 按钮颜色模块---->TSDETAIL  */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*已停用：记录Button类型  0-TExplorerButton, 1-NewButton */
  RESERVE02     VARCHAR(40),  /* 名称*/
  RESERVE03     VARCHAR(40),  /*TSCHCOLOR 按钮颜色*/
  RESERVE04     VARCHAR(40),  /* Bitmap  对于TSDETAIL.RESERVE02=0 此项不起作用; 只取文件名,不取路径,路径定死为:client.exe所在的目录再加上\Picture,如c:\SuperTouch\Picture  */
  RESERVE05     VARCHAR(40),  /* down Bitmap  对于TSDETAIL.RESERVE02=0 此项不起作用; 只取文件名,不取路径,路径定死为:client.exe所在的目录再加上\Picture,如c:\SuperTouch\Picture  */
  RESERVE06     VARCHAR(40),  /*TSCHFONTname*/
  RESERVE07     VARCHAR(40),  /*TSCHFONTSIZE*/
  RESERVE08     VARCHAR(40),  /*TSCHFONTCOLOR*/
  RESERVE09     VARCHAR(40),  /*文字位置*/
  RESERVE10     VARCHAR(40),  /*图片位置*/
  RESERVE11     VARCHAR(200),  /*其它属性(GlassFacePosition,)*/ /*lzm add 2021-03-23 01:18:36*/
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200), 
  /*BMPDOWN     BLOB SUB_TYPE 0 SEGMENT SIZE 80,*/
  /*BMP BLOB SUB_TYPE 0 SEGMENT SIZE 80,*/
  TSFONT1        VARCHAR(100),  /*font1的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT2        VARCHAR(100),  /*font2的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT3        VARCHAR(100),  /*font3的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT4        VARCHAR(100),  /*font4的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT5        VARCHAR(100),  /*font5的属性(charset,color,height,name,pitch,size,style)*/
  FONTSTYLE      INTEGER,    /*font.style 1=bold,2=ltalic,4=underline,8=strikeout*/
  PERLINEHAVEFONT  INTEGER DEFAULT 0,   /*每行文字用FONT而不是TSFONT1..TSFONT5*/
  BUTTONSTYLE    INTEGER DEFAULT 0,    /*按钮的类型(0=同系统按钮,1=Flat按钮,2=Class按钮,3=3D按钮)*/
  TEXTPOSITION    VARCHAR(20),    /*按钮文字的对齐方式*/
  GLYPHPOSITION    VARCHAR(20),    /*按钮图片的对齐方式*/
  BMPDOWN        VARCHAR(40),
  BMP            varchar(40),
  TransparentGlyph INTEGER DEFAULT 1,   /*图片背景透明*/
  FOLLOWSCREENTHEME INTEGER DEFAULT 1,  /*跟主题 0=否 1=是 lzm add 2011-11-21*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TBID)
);

CREATE TABLE SCREEN_THEME  /* 界面主题配置 lzm add 2011-11-19*/
(
  TBID  INTEGER NOT NULL,     /*主题编号*/
  CLASSID     VARCHAR(40),    /*主题界面编号
                                MICLASS=大类
                                MICLASSOTHER=小类
                                MIDETAIL=品种
                                MICLASSINFO=附加信息类别
                                MIDETAILINFO=附加信息
                                TABLE=台号
                                OTHER=其它
                                BACKROUND=底色*/
  CLASSNAME     VARCHAR(40),  /* 名称 */
  TSFONT0       VARCHAR(100), /*font0的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT1       VARCHAR(100), /*font1的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT2       VARCHAR(100), /*font2的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT3       VARCHAR(100), /*font3的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT4       VARCHAR(100), /*font4的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT5       VARCHAR(100), /*font5的属性(charset,color,height,name,pitch,size,style)*/
  BTNCOLOR      VARCHAR(40),  /*底色*/
  PERLINEHAVEFONT  INTEGER DEFAULT 0,   /*每行文字用FONT而不是TSFONT1..TSFONT5*/
  BUTTONSTYLE    INTEGER DEFAULT 0,    /*按钮的类型(0=同系统按钮,1=Flat按钮,2=Class按钮,3=3D按钮)*/
  TEXTPOSITION    VARCHAR(20),    /*按钮文字的对齐方式*/
  GLYPHPOSITION    VARCHAR(20),    /*按钮图片的对齐方式*/
  TransparentGlyph INTEGER DEFAULT 1,   /*图片背景透明*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  BUTTONOTHER VARCHAR(200) DEFAULT '',   /*按钮其它属性逗号分隔 lzm add 2021-03-23 17:56:18
                                            圆角[0=否 1=是]
                                          */

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TBID,CLASSID)
);

/*
DELETE FROM SCREEN_THEME where TBID=1;
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'MICLASS','#43A102', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'MICLASSOTHER','#849c32', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'MIDETAIL','#A2B700', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'MICLASSINFO','#909e5a', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'MIDETAILINFO','#a5b85e', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'TABLE','$00FFCCCC', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'OTHER','#43A102', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(1,'BACKROUND','#697CAF', 'charset=,color=#000000,height,name,pitch,size=12,style',0);

DELETE FROM SCREEN_THEME where TBID=2;
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'MICLASS','#04477c', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'MICLASSOTHER','#849c32', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'MIDETAIL','#065EB7', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'MICLASSINFO','#909e5a', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'MIDETAILINFO','#a5b85e', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'TABLE','$00FFCCCC', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'OTHER','#04477c', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(2,'BACKROUND','#697CAF', 'charset=,color=#000000,height,name,pitch,size=12,style',0);

DELETE FROM SCREEN_THEME where TBID=3;
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'MICLASS','#FF6600', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'MICLASSOTHER','#849c32', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'MIDETAIL','#FF981F', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'MICLASSINFO','#909e5a', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'MIDETAILINFO','#a5b85e', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'TABLE','$00FFCCCC', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'OTHER','#FF6600', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(3,'BACKROUND','#697CAF', 'charset=,color=#000000,height,name,pitch,size=12,style',0);

DELETE FROM SCREEN_THEME where TBID=4;
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'MICLASS','#FD9D01', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'MICLASSOTHER','#849c32', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'MIDETAIL','#FFBB1C', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'MICLASSINFO','#909e5a', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'MIDETAILINFO','#a5b85e', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'TABLE','$00FFCCCC', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'OTHER','#FD9D01', 'charset=,color=#000000,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(4,'BACKROUND','#697CAF', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);

DELETE FROM SCREEN_THEME where TBID=5;
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'MICLASS','#0595A3', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'MICLASSOTHER','#849c32', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'MIDETAIL','#06ADBC', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'MICLASSINFO','#909e5a', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'MIDETAILINFO','#a5b85e', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'TABLE','$00FFCCCC', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'OTHER','#0595A3', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
INSERT INTO SCREEN_THEME(TBID,CLASSID,BTNCOLOR,TSFONT0,BUTTONSTYLE) VALUES(5,'BACKROUND','#ECE9D8', 'charset=,color=#FFFFFF,height,name,pitch,size=12,style',0);
*/

/* Table: TABLE8, Owner: SYSDBA */

CREATE TABLE TABLE8       /* 原料类别表 ,与TABLE2关联(停用)*/
(
  TBID  INTEGER NOT NULL,    /*原料类别编号*/
  RESERVE01     VARCHAR(40), /*原料类别名称*/
  RESERVE02     VARCHAR(40), /*按钮类型:0-TLbSpeedButton;1-图形*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
 PRIMARY KEY (TBID)
);

/* Table: TABLE9, Owner: SYSDBA */

CREATE TABLE TABLE9    /*批处理事件-快捷输入:*05开头+对应的事件ID*/
(
  TBID  INTEGER NOT NULL, /*引用ID*/
  RESERVE01     VARCHAR(40), /*执行事件命令类型:0-内部事件;1-外部的EXE*/
  RESERVE02     VARCHAR(40), /*注解具体命令*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200), /*内容:内部事件---[功能号1,事件ID1{参数1}{参数2}..][功能号2,事件ID2{参数1}{参数2}..]..*/
                           /*     外部的EXE---具体路径{参数},可带参数    */
  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TBID)
);

/* Table: TABLE10, Owner: SYSDBA */

CREATE TABLE TABLE10  /*  Log  表  */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40), /*类型
                               0=普通
                               1=非接触式IC卡充值、改值
                               2=弹钱箱
                               3=转台
                               4=分单
                               5=合单
                               6=登录
                               7=修改价格
                               8=打折扣
                               9=收取服务费
                               10=修改数量
                               11=拷贝品种
                               12=沽清等操作
                               13=澳门通
                               14=支付宝付款
                               15=微信付款
                               16=其它支付操作
                               17=打印系统汇总报表  --用于触发数据上传稽核  --lzm add 2019-11-25 07:11:55
                               18=bbpos
                               19=微信会员卡
                               20=日结相关  --lzm add 2023-11-04 03:48:32
                               21=kpay  --lzm add 2025-07-26 01:10:52

                               30=后台管理系统 */
  RESERVE02     VARCHAR(40),  /*Log日期(格式：yyyy-mm-dd)*/
  RESERVE03     VARCHAR(40),  /*操作人员*/
  RESERVE04     TEXT,  /*原值*/
  RESERVE05     TEXT,  /*新值*/
  RESERVE06     TEXT,         /*内容 lzm modify varchar(200)->text 2013-02-27*/
  RESERVE07     VARCHAR(40),  /*商店编号SHOPID*/
  RESERVE08     VARCHAR(40),  /*终端号PCID*/
  RESERVE09     VARCHAR(100), /*按钮位置ScreenID,LINEID,BCID,ANUMBER*/
  RESERVE10     VARCHAR(40),  /*Log时间(格式：hh:nn:ss)*/
  RESERVE11     VARCHAR(40),  /*单号*/
  RESERVE12     VARCHAR(40),  /*授权人员*/
  RESERVE13     VARCHAR(40),  /*数据上传的稽核是否已处理 0或空=否 1=是 lzm add 2019-11-25 07:07:05*/
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
 PRIMARY KEY (TBID)
);
alter table TABLE10

/* Table: TENDERMEDIA, Owner: SYSDBA */

CREATE TABLE TENDERMEDIA   /*付款类型*/
(
  MEDIAID       INTEGER NOT NULL,
  MEDIANAME     VARCHAR(40),
  BCID  INTEGER,
  ANUMBER       INTEGER,
  MEDIARATE     NUMERIC(15, 3),  /*汇换率*/
  RESERVE1      VARCHAR(40),     /*not use*/
  RESERVE2      VARCHAR(40),     /*付款类型:
                                   对应 LISTCONTENT 的 LCLAID=21
                                   '0'=现金, '1'=CGC(赠券) 【在系统汇总报表，中根据该类型分别统计“现金”和“赠券”的消费金额】*/
                                 /*老版本的方式(v5.2之前)： CASHER REPORT 中,是否CGC(赠券),'Y' OR  'N'   */
  RESERVE3      VARCHAR(40), /*
                             0:空:普通
                             1:会员积分(之前是会员券)的付款方式(用A,B,C,D,E卡消费得到的积分付款)【会员可以有消费积分，根据消费积分可以转换为会员券】
                             2:用礼券付款【需要记录礼券编号】(v5.2之后的礼券付款标志)
                             3:"记帐"(CHECKRST.RESERVE04记录ABUYER.BUYERID)【旧的记账方式】
                             4:信用卡刷卡(CHECKRST.VISACARD_CARDNUM和CHECKRST.VISACARD_BILLNUM分别记录卡号和刷卡的帐单号)
                             5:订金
                             6:餐券付款【需要录入券额和数量，例如：20元2张】
                             7:银行积分付款 lzm add 【2009-06-21】
                             8:现金还款 lzm add 【2009-08-14】

                             9:IC卡记录消费金额的消费方式
                             10:IC卡充值的付款方式(金额数保存在IC卡上)  **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**

                             11:A卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             12:B卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             13:C卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             14:D卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             15:E卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**

                             16:直接修改总积分付款  //lzm add 2011-08-02
                             17:直接修改可用积分付款  //lzm add 2011-08-02
                             18:积分折现操作 //lzm add 2011-08-05
                             19:VIP卡挂失后退款的付款方式 //lzm add 2012-07-04
                             20:VIP卡挂失后换卡,补卡-新卡的付款方式 //lzm add 2012-07-04

                             21:A卡积分折现付款 lzm add 2011-07-13
                             22:B卡积分折现付款 lzm add 2011-07-13
                             23:C卡积分折现付款 lzm add 2011-07-13
                             24:D卡积分折现付款 lzm add 2011-07-13
                             25:E卡积分折现付款 lzm add 2011-07-13

                             26:酒店会员卡付款 lzm add 2012-06-17
                             27:酒店转房帐付款 lzm add 2012-06-17
                             28:酒店挂账付款 lzm add 2012-06-17

                             29:IC卡还款 lzm add 2013-11-28
                             30:磁卡还款 lzm add 2013-11-28

                             31:VIP卡挂失后换卡,补卡-旧卡的付款方式 //lzm add 2015/5/22 星期五

                             32:支付宝支付
                             33:微信支付
                             34:微信会员卡付款
                             35:微信会员积分付款
                             36:微信会员卡还款
                             37:微信优惠券
                             38:微信礼品卡付款 lzm add 2018-09-12 13:09:26
                             39:实体卡绑定微信会员卡 lzm add 2018-10-12 14:58:29

                             40:bbpos-付款（香港的收款对接设备），通过按钮参数设置具体的付款方式（CREDIT,KEYED,WECHAT,ALIPAY,QRPAY,OCTOPUS）
                             
                             41:"微信会员记帐"(CHECKRST.RESERVE04记录wecha_id)  --lzm add 2023-06-27 03:30:31
                             
                             42:直接扣减金额  --lzm add 2025-5-15 16:38:59

                             43:kpay-付款（香港的收款对接设备），通过按钮参数设置具体的付款方式（CREDIT,KEYED,WECHAT,ALIPAY,QRPAY,OCTOPUS） --lzm add 2025-07-22 18:23:10

                             100:消费日结标记 lzm add 2012-07-12

                             111:澳门通-售卡 lzm add 2013-02-26
                             112:澳门通-充值 lzm add 2013-02-26
                             113:澳门通-扣值 lzm add 2013-02-26
                             114:澳门通-结算 lzm add 2013-02-26
                             */
  RESERVE01     VARCHAR(40), /*(v5.2之前的礼券付款标志)是否礼券 标记为:L或l（需要录入礼券编号）*/
  RESERVE02     VARCHAR(40), /*固定付款金额*/
  RESERVE03     VARCHAR(40), /*对账额(折扣) 10%=9折 10=折掉10元 */
  RESERVE04     VARCHAR(40), /*最大允许的付款金额 50%=不能输入大于50%的账单金额 50=不能输入大于50元的金额 lzm modify 2009-08-07*/
  RESERVE05     VARCHAR(40), /*固定兑换后的金额 lzm add 2009-10-22*/
  NUMBER        VARCHAR(40), /*该付款的用户编号UserCode*/
  REPORTTYPE    VARCHAR(50) DEFAULT '', /*其它扩展参数 lzm add 2023-07-10 06:27:17【之前：用于新总部系统 lzm add 2010-09-02】
                                          {
                                            "bookaccountype":"0=付款 1=记账 2=还款", 
                                            "bookaccountvip":"0=线下会员 1=云端会员"
                                          }
                                        */

  DENOMINATION VARCHAR(40),    /*面额 >>>用在Android 手机 lzm add 2011-09-23*/
  REPORT_TYPE VARCHAR(40),     /*现金 信用卡  借记卡 支票 赠券 现金券 礼券 记账 其他 >>>用在Android 手机 lzm add 2011-09-23*/

  NEED_PAY_REMAIN INTEGER DEFAULT 0,  /*需要统计当前付款的账单余额 lzm add 2015-05-31*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MEDIAID)
);

/* Table: TIMEPERIOD, Owner: SYSDBA */

CREATE TABLE TIMEPERIOD  /*报表对应的时段*/
(
  TPID  INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  RESERVE01     VARCHAR(40),  /*当天的Start SPID*/
  RESERVE02     VARCHAR(40),  /*当天的End SPID,如为负数则为第二天的End SPID*/
  RESERVE03     VARCHAR(40),  /*开始时间*/
  RESERVE04     VARCHAR(40),  /*结束时间*/
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TPID)
);

CREATE TABLE CASHERTIMEPERIOD  /*收银报表对应的时段 lzm add 2012-07-22*/
(
  TPID  INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  RESERVE01     VARCHAR(40),  /**/
  RESERVE02     VARCHAR(40),  /**/
  RESERVE03     VARCHAR(40),  /*开始时间*/
  RESERVE04     VARCHAR(40),  /*结束时间*/
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TPID)
);

CREATE TABLE SHIFTTIMEPERIOD /*收银员时段对应的班次*/
(
  STPID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME VARCHAR(40),  /*开始时间*/
  ETIME VARCHAR(40),  /*结束时间*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,STPID)
);

/* Table: TRACKINGGROUP, Owner: SYSDBA */
/*
TGID
  1: 系统汇总报表
  2: 收银员汇总报表
  3: 周汇总报表
*/

CREATE TABLE TRACKINGGROUP  /*报表跟踪项*/
(
  TGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  ISDEFAULT     INTEGER,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TGID)
);

/* Table: TRACKINGGROUPITEM, Owner: SYSDBA */
/*
TGID
  1: 系统汇总报表
  2: 收银员汇总报表
  3: 周汇总报表
BCID的说明
 1:品种
 2:折扣
 3:服务费
 4:付款方式
 5:批处理
 6:功能
 7:报表辅助分类1
 8:报表辅助分类2
 9:TOTAL  从上一个9到这个9之间的总计
 10:说明信息
 11:OPENFOOD
 12:ALL TOTAL
 13:自动处理的品种结束标志
 14:四维品种
 15:大类和小类
 16:部门 //lzm add 2010-05-17
*/

CREATE TABLE TRACKINGGROUPITEM  /*报表跟踪项详细*/
(
  TGID  INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  BCID  INTEGER,                /*统计类别*/
  NUM   INTEGER,                /*内容编号*/
  APPENDCOL     VARCHAR(100),   /*说明信息*/
  RESERVE01     VARCHAR(40),    /*区域编号 A-Z //lzm add 2011-07-30*/
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TGID,LINEID)
);

/* Table: TSDETAILFORM, Owner: SYSDBA */

CREATE TABLE TSDETAILFORM  /*按钮授权列表(用于非动态按钮的授权)*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHLINEID    INTEGER NOT NULL,
  TLEGEND       VARCHAR(100) NOT NULL,        /*按钮名称(formname+buttonname)*/
  VALUSERSCLASS VARCHAR(40),                  /*授权用户组,多个用户组时用";"号分割*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TSCHID, TSCHLINEID, TLEGEND)
);

/* Table: TOUCHSCR, Owner: SYSDBA */

CREATE TABLE TOUCHSCR  /*界面*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHNAME      VARCHAR(100),
  RESERVE01     VARCHAR(40),  /*界面属性  模板编号 
                              0=普通界面
                              1=台号界面
                              2=收银界面
                              3=点菜界面
                              4=报表界面
                              5=设置界面
                              6=结账界面
                              7=外场点单编码界面
                              8=配菜界面
                              9=外场折扣界面
                              10=堂吃界面
                              11=外送界面
                              12=外带界面
                              13=其它用餐界面
                              14=简易点菜列表界面
                              15=详细点菜列表界面
                              16=账单金额信息界面
                              17=台号状态按钮界面
                              18=输入框或工具界面
                              */
  RESERVE02     VARCHAR(40),  /*子类别或子品种所在的界面，

                              已点列表位置信息
                              tsp_max_col,  
                              tsp_max_row,
                              tsp_max_height,
                              tsp_max_width,
                              tsp_min_height,
                              tsp_min_width,
                              tsp_min_col,
                              tsp_min_row,
                              tsp_defaultposition,   -- 0=详细 1=简单
                              tsp_ModeEnabled,
                              tsp_SubPanelVisible

                              */
  RESERVE03     VARCHAR(40),  /*自动开单参数
                              (
                               AutoOpenChecks 开单类型[0：无；1：堂食；2：外送；3:外带]
                               ,WhenReOpenFalse 取已结单失败后是否开新单[0:否,1:是]
                               ,WhenPickupFalse 取没结单失败后是否开新单[0:否,1:是]
                               ,AfterQueryChecks 查单后是否开新单[0:否,1:是]
                               ,AfterServiceTotal 入单后是否开新单[0:否,1:是]
                               ,AfterTenderMedia 结帐后是否开新单[0:否,1:是]
                              )*/
  RESERVE04     VARCHAR(40),  /*是否需要复位登陆数据,0=false,1=true*/
  RESERVE05     VARCHAR(40),  /*是否需要弹出显示和相关参数
                                    位置1:空或0=false 1=true 2=html(lzm add 2020-10-19 01:32:29) lzm modify 2010-07-21
                                    位置2:0=点击界面上的按钮后自动隐藏当前界面 1=不隐藏
                                    位置3:0=点击界面按钮后不隐藏当前界面 1=点击按钮后隐藏当前界面 lzm add 2010-10-10*/
  TSCHROW       INTEGER,
  TSCHCOL       INTEGER,
  TSCHHEIGHT    INTEGER,
  TSCHWIDTH     INTEGER,
  RELATE_TS01   INTEGER,  /*相关界面1*/
  RELATE_TS02   INTEGER,  /*相关界面2*/
  RELATE_TS03   INTEGER,  /*相关界面3*/
  RELATE_TS04   INTEGER,  /*相关界面4*/
  RELATE_TS05   INTEGER,  /*相关界面5*/
  RELATE_TS06   INTEGER,  /*相关界面6*/
  TSDETAILMAXLINEID     INTEGER DEFAULT 0,
  PTS   INTEGER,                /**/
  NTS   INTEGER,                /*做法1 做法2 做法3 ....做法N 所在的界面编号 0或空=无  lzm add 【2009-05-26】*/
  TSTIMESTAMP   TIMESTAMP,      /*修改时间*/
  PICTUREFILE   VARCHAR(240),   /*图片文件名称(包括路径)*/

  PANELMARGIN   VARCHAR(100),   /*LeftMargin,RightMargin,TopMargin,BottomMargin,BtnSpace,BadgeActive,ExtParam,HeadTSCHID(上一页界面ID),NextTSCHID(下一页界面ID)  lzm add 2011-11-22*/
  TITLETEXT     VARCHAR(100),   /*抬头内容  lzm add 2011-11-22*/
  TITLEFONT     VARCHAR(100),   /*抬头字体 charset,color,height,name,pitch,size,style  lzm add 2011-11-22*/
  BEVELWIDTH    INTEGER,        /*边框宽度 0=不显示边框 lzm add 2011-11-22*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TSCHID)
);

/* Table: TSDETAIL, Owner: SYSDBA */
/*
BCID的说明
 1:品种
 2:折扣
 3:服务费
 4:付款方式
 5:批处理
 6:功能
 7:报表辅助分类1
 8:报表辅助分类2
 9:TOTAL  从上一个9到这个9之间的总计
 10:说明信息
 11:OPENFOOD
 12:ALL TOTAL
 13:自动处理的品种结束标志
 14:四维品种
 15:大类和小类
 20:显示账单信息
        当ANUMBER:
        1=应付(总计)
        2=已付
        3=未付
        4=应找
        5=品种小计
        6=折扣
        7=服务费
        8=税1
        9=税2
        10=单号
        11=台号
        12=人数
        13=开单人
        14=操作人
        15=用餐方式
        16=订金
        17=会员券金额
        18=会员名称 称呼 电话 的信息
        19=开单时间
        20=原始单号
*/

CREATE TABLE TSDETAIL  /*按钮*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHLINEID    INTEGER NOT NULL,
  TSCHROW       INTEGER,
  TSCHCOL       INTEGER,
  TSCHHEIGHT    INTEGER,
  TSCHWIDTH     INTEGER,
  TLEGEND       VARCHAR(100),                   /*按钮名称*/
  TSCHFONT      VARCHAR(40) DEFAULT 'arial',
  TSCHFONTSIZE  INTEGER,
  BCID  INTEGER,
  ANUMBER       INTEGER,
  ANUMERIC      INTEGER,                        /*not use 数据类型不对（快捷键）*/
  TSNEXTSCR     INTEGER,                        /*下一界面编号*/
  BALANCEPRICE  NUMERIC(15, 3),                 /*差价(-10=加10 10=减10)*/
  TSCHCOLOR     VARCHAR(20),
  TSCHFONTCOLOR VARCHAR(20),
  RESERVE01     VARCHAR(40),                    /*按钮类型
                                                  空或0=TFreebutton

                                                */
  RESERVE02     VARCHAR(40),                    /**/
  RESERVE03     VARCHAR(40),                    /*快捷键*/
  RESERVE04     VARCHAR(40),                    /*颜色模版编号*/
  RESERVE05     VARCHAR(40),                    /*授权路径【权限名称 lzm modiy 2024-08-20 07:11:13】例如：权限付款/现金券 */
  TLEGEND_LANGUAGE      VARCHAR(100),           /*按钮英文名称*/
  TSVISIBLE     INT DEFAULT 1,                  /*按钮是否显示*/
  TSDPARAMETER  TEXT,                           /*按钮参数*/
  BALANCETYPE INTEGER DEFAULT 0,                /*差价的类型 0:直接减, 1:百分比, 2:等于品种价格减去该价格的值*/
  VALIDATEUSERSCLASS VARCHAR(254),              /*不需授权用户组,多个用户组时用";"号分割*/
  PICTUREFILE VARCHAR(240),                     /*图片文件名称(包括路径)*/
  VMICLASS text,                                /*不需需要授权的类别编号,有多个时用";"号分割*/
  VOPERATE VARCHAR(240),                        /*需要授权的操作*/
  ONBEFOREEVENT VARCHAR(200),                   /*执行前需要运行的批处理 lzm add 20100503*/
  ONAFTEREVENT VARCHAR(200),                    /*执行后需要运行的批处理 lzm add 20100503*/
  PRINTTEMPLATE VARCHAR(200),                   /*该事件前台打印需要用到的打印模版 lzm add 20100503*/
  PRINTCOUNT VARCHAR(40),                       /*该事件的前台打印份数 lzm add 20100504*/
  EXTPARAM VARCHAR(240),                        /*按钮扩展参数，分号分隔[ValidateOperate;] lzm add 20100504*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID, TSCHID, TSCHLINEID)
);

/* Table: VIP_MENUITEM, Owner: SYSDBA */

CREATE TABLE VIP_MENUITEM  /**/
(
  EMPID INTEGER NOT NULL,                   /*会员ID*/
  EMPLINEID     INTEGER NOT NULL,           /*LineID*/
  MENUITEMID    INTEGER,                    /* SID(大类或子类ID); -100000 ==>混合大类*/
  MENUITEMNAME  VARCHAR(100),               /*菜式名称, 若MENUITEMID为负   菜式ID, 若为负值,则该值为 MICLASS值,则为大类或子类名称*/
  COUNTS        INTEGER,                    /*数量*/
  FIXCOUNTS     INTEGER,                    /*记录原有的数量,不变的*/
  MIPRICE       NUMERIC(15, 3),             /*单价*/
  PARENTLINE    INTEGER,                    /*该菜式附属于某类别,=某类别EMPLINEID*/
  DISCOUNTTYPE  INTEGER DEFAULT 0,          /*针对MIPRICE: 0=不处理折扣,按MIPRICE原价处理;1=百分比折扣,为PERDISCOUNT;2=金额折扣,为PERDISCOUNT;3=该会员能打的折扣,由EMPCLASS.ACCESSLEVEL决定*/
  PERDISCOUNT   NUMERIC(15, 3) DEFAULT 0,   /*与DISCOUNTTYPE配合使用*/
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MENUITEMNAME_LANGUAGE VARCHAR(100),
  PRIMARY KEY (EMPID, EMPLINEID)
);

CREATE TABLE BEFOREFIX_ICCARD_CONSUME_INFO  /*修正数据前的备份(用于出报表) lzm add 2012-07-29*/
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,
  ICINFO_THETIME  TIMESTAMP NOT NULL,
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2   INTEGER DEFAULT 0,        /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单) 0=正常 1=作废单*/
  RESERVE3   TIMESTAMP,                /*保存销售数据的日期*/
  RSTLINEID  INTEGER,                  /*CHECKRST的行号*/
  CARDTYPE  VARCHAR(40),               /*卡的付款类别(11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0,
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分累计")消费金额 lzm add 2012-04-13
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额
                                                  */
  MEDIANAME  VARCHAR(40),                  /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);

CREATE TABLE MONTHTOTAL_ICCARD_CONSUME_INFO   /*保存一个月的合计数 lzm add 2013-05-16*/
(
  USER_ID INTEGER NOT NULL,
  SHOPID  VARCHAR(40) NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,           /*卡号*/
  ICINFO_MONTH TIMESTAMP NOT NULL,                 /*月份 2013-01-01代表2013年1月份*/
  ICINFO_VIPUSERNAME VARCHAR(40),                  /*会员名称*/
  ICINFO_AMOUNTS_BEFORE NUMERIC(15,3),             /*期初-金额*/
  ICINFO_GIVEAMOUNTS_BEFORE NUMERIC(15,3),         /*期初-赠送金额*/
  ICINFO_POINTS_BEFORE  NUMERIC(15,3),             /*期初-积分*/
  ICINFO_AMOUNTSPOINTS_BEFORE NUMERIC(15,3),       /*期初-积分折现金额*/
  ICINFO_AMOUNTS_IN NUMERIC(15,3),                 /*收入-充值金额*/
  ICINFO_GIVEAMOUNTS_IN NUMERIC(15,3),             /*收入-充值赠送金额*/
  ICINFO_POINTS_IN NUMERIC(15,3),                  /*收入-积分*/
  ICINFO_AMOUNTSPOINTS_IN NUMERIC(15,3),           /*收入-积分折现金额*/
  ICINFO_AMOUNTS_OUT NUMERIC(15,3),                /*支出-消费金额*/
  ICINFO_GIVEAMOUNTS_OUT NUMERIC(15,3),            /*支出-消费金额(赠送部分)*/
  ICINFO_POINTS_OUT NUMERIC(15,3),                 /*支出-消费积分*/
  ICINFO_AMOUNTSPOINTS_OUT NUMERIC(15,3),          /*支出-消费积分折现金额*/
  ICINFO_AMOUNTS_END NUMERIC(15,3),                /*期末-金额*/
  ICINFO_GIVEAMOUNTS_END NUMERIC(15,3),            /*期末-赠送金额*/
  ICINFO_POINTS_END NUMERIC(15,3),                 /*期末-积分*/
  ICINFO_AMOUNTSPOINTS_END NUMERIC(15,3),          /*期末-积分折现金额*/

  MEMO1  TEXT,                                     /*扩展信息*/
  REPORTCODE TEXT,
  ISFIXED INTEGER DEFAULT 0,
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',       /*店的GUID lzm add 2015-11-23*/

  ICINFO_AMOUNTS_REPAYMENT_IN NUMERIC(15,3),        /*收入-消费还款金额*/
  ICINFO_AMOUNTS_REFUND_IN NUMERIC(15,3),           /*收入-退款金额【挂失后退款】*/
  ICINFO_AMOUNTS_CHANGENEW_IN NUMERIC(15,3),        /*收入-补卡金额(新卡)【挂失后换新卡-新卡】*/
  ICINFO_AMOUNTS_CHANGEOLD_IN NUMERIC(15,3),        /*收入-补卡金额(旧卡)【挂失后换新卡-旧卡】*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ICINFO_ICCARDNO,ICINFO_MONTH)
);

/* Table: WHOLE_CHECKRST_MEDIANAME, Owner: SYSDBA */

CREATE TABLE WHOLE_CHECKRST_MEDIANAME(  /*用于400的报表，保存以日为单位的付款方式*/
  MEDIANAME VARCHAR(40),
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期*/
  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, RESERVE3, MEDIANAME)
);

--lzm add 2023-08-28 23:31:49
CREATE TABLE WHOLE_ICCARD_SUM  --会员卡汇总表
(
  RESERVE3  TIMESTAMP,             --数据的日期
  balance_sum numeric(15, 3),      --余额合计
  total_score_sum numeric(15, 3),      --积分
  
  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/
  
  primary key (USER_ID,SHOPID,SHOPGUID,RESERVE3)
);
create UNIQUE index whole_iccard_sum_unique_idx on whole_iccard_sum(RESERVE3);

--lzm add 2023-08-28 23:31:49
CREATE TABLE WHOLE_ICCARD_SUM_LINE  --会员卡汇总表明细
(
  RESERVE3  TIMESTAMP,             --数据的日期
  iccardno varchar(40),            --会员卡号
  balance numeric(15, 3),          --余额
  total_score numeric(15, 3),      --积分

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/
  
  primary key (USER_ID,SHOPID,SHOPGUID,RESERVE3,iccardno)
);
create UNIQUE index whole_iccard_sum_line_unique_idx on whole_iccard_sum_line(RESERVE3, iccardno);
create index whole_iccard_sum_line_reserve3_idx on whole_iccard_sum_line(cast(RESERVE3 as date));  --因为timestamp无法索引


CREATE TABLE ICCARD_CONSUME_INFO  /*用于出ICCard消费信息报表*/
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型:
                                               -1=无效充值
                                               0=VIP卡消费
                                               1=VIP卡充值
                                               2=修改IC卡消费金额
                                               3=积分累计记录
                                               4=积分扣除记录 和 积分付款消费(对应TENDERMEDIA的RESERVE3的1)
                                               5=积分换礼品
                                               6=积分折现付款(对应TENDERMEDIA的RESERVE3的21, 22, 23, 24, 25)
                                               7=直接修改总积分  //lzm add 2011-08-02
                                               8=直接修改可用积分  //lzm add 2011-08-02
                                               9=积分折现 //lzm add 2011-08-04
                                               12=挂失后退款
                                               13=挂失后换新卡-新卡
                                               14=消费还款 //lzm add 2013-12-02
                                               15=挂失后换新卡-旧卡
                                               16=实体卡绑定微信会员卡 lzm add 2018-10-12 14:58:29
                                               17=直接扣减金额  //lzm add 2025-5-15 16:24:03
                                               100=消费日结标记

                                               111:澳门通-售卡 lzm add 2013-02-26
                                               112:澳门通-充值 lzm add 2013-02-26
                                               113:澳门通-扣值 lzm add 2013-02-26
                                               114:澳门通-结算 lzm add 2013-02-26
                                               */
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*消费金额("消费")
                                               充值金额("充值")
                                               添加的消费数("修改IC卡消费金额")
                                               添加的积分数("积分累计")
                                               消费的积分数("积分消费")
                                               换礼品的积分数("积分换礼品")
                                               消费金额("积分折现付款")  lzm add 【2011-07-21】
                                               添加的总积分("直接修改总积分") //lzm add 2011-08-02
                                               添加的可用积分("直接修改可用积分") //lzm add 2011-08-02
                                               0("积分折现") //lzm add 2011-08-04
                                               退卡金额("12=挂失后退款"),负数 //lzm add 2012-07-04
                                               换新卡金额("13=挂失后换新卡-新卡"),负数 //lzm add 2012-07-04
                                               消费金额(14=消费还款) //lzm add 2013-12-02
                                               换卡-旧卡金额("15=挂失后换新卡-旧卡"),负数 //lzm add 2012-07-04
                                               */
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*卡内余额("消费")
                                               卡内余额("充值")
                                               卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                               卡内剩余积分("积分累计")
                                               卡内剩余积分("积分消费")
                                               卡内剩余积分("积分换礼品")
                                               卡内积分折现余额("积分折现付款")  lzm add 【2011-07-21】
                                               卡内剩余的总积分("直接修改总积分") //lzm add 2011-08-02
                                               卡内剩余的可用积分("直接修改可用积分") //lzm add 2011-08-02
                                               0("积分折现") //lzm add 2011-08-04
                                               0("12=挂失后退款"),负数 //lzm add 2012-07-04
                                               0("13=挂失后换新卡-新卡") //lzm add 2012-07-04
                                               卡内余额(14=消费还款) //lzm add 2013-12-02
                                               0("15=挂失后换新卡-旧卡") //lzm add 2012-07-04
                                               */
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2   INTEGER DEFAULT 0,        /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单) 0=正常 1=作废单*/
  RESERVE3   TIMESTAMP,                /*保存销售数据的日期*/
  RSTLINEID  INTEGER,                  /*CHECKRST的行号*/
  CARDTYPE  VARCHAR(40),               /*卡的付款类别(11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内剩余积分("积分累计")
                                                   之前卡内剩余积分("积分消费")
                                                   之前卡内剩余积分("积分换礼品")
                                                   之前卡内积分折现余额("积分折现付款")
                                                   之前卡内剩余的总积分("直接修改总积分") //lzm add 2011-08-02
                                                   之前卡内剩余的可用积分("直接修改可用积分") //lzm add 2011-08-02
                                                   0("积分折现") //lzm add 2011-08-04
                                                   0("12=挂失后退款"),负数 //lzm add 2012-07-04
                                                   0("13=挂失后换新卡") //lzm add 2012-07-04
                                                   之前卡内余额(14=消费还款) //lzm add 2013-12-02
                                                   0("15=挂失后换新卡-旧卡") //lzm add 2012-07-04
                                                   */
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分累计")消费金额 lzm add 2012-04-13
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额
                                                  */
  MEDIANAME  VARCHAR(40),                  /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,        /*VIP卡累总积分（包括当次获取的积分）( ICINFO_VIPPOTOTAL = ICINFO_VIPPOTOTALBEF + ICINFO_VIPPOTOTALADD ) lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,         /*当天累计积分(用于积分次日生效的算法) lzm add 【2011-07-21】*/
  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分(ICINFO_VIPPOINTNOW = ICINFO_VIPPOINTBEF - ICINFO_VIPPOINTUSE + ICINFO_VIPPOINTADD) lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);

/* Table: CHECKRST, Owner: SYSDBA */

CREATE TABLE CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,        /*付款方式ID*/
  AMOUNTS       NUMERIC(15, 3), /*未转换前的*/
  AMTCHANGE     NUMERIC(15, 3), /*如是外币,转换后的*/
  RESERVE1      VARCHAR(40),    /*Media Name*/  /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000-->0000"*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效账单 1=无效账单 ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期*/
  RESERVE01     VARCHAR(40),    /*记录收银员名称 lzm modify 2011-9-28 【作废:如果是特殊账单号CHECKID=-1则记录预定台号】*/
  RESERVE02     VARCHAR(250),   /*记录付款方式的按钮参数 lzm modify 2013-12-14 【作废:如果是特殊账单号CHECKID=-1则记录预定人的名字】*/
  RESERVE03     VARCHAR(40),    /*记录付款类别 lzm modify 2019-01-20 16:53:57【作废:如果是特殊账单号CHECKID=-1则记录预定的时间】*/
  RESERVE04     VARCHAR(40),    /*"记帐或还款的用户编号"，如果是云端会员则记录微信会员对应的wecha_id*/
  RESERVE05     VARCHAR(40),    /*付款方式名称,对应TENDERMEDIA内的RESERVE3*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',   /*IC卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型:
                                               -1=无效充值
                                               0=VIP卡消费(IC卡或磁卡)
                                               1=VIP卡充值(IC卡或磁卡)
                                               2=修改IC卡消费金额
                                               3=积分累计记录 //lzm modify 2015-10-15【由于之前是:3=其它付款方式，所以不能根据该记录判断是否为"积分累计"记录】
                                               4=积分扣除记录 和 积分付款消费(对应TENDERMEDIA的RESERVE3的1)  //lzm modify 2015-10-15
                                               5=积分换礼品记录 //lzm modify 2015-10-15
                                               6=VIP卡积分折现付款(磁卡)
                                               7=VIP卡直接修改总积分  //lzm add 2011-08-02
                                               8=VIP卡直接修改可用积分  //lzm add 2011-08-02
                                               9=VIP卡积分折现 //lzm add 2011-08-04
                                               12=VIP卡挂失后退款 lzm add 2012-07-6
                                               13=VIP卡挂失后换新卡-新卡 lzm add 2012-07-6
                                               14=VIP卡消费还款(IC卡或磁卡) //lzm add 2013-12-02
                                               15=VIP卡挂失后换新卡-旧卡 lzm add 2015/5/22 星期五
                                               16=实体卡绑定微信会员卡 lzm add 2018-10-12 14:58:29
                                               17=直接扣减金额  //lzm add 2025-5-15 16:24:03
                                               100=消费日结标记 lzm add 2012-07-12

                                               111:澳门通-售卡 lzm add 2013-02-26
                                               112:澳门通-充值 lzm add 2013-02-26
                                               113:澳门通-扣值 lzm add 2013-02-26
                                               114:澳门通-结算 lzm add 2013-02-26

                                               115=礼品卡消费

                                               999:其它付款方式(IC卡和磁卡积分付款、现金付款等) lzm add 2015-10-19
                                               */
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*IC卡消费或充值的金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*IC卡余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),            /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),         /*VISA卡刷卡时的银行帐单号*/
  LQNUMBER     VARCHAR(40),                  /* 当付款方式
                                                  TENDERMEDIA内的RESERVE3=2  用礼券付款    ：礼券编号。
                                                  TENDERMEDIA内的RESERVE3=37 用微信优惠券  ：卡券号码
                                                  TENDERMEDIA内的RESERVE3=38 微信礼品卡付款：礼品卡号 lzm add 2018-09-13 06:30:13
                                             */
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,        /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),     /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,                /*餐券数量*/
  NUMBER  VARCHAR(40),                       /*当前付款的编号 用于报表的统计*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称或会计记账号*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*充值赠送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,       /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,    /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,          /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/

  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 (ICINFO_VIPPOINTNOW = ICINFO_VIPPOINTBEF - ICINFO_VIPPOINTUSE + ICINFO_VIPPOINTADD) lzm add 【2009-10-19】*/

  ICINFO_CONSUMEBEF  NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD  NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW  NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/

  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*修改为：微信卡包名称_微信卡种名称 lzm modify 2019-01-07 12:31:28，之前是【相关的品种英文名称("积分换礼品")的礼品英文名称】*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 ( ICINFO_VIPPOTOTAL = ICINFO_VIPPOTOTALBEF + ICINFO_VIPPOTOTALADD ) lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,  /*之前的卡累总积分(目前只对磁卡生效) lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,  /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                                                  付款类型:1=会员卡 2=挂房帐 3=公司挂账
                                                  HOTEL_INSTR=
                                                    当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                                                    当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                                                    当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                                                  */
  MEMO1 TEXT,                                     /*备注1
                                                    当付款方式TENDERMEDIA内的RESERVE3:
                                                    113=澳门通-扣值时：记录澳门通返回的信息 lzm add 2013-03-01
                                                    37=用微信优惠券时：记录优惠券code和card_id返回的json
                                                  */
  PAYMENT       INTEGER DEFAULT 0,                /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,            /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型
                                                      讯联
                                                              PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                      翼富
                                                              PURC:下单支付
                                                              VOID:撤销
                                                              INQY:查询
                                                              CLOS:关闭订单
                                                      智能设备
                                                              SIGN:签到
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道
                                                      讯联
                                                              ALP:支付宝支付
                                                              WXP:微信支付
                                                      翼富
                                                              ALP:支付宝支付
                                                              WXP:微信支付
                                                              APP:苹果付
                                                              SXP:三星付
                                                              UNP:银联
                                                              OTP:第三方支付
                                                              WXALP:微信或支付宝自动识别
                                                      智能设备
                                                              BBPOS 香港的智能支付设备                                                      
                                                              KPAY 香港的智能支付设备                                                      
                                                  */
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于扫码支付 【1=线下支付 2=Web支付 3=线下预付 4=聚合码QRFast】 lzm add 2015-07-07
                                                    当CHECKRST_TYPE=0时：支付订单号 
                                                        KPay-Online: webbills:wxordernum ( 商戶全託管業務訂單號 managedOutTradeNo )
                                                    
                                                    当CHECKRST_TYPE=4时：当前 支付订单号 --lzm add 2024-02-28 21:09:07
                                                    当CHECKRST_TYPE=5时：当前 微信会员卡 撤销单号 --lzm add 2024-02-28 21:09:07
                                                    
                                                    当CHECKRST_TYPE=6时: 当前被退款对应的原始支付订单号 --lzm add 2024-02-28 21:09:07
                                                    当CHECKRST_TYPE=7时: 当前退款对应的退款单号 --lzm add 2024-02-28 21:09:07
                                                  */
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于扫码支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态
                                                      -1=用户取消(未支付)
                                                      0=没支付
                                                      1=正在支付
                                                      2=正在支付并等待用户输入密码
                                                      3=支付成功
                                                      4=支付失败
                                                      5=系统错误(支付结果未知，需要查询)
                                                      6=订单已关闭
                                                      7=订单不可退款或撤销
                                                      8=订单不存在(之前没有送到支付网关)
                                                      9=退款成功 用于扫码支付 lzm add 2015-07-07
                                                  */

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,         /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',            /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 KPay:保存orderNo 【用于讯联-支付宝微信支付】 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 
                                                    4=被红冲 lzm add 2016-2-21
                                                    5=红冲   lzm add 2016-2-21
                                                    
                                                    6=被部分退款  --lzm add 2024-02-28 21:09:07
                                                    7=部分退款  --lzm add 2024-02-28 21:09:07
                                                  */
  TRANSACTIONID VARCHAR(100),                     /*TRANSACTIONID 的内容与 微信会员卡 有关  --lzm add 根据之前的代码猜想 2025-08-04 05:37:20
  
                                                    当CHECKRST_TYPE=0时：微信会员卡支付订单号 和 现金等的第三方订单号(用于微信会员卡)  --lzm add 2016-05-25 13:28:37
                                                                        (提示：一般情况微信会员卡支付时SCPAYORDERNO没内容) 
                                                    当CHECKRST_TYPE=4时：当前 微信会员卡 支付订单号
                                                    当CHECKRST_TYPE=5时：当前 微信会员卡 撤销单号
                                                  */
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     7=微信礼品卡 //lzm add 2019-04-14 17:26:26
                                                  */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 2=YPOS调用富友支付 3=BBPOS 4=WXVIP 5=KPAY 6=KPAY-Online lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝微信预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 2=门店后台人工处理 3=云端400后台人工处理 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10
                                                  当CHECKRST_TYPE=4时: 当前被撤销对应的撤销单号 --lzm add 2025-08-04 16:55:32
                                                  当CHECKRST_TYPE=5时: 当前被撤销对应的原始支付订单号 --lzm add 2025-08-04 16:55:32
                                                  
                                                  当CHECKRST_TYPE=6时: 空（因为可以多次退款） --lzm add 2024-02-28 21:09:07
                                                  当CHECKRST_TYPE=7时: 当前退款对应的原始支付订单号 --lzm add 2024-02-28 21:09:07
                                                  */
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 4=退款失败 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP，支付宝官方通道ALP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP，微信官方通道WXP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*微信会员卡 和 第三方订单 支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*微信会员卡 和 第三方订单 支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*微信会员卡 和 第三方订单 退款订单号 lzm add 2020-01-19 14:14:52
                                                    
                                                  当CHECKRST_TYPE=4时: 当前被撤销对应的撤销单号 --lzm add 2025-08-04 16:55:32
                                                  当CHECKRST_TYPE=5时: 当前撤销对应的原始支付订单号 --lzm add 2025-08-04 16:55:32
                                                  */
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*微信会员卡 和 第三方订单 退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*微信会员卡 和 第三方订单 的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  --PRIMARY KEY (PCID, Y, M, D, CHECKID, LINEID)
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, Y, M, D, CHECKID, LINEID)
);

/* Table: CHECKS, Owner: SYSDBA */
/* 提取有效帐单的条件:
  RESERVE2=''' + cNotAddOrSplit + ''''
  CHECKCLOSED=' + IntToStr(cCheckNotClosed)
*/
CREATE TABLE CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/
  REFERENCE     VARCHAR(250),      /*外送单的相关信息
                                   如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"
                                   如果MODEID=盘点单，记录盘点的批号
                                   或
                                   用于总部的数据整理：'S1'=按用餐方式合计整天的营业数据到一张帐单*/
  SEVCHGAMT     NUMERIC(15, 3),    /* 自动的服务费(即品种服务费合计)＝SUBTOTAL*PERCENT */
  SUBTOTAL      NUMERIC(15, 3),    /* 合计＝CHECKDETAIL的AAMOUNTS的和 */
  FTOTAL        NUMERIC(15, 3),    /* 应付金额＝SUBTOTAL-DISCOUNT(CHECK+ITEM)+SERVICECHARGE(自动+附加)+税 */
  STIME TIMESTAMP,                 /*开单时间*/
  ETIME TIMESTAMP,                 /*结帐时间 印整单和收银时 记录该时间*/
  SERVICECHGAPPEND      NUMERIC(15, 3),    /*附加的服务费＝SUBTOTAL*PERCENT (即:单个品种收服务费后 可以再对 品种的合计SUBTOTAL收服务费)*/
  CHECKTOTAL    NUMERIC(15, 3), /*已付款金额*/
  TEXTAPPEND    TEXT,           /*扩展信息1(合单分单的信息和折扣信息等等..)， 当以PRINTTITLE2开头时作为厨房单的抬头变量[16]打印 lzm modify varchar(250)->text 2013-02-27*/
  CHECKCLOSED   INTEGER,        /*帐单是否是已结帐单
                                  0 :没结
                                  1 :已结
                                  2 :暂结单(挂单)【用于"已结单"和"没结单"里面隐藏该账单】
                                  3 :【预留-没实现】预售单(不扣库存)【用于"已结单"和"没结单"里面隐藏该账单】 lzm add 2022-01-07 02:13:13
                                */
  ADJUSTAMOUNT  NUMERIC(15, 3), /*与上单的差额*/
  SPID  INTEGER,                /* 用作记录    服务段:1~48*/
  DISCOUNT      NUMERIC(15, 3), /* 附加的账单折扣=SUBTOTAL*PERCENT (即:单个品种打折后 可以再对 品种的合计SUBTOTAL打折)*/
  INUSE VARCHAR(1) DEFAULT 'F', /*T:正在使用,F:没有使用*/
  LOCKTIME      TIMESTAMP,      /*帐单开始锁定的时间*/
  CASHIERID     INTEGER,        /*收银员编号*/
  ISCARRIEDOVER INTEGER,        /*首次付款方式（记录付款方式的编号，用于“根据付款方式出报表”）*/
  ISADDORSPLIT  INTEGER,        /*lzm 2011-10-18 改为"是否咨客开台 100=咨客开台 其它值=非咨客开台"    之前:不使用*/
  RESERVE1      VARCHAR(40),    /*出单次数*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效单据，1=无效单据【ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)】 
                                        2=作废  --lzm add 2024-02-26 12:01:01
                                      */
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期,如   19990130  ,六位的字符串*/
  RESERVE01     VARCHAR(40),    /*税1合计*/
  RESERVE02     VARCHAR(40),    /*磁卡或IC卡时：记录会员卡对应的'EMPID'  不是IDVALUE
                                  微信会员卡时：为空字符串暂时没用【之前：记录扩展信息 //lzm add 2018-12-13 02:59:13】
                                */
  RESERVE03     VARCHAR(40),    /*折扣【5种VIP卡和第四种打折方式】: "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]"， N表示nil 【状态:全部为0】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE04     VARCHAR(40),    /*折扣【餐后点饮料、原品续杯、非原品续杯】 "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]" N表示nil 【状态: 纪录0或空:不打折，1：餐后点饮料、2：原品续杯、3：非原品续杯】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE05     VARCHAR(40),    /*假帐 1=新的已结单, 由1更新到2=触发数据库触发器进行假帐处理并变为3, 3=处理完毕, 4=ReOpen的单据. (经过DBToFile程序后,由4更新到3,由1更新到2)

                                  对于EXPORT_CHECKS表:1=新的已结单 2=导出到接口库成功 3=生成冲红单到接口成功
                                */
  RESERVE11     VARCHAR(40),    /*jaja 记录预定人使用时Table5相应记录的id值*/
  RESERVE12     VARCHAR(40),    /*先保留没有启用【之前：jaja 记录---挂单 PutUpBillClickEvent()已停用 ---  0或null:不是挂单; 1:挂单】*/
  RESERVE13     VARCHAR(40),    /*实收金额*/
  RESERVE14     VARCHAR(40),    /*EMPNAME开单员工名称*/
  RESERVE15     VARCHAR(40),    /*MODENAME用餐方式名称*/
  RESERVE16     VARCHAR(40),    /*CASHIERNAME收银员名称*/
  RESERVE17     VARCHAR(40),    /*ITEMDISCOUNT品种折扣合计*/
  RESERVE18     VARCHAR(40),    /*上传数据到总部: 
                                  1=新的已结单, 
                                  3=处理完毕, 
                                  4=ReOpen的单据 或 需要全部重传, 
                                  5=账单不完整不需要上传总部 
                                  6=日结时修改了账单日期需要重新上传或作废账单需要重传【旧：0或空=新的已结单没有上传，1=成功【再旧：记录BackUp成功=1】】
                                */
  RESERVE19     VARCHAR(40),    /*上次上传数据到总部的压缩方法【旧：记录MIS成功=1】:
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  10=经过MIME64编码

                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                */
  RESERVE20     VARCHAR(40),    /*帐单类型(20050805)
                                营业报表只统计"普通账单"的记录（即：RESERVE20='' or RESERVE20='0' or RESERVE20 is NULL）

                                0或空=普通帐单
                                1=IC卡充值帐单
                                2=换礼品扣除会员券或积分(在功能 MinusCouponClickEvent 里设置)帐单
                                3=全VOID单
                                4=餐券入店记录-没做
                                5=从钱箱提取现金的帐单
                                6=收银交班帐单
                                7=客户记账后的还款帐单 lzm add 2009-08-14
                                8=【旧：预订单 lzm add 2010-12-17】
                                9=直接修改总积分 //lzm add 2011-08-02
                                10=直接修改可用积分 //lzm add 2011-08-02
                                11=积分折现操作 //lzm add 2011-08-04
                                12=挂失后退款 lzm add 2012-07-9
                                13=挂失后换新卡-新卡 lzm add 2012-07-9
                                14=消费还款 //lzm add 2013-12-02
                                15=挂失后换新卡-旧卡 //lzm add 2015/5/22 星期五
                                16=实体卡绑定微信会员卡  //lzm add 2018-10-12 14:58:29
                                17=直接扣减金额  //lzm add 2025-5-15 16:24:03
                                100=消费日结标记 //lzm add 2012-07-12

                                111:澳门通-售卡 lzm add 2013-02-26
                                112:澳门通-充值 lzm add 2013-02-26
                                113:澳门通-扣值 lzm add 2013-02-26
                                114:澳门通-结算 lzm add 2013-02-26
                                */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),   /*团体消费时的格式为(GROUP:组号),
                                 内容是空时为个人消费,
                                 内容是GUID时为记录消费者编号,*/
  RESERVE21     VARCHAR(40),   /*其它价格(卡种用户编号),用于判断:四维品种 和 1=全部会员 A=A会员 B=B会员 C=C会员 D=D会员 E=E会员 */           /*之前用于记录:老年*/
  RESERVE22     VARCHAR(40),   /*【VIP卡号】*/     /*【之前用于记录:台号(房间)价格*/    /*之前用于记录:中年*/
  RESERVE23     VARCHAR(40),   /*台号(房间)名称  用于PRN_CHECKS 当PRNDOCTYPE=4转台单时:保存转台前的台号名称(如:A14-A)*/     /*之前用于记录:少年*/
  RESERVE24     VARCHAR(40),   /*台号(房间)是否停止计时, 0或空=需要计时, 1=停止计时*/
  RESERVE25     VARCHAR(40),   /*台号(房间)所在的区域 组成: 区域编号A|区域中午名称|区域英文名称*/
  DISCOUNTNAME  TEXT,          /*记录最后一次的"单项"或"全单单项"折扣名称 用于印单*/
  PERIODOFTIME  INTEGER DEFAULT 0,            /*记录是否已进行埋单处理 0或空=没 1=已进行埋单 lzm add [2009-06-18]*/
  STOCKTIME TIMESTAMP,                        /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,                    /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，对应班次表 SHIFTTIMEPERIOD */
  MINPRICE      NUMERIC(15, 3),               /* ***会员当前账单得到的积分【之前是用于记录:"最低消费"】*/
  CHKDISCOUNTLIDU  INTEGER,                   /*账单折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比
                                                用于计算CHECKDISCOUNT*/
  CHKSEVCHGAMTLIDU INTEGER,                   /*自动服务费凹度 1=来自服务费表格(SERCHARGE[好像停用了2025-09-23 03:00:41]),2=OPEN金额,3=OPEN百分比
                                                用于计算SEVCHGAMT*/
  CHKSERVICECHGAPPENDLIDU INTEGER,            /*附加服务费凹度 1=来自服务费表格(SERCHARGE[好像停用了2025-09-23 03:00:45]),2=OPEN金额,3=OPEN百分比
                                                用于计算SERVICECHGAPPEND*/
  CHKDISCOUNTORG   NUMERIC(15, 3),            /*账单折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),            /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录服务费编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),     /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',       /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                  /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                  /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),               /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),               /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                     /*用于记录每次PDA通讯的GUID,判断上次已入单成功
                                                当 "扣减积分"享会员价时: 用于记录相关账单的hqbuillguid  --lzm add 2020-07-23 16:56:27
                                              */
  PCSERIALCODE VARCHAR(100),                  /*机器的注册序列号*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,                        /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/ /*税1合计=RESERVE01*/

  /*以下是用于预订台用的*/
  ORDERTIME     TIMESTAMP,       /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。多个时用分号";"分隔*/
  ORDERTYPE     INTEGER,         /* 报表没有对该域进行筛选
                                    
                                    提示：在预订窗口确认后移到"backup_"开头的表内并通过CHECKGUID与运行库关联(backup_checks的pcid: 1=历史单 0=预订单)
                                    0 :普通预订（用于backup_checks而且pcid=0）
                                    1 :婚宴预订（用于backup_checks而且pcid=0）
                                    2 :寿宴预订（用于backup_checks而且pcid=0）

                                    3 :其他
                                    5 :钱箱提现 lzm add 2018-07-18 14:08:44
                                    6 :美团外卖 lzm add 2018-08-21 23:44:55
                                    7 :蛋糕预订（用于平板蛋糕预订，并上传云端蛋糕工厂） lzm add 2019-01-12 01:42:07
                                    8 :【预留-没实现】预售单（点可预售品种时不扣库存，后通过[6,785]扣库存） lzm add 2022-01-07 02:13:13

                                    10:微信外卖 lzm add 2019-03-05 16:23:58
                                    11:餐台预订 lzm add 2019-03-05 16:24:19
                                    12:微信点餐(线下付款) lzm add 2019-03-05 16:24:19
                                    13:微信点餐(在线付款) lzm add 2019-03-05 16:24:19
                                    14:微信充值(在线付款) lzm add 2019-03-05 16:24:19
                                    15:微信码上付(在线付款) lzm add 2019-03-05 16:24:19
                                    22:自提 lzm add 2023-05-03 00:50:23
                                    23:楼面通月饼订单    --lzm add 2025-08-16 19:19:38
                                    24:YPOS[还没做，先保留]  --lzm add 2025-09-05 19:30:31
                                 */
  ORDERMENNEY   NUMERIC(15, 3),  /*定金,预付款*/
  CHECKGUID     VARCHAR(100),    /* GUID - 用于预订（backup_checks通过CHECKGUID与checks关联）
                                 */
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数，
                                   
                                   -- 会被撞餐用于临时记录循环的次数（次数过大强制退出撞餐算法），撞餐结束时恢复该值 lzm add 2025-06-28 04:49:34
                                   
                                 */

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420 lzm add 2010-04-20*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单折扣负责人姓名,用于在收银单打印"责任人"(用于折扣的授权 "沙面玫瑰园") lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*人手点击全单项目折扣的员工名称(如果不为空代表不需要重新计算折扣) lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单附加折扣的名称说明 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*人手点击全单项目折扣名称，用于判断是否已"清除折扣"、是否"需要计算营销活动"。是否"重新计算营销活动" lzm add 2010-06-18*/

  /*以下2个是用于预订台用的*/
  ORDEREXT1 text,             /*当ordertype=0,1,2时：{"partysize": 1, "TPI": {}} --TPI是第三方接口的英文简写 --lzm add 2023-12-19 20:15:55【之前：预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06】
  
                                当ordertype=6美团外卖时：'{"orderId":"56","deliveryTime":"1469527472"}' lzm add 2018-09-06 04:35:53
                                当ordertype=7蛋糕预订时：'{"cake_name":"劳","cake_phone":"1268899","cake_date":"2018-12-24","cake_time":"03:30","cake_congratulation":"生日快乐","cake_addr":"抠六年级"}'
                              */
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06
                              */

  PT_TOTAL NUMERIC(12, 2),            /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*已送优惠券数量 空或0=没有送 >1=送了多少张优惠券 lzm add 2018-09-26 04:33:01【之前是：来自web的账单数 lzm add 2011-04-11】*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分（目前只对磁卡生效） lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*记录微信会员的明细信息，用逗号分隔  --lzm add 2011-07-20
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        位置3=可用积分
                                        位置4=可用卡内余额 lzm add 2018-07-03 11:19:32
                                        位置5=扣卡内余额才能享受会员优惠 0或=否 1=是 //lzm add 2018-12-13 03:14:43
                                        位置6=卡号(无论是充值卡或礼品卡都记录)  //lzm add 2019-10-20 14:58:40
                                        位置7=卡类型(6=会员卡或7=礼品卡等) //lzm add 2019-10-20 15:13:33
                                        位置8=卡类型名称 //lzm add 2019-10-20 15:13:33
                                        位置9=会员姓名 //lzm add 2019-10-20 15:13:33
                                        位置10=积分兑换金额时，兑换多少金额  //lzm add 2020-07-23 21:50:24
                                        位置11=是否开启积分  //lzm add 2020-07-23 22:38:34
                                        位置12=付款时是否需要动态密码  //lzm add 2021-09-25 15:48:47
                                        位置13=是开启储值  //lzm add 2021-11-07 01:35:09
                                        位置14=是否允许充值  //lzm add 2021-11-07 01:35:09
                                        位置15=是否无论余额多少都能使用积分  //lzm add 2023-06-22 09:24:39
                                        
                                        例如:"100,20,45,68,1,37210021,7" 代表:积分折现=100 当日消费累计积分=20 可用积分=45 可用余额=68 扣卡内余额才能享受会员优惠=是 卡号:37210021 礼品卡
                                        */
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02
                                         当内容为: "weixin_code_needothers" 代表需要获取微信会员卡的明细信息(通过python获取)  --lzm add 2023-09-02 05:52:47
                                       */

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单或酒店会员的 用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间（用于：同步澳门通的LOG时间到CHECKS的LOG时间） lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 商场接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,       /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*先保留没有启用
                                            账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30
                                            日结标记-用于上传数据时：0=没有稽核 1=已稽核 lzm add 2019-10-15 16:03:21
                                       */

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',   /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20
                                           也用于WPOS自助设备DD点单后识别是否同一个账单用于FK付款命令 lzm add 2020-01-21 16:01:39
                                         */

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 或 有微信会员信息的普通付款方式 //lzm add 2016-05-28 10:22:20
                                                     7=微信礼品卡（这个好像没用）
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,               /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额，用于计算 REOPENCONTENT->'balance' lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  --PRIMARY KEY (PCID, Y, M, D, CHECKID)
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, Y, M, D, CHECKID)
);

/* Table: CHKDETAIL, Owner: SYSDBA */
/* 提取有效帐单的条件:
  RESERVE2=''' + cNotAddOrSplit + ''''
  ISVOID=' + IntToStr(cNotVOID)
  RESERVE04<>'5'  //内容分割行(系统保留)  <------------>
*/
/*
  LINEID
  1=最低消费                cLINEID_MINPRICE
  2=最低消费的差价          cLINEID_MINPRICE_BALANCE
  3=房间价格                cLINEID_TABLEPRICE
  4=折让成本（赠送、附加信息、套餐）   cLINEID_AMOUNTCODE
  5=保留
  6=保留
  7=保留
  8=保留
  9=保留
  10=品种"价格","折扣","服务费","税1","税2"的差额 cLINEID_MI_BALANCE
  11=第一个品种由LINEID=11开始

*/
CREATE TABLE CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,    /*cLINEID_MISTARTID=11*/
  MENUITEMID    INTEGER,             /* -1:ICCARD充值;
                                        -2:直接修改总积分;   //lzm add 2011-08-02
                                        -3:直接修改可用积分;   //lzm add 2011-08-02
                                        -4:积分折现操作;  //lzm add 2011-08-05
                                        null:OpenFood;
                                        0:CustomMenuItem;
                                        >0的数字:对应菜式*/
  COUNTS        INTEGER,             /*数量*/
  AMOUNTS       NUMERIC(15, 3),      /*金额=(COUNTS.TIMECOUNTS*单价) */
  STMARKER      INTEGER,             /*是否已送厨房 cNotSendToKitchen=0;cHaveSendToKitchen=1*/
  AMTDISCOUNT   NUMERIC(15, 3),      /*品种折扣*/
  ANAME VARCHAR(100),                   /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"*/
  ISVOID        INTEGER,                /*是否已取消
                                          cNotVOID = 0;
                                          cVOID = 1;
                                          cVOIDObject = 2;
                                          cVOIDObjectNotServiceTotal = 3;
                                        */
  VOIDEMPLOYEE  VARCHAR(40),            /*取消该品种的员工*/
  RESERVE1      VARCHAR(40),            /*厨房提成单价 --lzm modify 2023-09-10 17:43:21【之前:记录MIDETAIL的PREPCOST成本(????好像没使用????)】*/
  RESERVE2      INTEGER DEFAULT 0,      /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单) 0=有效品种 1=无效品种*/
  RESERVE3      TIMESTAMP,              /*保存销售数据的日期*/
  DISCOUNTREASON        VARCHAR(60),    /*折扣名称说明*/
  RESERVE01     VARCHAR(40),   /*税1*/
  RESERVE02     VARCHAR(40),   /*  纪录0或空:普通、
                                   1:餐后点饮料、
                                   2:原品续杯、
                                   3:非原品续杯 、
                                   4:已计算的相撞优惠品种
                                   5:自动大单分账
                                   6:手动大单分账
                               */
  RESERVE03     VARCHAR(40),   /*  父菜式的LineID ,空无父菜式
                                   如果 >0 证明该品种是套餐内容或品种的小费【套餐父亲的RESERVE03也需要>0，否则厨房套餐打印会有问题】

                                        >0 and RESERVE02=4 时代表相撞的品种LineID(***停用 lzm modify 2010-09-18***)
                                        >0 and RESERVE02=5 时代表大单分账的品种LineID(***停用 lzm modify 2010-09-18***)
                               */
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-内容分割行(系统保留) 之前:其它
                                6-小费,
                                7-计时服务项(要配合 MIPRICE_SUM_UNIT 使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Openfood品种
                               11-IC卡充值(系统保留)
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价(****与MIDETAIL不通****)
                               15-房价(****与MIDETAIL不通****)
                               16-VIP卡修改消费金额(系统保留) 2009-4-9
                               17- ***20100615停止使用(用存储过程代替)***(A+B送C中 属于送C的品种 lzm add 【2009-05-05】)
                               18-手写单
                               19-后一品种当做法(拼上做法)
                               20-后一品种合并厨打(拼上品种)
                               21-茶位等
                               22-差价(系统保留)
                               23-直接修改总积分(系统保留)  //lzm add 2011-08-02
                               24-直接修改可用积分(系统保留)  //lzm add 2011-08-02
                               25-积分折现操作(系统保留) //lzm add 2011-08-04
                               26-VIP卡挂失后退款(系统保留) //lzm add 2012-07-06
                               27-VIP卡挂失后换卡-新卡(系统保留) //lzm add 2012-07-06
                               28-分[X]席(系统保留) //lzm add 【2012-11-07】
                               29-计量单位 lzm add 2012-11-17
                               30-VIP卡挂失后换卡-旧卡(系统保留) //lzm add 2015/5/22 星期五
                               31-实体卡绑定微信会员卡 lzm add 2018-10-12 14:58:29
                               32-折让成本（赠送、附加信息、套餐）
                               33-与前一品种合并厨打  --lzm add 2024-3-27 03:35:51
                               34-直接扣减金额(系统保留)  //lzm add 2025-5-15 16:24:03
                               100-消费日结标记(系统保留) lzm add 2012-07-12

                               111:澳门通-售卡 lzm add 2013-02-26
                               112:澳门通-充值 lzm add 2013-02-26
                               113:澳门通-扣值 lzm add 2013-02-26
                               114:澳门通-结算 lzm add 2013-02-26
                               */
  RESERVE05     VARCHAR(40),   /*  OpenFood的逻辑打印机的名称*/
  RESERVE11     VARCHAR(250),   /*  4维菜式参数 1维 */
  RESERVE12     VARCHAR(250),   /*  4维菜式参数 2维 */
  RESERVE13     VARCHAR(250),   /*  4维菜式参数 3维 */
  RESERVE14     VARCHAR(250),   /*  4维菜式参数 4维 */
  RESERVE15     VARCHAR(40),   /* lzm modify 2012-3-28 是否人手修改价格 0或空=否 1=是【之前用于:折扣ID】  */
  RESERVE16     VARCHAR(40),   /*用于"入单"时的"印单",                         */
                               /*  入单时暂时设置RESERVE16=cNotSendTag,                */
                               /*  印单时查找RESERVE16=cNotSendTag的记录打印,  */
                               /*  入单后设置RESERVE16=NULL                        */
  RESERVE17     VARCHAR(250),  /* 品种的原始名词(改于:2008-1-10),用于出报表
                                【之前用于：RESERVE17是否已经计算入sumery的标志,记录Reopen已void的标记
                                  1:已将void的菜式update入sales_sumery
                                 】
                              */
  RESERVE18     VARCHAR(40),  /*记录 K */
  RESERVE19     VARCHAR(40),  /*记录入单的时间如  15:25
                                没入单前作为临时标记使用0，1
                              */
  RESERVE20     VARCHAR(40),  /* 对于prn_chkdetail时，在打印服务器被用于判断总单是否需要删除相同名称的记录(0=普通品种 1=拼上的品种 2=多份打印的品种) lzm modify 2010-10-13

                                (停用20020815)记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为1[ID],ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)
                                (停用20020702)记录该菜式是打印到哪里:WATERBAR;KICHEN1;KICHEN2,NOTPRINT等等
                              */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,         /* [提酒] 记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为ID,ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)  herman 20020812*/
  RESERVE21     VARCHAR(40),     /*        记录会员卡卡号,与RESERVE20相关  herman 20020812*/
  RESERVE22     VARCHAR(10),     /* [提酒] 卡号购买时间  herman 20020812*/
  RESERVE23     VARCHAR(40),     /* 1.记录该菜式送给谁的,如:玫瑰花送给哪位小姐*/
                                 /* 2.如果AFEMPID不为空或0, 则记录该技师的服务类别:1="点钟",2="普通钟",3="CALL钟"*/
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  RESERVE24     VARCHAR(240),         /*记录点菜人的名字*/
  RESERVE25     VARCHAR(40),          /*用于"叫起" [空值=按原来的方式打印; 0=叫起(未入单前); 1=起叫(入单后);  起叫后,Clear该值]*/
  RESERVE11_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 1维名称(本地语言) */
  RESERVE12_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 2维名称(本地语言) */
  RESERVE13_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 3维名称(本地语言) */
  RESERVE14_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 4维名称(本地语言) */
  SPID  INTEGER,                             /*品种时段参数,所属时间段编号(SERVICEPERIOD), 1~48个时间段(老的时段报表需要该数据)*/
  TPID  INTEGER,                             /*四维时段参数*/
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,    /*附加信息的金额 负数=增加 正数=减*/
  ADDININFO    VARCHAR(40) DEFAULT '',       /*附加信息的信息*/
  BARCODE VARCHAR(40),                       /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑拿开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑拿结束计时时间*/
  AFEMPID INTEGER,                           /*桑拿技师ID; 0或空=没有技师。*/
  TEMPENDTIME TIMESTAMP,                     /*1.桑拿预约结束计时时间
                                               2.当是可预售品种(即ODOOCODE的 {"presales": 1} 时) 代表扣库存时间 lzm add 2022-01-12 23:56:01
                                             */
  ATABLESUBID INTEGER DEFAULT 1,             /*桑拿点该品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',      /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑拿技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                      /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成
                                               如果有多个编号则用分号";"分隔,代表该品种的提成由相应的员工平分
                                             */
  HANDCARDNUM  VARCHAR(40),                  /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                  /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,           /*折扣凹度*/
                                             /*1=来源折扣表格(DISCOUNT)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  SERCHARGELIDU INTEGER,           /*服务费凹度*/
                                             /*0或空 需要根据checks的CHKSEVCHGAMTLIDU和CHKSEVCHGAMTORG重新计算*/
                                             /*1=来源服务费表格(SERCHARGE)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  DISCOUNTORG   NUMERIC(15, 3),    /*折扣来源*/
                                             /*当DISCOUNTLIDU=1时:记录折扣编号*/
                                             /*当DISCOUNTLIDU=2时:记录金额*/
                                             /*当DISCOUNTLIDU=3时:记录百分比*/
  SERCHARGEORG  NUMERIC(15, 3),    /*服务费来源*/
                                             /*当SERCHARGELIDU=1时:记录折扣编号*/
                                             /*当SERCHARGELIDU=2时:记录金额*/
                                             /*当SERCHARGELIDU=3时:记录百分比*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                /*记录套餐父品种名称 用于打印和出报表*/
  TCMINAME_LANGUAGE      VARCHAR(100),       /*记录套餐父品种英文名称 用于打印*/
  AMOUNTSORG    NUMERIC(15,3),               /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算（套餐的折让成本不通过AMOUNTSORG进行计算）*/
  TIMECOUNTS    NUMERIC(15,4),  /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),  /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送、损耗或招待金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /* 计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /* 用于照片时:单位价格对于的面积 或 首次输入的数量(用于席数计算)*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /* 用于照片时:总面积 或 首次输入的计量单位2数量(用于席数计算 --lzm add 2024-01-08 15:47:30)*/
  FAMILGID      INTEGER,          /*辅助分类2 系统规定:-10=台号 -11=折让成本(赠送、附加信息、套餐)*/
  MAJORGID      INTEGER,          /*辅助分类1*/
  DEPARTMENTID  INTEGER,          /*所属部门编号 系统规定:-10=台号(房价部门) -11=折让成本(赠送、附加信息、套餐)*/
  AMOUNTORGPER  NUMERIC(15, 3),   /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本=chkdetail.cost+chkdetail_ext.cost+chkdetail_ext.micost*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码(ERP) 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*计量单位2数量(用于记录海鲜的条数等) lzm add 2009-08-14*/

  KOUTTIME      TIMESTAMP,        /*厨房地喱出单(划单)时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房出单(划单)的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*1.厨房出单(划单)的员工名称 lzm add 2010-01-13
                                    2.当：自助餐厅时用于记录智盘的序列号UID，并以"RFID:"开头 lzm add 2022-04-20 08:42:11
                                  */
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),     /*点单的终端名称，格式：YPOS-终端号-命令uuid lzm add 2010-01-13*/
  KOUTCODE      serial,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 2=通过分单转台*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称(***撞餐优惠折扣没有做***) lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),                /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*1.用于记录分账的父品种LINEID lzm add 2010-09-19
                                              或
                                              2.当ISVOID=1时记录原始品种的 KOUTCODE ，用于厨房绩效统计 --lzm add 2023-09-08 04:42:24
                                            */
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04( 20=拼上品种 )lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*1.技师编号(不是EMPID) lzm add 2011-05-20
                                              或
                                              2.RFID的标签id(当AFPNAME='RFID'时，这里记录标签的ID) lzm add 2022-05-18 02:00:15
                                            */
  AFPNAME       VARCHAR(40),                /*1.技师名称 lzm add 2011-05-20
                                              或
                                              2.记录RFID lzm add 2022-05-18 02:00:15
                                            */
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是。--通过SetAfterMenuitemIsAddEvent触发是否为加菜
                                              但是当ITEMISADD=10000代表正在结束营业日停止(用于扣库存的触发器) lzm add 2012-04-16
                                            */
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,          /*厨房划单时间(用于厨房划2次单) 用于按下单数量显示 lzm add 2014-8-22*/
  KOUTTIMES     TEXT,               /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,               /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,       /*厨房划单数量(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,         /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前primarykey主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,1.5,斤,1,条,总仓;10203,凉瓜,2.3,两,,,总仓 在stock_chkdetail_before_update_tri()使用 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 空或0=没同步 1=已同步 -200=上传有重复无需再上传 2=人工设置为已处理 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              /*扩展的统计信息  --lzm add 2019-06-19 01:44:37
                                { 
                                  "stocknum_dec": [已扣库存量],        --已扣库存量，用于蛋糕的付款后扣库存
                                  "sgdiscount": {                      --营销活动相关
                                    "vip_use_score": [该品种优惠需要扣积分 0或空=否 1=是],  
                                  },
                                  "amount_balance": {                 --折让统计相关
                                    "need_calc_tc": [当前品种是否要统计套餐折让成本 0=否 1=是]  --记录midetail表XGDJ域的need_amount_balance值 --lzm add 2022-08-14 14:11:15
                                  },
                                  "wconfirm": {
                                    "is_wconfirm": [是否已重量确认 0=否 1=是]  --lzm add 2024-04-22 05:26:54
                                  },
                                  "webbills_line_uuid": "12345_1"  --扫码点餐的行唯一号  --lzm add 2024-06-14 01:46:50
                                }
                                /*

  --PRIMARY KEY (PCID, Y, M, D, CHECKID, LINEID)
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, Y, M, D, CHECKID, LINEID)
);
alter table chkdetail alter column odoocode type varchar(240);
alter table sum_chkdetail alter column odoocode type varchar(240);
alter table BACKUP_CHKDETAIL alter column odoocode type varchar(240);
alter table whole_chkdetail alter column odoocode type varchar(240);
alter table YEAR_WHOLE_CHKDETAIL alter column odoocode type varchar(240);
alter table EXPORT_CHKDETAIL alter column odoocode type varchar(240);
alter table ANALYZE_CHKDETAIL alter column odoocode type varchar(240);
alter table PRN_CHKDETAIL alter column odoocode type varchar(240);


CREATE TABLE CHKDETAIL_EXT  /*点菜的附加信息表*/
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,              /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS*单价 */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /* ***停用，因为通过查询CHKDETAIL可以知道ISVOID的状态
                                       是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,            /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类-与CHKDETAIL的RESERVE04相同
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价
                               15-房价
                               16-VIP卡修改消费金额(系统保留) 2009-4-9
                               17- ***20100615停止使用(用存储过程代替)***(A+B送C中 属于送C的品种 lzm add 【2009-05-05】)
                               18-手写单
                               19-拼上附加信息
                               20=拼上品种
                               21-茶位等
                               22=差价(系统保留)
                               23-直接修改总积分(系统保留)  //lzm add 2011-08-02
                               24-直接修改可用积分(系统保留)  //lzm add 2011-08-02
                               25-积分折现操作(系统保留) //lzm add 2011-08-04
                               26-VIP卡挂失后退款(系统保留) //lzm add 2012-07-06
                               27-VIP卡挂失后换卡(系统保留) //lzm add 2012-07-06
                               28=分[X]席(系统保留) //lzm add 【2012-11-07】
                               */
  COST  NUMERIC(15, 3),          /*附加信息自己的原材料成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /* ***停用 记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0=直接扣减 或1=百分比扣减, 2=补差价 3=乘上指定数值*/
  AMOUNTSTYP    VARCHAR(10),       /*与AMOUNTSLDU匹配的数值*/
  ADDEMPID INTEGER DEFAULT -1,     /*添加附加信息的员工编号,如果授权则记录授权人的编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称,如果授权则记录授权人的名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比
                                     百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比
                                     百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比
                                     百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),    /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四
                                     ..
                                     9=做法9
                                     10=介绍人提成(由ANAME记录介绍人名称) //lzm add 【2009-06-08】
                                     11=服务员提成(由ANAME记录服务员名称) //lzm add 【2009-06-10】
                                     12=吧女提成(由ANAME记录吧女名称) //lzm add 【2009-06-10】
                                     --取消 13=记录已计算的数量(用于满量优惠计算) --lzm add 2018-11-05 03:32:00
                                   */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 2=修改价格的补差价(放在终极计算) lzm add 2011-08-11*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  --PRIMARY KEY (PCID, Y, M, D, CHECKID, LINEID)
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,   /*店编号*/
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,                   /*操作LINEID*/
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 1=折扣处理(没做)(用于报表的统计lzm add 2010-06-14)
                                 2=修改价格(没做)
                                 3=修改数量(没做)
                                 4=打印报表(没做)
                                 5= ***20100615停止使用(用存储过程代替)***(A+B送C的操作)
                                 100=酒楼附加收费项目(只需要打印,不需要计算入营业额) lzm add 2012-08-30
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量或金额或折扣*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量或金额或折扣*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  --PRIMARY KEY (PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, Y, M, D, CHECKID, CHKLINEID, OPID)
);

/* Table: SALES_SUMERY, Owner: SYSDBA */

CREATE TABLE SALES_SUMERY
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP1_COUNT     INTEGER DEFAULT 0,
  TP1_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP1_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP1_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP2_COUNT     INTEGER DEFAULT 0,
  TP2_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP2_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP2_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP3_COUNT     INTEGER DEFAULT 0,
  TP3_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP3_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP3_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP4_COUNT     INTEGER DEFAULT 0,
  TP4_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP4_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP4_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP5_COUNT     INTEGER DEFAULT 0,
  TP5_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP5_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP5_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP6_COUNT     INTEGER DEFAULT 0,
  TP6_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP6_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP6_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP7_COUNT     INTEGER DEFAULT 0,
  TP7_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP7_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP7_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP8_COUNT     INTEGER DEFAULT 0,
  TP8_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP8_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP8_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP9_COUNT     INTEGER DEFAULT 0,
  TP9_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP9_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP9_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP10_COUNT    INTEGER DEFAULT 0,
  TP10_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP10_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP10_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP11_COUNT    INTEGER DEFAULT 0,
  TP11_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP11_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP11_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP12_COUNT    INTEGER DEFAULT 0,
  TP12_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP12_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP12_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP13_COUNT    INTEGER DEFAULT 0,
  TP13_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP13_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP13_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP14_COUNT    INTEGER DEFAULT 0,
  TP14_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP14_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP14_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP15_COUNT    INTEGER DEFAULT 0,
  TP15_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP15_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP15_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP16_COUNT    INTEGER DEFAULT 0,
  TP16_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP16_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP16_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP17_COUNT    INTEGER DEFAULT 0,
  TP17_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP17_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP17_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP18_COUNT    INTEGER DEFAULT 0,
  TP18_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP18_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP18_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP19_COUNT    INTEGER DEFAULT 0,
  TP19_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP19_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP19_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP20_COUNT    INTEGER DEFAULT 0,
  TP20_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP20_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP20_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP21_COUNT    INTEGER DEFAULT 0,
  TP21_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP21_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP21_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP22_COUNT    INTEGER DEFAULT 0,
  TP22_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP22_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP22_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP23_COUNT    INTEGER DEFAULT 0,
  TP23_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP23_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP23_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP24_COUNT    INTEGER DEFAULT 0,
  TP24_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP24_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP24_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP25_COUNT    INTEGER DEFAULT 0,
  TP25_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP25_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP25_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP26_COUNT    INTEGER DEFAULT 0,
  TP26_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP26_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP26_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP27_COUNT    INTEGER DEFAULT 0,
  TP27_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP27_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP27_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP28_COUNT    INTEGER DEFAULT 0,
  TP28_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP28_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP28_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/* Table: SALES_SUMERY_OTHER, Owner: SYSDBA */

CREATE TABLE SALES_SUMERY_OTHER
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP29_COUNT    INTEGER DEFAULT 0,
  TP29_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP29_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP29_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP30_COUNT    INTEGER DEFAULT 0,
  TP30_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP30_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP30_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP31_COUNT    INTEGER DEFAULT 0,
  TP31_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP31_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP31_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP32_COUNT    INTEGER DEFAULT 0,
  TP32_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP32_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP32_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP33_COUNT    INTEGER DEFAULT 0,
  TP33_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP33_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP33_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP34_COUNT    INTEGER DEFAULT 0,
  TP34_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP34_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP34_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP35_COUNT    INTEGER DEFAULT 0,
  TP35_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP35_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP35_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP36_COUNT    INTEGER DEFAULT 0,
  TP36_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP36_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP36_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP37_COUNT    INTEGER DEFAULT 0,
  TP37_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP37_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP37_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP38_COUNT    INTEGER DEFAULT 0,
  TP38_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP38_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP38_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP39_COUNT    INTEGER DEFAULT 0,
  TP39_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP39_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP39_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP40_COUNT    INTEGER DEFAULT 0,
  TP40_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP40_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP40_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP41_COUNT    INTEGER DEFAULT 0,
  TP41_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP41_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP41_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP42_COUNT    INTEGER DEFAULT 0,
  TP42_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP42_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP42_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP43_COUNT    INTEGER DEFAULT 0,
  TP43_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP43_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP43_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP44_COUNT    INTEGER DEFAULT 0,
  TP44_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP44_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP44_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP45_COUNT    INTEGER DEFAULT 0,
  TP45_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP45_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP45_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP46_COUNT    INTEGER DEFAULT 0,
  TP46_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP46_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP46_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP47_COUNT    INTEGER DEFAULT 0,
  TP47_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP47_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP47_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP48_COUNT    INTEGER DEFAULT 0,
  TP48_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP48_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP48_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);


/*用于出ICCard消费信息报表*/
CREATE TABLE SUM_ICCARD_CONSUME_INFO
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2  INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3  TIMESTAMP,    /*保存销售数据的日期*/
  CARDTYPE  VARCHAR(40),                /*卡的付款类别(10,11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前的余额*/
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                          /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),                   /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),          /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),                /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/
  MEDIANAME  VARCHAR(40),                         /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0, /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);

/* Table: SUM_CHECKRST, Owner: SYSDBA */

CREATE TABLE SUM_CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  AMTCHANGE     NUMERIC(15, 3),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',        /*卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),   /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),    /*VISA卡刷卡时的银行帐单号*/
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,  /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),  /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,  /*餐券数量*/
  NUMBER  VARCHAR(40),   /*编号*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,      /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,   /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,         /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                    //付款类型:1=会员卡 2=挂房帐 3=公司挂账
                    //HOTEL_INSTR=
                    //  当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                    //  当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                    //  当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                    */
  MEMO1 TEXT,                                     /*备注1(澳门通-扣值时,记录澳门通返回的信息) lzm add 2013-03-01*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,                /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型  PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道 用于讯联-支付宝微信支付 ALP:支付宝支付  WXP:微信支付*/
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 用于讯联-支付宝微信支付 lzm add 2015-07-07*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 用于讯联-支付宝微信支付 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 lzm add 2016-05-25 13:28:37*/
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10*/
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*第三方订单支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*第三方订单支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*第三方订单退款订单号 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*第三方订单退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*第三方订单的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  /*INSERTTIME  TIMESTAMP,*/
 PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/* Table: SUM_CHECKS, Owner: SYSDBA */

CREATE TABLE SUM_CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,
  REFERENCE     VARCHAR(250),
  SEVCHGAMT     NUMERIC(15, 3),
  SUBTOTAL      NUMERIC(15, 3),
  FTOTAL        NUMERIC(15, 3),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  SERVICECHGAPPEND      NUMERIC(15, 3),
  CHECKTOTAL    NUMERIC(15, 3),
  TEXTAPPEND    TEXT,
  CHECKCLOSED   INTEGER,
  ADJUSTAMOUNT  NUMERIC(15, 3),
  SPID  INTEGER,
  DISCOUNT      NUMERIC(15, 3),
  INUSE VARCHAR(1) DEFAULT 'F',
  LOCKTIME      TIMESTAMP,
  CASHIERID     INTEGER,
  ISCARRIEDOVER INTEGER,
  ISADDORSPLIT  INTEGER,
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(40),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(40),
  RESERVE23     VARCHAR(40),
  RESERVE24     VARCHAR(40),
  RESERVE25     VARCHAR(40),
  DISCOUNTNAME  TEXT,
  PERIODOFTIME  INTEGER DEFAULT 0,
  STOCKTIME TIMESTAMP,      /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,                    /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，1=早班，2=中班，3=晚班*/
  MINPRICE      NUMERIC(15, 3),               /*最低消费*/
  CHKDISCOUNTLIDU  INTEGER,                  /*折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比*/
  CHKSEVCHGAMTLIDU INTEGER,                  /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKSERVICECHGAPPENDLIDU INTEGER,           /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKDISCOUNTORG   NUMERIC(15, 3),           /*折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),           /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),    /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',      /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                 /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                 /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),              /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),              /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                    /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                 /*机器的序列号*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,                       /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),         /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,       /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  /*INSERTTIME  TIMESTAMP,*/
 PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID)
);

/* Table: SUM_CHKDETAIL, Owner: SYSDBA */

CREATE TABLE SUM_CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,
  COUNTS        INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  STMARKER      INTEGER,
  AMTDISCOUNT   NUMERIC(15, 3),
  ANAME VARCHAR(100),
  ISVOID        INTEGER,
  VOIDEMPLOYEE  VARCHAR(40),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  DISCOUNTREASON        VARCHAR(60),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(250),
  RESERVE12     VARCHAR(250),
  RESERVE13     VARCHAR(250),
  RESERVE14     VARCHAR(250),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(250),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(10),
  RESERVE23     VARCHAR(40),
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),
  KICKBACK      NUMERIC(15, 3),
  RESERVE24     VARCHAR(240),
  RESERVE25     VARCHAR(40),
  RESERVE11_LANGUAGE    VARCHAR(250),
  RESERVE12_LANGUAGE    VARCHAR(250),
  RESERVE13_LANGUAGE    VARCHAR(250),
  RESERVE14_LANGUAGE    VARCHAR(250),
  SPID  INTEGER,
  TPID  INTEGER,
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,
  ADDININFO    VARCHAR(40) DEFAULT '',
  BARCODE VARCHAR(40),                          /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑那开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑那结束计时时间*/
  AFEMPID INTEGER,                          /*技师ID*/
  TEMPENDTIME TIMESTAMP,                    /*预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*点该品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',         /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                 /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑那技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                         /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成*/
  HANDCARDNUM  VARCHAR(40),                     /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                     /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,                     /*折扣凹度*/
  SERCHARGELIDU INTEGER,                     /*服务费凹度*/
  DISCOUNTORG   NUMERIC(15, 3),              /*折扣来源*/
  SERCHARGEORG  NUMERIC(15, 3),              /*服务费来源*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                   /*记录套餐父品种编号*/
  TCMINAME_LANGUAGE      VARCHAR(100),          /*记录套餐父品种编号*/
  AMOUNTSORG    NUMERIC(15,3),                /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格*/
  TIMECOUNTS    NUMERIC(15,4),               /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),               /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,
  MAJORGID      INTEGER,
  DEPARTMENTID  INTEGER,          /*所属部门编号*/
  AMOUNTORGPER  NUMERIC(15,3),    /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),    /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,             /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER NOT NULL DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  /*INSERTTIME  TIMESTAMP,*/
 PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/*点菜的附加信息表*/
CREATE TABLE SUM_CHKDETAIL_EXT
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,          /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS* */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /*是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,          /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,          /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               */
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0或1=扣减, 2=补差价*/
  AMOUNTSTYP    VARCHAR(10),       /*百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  ADDEMPID INTEGER DEFAULT -1,   /*添加附加信息的员工编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位成本价格
                                        =百分比 时:记录成本跟父品种价格的每单位百分比*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位提成价格
                                        =百分比 时:记录提成跟父品种价格的每单位百分比*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),    /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四

                                     10=介绍人提成 //lzm add 【2009-06-08】
                                     11=服务员提成 //lzm add 【2009-06-10】
                                     12=吧女提成 //lzm add 【2009-06-10】
                                     */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  USER_ID INTEGER NOT NULL DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE SUM_CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 请查阅CHECKOPLOG
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量金额*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量金额*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
);

/* Table: SUM_SALES_SUMERY, Owner: SYSDBA */

CREATE TABLE SUM_SALES_SUMERY
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP1_COUNT     INTEGER DEFAULT 0,
  TP1_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP1_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP1_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP2_COUNT     INTEGER DEFAULT 0,
  TP2_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP2_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP2_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP3_COUNT     INTEGER DEFAULT 0,
  TP3_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP3_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP3_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP4_COUNT     INTEGER DEFAULT 0,
  TP4_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP4_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP4_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP5_COUNT     INTEGER DEFAULT 0,
  TP5_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP5_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP5_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP6_COUNT     INTEGER DEFAULT 0,
  TP6_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP6_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP6_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP7_COUNT     INTEGER DEFAULT 0,
  TP7_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP7_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP7_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP8_COUNT     INTEGER DEFAULT 0,
  TP8_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP8_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP8_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP9_COUNT     INTEGER DEFAULT 0,
  TP9_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP9_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP9_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP10_COUNT    INTEGER DEFAULT 0,
  TP10_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP10_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP10_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP11_COUNT    INTEGER DEFAULT 0,
  TP11_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP11_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP11_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP12_COUNT    INTEGER DEFAULT 0,
  TP12_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP12_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP12_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP13_COUNT    INTEGER DEFAULT 0,
  TP13_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP13_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP13_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP14_COUNT    INTEGER DEFAULT 0,
  TP14_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP14_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP14_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP15_COUNT    INTEGER DEFAULT 0,
  TP15_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP15_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP15_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP16_COUNT    INTEGER DEFAULT 0,
  TP16_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP16_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP16_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP17_COUNT    INTEGER DEFAULT 0,
  TP17_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP17_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP17_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP18_COUNT    INTEGER DEFAULT 0,
  TP18_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP18_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP18_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP19_COUNT    INTEGER DEFAULT 0,
  TP19_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP19_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP19_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP20_COUNT    INTEGER DEFAULT 0,
  TP20_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP20_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP20_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP21_COUNT    INTEGER DEFAULT 0,
  TP21_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP21_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP21_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP22_COUNT    INTEGER DEFAULT 0,
  TP22_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP22_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP22_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP23_COUNT    INTEGER DEFAULT 0,
  TP23_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP23_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP23_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP24_COUNT    INTEGER DEFAULT 0,
  TP24_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP24_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP24_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP25_COUNT    INTEGER DEFAULT 0,
  TP25_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP25_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP25_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP26_COUNT    INTEGER DEFAULT 0,
  TP26_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP26_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP26_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP27_COUNT    INTEGER DEFAULT 0,
  TP27_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP27_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP27_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP28_COUNT    INTEGER DEFAULT 0,
  TP28_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP28_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP28_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) NOT NULL,
  /*INSERTTIME  TIMESTAMP,*/
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/* Table: SUM_SALES_SUMERY_OTHER, Owner: SYSDBA */

CREATE TABLE SUM_SALES_SUMERY_OTHER
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP29_COUNT    INTEGER DEFAULT 0,
  TP29_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP29_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP29_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP30_COUNT    INTEGER DEFAULT 0,
  TP30_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP30_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP30_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP31_COUNT    INTEGER DEFAULT 0,
  TP31_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP31_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP31_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP32_COUNT    INTEGER DEFAULT 0,
  TP32_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP32_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP32_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP33_COUNT    INTEGER DEFAULT 0,
  TP33_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP33_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP33_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP34_COUNT    INTEGER DEFAULT 0,
  TP34_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP34_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP34_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP35_COUNT    INTEGER DEFAULT 0,
  TP35_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP35_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP35_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP36_COUNT    INTEGER DEFAULT 0,
  TP36_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP36_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP36_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP37_COUNT    INTEGER DEFAULT 0,
  TP37_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP37_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP37_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP38_COUNT    INTEGER DEFAULT 0,
  TP38_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP38_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP38_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP39_COUNT    INTEGER DEFAULT 0,
  TP39_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP39_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP39_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP40_COUNT    INTEGER DEFAULT 0,
  TP40_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP40_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP40_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP41_COUNT    INTEGER DEFAULT 0,
  TP41_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP41_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP41_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP42_COUNT    INTEGER DEFAULT 0,
  TP42_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP42_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP42_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP43_COUNT    INTEGER DEFAULT 0,
  TP43_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP43_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP43_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP44_COUNT    INTEGER DEFAULT 0,
  TP44_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP44_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP44_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP45_COUNT    INTEGER DEFAULT 0,
  TP45_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP45_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP45_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP46_COUNT    INTEGER DEFAULT 0,
  TP46_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP46_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP46_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP47_COUNT    INTEGER DEFAULT 0,
  TP47_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP47_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP47_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP48_COUNT    INTEGER DEFAULT 0,
  TP48_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP48_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP48_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) NOT NULL,
  /*INSERTTIME  TIMESTAMP,*/
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/*用于出ICCard消费信息报表*/
CREATE TABLE BACKUP_ICCARD_CONSUME_INFO
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2  INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3  TIMESTAMP,    /*保存销售数据的日期*/
  CARDTYPE  VARCHAR(40),                /*卡的付款类别(10,11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前的余额*/
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                          /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),                   /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),          /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),                /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/
  MEDIANAME  VARCHAR(40),                         /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0, /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);

/* Table: BACKUP_CHECKRST, Owner: SYSDBA */

CREATE TABLE BACKUP_CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  AMTCHANGE     NUMERIC(15, 3),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',        /*卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),   /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),    /*VISA卡刷卡时的银行帐单号*/
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,  /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),  /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,  /*餐券数量*/
  NUMBER  VARCHAR(40),   /*编号*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,      /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,   /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,         /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                    //付款类型:1=会员卡 2=挂房帐 3=公司挂账
                    //HOTEL_INSTR=
                    //  当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                    //  当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                    //  当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                    */
  MEMO1 TEXT,                                     /*备注1(澳门通-扣值时,记录澳门通返回的信息) lzm add 2013-03-01*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,                /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型  PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道 用于讯联-支付宝微信支付 ALP:支付宝支付  WXP:微信支付*/
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 用于讯联-支付宝微信支付 lzm add 2015-07-07*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 用于讯联-支付宝微信支付 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 lzm add 2016-05-25 13:28:37*/
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10*/
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*第三方订单支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*第三方订单支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*第三方订单退款订单号 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*第三方订单退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*第三方订单的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/* Table: BACKUP_CHECKS, Owner: SYSDBA */

CREATE TABLE BACKUP_CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,
  REFERENCE     VARCHAR(250),
  SEVCHGAMT     NUMERIC(15, 3),
  SUBTOTAL      NUMERIC(15, 3),
  FTOTAL        NUMERIC(15, 3),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  SERVICECHGAPPEND      NUMERIC(15, 3),
  CHECKTOTAL    NUMERIC(15, 3),
  TEXTAPPEND    TEXT,
  CHECKCLOSED   INTEGER,
  ADJUSTAMOUNT  NUMERIC(15, 3),
  SPID  INTEGER,
  DISCOUNT      NUMERIC(15, 3),
  INUSE VARCHAR(1) DEFAULT 'F',
  LOCKTIME      TIMESTAMP,
  CASHIERID     INTEGER,
  ISCARRIEDOVER INTEGER,
  ISADDORSPLIT  INTEGER,
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(40),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(40),
  RESERVE23     VARCHAR(40),
  RESERVE24     VARCHAR(40),
  RESERVE25     VARCHAR(40),
  DISCOUNTNAME  TEXT,
  PERIODOFTIME  INTEGER DEFAULT 0,
  STOCKTIME TIMESTAMP,      /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,  /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，1=早班，2=中班，3=晚班*/
  MINPRICE      NUMERIC(15, 3),               /*最低消费*/
  CHKDISCOUNTLIDU  INTEGER,                  /*折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比*/
  CHKSEVCHGAMTLIDU INTEGER,                  /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKSERVICECHGAPPENDLIDU INTEGER,           /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKDISCOUNTORG   NUMERIC(15, 3),           /*折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),           /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),    /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',      /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                 /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                 /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),              /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),              /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                    /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                 /*机器的序列号*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,                       /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,     /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID)
);

/* Table: BACKUP_CHKDETAIL, Owner: SYSDBA */

CREATE TABLE BACKUP_CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,
  COUNTS        INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  STMARKER      INTEGER,
  AMTDISCOUNT   NUMERIC(15, 3),
  ANAME VARCHAR(100),
  ISVOID        INTEGER,
  VOIDEMPLOYEE  VARCHAR(40),
  RESERVE1      VARCHAR(40),
  RESERVE2      VARCHAR(40),
  RESERVE3      TIMESTAMP,
  DISCOUNTREASON        VARCHAR(60),
  RESERVE01     VARCHAR(40),
  RESERVE02     INTEGER DEFAULT 0,
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(250),
  RESERVE12     VARCHAR(250),
  RESERVE13     VARCHAR(250),
  RESERVE14     VARCHAR(250),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(250),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(10),
  RESERVE23     VARCHAR(40),
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),
  KICKBACK      NUMERIC(15, 3),
  RESERVE24     VARCHAR(240),
  RESERVE25     VARCHAR(40),
  RESERVE11_LANGUAGE    VARCHAR(250),
  RESERVE12_LANGUAGE    VARCHAR(250),
  RESERVE13_LANGUAGE    VARCHAR(250),
  RESERVE14_LANGUAGE    VARCHAR(250),
  SPID  INTEGER,
  TPID  INTEGER,
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,
  ADDININFO    VARCHAR(40) DEFAULT '',
  BARCODE VARCHAR(40),                          /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑那开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑那结束计时时间*/
  AFEMPID INTEGER,                          /*技师ID*/
  TEMPENDTIME TIMESTAMP,                    /*预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*点改品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',         /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑那技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                         /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成*/
  HANDCARDNUM  VARCHAR(40),                     /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                     /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,                     /*折扣凹度*/
  SERCHARGELIDU INTEGER,                     /*服务费凹度*/
  DISCOUNTORG   NUMERIC(15, 3),              /*折扣来源*/
  SERCHARGEORG  NUMERIC(15, 3),              /*服务费来源*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                   /*记录套餐父品种编号*/
  TCMINAME_LANGUAGE      VARCHAR(100),          /*记录套餐父品种编号*/
  AMOUNTSORG    NUMERIC(15,3),                /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格*/
  TIMECOUNTS    NUMERIC(15,4),               /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),               /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,
  MAJORGID      INTEGER,
  DEPARTMENTID  INTEGER,          /*所属部门编号*/
  AMOUNTORGPER  NUMERIC(15,3),    /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER NOT NULL DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/*点菜的附加信息表*/
CREATE TABLE BACKUP_CHKDETAIL_EXT
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,          /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS* */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /*是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,          /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,          /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               */
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0或1=扣减, 2=补差价*/
  AMOUNTSTYP    VARCHAR(10),       /*百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  ADDEMPID INTEGER DEFAULT -1,   /*添加附加信息的员工编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位成本价格
                                        =百分比 时:记录成本跟父品种价格的每单位百分比*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位提成价格
                                        =百分比 时:记录提成跟父品种价格的每单位百分比*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四

                                     10=介绍人提成 //lzm add 【2009-06-08】
                                     11=服务员提成 //lzm add 【2009-06-10】
                                     12=吧女提成 //lzm add 【2009-06-10】
                                     */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE BACKUP_CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 请查阅CHECKOPLOG
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量金额*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量金额*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
);

/* Table: BACKUP_SALES_SUMERY, Owner: SYSDBA */

CREATE TABLE BACKUP_SALES_SUMERY
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP1_COUNT     INTEGER DEFAULT 0,
  TP1_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP1_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP1_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP2_COUNT     INTEGER DEFAULT 0,
  TP2_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP2_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP2_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP3_COUNT     INTEGER DEFAULT 0,
  TP3_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP3_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP3_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP4_COUNT     INTEGER DEFAULT 0,
  TP4_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP4_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP4_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP5_COUNT     INTEGER DEFAULT 0,
  TP5_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP5_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP5_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP6_COUNT     INTEGER DEFAULT 0,
  TP6_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP6_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP6_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP7_COUNT     INTEGER DEFAULT 0,
  TP7_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP7_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP7_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP8_COUNT     INTEGER DEFAULT 0,
  TP8_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP8_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP8_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP9_COUNT     INTEGER DEFAULT 0,
  TP9_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP9_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP9_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP10_COUNT    INTEGER DEFAULT 0,
  TP10_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP10_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP10_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP11_COUNT    INTEGER DEFAULT 0,
  TP11_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP11_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP11_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP12_COUNT    INTEGER DEFAULT 0,
  TP12_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP12_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP12_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP13_COUNT    INTEGER DEFAULT 0,
  TP13_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP13_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP13_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP14_COUNT    INTEGER DEFAULT 0,
  TP14_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP14_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP14_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP15_COUNT    INTEGER DEFAULT 0,
  TP15_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP15_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP15_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP16_COUNT    INTEGER DEFAULT 0,
  TP16_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP16_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP16_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP17_COUNT    INTEGER DEFAULT 0,
  TP17_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP17_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP17_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP18_COUNT    INTEGER DEFAULT 0,
  TP18_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP18_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP18_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP19_COUNT    INTEGER DEFAULT 0,
  TP19_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP19_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP19_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP20_COUNT    INTEGER DEFAULT 0,
  TP20_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP20_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP20_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP21_COUNT    INTEGER DEFAULT 0,
  TP21_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP21_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP21_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP22_COUNT    INTEGER DEFAULT 0,
  TP22_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP22_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP22_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP23_COUNT    INTEGER DEFAULT 0,
  TP23_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP23_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP23_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP24_COUNT    INTEGER DEFAULT 0,
  TP24_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP24_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP24_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP25_COUNT    INTEGER DEFAULT 0,
  TP25_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP25_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP25_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP26_COUNT    INTEGER DEFAULT 0,
  TP26_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP26_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP26_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP27_COUNT    INTEGER DEFAULT 0,
  TP27_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP27_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP27_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP28_COUNT    INTEGER DEFAULT 0,
  TP28_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP28_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP28_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/* Table: BACKUP_SALES_SUMERY_OTHER, Owner: SYSDBA */

CREATE TABLE BACKUP_SALES_SUMERY_OTHER
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP29_COUNT    INTEGER DEFAULT 0,
  TP29_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP29_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP29_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP30_COUNT    INTEGER DEFAULT 0,
  TP30_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP30_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP30_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP31_COUNT    INTEGER DEFAULT 0,
  TP31_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP31_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP31_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP32_COUNT    INTEGER DEFAULT 0,
  TP32_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP32_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP32_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP33_COUNT    INTEGER DEFAULT 0,
  TP33_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP33_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP33_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP34_COUNT    INTEGER DEFAULT 0,
  TP34_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP34_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP34_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP35_COUNT    INTEGER DEFAULT 0,
  TP35_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP35_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP35_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP36_COUNT    INTEGER DEFAULT 0,
  TP36_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP36_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP36_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP37_COUNT    INTEGER DEFAULT 0,
  TP37_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP37_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP37_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP38_COUNT    INTEGER DEFAULT 0,
  TP38_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP38_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP38_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP39_COUNT    INTEGER DEFAULT 0,
  TP39_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP39_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP39_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP40_COUNT    INTEGER DEFAULT 0,
  TP40_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP40_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP40_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP41_COUNT    INTEGER DEFAULT 0,
  TP41_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP41_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP41_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP42_COUNT    INTEGER DEFAULT 0,
  TP42_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP42_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP42_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP43_COUNT    INTEGER DEFAULT 0,
  TP43_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP43_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP43_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP44_COUNT    INTEGER DEFAULT 0,
  TP44_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP44_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP44_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP45_COUNT    INTEGER DEFAULT 0,
  TP45_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP45_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP45_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP46_COUNT    INTEGER DEFAULT 0,
  TP46_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP46_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP46_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP47_COUNT    INTEGER DEFAULT 0,
  TP47_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP47_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP47_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP48_COUNT    INTEGER DEFAULT 0,
  TP48_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP48_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP48_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/*用于出ICCard消费信息报表*/
CREATE TABLE WHOLE_ICCARD_CONSUME_INFO
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2  INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3  TIMESTAMP,    /*保存销售数据的日期*/
  CARDTYPE  VARCHAR(40),                /*卡的付款类别(10,11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前的余额*/
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                          /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),                   /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),          /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),                /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/
  MEDIANAME  VARCHAR(40),                         /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0, /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);
create index whole_ICCARD_CONSUME_INFO_report_idx on whole_ICCARD_CONSUME_INFO(user_id,shopid,shopguid,checkid,reserve3);

/* Table: WHOLE_CHECKRST, Owner: SYSDBA */

CREATE TABLE WHOLE_CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  AMTCHANGE     NUMERIC(15, 3),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',        /*卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),   /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),    /*VISA卡刷卡时的银行帐单号*/
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,  /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),  /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,  /*餐券数量*/
  NUMBER  VARCHAR(40),   /*编号*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,      /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,   /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,         /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                    //付款类型:1=会员卡 2=挂房帐 3=公司挂账
                    //HOTEL_INSTR=
                    //  当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                    //  当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                    //  当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                    */
  MEMO1 TEXT,                                     /*备注1(澳门通-扣值时,记录澳门通返回的信息) lzm add 2013-03-01*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,                /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型  PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道 用于讯联-支付宝微信支付 ALP:支付宝支付  WXP:微信支付*/
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 用于讯联-支付宝微信支付 lzm add 2015-07-07*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,       /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,  /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 用于讯联-支付宝微信支付 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 lzm add 2016-05-25 13:28:37*/
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10*/
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*第三方订单支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*第三方订单支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*第三方订单退款订单号 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*第三方订单退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*第三方订单的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);
--用于 distinct 和 group by 使用索引
create index whole_CHECKRST_report_RESERVE1_idx on whole_CHECKRST(user_id,shopid,shopguid,checkid,reserve3,pcid,reserve2) INCLUDE (RESERVE1);
create index whole_CHECKRST_report_RESERVE1_AMTCHANGE_idx on whole_CHECKRST(user_id,shopid,shopguid,checkid,reserve3,pcid,reserve2) INCLUDE (RESERVE1,AMTCHANGE);

/* Table: WHOLE_CHECKS, Owner: SYSDBA */

CREATE TABLE WHOLE_CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,
  REFERENCE     VARCHAR(250),
  SEVCHGAMT     NUMERIC(15, 3),
  SUBTOTAL      NUMERIC(15, 3),
  FTOTAL        NUMERIC(15, 3),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  SERVICECHGAPPEND      NUMERIC(15, 3),
  CHECKTOTAL    NUMERIC(15, 3),
  TEXTAPPEND    TEXT,
  CHECKCLOSED   INTEGER,
  ADJUSTAMOUNT  NUMERIC(15, 3),
  SPID  INTEGER,
  DISCOUNT      NUMERIC(15, 3),
  INUSE VARCHAR(1) DEFAULT 'F',
  LOCKTIME      TIMESTAMP,
  CASHIERID     INTEGER,
  ISCARRIEDOVER INTEGER,
  ISADDORSPLIT  INTEGER,
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(40),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(40),
  RESERVE23     VARCHAR(40),
  RESERVE24     VARCHAR(40),
  RESERVE25     VARCHAR(40),
  DISCOUNTNAME  TEXT,
  PERIODOFTIME  INTEGER DEFAULT 0,
  STOCKTIME TIMESTAMP,      /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,  /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，1=早班，2=中班，3=晚班*/
  MINPRICE      NUMERIC(15, 3),               /*最低消费*/
  CHKDISCOUNTLIDU  INTEGER,                  /*折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比*/
  CHKSEVCHGAMTLIDU INTEGER,                  /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKSERVICECHGAPPENDLIDU INTEGER,           /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKDISCOUNTORG   NUMERIC(15, 3),           /*折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),           /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),    /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',      /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                 /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                 /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),              /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),              /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                    /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                 /*机器的序列号*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,                       /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,     /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID)
);
create index whole_CHECKS_report_reserve2 on whole_CHECKS(user_id,shopid,shopguid,checkid,reserve3,pcid,reserve2);

create index whole_checks_reserve3checkid on whole_checks(user_id,shopid,reserve3,checkid);
create index whole_checkrst_reserve3checkid on whole_checkrst(user_id,shopid,reserve3,checkid);
create index whole_chkdetail_reserve3checkid on whole_chkdetail(user_id,shopid,reserve3,checkid);
create index whole_chkdetail_ext_reserve3checkid on whole_chkdetail_ext(user_id,shopid,reserve3,checkid);
create index whole_iccard_consume_info_reserve3checkid on whole_iccard_consume_info(user_id,shopid,reserve3,checkid);

/* Table: WHOLE_CHKDETAIL, Owner: SYSDBA */

CREATE TABLE WHOLE_CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,
  COUNTS        INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  STMARKER      INTEGER,
  AMTDISCOUNT   NUMERIC(15, 3),
  ANAME VARCHAR(100),
  ISVOID        INTEGER,
  VOIDEMPLOYEE  VARCHAR(40),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  DISCOUNTREASON        VARCHAR(60),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(250),
  RESERVE12     VARCHAR(250),
  RESERVE13     VARCHAR(250),
  RESERVE14     VARCHAR(250),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(250),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(10),
  RESERVE23     VARCHAR(40),
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),
  KICKBACK      NUMERIC(15, 3),
  RESERVE24     VARCHAR(240),
  RESERVE25     VARCHAR(40),
  RESERVE11_LANGUAGE    VARCHAR(250),
  RESERVE12_LANGUAGE    VARCHAR(250),
  RESERVE13_LANGUAGE    VARCHAR(250),
  RESERVE14_LANGUAGE    VARCHAR(250),
  SPID  INTEGER,
  TPID  INTEGER,
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,
  ADDININFO    VARCHAR(40) DEFAULT '',
  BARCODE VARCHAR(40),                          /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑那开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑那结束计时时间*/
  AFEMPID INTEGER,                          /*技师ID*/
  TEMPENDTIME TIMESTAMP,                    /*预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*点改品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',         /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑那技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                         /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成*/
  HANDCARDNUM  VARCHAR(40),                     /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                     /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,                     /*折扣凹度*/
  SERCHARGELIDU INTEGER,                     /*服务费凹度*/
  DISCOUNTORG   NUMERIC(15, 3),              /*折扣来源*/
  SERCHARGEORG  NUMERIC(15, 3),              /*服务费来源*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                   /*记录套餐父品种编号*/
  TCMINAME_LANGUAGE      VARCHAR(100),          /*记录套餐父品种编号*/
  AMOUNTSORG    NUMERIC(15,3),                /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格*/
  TIMECOUNTS    NUMERIC(15,4),               /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),               /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,
  MAJORGID      INTEGER,
  DEPARTMENTID  INTEGER,          /*所属部门编号*/
  AMOUNTORGPER  NUMERIC(15,3),    /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/*点菜的附加信息表*/
CREATE TABLE WHOLE_CHKDETAIL_EXT
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,          /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS* */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /*是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,          /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,          /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               */
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0或1=扣减, 2=补差价*/
  AMOUNTSTYP    VARCHAR(10),       /*百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  ADDEMPID INTEGER DEFAULT -1,   /*添加附加信息的员工编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位成本价格
                                        =百分比 时:记录成本跟父品种价格的每单位百分比*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位提成价格
                                        =百分比 时:记录提成跟父品种价格的每单位百分比*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四

                                     10=介绍人提成 //lzm add 【2009-06-08】
                                     11=服务员提成 //lzm add 【2009-06-10】
                                     12=吧女提成 //lzm add 【2009-06-10】
                                     */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE WHOLE_CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 请查阅CHECKOPLOG
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量金额*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量金额*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
);

/* Table: WHOLE_SALES_SUMERY, Owner: SYSDBA */

CREATE TABLE WHOLE_SALES_SUMERY
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP1_COUNT     INTEGER DEFAULT 0,
  TP1_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP1_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP1_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP2_COUNT     INTEGER DEFAULT 0,
  TP2_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP2_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP2_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP3_COUNT     INTEGER DEFAULT 0,
  TP3_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP3_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP3_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP4_COUNT     INTEGER DEFAULT 0,
  TP4_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP4_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP4_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP5_COUNT     INTEGER DEFAULT 0,
  TP5_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP5_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP5_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP6_COUNT     INTEGER DEFAULT 0,
  TP6_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP6_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP6_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP7_COUNT     INTEGER DEFAULT 0,
  TP7_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP7_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP7_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP8_COUNT     INTEGER DEFAULT 0,
  TP8_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP8_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP8_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP9_COUNT     INTEGER DEFAULT 0,
  TP9_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP9_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP9_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP10_COUNT    INTEGER DEFAULT 0,
  TP10_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP10_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP10_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP11_COUNT    INTEGER DEFAULT 0,
  TP11_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP11_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP11_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP12_COUNT    INTEGER DEFAULT 0,
  TP12_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP12_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP12_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP13_COUNT    INTEGER DEFAULT 0,
  TP13_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP13_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP13_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP14_COUNT    INTEGER DEFAULT 0,
  TP14_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP14_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP14_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP15_COUNT    INTEGER DEFAULT 0,
  TP15_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP15_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP15_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP16_COUNT    INTEGER DEFAULT 0,
  TP16_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP16_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP16_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP17_COUNT    INTEGER DEFAULT 0,
  TP17_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP17_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP17_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP18_COUNT    INTEGER DEFAULT 0,
  TP18_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP18_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP18_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP19_COUNT    INTEGER DEFAULT 0,
  TP19_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP19_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP19_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP20_COUNT    INTEGER DEFAULT 0,
  TP20_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP20_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP20_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP21_COUNT    INTEGER DEFAULT 0,
  TP21_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP21_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP21_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP22_COUNT    INTEGER DEFAULT 0,
  TP22_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP22_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP22_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP23_COUNT    INTEGER DEFAULT 0,
  TP23_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP23_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP23_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP24_COUNT    INTEGER DEFAULT 0,
  TP24_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP24_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP24_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP25_COUNT    INTEGER DEFAULT 0,
  TP25_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP25_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP25_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP26_COUNT    INTEGER DEFAULT 0,
  TP26_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP26_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP26_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP27_COUNT    INTEGER DEFAULT 0,
  TP27_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP27_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP27_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP28_COUNT    INTEGER DEFAULT 0,
  TP28_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP28_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP28_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/* Table: WHOLE_SALES_SUMERY_OTHER, Owner: SYSDBA */

CREATE TABLE WHOLE_SALES_SUMERY_OTHER
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP29_COUNT    INTEGER DEFAULT 0,
  TP29_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP29_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP29_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP30_COUNT    INTEGER DEFAULT 0,
  TP30_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP30_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP30_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP31_COUNT    INTEGER DEFAULT 0,
  TP31_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP31_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP31_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP32_COUNT    INTEGER DEFAULT 0,
  TP32_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP32_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP32_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP33_COUNT    INTEGER DEFAULT 0,
  TP33_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP33_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP33_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP34_COUNT    INTEGER DEFAULT 0,
  TP34_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP34_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP34_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP35_COUNT    INTEGER DEFAULT 0,
  TP35_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP35_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP35_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP36_COUNT    INTEGER DEFAULT 0,
  TP36_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP36_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP36_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP37_COUNT    INTEGER DEFAULT 0,
  TP37_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP37_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP37_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP38_COUNT    INTEGER DEFAULT 0,
  TP38_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP38_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP38_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP39_COUNT    INTEGER DEFAULT 0,
  TP39_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP39_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP39_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP40_COUNT    INTEGER DEFAULT 0,
  TP40_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP40_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP40_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP41_COUNT    INTEGER DEFAULT 0,
  TP41_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP41_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP41_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP42_COUNT    INTEGER DEFAULT 0,
  TP42_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP42_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP42_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP43_COUNT    INTEGER DEFAULT 0,
  TP43_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP43_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP43_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP44_COUNT    INTEGER DEFAULT 0,
  TP44_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP44_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP44_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP45_COUNT    INTEGER DEFAULT 0,
  TP45_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP45_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP45_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP46_COUNT    INTEGER DEFAULT 0,
  TP46_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP46_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP46_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP47_COUNT    INTEGER DEFAULT 0,
  TP47_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP47_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP47_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP48_COUNT    INTEGER DEFAULT 0,
  TP48_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP48_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP48_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/*用于出ICCard消费信息报表*/
CREATE TABLE YEAR_WHOLE_ICCARD_CONSUME_INFO
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2  INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3  TIMESTAMP,    /*保存销售数据的日期*/
  CARDTYPE  VARCHAR(40),                /*卡的付款类别(10,11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前的余额*/
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                          /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),                   /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),          /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),                /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/
  MEDIANAME  VARCHAR(40),                         /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0, /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, ICINFO_ICCARDNO, ICINFO_THETIME, CHECKID,LINEID)
);

/* Table: YEAR_WHOLE_CHECKRST, Owner: SYSDBA */

CREATE TABLE YEAR_WHOLE_CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  AMTCHANGE     NUMERIC(15, 3),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',        /*卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),   /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),    /*VISA卡刷卡时的银行帐单号*/
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,  /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),  /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,  /*餐券数量*/
  NUMBER  VARCHAR(40),   /*编号*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,      /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,   /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,         /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                    //付款类型:1=会员卡 2=挂房帐 3=公司挂账
                    //HOTEL_INSTR=
                    //  当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                    //  当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                    //  当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                    */
  MEMO1 TEXT,                                     /*备注1(澳门通-扣值时,记录澳门通返回的信息) lzm add 2013-03-01*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,                /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型  PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道 用于讯联-支付宝微信支付 ALP:支付宝支付  WXP:微信支付*/
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 用于讯联-支付宝微信支付 lzm add 2015-07-07*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,       /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,  /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 用于讯联-支付宝微信支付 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 lzm add 2016-05-25 13:28:37*/
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10*/
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*第三方订单支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*第三方订单支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*第三方订单退款订单号 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*第三方订单退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*第三方订单的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/* Table: YEAR_WHOLE_CHECKS, Owner: SYSDBA */

CREATE TABLE YEAR_WHOLE_CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,
  REFERENCE     VARCHAR(250),
  SEVCHGAMT     NUMERIC(15, 3),
  SUBTOTAL      NUMERIC(15, 3),
  FTOTAL        NUMERIC(15, 3),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  SERVICECHGAPPEND      NUMERIC(15, 3),
  CHECKTOTAL    NUMERIC(15, 3),
  TEXTAPPEND    TEXT,
  CHECKCLOSED   INTEGER,
  ADJUSTAMOUNT  NUMERIC(15, 3),
  SPID  INTEGER,
  DISCOUNT      NUMERIC(15, 3),
  INUSE VARCHAR(1) DEFAULT 'F',
  LOCKTIME      TIMESTAMP,
  CASHIERID     INTEGER,
  ISCARRIEDOVER INTEGER,
  ISADDORSPLIT  INTEGER,
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(40),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(40),
  RESERVE23     VARCHAR(40),
  RESERVE24     VARCHAR(40),
  RESERVE25     VARCHAR(40),
  DISCOUNTNAME  TEXT,
  PERIODOFTIME  INTEGER DEFAULT 0,
  STOCKTIME TIMESTAMP,      /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,  /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，1=早班，2=中班，3=晚班*/
  MINPRICE      NUMERIC(15, 3),               /*最低消费*/
  CHKDISCOUNTLIDU  INTEGER,                  /*折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比*/
  CHKSEVCHGAMTLIDU INTEGER,                  /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKSERVICECHGAPPENDLIDU INTEGER,           /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比*/
  CHKDISCOUNTORG   NUMERIC(15, 3),           /*折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),           /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),    /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',      /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                 /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                 /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),              /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),              /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                    /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                 /*机器的序列号*/
  SHOPID  VARCHAR(40) DEFAULT ''  NOT NULL,                       /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,     /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID)
);

/* Table: YEAR_WHOLE_CHKDETAIL, Owner: SYSDBA */

CREATE TABLE YEAR_WHOLE_CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,
  COUNTS        INTEGER,
  AMOUNTS       NUMERIC(15, 3),
  STMARKER      INTEGER,
  AMTDISCOUNT   NUMERIC(15, 3),
  ANAME VARCHAR(100),
  ISVOID        INTEGER,
  VOIDEMPLOYEE  VARCHAR(40),
  RESERVE1      VARCHAR(40),
  RESERVE2      INTEGER DEFAULT 0,
  RESERVE3      TIMESTAMP,
  DISCOUNTREASON        VARCHAR(60),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE11     VARCHAR(250),
  RESERVE12     VARCHAR(250),
  RESERVE13     VARCHAR(250),
  RESERVE14     VARCHAR(250),
  RESERVE15     VARCHAR(40),
  RESERVE16     VARCHAR(40),
  RESERVE17     VARCHAR(250),
  RESERVE18     VARCHAR(40),
  RESERVE19     VARCHAR(40),
  RESERVE20     VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,
  RESERVE21     VARCHAR(40),
  RESERVE22     VARCHAR(10),
  RESERVE23     VARCHAR(40),
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),
  KICKBACK      NUMERIC(15, 3),
  RESERVE24     VARCHAR(240),
  RESERVE25     VARCHAR(40),
  RESERVE11_LANGUAGE    VARCHAR(250),
  RESERVE12_LANGUAGE    VARCHAR(250),
  RESERVE13_LANGUAGE    VARCHAR(250),
  RESERVE14_LANGUAGE    VARCHAR(250),
  SPID  INTEGER,
  TPID  INTEGER,
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,
  ADDININFO    VARCHAR(40) DEFAULT '',
  BARCODE VARCHAR(40),                          /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑那开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑那结束计时时间*/
  AFEMPID INTEGER,                          /*技师ID*/
  TEMPENDTIME TIMESTAMP,                    /*预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*点改品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',         /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑那技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                         /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成*/
  HANDCARDNUM  VARCHAR(40),                     /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                     /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,                     /*折扣凹度*/
  SERCHARGELIDU INTEGER,                     /*服务费凹度*/
  DISCOUNTORG   NUMERIC(15, 3),              /*折扣来源*/
  SERCHARGEORG  NUMERIC(15, 3),              /*服务费来源*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                   /*记录套餐父品种编号*/
  TCMINAME_LANGUAGE      VARCHAR(100),          /*记录套餐父品种编号*/
  AMOUNTSORG    NUMERIC(15,3),                /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格*/
  TIMECOUNTS    NUMERIC(15,4),               /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),               /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,
  MAJORGID      INTEGER,
  DEPARTMENTID  INTEGER,          /*所属部门编号*/
  AMOUNTORGPER  NUMERIC(15,3),    /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/*点菜的附加信息表*/
CREATE TABLE YEAR_WHOLE_CHKDETAIL_EXT
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,          /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS* */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /*是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,          /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,          /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               */
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0=金额扣减, 1=百分比扣减, 2=补差价*/
  AMOUNTSTYP    VARCHAR(10),       /*百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  ADDEMPID INTEGER DEFAULT -1,   /*添加附加信息的员工编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位成本价格
                                        =百分比 时:记录成本跟父品种价格的每单位百分比*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位提成价格
                                        =百分比 时:记录提成跟父品种价格的每单位百分比*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四

                                     10=介绍人提成 //lzm add 【2009-06-08】
                                     11=服务员提成 //lzm add 【2009-06-10】
                                     12=吧女提成 //lzm add 【2009-06-10】
                                     */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE YEAR_WHOLE_CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 请查阅CHECKOPLOG
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量金额*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量金额*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
);

/* Table: YEAR_WHOLE_SALES_SUMERY, Owner: SYSDBA */

CREATE TABLE YEAR_WHOLE_SALES_SUMERY
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP1_COUNT     INTEGER DEFAULT 0,
  TP1_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP1_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP1_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP2_COUNT     INTEGER DEFAULT 0,
  TP2_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP2_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP2_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP3_COUNT     INTEGER DEFAULT 0,
  TP3_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP3_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP3_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP4_COUNT     INTEGER DEFAULT 0,
  TP4_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP4_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP4_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP5_COUNT     INTEGER DEFAULT 0,
  TP5_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP5_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP5_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP6_COUNT     INTEGER DEFAULT 0,
  TP6_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP6_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP6_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP7_COUNT     INTEGER DEFAULT 0,
  TP7_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP7_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP7_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP8_COUNT     INTEGER DEFAULT 0,
  TP8_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP8_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP8_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP9_COUNT     INTEGER DEFAULT 0,
  TP9_AMOUNTS   NUMERIC(15, 3) DEFAULT 0,
  TP9_TAX       NUMERIC(15, 3) DEFAULT 0,
  TP9_DISCOUNT  NUMERIC(15, 3) DEFAULT 0,
  TP10_COUNT    INTEGER DEFAULT 0,
  TP10_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP10_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP10_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP11_COUNT    INTEGER DEFAULT 0,
  TP11_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP11_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP11_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP12_COUNT    INTEGER DEFAULT 0,
  TP12_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP12_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP12_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP13_COUNT    INTEGER DEFAULT 0,
  TP13_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP13_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP13_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP14_COUNT    INTEGER DEFAULT 0,
  TP14_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP14_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP14_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP15_COUNT    INTEGER DEFAULT 0,
  TP15_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP15_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP15_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP16_COUNT    INTEGER DEFAULT 0,
  TP16_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP16_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP16_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP17_COUNT    INTEGER DEFAULT 0,
  TP17_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP17_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP17_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP18_COUNT    INTEGER DEFAULT 0,
  TP18_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP18_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP18_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP19_COUNT    INTEGER DEFAULT 0,
  TP19_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP19_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP19_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP20_COUNT    INTEGER DEFAULT 0,
  TP20_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP20_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP20_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP21_COUNT    INTEGER DEFAULT 0,
  TP21_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP21_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP21_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP22_COUNT    INTEGER DEFAULT 0,
  TP22_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP22_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP22_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP23_COUNT    INTEGER DEFAULT 0,
  TP23_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP23_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP23_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP24_COUNT    INTEGER DEFAULT 0,
  TP24_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP24_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP24_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP25_COUNT    INTEGER DEFAULT 0,
  TP25_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP25_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP25_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP26_COUNT    INTEGER DEFAULT 0,
  TP26_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP26_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP26_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP27_COUNT    INTEGER DEFAULT 0,
  TP27_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP27_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP27_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP28_COUNT    INTEGER DEFAULT 0,
  TP28_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP28_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP28_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

/* Table: YEAR_WHOLE_SALES_SUMERY_OTHER, Owner: SYSDBA */

CREATE TABLE YEAR_WHOLE_SALES_SUMERY_OTHER
(
  MENUITEMID    INTEGER NOT NULL,
  FAMILYGROUPID INTEGER,
  MAJORGROUPID  INTEGER,
  TP29_COUNT    INTEGER DEFAULT 0,
  TP29_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP29_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP29_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP30_COUNT    INTEGER DEFAULT 0,
  TP30_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP30_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP30_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP31_COUNT    INTEGER DEFAULT 0,
  TP31_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP31_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP31_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP32_COUNT    INTEGER DEFAULT 0,
  TP32_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP32_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP32_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP33_COUNT    INTEGER DEFAULT 0,
  TP33_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP33_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP33_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP34_COUNT    INTEGER DEFAULT 0,
  TP34_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP34_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP34_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP35_COUNT    INTEGER DEFAULT 0,
  TP35_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP35_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP35_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP36_COUNT    INTEGER DEFAULT 0,
  TP36_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP36_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP36_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP37_COUNT    INTEGER DEFAULT 0,
  TP37_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP37_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP37_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP38_COUNT    INTEGER DEFAULT 0,
  TP38_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP38_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP38_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP39_COUNT    INTEGER DEFAULT 0,
  TP39_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP39_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP39_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP40_COUNT    INTEGER DEFAULT 0,
  TP40_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP40_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP40_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP41_COUNT    INTEGER DEFAULT 0,
  TP41_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP41_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP41_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP42_COUNT    INTEGER DEFAULT 0,
  TP42_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP42_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP42_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP43_COUNT    INTEGER DEFAULT 0,
  TP43_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP43_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP43_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP44_COUNT    INTEGER DEFAULT 0,
  TP44_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP44_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP44_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP45_COUNT    INTEGER DEFAULT 0,
  TP45_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP45_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP45_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP46_COUNT    INTEGER DEFAULT 0,
  TP46_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP46_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP46_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP47_COUNT    INTEGER DEFAULT 0,
  TP47_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP47_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP47_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  TP48_COUNT    INTEGER DEFAULT 0,
  TP48_AMOUNTS  NUMERIC(15, 3) DEFAULT 0,
  TP48_TAX      NUMERIC(15, 3) DEFAULT 0,
  TP48_DISCOUNT NUMERIC(15, 3) DEFAULT 0,
  RESERVE3      VARCHAR(40),
  Y     INTEGER NOT NULL,
  M     INTEGER NOT NULL,
  D     INTEGER NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
 PRIMARY KEY (PCID, Y, M, D, MENUITEMID)
);

CREATE TABLE EXPORT_ICCARD_CONSUME_INFO  /*用于出ICCard消费信息报表*/
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2   INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3   TIMESTAMP,                /*保存销售数据的日期*/
  RSTLINEID  INTEGER,                    /*CHECKRST的行号*/
  CARDTYPE  VARCHAR(40),                /*卡的付款类别(11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前的余额*/
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                          /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),                   /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),          /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),                /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/
  MEDIANAME  VARCHAR(40),                         /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0, /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);

/* Table: CHECKRST, Owner: SYSDBA */

CREATE TABLE EXPORT_CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,        /*付款类型*/
  AMOUNTS       NUMERIC(15, 3), /*未转换前的*/
  AMTCHANGE     NUMERIC(15, 3), /*如是外币,转换后的*/
  RESERVE1      VARCHAR(40),    /*Media Name*/  /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000-->0000"*/
  RESERVE2      INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期*/
  RESERVE01     VARCHAR(40),    /* 如果是特殊账单号CHECKID=-1则记录预定台号*/
  RESERVE02     VARCHAR(40),    /* 如果是特殊账单号CHECKID=-1则记录预定人的名字*/
  RESERVE03     VARCHAR(40),    /* 如果是特殊账单号CHECKID=-1则记录预定的时间*/
  RESERVE04     VARCHAR(40),    /*"记帐的用户编号"*/
  RESERVE05     VARCHAR(40),    /*付款方式,对应TENDERMEDIA内的RESERVE3*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',   /*IC卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=消费 1=充值*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*IC卡小费或充值的金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*IC卡余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),            /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),         /*VISA卡刷卡时的银行帐单号*/
  LQNUMBER     VARCHAR(40),                  /*礼券编号*/
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,        /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),     /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,                /*餐券数量*/
  NUMBER  VARCHAR(40),                       /*当前付款的编号*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,      /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,   /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,         /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计("修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                    //付款类型:1=会员卡 2=挂房帐 3=公司挂账
                    //HOTEL_INSTR=
                    //  当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                    //  当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                    //  当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                    */
  MEMO1 TEXT,                                     /*备注1(澳门通-扣值时,记录澳门通返回的信息) lzm add 2013-03-01*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,                /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型  PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道 用于讯联-支付宝微信支付 ALP:支付宝支付  WXP:微信支付*/
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 用于讯联-支付宝微信支付 lzm add 2015-07-07*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,       /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,  /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 用于讯联-支付宝微信支付 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 lzm add 2016-05-25 13:28:37*/
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10*/
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*第三方订单支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*第三方订单支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*第三方订单退款订单号 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*第三方订单退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*第三方订单的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/* Table: CHECKS, Owner: SYSDBA */
/* 提取有效帐单的条件:
  RESERVE2=''' + cNotAddOrSplit + ''''
  CHECKCLOSED=' + IntToStr(cCheckNotClosed)
*/
CREATE TABLE EXPORT_CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/
  REFERENCE     VARCHAR(250),       /*外送单的相关信息
                                   如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"
                                   如果MODEID=盘点单，记录盘点的批号
                                   或
                                   用于总部的数据整理：'S1'=按用餐方式合计整天的营业数据到一张帐单*/
  SEVCHGAMT     NUMERIC(15, 3),    /* 自动的服务费(即品种服务费合计)＝SUBTOTAL*PERCENT */
  SUBTOTAL      NUMERIC(15, 3),    /* 合计＝CHECKDETAIL的AAMOUNTS的和 */
  FTOTAL        NUMERIC(15, 3),    /* 应付金额＝SUBTOTAL-DISCOUNT(CHECK+ITEM)+SERVICECHARGE(自动+附加)+税 */
  STIME TIMESTAMP,                 /*开单时间*/
  ETIME TIMESTAMP,                 /*结帐时间*/
  SERVICECHGAPPEND      NUMERIC(15, 3),    /*附加的服务费＝SUBTOTAL*PERCENT (即:单个品种收服务费后 可以再对 品种的合计SUBTOTAL收服务费)*/
  CHECKTOTAL    NUMERIC(15, 3), /*已付款金额*/
  TEXTAPPEND    TEXT,           /*附加信息1(合单分单的信息和折扣信息等等..)*/
  CHECKCLOSED   INTEGER,        /*帐单是否是已结帐单(0:没结 1:已结)*/
  ADJUSTAMOUNT  NUMERIC(15, 3), /*与上单的差额*/
  SPID  INTEGER,                /* 用作记录    服务段:1~48*/
  DISCOUNT      NUMERIC(15, 3), /* 附加的账单折扣=SUBTOTAL*PERCENT (即:单个品种打折后 可以再对 品种的合计SUBTOTAL打折)*/
  INUSE VARCHAR(1) DEFAULT 'F', /*T:正在使用,F:没有使用*/
  LOCKTIME      TIMESTAMP,      /*帐单开始锁定的时间*/
  CASHIERID     INTEGER,        /*收银员编号*/
  ISCARRIEDOVER INTEGER,        /*首次付款方式（记录付款方式的编号，用于“根据付款方式出报表”）*/
  ISADDORSPLIT  INTEGER,        /*不使用*/
  RESERVE1      VARCHAR(40),    /*出单次数*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效单据，1=无效单据【ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)】*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期,如   19990130  ,六位的字符串*/
  RESERVE01     VARCHAR(40),    /*税1合计*/
  RESERVE02     VARCHAR(40),    /*会员卡对应的'EMPID'  不是IDVALUE*/
  RESERVE03     VARCHAR(40),    /*折扣【5种VIP卡和第四种打折方式】: "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]"  N表示nil 【状态:全部为0】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE04     VARCHAR(40),    /*折扣【餐后点饮料、原品续杯、非原品续杯】 "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]" N表示nil 【状态: 纪录0或空:不打折，1：餐后点饮料、2：原品续杯、3：非原品续杯】,【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE05     VARCHAR(40),    /*假帐 1=新的已结单, 由1更新到2=触发数据库触发器进行假帐处理和变为3, 3=处理完毕, 4=ReOpen的单据. (经过DBToFile程序后,由4更新到3,由1更新到2)*/
  RESERVE11     VARCHAR(40),    /*jaja 记录预定人使用时Table5相应记录的id值*/
  RESERVE12     VARCHAR(40),    /*记录---挂单---  0或null:不是挂单; 1:挂单*/
  RESERVE13     VARCHAR(40),    /*实收金额*/
  RESERVE14     VARCHAR(40),    /*EMPNAME员工名称*/
  RESERVE15     VARCHAR(40),    /*MODENAME用餐方式名称*/
  RESERVE16     VARCHAR(40),    /*CASHIERNAME收银员名称*/
  RESERVE17     VARCHAR(40),    /*ITEMDISCOUNT品种折扣合计*/
  RESERVE18     VARCHAR(40),    /*上传数据到总部: 0或空=没有上传，1=成功【旧：记录BackUp成功=1】*/
  RESERVE19     VARCHAR(40),    /*上次上传数据到总部的压缩方法【旧：记录MIS成功=1】:
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  10=经过MIME64编码

                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                */
  RESERVE20     VARCHAR(40),    /*帐单类型(20050805)
                                0或空=普通帐单
                                1=IC卡充值
                                2=换礼品扣除会员券或积分(在功能 MinusCouponClickEvent 里设置)
                                3=全VOID单
                                4=餐券入店记录-没做
                                5=从钱箱提取现金的帐单记录
                                */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),   /*团体消费时的格式为(GROUP:组号),
                                 内容是空时为个人消费,
                                 内容是GUID时为记录消费者编号,*/
  RESERVE21     VARCHAR(40),   /*其它价格,用于判断:四维品种 和 1=会员价*/       /*老年*/
  RESERVE22     VARCHAR(40),   /*VIP卡号【之前用于记录:台号(房间)价格】*/         /*中年*/
  RESERVE23     VARCHAR(40),   /*台号(房间)名称*/                               /*少年*/
  RESERVE24     VARCHAR(40),   /*台号(房间)是否停止计时, 0或空=需要计时, 1=停止计时*/
  RESERVE25     VARCHAR(40),   /*台号(房间)所在的区域 组成: 区域编号A|区域中午名称|区域英文名称*/
  DISCOUNTNAME  TEXT,                  /*折扣名称*/
  PERIODOFTIME  INTEGER DEFAULT 0,            /**/
  STOCKTIME TIMESTAMP,                        /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,                    /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，对应班次表SHIFTTIMEPERIOD*/
  MINPRICE      NUMERIC(15, 3),               /*会员当前账单得到的积分【之前是用于记录:"最低消费"】*/
  CHKDISCOUNTLIDU  INTEGER,                   /*账单折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比
                                                用于计算CHECKDISCOUNT*/
  CHKSEVCHGAMTLIDU INTEGER,                   /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SEVCHGAMT*/
  CHKSERVICECHGAPPENDLIDU INTEGER,            /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SERVICECHGAPPEND*/
  CHKDISCOUNTORG   NUMERIC(15, 3),            /*账单折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),            /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),     /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',       /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                  /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                  /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),               /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),               /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                     /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                  /*机器的注册序列号*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,                        /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,     /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID)
);

/* Table: CHKDETAIL, Owner: SYSDBA */
/* 提取有效帐单的条件:
  RESERVE2=''' + cNotAddOrSplit + ''''
  ISVOID=' + IntToStr(cNotVOID)
  RESERVE04<>'5'  //内容分割行(系统保留)  <------------>
*/
/*
  LINEID
  1=最低消费
  2=最低消费的差价
  3=房间价格
  4=保留
  5=保留
  6=保留
  7=保留
  8=保留
  9=保留
  10=保留
  11=第一个品种由LINEID=11开始

*/
CREATE TABLE EXPORT_CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,             /* -1:ICCARD充值;null:OpenFood; 0:CustomMenuItem; >0的数字:对应菜式*/
  COUNTS        INTEGER,             /*数量*/
  AMOUNTS       NUMERIC(15, 3),      /*金额=(COUNTS.TIMECOUNTS*单价) */
  STMARKER      INTEGER,             /*是否已送厨房 cNotSendToKitchen=0;cHaveSendToKitchen=1*/
  AMTDISCOUNT   NUMERIC(15, 3),      /*品种折扣*/
  ANAME VARCHAR(100),                   /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"*/
  ISVOID        INTEGER,                /*是否已取消
                                          cNotVOID = 0;
                                          cVOID = 1;
                                          cVOIDObject = 2;
                                          cVOIDObjectNotServiceTotal = 3;
                                        */
  VOIDEMPLOYEE  VARCHAR(40),            /*取消该品种的员工*/
  RESERVE1      VARCHAR(40),            /*成本(????好像已停用????)*/
  RESERVE2      INTEGER DEFAULT 0,      /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,              /*保存销售数据的日期*/
  DISCOUNTREASON        VARCHAR(60),    /*折扣原因*/
  RESERVE01     VARCHAR(40),   /*税1*/
  RESERVE02     VARCHAR(40),   /*  纪录0或空:普通、
                                   1:餐后点饮料、
                                   2:原品续杯、
                                   3:非原品续杯 、
                                   4:已计算的相撞优惠品种
                                   5:大单分账*/
  RESERVE03     VARCHAR(40),   /*  父菜式的LineID ,空无父菜式 ,
                                   如果 >=0 证明该品种是套餐内容或品种的小费，
                                        >=0 and RESERVE02=4 时代表相撞的品种LineID
                                        >=0 and RESERVE02=5 时代表大单分账的品种LineID
                               */
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Openfood品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价
                               15-房价
                               */
  RESERVE05     VARCHAR(40),   /*  OpenFood的逻辑打印机的名称*/
  RESERVE11     VARCHAR(250),   /*  4维菜式参数 1维 */
  RESERVE12     VARCHAR(250),   /*  4维菜式参数 2维 */
  RESERVE13     VARCHAR(250),   /*  4维菜式参数 3维 */
  RESERVE14     VARCHAR(250),   /*  4维菜式参数 4维 */
  RESERVE15     VARCHAR(40),   /*  折扣ID  */
  RESERVE16     VARCHAR(40),   /*用于"入单"时的"印单",                         */
                              /*  入单时暂时设置RESERVE16=cNotSendTag,                */
                              /*  印单时查找RESERVE16=cNotSendTag的记录打印,  */
                              /*  入单后设置RESERVE16=NULL                        */
  RESERVE17     VARCHAR(250),  /* 品种的原始名词(改于:2008-1-10),用于出报表
                                【之前用于：RESERVE17是否已经计算入sumery的标志,记录Reopen已void的标记
                                  1:已将void的菜式update入sales_sumery
                                 】
                              */
  RESERVE18     VARCHAR(40),  /*记录 K */
  RESERVE19     VARCHAR(40),  /*记录入单的时间如  15:25
                                没入单前作为临时标记使用0，1
                              */
  RESERVE20     VARCHAR(40),  /*(停用20020815)记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为1[ID],ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)*/
                              /*(停用20020702)记录该菜式是打印到哪里:WATERBAR;KICHEN1;KICHEN2,NOTPRINT等等*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,         /*记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为ID,ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)*/
  RESERVE21     VARCHAR(40),     /*记录会员卡卡号,与RESERVE20相关*/
  RESERVE22     VARCHAR(10),     /*卡号购买时间*/
  RESERVE23     VARCHAR(40),     /* 1.记录该菜式送给谁的,如:玫瑰花送给哪位小姐*/
                                 /* 2.如果AFEMPID不为空或0, 则记录该技师的服务类别:1="点钟",2="普通钟",3="CALL钟"*/
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  RESERVE24     VARCHAR(240),         /*记录点菜人的名字*/
  RESERVE25     VARCHAR(40),          /*用于"叫起" [空值=按原来的方式打印; 0=叫起(未入单前); 1=起叫(入单后);  起叫后,Clear该值]*/
  RESERVE11_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 1维名称(本地语言) */
  RESERVE12_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 2维名称(本地语言) */
  RESERVE13_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 3维名称(本地语言) */
  RESERVE14_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 4维名称(本地语言) */
  SPID  INTEGER,                             /*品种时段参数,所属时间段编号(SERVICEPERIOD), 1~48个时间段(老的时段报表需要该数据)*/
  TPID  INTEGER,                             /*四维时段参数*/
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,    /*附加信息的金额*/
  ADDININFO    VARCHAR(40) DEFAULT '',       /*附加信息的信息*/
  BARCODE VARCHAR(40),                       /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑拿开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑拿结束计时时间*/
  AFEMPID INTEGER,                           /*桑拿技师ID; 0或空=没有技师。*/
  TEMPENDTIME TIMESTAMP,                     /*桑拿预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*桑拿点该品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',      /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑拿技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                      /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成
                                               如果有多个编号则用分号";"分隔,代表该品种的提成由相应的员工平分
                                             */
  HANDCARDNUM  VARCHAR(40),                  /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                  /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,           /*折扣凹度*/
                                             /*1=来源折扣表格(DISCOUNT)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  SERCHARGELIDU INTEGER,           /*服务费凹度*/
                                             /*1=来源服务费表格(SERCHARGE)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  DISCOUNTORG   NUMERIC(15, 3),    /*折扣来源*/
                                             /*当DISCOUNTLIDU=1时:记录折扣编号*/
                                             /*当DISCOUNTLIDU=2时:记录金额*/
                                             /*当DISCOUNTLIDU=3时:记录百分比*/
  SERCHARGEORG  NUMERIC(15, 3),    /*服务费来源*/
                                             /*当SERCHARGELIDU=1时:记录折扣编号*/
                                             /*当SERCHARGELIDU=2时:记录金额*/
                                             /*当SERCHARGELIDU=3时:记录百分比*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                /*记录套餐父品种名称*/
  TCMINAME_LANGUAGE      VARCHAR(100),       /*记录套餐父品种英文名称*/
  AMOUNTSORG    NUMERIC(15,3),               /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  TIMECOUNTS    NUMERIC(15,4),  /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),  /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,          /*辅助分类2 系统规定:-10=台号*/
  MAJORGID      INTEGER,          /*辅助分类1*/
  DEPARTMENTID  INTEGER,          /*所属部门编号 系统规定:-10=台号*/
  AMOUNTORGPER  NUMERIC(15, 3),   /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE EXPORT_CHKDETAIL_EXT  /*点菜的附加信息表*/
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,              /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS* */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /*停用，因为通过查询CHKDETAIL可以知道ISVOID的状态
                                       是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,            /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               */
  COST  NUMERIC(15, 3),          /*附加信息自己的原材料成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /*停用 记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0或1=扣减, 2=补差价*/
  AMOUNTSTYP    VARCHAR(10),       /*百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  ADDEMPID INTEGER DEFAULT -1,     /*添加附加信息的员工编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位成本价格
                                        =百分比 时:记录成本跟父品种价格的每单位百分比*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位提成价格
                                        =百分比 时:记录提成跟父品种价格的每单位百分比*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),    /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四

                                     10=介绍人提成 //lzm add 【2009-06-08】
                                     11=服务员提成 //lzm add 【2009-06-10】
                                     12=吧女提成 //lzm add 【2009-06-10】
                                     */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE EXPORT_CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,          /*操作ID*/
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 请查阅CHECKOPLOG
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量或金额*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量或金额*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
);


CREATE TABLE ANALYZE_ICCARD_CONSUME_INFO  /*用于出ICCard消费信息报表*/
(
  CHECKID  INTEGER NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) NOT NULL,
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=IC卡消费 1=IC卡充值 2=修改IC卡消费金额 3=消费产生的积分累计 4=积分消费 5=积分换礼品*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*消费金额("消费")
                                               充值金额("充值")
                                               添加的消费数("修改IC卡消费金额")
                                               添加的积分数(积分累计)
                                               消费的积分数(积分消费)
                                               换礼品的积分数(积分换礼品)*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*卡内余额("消费")
                                               卡内余额("充值")
                                               卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                               卡内剩余积分("积分累计")
                                               卡内剩余积分("积分消费")
                                               卡内剩余积分("积分换礼品")*/
  ICINFO_THETIME  TIMESTAMP NOT NULL,        /*消费时间*/
  Y     INTEGER DEFAULT NULL,
  M     INTEGER DEFAULT NULL,
  D     INTEGER DEFAULT NULL,
  PCID  VARCHAR(40) DEFAULT NULL,
  RESERVE2   INTEGER DEFAULT 0,        /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3   TIMESTAMP,                /*保存销售数据的日期*/
  RSTLINEID  INTEGER,                  /*CHECKRST的行号*/
  CARDTYPE  VARCHAR(40),               /*卡的付款类别(11,12,13,14,15)*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内剩余积分("积分累计")
                                                   之前卡内剩余积分("积分消费")
                                                   之前卡内剩余积分("积分换礼品")*/
  MEMO1  TEXT,                 /*扩展信息 2009-4-8  lzm modify varchar(250)->text 2013-02-27
                                       */
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*送的金额  lzm add 【2009-05-06】*/
  --ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  --ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/
  MEDIANAME  VARCHAR(40),                         /*付款名称*/
  LINEID     serial,                       /*行号 lzm add 2010-09-07*/
  CASHIERNAME  VARCHAR(50),                /*收银员名称 lzm add 2010-12-07*/
  ABUYERNAME   VARCHAR(50),                /*会员名称 lzm add 2010-12-07*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-07-05】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-07-21】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,       /*之前剩余积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,       /*现在使用积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,       /*现在获得积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,       /*现在剩余积分 lzm add 【2011-08-02】*/

  ICINFO_P2M_MONEYBEF NUMERIC(15,3) DEFAULT 0,       /*之前折现金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_DECPOINTS NUMERIC(15,3) DEFAULT 0,      /*折现扣减积分(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_ADDMONEY NUMERIC(15,3) DEFAULT 0,       /*折现增加金额(用于积分折现报表) lzm add 【2011-08-04】*/
  ICINFO_P2M_MONEYNOW NUMERIC(15,3) DEFAULT 0,       /*现在折现金额(用于积分折现报表) lzm add 【2011-08-04】*/

  REPORTCODE TEXT,            /*lzm add 2012-07-30*/
  ISFIXED INTEGER DEFAULT 0,  /*lzm add 2012-07-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0, /*lzm add 2015-05-27*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*lzm add 2015-05-27*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  ICINFO_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, ICINFO_ICCARDNO,ICINFO_THETIME,CHECKID,LINEID)
);

/* Table: CHECKRST, Owner: SYSDBA */

CREATE TABLE ANALYZE_CHECKRST
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MEDIAID       INTEGER,        /*付款类型*/
  AMOUNTS       NUMERIC(15, 3), /*未转换前的*/
  AMTCHANGE     NUMERIC(15, 3), /*如是外币,转换后的*/
  RESERVE1      VARCHAR(40),    /*Media Name*/  /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000-->0000"*/
  RESERVE2      INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期*/
  RESERVE01     VARCHAR(40),    /* 【作废:如果是特殊账单号CHECKID=-1则记录预定台号】*/
  RESERVE02     VARCHAR(40),    /* 【作废:如果是特殊账单号CHECKID=-1则记录预定人的名字】*/
  RESERVE03     VARCHAR(40),    /* 【作废:如果是特殊账单号CHECKID=-1则记录预定的时间】*/
  RESERVE04     VARCHAR(40),    /*"记帐的用户编号"*/
  RESERVE05     VARCHAR(40),    /*付款方式,对应TENDERMEDIA内的RESERVE3*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  ICINFO_ICCARDNO  VARCHAR(40) DEFAULT '',   /*IC卡号*/
  ICINFO_CONSUMETYPE  INTEGER DEFAULT 0,     /*类型: 0=IC卡消费 1=IC卡充值 2=没使用 3=其它付款方式(非VIP付款方式)*/
  ICINFO_AMOUNT   NUMERIC(15,3) DEFAULT 0,   /*IC卡小费或充值的金额*/
  ICINFO_BALANCE  NUMERIC(15,3) DEFAULT 0,   /*IC卡余额(消费或充值后的卡内金额)*/
  ICINFO_THETIME  TIMESTAMP,                 /*消费时间*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  VISACARD_CARDNUM  VARCHAR(100),            /*VISA卡号*/
  VISACARD_BANKBILLNUM  VARCHAR(40),         /*VISA卡刷卡时的银行帐单号*/
  LQNUMBER     VARCHAR(40),                  /*礼券编号*/
  BAKSHEESH  NUMERIC(15,3) DEFAULT 0,        /*小费金额*/
  MEALTICKET_AMOUNTSUNIT  NUMERIC(15,3),     /*餐券面额*/
  MEALTICKET_COUNTS  INTEGER,                /*餐券数量*/
  NUMBER  VARCHAR(40),                       /*当前付款的编号 用于报表的统计*/
  ACCOUNTANTNAME  VARCHAR(20),               /*会计名称*/
  ICINFO_GIVEAMOUNT  NUMERIC(15,3) DEFAULT 0,  /*充值赠送的金额  lzm add 【2009-05-06】*/
  RECEIVEDLIDU VARCHAR(10) DEFAULT NULL,       /*对账额率  lzm add 【2009-06-21】*/
  RECEIVEDACCOUNTS NUMERIC(15,3) DEFAULT 0,    /*对账额  lzm add 【2009-06-21】*/
  INPUTMONEY NUMERIC(15,3) DEFAULT 0,          /*键入的金额 lzm add 【2009-06-21】*/
  ICINFO_BEFOREBALANCE  NUMERIC(15,3) DEFAULT 0, /*之前卡内余额("消费")
                                                   之前卡内余额("充值")
                                                   之前卡内剩余消费合计("修改IC卡消费金额"后的卡内余额)
                                                   之前卡内余额("其它付款方式")*/
  ICINFO_VIPPOINTBEF  NUMERIC(15,3) DEFAULT 0,                /*之前剩余积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTUSE  NUMERIC(15,3) DEFAULT 0,                /*现在使用积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTADD  NUMERIC(15,3) DEFAULT 0,                /*现在获得积分 lzm add 【2009-10-19】*/
  ICINFO_VIPPOINTNOW  NUMERIC(15,3) DEFAULT 0,                /*现在剩余积分 lzm add 【2009-10-19】*/
  ICINFO_CONSUMEBEF  NUMERIC(15,3) DEFAULT 0,                 /*之前剩余消费合计(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BEFOREBALANCE" lzm add 【2009-10-19】*/
  ICINFO_CONSUMEADD  NUMERIC(15,3) DEFAULT 0,                 /*现在添加的消费数(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_AMOUNT" lzm add 【2009-10-19】*/
  ICINFO_CONSUMENOW  NUMERIC(15,3) DEFAULT 0,                 /*现在剩余消费合计(用于"修改IC卡消费金额") 对应ICCARD_CONSUME_INFO的"ICINFO_BALANCE" lzm add 【2009-10-19】*/
  ICINFO_MENUITEMID  INTEGER,                     /*相关的品种编号
                                                  ("积分换礼品")礼品的品种编号*/
  ICINFO_MENUITEMNAME  VARCHAR(100),              /*相关的品种名称
                                                  ("积分换礼品")礼品名称*/
  ICINFO_MENUITEMNAME_LANGUAGE  VARCHAR(100),     /*相关的品种英文名称
                                                  ("积分换礼品")的礼品英文名称*/
  ICINFO_MENUITEMAMOUNTS NUMERIC(15,3),           /*相关的品种价格
                                                  ("积分消费")消费的金额
                                                  ("积分换礼品")礼品的金额*/

  ICINFO_VIPPOTOTAL  NUMERIC(15,3) DEFAULT 0,     /*VIP卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTODAY NUMERIC(15,3) DEFAULT 0,      /*当天累计积分 lzm add 【2011-08-02】*/

  ICINFO_VIPPOTOTALBEF  NUMERIC(15,3) DEFAULT 0,     /*之前的卡累总积分 lzm add 【2011-08-02】*/
  ICINFO_VIPPOTOTALADD  NUMERIC(15,3) DEFAULT 0,     /*增加的累总积分 lzm add 【2011-08-02】*/

  HOTEL_INSTR VARCHAR(100),                       /*记录酒店的相关信息 用`分隔 用于酒店的清除付款 lzm add 2012-06-26
                    //付款类型:1=会员卡 2=挂房帐 3=公司挂账
                    //HOTEL_INSTR=
                    //  当付款类型=1,内容为: 付款类型`客人ID`扣款金额(储值卡用)`增加积分数(刷卡积分用)`扣除次数(次卡用)
                    //  当付款类型=2,内容为: 付款类型`客人帐号`房间号`扣款金额
                    //  当付款类型=3,内容为: 付款类型`挂账公司ID`扣款金额
                    */
  MEMO1 TEXT,                                     /*备注1(澳门通-扣值时,记录澳门通返回的信息) lzm add 2013-03-01*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 对应CHKDETAIL的PAYMENT lzm add 2011-07-28*/
  PAY_REMAIN  NUMERIC(15,3) DEFAULT 0,                /*付款的余额 lzm add 2015-05-28*/
  SCPAYCLASS   VARCHAR(200),                      /*支付类型  PURC:下单支付
                                                              VOID:撤销
                                                              REFD:退款
                                                              INQY:查询
                                                              PAUT:预下单
                                                              VERI:卡券核销
                                                  */
  SCPAYCHANNEL VARCHAR(200),                      /*支付渠道 用于讯联-支付宝微信支付 ALP:支付宝支付  WXP:微信支付*/
  SCPAYORDERNO VARCHAR(200),                      /*支付订单号 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYBARCODE VARCHAR(200),                      /*支付条码 用于讯联-支付宝微信支付 lzm add 2015-07-07*/
  SCPAYSTATUS  INTEGER,                           /*支付状态 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 用于讯联-支付宝微信支付 lzm add 2015-07-07*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,       /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,  /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  SCPAYCHANNELCODE VARCHAR(200),                  /*支付渠道交易号 用于讯联-支付宝微信支付 lzm add 2016-2-2*/

  CHECKRST_TYPE INTEGER DEFAULT 0,                /*0=正常 4=被红冲 5=红冲 lzm add 2016-2-21*/
  TRANSACTIONID VARCHAR(100),                     /*第三方订单号 lzm add 2016-05-25 13:28:37*/
  ICINFO_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
  SCANPAYTYPE INTEGER DEFAULT 0,                  /*扫码支付类型 0=讯联 1=翼富 lzm add 2016-07-19 18:46:46*/
  SCPAYQRCODE VARCHAR(240) DEFAULT '',            /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
  SCPAYMANUAL INTEGER DEFAULT 0,                  /*扫码支付结果是否为人工处理 0=否 1=是 lzm add 2017-02-14 15:55:23*/
  SCPAYMEMO VARCHAR(240) DEFAULT '',              /*扫码支付的备注 lzm add 2017-02-14 14:49:04*/
  SCPAYVOIDNO VARCHAR(200) DEFAULT '',            /*退款订单号 lzm add 2017-02-18 16:03:10*/
  SCPAYVOIDSTATUS INTEGER DEFAULT 0,              /*退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2017-02-18 16:03:16*/
  SCPAYDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*可参与优惠的金额 和 SCPAYUNDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAYUNDISCOUNTABLEAMOUNT VARCHAR(40) DEFAULT '', /*不可参与优惠的金额 和 SCPAYDISCOUNTABLEAMOUNT 只能二选一 lzm add 2017-03-11 01:56:57*/
  SCPAY_ALIPAY_WAY VARCHAR(20) DEFAULT '',        /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:47*/
  SCPAY_WXPAY_WAY VARCHAR(20) DEFAULT '',         /*用于记录是否银行通道BMP lzm add 2017-08-24 16:42:56*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  TRANSACTIONID_STATUS  INTEGER default 0,        /*第三方订单支付状态 -1=用户取消(未支付) 0=没支付 1=正在支付 2=正在支付并等待用户输入密码 3=支付成功 4=支付失败 5=系统错误(支付结果未知，需要查询) 6=订单已关闭 7=订单不可退款或撤销 8=订单不存在 9=退款成功 用于扫码支付 lzm add 2020-01-17 08:45:04*/
  TRANSACTIONID_MANUAL INTEGER DEFAULT 0,         /*第三方订单支付是否为人工处理 0=否 1=是 lzm add 2020-01-17 08:44:58*/
  TRANSACTIONID_VOIDNO VARCHAR(200) DEFAULT '',   /*第三方订单退款订单号 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_VOIDSTATUS INTEGER DEFAULT 0,     /*第三方订单退款是否成功 0=没进行退款处理或退款失败 3=退款成功 lzm add 2020-01-19 14:14:52*/
  TRANSACTIONID_MEMO VARCHAR(240) DEFAULT '',     /*第三方订单的备注 lzm add 2020-01-19 14:14:52*/

  SCPAY_RESULT TEXT,                              /*支付结果 lzm add 2020-04-02 04:45:10*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

/* Table: CHECKS, Owner: SYSDBA */
/* 提取有效帐单的条件:
  RESERVE2=''' + cNotAddOrSplit + ''''
  CHECKCLOSED=' + IntToStr(cCheckNotClosed)
*/
CREATE TABLE ANALYZE_CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/
  REFERENCE     VARCHAR(250),       /*外送单的相关信息
                                   如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"
                                   如果MODEID=盘点单，记录盘点的批号
                                   或
                                   用于总部的数据整理：'S1'=按用餐方式合计整天的营业数据到一张帐单*/
  SEVCHGAMT     NUMERIC(15, 3),    /* 自动的服务费(即品种服务费合计)＝SUBTOTAL*PERCENT */
  SUBTOTAL      NUMERIC(15, 3),    /* 合计＝CHECKDETAIL的AAMOUNTS的和 */
  FTOTAL        NUMERIC(15, 3),    /* 应付金额＝SUBTOTAL-DISCOUNT(CHECK+ITEM)+SERVICECHARGE(自动+附加)+税 */
  STIME TIMESTAMP,                 /*开单时间*/
  ETIME TIMESTAMP,                 /*结帐时间 印整单和收银时 记录改时间*/
  SERVICECHGAPPEND      NUMERIC(15, 3),    /*附加的服务费＝SUBTOTAL*PERCENT (即:单个品种收服务费后 可以再对 品种的合计SUBTOTAL收服务费)*/
  CHECKTOTAL    NUMERIC(15, 3), /*已付款金额*/
  TEXTAPPEND    TEXT,           /*扩展信息1(合单分单的信息和折扣信息等等..)*/
  CHECKCLOSED   INTEGER,        /*帐单是否是已结帐单(0:没结 1:已结 2:暂结单)*/
  ADJUSTAMOUNT  NUMERIC(15, 3), /*与上单的差额*/
  SPID  INTEGER,                /* 用作记录    服务段:1~48*/
  DISCOUNT      NUMERIC(15, 3), /* 附加的账单折扣=SUBTOTAL*PERCENT (即:单个品种打折后 可以再对 品种的合计SUBTOTAL打折)*/
  INUSE VARCHAR(1) DEFAULT 'F', /*T:正在使用,F:没有使用*/
  LOCKTIME      TIMESTAMP,      /*帐单开始锁定的时间*/
  CASHIERID     INTEGER,        /*收银员编号*/
  ISCARRIEDOVER INTEGER,        /*首次付款方式（记录付款方式的编号，用于“根据付款方式出报表”）*/
  ISADDORSPLIT  INTEGER,        /*不使用*/
  RESERVE1      VARCHAR(40),    /*出单次数*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效单据，1=无效单据【ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)】*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期,如   19990130  ,六位的字符串*/
  RESERVE01     VARCHAR(40),    /*税1合计*/
  RESERVE02     VARCHAR(40),    /*会员卡对应的'EMPID'  不是IDVALUE*/
  RESERVE03     VARCHAR(40),    /*折扣【5种VIP卡和第四种打折方式】: "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]"  N表示nil 【状态:全部为0】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE04     VARCHAR(40),    /*折扣【餐后点饮料、原品续杯、非原品续杯】 "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]" N表示nil 【状态: 纪录0或空:不打折，1：餐后点饮料、2：原品续杯、3：非原品续杯】,【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE05     VARCHAR(40),    /*假帐 1=新的已结单, 由1更新到2=触发数据库触发器进行假帐处理和变为3, 3=处理完毕, 4=ReOpen的单据. (经过DBToFile程序后,由4更新到3,由1更新到2)

                                  对于EXPORT_CHECKS表:1=新的已结单 2=导出到接口库成功 3=生成冲红单到接口成功
                                */
  RESERVE11     VARCHAR(40),    /*jaja 记录预定人使用时Table5相应记录的id值*/
  RESERVE12     VARCHAR(40),    /*记录---挂单---  0或null:不是挂单; 1:挂单*/
  RESERVE13     VARCHAR(40),    /*实收金额*/
  RESERVE14     VARCHAR(40),    /*EMPNAME开单员工名称*/
  RESERVE15     VARCHAR(40),    /*MODENAME用餐方式名称*/
  RESERVE16     VARCHAR(40),    /*CASHIERNAME收银员名称*/
  RESERVE17     VARCHAR(40),    /*ITEMDISCOUNT品种折扣合计*/
  RESERVE18     VARCHAR(40),    /*上传数据到总部: 0或空=没有上传，1=成功【旧：记录BackUp成功=1】*/
  RESERVE19     VARCHAR(40),    /*上次上传数据到总部的压缩方法【旧：记录MIS成功=1】:
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  10=经过MIME64编码

                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                */
  RESERVE20     VARCHAR(40),    /*帐单类型(20050805)
                                0或空=普通帐单
                                1=IC卡充值帐单
                                2=换礼品扣除会员券或积分(在功能 MinusCouponClickEvent 里设置)帐单
                                3=全VOID单
                                4=餐券入店记录-没做
                                5=从钱箱提取现金的帐单
                                6=收银交班帐单
                                7=客户记账后的还款帐单 lzm add 2009-08-14
                                8=预订单 lzm add 2010-12-17
                                */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),   /*团体消费时的格式为(GROUP:组号),
                                 内容是空时为个人消费,
                                 内容是GUID时为记录消费者编号,*/
  RESERVE21     VARCHAR(40),   /*其它价格,用于判断:四维品种 和 1=会员价*/               /*之前用于记录:老年*/
  RESERVE22     VARCHAR(40),   /*【VIP卡号】*/     /*【之前用于记录:台号(房间)价格*/    /*之前用于记录:中年*/
  RESERVE23     VARCHAR(40),   /*台号(房间)名称*/                                       /*之前用于记录:少年*/
  RESERVE24     VARCHAR(40),   /*台号(房间)是否停止计时, 0或空=需要计时, 1=停止计时*/
  RESERVE25     VARCHAR(40),   /*台号(房间)所在的区域 组成: 区域编号A|区域中午名称|区域英文名称*/
  DISCOUNTNAME  TEXT,                 /*记录最后一次的"单项"或"全单单项"折扣名称*/
  PERIODOFTIME  INTEGER DEFAULT 0,            /*记录是否已进行埋单处理 0或空=没 1=已进行埋单 lzm add [2009-06-18]*/
  STOCKTIME TIMESTAMP,                        /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,                    /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，对应班次表SHIFTTIMEPERIOD */
  MINPRICE      NUMERIC(15, 3),               /* ***会员当前账单得到的积分【之前是用于记录:"最低消费"】*/
  CHKDISCOUNTLIDU  INTEGER,                   /*账单折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比
                                                用于计算CHECKDISCOUNT*/
  CHKSEVCHGAMTLIDU INTEGER,                   /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SEVCHGAMT*/
  CHKSERVICECHGAPPENDLIDU INTEGER,            /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SERVICECHGAPPEND*/
  CHKDISCOUNTORG   NUMERIC(15, 3),            /*账单折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),            /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),     /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',       /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                  /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                  /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),               /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),               /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                     /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                  /*机器的注册序列号*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,                        /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/ /*税1合计=RESERVE01*/

  /*以下是用于预订台用的*/
  ORDERTIME     TIMESTAMP,       /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY   NUMERIC(15, 3),  /*定金*/
  CHECKGUID     VARCHAR(100),    /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420 lzm add 2010-04-20*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权_沙面玫瑰园_) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单附加折扣的名称说明 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*全单项目折扣名称 lzm add 2010-06-18*/

  /*以下2个是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),            /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,     /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID)
);

/* Table: CHKDETAIL, Owner: SYSDBA */
/* 提取有效帐单的条件:
  RESERVE2=''' + cNotAddOrSplit + ''''
  ISVOID=' + IntToStr(cNotVOID)
  RESERVE04<>'5'  //内容分割行(系统保留)  <------------>
*/
/*
  LINEID
  1=最低消费
  2=最低消费的差价
  3=房间价格
  4=保留
  5=保留
  6=保留
  7=保留
  8=保留
  9=保留
  10=保留
  11=第一个品种由LINEID=11开始

*/
CREATE TABLE ANALYZE_CHKDETAIL
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,    /*cLINEID_MISTARTID=11*/
  MENUITEMID    INTEGER,             /* -1:ICCARD充值;null:OpenFood; 0:CustomMenuItem; >0的数字:对应菜式*/
  COUNTS        INTEGER,             /*数量*/
  AMOUNTS       NUMERIC(15, 3),      /*金额=(COUNTS.TIMECOUNTS*单价) */
  STMARKER      INTEGER,             /*是否已送厨房 cNotSendToKitchen=0;cHaveSendToKitchen=1*/
  AMTDISCOUNT   NUMERIC(15, 3),      /*品种折扣*/
  ANAME VARCHAR(100),                   /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"*/
  ISVOID        INTEGER,                /*是否已取消
                                          cNotVOID = 0;
                                          cVOID = 1;
                                          cVOIDObject = 2;
                                          cVOIDObjectNotServiceTotal = 3;
                                        */
  VOIDEMPLOYEE  VARCHAR(40),            /*取消该品种的员工*/
  RESERVE1      VARCHAR(40),            /*之前:记录MIDETAIL的PREPCOST成本(????好像没使用????)*/
  RESERVE2      INTEGER DEFAULT 0,      /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,              /*保存销售数据的日期*/
  DISCOUNTREASON        VARCHAR(60),    /*折扣名称说明*/
  RESERVE01     VARCHAR(40),   /*税1*/
  RESERVE02     VARCHAR(40),   /*  纪录0或空:普通、
                                   1:餐后点饮料、
                                   2:原品续杯、
                                   3:非原品续杯 、
                                   4:已计算的相撞优惠品种
                                   5:自动大单分账
                                   6:手动大单分账
                               */
  RESERVE03     VARCHAR(40),   /*  父菜式的LineID ,空无父菜式 ,
                                   如果 >0 证明该品种是套餐内容或品种的小费，

                                        >0 and RESERVE02=4 时代表相撞的品种LineID(***停用 lzm modify 2010-09-18***)
                                        >0 and RESERVE02=5 时代表大单分账的品种LineID(***停用 lzm modify 2010-09-18***)
                               */
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Openfood品种
                               11-IC卡充值(系统保留)
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价(****与MIDETAIL不通****)
                               15-房价(****与MIDETAIL不通****)
                               16-VIP卡修改消费金额(系统保留) 2009-4-9
                               17- ***20100615停止使用(用存储过程代替)***(A+B送C中 属于送C的品种 lzm add 【2009-05-05】)
                               18-手写单
                               19-拼上做法
                               20-拼上品种
                               21-茶位等
                               */
  RESERVE05     VARCHAR(40),   /*  OpenFood的逻辑打印机的名称*/
  RESERVE11     VARCHAR(250),   /*  4维菜式参数 1维 */
  RESERVE12     VARCHAR(250),   /*  4维菜式参数 2维 */
  RESERVE13     VARCHAR(250),   /*  4维菜式参数 3维 */
  RESERVE14     VARCHAR(250),   /*  4维菜式参数 4维 */
  RESERVE15     VARCHAR(40),   /* ------没有使用------【之前用于:折扣ID】  */
  RESERVE16     VARCHAR(40),   /*用于"入单"时的"印单",                         */
                               /*  入单时暂时设置RESERVE16=cNotSendTag,                */
                               /*  印单时查找RESERVE16=cNotSendTag的记录打印,  */
                               /*  入单后设置RESERVE16=NULL                        */
  RESERVE17     VARCHAR(250),  /* 品种的原始名词(改于:2008-1-10),用于出报表
                                【之前用于：RESERVE17是否已经计算入sumery的标志,记录Reopen已void的标记
                                  1:已将void的菜式update入sales_sumery
                                 】
                              */
  RESERVE18     VARCHAR(40),  /*记录 K */
  RESERVE19     VARCHAR(40),  /*记录入单的时间如  15:25
                                没入单前作为临时标记使用0，1
                              */
  RESERVE20     VARCHAR(40),  /* 对于prn_chkdetail在打印服务器被用于判断总单是否需要删除相同名称的记录(0=普通品种 1=拼上的品种 2=多份打印的品种) lzm modify 2010-10-13

                                (停用20020815)记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为1[ID],ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)
                                (停用20020702)记录该菜式是打印到哪里:WATERBAR;KICHEN1;KICHEN2,NOTPRINT等等
                              */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,         /* [提酒] 记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为ID,ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)  herman 20020812*/
  RESERVE21     VARCHAR(40),     /*        记录会员卡卡号,与RESERVE20相关  herman 20020812*/
  RESERVE22     VARCHAR(10),     /* [提酒] 卡号购买时间  herman 20020812*/
  RESERVE23     VARCHAR(40),     /* 1.记录该菜式送给谁的,如:玫瑰花送给哪位小姐*/
                                 /* 2.如果AFEMPID不为空或0, 则记录该技师的服务类别:1="点钟",2="普通钟",3="CALL钟"*/
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  RESERVE24     VARCHAR(240),         /*记录点菜人的名字*/
  RESERVE25     VARCHAR(40),          /*用于"叫起" [空值=按原来的方式打印; 0=叫起(未入单前); 1=起叫(入单后);  起叫后,Clear该值]*/
  RESERVE11_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 1维名称(本地语言) */
  RESERVE12_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 2维名称(本地语言) */
  RESERVE13_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 3维名称(本地语言) */
  RESERVE14_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 4维名称(本地语言) */
  SPID  INTEGER,                             /*品种时段参数,所属时间段编号(SERVICEPERIOD), 1~48个时间段(老的时段报表需要该数据)*/
  TPID  INTEGER,                             /*四维时段参数*/
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,    /*附加信息的金额*/
  ADDININFO    VARCHAR(40) DEFAULT '',       /*附加信息的信息*/
  BARCODE VARCHAR(40),                       /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑拿开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑拿结束计时时间*/
  AFEMPID INTEGER,                           /*桑拿技师ID; 0或空=没有技师。*/
  TEMPENDTIME TIMESTAMP,                     /*桑拿预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*桑拿点该品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',      /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑拿技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                      /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成
                                               如果有多个编号则用分号";"分隔,代表该品种的提成由相应的员工平分
                                             */
  HANDCARDNUM  VARCHAR(40),                  /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                  /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,           /*折扣凹度*/
                                             /*1=来源折扣表格(DISCOUNT)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  SERCHARGELIDU INTEGER,           /*服务费凹度*/
                                             /*1=来源服务费表格(SERCHARGE)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  DISCOUNTORG   NUMERIC(15, 3),    /*折扣来源*/
                                             /*当DISCOUNTLIDU=1时:记录折扣编号*/
                                             /*当DISCOUNTLIDU=2时:记录金额*/
                                             /*当DISCOUNTLIDU=3时:记录百分比*/
  SERCHARGEORG  NUMERIC(15, 3),    /*服务费来源*/
                                             /*当SERCHARGELIDU=1时:记录折扣编号*/
                                             /*当SERCHARGELIDU=2时:记录金额*/
                                             /*当SERCHARGELIDU=3时:记录百分比*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                /*记录套餐父品种名称 用于打印和出报表*/
  TCMINAME_LANGUAGE      VARCHAR(100),       /*记录套餐父品种英文名称 用于打印*/
  AMOUNTSORG    NUMERIC(15,3),               /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  TIMECOUNTS    NUMERIC(15,4),  /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),  /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /* 计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /* 用于照片时:单位价格对于的面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /* 用于照片时:总面积*/
  FAMILGID      INTEGER,          /*辅助分类2 系统规定:-10=台号*/
  MAJORGID      INTEGER,          /*辅助分类1*/
  DEPARTMENTID  INTEGER,          /*所属部门编号 系统规定:-10=台号(房价部门)*/
  AMOUNTORGPER  NUMERIC(15, 3),   /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*计量单位2数量(用于记录海鲜的条数等) lzm add 2009-08-14*/

  KOUTTIME      TIMESTAMP,        /*厨房地喱出单(划单)时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房出单(划单)的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      serial,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 2=通过分单转台*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称(***撞餐优惠折扣没有做***) lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE ANALYZE_CHKDETAIL_EXT  /*点菜的附加信息表*/
(
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  CHKDETAIL_LINEID  INTEGER NOT NULL, /*对应CHKDETAIL的LINEID*/
  MENUITEMID    INTEGER,              /*附加信息对应的品种编号*/
  ANAME         VARCHAR(100),         /*附加信息名称*/
  ANAME_LANGUAGE  VARCHAR(100),
  COUNTS        NUMERIC(15, 3),       /*数量*/
  AMOUNTS       NUMERIC(15, 3),       /*金额=COUNTS.TIMECOUNTS*单价 */
  AMTDISCOUNT   NUMERIC(15, 3),       /*折扣*/
  AMTSERCHARGE  NUMERIC(15, 3),       /*服务费*/
  AMTTAX        NUMERIC(15, 3),       /*税  之前是VARCHAR(40)*/
  ISVOID        INTEGER,              /* ***停用，因为通过查询CHKDETAIL可以知道ISVOID的状态
                                       是否已取消
                                       cNotVOID = 0;
                                       cVOID = 1;
                                       cVOIDObject = 2;
                                       cVOIDObjectNotServiceTotal = 3;
                                      */
  RESERVE2      INTEGER DEFAULT 0,    /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,            /*保存销售数据的日期*/
  RESERVE04     VARCHAR(40),   /*  菜式种类-与CHKDETAIL的RESERVE04相同
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Open品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价
                               15-房价
                               16-VIP卡修改消费金额(系统保留) 2009-4-9
                               17- ***20100615停止使用(用存储过程代替)***(A+B送C中 属于送C的品种 lzm add 【2009-05-05】)
                               18-手写单
                               19-拼上
                               */
  COST  NUMERIC(15, 3),          /*附加信息自己的原材料成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,
  FAMILGID      INTEGER,           /*辅助分类1*/
  MAJORGID      INTEGER,           /*辅助分类2*/
  DEPARTMENTID  INTEGER,           /*所属部门编号*/
  AMOUNTSORG    NUMERIC(15,3),     /* ***停用 记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  AMOUNTSLDU    INTEGER DEFAULT 0, /*0或1=扣减, 2=补差价*/
  AMOUNTSTYP    VARCHAR(10),       /*百分比或金额(10%=减10%,10=减10元,-10%=加10%,-10=加10元)*/
  ADDEMPID INTEGER DEFAULT -1,     /*添加附加信息的员工编号,如果授权则记录授权人的编号*/
  ADDEMPNAME    VARCHAR(40),       /*添加附加信息的员工名称,如果授权则记录授权人的名称*/
  AMOUNTPERCENT VARCHAR(10),       /*用于进销存的扣原材料(例如:附加信息为"大份",加10%价格)
                                     当 =数值   时:记录每单位价格
                                        =百分比 时:记录跟父品种价格的每单位百分比*/
  COSTPERCENT   VARCHAR(10),       /*当 =数值   时:记录每单位成本价格
                                        =百分比 时:记录成本跟父品种价格的每单位百分比*/
  KICKBACKPERCENT VARCHAR(10),     /*当 =数值   时:记录每单位提成价格
                                        =百分比 时:记录提成跟父品种价格的每单位百分比*/
  MICOST  NUMERIC(15, 3),          /*附加信息对应的"品种原材料"成本*/
  ITEMTAX2      NUMERIC(15, 3),    /*品种税2*/
  ITEMTYPE    INTEGER DEFAULT 1,   /*lzm add 【2009-05-25】
                                     1=做法一
                                     2=做法二
                                     3=做法三
                                     4=做法四
                                     ..
                                     9=做法9
                                     10=介绍人提成 //lzm add 【2009-06-08】
                                     11=服务员提成 //lzm add 【2009-06-10】
                                     12=吧女提成 //lzm add 【2009-06-10】
                                   */
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ADDOTHERINFO  VARCHAR(40),      /*记录 赠送 或 损耗 (用于出部门和辅助分类的赠送或损耗) lzm add 2010-05-31*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PERCOUNT      NUMERIC(15, 3) DEFAULT 0,   /*每份品种对于的附加信息数量(例如用于记录时价数量) lzm add 2010-11-24
                                              例如:品种的数量=2,附加信息的PERCOUNT=1.4,所以该附加信息的数量COUNTS=1.4*2=2.8
                                            */
  WEB_GROUPID   INTEGER DEFAULT 0,  /*附加信息组号 lzm add 2011-08-11*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, LINEID)
);

CREATE TABLE ANALYZE_CHECKOPLOG  /*账单详细操作记录表*/
(
  CHECKID     INTEGER NOT NULL,          /*对应的账单编号 =0代表无对应的账单*/
  CHKLINEID   INTEGER NOT NULL,          /*对应的账单详细LINEID =0代表无对应的账单详细*/
  RESERVE3    TIMESTAMP NOT NULL,        /*对应的账单所属日期*/
  Y           INTEGER DEFAULT 2001 NOT NULL,
  M           INTEGER DEFAULT 1 NOT NULL,
  D           INTEGER DEFAULT 1 NOT NULL,
  PCID        VARCHAR(40) DEFAULT 'A' NOT NULL,   /*店编号*/
  SHOPID      VARCHAR(40) DEFAULT '' NOT NULL,
  OPID        INTEGER NOT NULL,                   /*操作LINEID*/
  OPEMPID     INTEGER,          /*员工编号*/
  OPEMPNAME   VARCHAR(40),      /*员工名称*/
  OPTIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),        /*操作的时间*/
  OPMODEID    INTEGER,          /*操作类型
                                 1=折扣处理(没做)(用于报表的统计lzm add 2010-06-14)
                                 2=修改价格(没做)
                                 3=修改数量(没做)
                                 4=打印报表(没做)
                                 5= ***20100615停止使用(用存储过程代替)***(A+B送C的操作)
                                */
  OPNAME      VARCHAR(100),     /*操作详细名称*/
  OPAMOUNT1   NUMERIC(15,3) DEFAULT 0,    /*操作之前的数量或金额或折扣*/
  OPAMOUNT2   NUMERIC(15,3) DEFAULT 0,    /*操作之后的数量或金额或折扣*/
  OPMEMO      VARCHAR(200),     /*操作说明*/
  OPPCID      VARCHAR(40),      /*操作所在的机器编号*/
  OPANUMBER   INTEGER,          /*操作的子号  lzm add 2010-04-15*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, PCID, Y, M, D, CHECKID, CHKLINEID, OPID)
);

CREATE TABLE PRN_CHECKS /*用于厨房打印 结构同CHECKS*/
(
  PRNID         INTEGER NOT NULL,  /*打印队列编号*/
  PRNTIME       TIMESTAMP,         /*入单时间*/
  PRNWORKTIME   TIMESTAMP,         /*打印处理时间 用于处理失败后更新这个时间,使之排列到后面*/
  PRNPCNO       VARCHAR(40),       /*终端名称*/
  PRNPREVIEW    INTEGER DEFAULT 0, /*是否需要预览 0=不需要预览 和 设置的打印单状态是1(即:DOCMAIN表的DOCSATE) 1=现在需要打印
                                                  1=需要预览 和 设置的打印单状态是0(即:DOCMAIN表的DOCSATE) 1=现在需要打印

                                                  【以下是用于结账内的入单】
                                                  2=不需要预览 和 设置的打印单状态是0(即:DOCMAIN表的DOCSATE) 0=新打印单
                                                  3=需要预览 和 设置的打印单状态是0(即:DOCMAIN表的DOCSATE) 0=新打印单
                                                  */
  PRNSTATUS     INTEGER DEFAULT 0, /*处理状态 0=新的帐单 1=正在处理 2=处理成功 3=处理成功但没找到打印内容 4=现需要处理 5=打印超时 10=处理失败 */
  PRNDOCTYPE    INTEGER DEFAULT 1, /*0=报表和杂项
                                     1=厨房打印(催单,厨房单)
                                     2=转台(从PRN_DOCDETAIL提取打印详细)
                                     3=弹钱箱
                                     4=转台-需要通知出品部(从PRN_CHKDETAIL提取打印详细) //lzm add 2010-09-02
                                     5=打印自定义信息(从PRN_DOCDETAIL提取打印详细) 打印Web的呼叫信息 //lzm add 2012-2-3
                                     6=打印收银单 //lzm add 2017-02-25 11:54:11
                                     7=重量确认打印单  //lzm add 2023-07-05 01:26:28
                                     8=打印点餐二维码  //lzm add 2025-09-16 11:27:08
                                   */
  CHECKID       INTEGER NOT NULL,
  EMPID         INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/
  REFERENCE     VARCHAR(250),       /*外送单的相关信息
                                   如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"
                                   如果MODEID=盘点单，记录盘点的批号
                                   或
                                   用于总部的数据整理：'S1'=按用餐方式合计整天的营业数据到一张帐单*/
  SEVCHGAMT     NUMERIC(15, 3),    /* 自动的服务费(即品种服务费合计)＝SUBTOTAL*PERCENT */
  SUBTOTAL      NUMERIC(15, 3),    /* 合计＝CHECKDETAIL的AAMOUNTS的和 */
  FTOTAL        NUMERIC(15, 3),    /* 应付金额＝SUBTOTAL-DISCOUNT(CHECK+ITEM)+SERVICECHARGE(自动+附加)+税 */
  STIME TIMESTAMP,                 /*开单时间*/
  ETIME TIMESTAMP,                 /*结帐时间*/
  SERVICECHGAPPEND      NUMERIC(15, 3),    /*附加的服务费＝SUBTOTAL*PERCENT (即:单个品种收服务费后 可以再对 品种的合计SUBTOTAL收服务费)*/
  CHECKTOTAL    NUMERIC(15, 3), /*已付款金额*/
  TEXTAPPEND    TEXT,           /*附加信息1(合单分单的信息和折扣信息等等..)*/
  CHECKCLOSED   INTEGER,        /*帐单是否是已结帐单(0:没结 1:已结)*/
  ADJUSTAMOUNT  NUMERIC(15, 3), /*与上单的差额*/
  SPID  INTEGER,                /* 用作记录    服务段:1~48*/
  DISCOUNT      NUMERIC(15, 3), /* 附加的账单折扣=SUBTOTAL*PERCENT (即:单个品种打折后 可以再对 品种的合计SUBTOTAL打折)*/
  INUSE VARCHAR(1) DEFAULT 'F', /*T:正在使用,F:没有使用*/
  LOCKTIME      TIMESTAMP,      /*帐单开始锁定的时间*/
  CASHIERID     INTEGER,        /*收银员编号*/
  ISCARRIEDOVER INTEGER,        /*首次付款方式（记录付款方式的编号，用于“根据付款方式出报表”）*/
  ISADDORSPLIT  INTEGER,        /*不使用*/
  RESERVE1      VARCHAR(40),    /*出单次数*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效单据，1=无效单据【ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)】*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期,如   19990130  ,六位的字符串*/
  RESERVE01     VARCHAR(40),    /*税1合计*/
  RESERVE02     VARCHAR(40),    /*会员卡对应的'EMPID'  不是IDVALUE*/
  RESERVE03     VARCHAR(40),    /*折扣【5种VIP卡和第四种打折方式】: "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]"  N表示nil 【状态:全部为0】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE04     VARCHAR(40),    /*折扣【餐后点饮料、原品续杯、非原品续杯】 "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]" N表示nil 【状态: 纪录0或空:不打折，1：餐后点饮料、2：原品续杯、3：非原品续杯】,【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE05     VARCHAR(40),    /*假帐 1=新的已结单, 由1更新到2=触发数据库触发器进行假帐处理和变为3, 3=处理完毕, 4=ReOpen的单据. (经过DBToFile程序后,由4更新到3,由1更新到2)

                                  对于EXPORT_CHECKS表:1=新的已结单 2=导出到接口库成功 3=生成冲红单到接口成功
                                */
  RESERVE11     VARCHAR(40),    /*jaja 记录预定人使用时Table5相应记录的id值*/
  RESERVE12     VARCHAR(40),    /*记录---挂单---  0或null:不是挂单; 1:挂单*/
  RESERVE13     VARCHAR(40),    /*实收金额*/
  RESERVE14     VARCHAR(40),    /*EMPNAME员工名称*/
  RESERVE15     VARCHAR(40),    /*MODENAME用餐方式名称*/
  RESERVE16     VARCHAR(40),    /*CASHIERNAME收银员名称*/
  RESERVE17     VARCHAR(40),    /*ITEMDISCOUNT品种折扣合计*/
  RESERVE18     VARCHAR(40),    /*上传数据到总部: 0或空=没有上传，1=成功【旧：记录BackUp成功=1】*/
  RESERVE19     VARCHAR(40),    /*上次上传数据到总部的压缩方法【旧：记录MIS成功=1】:
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  10=经过MIME64编码

                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                */
  RESERVE20     VARCHAR(40),    /*帐单类型(20050805)
                                0或空=普通帐单
                                1=IC卡充值
                                2=换礼品扣除会员券或积分(在功能 MinusCouponClickEvent 里设置)
                                3=全VOID单
                                4=餐券入店记录-没做
                                5=从钱箱提取现金的帐单记录
                                */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),   /*团体消费时的格式为(GROUP:组号),
                                 内容是空时为个人消费,
                                 内容是GUID时为记录消费者编号,*/
  RESERVE21     VARCHAR(40),   /*其它价格,用于判断:四维品种 和 1=会员价*/                               /*之前用于保存:老年信息*/
  RESERVE22     VARCHAR(40),   /*VIP卡号【之前用于记录:台号(房间)价格】*/                               /*之前用于保存:中年信息*/
  RESERVE23     VARCHAR(40),   /*台号(房间)名称  当PRNDOCTYPE=4转台单时:保存转台前的台号名称(如:A14-A) */     /*之前用于保存:少年信息*/
  RESERVE24     VARCHAR(40),   /*台号(房间)是否停止计时, 0或空=需要计时, 1=停止计时*/
  RESERVE25     VARCHAR(40),   /*台号(房间)所在的区域 组成: 区域编号A|区域中午名称|区域英文名称*/
  DISCOUNTNAME  TEXT,                  /*折扣名称*/
  PERIODOFTIME  INTEGER DEFAULT 0,            /**/
  STOCKTIME TIMESTAMP,                        /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,                    /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，对应班次表SHIFTTIMEPERIOD*/
  MINPRICE      NUMERIC(15, 3),               /*会员当前账单得到的积分【之前是用于记录:"最低消费"】*/
  CHKDISCOUNTLIDU  INTEGER,                   /*账单折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比
                                                用于计算CHECKDISCOUNT*/
  CHKSEVCHGAMTLIDU INTEGER,                   /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SEVCHGAMT*/
  CHKSERVICECHGAPPENDLIDU INTEGER,            /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SERVICECHGAPPEND*/
  CHKDISCOUNTORG   NUMERIC(15, 3),            /*账单折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),            /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),     /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',       /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                  /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                  /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),               /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),               /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                     /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                  /*机器的注册序列号*/
  SHOPID  VARCHAR(40) DEFAULT '',                        /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工名称 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,     /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (PRNID)
);


CREATE TABLE PRN_CHKDETAIL /*用于厨房打印 结构通CHKDETAIL*/
(
  PRNID         INTEGER NOT NULL,    /*打印队列编号*/
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,             /* -1:ICCARD充值;null:OpenFood; 0:CustomMenuItem; >0的数字:对应菜式*/
  COUNTS        INTEGER,             /*数量*/
  AMOUNTS       NUMERIC(15, 3),      /*金额=(COUNTS.TIMECOUNTS*单价) */
  STMARKER      INTEGER,             /*是否已送厨房 cNotSendToKitchen=0;cHaveSendToKitchen=1*/
  AMTDISCOUNT   NUMERIC(15, 3),      /*品种折扣*/
  ANAME VARCHAR(100),                   /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"*/
  ISVOID        INTEGER,                /*是否已取消
                                          cNotVOID = 0;
                                          cVOID = 1;
                                          cVOIDObject = 2;
                                          cVOIDObjectNotServiceTotal = 3;
                                        */
  VOIDEMPLOYEE  VARCHAR(40),            /*取消该品种的员工*/
  RESERVE1      VARCHAR(40),            /*成本(????好像已停用????)*/
  RESERVE2      INTEGER DEFAULT 0,      /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,              /*保存销售数据的日期*/
  DISCOUNTREASON        VARCHAR(60),    /*折扣原因*/
  RESERVE01     VARCHAR(40),   /*税1*/
  RESERVE02     VARCHAR(40),   /*  纪录0或空:普通、
                                   1:餐后点饮料、
                                   2:原品续杯、
                                   3:非原品续杯 、
                                   4:已计算的相撞优惠品种
                                   5:自动大单分账
                                   6:手动大胆分账*/
  RESERVE03     VARCHAR(40),   /*  父菜式的LineID ,空无父菜式 ,
                                   如果 >0 证明该品种是套餐内容或品种的小费，
                                        >0 and RESERVE02=4 时代表相撞的品种LineID
                                        >0 and RESERVE02=5 时代表大单分账的品种LineID
                               */
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Openfood品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价
                               15-房价
                               */
  RESERVE05     VARCHAR(40),   /*  OpenFood的逻辑打印机的名称*/
  RESERVE11     VARCHAR(250),   /*  4维菜式参数 1维 */
  RESERVE12     VARCHAR(250),   /*  4维菜式参数 2维 */
  RESERVE13     VARCHAR(250),   /*  4维菜式参数 3维 */
  RESERVE14     VARCHAR(250),   /*  4维菜式参数 4维 */
  RESERVE15     VARCHAR(40),   /*  折扣ID  */
  RESERVE16     VARCHAR(40),   /*用于"入单"时的"印单",                         */
                              /*  入单时暂时设置RESERVE16=cNotSendTag,                */
                              /*  印单时查找RESERVE16=cNotSendTag的记录打印,  */
                              /*  入单后设置RESERVE16=NULL                        */
  RESERVE17     VARCHAR(250),  /* 品种的原始名词(改于:2008-1-10),用于出报表
                                【之前用于：RESERVE17是否已经计算入sumery的标志,记录Reopen已void的标记
                                  1:已将void的菜式update入sales_sumery
                                 】
                              */
  RESERVE18     VARCHAR(40),  /*记录 K */
  RESERVE19     VARCHAR(40),  /*记录入单的时间如  15:25
                                没入单前作为临时标记使用0，1
                              */
  RESERVE20     VARCHAR(40),  /*(停用20020815)记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为1[ID],ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)*/
                              /*(停用20020702)记录该菜式是打印到哪里:WATERBAR;KICHEN1;KICHEN2,NOTPRINT等等*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,         /*记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为ID,ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)*/
  RESERVE21     VARCHAR(40),     /*记录会员卡卡号,与RESERVE20相关*/
  RESERVE22     VARCHAR(10),     /*卡号购买时间*/
  RESERVE23     VARCHAR(40),     /* 1.记录该菜式送给谁的,如:玫瑰花送给哪位小姐*/
                                 /* 2.如果AFEMPID不为空或0, 则记录该技师的服务类别:1="点钟",2="普通钟",3="CALL钟"*/
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  RESERVE24     VARCHAR(240),         /*记录点菜人的名字*/
  RESERVE25     VARCHAR(40),          /*用于"叫起" [空值=按原来的方式打印; 0=叫起(未入单前); 1=起叫(入单后);  起叫后,Clear该值]*/
  RESERVE11_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 1维名称(本地语言) */
  RESERVE12_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 2维名称(本地语言) */
  RESERVE13_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 3维名称(本地语言) */
  RESERVE14_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 4维名称(本地语言) */
  SPID  INTEGER,                             /*品种时段参数,所属时间段编号(SERVICEPERIOD), 1~48个时间段(老的时段报表需要该数据)*/
  TPID  INTEGER,                             /*四维时段参数*/
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,    /*附加信息的金额*/
  ADDININFO    VARCHAR(40) DEFAULT '',       /*附加信息的信息*/
  BARCODE VARCHAR(40),                       /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑拿开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑拿结束计时时间*/
  AFEMPID INTEGER,                           /*桑拿技师ID; 0或空=没有技师。*/
  TEMPENDTIME TIMESTAMP,                     /*桑拿预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*桑拿点该品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',      /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑拿技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                      /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成
                                               如果有多个编号则用分号";"分隔,代表该品种的提成由相应的员工平分
                                             */
  HANDCARDNUM  VARCHAR(40),                  /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                  /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,           /*折扣凹度*/
                                             /*1=来源折扣表格(DISCOUNT)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  SERCHARGELIDU INTEGER,           /*服务费凹度*/
                                             /*1=来源服务费表格(SERCHARGE)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  DISCOUNTORG   NUMERIC(15, 3),    /*折扣来源*/
                                             /*当DISCOUNTLIDU=1时:记录折扣编号*/
                                             /*当DISCOUNTLIDU=2时:记录金额*/
                                             /*当DISCOUNTLIDU=3时:记录百分比*/
  SERCHARGEORG  NUMERIC(15, 3),    /*服务费来源*/
                                             /*当SERCHARGELIDU=1时:记录折扣编号*/
                                             /*当SERCHARGELIDU=2时:记录金额*/
                                             /*当SERCHARGELIDU=3时:记录百分比*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                /*记录套餐父品种名称*/
  TCMINAME_LANGUAGE      VARCHAR(100),       /*记录套餐父品种英文名称*/
  AMOUNTSORG    NUMERIC(15,3),               /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  TIMECOUNTS    NUMERIC(15,4),  /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),  /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,          /*辅助分类2 系统规定:-10=台号*/
  MAJORGID      INTEGER,          /*辅助分类1*/
  DEPARTMENTID  INTEGER,          /*所属部门编号 系统规定:-10=台号*/
  AMOUNTORGPER  NUMERIC(15, 3),   /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '',           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (PRNID, LINEID)
);

CREATE TABLE PRN_WHOLE_CHECKS /*用于厨房打印 结构同CHECKS*/
(
  PRNID         INTEGER NOT NULL,  /*打印队列编号*/
  PRNTIME       TIMESTAMP,         /*入单时间*/
  PRNWORKTIME   TIMESTAMP,         /*打印处理时间 用于处理失败后更新这个时间,使之排列到后面*/
  PRNPCNO       VARCHAR(40),       /*终端名称*/
  PRNPREVIEW    INTEGER DEFAULT 0, /*是否需要预览 0=否 1=是*/
  PRNSTATUS     INTEGER DEFAULT 0, /*处理状态 0=新的帐单 1=正在处理 2=处理成功 3=处理成功但没找到打印内容 10=处理失败*/
  PRNDOCTYPE    INTEGER DEFAULT 1, /*0=报表和杂项 1=帐单相关(催单,厨房单) 2=转台(从PRN_DOCDETAIL提取打印详细) 3=弹钱箱*/

  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/
  REFERENCE     VARCHAR(250),       /*外送单的相关信息
                                   如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"
                                   如果MODEID=盘点单，记录盘点的批号
                                   或
                                   用于总部的数据整理：'S1'=按用餐方式合计整天的营业数据到一张帐单*/
  SEVCHGAMT     NUMERIC(15, 3),    /* 自动的服务费(即品种服务费合计)＝SUBTOTAL*PERCENT */
  SUBTOTAL      NUMERIC(15, 3),    /* 合计＝CHECKDETAIL的AAMOUNTS的和 */
  FTOTAL        NUMERIC(15, 3),    /* 应付金额＝SUBTOTAL-DISCOUNT(CHECK+ITEM)+SERVICECHARGE(自动+附加)+税 */
  STIME TIMESTAMP,                 /*开单时间*/
  ETIME TIMESTAMP,                 /*结帐时间*/
  SERVICECHGAPPEND      NUMERIC(15, 3),    /*附加的服务费＝SUBTOTAL*PERCENT (即:单个品种收服务费后 可以再对 品种的合计SUBTOTAL收服务费)*/
  CHECKTOTAL    NUMERIC(15, 3), /*已付款金额*/
  TEXTAPPEND    TEXT,           /*附加信息1(合单分单的信息和折扣信息等等..)*/
  CHECKCLOSED   INTEGER,        /*帐单是否是已结帐单(0:没结 1:已结)*/
  ADJUSTAMOUNT  NUMERIC(15, 3), /*与上单的差额*/
  SPID  INTEGER,                /* 用作记录    服务段:1~48*/
  DISCOUNT      NUMERIC(15, 3), /* 附加的账单折扣=SUBTOTAL*PERCENT (即:单个品种打折后 可以再对 品种的合计SUBTOTAL打折)*/
  INUSE VARCHAR(1) DEFAULT 'F', /*T:正在使用,F:没有使用*/
  LOCKTIME      TIMESTAMP,      /*帐单开始锁定的时间*/
  CASHIERID     INTEGER,        /*收银员编号*/
  ISCARRIEDOVER INTEGER,        /*首次付款方式（记录付款方式的编号，用于“根据付款方式出报表”）*/
  ISADDORSPLIT  INTEGER,        /*不使用*/
  RESERVE1      VARCHAR(40),    /*出单次数*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效单据，1=无效单据【ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)】*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期,如   19990130  ,六位的字符串*/
  RESERVE01     VARCHAR(40),    /*税1合计*/
  RESERVE02     VARCHAR(40),    /*会员卡对应的'EMPID'  不是IDVALUE*/
  RESERVE03     VARCHAR(40),    /*折扣【5种VIP卡和第四种打折方式】: "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]"  N表示nil 【状态:全部为0】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE04     VARCHAR(40),    /*折扣【餐后点饮料、原品续杯、非原品续杯】 "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]" N表示nil 【状态: 纪录0或空:不打折，1：餐后点饮料、2：原品续杯、3：非原品续杯】,【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE05     VARCHAR(40),    /*假帐 1=新的已结单, 由1更新到2=触发数据库触发器进行假帐处理和变为3, 3=处理完毕, 4=ReOpen的单据. (经过DBToFile程序后,由4更新到3,由1更新到2)

                                  对于EXPORT_CHECKS表:1=新的已结单 2=导出到接口库成功 3=生成冲红单到接口成功
                                */
  RESERVE11     VARCHAR(40),    /*jaja 记录预定人使用时Table5相应记录的id值*/
  RESERVE12     VARCHAR(40),    /*记录---挂单---  0或null:不是挂单; 1:挂单*/
  RESERVE13     VARCHAR(40),    /*实收金额*/
  RESERVE14     VARCHAR(40),    /*EMPNAME员工名称*/
  RESERVE15     VARCHAR(40),    /*MODENAME用餐方式名称*/
  RESERVE16     VARCHAR(40),    /*CASHIERNAME收银员名称*/
  RESERVE17     VARCHAR(40),    /*ITEMDISCOUNT品种折扣合计*/
  RESERVE18     VARCHAR(40),    /*上传数据到总部: 0或空=没有上传，1=成功【旧：记录BackUp成功=1】*/
  RESERVE19     VARCHAR(40),    /*上次上传数据到总部的压缩方法【旧：记录MIS成功=1】:
                                  空=之前没有上传过数据,
                                  0=普通的ZLib,
                                  1=VclZip里面的Zlib,
                                  2=VclZip里面的zip,
                                  3=不压缩,
                                  10=经过MIME64编码

                                  12=经过MIME64编码 和 VclZip里面的zip压缩
                                */
  RESERVE20     VARCHAR(40),    /*帐单类型(20050805)
                                0或空=普通帐单
                                1=IC卡充值
                                2=换礼品扣除会员券或积分(在功能 MinusCouponClickEvent 里设置)
                                3=全VOID单
                                4=餐券入店记录-没做
                                5=从钱箱提取现金的帐单记录
                                */
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),   /*团体消费时的格式为(GROUP:组号),
                                 内容是空时为个人消费,
                                 内容是GUID时为记录消费者编号,*/
  RESERVE21     VARCHAR(40),   /*其它价格,用于判断:四维品种 和 1=会员价*/       /*老年*/
  RESERVE22     VARCHAR(40),   /*VIP卡号【之前用于记录:台号(房间)价格】*/         /*中年*/
  RESERVE23     VARCHAR(40),   /*台号(房间)名称*/                               /*少年*/
  RESERVE24     VARCHAR(40),   /*台号(房间)是否停止计时, 0或空=需要计时, 1=停止计时*/
  RESERVE25     VARCHAR(40),   /*台号(房间)所在的区域 组成: 区域编号A|区域中午名称|区域英文名称*/
  DISCOUNTNAME  TEXT,                  /*折扣名称*/
  PERIODOFTIME  INTEGER DEFAULT 0,            /**/
  STOCKTIME TIMESTAMP,                        /*所属期初库存的时间编号*/
  CHECKID_NUMBER  INTEGER,                    /*帐单顺序号*/
  ADDORSPLIT_REFERENCE VARCHAR(254) DEFAULT '',  /*合并或分单的相关信息,合单时记录合单的台号(台号+台号+..)*/
  HANDCARDNUM  VARCHAR(40),                      /*对应的手牌号码*/
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，对应班次表SHIFTTIMEPERIOD*/
  MINPRICE      NUMERIC(15, 3),               /*会员当前账单得到的积分【之前是用于记录:"最低消费"】*/
  CHKDISCOUNTLIDU  INTEGER,                   /*账单折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比
                                                用于计算CHECKDISCOUNT*/
  CHKSEVCHGAMTLIDU INTEGER,                   /*自动服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SEVCHGAMT*/
  CHKSERVICECHGAPPENDLIDU INTEGER,            /*附加服务费凹度 1=来自服务费表格(SERCHARGE),2=OPEN金额,3=OPEN百分比
                                                用于计算SERVICECHGAPPEND*/
  CHKDISCOUNTORG   NUMERIC(15, 3),            /*账单折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),            /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),     /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',       /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                  /* ***原始单号 lzm modify 2009-06-05 【之前是：最低消费TFX的标志  T:F:X: 是否"不打折","免服务费","不收税"】*/
  THETABLE_TFX  VARCHAR(20),                  /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),               /* ***参与积分的消费金额 lzm modify 2009-08-11 【之前是：房间折扣】*/
  AMOUNTCHARGE  NUMERIC(15, 3),               /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                     /*用于记录每次PDA通讯的GUID,判断上次已入单成功*/
  PCSERIALCODE VARCHAR(100),                  /*机器的注册序列号*/
  SHOPID  VARCHAR(40) DEFAULT '',                        /*店编号*/
  ITEMTOTALTAX1 NUMERIC(15, 3),               /*品种税1*/
  CHECKTAX1 NUMERIC(15, 3),                   /*账单税1*/
  ITEMTOTALTAX2 NUMERIC(15, 3),               /*品种税2*/
  CHECKTAX2 NUMERIC(15, 3),                   /*账单税2*/
  TOTALTAX2 NUMERIC(15, 3),                   /*税2合计*/

  /*以下是用于预订台用的*/
  ORDERTIME TIMESTAMP,           /*预订时间*/
  TABLECOUNT    INTEGER,         /*席数*/
  TABLENAMES    VARCHAR(254),    /*具体的台号。。。。。*/
  ORDERTYPE     INTEGER,         /*0:普通    1:婚宴  2:寿宴   3:其他 */
  ORDERMENNEY NUMERIC(15, 3),    /*定金*/
  CHECKGUID  VARCHAR(100),       /*GUID*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分 lzm add 2009-07-14*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分 lzm add 2009-07-14*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空 lzm add 2009-07-28*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序 lzm add 2010-01-15*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间 lzm add 2010-01-15*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果 lzm add 2010-04-20*/
  BILLASSIGNTO  VARCHAR(40),          /*账单负责人姓名(用于折扣,赠送和签帐的授权) lzm add 2010-06-13*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工姓名 lzm add 2010-06-16*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*全单项目折扣的员工姓名 lzm add 2010-06-16*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单附加折扣的原因 lzm add 2010-06-17*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*品种折扣名称 lzm add 2010-06-18*/

  /*以下是用于预订台用的*/
  ORDEREXT1 text,             /*预定扩展信息(固定长度):预定人数[3位] lzm add 2010-08-06*/
  ORDERDEMO text,             /*预定备注 lzm add 2010-08-06*/

  PT_TOTAL NUMERIC(12, 2),                      /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔 lzm add 2010-12-23*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数 lzm add 2010-12-23*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额 lzm add 2010-12-23*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折 lzm add 2011-04-11*/
  WEBBILLS     INTEGER DEFAULT 0,     /*来自web的账单数 lzm add 2011-04-11*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折 lzm add 2011-03-18*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称 lzm add 2011-05-20*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称 lzm add 2011-05-31*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分 lzm add 2011-07-12*/
  VIPOTHERS     VARCHAR(100),          /*用逗号分隔
                                        位置1=积分折现余额
                                        位置2=当日消费累计积分
                                        例如:"100,20" 代表:积分折现=100 当日消费累计积分=20
                                        lzm add 2011-07-20*/
  ABUYERNAME   VARCHAR(50),            /*会员名称 lzm add 2011-08-02*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3 lzm add 2011-10-12*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧 lzm add 2011-10-13*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单的用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号) lzm add 2012-12-12*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差 lzm add 2013-10-09*/
  LOGTIME TIMESTAMP,                   /*LOG的时间 lzm add 2013-10-10*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 超市接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,       /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三 */
  CHKSTATUS integer default 0,         /*没有启动 账单状态 0=点单 1=等待用户付款(已印收银单) lzm add 2015-06-30*/

  USER_ID INTEGER DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐 lzm add 2016-01-28)*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡 lzm add 2016-06-03 09:56:55
                                                     0=普通员工磁卡
                                                     1=高级员工磁卡（有打折功能）
                                                     2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                                                     3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                                                     4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                                                     6=微信会员卡 //lzm add 2016-05-28 10:22:20
                                                     */
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额 lzm add 2017-01-16 13:54:30*/

  REOPENED INTEGER DEFAULT 0,             /*是否反结账 0=否 1=是 lzm add 2017-08-30 00:09:29*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}] lzm add 2017-09-11 04:34:43*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额 lzm add 2017-09-14 00:24:37*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (PRNID)
);


CREATE TABLE PRN_WHOLE_CHKDETAIL /*用于厨房打印 结构通CHKDETAIL*/
(
  PRNID         INTEGER NOT NULL,    /*打印队列编号*/
  CHECKID       INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  MENUITEMID    INTEGER,             /* -1:ICCARD充值;null:OpenFood; 0:CustomMenuItem; >0的数字:对应菜式*/
  COUNTS        INTEGER,             /*数量*/
  AMOUNTS       NUMERIC(15, 3),      /*金额=(COUNTS.TIMECOUNTS*单价) */
  STMARKER      INTEGER,             /*是否已送厨房 cNotSendToKitchen=0;cHaveSendToKitchen=1*/
  AMTDISCOUNT   NUMERIC(15, 3),      /*品种折扣*/
  ANAME VARCHAR(100),                   /*如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000"*/
  ISVOID        INTEGER,                /*是否已取消
                                          cNotVOID = 0;
                                          cVOID = 1;
                                          cVOIDObject = 2;
                                          cVOIDObjectNotServiceTotal = 3;
                                        */
  VOIDEMPLOYEE  VARCHAR(40),            /*取消该品种的员工*/
  RESERVE1      VARCHAR(40),            /*成本(????好像已停用????)*/
  RESERVE2      INTEGER DEFAULT 0,      /*ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)*/
  RESERVE3      TIMESTAMP,              /*保存销售数据的日期*/
  DISCOUNTREASON        VARCHAR(60),    /*折扣原因*/
  RESERVE01     VARCHAR(40),   /*税1*/
  RESERVE02     VARCHAR(40),   /*  纪录0或空:普通、
                                   1:餐后点饮料、
                                   2:原品续杯、
                                   3:非原品续杯 、
                                   4:已计算的相撞优惠品种
                                   5:自动大单分账
                                   6:手动大胆分账*/
  RESERVE03     VARCHAR(40),   /*  父菜式的LineID ,空无父菜式 ,
                                   如果 >0 证明该品种是套餐内容或品种的小费，
                                        >0 and RESERVE02=4 时代表相撞的品种LineID
                                        >0 and RESERVE02=5 时代表大单分账的品种LineID
                               */
  RESERVE04     VARCHAR(40),   /*  菜式种类
                                0-主菜
                                1-配菜
                                2-饮料
                                3-套餐
                                4-说明信息
                                5-其他,
                                6-小费,
                                7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                8-普通服务项
                                9-最低消费
                               10-Openfood品种
                               11-IC卡充值
                               12-其它类型品种
                               13-礼品(需要用会员券汇换)
                               14-最低消费的差价
                               15-房价
                               */
  RESERVE05     VARCHAR(40),   /*  OpenFood的逻辑打印机的名称*/
  RESERVE11     VARCHAR(250),   /*  4维菜式参数 1维 */
  RESERVE12     VARCHAR(250),   /*  4维菜式参数 2维 */
  RESERVE13     VARCHAR(250),   /*  4维菜式参数 3维 */
  RESERVE14     VARCHAR(250),   /*  4维菜式参数 4维 */
  RESERVE15     VARCHAR(40),   /*  折扣ID  */
  RESERVE16     VARCHAR(40),   /*用于"入单"时的"印单",                         */
                              /*  入单时暂时设置RESERVE16=cNotSendTag,                */
                              /*  印单时查找RESERVE16=cNotSendTag的记录打印,  */
                              /*  入单后设置RESERVE16=NULL                        */
  RESERVE17     VARCHAR(250),  /* 品种的原始名词(改于:2008-1-10),用于出报表
                                【之前用于：RESERVE17是否已经计算入sumery的标志,记录Reopen已void的标记
                                  1:已将void的菜式update入sales_sumery
                                 】
                              */
  RESERVE18     VARCHAR(40),  /*记录 K */
  RESERVE19     VARCHAR(40),  /*记录入单的时间如  15:25
                                没入单前作为临时标记使用0，1
                              */
  RESERVE20     VARCHAR(40),  /*(停用20020815)记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为1[ID],ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)*/
                              /*(停用20020702)记录该菜式是打印到哪里:WATERBAR;KICHEN1;KICHEN2,NOTPRINT等等*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  VIPMIID       INTEGER,         /*记录该菜式为会员卡从VIP_MENUITEM里扣的,标记为ID,ID=(MenuItemID)or(-MICLASSID)or(-arg_MAJORGID)*/
  RESERVE21     VARCHAR(40),     /*记录会员卡卡号,与RESERVE20相关*/
  RESERVE22     VARCHAR(10),     /*卡号购买时间*/
  RESERVE23     VARCHAR(40),     /* 1.记录该菜式送给谁的,如:玫瑰花送给哪位小姐*/
                                 /* 2.如果AFEMPID不为空或0, 则记录该技师的服务类别:1="点钟",2="普通钟",3="CALL钟"*/
  ANAME_LANGUAGE        VARCHAR(100),
  COST  NUMERIC(15, 3),          /*成本*/
  KICKBACK      NUMERIC(15, 3),  /*提成*/
  RESERVE24     VARCHAR(240),         /*记录点菜人的名字*/
  RESERVE25     VARCHAR(40),          /*用于"叫起" [空值=按原来的方式打印; 0=叫起(未入单前); 1=起叫(入单后);  起叫后,Clear该值]*/
  RESERVE11_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 1维名称(本地语言) */
  RESERVE12_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 2维名称(本地语言) */
  RESERVE13_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 3维名称(本地语言) */
  RESERVE14_LANGUAGE    VARCHAR(250),  /*  4维菜式参数 4维名称(本地语言) */
  SPID  INTEGER,                             /*品种时段参数,所属时间段编号(SERVICEPERIOD), 1~48个时间段(老的时段报表需要该数据)*/
  TPID  INTEGER,                             /*四维时段参数*/
  ADDINPRICE    NUMERIC(15, 3) DEFAULT 0,    /*附加信息的金额*/
  ADDININFO    VARCHAR(40) DEFAULT '',       /*附加信息的信息*/
  BARCODE VARCHAR(40),                       /*条码*/
  BEGINTIME TIMESTAMP,                       /*桑拿开始计时时间*/
  ENDTIME TIMESTAMP,                         /*桑拿结束计时时间*/
  AFEMPID INTEGER,                           /*桑拿技师ID; 0或空=没有技师。*/
  TEMPENDTIME TIMESTAMP,                     /*桑拿预约结束计时时间*/
  ATABLESUBID INTEGER DEFAULT 1,             /*桑拿点该品种的子台号编号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '',      /*逻辑打印机*/
  MODEID INTEGER DEFAULT 0,                  /*用餐方式*/
  ADDEMPID INTEGER DEFAULT -1,               /*添加附加信息的员工编号*/
  AFEMPNOTWORKING INTEGER DEFAULT 0,         /*桑拿技师工作状态.0=正常,1=提前下钟*/
  WEITERID VARCHAR(40),                      /*服务员、技师或吧女的EMPID,对应EMPLOYESS的EMPID,设计期初是为了出服务员或吧女的提成
                                               如果有多个编号则用分号";"分隔,代表该品种的提成由相应的员工平分
                                             */
  HANDCARDNUM  VARCHAR(40),                  /*对应的手牌号码*/
  VOIDREASON  VARCHAR(200),                  /*VOID取消该品种的原因*/
  DISCOUNTLIDU  INTEGER,           /*折扣凹度*/
                                             /*1=来源折扣表格(DISCOUNT)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  SERCHARGELIDU INTEGER,           /*服务费凹度*/
                                             /*1=来源服务费表格(SERCHARGE)*/
                                             /*2=OPEN金额*/
                                             /*3=OPEN百分比*/
  DISCOUNTORG   NUMERIC(15, 3),    /*折扣来源*/
                                             /*当DISCOUNTLIDU=1时:记录折扣编号*/
                                             /*当DISCOUNTLIDU=2时:记录金额*/
                                             /*当DISCOUNTLIDU=3时:记录百分比*/
  SERCHARGEORG  NUMERIC(15, 3),    /*服务费来源*/
                                             /*当SERCHARGELIDU=1时:记录折扣编号*/
                                             /*当SERCHARGELIDU=2时:记录金额*/
                                             /*当SERCHARGELIDU=3时:记录百分比*/
  AMTSERCHARGE  NUMERIC(15, 3),              /*品种服务费*/
  TCMIPRICE     NUMERIC(15, 3),              /*记录套餐内容的价格-用于统计套餐内容的利润*/
  TCMEMUITEMID  INTEGER,                     /*记录套餐父品种编号*/
  TCMINAME      VARCHAR(100),                /*记录套餐父品种名称*/
  TCMINAME_LANGUAGE      VARCHAR(100),       /*记录套餐父品种英文名称*/
  AMOUNTSORG    NUMERIC(15,3),               /*记录该品种的原始价格，用于VOID相撞的优惠价格时恢复原价格，和报表的送计算*/
  TIMECOUNTS    NUMERIC(15,4),  /*数量的小数部分(扩展数量)*/
  TIMEPRICE     NUMERIC(15,3),  /*时价品种单价*/
  TIMESUMPRICE  NUMERIC(15,3),               /*赠送或损耗金额 lzm modify【2009-06-01】*/
  TIMECOUNTUNIT INTEGER DEFAULT 1,           /*计算单位 1=数量, 2=厘米, 3=寸*/
  UNITAREA      NUMERIC(15,4) DEFAULT 0,     /*单价面积*/
  SUMAREA       NUMERIC(15,4) DEFAULT 0,     /*总面积*/
  FAMILGID      INTEGER,          /*辅助分类2 系统规定:-10=台号*/
  MAJORGID      INTEGER,          /*辅助分类1*/
  DEPARTMENTID  INTEGER,          /*所属部门编号 系统规定:-10=台号*/
  AMOUNTORGPER  NUMERIC(15, 3),   /*每单位的原始价格*/
  AMTCOST       NUMERIC(15, 3),   /*总成本*/
  ITEMTAX2      NUMERIC(15, 3),   /*品种税2*/
  OTHERCODE     VARCHAR(40),      /*其它编码 例如:SAP的ItemCode*/
  COUNTS_OTHER  NUMERIC(15, 3),   /*辅助数量 lzm add 2009-08-14*/
  KOUTTIME      TIMESTAMP,        /*厨房地喱划单时间 lzm add 2010-01-11*/
  KOUTCOUNTS    NUMERIC(15,3) DEFAULT 0,    /*厨房划单的数量 lzm add 2010-01-11*/
  KOUTEMPNAME   VARCHAR(40),      /*厨房出单(划单)的员工名称 lzm add 2010-01-13*/
  KINTIME       TIMESTAMP,        /*以日期格式保存的入单时间 lzm add 2010-01-13*/
  KPRNNAME      VARCHAR(40),      /*实际要打印到厨房的逻辑打印机名称 lzm add 2010-01-13*/
  PCNAME        VARCHAR(200),      /*点单的终端名称 lzm add 2010-01-13*/
  KOUTCODE      INTEGER,           /*厨房划单的条码打印*/
  KOUTPROCESS   INTEGER DEFAULT 0, /*0=普通 1=已被转台 3=*/
  KOUTMEMO      VARCHAR(100),     /*厨房划单的备注(和序号条码一起打印),例如:转台等信息*/
  KEXTCODE      VARCHAR(20),      /*辅助号(和材料一起送到厨房的木夹号)lzm add 2010-02-24*/
  PARENTCLASSNAME VARCHAR(40),    /*对应的父类别名称 lzm add 2010-04-26*/
  UNIT1NAME     VARCHAR(20),      /*计量单位名称 lzm add 2010-05-24*/
  UNIT2NAME     VARCHAR(20),      /*计量单位2名称 lzm add 2010-05-24*/
  ISVIPPRICE    INTEGER DEFAULT 0,    /*0=不是会员价 1=是会员价 lzm add 2010-06-13*/
  DISCOUNTEMP   VARCHAR(20),      /*折扣人名称 lzm add 2010-06-15*/
  ADDEMPNAME    VARCHAR(40),      /*添加附加信息在员工名称 lzm add 2010-06-20*/
  VIPNUM        VARCHAR(40),      /*VIP卡号 lzm add 2010-08-23*/
  VIPPOINTS     NUMERIC(15, 3) DEFAULT 0,   /*扣除的VIP积分 lzm add 2010-08-23*/
  PT_PATH       REAL[][],         /*用于折扣优惠 simon 2010-09-06*/
  PT_COUNT      NUMERIC(12, 2),             /*用于折扣优惠 simon 2010-09-06*/
  SPLITPLINEID  INTEGER DEFAULT 0,          /*用于记录分账的父品种LINEID lzm add 2010-09-19*/
  ADDINFOTYPE   INTEGER DEFAULT 0,          /*附加信息所属的菜式种类,对应MIDETAIL的RESERVE04 lzm add 2010-10-12*/
  AFNUM         VARCHAR(40),                /*技师编号(不是EMPID) lzm add 2011-05-20*/
  AFPNAME       VARCHAR(40),                /*技师名称 lzm add 2011-05-20*/
  PAYMENT       INTEGER DEFAULT 0,          /*付款批次 0=没付款 >0=已付款批次 lzm add 2011-07-28*/
  PAYMENTEMP    VARCHAR(40),                /*付款人名称 lzm add 2011-9-28*/
  ITEMISADD     INTEGER DEFAULT 0,          /*是否是加菜 0或空=否 1=是 lzm add 2012-04-16*/
  PRESENTSTR    VARCHAR(40),                /*用于记录招待的(逗号分隔) EMPCLASSID,EMPID,PRESENTCTYPE lzm add 2012-12-07*/
  CFKOUTTIME    TIMESTAMP,        /*厨房划单时间(用于厨房划2次单) lzm add 2014-8-22*/
  KOUTTIMES     TEXT,             /*厨房地喱划单时间              用于一个品种显示一行 lzm add 2014-9-4*/
  CFKOUTTIMES   TEXT,             /*厨房划单时间(用于厨房划2次单) 用于一个品种显示一行 lzm add 2014-9-4*/
  ISNEWBILL     INTEGER DEFAULT 0,  /*是否新单 用于厨房划单 lzm add 2014-9-5*/
  --KOUTCOUNTS    NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/
  CFKOUTCOUNTS  NUMERIC(15, 3) DEFAULT 0,     /*厨房划单时间(用于厨房划2次单) lzm add 2014-9-4*/

  USER_ID INTEGER DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '',           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"} lzm add 2015-12-19*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',             /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部 lzm add 2015-12-20*/
  BOM TEXT,                              /*物料清单，例如：10002,牛肉,斤,1,总仓;10203,凉瓜,两,2.3,总仓 lzm add 2016-10-04 18:51:55*/

  FAMILGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类2 名称 系统规定:-10=台号 lzm add 2017-08-30 00:13:21*/
  MAJORGNAME      VARCHAR(40) DEFAULT '',          /*辅助分类1 名称 lzm add 2017-08-30 00:13:21*/
  DEPARTMENTNAME  VARCHAR(40) DEFAULT '',          /*所属部门编号 名称 系统规定:-10=台号(房价部门) lzm add 2017-08-30 00:13:21*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间 lzm add 2015-09-17*/

  OTHERCODE_TRANSFER INTEGER DEFAULT 0,            /*其它编码(ERP)是否已同步 lzm add 2019-01-25 02:14:15*/
  ODOOCODE VARCHAR(40),                            /*odoo编码 lzm add 2019-05-16 02:29:04*/
  ODOOCODE_TRANSFER INTEGER DEFAULT 0,             /*odoo编码是否已同步 lzm add 2019-05-16 02:29:12*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  PRIMARY KEY (PRNID, LINEID)
);

CREATE TABLE PRN_DOC    /*要打印的文档*/
(
  PRNID         INTEGER NOT NULL,  /*打印队列编号*/
  PRNMODELFILE  VARCHAR(200),      /*模板文件名(不带路径)*/
  PRNLANGUAGE   VARCHAR(20),       /*模板语言*/
  PRNPRINTTYPE  VARCHAR(20),       /*打印机类型*/
  LOGICPRNNAME  VARCHAR(40),       /*对应的打印机 lzm add 2011-10-10*/
  PRIMARY KEY (PRNID)
);

CREATE TABLE PRN_DOCDETAIL    /*要打印文档的内容*/
(
  PRNID         INTEGER NOT NULL,  /*打印队列编号*/
  PRNVARID      INTEGER,           /*变量编号*/
  PRNVARLINEID  INTEGER,           /*变量的行编号*/
  PRNVARCONT    VARCHAR(200),      /*变量的内容*/
  PRIMARY KEY (PRNID, PRNVARID, PRNVARLINEID)
);

CREATE TABLE PDA_IN_MSG    /*PDA传送过PC的信息 lzm add 2011-04-21*/
(
  MSGGUID       VARCHAR(40),          /*用于PDA端入单失败后重新入单的问题,区分是否是同一信息*/
  MSGTYPE       INTEGER DEFAULT 0,    /*信息类型 1=入单*/
  MSGCONTENT    TEXT,                 /*信息内容*/
  MSGPROCESS    INTEGER DEFAULT 0,    /*是否已提取并处理 0=没处理 1=已处理*/
  MSGITIME      TIMESTAMP DEFAULT date_trunc('second', NOW()),  /*信息写入时间*/
  MSGPTIME      TIMESTAMP DEFAULT NULL,   /*信息已提取并处理时间*/
  MSGEMP        VARCHAR(40),          /*信息发送人名称*/
  PDA_NO        VARCHAR(20),          /*PDA编号*/
  PDA_IP        VARCHAR(20),          /*PDA的IP地址*/
  PRNPCNO       VARCHAR(40),          /*要处理该信息的打印单所在的机器名称*/
  PRIMARY KEY (MSGGUID)
);

CREATE TABLE POINTS2MONEY  /*积分兑换金额转换表 lzm add 2011-07-05*/
(
  POINTS_S          INTEGER NOT NULL,       /*可用积分开始范围*/
  POINTS_E          INTEGER NOT NULL,       /*可用积分结束范围*/
  CONVER_RATE       VARCHAR(10) NOT NULL,   /*积分转金额比率*/
  MONEY_S           INTEGER,                /*可兑换金额开始范围(用于比较和查看)*/
  MONEY_E           INTEGER,                /*可兑换金额结束范围(用于比较和查看)*/
  MONEY_PER_POINTS  VARCHAR(20),            /*每分折算金额(用于比较和查看)*/
  REMARK            VARCHAR(100),           /*备注*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,POINTS_S, POINTS_E, CONVER_RATE)
);

--start---------------Android 的表-------------------------

CREATE TABLE WPOS_SYSTEM /*简单设置表>>>用在Android 手机 lzm add 2011-09-23*/
(
  SZBH     TEXT NOT NULL,    /*编号*/
  SZMC     TEXT,    /*名称*/
  NR       TEXT,    /*内容*/
  FCOMMENT TEXT,    /*备注 lzm add 2012-12-18*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,SZBH)
);
/*
WPOS_SYSTEM		可以用于设置税率和服务费计算规则
					tax_ratetype=inamount or addtoamount

					tax_rate1=数字%  税率百分比
					tax_rate2=数字%;数字%...  税率百分比   多重税率
					可以设置多个税率名称，然后跟vip连接，就知道该vip对应的税率情况		//解决根据客户收入水平，决定税率

					servicefee=数字%    //基本服务费
					servicefee1=数字%
					servicefee2=数字%
					可以设置多个服务费名称，然后跟餐台连接，就能决定哪个餐区的餐台使用不同的服务费收费

下面
st_table_system
    map.put("szbh", "");  //设置编号
    map.put("szmc", "");  //设置名称
    map.put("nr", "");  //设置内容



("szmc","nr")
    //老版本没有参数，设置一些缺省参数
    wpos_function_map.put("m0","1");//"点单"
    wpos_function_map.put("m1","1");//"退单"
    wpos_function_map.put("m2","1");//"催单"
    wpos_function_map.put("m3","0");//"转菜"
    wpos_function_map.put("m4","1");//"修改人数"
    wpos_function_map.put("m5","0");//"赠送"
    wpos_function_map.put("m6","0");//"招待"
    wpos_function_map.put("m7","0");//"重量确认"
    wpos_function_map.put("m8","0");//"划单"
    wpos_function_map.put("m9","1");//"账单查询"
    wpos_function_map.put("m10","0");//"上菜"
    wpos_function_map.put("m11","0");//"预订模块"
    wpos_function_map.put("m12","0");//"沽清管理模块"
    wpos_function_map.put("m13","1");//"开换并台模块"
    wpos_function_map.put("m14","1");//"餐台状态模块"
    wpos_function_map.put("m15","0");//"付款模块"
    wpos_function_map.put("m16","0");//"合单"
    wpos_function_map.put("m17","0");//"拆单"
    wpos_function_map.put("m18","0");//"会员查询"
    wpos_function_map.put("m19","0");//"消息通知"
    wpos_function_map.put("m20","0");//"修改密码"
    wpos_function_map.put("m11-0","1");//"全部预订"
    wpos_function_map.put("m11-1","1");//"餐台预订"
    wpos_function_map.put("m11-2","1");//"预订开台"
    wpos_function_map.put("m11-3","1");//"预订"
    wpos_function_map.put("m12-0","1");//"存量"
    wpos_function_map.put("m12-1","1");//"沽清"
    wpos_function_map.put("m12-2","1");//"取消沽清"
    wpos_function_map.put("m12-3","1");//"沽清列表"
    wpos_function_map.put("m13-0","1");//"开台"
    wpos_function_map.put("m13-1","1");//"换台"
    wpos_function_map.put("m13-2","0");//"并台"
    wpos_function_map.put("m13-3","0");//"取消并台"
    wpos_function_map.put("m13-4","0");//"清台"
    wpos_function_map.put("m14-0","1");//"餐台状态"
    wpos_function_map.put("m14-1","0");//"空台汇总"
    wpos_function_map.put("m14-2","1");//"餐区空台"
    wpos_function_map.put("m14-3","1");//"空台"
    wpos_function_map.put("m15-0","1");//"预付款"
    wpos_function_map.put("m15-1","1");//"会员优惠"
    wpos_function_map.put("m15-2","1");//"权限折扣"
    wpos_function_map.put("m15-3","1");//"打印账单"
    wpos_function_map.put("m15-4","1");//"埋单"
    wpos_function_map.put("m15-5","1");//"请求结账"
    wpos_function_map.put("m15-6","1");//"付款"
*/


CREATE TABLE WPOS_ENTERTAIN   /*(没做)招待表>>>用在Android 手机 lzm add 2011-09-23*/
(
  JH     TEXT NOT NULL,  /*wpos机号*/
  MAC    TEXT,  /*wpos mac地址*/
  BH     TEXT NOT NULL,  /*菜式编号*/
  SL     TEXT,  /*数量*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,JH,BH)
);

--lzm 停用该表 改成 从systempara提取 取消原因 2011-10-09
CREATE TABLE WPOS_RETREAT   /*退菜理由表>>>用在Android 手机 lzm add 2011-09-23*/
(
  BH     TEXT NOT NULL,  /*退菜理由编号*/
  MC     TEXT,  /*退菜理由名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,BH)
);

/*该表已经不使用，我用midetail中miclassid=2的midetail来代替，但是表要保留，我没删除下载设置数据的代码，如果删除，会出错*/
CREATE TABLE WPOS_REQUEST   /*客人要求表>>>用在Android 手机 lzm add 2011-09-23*/
(
  BH     TEXT NOT NULL,  /*编号*/
  MC     TEXT,  /*名称*/
  CJJE   TEXT,  /*差价金额:(10%,-100%,10,-10)*/
  CYSL   TEXT,  /*差价是否需要乘以数量*/
  ZJM    TEXT,  /*助记码*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,BH)
);

CREATE TABLE WPOS_DREC    /*(没做)推荐菜品类别表>>>用在Android 手机 lzm add 2011-09-23*/
(
  TJCPBH     TEXT NOT NULL,  /*推荐菜品类别编号*/
  TJCPMC     TEXT,  /*推荐菜品类别名称*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TJCPBH)
);

CREATE TABLE WPOS_DRECD   /*推荐菜品内容表>>>用在Android 手机 lzm add 2011-09-23*/
(
  TJCPBH   TEXT NOT NULL,  /*推荐菜品类别编号*/
  CPBH     TEXT NOT NULL,  /*菜品编号*/
  SL       TEXT,  /*数量，限量推荐*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TJCPBH,CPBH)
);

CREATE TABLE MI_RULES     /*规则表>>>用在Android 手机 lzm add 2011-09-23*/
(
  BH     TEXT NOT NULL,  /**/
  MC     TEXT,  /**/
  NR     TEXT,  /**/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,BH)
);
/*MI_RULES表

		vip=vip卡号;vip卡号('any'表示任意的VIP),tablearea=A;B;C,dinemode=堂食;外卖,timeperiod=HH:MM~HH:MM,weekperiod=1;3;5,dateperiod=YYYY-MM-DD~YYYYY-MM-DD,price=数字或者balanceprice=数字
		menuitem=菜式ID01;菜式ID02...,option	,repeat	,vip=vip卡号;vip卡号('any'表示任意的VIP),tablearea=A;B;C,dinemode=堂食;外卖,timeperiod=HH:MM~HH:MM,weekperiod=1;3;5,dateperiod=YYYY-MM-DD~YYYYY-MM-DD,price=数字或者balanceprice=数字
		menuclass=-类别ID,option,repeat	,vip=vip卡号;vip卡号('any'表示任意的VIP),tablearea=A;B;C,dinemode=堂食;外卖,timeperiod=HH:MM~HH:MM,weekperiod=1;3;5,dateperiod=YYYY-MM-DD~YYYYY-MM-DD,price=数字 或者balanceprice=数字
		menureportclass=--辅助类别ID	,option	,repeat,vip=vip卡号;vip卡号('any'表示任意的VIP),tablearea=A;B;C,dinemode=堂食;外卖,timeperiod=HH:MM~HH:MM,weekperiod=1;3;5,dateperiod=YYYY-MM-DD~YYYYY-MM-DD,price=数字或者balanceprice=数字

		property=菜式ID01,vip=vip卡号;vip卡号('any'表示任意的VIP),tablearea=A;B;C,dinemode=堂食;外卖,timeperiod=HH:MM~HH:MM,weekperiod=1;3;5,dateperiod=YYYY-MM-DD~YYYYY-MM-DD,price=数字或者balanceprice=数字

*/

CREATE TABLE DB_VERSION /*数据库表格的版本,数据同步需要 >>>用在Android 手机 lzm add 2011-09-23*/
(
  TABLE_NUMBER TEXT NOT NULL,
  BB TEXT,      /*点菜王同步数据需要查询的版本号 通过[6,671]人工运行函数wpos_db_version_sync() 和函数wpos_initdata_db_version()从BBORI复制版本号到BB*/
  BBORI  TEXT,  /*电脑修改相应的表后的版本号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  bb_gen_mi_gz TEXT,    /*产生规则时的 版本号 lzm add 2018-04-15 18:20:20*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TABLE_NUMBER)
);

--执行版本更新时，自动更新规则表和生成系统定义的菜式（类别=1和类别=2的菜式）
CREATE TRIGGER db_version_tri AFTER UPDATE ON db_version  EXECUTE PROCEDURE db_version_tri();

insert into db_version values('1','2');   /*表名1.菜品表*/
insert into db_version values('2','2');   /*表名2.菜品类别表*/
insert into db_version values('3','2');   /*表名3.菜品辅助类别表*/
insert into db_version values('4','2');   /*表名4.推荐菜品类别表*/
insert into db_version values('5','2');   /*表名5.推荐菜品内容表*/
insert into db_version values('6','2');   /*表名6.餐台表*/
insert into db_version values('7','2');   /*表名7.客户要求表*/
insert into db_version values('8','2');   /*表名8.退菜理由表*/
insert into db_version values('9','2');   /*表名9.优惠类别*/
insert into db_version values('10','2');   /*表名10.优惠规则*/
insert into db_version values('11','2');   /*表名11.招待表*/
insert into db_version values('12','2');   /*表名12.简单设置表*/
insert into db_version values('13','2');   /*表名13.会员表*/
insert into db_version values('14','2');   /*表名14.折扣表*/
insert into db_version values('15','2');   /*表名15.付款方式表*/
insert into db_version values('16','2');   /*表名16.餐区表*/
insert into db_version values('17','2');   /*表名17.部门表*/
insert into db_version values('18','2');   /*表名18.员工表*/
insert into db_version values('19','2');   /*表名19.规则表*/
insert into db_version values('20','2');   /*表名20.沽清表*/

/*优惠类别（类别名称-->对应的所有品种名称）*/
CREATE TABLE PREFERENCIAL_TREATMENT_CLASS /*优惠类别(蓝鸟) lzm add 2011-09-23*/
(
  ID serial NOT NULL,
  CLASSNAME text DEFAULT '',
  MENUITEMNAME_DEFINE text DEFAULT '',

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  CONSTRAINT PREFERENCIAL_TREATMENT_CLASS_pkey PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);

/*
10;"新品";"巧克力北海道;爱尔兰咖啡;蓝莓金字塔;草莓金字塔;摩卡咖啡卷;蓝莓满福;一窝蜂;阿扁;黑糖糕;花生包;美式薄片;椰香蔓越莓;芋金香;蒜香起士;潜水艇;夏之雪;蓝山咖啡;芝士火腿;杂量蜜红豆;蓝莓乳酪;青葱包;雪藏草莓;培根蛋卷;三色面包;黑钻巧克力;美式咖喱;韩国泡菜"
11;"外带饮料";"美式咖啡(中);特调冰咖啡(中);拿铁咖啡(冰)(中);拿铁咖啡(热)(中);卡布基诺(冰)(中);卡布基诺(热)(中);焦糖玛琪朵(冰)(中);焦糖玛琪朵(热)(中);巧克力冰摩卡(中);抹茶拿铁冰咖啡;台湾珍珠奶茶(冰)(大);台湾珍珠奶茶(热)(大);鲜草蜜奶茶（大）;番茄健康醋饮（大）;冬瓜仙草乌龙茶（大）;鲜芒果绿茶（大）;碳陪乌龙拿铁（大）;梅子果醋绿茶（大）;梅子绿茶(热);梅子红茶(热);冬瓜柠檬桔(大);百香果红茶(大);百香果绿茶(大);养乐多红茶(大);养乐多绿茶(大);台湾爱玉柠檬冰茶(大);冰镇洛神花茶(大);泰式柠檬绿茶(大);梅子绿茶(冰);梅子红茶(冰);新鲜芒果冰沙（大）;恋爱冰沙（大）;花生冰沙（大）;新鲜草莓冰沙（大）;摩卡冰沙（大）"
12;"单品蛋糕";"枕头蛋糕;戚风蛋糕;黑枣核桃糕;桂圆糕;草莓甜心;橘香甜心;挪威森林;香芋大理石;巧克力大理石;抹茶大理石;松露巧克力;皇后乳酪球;摩卡咖啡卷;蓝莓满福;一窝蜂;阿扁;黑糖糕;巧克力北海道;爱尔兰咖啡;蓝莓金字塔;草莓金字塔;特制乳酪;巧克力旋風;聖馬克;摩卡咖啡;什錦水果長條;杏仁咖啡;櫻桃乳酪;黑森林條;魔鬼長條;抹茶蛋糕條;藍莓乳酪;特制乳酪(第二个);花生大福(麻薯);红豆大福(麻薯);养生布丁;乳酪塔;泡芙;重乳酪;黑森林;栗子;蓝莓乳酪;提拉米苏;抹茶蛋糕;极品巧克力瑞士卷;白雪公主;乳酪条(蓝莓味);乳酪条(芒果味);乳酪条(原味);圆形乳酪;枫糖布丁;纽约起士;北海道蛋糕杯;轻乳酪;覆盆子慕斯;蒙布朗片;香芒芝士慕斯;美國泥巴;櫻桃芝士;優格芝士;巧克力慕斯;泡芙盒;轻乳酪优惠价;轻乳酪特惠价;优格草莓杯;巧克力泡芙;香橙香芒泡芙;香橙香芒泡芙（盒）;巧克力泡芙（盒）;原味泡芙盒;新泡芙;焦糖布丁;提拉米蘇（草莓）;巧克力树;天使慕斯;栗子玛隆;宇治金时;蓝莓欧蕾;芒果森巴;秀可拉丁;樱桃白兰地;火山豆巧克力;草莓牛奶;巧克力山;摩卡巧克力;栗子芒果;巧克力乳加丁"
13;"A";"甜甜圈;白巧克力甜甜圈;黑巧克力甜甜圈"
14;"B";"法国魔杖;大蒜面包;杂粮黑麦;北欧坚果;红豆杂粮;奶酥蜀麦;南瓜杂粮;原味杂粮;起司核桃"
15;"C";"丹麦蓝莓;丹麦哈士;丹麦肉松;丹麦小牛角;富士山;丹麦芝士鲔鱼;丹麦土司;丹麦起司火腿;丹麦芋泥;丹麦小热狗;丹麦热狗;丹麦香肠;丹麦红豆卷;丹麦红豆;丹麦小热狗"
16;"红标";"鲜奶吐司5片;全麦吐司;葡萄吐司;芋香吐司;椰奶吐司;菠萝吐司;全麦枫糖吐司;杂粮核桃吐司;鲜奶吐司8片;厚片全麦吐司;厚片鲜奶吐司;红萝卜吐司"
17;"绿标";"巧克力菊花酥;起酥蛋糕;菊花小餅;意大利脆饼(原味);意大利脆饼(巧克力);紅茶曲奇;蕉糖牛油曲奇;巧克力果仁瓦片;核桃曲奇;輩翠小西餅;巧克力雪球;花生曲奇;杏仁脆胼;麥片提子曲奇;可可杏仁曲奇;椰子圈;抹茶杏仁曲奇;杏仁瓦片;瓜仁瓦片;小樱桃芝士;小优格芝士;小日本粟子塔;小咖啡慕斯;小枫糖果仁塔;小提拉米苏;小水果塔;小芒果乳酪;小巧克力脆饼;小樱桃芝士;小优格芝士;小日本粟子塔;小咖啡慕斯;小枫糖果仁塔;小提拉米苏;小红莓;小水果塔;小芒果乳酪;小巧克力脆饼"
18;"特价区产品";"原味波堤;彩米白巧波堤;彩米黑巧波堤;彩米草莓波堤;彩米檸檬波堤;杏仁白巧波堤;杏仁黑巧波堤;夏威夷豆白巧波堤;夏威夷豆黑巧波堤"
20;"ABC";"大亨纯鲜牛奶;乳酸菌奶;草莓果酱;大酸梅汤;小酸梅汤;法國汽水;滋寶純淨水;大卡士奶;小卡士奶;卡士奶（原味）;卡士奶（草莓）;多美洲方粒奶酪;太陽神純淨水;丘比藍莓醬170g;丘比什錦醬170g;丘比沙拉醬200g;光明奶粒6粒/包;樂天青梅汁;樂天富足2%桃飲料;安佳牛油粒10粒/包;四季寶巧克力花生醬;四季寶花生小醬;永和米漿;統一蜜豆奶（雞蛋）;統一蜜豆奶（草莓）;雀巢鷹嘜煉奶巧克力味;雀巢鷹嘜煉奶草莓味;即品拿铁3合1;即品拿铁2合1;法式香草咖啡;焦糖玛琪朵;奶精球;藍山咖啡豆;意大利咖啡豆;曼特寧咖啡豆;巴西咖啡豆;大维记牛奶;小维记牛奶;都乐苹果汁;都乐葡萄汁;都乐橙汁;咖啡糖包;安佳牛油;四季宝小酱;统一(鸡蛋);统一(草莓);雀巢(巧克力);雀巢(草莓);都乐鲜橙汁;T:速溶咖啡买三送一;牛奶加两元送面包;纯天然果酱"
*/


CREATE TABLE PREFERENCIAL_TREATMENT_RULES /*优惠规则(蓝鸟) lzm add 2011-09-23*/
(
  ID serial NOT NULL,
		--类名1;类名2;类名3...
		--    {hh:mm~hhmm;total=浮点数;disc=数字或者数字%}
		--    {hh:mm~hhmm;num=整数;disc=数字或者数字%}
		--    {hh:mm~hhmm;next;disc=数字或者数字%}
		--    {hh:mm~hhmm;three;disc=数字或者数字%}
		--    {hh:mm~hhmm;类名1 price>=current;disc=数字或者数字%}
		--    {hh:mm~hhmm;类名1+类名2+类名3...;disc=数字或者数字%}
  RULE_DEFINE text DEFAULT '',
  RULE_MSG text DEFAULT '',

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  CONSTRAINT PREFERENCIAL_TREATMENT_RULES_pkey PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,ID)
);
/*
13;"B{A;disc=2}";"买A加2元得B"
14;"新品{total=20.9;disc=3}";"消费满20元，加3元得新品"
15;"A{num=5;disc=1}";"买5个A，加1元多得一个A"
16;"ABC{ABC price>=current;disc=0}";"ABC买1送1（送等价或低价）"
17;"特价区产品{12:00~15:00;特价区产品;disc=0}";"12:00~15:00特价区产品买1送1"
18;"红标{外带饮料;disc=80%}";"买外带饮料，红标8折"
19;"绿标{外带饮料;disc=80%}";"买外带饮料，绿标8折"
20;"单品蛋糕{外带饮料;disc=80%}";"买外带饮料，单品蛋糕8折"
21;"红标{绿标;disc=80%}";"买绿标，红标8折"
22;"绿标{红标;disc=80%}";"买红标，绿标8折"
23;"A+B+C+红标+绿标+单品蛋糕{charge>=100;present=20}";"充值100送价值20元产品"
24;"B{next;disc=5}";"B产品，再买一个5元"
25;"B{three;disc=3}";"B产品，第三个3元"
*/


CREATE TABLE WPOS_COMMAND_HISTORY /*点菜机发送过来的历史命令 >>>用在Android 手机 lzm add 2011-09-23*/
(
  COMMANDSTR TEXT NOT NULL,           /*命令内容*/
  ITIME TIMESTAMP DEFAULT date_trunc('second', now()),      /*命令插入时间 date_trunc('second', CURRENT_TIMESTAMP)*/
  WORKTIME TIMESTAMP,                 /*命令执行时间*/
  PROCESSSTATUS INTEGER DEFAULT 0,    /*命令的执行情况 0=新命令 1=执行成功 2=执行失败 3=超时*/
  PROCESSCOUNT INTEGER DEFAULT 0,     /*命令执行的次数*/
  AFTEROKTRYCOUNT INTEGER DEFAULT 0,  /*命令执行成功后 还继续尝试的次数*/
  LASTERROR TEXT,                     /*最后一次执行错误的原因*/
  RESULTSTR TEXT,                     /*成功执行的返回结果,用于直接返回重复执行的命令*/
  MEMO TEXT,                          /*注解*/
  COMMANDORG TEXT,                    /*原始命令内容(存储过程没执行replace(replace(replace(v_command,E'\r\n','`'),E'\r','`'),E'\n','`')前的内容) lzm add 2012-3-2*/
  USERNAME TEXT,                      /*操作用户 lzm add 2012-3-2*/
  PCID TEXT,                          /*操作机器 lzm add 2012-3-2*/
  CHECKINFO TEXT,                     /*账单信息 lzm add 2012-3-2*/
  SHOPID TEXT NOT NULL DEFAULT '',             /*店编号 lzm add 2012-3-2*/
  USER_ID INTEGER NOT NULL DEFAULT 0,          /*集团号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',   /*店的GUID lzm add 2015-09-17*/
  MCCODE TEXT,                                 /*用于socket门店推送的uuid lzm add 2018-04-11 03:16:24*/
  COMMANDUUID TEXT,                            /*命令的UUID lzm add 2018-04-11 18:08:49*/
  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,COMMANDSTR)
);

CREATE TABLE WPOS_CLIENTLIST /*允许的点菜王CODE lzm add 2011-11-11*/
(
  ID INTEGER NOT NULL,
  CLIENTCODE  VARCHAR(100),
  PRIMARY KEY (ID)
);

CREATE TABLE WPOS_YUN_COMMAND_TOSHOP /*点菜机发送过来需要发送到门店的命令 >>>用在Android 手机 lzm add 2011-09-23*/
(
  ID SERIAL,
  COMMANDSTR TEXT NOT NULL,           /*命令内容*/
  ITIME TIMESTAMP DEFAULT date_trunc('second', now()),      /*命令插入时间 date_trunc('second', CURRENT_TIMESTAMP)*/
  WORKTIME TIMESTAMP,                 /*命令执行时间*/
  PROCESSSTATUS INTEGER DEFAULT 0,    /*命令的执行情况 0=新命令 1=执行成功 2=执行失败 3=超时*/
  PROCESSCOUNT INTEGER DEFAULT 0,     /*命令执行的次数*/
  AFTEROKTRYCOUNT INTEGER DEFAULT 0,  /*命令执行成功后 还继续尝试的次数*/
  LASTERROR TEXT,                     /*最后一次执行错误的原因*/
  RESULTSTR TEXT,                     /*成功执行的返回结果,用于直接返回重复执行的命令*/
  MEMO TEXT,                          /*注解*/
  COMMANDORG TEXT,                    /*原始命令内容(存储过程没执行replace(replace(replace(v_command,E'\r\n','`'),E'\r','`'),E'\n','`')前的内容) lzm add 2012-3-2*/
  USERNAME TEXT,                      /*操作用户 lzm add 2012-3-2*/
  PCID TEXT,                          /*操作机器 lzm add 2012-3-2*/
  CHECKINFO TEXT,                     /*账单信息 lzm add 2012-3-2*/
  SHOPID VARCHAR(40) NOT NULL DEFAULT '',      /*店编号 lzm add 2012-3-2*/
  USER_ID INTEGER NOT NULL DEFAULT 0,          /*集团号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '',   /*店的GUID lzm add 2015-09-17*/
  MCCODE TEXT,                                 /*用于socket门店推送的uuid lzm add 2018-04-11 03:16:24*/
  COMMANDUUID TEXT,                            /*命令的UUID lzm add 2018-04-11 18:08:49*/
  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,COMMANDSTR)
);


CREATE TABLE WPOS_HQRD_DB_VERSION /*数据库表格的版本,数据同步需要 >>>用在Android 手机 lzm add 2011-09-23*/
(
  TABLE_NUMBER TEXT NOT NULL,
  BB TEXT,      /*点菜王同步数据需要查询的版本号 通过[6,671]人工运行函数wpos_initdata_db_version()从BBORI复制版本号到BB*/
  BBORI  TEXT,  /*电脑修改相应的表后的版本号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,TABLE_NUMBER)
);

CREATE TABLE WPOS_HQRD_COMMAND_HISTORY /*点菜机发送过来的历史命令 >>>用在Android 手机 lzm add 2011-09-23*/
(
  COMMANDSTR TEXT NOT NULL,           /*命令内容*/
  ITIME TIMESTAMP DEFAULT date_trunc('second', now()),      /*命令插入时间 date_trunc('second', CURRENT_TIMESTAMP)*/
  WORKTIME TIMESTAMP,                 /*命令执行时间*/
  PROCESSSTATUS INTEGER DEFAULT 0,    /*命令的执行情况 0=新命令 1=执行成功 2=执行失败 3=超时*/
  PROCESSCOUNT INTEGER DEFAULT 0,     /*命令执行的次数*/
  AFTEROKTRYCOUNT INTEGER DEFAULT 0,  /*命令执行成功后 还继续尝试的次数*/
  LASTERROR TEXT,                     /*最后一次执行错误的原因*/
  RESULTSTR TEXT,                     /*成功执行的返回结果,用于直接返回重复执行的命令*/
  MEMO TEXT,                          /*注解*/
  COMMANDORG TEXT,                    /*原始命令内容(存储过程没执行replace(replace(replace(v_command,E'\r\n','`'),E'\r','`'),E'\n','`')前的内容) lzm add 2012-3-2*/
  USERNAME TEXT,                      /*操作用户 lzm add 2012-3-2*/
  PCID TEXT,                          /*操作机器 lzm add 2012-3-2*/
  CHECKINFO TEXT,                     /*账单信息 lzm add 2012-3-2*/
  SHOPID VARCHAR(40),                 /*店编号 lzm add 2012-3-2*/
  USER_ID INTEGER DEFAULT 0,          /*集团号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '',   /*店的GUID lzm add 2015-09-17*/
  PRIMARY KEY (COMMANDSTR)
);

CREATE TABLE WPOS_YP318_CLIENTLIST /*允许的YP318 CODE lzm add 2012-2-22*/
(
  ID INTEGER NOT NULL,
  CLIENTCODE  VARCHAR(100),
  PRIMARY KEY (ID)
);

CREATE TABLE WPOS_YP318_COMMAND_HISTORY /*YP318发送过来的历史命令 lzm add 2012-2-22*/
(
  COMMANDSTR TEXT NOT NULL,           /*命令内容*/
  ITIME TIMESTAMP DEFAULT date_trunc('second', now()),      /*命令插入时间 date_trunc('second', CURRENT_TIMESTAMP)*/
  WORKTIME TIMESTAMP,                 /*命令执行时间*/
  PROCESSSTATUS INTEGER DEFAULT 0,    /*命令的执行情况 0=新命令 1=执行成功 2=执行失败 3=超时*/
  PROCESSCOUNT INTEGER DEFAULT 0,     /*命令执行的次数*/
  AFTEROKTRYCOUNT INTEGER DEFAULT 0,  /*命令执行成功后 还继续尝试的次数*/
  LASTERROR TEXT,                     /*最后一次执行错误的原因*/
  RESULTSTR TEXT,                     /*成功执行的返回结果,用于直接返回重复执行的命令*/
  MEMO TEXT,                          /*注解*/
  COMMANDORG TEXT,                    /*原始命令内容(存储过程没执行replace(replace(replace(v_command,E'\r\n','`'),E'\r','`'),E'\n','`')前的内容) lzm add 2012-3-2*/
  USERNAME TEXT,                      /*操作用户 lzm add 2012-3-2*/
  PCID TEXT,                          /*操作机器 lzm add 2012-3-2*/
  CHECKINFO TEXT,                     /*账单信息 lzm add 2012-3-2*/
  SHOPID TEXT,                        /*店编号 lzm add 2012-3-2*/
  USER_ID INTEGER DEFAULT 0,          /*集团号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '',   /*店的GUID lzm add 2015-09-17*/
  PRIMARY KEY (COMMANDSTR)
);

CREATE TABLE WPOS_BL600_CLIENTLIST /*允许的BL600 CODE lzm add 2012-2-22*/
(
  ID INTEGER NOT NULL,
  CLIENTCODE  VARCHAR(100),
  PRIMARY KEY (ID)
);

CREATE TABLE WPOS_BL600_COMMAND_HISTORY /*BL600发送过来的历史命令 lzm add 2012-2-22*/
(
  COMMANDSTR TEXT NOT NULL,           /*命令内容*/
  ITIME TIMESTAMP DEFAULT date_trunc('second', now()),      /*命令插入时间 date_trunc('second', CURRENT_TIMESTAMP)*/
  WORKTIME TIMESTAMP,                 /*命令成功执行时间*/
  PROCESSSTATUS INTEGER DEFAULT 0,    /*命令的执行情况 0=新命令 1=执行成功 2=执行失败 3=超时*/
  PROCESSCOUNT INTEGER DEFAULT 0,     /*命令执行的次数*/
  AFTEROKTRYCOUNT INTEGER DEFAULT 0,  /*命令执行成功后 还继续尝试的次数*/
  LASTERROR TEXT,                     /*最后一次执行错误的原因*/
  RESULTSTR TEXT,                     /*成功执行的返回结果,用于直接返回重复执行的命令*/
  MEMO TEXT,                          /*注解*/
  COMMANDORG TEXT,                    /*原始命令内容(存储过程没执行replace(replace(replace(v_command,E'\r\n','`'),E'\r','`'),E'\n','`')前的内容) lzm add 2012-3-2*/
  USERNAME TEXT,                      /*操作用户 lzm add 2012-3-2*/
  PCID TEXT,                          /*操作机器 lzm add 2012-3-2*/
  CHECKINFO TEXT,                     /*账单信息 lzm add 2012-3-2*/
  SHOPID TEXT,                        /*店编号 lzm add 2012-3-2*/
  TRYTIME TIMESTAMP,                  /*命令尝试执行时间 lzm add 2014-9-12*/
  USER_ID INTEGER DEFAULT 0,          /*集团号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '',   /*店的GUID lzm add 2015-09-17*/
  PRIMARY KEY (COMMANDSTR,ITIME)
);

CREATE TABLE WPOS_BL600_MACHINELIST /*允许的BL600 Machine CODE lzm add 2012-2-22*/
(
  ID INTEGER NOT NULL,
  MACHINECODE  VARCHAR(100),
  PRIMARY KEY (ID)
);

CREATE TABLE WPOS_BL600_DISH_TXT
(
  BH   TEXT NOT NULL, --编号(5位)、
  LBH  TEXT,          --类别号(2位)、
  ZWMC TEXT,          --中文名称(18位)、
  DJ1  TEXT,          --单价1(8位)、
  DJ2  TEXT,          --单价2(8位) 、
  DJ3  TEXT,          --单价3(8位) 、
  DJ4  TEXT,          --单价4(8位)、
  DW1  TEXT,          --单位1(4位)、
  DW2  TEXT,          --单位2(4位) 、
  DW3  TEXT,          --单位3(4位) 、
  DW4  TEXT,          --单位4(4位)、
  QRZL TEXT,          --重量确认(1位)
  ZF   TEXT,          --作法(30位)、
  ZJM  TEXT,          --助记码(4位)
  PRIMARY KEY(BH)
);

CREATE TABLE WPOS_BL600_DSET_TXT
(
  LBBH  TEXT NOT NULL,  --类别编号(2位)、
  LBMC  TEXT,           --类别名称(10位)
  MENUITEMID INTEGER,   --品种编号
  PRIMARY KEY (LBBH)
);

CREATE TABLE SHOP_CNF
(
  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  DATAID INTEGER NOT NULL,                  /*需要同步的表ID
                                              0=全部
                                              1=员工【***停用】
                                              2=会员卡【***停用】
                                              3=会员信息【***停用】
                                              4=房间(台号)
                                              5=打印机配置【***停用】
                                              6=原材料【***停用】
                                              7=下拉框信息
                                              8=品种
                                              9=假期时段
                                              10=附加信息【***停用】
                                              11=界面布局
                                              12=班次设置
                                              13=部门和辅助分类
                                              14=进销存基本资料【***停用】
                                              15=系统配置信息
                                              16=折扣表
                                              17=服务费表
                                              18=用餐方式
                                              19=付款方式报表跟踪项
                                              20=在云端设置的优惠活动
                                              lzm add 2015-09-17*/
  FROMSHOPID  VARCHAR(40) DEFAULT '',       /*与那个店编号采用相同配置 lzm add 2015-09-16*/

  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  EFFECTIVETIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),    /*生效时间 lzm add 2015-09-17*/

  DOWNLOADED INTEGER DEFAULT 0,             /*数据已下载完成 0=否 1=是*/
  APPLYUPDATE INTEGER DEFAULT 0,            /*是否应用了更新 0=否 1=是*/
  APPLYTIME VARCHAR(30),                    /*更新数据时间*/
  EFFECTIVENOW INTEGER DEFAULT 0,           /*是否现在要更新 0=根据生效时间更新 1=现在更新 lzm add 2018-11-01 00:33:00*/


  PRIMARY KEY(USER_ID,SHOPID,SHOPGUID,DATAID)
);

--start--------------------------------需要同步的品种表-----------------------------------
CREATE TABLE NEW_SHOP_CNF
(
  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  DATAID INTEGER NOT NULL,                  /*需要同步的表ID
                                              0=全部
                                              1=员工【***停用】
                                              2=会员卡【***停用】
                                              3=会员信息【***停用】
                                              4=房间(台号)
                                              5=打印机配置【***停用】
                                              6=原材料【***停用】
                                              7=下拉框信息
                                              8=品种
                                              9=假期时段
                                              10=附加信息【***停用】
                                              11=界面布局
                                              12=班次设置
                                              13=部门和辅助分类
                                              14=进销存基本资料【***停用】
                                              15=系统配置信息
                                              16=折扣表
                                              17=服务费表
                                              18=用餐方式
                                              19=付款方式报表跟踪项
                                              20=在云端设置的优惠活动
                                              lzm add 2015-09-17*/
  FROMSHOPID  VARCHAR(40) DEFAULT '',       /*与那个店编号采用相同配置 lzm add 2015-09-16*/

  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  EFFECTIVETIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),    /*生效时间 lzm add 2015-09-17*/

  DOWNLOADED INTEGER DEFAULT 0,             /*数据已下载完成 0=否 1=是*/
  APPLYUPDATE INTEGER DEFAULT 0,            /*是否应用了更新 0=否 1=是*/
  APPLYTIME VARCHAR(30),                    /*更新数据时间*/
  EFFECTIVENOW INTEGER DEFAULT 0,           /*是否现在要更新 0=根据生效时间更新 1=现在更新 lzm add 2018-11-01 00:33:00*/


  PRIMARY KEY(USER_ID,SHOPID,SHOPGUID,DATAID)
);

/* Table: MICLASS, Owner: SYSDBA */

CREATE TABLE NEW_MICLASS
(
  MICLASSID     INTEGER NOT NULL,
  MICLASSNAME   VARCHAR(100),
  MICLASSDISCOUNT       NUMERIC(15, 3) default 0,  /*类别折扣率%*/
  RESERVE01     VARCHAR(40),  /*按钮模板编号*/
  RESERVE02     VARCHAR(40),  /*关联界面或类别1*/
  RESERVE03     VARCHAR(40),  /*子类或品种的按钮模板编号*/
  RESERVE04     text,
  RESERVE05     VARCHAR(40),
  SORTORDER     INTEGER default 0,
  TOUCHSCRID    INTEGER,
  TOUCHSCRLINEID        INTEGER,
  SIMPLENAME    VARCHAR(100),
  PARENTMICLASS INTEGER,     /*根类别编号*/
  MICLASSNAME_LANGUAGE  VARCHAR(100),
  SIMPLENAME_LANGUAGE   VARCHAR(100),
  TS_TSCHROW    INTEGER,     /*父类别2编号*/
  TS_TSCHCOL    INTEGER,     /*类别属性 0或空=品种类别 1=附加信息*/
  TS_TSCHHEIGHT INTEGER,     /*是否系统保留 0或空=否 1=是*/
  TS_TSCHWIDTH  INTEGER,
  TS_TLEGEND    VARCHAR(100),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(100),
  TS_TSCHFONT   VARCHAR(40) DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,
  TS_TSNEXTSCR  INTEGER,                 /*子类别所在的界面*/
  TS_BALANCEPRICE       NUMERIC(15, 3),
  TS_TSCHCOLOR  VARCHAR(20),
  TS_TSCHFONTCOLOR      VARCHAR(20),
  TS_RESERVE01  VARCHAR(40),    /*不需授权用户类别 lzm add 2010-05-14*/
  TS_RESERVE02  VARCHAR(40),    /*需授权的状态 lzm add 2010-05-14*/
  TS_RESERVE03  VARCHAR(40),
  TS_RESERVE04  VARCHAR(40),
  TS_RESERVE05  VARCHAR(40),
  PICTUREFILE VARCHAR(240),        /*图片文件名称(包括路径)*/
  SUBMITSCHID  INTEGER DEFAULT 0,  /*子品种所在的界面    ****之前:该类别下的类别或品种所在的界面*/
  MICVISIBLED  INTEGER DEFAULT 1,  /*是否可见 0=否,1=是*/
  MAXINPUTMI   INTEGER DEFAULT 1,  /*最多允许键入该类别品种的次数 注意:只对附加信息生效*/
  MININPUTMI   INTEGER DEFAULT 1,  /*最少允许键入该类别品种的次数 注意:只对附加信息生效*/
  CANREPEATEINPUT  INTEGER DEFAULT 0,  /*是否可以重复录入相同的品种,0=false,1=true*/
  WEB_TAG      INTEGER DEFAULT 0,  /*需要同步到web_miclass lzm add 2011-03-30*/
  WEB_NAME     VARCHAR(100),       /*在web_miclass的别名 lzm add 2011-03-30*/
  WEB_FILE     VARCHAR(240),       /*在web_miclass的picturefile lzm add 2011-03-30*/
  WEB_FILE_MOBILE  VARCHAR(240),   /*在web_miclass的picturefile_mobile lzm add 2011-03-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MICLASSID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: MIDETAIL, Owner: SYSDBA */

CREATE TABLE NEW_MIDETAIL
(
  MENUITEMID    INTEGER NOT NULL,
  MICLASSID     INTEGER DEFAULT 0,
  MENUITEMNAME  VARCHAR(100),   /*品种名称*/
  LOGICPRNNAME  VARCHAR(100),   /*逻辑打印机*/
  BCID          INTEGER,
  ANUMBER       INTEGER,
  FAMILGID      INTEGER,        /*辅助分类1*/
  MAJORGID      INTEGER,        /*辅助分类2*/
  MIPRICE       NUMERIC(15, 3), /*价格*/
  PREPCOST      NUMERIC(15, 3) default 0,  /*成本*/
  AMTDISCOUNT   NUMERIC(15, 3) default 0,  /*品种折扣额$*/
  RESERVE01     VARCHAR(40),    /* 是否时价 0:否,1:时价 */
  RESERVE02     VARCHAR(40),    /* 0:eatin  1:delivery  2:takeout  3:eatin for employees*/
  RESERVE03     VARCHAR(40),    /* 优惠价类别,用于两个品种相撞的价格*/
  RESERVE04     VARCHAR(40),    /* 菜式种类
                                   0-普通主菜
                                   1-配菜
                                   2-饮料
                                   3-套餐
                                   4-说明信息
                                   5-其他,
                                   6-小费,
                                   7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                   8-普通服务项
                                   9-最低消费
                                  10-Open品种
                                  11-IC卡充值
                                  12-其它类型品种
                                  13-礼品(需要用会员券汇换)
                                  14-品种连接
                                  15-类别连接
                                  16-
                                  17-
                                  18-手写单 lzm add 2010-03-12
                                  19-拼上做法
                                  20-拼上品种
                                  21-茶位等
                                  22-差价(系统保留)
                                  23-直接修改总积分(系统保留)  //lzm add 2011-08-02
                                  24-直接修改可用积分(系统保留)  //lzm add 2011-08-02
                                  25-积分折现操作(系统保留) //lzm add 2011-08-04
                                  26-VIP卡挂失后退款(系统保留) //lzm add 2012-07-06
                                  27-VIP卡挂失后换卡(系统保留) //lzm add 2012-07-06
                                  28-分[X]席(系统保留) //lzm add 【2012-11-07】
                                  29-计量单位 lzm add 2012-11-17
                                */
  RESERVE05     VARCHAR(40),    /*jaja  【估清】菜式的数量  2001-4-17  -1和空=不限数量 >=0代表现存的品种数量*/
  SORTORDER     INTEGER default 0,      /*排序*/
  TOUCHSCRID    INTEGER,                /*不需要厨房划单 0=需要划单 1=不需要划单 lzm modify 2010-01-16*/
  TOUCHSCRLINEID        INTEGER,        /*不需要打折(与T:有相同的作用,但T:可以不计入最低消费,而这个需要计入最低消费)  lzm modify 2010-01-16*/
  SIMPLENAME    VARCHAR(100),           /*简称*/
  BARCODE       VARCHAR(40),            /*条码*/
  CODE          VARCHAR(40),
  NEEDADDTOTG   INTEGER,                /*是否在报表中出现*/
  COST          NUMERIC(15, 3),         /*成本*/
  KICKBACK      NUMERIC(15, 3),         /*员工提成*/
  MENUITEMNAME_LANGUAGE VARCHAR(100),   /*英语名称*/
  SIMPLENAME_LANGUAGE   VARCHAR(100),   /*简称(一般用于厨房的打印)*/
  ISINFOMENUITEM        INTEGER,        /*是否是附加信息 0或空=否 1=是 */
  BALANCEPRICE  NUMERIC(15, 3),         /*差价*/
  TS_TSCHROW    VARCHAR(40), --INTEGER, /*OtherCode其它编码 例如SAP的物料ItemCode*/
  TS_TSCHCOL    INTEGER,                /*是否隐藏该品种 0或空=不隐藏 1=隐藏*/
  TS_TSCHHEIGHT INTEGER,                /*是否系统保留 0或空=否 1=是*/
  TS_TSCHWIDTH  INTEGER,                /*附加信息价格是否根据数量变化而变化 0=根据数量变化 1=固定加格 lzm add 2009-07-26*/
  TS_TLEGEND    VARCHAR(240),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(240),
  TS_TSCHFONT   VARCHAR(40) DEFAULT 'Arial', --DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,        /*无需积分 0或空=否 1=是 lzm modify 2009-08-11*/
  TS_TSNEXTSCR  INTEGER,                /*对应原材料表Ware的ID编号 lzm modify 2009-08-04*/
  TS_BALANCEPRICE       NUMERIC(15, 3), /*扣除的积分 lzm modify 2010-08-23*/
  TS_TSCHCOLOR  VARCHAR(20),            /*单位2缺省数量 lzm modify 2009-10-10*/
  TS_TSCHFONTCOLOR      VARCHAR(20),    /*是否允许修改时价价格 0或空=跟系统设置 1=允许修改 2=不允许修改 lzm modify 2011-05-04*/
  TS_RESERVE01  VARCHAR(40),     /*计量单位 例如:笼*/
  TS_RESERVE02  VARCHAR(40),     /*辅助单位 例如:颗*/
  TS_RESERVE03  VARCHAR(40),     /*单位比例 例如:4    (代表1笼=4颗牛肉丸)*/
  TS_RESERVE04  VARCHAR(40),     /*账单显示的单位 0=计量单位 1=辅助单位*/
  TS_RESERVE05  VARCHAR(40),     /*计量单位2  例如:条(用于记录海鲜的条数等) lzm add 2009-08-31*/
  NEXTMICLASSID INTEGER,         /*(负数代表类别,整数代表品种或条码)点了该品种后跳动的下一个类别,或
                                     品种编号(如果是品种编号则:指明下一个要消费的品种)
                                     或品种条码(如果是品种条码则:指明下一个要消费的品种)
                                     【注意：如果该品种属于计时的服务项目，则要“开始计时”时才执行以上的动作】
                                 */
  BALANCETYPE  INTEGER,          /*差价的类型 0:直接加减 1:按百分比加减 2=补差价(即:+品种价格减去该差价的值)
                                   3=乘上指定数值 lzm add 2010-10-03*/

  MIFAMOUSBRAND VARCHAR(20),     /*品牌*/
  MICLASSNAME   VARCHAR(20),     /*所属的品种类别名称*/
  MISIZE        VARCHAR(20),     /*尺寸 大中小餐具的属性,用于在前台统计大中小的数量 lzm modify 2012-11-17*/
  MICOLOR       VARCHAR(20),     /*颜色*/
  MIBATCHPRICE  NUMERIC(15, 3),  /*批发价*/
  MISTOCKALARM_UP  INTEGER,      /*库存警告上限*/
  MISTOCKALARM_DOWN  INTEGER,    /*库存警告下限*/
  MITYPENUM     VARCHAR(20),     /*品种型号，服装*/
  MIPRICE_SUM_UNIT NUMERIC(15, 3) DEFAULT 0,        /*品种价格MIPRICE的总单位数量或时长(即:单位价格=MIPRICE_SUM_UNIT / MIPRICE)*/
  MIPRICE_DEFAULTUNIT NUMERIC(15, 3) DEFAULT 0,     /*品种价格MIPRICE的缺省数量或时长*/
  MI_MASSAGE_ADDTIME INTEGER DEFAULT 0,             /*属于按摩加钟,加钟时取上次按摩的技师*/
  MIISGROUP INTEGER DEFAULT 0,         /*属于组品种(即:如果是组品种,则其它与该帐单相同的组号也添加该品种)【桑拿沐足】*/
  BEFOREORDER VARCHAR(40),             /*点击该品种前要执行的命令(这个只能执行指定的命令)*/
  AFTERORDER VARCHAR(40),              /*点击该品种后要执行的命令*/
  NEEDAFEMPID INTEGER DEFAULT 0,       /*是否需要技师 0=不需，1=需要*/
  PICTUREFILE VARCHAR(240),            /*图片文件名称(包括路径)*/
  DEPARTMENTID INTEGER,                /*所属部门编号*/
  MICOUNTWORDS INTEGER,                /*笔划*/
  MIPINYIN   VARCHAR(20),              /*其它名称信息,例如:拼音*/
  DIRECTDEC     INTEGER DEFAULT 0,     /*直接扣减库存 0=否, 1=是*/
  NOTINVOICE   INTEGER DEFAULT 0,      /*不需要在票据中出现(不需在账单打印)*/
  AREASQM    NUMERIC(15, 4) DEFAULT 0, /*面积(平方米)*/
  AREAITEM   INTEGER DEFAULT 0,        /*按面积计算*/
  NOSERTOTALPAPER INTEGER DEFAULT 0,   /*不需要入单纸*/
  COSTPERTCENT VARCHAR(10),            /*成本(原材料) 金额或百分比*/
  ABCID VARCHAR(20),                   /* ***20100615停止使用(用存储过程代替)***(A+B送C的类别编号  lzm add 【2009-05-06】)*/
  NEEDKEXTCODE INTEGER DEFAULT 0,      /*录入品种时需要录入辅助号(木夹号)*/
  ABC_DISCOUNT_MATCH_NUM VARCHAR(40),  /* ***20100917停止使用(用促销组合代替)*** 用于ABC优惠 '1':表示类型A  '2':表示类型B  '3':表示类型C  lzm add 2010-09-02*/
  WEB_TAG      INTEGER DEFAULT 0,      /*需要同步到web_midetail lzm add 2011-03-30*/
  WEB_FILE_S     VARCHAR(240),         /*小图,在web_midetail的picturefile_small lzm add 2011-03-30*/
  WEB_FILE_B     VARCHAR(240),         /*大图,在web_midetail的picturefile_big lzm add 2011-03-30*/
  WEB_FILE_S_MOBILE  VARCHAR(240),     /*手机小图,在web_midetail的picturefile_small_mobile lzm add 2011-03-30*/
  WEB_FILE_B_MOBILE  VARCHAR(240),     /*手机大图,在web_midetail的picturefile_big_mobile lzm add 2011-03-30*/
  WEB_GROUPID     INTEGER DEFAULT 0,   /*附加信息的组号,在web_midetail的groupid lzm add 2011-03-30*/
  WEB_ISHOT       INTEGER DEFAULT 0,   /*热销菜,在web_midetail的isHot lzm add 2011-03-30*/
  WEB_ISSPECIALS  INTEGER DEFAULT 0,   /*特价菜,在web_midetail的isSpecials lzm add 2011-03-30*/
  WEB_MIDESCRIPTION  VARCHAR(240),     /*品种的详细描述 lzm add 2011-03-30*/
  CLASSTYPE  VARCHAR(40) DEFAULT '',   /*所属归类 例如:啤酒 红酒 洋酒 lzm add 2011-08-09*/
  VC_RATE  INTEGER DEFAULT 1,          /*退换的单位比率 lzm add 2011-08-09
                                          如果该品种是"扎"则"单位比率"应该填入"12"
                                          如果该品种是"半扎"则"单位比率"应该填入"6"
                                       */
  VC_ITEM  INTEGER DEFAULT 0,         /*退换的品种编号 lzm add 2011-08-09*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  XGDJ TEXT,    /*是否允许修改单价>>>用在Android 手机 lzm add 2011-09-23*/
  YJ TEXT,      /*>>>用在Android 手机 lzm add 2011-09-23(说明信息如果出现百分比的说明信息，是按照原价计算，还是按照其他说明信息合计之后的总价的百分比来计算)*/
  GZBH VARCHAR(40),    /*指向规则表的规则编号>>>用在Android 手机 lzm add 2011-09-23*/
  SYSCODE VARCHAR(40) DEFAULT '0',   /*>>>用在Android 手机 lzm add 2011-09-23
                              SYSCODE在  菜式类别id=1时，
                                1:1食
                                2:2食
                                3:3食
                                4:4食
                                5:5食
                                6:6食
                                7:7食
                                8:8食
                                9:9食
                                10:10食

                                11:赠送
                                12:招待

                                20:席数  --现在没有实现 syscode=20的席数功能

                              SYSCODE在  菜式类别id=2时(客人要求)，
                                取值只会等于0，表示普通syscode,而这个miclassid=2的菜式就是客人要求的菜式品种
                                0:普通
                              */
  WCONFIRM INTEGER DEFAULT 0,       /*是否需要重量确认 2012-2-22*/
  TEMPDISH INTEGER DEFAULT 0,       /*是否可以作为临时菜编号 2012-2-22*/
  OTHERPRICEID VARCHAR(40) DEFAULT NULL,      /*所属价格分类 lzm add 2012-4-19*/
  STOCKCOUNTSORI NUMERIC(15, 3) DEFAULT -1,   /*存量原始值 lzm add 2012-04-23*/
  WEBCHAT_TAG      INTEGER DEFAULT 0,      /*需要同步到 Web订餐(微信) lzm add 2014/3/13*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  STOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),        /*库存时间 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKNUM NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKORI NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量原始值 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()), /*Web订餐(微信) 同步库存时间 lzm add 2016-03-01*/

  takeaway_Tag INTEGER DEFAULT 0,            /*外卖 外卖品种 lzm add 2018-07-30 06:57:38*/
  boxnum INTEGER DEFAULT 0,                  /*外卖 打包盒数量 lzm add 2018-07-30 06:57:38*/
  boxprice NUMERIC(15,3) DEFAULT 0,          /*外卖 打包盒单价 lzm add 2018-07-30 06:57:38*/
  minordercount INTEGER DEFAULT 0,           /*外卖 最小数量 lzm add 2018-07-30 06:57:38*/

  PRIMARY KEY (MENUITEMID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TCSL, Owner: SYSDBA */

CREATE TABLE NEW_TCSL   /*套餐选择  一个套餐组合为一条记录*/
(
  TCSLID        INTEGER NOT NULL,
  MENUITEMID    INTEGER NOT NULL,         /*对应的套餐品种编号*/
  SORTID        INTEGER,                  /*排序编号*/
  TCSLCOUNT     INTEGER,                  /*可选品种的数量*/
  TCSLLIMITPRICE        NUMERIC(15, 3),   /*价格上限*/
  TOUCHSCRID    INTEGER,
  COST          NUMERIC(15, 3),     /*成本*/
  KICKBACK      NUMERIC(15, 3),     /*提成*/
  PRICE         NUMERIC(15, 3),     /*在套餐中所占的价格*/
  CANREPEAT     INTEGER DEFAULT 0,  /*是否可以重复键入*/
  MAXINCOUNT    INTEGER DEFAULT 1,  /*最多可以键入的次数*/
  MININCOUNT    INTEGER DEFAULT 1,  /*最少可以键入的次数*/
  HAVEINCOUNT   INTEGER DEFAULT 0,  /*记录以选择的次数*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  TCSLNAME  VARCHAR(40),        /*名称 lzm add 2023-01-02 10:32:36*/
  TCSLMEMO  VARCHAR(100),       /*备注 lzm add 2023-01-02 10:32:41*/
  TCSL_EXTCOL JSON,             /*扩展信息 lzm add 2023-01-02 10:33:17
                                {  //留以后扩展用
                                }
                                */

  PRIMARY KEY (TCSLID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TCSL_DETAIL, Owner: SYSDBA */

CREATE TABLE NEW_TCSL_DETAIL   /*套餐选择详细*/
(
  CONTAINERID   INTEGER NOT NULL,
  TCSLID        INTEGER NOT NULL,  /*对应的套餐选择*/
  MENUITEMID    INTEGER,           /*可选项对应的品种编号*/
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  TOUCHSCRLINEID        INTEGER,
  TS_TSCHROW    INTEGER,
  TS_TSCHCOL    INTEGER,
  TS_TSCHHEIGHT INTEGER,
  TS_TSCHWIDTH  INTEGER,
  TS_TLEGEND    VARCHAR(100),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(100),
  TS_TSCHFONT   VARCHAR(40) DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,
  TS_TSNEXTSCR  INTEGER,
  TS_BALANCEPRICE       NUMERIC(15, 3),
  TS_TSCHCOLOR  VARCHAR(20),
  TS_TSCHFONTCOLOR      VARCHAR(20),
  TS_RESERVE01  VARCHAR(40),
  TS_RESERVE02  VARCHAR(40),
  TS_RESERVE03  VARCHAR(40),
  TS_RESERVE04  VARCHAR(40),
  TS_RESERVE05  VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (CONTAINERID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TABLE1, Owner: SYSDBA */

CREATE TABLE NEW_TABLE1     /*   菜式4维表(扩展价格表)   */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),    /* MIDETAIL菜式编号-MENUITEMID  */
  RESERVE02     VARCHAR(40),    /* 菜名-MENUITEMNAME,可填可不填*/
  RESERVE03     VARCHAR(40),    /*  1维 = 填入TABLE4中1维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE04     VARCHAR(40),    /*  2维 = 填入TABLE4中2维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE05     VARCHAR(40),    /*  3维 = 填入TABLE4中3维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE06     VARCHAR(40),    /*  4维 = 填入TABLE4中4维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE07     VARCHAR(40),    /*  价格  */
  RESERVE08     VARCHAR(40),    /*  数量  */
  RESERVE09     VARCHAR(40),    /*  (时间维) = TIMEPERIOD.TPID(SPID)*/
  RESERVE10     VARCHAR(40),    /*  条码 */
  RESERVE11     VARCHAR(40),    /*  打印机*/
  RESERVE12     VARCHAR(40),    /*  用餐方式编号 = DINMODES.MODEID*/
  RESERVE13     VARCHAR(40),    /*  排列编号*/
  RESERVE14     VARCHAR(40),    /*  其它类型, 1=会员价*/
  RESERVE15     VARCHAR(200),
  RESERVE16     VARCHAR(40),    /*  假日*/
  RESERVE17     VARCHAR(40),    /*  星期*/
  PRE_CLASS     VARCHAR(40),    /*  优惠价格类型(撞优惠类别)*/
  T1COST        VARCHAR(20),    /* 成本(注解:PDA点菜时不录入该值,在提交到服务端时根据选择的价格重新提取T1COST) lzm add 2010-06-09 */
  T1KICKBACK    VARCHAR(20),    /* 提成(注解:PDA点菜时不录入该值,在提交到服务端时根据选择的价格重新提取T1KICKBACK) lzm add 2010-06-09 */

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TABLE4, Owner: SYSDBA */
/* （例如 1维有:大,中,小 2维有:冷,热 就记录在该表内）*/

CREATE TABLE NEW_TABLE4    /*记录TABLE1的四个维的数据(即：本餐饮系统拥有的四维数据定义)*/
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),   /*1:一维;2:二维;3:三维;4:四维 */
  RESERVE02     VARCHAR(40),   /*各维的内容编号line id*/
  RESERVE03     VARCHAR(40),   /*名称 */
  RESERVE04     VARCHAR(40),   /*名称(英文)   */
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_MIPARINTERS  /*品种需要多份打印的打印信息表*/
(
  MIPRNID       SERIAL,
  MENUITEMID    INTEGER NOT NULL,
  PRINTCOUNT    INTEGER DEFAULT 0,
  LOGICPRNNAME  VARCHAR(100),
  HOLIDAY       VARCHAR(40),     /*假期*/
  TIMEPERIOD    VARCHAR(40),     /*时段*/
  DINMODES      VARCHAR(40),     /*用餐方式编号*/
  WEEK          VARCHAR(40),     /*星期*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MIPRNID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_WEB_MI_INFO  /*品种拥有的附加信息*/
(
  MENUITEMID INTEGER NOT NULL,  /*品种名称*/
  INFOITEMID INTEGER NOT NULL,  /*附加信息编号*/
  INFOLINEID INTEGER NOT NULL,  /*行号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  INFOCLASSNAME VARCHAR(40) DEFAULT '',  /*分类名称 lzm add 2018-08-06 16:10:58*/
  WEB_GROUPID    INTEGER,           /*组号 lzm add 2022-12-31 11:08:38*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID, MENUITEMID, INFOITEMID, INFOLINEID)
);

CREATE TABLE NEW_BUYSLGIVESL  /*买几送几*/
(
  SGID          INTEGER NOT NULL,
  SGMENUITEMID  VARCHAR(20) NOT NULL,     /*品种编号*/
  SGBUYSEVERAL  NUMERIC(15,3),   /*买几*/
  SGGIVESEVERAL NUMERIC(15,3),   /*送几*/
  SGHOLIDAY     VARCHAR(40),     /*假期*/
  SGWEEK        VARCHAR(40),     /*星期*/
  SGTIMEPERIOD  VARCHAR(40),     /*时段*/
  SGDISCOUNT    VARCHAR(40) DEFAULT '',     /*折扣金额(空或''代表-100%) ==> 10%（即：价格=10%） 10（即：价格=10元） -10%（即：减去10%） -10（即：减去10元）lzm add 2018-07-01 16:21:45*/
  SGVIP         VARCHAR(40) DEFAULT '',     /*会员卡种(多个时用,分割) lzm add 2018-07-01 16:21:41*/
  SGSHOPIDS     VARCHAR(40) DEFAULT '',     /*适合门店(多个时用,分割) lzm add 2018-07-01 16:24:10*/
  SGNAME        VARCHAR(40) DEFAULT '',     /*活动名称(从MIDETAIL_CampaignActivity来) lzm add 2018-07-01 16:32:55*/
  SGFROM        INTEGER DEFAULT 0,          /*来源 0=品种管理 1=来自营销活动*/
  SGMENUITEMNAME VARCHAR(100),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SGID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_MIDETAIL_NEXTMICLASS   /*品种对应的下一类别*/
(
  NMMENUITEMID  INTEGER NOT NULL,     /*品种编号*/
  NMLINEID      INTEGER NOT NULL,     /*顺序编号*/
  NMMICLASS     INTEGER DEFAULT 0,    /*候选类别编号*/
  NMCANREPEAT   INTEGER DEFAULT 1,    /*是否允许重复选择相同的品种*/
  NMMAXCOUNT    INTEGER DEFAULT 1,    /*最多选择次数*/
  NMMINCOUNT    INTEGER DEFAULT 1,    /*最少选择次数*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (NMMENUITEMID,NMLINEID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_MIDETAIL_SPLITPRICE   /*品种对应的大单分账*/
(
  SPMENUITEMID  INTEGER NOT NULL,          /*品种编号*/
  SPLINEID      INTEGER NOT NULL,          /*顺序编号*/
  SPITEMID      INTEGER DEFAULT 0,         /*分账的品种编号*/
  SPITEMNAME    VARCHAR(100),              /*分账的品种名称*/
  SPITEMPRICE   NUMERIC(15,3) DEFAULT 0,   /*分账的品种价格*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SPMENUITEMID,SPLINEID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_MIDETAIL_STOCK_ERP   /*品种对应的ERP存量*/ /*lzm add 2021-11-16 04:03:10*/
(
  MENUITEMID  INTEGER NOT NULL,            /*品种编号  当menuitemid-1时： STOCKNUM=0.000代表可以负库存销售， STOCKNUM=1.000代表不可以负库存销售*/
  STOCKNUM numeric(15,3) DEFAULT 0,        /*存量数量*/
  STOCKTIME timestamp default null,        /*存量的时间*/
  PRODUCT_ID integer default 0,            /*ERP商品的id*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MENUITEMID)
);


CREATE TABLE NEW_MIWITHMI_CLASSSORT  /*有多个相同优惠类别时,那个优先*/
(
  MWMCID           SERIAL,
  MWMCLASSID       INTEGER NOT NULL,   /*(停用)类别id*/
  MWMCSORTCLASSID  INTEGER NOT NULL,   /*排列类别id*/
  MWMCSORTORDER    INTEGER DEFAULT 0,
  MWMCSORTCONDITION     INTEGER DEFAULT 0,  /*有两个相同类别品种时,那个优先.0=最低价优先,1=最高价优先*/
  MWMCLASSID_CHAR  VARCHAR(40),        /*类别ID*/
  MWMCNOTE         VARCHAR(40),        /*撞餐类别说明*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MWMCID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_DEPARTMENTINFO  /*部门信息*/
(
  DEPARTMENTID INTEGER NOT NULL,
  DEPARTMENTNAME  VARCHAR(40),
  DEPARTMENTNAME_LANGUAGE  VARCHAR(40),
  DEPTUSERCODE VARCHAR(30),             /*用户编号 lzm add 2009-08-29*/
  DEPT2DEPOTID INTEGER DEFAULT 0,       /*与部门挂钩的仓库编号 lzm add 2009-09-09*/
  LOGICPRNNAME VARCHAR(40),             /*部门对应的打印机 用于wpos的部门信息通知 lzm add 2011-10-10*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (DEPARTMENTID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_FAMILYGROUP /*报表辅助分类1*/
(
  FGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (FGID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_GENERATOR  /*编号*/
(
  GENERATORID   SERIAL,
  GENERATORNAME VARCHAR(40) NOT NULL ,
  VAL   NUMERIC(10,0) DEFAULT 0 NOT NULL ,
  VALCHAR       VARCHAR(40) DEFAULT '',
  VALTIME       TIMESTAMP,

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,GENERATORID)
);

CREATE TABLE NEW_MIHOLIDAY  /*(品种,服务费)的假期*/
(
  MIHID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  SDAY  VARCHAR(40),  /*开始日期*/
  EDAY  VARCHAR(40),  /*结束日期*/
  GROUPID  VARCHAR(10),  /*所属的组编号*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (MIHID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_MITIMEPERIOD /*(品种,服务费,折扣)的时段*/
(
  MITID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME VARCHAR(40),  /*开始时间*/
  ETIME VARCHAR(40),  /*结束时间*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (MITID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_MIMAKEUP  /*品种的原材料构成*/
(
  MENUITEMID    INTEGER NOT NULL,             /*品种编号*/
  MTID          VARCHAR(30) NOT NULL,         /*原材料用户编号，对应进销存原材料的UserCode*/
  AMOUNT        NUMERIC(15, 3) DEFAULT 0,     /*销售单价*/
  MMCOUNTS      NUMERIC(15, 3) DEFAULT 0,     /*数量*/
  UNIT          VARCHAR(30),                  /*单位1*/
  LINEID        INTEGER DEFAULT 0,            /*行号*/
  UNITOTHERCOUNTS  NUMERIC(15, 3) DEFAULT 0,  /*单位2数量*/
  DEPOTID       INTEGER DEFAULT 0,            /*仓库编号*/
  WAREID        INTEGER DEFAULT NULL,         /*原材料ID编号*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MENUITEMID,MTID,USER_ID,SHOPID,SHOPGUID)
);


--end--------------------------------需要同步的品种表-----------------------------------

--start--------------------------------会员信息-----------------------------------
CREATE TABLE NEW_ABUYER
(
  ABID  SERIAL,
  BUYERID       VARCHAR(40) DEFAULT '' NOT NULL,
  BUYERNAME     VARCHAR(200),          /*姓名*/
  BUYERADDRESS  VARCHAR(200),          /*地址*/
  BUYERTEL      VARCHAR(100),          /*手机*/
  BUYERSEX      VARCHAR(10),           /*性别*/
  BUYERZIP      VARCHAR(20),           /*邮编*/

  BUYERLANG     VARCHAR(40),           /*语言*/
  BUYERFAX     VARCHAR(40),            /*传真*/
  BUYEREMAIL   VARCHAR(40),            /*EMAIL*/
  BUYERPOSITION  VARCHAR(40),          /*职务*/
  BUYERCOMPAY  VARCHAR(40),            /*单位.公司名称*/
  BUYERTYPEID     VARCHAR(10),         /*客户类型编号(A卡,B卡,C卡,D卡,E卡,散客,团队,会议,长包公司,永久帐户...)*/
  BUYERCERTIFICATEID  VARCHAR(10),     /*证件类型编号(身份证,驾驶执照...)*/
  BUYERCERTIFICATENUM  VARCHAR(50),    /*证件号码*/
  BUYERNATIONALITYID  VARCHAR(10),     /*国籍编号(中国,美国,德国...)*/
  BUYERNATIVEPLACEID  VARCHAR(10),     /*籍贯编号(广州,北京,上海,成都...)*/
  BUYERBIRTHDAY  TIMESTAMP,            /*生日.出生日期*/
  BUYERTITLEID    VARCHAR(10),         /*称谓编号(先生,女士,夫人,小姐...)*/
  BUYERPASSPORTTYPEID  VARCHAR(10),    /*护照类型编号(...)*/
  BUYERPASSPORTNUM  VARCHAR(50),       /*护照号码*/
  BUYERVISATYPEID  VARCHAR(10),        /*签证类型编号(...)*/
  BUYERVISAVALIDDAY  TIMESTAMP,        /*签证有效日期*/
  BUYERIMAGEDIR  VARCHAR(50),          /*照片路径*/

  BUYERDEPUTY  VARCHAR(20),            /*企业代表人*/
  BUYERLIKEROOM  VARCHAR(50),          /*满意房间*/
  BUYERSERVICE  VARCHAR(100),          /*房间服务*/
  BUYERSPECIALNEED  VARCHAR(200),      /*特殊要求*/
  BUYERCONFERCON  VARCHAR(254),        /*协议内容*/
  BUYERNOTE1  VARCHAR(200),            /*备注*/
  BUYERISCONFER  INTEGER,              /*是否协议单位 0=否,1=是*/
  BUYERCLASS  INTEGER,                 /*所属宾客 0=内宾,1=外宾(1001=欧美 1002=亚洲),2=香港,3=台湾*/
  BUYERWRITEMAN  VARCHAR(200),         /*签单人*/
  BUYERCODE  VARCHAR(20),              /*会员代码*/
  BUYERPINYIN  VARCHAR(20),            /*拼音*/
  LASTCONSUMEDATE TIMESTAMP,           /*最后消费日期*/
  --BUYERROWSTATUS INTEGER DEFAULT 0,  /*数据状态: 0=新记录, 1=已同步*/

  ADDEMPNAME  VARCHAR(40),             /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,               /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),             /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),             /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,               /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),             /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),             /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,               /*同步时间VER7.2.0 X3*/

  --IDVALUE     VARCHAR(40),             /*卡号 lzm add 2010-05-07*/
  BUYERTEL1   varchar(100),            /*电话1 lzm add 2010-12-08*/
  BUYERTEL2   varchar(100),            /*电话2 lzm add 2010-12-08*/
  BUYERTEL3   varchar(100),            /*电话3 lzm add 2010-12-08*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY(ABID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_VIPDISCOUNT  /*会员积分对应的折扣*/
(
  VSEMPLASSID     INTEGER NOT NULL,      /*会员类别编号*/
  VSLINEID        INTEGER NOT NULL,      /*折扣行编号*/
  VSQ             INTEGER NOT NULL,      /*积分数*/
  VSDISCOUNT      VARCHAR(10) NOT NULL,  /*折扣  10=10元,10%=9折*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (VSEMPLASSID,VSLINEID,USER_ID,SHOPID,SHOPGUID)
);
CREATE TABLE NEW_TABLE6  /* 会员卡 VIP 积分管理 */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*累积消费额*/
  RESERVE02     VARCHAR(40),  /*会员券*/
  RESERVE03     VARCHAR(40),  /*对应VIP类别编号*/
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------会员信息-----------------------------------

--start--------------------------------台号信息-----------------------------------
CREATE TABLE NEW_ATABLESECTIONS  /*区域名称*/
(
  SECNUM      SERIAL,
  SECID       VARCHAR(10) DEFAULT '',
  SECNAME     VARCHAR(40),
  SECNAME_LANGUAGE  VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SECNUM,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_ATABLES
(
  ATABLESID     INTEGER NOT NULL,
  ATABLESNUM    INTEGER,             /* not use again */
  SEATCOUNT     INTEGER,             /*容许最大人数*/
  TABLEUSED     INTEGER DEFAULT 0,   /* 0空闲， 1被占用  newadd  2预订,3合桌(被合并到的,核心的),4拆台,5维修,6清洁,7预订,8过夜*/
  RESERVE01     VARCHAR(40),            /* 台号名称 use to remember the table name 不能有重复*/
  RESERVE02     VARCHAR(40),            /* 如为合桌或拆台,则记录是从那个台号合桌或拆台,格式:拆+台号,并+台号，如为预定则记录'Book'*/
  RESERVE03     VARCHAR(40),            /* 餐区,即台号分区显示*/
  RESERVE04     VARCHAR(40),            /* aTOUCHSCRLINEID*/
  RESERVE05     VARCHAR(40),            /* aTSCHID */
  SMSTABLEID    VARCHAR(10),            /*短信点菜的台号编号*/
  SORTORDER     INTEGER DEFAULT 0,      /*排列序号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '', /*要打印到的逻辑打印机*/

  BUILDINGNUM   VARCHAR(20),           /*楼号,那栋楼*/
  FLOORNUM      VARCHAR(20),           /*楼层*/
  ATABLECLASS   VARCHAR(20),           /*类别(房间,台号,厅,计时房间或椅号,散客区)*/
  ATABLETYPE    VARCHAR(20),           /*类型(标准,单人,双人,三人,四人,五人,普通套房,豪华套房)*/
  BEGINORDER    VARCHAR(40),           /*开房或台时要执行的命令*/
  BEGINMENUITEM VARCHAR(40),           /*开房或台时要消费的品种*/
  MINPRICE_MENUITEMID  VARCHAR(40),    /*最低消费对应的品种编号*/
  TABLEPRICE    NUMERIC(15, 3) DEFAULT 0,        /*房间价格                         100元  */
  COMPUTETIME   INTEGER DEFAULT 0,               /*房价计算时间(分钟)               60分钟:代表每小时100元   */
  UNITTIME      INTEGER DEFAULT 0,               /*房价最小单位(分钟)要小于计算时间 30分钟:代表半小时一计    */
  MINPRICE_NOTT INTEGER DEFAULT 0,         /*最低消费是否包括特价品种(T:) 0＝否，1＝是*/
  MINPRICE_MAN  INTEGER DEFAULT 0,         /*最低消费按人数算 0＝否，1＝是*/
  THETABLE_IST  INTEGER DEFAULT 0,         /*房价特价不打折 0＝否，1＝是*/
  THETABLE_ISF  INTEGER DEFAULT 0,         /*房价免服务费 0＝否，1＝是*/
  MINPRICE_NOTTABLE  INTEGER DEFAULT 0,    /*最低消费是否包括房价 0＝否，1＝是*/
  NEEDSUBTABLEID INTEGER DEFAULT 1,        /*同台多单时需要录入子台号*/
  UNITEATABLEID  VARCHAR(40),              /*合并台号的ID，用于并台*/
  TBLPRICE_MENUITEMID VARCHAR(40),         /*房价对应的品种编号*/
  TBLTOTALPAGEPRN  VARCHAR(40),            /*总单打印机*/
  ADDPARTYNUM   INTEGER DEFAULT 0,         /*允许搭台的数量. >1才会在前台弹出搭台窗口,例如6=(A,B,C,D,E,F)*/
  TRUNTOPRINT   VARCHAR(240),              /*打印机转向设置(一行设置一个打印机的转向) 例如:一楼厨房=二楼厨房 */
  TABLECOLOR    VARCHAR(40),               /*台号的颜色 空:还原颜色的正常显示 lzm add 2010-06-06*/
  WEB_TAG      INTEGER DEFAULT 0,          /*需要同步到web_atables lzm add 2011-03-30*/

  FWFMC VARCHAR(40),   /*服务费名称---->根据简单设置表的服务费名称得到相应的服务费率>>>用在Android 手机 lzm add 2011-09-23*/

  COMMISSIONVALUE NUMERIC(15, 3) DEFAULT 0,  /*帮订人的提成起始金额 lzm add 2011-10-12*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (ATABLESID,USER_ID,SHOPID,SHOPGUID)
);
--end---------------------------------台号信息-----------------------------------

--start--------------------------------打印机信息-----------------------------------
CREATE TABLE NEW_APRINTERS
(
  PRINTERID     INTEGER NOT NULL,
  LOGICPRNNAME  VARCHAR(100), /*逻辑打印机名称*/
  PHYICPRNNAME  VARCHAR(100), /*系统打印机名称 OPOS(OPOSCOM1 OPOSCOM2 ..)*/
  RESERVE01     VARCHAR(40),  /*打印机所在的机器IP*/
  RESERVE02     VARCHAR(40),  /*打印机类型*/
  RESERVE03     VARCHAR(40),  /*打印方法:0=通过打印驱动程序 1=通过打印驱动程序发控制码打印 3=通过串并口直接打印  (作废->:0=driverrawprint,1=drivercodeprint,2=driverdocprint,3=oposprint)*/
  RESERVE04     VARCHAR(40),  /*候选1(曾经停用)*/
  RESERVE05     VARCHAR(40),  /*分单打印时的总单:一个品种一张单 0=否 1=是                      候选2(停用)*/
  RESERVE06     VARCHAR(40),  /*上菜不需要打印分单 //lzm modiry 2013-01-15                     候选3(停用)*/
  RESERVE07     VARCHAR(40),  /*候选4(停用)*/
  RESERVE08     VARCHAR(40),  /*打印失败的逻辑打印机跳单顺序
                                多个时用","分隔
                              */
  RESERVE09     VARCHAR(200),  /*总单打印机 多个时用逗号","分隔*/
  RESERVE10     VARCHAR(40),  /*单据抬头*/
  RESERVE11     VARCHAR(40),  /*打印机所在的机器名称(用于判断是否是本机) 空代表本地打印 */
  RESERVE12     VARCHAR(40),  /*打印端口(LPT1:,COM1)*/
  TOASPRINT     INTEGER DEFAULT 0, /*分单或总单打印(ToAllSinglePrint),0=总单打印,1=分单打印,2=先总单后分单,3=先分单后总单*/
  COMPARAM      VARCHAR(40),  /*串口参数*/
  TPPRINT       INTEGER DEFAULT 0, /*总单品种打印方法: 0=合并打印 1=按逻辑打印机分开打印*/
  TCALONEPRNINTP   INTEGER DEFAULT 0, /*总单的套餐需要单独打印: 0=不需要 1=需要单独打印*/
  PRNSTATUS     INTEGER,      /*打印机状态*/
  LABELPARAM    VARCHAR(200), /*标签打印机参数，用逗号分隔参数.*/
  TOTALPAGEM    INTEGER DEFAULT 3,    /*总单打印机的打印方式
                                        0=不打印
                                        1=打印到本打印机
                                        2=打印到台号指定的总单打印机
                                        3=打印到RESERVE09指定的打印机
                                      */
  WORKTYPE      INTEGER DEFAULT 0,    /*工作方式 0=需要打印 1=该打印机停止打印*/
  BITMAPFONT    INTEGER DEFAULT 0,    /*按位图方式打印所有文字*/

  PCOPYSINALL   INTEGER DEFAULT 1,    /*总单打印份数 lzm add 2009-08-01*/
  PCOPYSINSIN   INTEGER DEFAULT 1,    /*分单打印份数 lzm add 2009-08-01*/
  NEEDCHGTLE    INTEGER DEFAULT 0,    /*是否需要转台单 lzm add 2010-06-29 */
  HASTENPRN     VARCHAR(200),         /*催单打印机 lzm add 2010-08-19*/
  BEEPBEEP      INTEGER DEFAULT 0,    /*来单蜂鸣提醒 lzm add 2010-09-29*/
  VOIDOTHERPRN  VARCHAR(200),         /*取消单逻辑打印机 lzm add 2010-11-03*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  KICHENPRINTER INTEGER DEFAULT 0,          /*是否出品打印机，目前用于上菜厨房打印 lzm add 2018-10-23 03:37:25*/
  QJPRINTER VARCHAR(100) DEFAULT '',        /*上菜时厨房需要打印的打印机，空=全部出品打印 非空=指定的逻辑打印机  lzm add 2018-10-23 03:39:06*/
  
  PRIMARY KEY (PRINTERID,USER_ID,SHOPID,SHOPGUID)
);
--end----------------------------------打印机信息-----------------------------------

--start--------------------------------节假日信息-----------------------------------
CREATE TABLE NEW_TIMEPERIOD  /*报表对应的时段*/
(
  TPID  INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  RESERVE01     VARCHAR(40),  /*当天的Start SPID*/
  RESERVE02     VARCHAR(40),  /*当天的End SPID,如为负数则为第二天的End SPID*/
  RESERVE03     VARCHAR(40),  /*开始时间*/
  RESERVE04     VARCHAR(40),  /*结束时间*/
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TPID,USER_ID,SHOPID,SHOPGUID)
);

--end----------------------------------节假日信息-----------------------------------

--start--------------------------------下拉框信息-----------------------------------
CREATE TABLE NEW_LISTCLASS  /*下拉项 */
(
  LCLAID   INTEGER NOT NULL,
  CAPTION  VARCHAR(40),
  CAPTION_LANGUAGE  VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (LCLAID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_LISTCONTENT  /*下拉内容*/
(
  LCLAID    INTEGER NOT NULL,
  LCONID    INTEGER NOT NULL,
  CONTENTS  VARCHAR(40),        /*下拉内容*/
  SHUTCUTKEY  VARCHAR(40),      /*下拉内容的缩写. 例如LCLAID=5时 代表该国家的简称*/
  OTHERINFO  VARCHAR(40),       /*下拉内容的相关信息
                              当:LCLAID=10时 0=不能进入该台,空和1=允许进入该台
                             */
  CONTENTS_LANGUAGE VARCHAR(40), /*英语*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY(LCLAID,LCONID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------下拉框信息-----------------------------------

--start--------------------------------界面信息-----------------------------------
CREATE TABLE NEW_TOUCHSCR  /*界面*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHNAME      VARCHAR(100),
  RESERVE01     VARCHAR(40),  /*界面属性  模板编号*/
  RESERVE02     VARCHAR(40),  /*子类别或子品种所在的界面*/
  RESERVE03     VARCHAR(40),  /*自动开单参数
                              (
                               AutoOpenChecks 开单类型[0：无；1：堂食；2：外送；3:外带]
                               ,WhenReOpenFalse 取已结单失败后是否开新单[0:否,1:是]
                               ,WhenPickupFalse 取没结单失败后是否开新单[0:否,1:是]
                               ,AfterQueryChecks 查单后是否开新单[0:否,1:是]
                               ,AfterServiceTotal 入单后是否开新单[0:否,1:是]
                               ,AfterTenderMedia 结帐后是否开新单[0:否,1:是]
                              )*/
  RESERVE04     VARCHAR(40),  /*是否需要复位登陆数据,0=false,1=true*/
  RESERVE05     VARCHAR(40),  /*是否需要弹出显示和相关参数
                                    位置1:空或0=false 1=true lzm modify 2010-07-21
                                    位置2:0=点击界面上的按钮后自动隐藏当前界面 1=不隐藏
                                    位置3:0=点击界面按钮后不隐藏当前界面 1=点击按钮后隐藏当前界面 lzm add 2010-10-10*/
  TSCHROW       INTEGER,
  TSCHCOL       INTEGER,
  TSCHHEIGHT    INTEGER,
  TSCHWIDTH     INTEGER,
  RELATE_TS01   INTEGER,  /*相关界面1*/
  RELATE_TS02   INTEGER,  /*相关界面2*/
  RELATE_TS03   INTEGER,  /*相关界面3*/
  RELATE_TS04   INTEGER,  /*相关界面4*/
  RELATE_TS05   INTEGER,  /*相关界面5*/
  RELATE_TS06   INTEGER,  /*相关界面6*/
  TSDETAILMAXLINEID     INTEGER DEFAULT 0,
  PTS   INTEGER,                /**/
  NTS   INTEGER,                /*做法1 做法2 做法3 ....做法N 所在的界面编号 0或空=无  lzm add 【2009-05-26】*/
  TSTIMESTAMP   TIMESTAMP,      /*界面使用时间(用于判断该界面是否有在使用) lzm modify 2022-05-19 07:07:14【之前为：修改时间】*/
  PICTUREFILE   VARCHAR(240),   /*图片文件名称(包括路径)*/

  PANELMARGIN   VARCHAR(100),   /*LeftMargin,RightMargin,TopMargin,BottomMargin  lzm add 2011-11-22*/
  TITLETEXT     VARCHAR(100),   /*抬头内容  lzm add 2011-11-22*/
  TITLEFONT     VARCHAR(100),   /*抬头字体 charset,color,height,name,pitch,size,style  lzm add 2011-11-22*/
  BEVELWIDTH    INTEGER,        /*边框宽度 0=不显示边框 lzm add 2011-11-22*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TSCHID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_TSDETAIL  /*按钮*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHLINEID    INTEGER NOT NULL,
  TSCHROW       INTEGER,
  TSCHCOL       INTEGER,
  TSCHHEIGHT    INTEGER,
  TSCHWIDTH     INTEGER,
  TLEGEND       VARCHAR(100),                   /*按钮名称*/
  TSCHFONT      VARCHAR(40) DEFAULT 'arial',
  TSCHFONTSIZE  INTEGER,
  BCID  INTEGER,
  ANUMBER       INTEGER,
  ANUMERIC      INTEGER,                        /*not use 数据类型不对（快捷键）*/
  TSNEXTSCR     INTEGER,                        /*下一界面编号*/
  BALANCEPRICE  NUMERIC(15, 3),                 /*差价(-10=加10 10=减10)*/
  TSCHCOLOR     VARCHAR(20),
  TSCHFONTCOLOR VARCHAR(20),
  RESERVE01     VARCHAR(40),                    /*按钮类型
                                                  空或0=TFreebutton

                                                */
  RESERVE02     VARCHAR(40),                    /**/
  RESERVE03     VARCHAR(40),                    /*快捷键*/
  RESERVE04     VARCHAR(40),                    /*颜色模版编号*/
  RESERVE05     VARCHAR(40),                    /**/
  TLEGEND_LANGUAGE      VARCHAR(100),           /*按钮英文名称*/
  TSVISIBLE     INT DEFAULT 1,                  /*按钮是否显示*/
  TSDPARAMETER  TEXT,                           /*按钮参数*/
  BALANCETYPE INTEGER DEFAULT 0,                /*差价的类型 0:直接减, 1:百分比, 2:等于品种价格减去该价格的值*/
  VALIDATEUSERSCLASS VARCHAR(254),              /*不需授权用户组,多个用户组时用";"号分割*/
  PICTUREFILE VARCHAR(240),                     /*图片文件名称(包括路径)*/
  VMICLASS text,                                /*不需需要授权的类别编号,有多个时用";"号分割*/
  VOPERATE VARCHAR(240),                        /*需要授权的操作*/
  ONBEFOREEVENT VARCHAR(200),                   /*执行前需要运行的批处理 lzm add 20100503*/
  ONAFTEREVENT VARCHAR(200),                    /*执行后需要运行的批处理 lzm add 20100503*/
  PRINTTEMPLATE VARCHAR(200),                   /*该事件前台打印需要用到的打印模版 lzm add 20100503*/
  PRINTCOUNT VARCHAR(40),                       /*该事件的前台打印份数 lzm add 20100504*/
  EXTPARAM VARCHAR(240),                        /*按钮扩展参数 lzm add 20100504*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TSCHID, TSCHLINEID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_TABLE7  /* 前台界面 按钮颜色模块---->TSDETAIL  */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*已停用：记录Button类型  0-TExplorerButton, 1-NewButton */
  RESERVE02     VARCHAR(40),  /* 名称*/
  RESERVE03     VARCHAR(40),  /*TSCHCOLOR 按钮颜色*/
  RESERVE04     VARCHAR(40),  /* Bitmap  对于TSDETAIL.RESERVE02=0 此项不起作用; 只取文件名,不取路径,路径定死为:client.exe所在的目录再加上\Picture,如c:\SuperTouch\Picture  */
  RESERVE05     VARCHAR(40),  /* down Bitmap  对于TSDETAIL.RESERVE02=0 此项不起作用; 只取文件名,不取路径,路径定死为:client.exe所在的目录再加上\Picture,如c:\SuperTouch\Picture  */
  RESERVE06     VARCHAR(40),  /*TSCHFONTname*/
  RESERVE07     VARCHAR(40),  /*TSCHFONTSIZE*/
  RESERVE08     VARCHAR(40),  /*TSCHFONTCOLOR*/
  RESERVE09     VARCHAR(40),  /*文字位置*/
  RESERVE10     VARCHAR(40),  /*图片位置*/
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
  /*BMPDOWN     BLOB SUB_TYPE 0 SEGMENT SIZE 80,*/
  /*BMP BLOB SUB_TYPE 0 SEGMENT SIZE 80,*/
  TSFONT1        VARCHAR(100),  /*font1的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT2        VARCHAR(100),  /*font2的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT3        VARCHAR(100),  /*font3的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT4        VARCHAR(100),  /*font4的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT5        VARCHAR(100),  /*font5的属性(charset,color,height,name,pitch,size,style)*/
  FONTSTYLE      INTEGER,    /*font.style 1=bold,2=ltalic,4=underline,8=strikeout*/
  PERLINEHAVEFONT  INTEGER DEFAULT 0,   /*每行文字用FONT而不是TSFONT1..TSFONT5*/
  BUTTONSTYLE    INTEGER DEFAULT 0,    /*按钮的类型(0=同系统按钮,1=Flat按钮,2=Class按钮,3=3D按钮)*/
  TEXTPOSITION    VARCHAR(20),    /*按钮文字的对齐方式*/
  GLYPHPOSITION    VARCHAR(20),    /*按钮图片的对齐方式*/
  BMPDOWN        VARCHAR(40),
  BMP            varchar(40),
  TransparentGlyph INTEGER DEFAULT 1,   /*图片背景透明*/
  FOLLOWSCREENTHEME INTEGER DEFAULT 1,  /*跟主题 0=否 1=是 lzm add 2011-11-21*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_TABLE9    /*批处理事件-快捷输入:*05开头+对应的事件ID*/
(
  TBID  INTEGER NOT NULL, /*引用ID*/
  RESERVE01     VARCHAR(40), /*执行事件命令类型:0-内部事件;1-外部的EXE*/
  RESERVE02     VARCHAR(40), /*注解具体命令*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200), /*内容:内部事件---[功能号1,事件ID1{参数1}{参数2}..][功能号2,事件ID2{参数1}{参数2}..]..*/
                           /*     外部的EXE---具体路径{参数},可带参数    */
  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_SCREEN_THEME  /* 界面主题配置 lzm add 2011-11-19*/
(
  TBID  INTEGER NOT NULL,     /*主题编号*/
  CLASSID     VARCHAR(40),    /*主题界面编号
                                MICLASS=大类
                                MICLASSOTHER=小类
                                MIDETAIL=品种
                                MICLASSINFO=附加信息类别
                                MIDETAILINFO=附加信息
                                TABLE=台号
                                OTHER=其它
                                BACKROUND=底色*/
  CLASSNAME     VARCHAR(40),  /* 名称 */
  TSFONT0       VARCHAR(100), /*font0的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT1       VARCHAR(100), /*font1的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT2       VARCHAR(100), /*font2的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT3       VARCHAR(100), /*font3的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT4       VARCHAR(100), /*font4的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT5       VARCHAR(100), /*font5的属性(charset,color,height,name,pitch,size,style)*/
  BTNCOLOR      VARCHAR(40),  /*底色*/
  PERLINEHAVEFONT  INTEGER DEFAULT 0,   /*每行文字用FONT而不是TSFONT1..TSFONT5*/
  BUTTONSTYLE    INTEGER DEFAULT 0,    /*按钮的类型(0=同系统按钮,1=Flat按钮,2=Class按钮,3=3D按钮)*/
  TEXTPOSITION    VARCHAR(20),    /*按钮文字的对齐方式*/
  GLYPHPOSITION    VARCHAR(20),    /*按钮图片的对齐方式*/
  TransparentGlyph INTEGER DEFAULT 1,   /*图片背景透明*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  BUTTONOTHER VARCHAR(200) DEFAULT '',   /*按钮其它属性逗号分隔 lzm add 2021-03-23 17:56:18
                                            圆角[0=否 1=是]
                                          */

  PRIMARY KEY (TBID,CLASSID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_TSDETAILFORM  /*按钮授权列表(用于非动态按钮的授权)*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHLINEID    INTEGER NOT NULL,
  TLEGEND       VARCHAR(100) NOT NULL,        /*按钮名称(formname+buttonname)*/
  VALUSERSCLASS VARCHAR(40),                  /*授权用户组,多个用户组时用";"号分割*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (TSCHID, TSCHLINEID, TLEGEND,USER_ID,SHOPID,SHOPGUID)
);
CREATE TABLE NEW_GRIDCOLSETUP  /*表格列设置*/
(
  GCID          INTEGER NOT NULL,
  GCGRIDID      VARCHAR(254) NOT NULL,
  GCFIELDNAME   VARCHAR(60),
  GCSYSNAME     VARCHAR(60),
  GCUSERNAME    VARCHAR(60),
  GCCAPTION     VARCHAR(100),
  GCWIDTH       INTEGER DEFAULT 10,
  GCVISIBLE     INTEGER DEFAULT 1,
  GCCOLORDER    INTEGER DEFAULT 0,

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (GCID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------界面信息-----------------------------------

--start------------------------------班次信息-----------------------------------
CREATE TABLE NEW_SHIFTTIMEPERIOD /*收银员时段对应的班次*/
(
  STPID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME VARCHAR(40),  /*开始时间*/
  ETIME VARCHAR(40),  /*结束时间*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (STPID,USER_ID,SHOPID,SHOPGUID)
);
--end--------------------------------班次信息-----------------------------------

CREATE TABLE NEW_WEB_GROUP /*附加信息所属组信息 lzm add 2011-08-10*/
(
  WEB_GROUPID    INTEGER NOT NULL,   /*组号*/
  WEB_GROUPNAME  VARCHAR(40),        /*名称*/
  WEB_GROUPMEMO  VARCHAR(100),       /*备注*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  MENUITEMID INTEGER DEFAULT 0,   /*品种编号  //lzm add 2022-12-31 11:36:09 */
  WEB_EXTCOL JSON,   /*扩展信息  //lzm add 2022-12-31 11:36:09*
                      {"canrepeat": "0",   //是否可以重复键入
                       "maxincount": "1"   //最多可以键入的次数
                       "minincount": "1"   //最少可以键入的次数
                      }
                      */

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,WEB_GROUPID)
);

--start------------------------------服务费-----------------------------------
CREATE TABLE NEW_SERVICEAUTO  /*服务费*/
(
  SAID          INTEGER NOT NULL,
  SANAME        VARCHAR(40),     /*服务费的名称*/
  SATYPE        INTEGER,         /*0=百分比 , 1=金额 */
  PERSAPRICE    NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTSAPRICE    NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  SAHOLIDAY     VARCHAR(40),     /*假期*/
  SATIMEPERIOD  VARCHAR(40),     /*时段*/
  SADINMODES    VARCHAR(40),     /*用餐方式编号*/
  SAWEEK        VARCHAR(40),     /*星期*/
  SACOMPUTTYPE  VARCHAR(10),     /*计算方式 1=开新单计, 2＝即时计*/
  LIDU  INTEGER,           /*
                             = 0; //对账单中的当前品种添加服务费
                             = 1; //代表对账单中的当前的品种添加服务费
                             = 2; //下一菜式要收服务费
                             = 3; //取消2方式定义的服务费
                             = 4; //对账单中的所有的菜项添加服务费
                           */
  BCID          INTEGER,
  ANUMBER       INTEGER,

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SAID,USER_ID,SHOPID,SHOPGUID)
);
--end--------------------------------服务费-----------------------------------

--start------------------------------用餐方式-----------------------------------
CREATE TABLE NEW_DINMODES
(
  MODEID        INTEGER NOT NULL,
  MODENAME      VARCHAR(100),       /*名称*/
  PERDISCOUNT   NUMERIC(15, 3),     /*折扣(停用)*/
  PERSERCHARGE  NUMERIC(15, 3),     /*服务费*/
  KICHENPRINTCOLOR      INTEGER DEFAULT 0, /**/
  RESERVE01     VARCHAR(40),        /*开单时自动点菜[菜式编号{数量}]..[]*/
  RESERVE02     VARCHAR(40),        /*开单时自动执行的命令[BCID,ANUMBER{界面编号}{按钮参数}]...[]*/
  RESERVE03     VARCHAR(40),        /* 单据类型,要结合RESERVE04:
                                       空和0=【RESERVE04="－"时为:销售单(餐饮的"堂吃"属于销售单)】,【RESERVE04="＋"时为:销售退单】;
                                       1=【RESERVE04="＋"时为:进货单】,【RESERVE04="－"时为:进货退单】;
                                       2=【盘点单,同时RESERVE04="=="】,【RESERVE04="=＋"时为:报益单】,【RESERVE04="=－"时为:报损单】;
                                       3=【RESERVE04="=＋"时为:退料单】,【RESERVE04="=－"时为:领料单】;

                                    */
  RESERVE04     VARCHAR(40),        /* 该单的品种为正数或负数 +:正数,-:负数,nil:不参与计算,空:负数,=:与库存一致*/
  RESERVE05     VARCHAR(40),        /* 预留 历史:停用->(点品种时要执行的命令[])*/
  MUSTCLASS1    VARCHAR(100),       /*必须点的品种类别1(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS2    VARCHAR(100),       /*必须点的品种类别2(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS3    VARCHAR(100),       /*必须点的品种类别3(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS4    VARCHAR(100),       /*必须点的品种类别4(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  DMNEEDTABLE   INTEGER DEFAULT 1,  /*可以不录入台号 0=否,1=是*/
  DMNOTPERPAPER INTEGER DEFAULT 0,  /*不需要入单纸 lzm add 2010-05-15*/
  GENIDTYPE     INTEGER DEFAULT 0,  /*单号的产生方式 0=跟系统 1=顺序号 2=随机号 3=人工单号 lzm add 2011-05-23*/
  NOTPERPAPER   INTEGER DEFAULT 0,  /*不要厨房分单 0=否 1=是 lzm add 2012-07-10*/
  NOTSUMPAPER   INTEGER DEFAULT 0,  /*不要厨房总单 0=否 1=是 lzm add 2012-07-09*/
  NOTVOIDPAPER  INTEGER DEFAULT 0,  /*不需要退单纸 lzm add 2012-08-08*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (MODEID,USER_ID,SHOPID,SHOPGUID)
);
--end--------------------------------用餐方式-----------------------------------

--start------------------------------折扣-----------------------------------
CREATE TABLE NEW_DISCOUNT  /*折扣*/
(
  DISCOUNTID    INTEGER NOT NULL,
  DISCOUNTNAME  VARCHAR(40),
  DISCOUNTTYPE  INTEGER,         /*0=百分比, 1=金额*/
  PERDISCOUNT   NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTDISCOUNT   NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  LIDU  INTEGER,           /*
                             = 0; //整单打折
                             = 1; //行打折
                             = 2; //下一菜式要打折
                             = 3; //取消打折
                             = 4; //整单品种打折 (之前:不用授权的VIP卡打折)

                             //可以有5种不同的VIP折扣
                             = 11; //A卡折扣
                             = 12; //B卡折扣
                             = 13; //C卡折扣
                             = 14; //D卡折扣
                             = 15; //E卡折扣
                           */
  BCID  INTEGER,
  ANUMBER       INTEGER,
  RESERVE01     VARCHAR(40),   /* 是否优惠卡(即：是否可以打折)   0和空:非优惠卡,1:优惠卡 */
  RESERVE02     VARCHAR(40),   /*计算的方式 1=开新单计，2＝即时计*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  HOLIDAY       VARCHAR(40),     /*假期*/
  TIMEPERIOD    VARCHAR(40),     /*时段*/
  DINMODES      VARCHAR(40),     /*用餐方式编号*/
  WEEK          VARCHAR(40),     /*星期*/

  DISCOUNT_LEVEL INTEGER,   /*折扣级别>>>用在Android 手机 lzm add 2011-09-23*/
  REPORT_TYPE VARCHAR(40),   /*折扣类型 赠送 招待(现在没有使用这个域值)>>>用在Android 手机 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,DISCOUNTID)
);
--end--------------------------------折扣-----------------------------------

--start------------------------------付款方式报表跟踪项-----------------------------------

CREATE TABLE NEW_TENDERMEDIA   /*付款类型*/
(
  MEDIAID       INTEGER NOT NULL,
  MEDIANAME     VARCHAR(40),
  BCID  INTEGER,
  ANUMBER       INTEGER,
  MEDIARATE     NUMERIC(15, 3),  /*汇换率*/
  RESERVE1      VARCHAR(40),     /*not use*/
  RESERVE2      VARCHAR(40),     /*付款类型:
                                   对应 LISTCONTENT 的 LCLAID=21
                                   '0'=现金, '1'=CGC(赠券) 【在系统汇总报表，中根据该类型分别统计“现金”和“赠券”的消费金额】*/
                                 /*老版本的方式(v5.2之前)： CASHER REPORT 中,是否CGC(赠券),'Y' OR  'N'   */
  RESERVE3      VARCHAR(40), /*
                             0:空:普通
                             1:会员券(即:积分)的付款方式【会员可以有消费积分，根据消费积分可以转换为会员券】
                             2:用礼券付款【需要记录礼券编号】(v5.2之后的礼券付款标志)
                             3:"记帐"(CHECKRST.RESERVE04记录ABUYER.BUYERID)
                             4:信用卡刷卡(CHECKRST.VISACARD_CARDNUM和CHECKRST.VISACARD_BILLNUM分别记录卡号和刷卡的帐单号)
                             5:订金
                             6:餐券付款【需要录入券额和数量】
                             7:银行积分付款 lzm add 【2009-06-21】
                             8:客户记账后的现金还款 lzm add 【2009-08-14】

                             9:IC卡记录消费金额的消费方式
                             10:IC卡充值的付款方式(金额数保存在IC卡上)  **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**

                             11:A卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             12:B卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             13:C卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             14:D卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             15:E卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**

                             16:直接修改总积分付款  //lzm add 2011-08-02
                             17:直接修改可用积分付款  //lzm add 2011-08-02
                             18:积分折现操作 //lzm add 2011-08-05
                             19:VIP卡挂失后退款的付款方式 //lzm add 2012-07-04
                             20:VIP卡挂失后换卡,补卡-新卡的付款方式 //lzm add 2012-07-04

                             21:A卡积分折现付款 lzm add 2011-07-13
                             22:B卡积分折现付款 lzm add 2011-07-13
                             23:C卡积分折现付款 lzm add 2011-07-13
                             24:D卡积分折现付款 lzm add 2011-07-13
                             25:E卡积分折现付款 lzm add 2011-07-13

                             26:酒店会员卡付款 lzm add 2012-06-17
                             27:酒店转房帐付款 lzm add 2012-06-17
                             28:酒店挂账付款 lzm add 2012-06-17

                             29:IC卡还款 lzm add 2013-11-28
                             30:磁卡还款 lzm add 2013-11-28

                             31:VIP卡挂失后换卡,补卡-旧卡的付款方式 //lzm add 2015/5/22 星期五

                             32:支付宝支付
                             33:微信支付

                             100:消费日结标记 lzm add 2012-07-12

                             111:澳门通-售卡 lzm add 2013-02-26
                             112:澳门通-充值 lzm add 2013-02-26
                             113:澳门通-扣值 lzm add 2013-02-26
                             114:澳门通-结算 lzm add 2013-02-26
                             */
  RESERVE01     VARCHAR(40), /*(v5.2之前的礼券付款标志)是否礼券 标记为:L或l（需要录入礼券编号）*/
  RESERVE02     VARCHAR(40), /*固定付款金额*/
  RESERVE03     VARCHAR(40), /*对账额(折扣) 10%=9折 10=折掉10元 */
  RESERVE04     VARCHAR(40), /*最大允许的付款金额 50%=不能输入大于50%的账单金额 50=不能输入大于50元的金额 lzm modify 2009-08-07*/
  RESERVE05     VARCHAR(40), /*固定兑换后的金额 lzm add 2009-10-22*/
  NUMBER        VARCHAR(40), /*该付款的用户编号UserCode*/
  REPORTTYPE    VARCHAR(50) DEFAULT '', /*用于新总部系统 lzm add 2010-09-02*/

  DENOMINATION VARCHAR(40),    /*面额 >>>用在Android 手机 lzm add 2011-09-23*/
  REPORT_TYPE VARCHAR(40),     /*现金 信用卡  借记卡 支票 赠券 现金券 礼券 记账 其他 >>>用在Android 手机 lzm add 2011-09-23*/

  NEED_PAY_REMAIN INTEGER DEFAULT 0,  /*需要统计当前付款的账单余额 lzm add 2015-05-31*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MEDIAID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_TRACKINGGROUP  /*报表跟踪项*/
(
  TGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  ISDEFAULT     INTEGER,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TGID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_TRACKINGGROUPITEM  /*报表跟踪项详细*/
(
  TGID  INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  BCID  INTEGER,                /*统计类别*/
  NUM   INTEGER,                /*内容编号*/
  APPENDCOL     VARCHAR(100),   /*说明信息*/
  RESERVE01     VARCHAR(40),    /*区域编号 A-Z //lzm add 2011-07-30*/
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TGID, LINEID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------付款方式报表跟踪项-----------------------------------

CREATE TABLE NEW_EMPCLASS
(
  EMPCLASSID    INTEGER NOT NULL, /*会员EMPCLASSID=1..10000 VIP卡EMPCLASSID=10001..10005  lzm modify 分开接收员工和会员信息 2012-4-23*/
  EMPCLASSNAME  VARCHAR(40),   /*类别名称*/
  TSID  INTEGER,               /*登录到的界面编号*/
  ACCESSLEVEL   INTEGER,       /*
                               0-Admin管理权限,
                               1-Normal普通权限,
                               2-cFreeRight,
                               3-咨客开单,
                               4-桑那钟房,
                               5-技师,
                               6-客房管理员
                               7-服务员或吧女,用于推销酒水或其它品种的提成
                               8-划单员

                               等于以下值时，对应Discount表的:LIDU(凹度):可以知道该用户的折扣率
                               11=A卡
                               12=B卡
                               13=C卡
                               14=D卡
                               15=E卡
                               */
  RESERVE01     VARCHAR(40),   /*员工类型,-1=隐藏该用户,0=员工,1=VIP*/
  RESERVE02     VARCHAR(40),   /*普通、银、金卡、白金卡： Money
                               亦可作该卡的最低金额
                               */
  RESERVE03     VARCHAR(40),   /*卡的明细类型
                               0=普通员工磁卡
                               1=高级员工磁卡（有打折功能）
                               2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                               3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                               4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                               ?5=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                               */
  RESERVE04     TEXT,           /*YPOS的权限 lzm add 2018-12-04 03:14:40【之前是：2=管理库存权限,】
                              jb = {shopname:"",                      --店名
                                    loginuserdiscount_upperlimit:"",  --折扣上限   例如:10% 代表只能进行0%到10%的折扣
                                    loginuser_ql_discount_upperlimit; --例如:10 代表只能进行0到10的去零
                                    loginuserStorage:"",              --是否启用联机的库存管理   ""或0  不进过服务器    1使用服务器处理库存
                                    loginuserType:"",                 --5：系统管理员 4：老板   3：经理  2：财务人员  1：部长  0:普通业务员
                                    loginuserIsFreePrice:"",          --0:不启用   1:启用改价格功能
                                    loginuserMode:"",                 --0:没有PC    1:经过互联网下服务器PC    2:直接通过局域网连接PC
                                    jb:""                             --折扣级别  0是缺省级别，数字越高，级别越高
                                  }
                                */
  RESERVE05     VARCHAR(40),    /*要登录的界面,多个界面时用分号(";")分隔*/
  SMSTABLEID    VARCHAR(10),    /*短信台号*/
  BEFOREORDER   VARCHAR(100),    /*登陆时要执行的命令*/
  PCID          VARCHAR(40) DEFAULT '',  /*空=门店员工信息和门店VIP卡信息 */
  GRANTSTR      VARCHAR(200),            /*用户权限,拥有的权限用逗号分割
                                           [
                                           位置1:领料单是否允许修改单价 0=否1=是
                                           位置2:退料单是否允许修改单价 0=否1=是
                                           位置3:直拨单的供应商编号对应的单价是否允许修改
                                                (格式:  01;02=1 代表:只允许编号为01或02的供应商修改单价
                                                        01=1    代表:只允许编号为01的供应商时修改单价)
                                           位置4:进货单的供应商编号对应的单价是否允许修改
                                                (格式:  01;02=1 代表:只允许编号为01或02的供应商修改单价
                                                        01=1    代表:只允许编号为01的供应商时修改单价)
                                           ]*/
  MUSTWORKON    INTEGER DEFAULT 0,       /*必须上班才能登陆 0=否 1=是*/
  AFTERPRNBILLSCID  VARCHAR(40),         /*印整单后点击台号进入的界面*/

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  OPENBILLSCID  VARCHAR(40),            /*如果该单有内容则点击台号进入的界面*/
  MIDETAILSCID  VARCHAR(40),            /*该类员工使用的品种界面用逗号分割 500,600,1000,700*/

  LEVELID       INTEGER DEFAULT 0,      /*权限级别 对应授权级别表"LEVELCLASS"的LEVELID lzm add 2010-06-13*/
  AFTERTBLSCID  VARCHAR(40),            /*点击台号后进入的界面 lzm add 2010-07-26*/
  PHONECALLAUTO INTEGER DEFAULT 0,      /*自动弹出来电显示窗口的停留时间 0=不弹出来电窗口 -1=不自动关闭 lzm add 2010-12-21*/
  PRESENTITEM   INTEGER DEFAULT 0,      /*招待 0=不限制招待 >1=需要限制招待的份数 lzm add 2011-06-14*/
  PRESENTCTYPE  INTEGER DEFAULT 0,      /*招待的周期 0=按日计算 1=按周计算 2=按月计算 lzm add 2011-06-14*/

  PRESENTINUSE  INTEGER DEFAULT 0,      /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/
  STOCKALARM    INTEGER DEFAULT 0,      /*是否弹出库存警报 0=否 1=启用 lzm add 2011-12-26*/

  PRESENTAMOUNT  NUMERIC(15, 3),        /*限制招待的金额 0或空=不限制 lzm add 2013-09-02*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRESENTLIMIT VARCHAR(20),                 /*账单的招待上限 lzm add 2015-09-28*/

  PRIMARY KEY (EMPCLASSID,PCID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_EMPLOYEES /*EMPLOYEES与ABUYER是多对一的关系 通过BUYERID联系(即：一个人可以有多个VIP卡)*/
(
  EMPID INTEGER NOT NULL,       /*会员EMPID=1..10000 VIP卡EMPID>=10001 lzm modify 分开接收员工和会员信息 2012-4-23*/
  FIRSTNAME     VARCHAR(100),    /*姓名1*/
  LASTNAME      VARCHAR(100),    /*姓名2*/
  IDVALUE       VARCHAR(40),    /*卡号(即:密码)*/
  EMPCLASSID    INTEGER,
  RESERVE01     VARCHAR(40),    /*有效期  PeriodOfValidity 例如:20110101*/
  RESERVE02     VARCHAR(40),    /*地址 Address */
  RESERVE03     VARCHAR(40),    /*联系电话 Tel*/
  RESERVE04     VARCHAR(40),    /*邮编 ZipCode*/
  RESERVE05     VARCHAR(40),    /* ***lzm 作废 2013-05-24*** 用于积分 VIP卡消费累计总金额,即开卡以来的消费金额*/
  RESERVE11     VARCHAR(40),    /*用于积分 可用积分(或会员券)*/
  RESERVE12     VARCHAR(40),    /* ***lzm 作废 2013-05-24*** 用于积分 已经计算的VIP卡消费总额,即多少钱已兑换成积分(或会员券)*/
  RESERVE13     VARCHAR(40),    /*改为VIP的品种存量 之前:磁卡：剩余的 Money  */
  RESERVE14     VARCHAR(40),    /*会员卡的金额 Money*/
  RESERVE15     VARCHAR(40),    /*手机Mobile*/
  RESERVE16     VARCHAR(40),    /*传真Fax*/
  RESERVE17     VARCHAR(40),    /*公司名company*/
  RESERVE18     VARCHAR(40),    /*公司职务CoHeadship*/
  RESERVE19     VARCHAR(40),    /*台商会分会名ASSN*/
  RESERVE20     VARCHAR(40),    /*分会职务ASSNHeadship*/
  RESERVE21     VARCHAR(40),    /*人士Degree*/
  RESERVE22     VARCHAR(40),    /*生日Birthday */
  RESERVE23     VARCHAR(40),    /*语言   cn  en     */
  RESERVE24     VARCHAR(40),    /*UserCode 用户编号,比如技师的编号等*/
  RESERVE25     VARCHAR(40),    /*最后充值日期 lzm modify 2013-04-17*/
  BUYDATE       VARCHAR(10),    /*购卡日期*/
  ORDERID       INTEGER DEFAULT 0,     /*排列编号*/
  BUYERID       VARCHAR(40),    /*对应ABUYER的BUYERID  EMPLOYEES与ABUYER是多对一的关系(即：一个人可以有多个VIP卡)*/
  EMPPASSWORD   VARCHAR(128),   /*用户自己定义的密码*/
  LASTCONSUMEDATE  TIMESTAMP,   /*最后消费日期*/
  PCID          VARCHAR(40) DEFAULT '', /*空=门店员工信息和门店VIP卡信息(以前的总部系统用于区分总部员工和门店员工) */
  NOTADDINTERNAL   INTEGER DEFAULT 0,  /*不需要继续累积消费积分 0=需要继续累计 1=不需要继续累计*/
  JXCUSERID     VARCHAR(40),    /*改为进销存的客户或供应商名称 lzm modify 2011-12-13 (之前:进销存的用户ID)*/
  JXCPASSWORD   VARCHAR(40),    /*进销存的密码*/

  treeparent    INTEGER DEFAULT -1, /**/
  wage          NUMERIC DEFAULT 0,  /*基本工资*/
  dept          VARCHAR(20),        /*部门*/
  learning      VARCHAR(20),        /*学历名称*/
  isdeliver     INTEGER DEFAULT 0,  /* ***保留***(暂时被程序固定为1) 1=进销存高级用户 0=普通用户 (即之前的:是否配送中心员工) 就是进销存管理的员工管理的Admin*/
  comedate      TIMESTAMP,          /*入职时间*/
  sex           VARCHAR(10),        /*男女*/
  place         VARCHAR(30),        /*籍贯*/

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  TBLNAME     VARCHAR(40),              /*对应到的台号名称,用于现在用户只能操作的台号 lzm add 2010-08-13*/

  WEB_TAG      INTEGER DEFAULT 0,       /*需要同步到web_sysuser lzm add 2011-03-30*/

  DISCOUNT_LEVEL INTEGER,        /*员工或者会员的折扣级别---->根据折扣表得到该会员能够拥有的折扣>>>用在Android 手机 lzm add 2011-09-23*/
  TAX_DEFINE VARCHAR(40),        /*根据简单设置表的税率名称得到相应的税率>>>用在Android 手机 lzm add 2011-09-23*/

  PRESENTITEM   INTEGER DEFAULT NULL,  /*招待 空=跟类别设置 0=不限制招待 >1=需要限制招待的份数 lzm add 2011-06-14*/
  PRESENTCTYPE  INTEGER DEFAULT NULL,  /*招待的周期 空=跟类别设置 0=按日计算 1=按周计算 2=按月计算 lzm add 2011-06-14*/

  POINTSTODAY  NUMERIC(15,3) DEFAULT 0.0,       /*用于积分 今天的积分(用于积分次日生效的算法) lzm add 2011-07-10*/
  POINTSTOTAL   NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 累计总积分 lzm add 2011-07-05*/
  MONEYFPOINTS  NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 上月积分已折现金额(可当付款使用) lzm add 2011-07-05*/
  POINTSADDTIME TIMESTAMP,                      /*用于积分 最后获得积分的时间(用于上月积分需要兑换为现金的算法) lzm add 2011-07-11*/
  MONEYFPOINTSTIME TIMESTAMP,                   /*用于积分 上次积分折现的时间(用于上月积分需要兑换为现金的算法) lzm add 2011-07-11*/
  POINTSISUSED  NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 已兑换的积分 lzm add 2011-07-18*/
  --CANTRUNPOINTS NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 现在可折现的积分(用于上月积分需要兑换为现金的算法) lzm add 2011-08-04*/

  PRESENTINUSE  INTEGER DEFAULT 0,     /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  AUDITLEVEL  INTEGER DEFAULT 1,       /*审核级别 1=一级审核(入单员就是一级审核员) lzm add 2011-10-30*/
  STOCKDEPOT  VARCHAR(40),             /*仓库编号(空:全部),用于限制用户只能操作的仓库 lzm add 2011-11-2*/

  WPOS_SN  VARCHAR(40),                /*点菜机的序列号 lzm add 2012-02-25*/
  CARDSTATE     INTEGER DEFAULT 0,     /*VIP卡的状态 0=在用 1=挂失 2=作废 3=黑名单 lzm add 2012-07-05*/
  RETURNBACK    INTEGER DEFAULT 0,     /*VIP卡已退款 0=否 1=是 lzm add 2012-07-05*/
  EXCHANGENEWCARD  VARCHAR(50),        /*VIP卡换卡,补卡对应的新卡号 lzm add 2012-07-05*/

  PRESENTAMOUNT  NUMERIC(15, 3),       /*限制招待的金额 空=跟类别设置 0=不限制 lzm add 2013-09-02*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRESENTLIMIT VARCHAR(20),                 /*账单的招待上限 lzm add 2015-09-28*/

  PRIMARY KEY (EMPID,PCID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_PRESENT_MICLASS_EMPCLASET  /*员工类别,可招待的品种类别和数量 lzm add 2011-06-14*/
(
  EMPCLASSID    INTEGER NOT NULL,     /*员工类别编号*/
  MICLASSID     INTEGER NOT NULL,     /*品种类别编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPCLASSID, MICLASSID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_PRESENT_MIDETAIL_EMPCLASET  /*员工类别,可招待的品种和数量 lzm add 2011-06-14*/
(
  EMPCLASSID    INTEGER NOT NULL,     /*员工类别编号*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPCLASSID, MENUITEMID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_PRESENT_MICLASS_EMPSET  /*员工,可招待的品种类别和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MICLASSID     INTEGER NOT NULL,     /*品种类别编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPID, MICLASSID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_PRESENT_MIDETAIL_EMPET  /*员工,可招待的品种和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPID, MENUITEMID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_PRESENT_MIDETAIL_EMPRUN  /*员工曾经已招待的品种和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  SALEDATE      TIMESTAMP NOT NULL,   /*销售日期*/
  APRESENTCOUNT INTEGER,              /*已招待数量*/

  APRESENTAMOUNT NUMERIC(15, 3),      /*已招待金额 lzm add 2013-09-02*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPID, MENUITEMID, SALEDATE,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_POINTS2MONEY  /*积分兑换金额转换表 lzm add 2011-07-05*/
(
  POINTS_S          INTEGER NOT NULL,       /*可用积分开始范围*/
  POINTS_E          INTEGER NOT NULL,       /*可用积分结束范围*/
  CONVER_RATE       VARCHAR(10) NOT NULL,   /*积分转金额比率*/
  MONEY_S           INTEGER,                /*可兑换金额开始范围(用于比较和查看)*/
  MONEY_E           INTEGER,                /*可兑换金额结束范围(用于比较和查看)*/
  MONEY_PER_POINTS  VARCHAR(20),            /*每分折算金额(用于比较和查看)*/
  REMARK            VARCHAR(100),           /*备注*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (POINTS_S, POINTS_E, CONVER_RATE,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE NEW_SYSTEMPARA    /*系统参数*/
(
  ID    SERIAL,
  NAME  VARCHAR(40),
  VAL   TEXT, /*old varchar(40), alter table SYSTEMPARA alter VAL type VARCHAR(240)*/
  RESERVE01     VARCHAR(40),  /*Section*/
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MDTIME        TIMESTAMP,    /*数据修改时间*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (ID)
);

CREATE TABLE NEW_SYSTEMPARA_400    /*400上设置的系统参数*/ /*lzm add 2021-11-18 12:46:28*/
(
  ID    SERIAL,
  NAME  VARCHAR(40),
  VAL   TEXT, /*old varchar(40), alter table SYSTEMPARA alter VAL type VARCHAR(240)*/
  RESERVE01     VARCHAR(40),  /*Section*/
  RESERVE02     VARCHAR(40),  /*file=更新到文件root\data\SystemPara.ini db=更新到SYSTEMPARA表*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MDTIME        TIMESTAMP,    /*数据修改时间*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (ID)
);

--start--------------------------------总部配置下达表-----------------------------------
CREATE TABLE HQ_ISSUE_SHOP_CNF
(
  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  DATAID INTEGER NOT NULL,                  /*需要同步的表ID
                                              0=全部
                                              1=员工【***停用】
                                              2=会员卡【***停用】
                                              3=会员信息【***停用】
                                              4=房间(台号)
                                              5=打印机配置【***停用】
                                              6=原材料【***停用】
                                              7=下拉框信息
                                              8=品种
                                              9=假期时段
                                              10=附加信息【***停用】
                                              11=界面布局
                                              12=班次设置
                                              13=部门和辅助分类
                                              14=进销存基本资料【***停用】
                                              15=系统配置信息
                                              16=折扣表
                                              17=服务费表
                                              18=用餐方式
                                              19=付款方式报表跟踪项
                                              20=在云端设置的优惠活动
                                              21=品种对应的ERP存量
                                              22=SYSTEMPARA_400
                                              23=需要从Odoo更新门店ERP存量并下发门店
                                              lzm add 2015-09-17*/
  FROMSHOPID  VARCHAR(40) DEFAULT '',       /*与那个店编号采用相同配置 lzm add 2015-09-16*/

  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  EFFECTIVETIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),    /*生效时间 lzm add 2015-09-17*/

  DOWNLOADTIME VARCHAR(30),                 /*门店下载数据时间或处理时间*/
  EFFECTIVENOW INTEGER DEFAULT 0,           /*是否现在要更新 0=根据生效时间更新 1=现在更新 lzm add 2018-11-01 00:33:00*/


  PRIMARY KEY(USER_ID,SHOPID,SHOPGUID,DATAID)
);

/* Table: MICLASS, Owner: SYSDBA */

CREATE TABLE HQ_ISSUE_MICLASS
(
  MICLASSID     INTEGER NOT NULL,
  MICLASSNAME   VARCHAR(100),
  MICLASSDISCOUNT       NUMERIC(15, 3) default 0,  /*类别折扣率%*/
  RESERVE01     VARCHAR(40),  /*按钮模板编号*/
  RESERVE02     VARCHAR(40),  /*关联界面或类别1*/
  RESERVE03     VARCHAR(40),  /*子类或品种的按钮模板编号*/
  RESERVE04     text,
  RESERVE05     VARCHAR(40),
  SORTORDER     INTEGER default 0,
  TOUCHSCRID    INTEGER,
  TOUCHSCRLINEID        INTEGER,
  SIMPLENAME    VARCHAR(100),
  PARENTMICLASS INTEGER,     /*根类别编号*/
  MICLASSNAME_LANGUAGE  VARCHAR(100),
  SIMPLENAME_LANGUAGE   VARCHAR(100),
  TS_TSCHROW    INTEGER,     /*父类别2编号*/
  TS_TSCHCOL    INTEGER,     /*类别属性 0或空=品种类别 1=附加信息*/
  TS_TSCHHEIGHT INTEGER,     /*是否系统保留 0或空=否 1=是*/
  TS_TSCHWIDTH  INTEGER,
  TS_TLEGEND    VARCHAR(100),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(100),
  TS_TSCHFONT   VARCHAR(40) DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,
  TS_TSNEXTSCR  INTEGER,                 /*子类别所在的界面*/
  TS_BALANCEPRICE       NUMERIC(15, 3),
  TS_TSCHCOLOR  VARCHAR(20),
  TS_TSCHFONTCOLOR      VARCHAR(20),
  TS_RESERVE01  VARCHAR(40),    /*不需授权用户类别 lzm add 2010-05-14*/
  TS_RESERVE02  VARCHAR(40),    /*需授权的状态 lzm add 2010-05-14*/
  TS_RESERVE03  VARCHAR(40),
  TS_RESERVE04  VARCHAR(40),
  TS_RESERVE05  VARCHAR(40),
  PICTUREFILE VARCHAR(240),        /*图片文件名称(包括路径)*/
  SUBMITSCHID  INTEGER DEFAULT 0,  /*子品种所在的界面    ****之前:该类别下的类别或品种所在的界面*/
  MICVISIBLED  INTEGER DEFAULT 1,  /*是否可见 0=否,1=是*/
  MAXINPUTMI   INTEGER DEFAULT 1,  /*最多允许键入该类别品种的次数 注意:只对附加信息生效*/
  MININPUTMI   INTEGER DEFAULT 1,  /*最少允许键入该类别品种的次数 注意:只对附加信息生效*/
  CANREPEATEINPUT  INTEGER DEFAULT 0,  /*是否可以重复录入相同的品种,0=false,1=true*/
  WEB_TAG      INTEGER DEFAULT 0,  /*需要同步到web_miclass lzm add 2011-03-30*/
  WEB_NAME     VARCHAR(100),       /*在web_miclass的别名 lzm add 2011-03-30*/
  WEB_FILE     VARCHAR(240),       /*在web_miclass的picturefile lzm add 2011-03-30*/
  WEB_FILE_MOBILE  VARCHAR(240),   /*在web_miclass的picturefile_mobile lzm add 2011-03-30*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MICLASSID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: MIDETAIL, Owner: SYSDBA */

CREATE TABLE HQ_ISSUE_MIDETAIL
(
  MENUITEMID    INTEGER NOT NULL,
  MICLASSID     INTEGER DEFAULT 0,
  MENUITEMNAME  VARCHAR(100),   /*品种名称*/
  LOGICPRNNAME  VARCHAR(100),   /*逻辑打印机*/
  BCID          INTEGER,
  ANUMBER       INTEGER,
  FAMILGID      INTEGER,        /*辅助分类1*/
  MAJORGID      INTEGER,        /*辅助分类2*/
  MIPRICE       NUMERIC(15, 3), /*价格*/
  PREPCOST      NUMERIC(15, 3) default 0,  /*成本*/
  AMTDISCOUNT   NUMERIC(15, 3) default 0,  /*品种折扣额$*/
  RESERVE01     VARCHAR(40),    /* 是否时价 0:否,1:时价 */
  RESERVE02     VARCHAR(40),    /* 0:eatin  1:delivery  2:takeout  3:eatin for employees*/
  RESERVE03     VARCHAR(40),    /* 优惠价类别,用于两个品种相撞的价格*/
  RESERVE04     VARCHAR(40),    /* 菜式种类
                                   0-普通主菜
                                   1-配菜
                                   2-饮料
                                   3-套餐
                                   4-说明信息
                                   5-其他,
                                   6-小费,
                                   7-计时服务项(要配合MIPRICE_SUM_UNIT使用，只有 MIPRICE_SUM_UNIT>0 才表明该品种需要开始计时和分配技师)
                                   8-普通服务项
                                   9-最低消费
                                  10-Open品种
                                  11-IC卡充值
                                  12-其它类型品种
                                  13-礼品(需要用会员券汇换)
                                  14-品种连接
                                  15-类别连接
                                  16-
                                  17-
                                  18-手写单 lzm add 2010-03-12
                                  19-拼上做法
                                  20-拼上品种
                                  21-茶位等
                                  22-差价(系统保留)
                                  23-直接修改总积分(系统保留)  //lzm add 2011-08-02
                                  24-直接修改可用积分(系统保留)  //lzm add 2011-08-02
                                  25-积分折现操作(系统保留) //lzm add 2011-08-04
                                  26-VIP卡挂失后退款(系统保留) //lzm add 2012-07-06
                                  27-VIP卡挂失后换卡(系统保留) //lzm add 2012-07-06
                                  28-分[X]席(系统保留) //lzm add 【2012-11-07】
                                  29-计量单位 lzm add 2012-11-17
                                */
  RESERVE05     VARCHAR(40),    /*jaja  【估清】菜式的数量  2001-4-17  -1和空=不限数量 >=0代表现存的品种数量*/
  SORTORDER     INTEGER default 0,      /*排序*/
  TOUCHSCRID    INTEGER,                /*不需要厨房划单 0=需要划单 1=不需要划单 lzm modify 2010-01-16*/
  TOUCHSCRLINEID        INTEGER,        /*不需要打折(与T:有相同的作用,但T:可以不计入最低消费,而这个需要计入最低消费)  lzm modify 2010-01-16*/
  SIMPLENAME    VARCHAR(100),           /*简称*/
  BARCODE       VARCHAR(40),            /*条码*/
  CODE          VARCHAR(40),
  NEEDADDTOTG   INTEGER,                /*是否在报表中出现*/
  COST          NUMERIC(15, 3),         /*成本*/
  KICKBACK      NUMERIC(15, 3),         /*员工提成*/
  MENUITEMNAME_LANGUAGE VARCHAR(100),   /*英语名称*/
  SIMPLENAME_LANGUAGE   VARCHAR(100),   /*简称(一般用于厨房的打印)*/
  ISINFOMENUITEM        INTEGER,        /*是否是附加信息 0或空=否 1=是 */
  BALANCEPRICE  NUMERIC(15, 3),         /*差价*/
  TS_TSCHROW    VARCHAR(40), --INTEGER, /*OtherCode其它编码 例如SAP的物料ItemCode*/
  TS_TSCHCOL    INTEGER,                /*是否隐藏该品种 0或空=不隐藏 1=隐藏*/
  TS_TSCHHEIGHT INTEGER,                /*是否系统保留 0或空=否 1=是*/
  TS_TSCHWIDTH  INTEGER,                /*附加信息价格是否根据数量变化而变化 0=根据数量变化 1=固定加格 lzm add 2009-07-26*/
  TS_TLEGEND    VARCHAR(240),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(240),
  TS_TSCHFONT   VARCHAR(40) DEFAULT 'Arial', --DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,        /*无需积分 0或空=否 1=是 lzm modify 2009-08-11*/
  TS_TSNEXTSCR  INTEGER,                /*对应原材料表Ware的ID编号 lzm modify 2009-08-04*/
  TS_BALANCEPRICE       NUMERIC(15, 3), /*扣除的积分 lzm modify 2010-08-23*/
  TS_TSCHCOLOR  VARCHAR(20),            /*单位2缺省数量 lzm modify 2009-10-10*/
  TS_TSCHFONTCOLOR      VARCHAR(20),    /*是否允许修改时价价格 0或空=跟系统设置 1=允许修改 2=不允许修改 lzm modify 2011-05-04*/
  TS_RESERVE01  VARCHAR(40),     /*计量单位 例如:笼*/
  TS_RESERVE02  VARCHAR(40),     /*辅助单位 例如:颗*/
  TS_RESERVE03  VARCHAR(40),     /*单位比例 例如:4    (代表1笼=4颗牛肉丸)*/
  TS_RESERVE04  VARCHAR(40),     /*账单显示的单位 0=计量单位 1=辅助单位*/
  TS_RESERVE05  VARCHAR(40),     /*计量单位2  例如:条(用于记录海鲜的条数等) lzm add 2009-08-31*/
  NEXTMICLASSID INTEGER,         /*(负数代表类别,整数代表品种或条码)点了该品种后跳动的下一个类别,或
                                     品种编号(如果是品种编号则:指明下一个要消费的品种)
                                     或品种条码(如果是品种条码则:指明下一个要消费的品种)
                                     【注意：如果该品种属于计时的服务项目，则要“开始计时”时才执行以上的动作】
                                 */
  BALANCETYPE  INTEGER,          /*差价的类型 0:直接加减 1:按百分比加减 2=补差价(即:+品种价格减去该差价的值)
                                   3=乘上指定数值 lzm add 2010-10-03*/

  MIFAMOUSBRAND VARCHAR(20),     /*品牌*/
  MICLASSNAME   VARCHAR(20),     /*所属的品种类别名称*/
  MISIZE        VARCHAR(20),     /*尺寸 大中小餐具的属性,用于在前台统计大中小的数量 lzm modify 2012-11-17*/
  MICOLOR       VARCHAR(20),     /*颜色*/
  MIBATCHPRICE  NUMERIC(15, 3),  /*批发价*/
  MISTOCKALARM_UP  INTEGER,      /*库存警告上限*/
  MISTOCKALARM_DOWN  INTEGER,    /*库存警告下限*/
  MITYPENUM     VARCHAR(20),     /*品种型号，服装*/
  MIPRICE_SUM_UNIT NUMERIC(15, 3) DEFAULT 0,        /*品种价格MIPRICE的总单位数量或时长(即:单位价格=MIPRICE_SUM_UNIT / MIPRICE)*/
  MIPRICE_DEFAULTUNIT NUMERIC(15, 3) DEFAULT 0,     /*品种价格MIPRICE的缺省数量或时长*/
  MI_MASSAGE_ADDTIME INTEGER DEFAULT 0,             /*属于按摩加钟,加钟时取上次按摩的技师*/
  MIISGROUP INTEGER DEFAULT 0,         /*属于组品种(即:在一个帐单内点该品种时其它和该帐单属于同一组编号也自动添加该品种)*/
  BEFOREORDER VARCHAR(40),             /*点击该品种前要执行的命令(这个只能执行指定的命令)*/
  AFTERORDER VARCHAR(40),              /*点击该品种后要执行的命令*/
  NEEDAFEMPID INTEGER DEFAULT 0,       /*是否需要技师 0=不需，1=需要*/
  PICTUREFILE VARCHAR(240),            /*图片文件名称(包括路径)*/
  DEPARTMENTID INTEGER,                /*所属部门编号*/
  MICOUNTWORDS INTEGER,                /*笔划*/
  MIPINYIN   VARCHAR(20),              /*其它名称信息,例如:拼音*/
  DIRECTDEC     INTEGER DEFAULT 0,     /*直接扣减库存 0=否, 1=是*/
  NOTINVOICE   INTEGER DEFAULT 0,      /*不需要在票据中出现(不需在账单打印)*/
  AREASQM    NUMERIC(15, 4) DEFAULT 0, /*面积(平方米)*/
  AREAITEM   INTEGER DEFAULT 0,        /*按面积计算*/
  NOSERTOTALPAPER INTEGER DEFAULT 0,   /*不需要入单纸*/
  COSTPERTCENT VARCHAR(10),            /*成本(原材料) 金额或百分比*/
  ABCID VARCHAR(20),                   /* ***20100615停止使用(用存储过程代替)***(A+B送C的类别编号  lzm add 【2009-05-06】)*/
  NEEDKEXTCODE INTEGER DEFAULT 0,      /*录入品种时需要录入辅助号(木夹号)*/
  ABC_DISCOUNT_MATCH_NUM VARCHAR(40),  /* ***20100917停止使用(用促销组合代替)*** 用于ABC优惠 '1':表示类型A  '2':表示类型B  '3':表示类型C  lzm add 2010-09-02*/
  WEB_TAG      INTEGER DEFAULT 0,      /*需要同步到web_midetail lzm add 2011-03-30*/
  WEB_FILE_S     VARCHAR(240),         /*小图,在web_midetail的picturefile_small lzm add 2011-03-30*/
  WEB_FILE_B     VARCHAR(240),         /*大图,在web_midetail的picturefile_big lzm add 2011-03-30*/
  WEB_FILE_S_MOBILE  VARCHAR(240),     /*手机小图,在web_midetail的picturefile_small_mobile lzm add 2011-03-30*/
  WEB_FILE_B_MOBILE  VARCHAR(240),     /*手机大图,在web_midetail的picturefile_big_mobile lzm add 2011-03-30*/
  WEB_GROUPID     INTEGER DEFAULT 0,   /*附加信息的组号,在web_midetail的groupid lzm add 2011-03-30*/
  WEB_ISHOT       INTEGER DEFAULT 0,   /*热销菜,在web_midetail的isHot lzm add 2011-03-30*/
  WEB_ISSPECIALS  INTEGER DEFAULT 0,   /*特价菜,在web_midetail的isSpecials lzm add 2011-03-30*/
  WEB_MIDESCRIPTION  VARCHAR(240),     /*品种的详细描述 lzm add 2011-03-30*/
  CLASSTYPE  VARCHAR(40) DEFAULT '',   /*所属归类 例如:啤酒 红酒 洋酒 lzm add 2011-08-09*/
  VC_RATE  INTEGER DEFAULT 1,          /*退换的单位比率 lzm add 2011-08-09
                                          如果该品种是"扎"则"单位比率"应该填入"12"
                                          如果该品种是"半扎"则"单位比率"应该填入"6"
                                       */
  VC_ITEM  INTEGER DEFAULT 0,         /*退换的品种编号 lzm add 2011-08-09*/
  INFOCOMPUTTYPE  INTEGER DEFAULT 0, /*附加信息计算方法 0=原价计算 1=放在最后计算 lzm add 2011-08-11*/

  XGDJ TEXT,    /*是否允许修改单价>>>用在Android 手机 lzm add 2011-09-23*/
  YJ TEXT,      /*>>>用在Android 手机 lzm add 2011-09-23(说明信息如果出现百分比的说明信息，是按照原价计算，还是按照其他说明信息合计之后的总价的百分比来计算)*/
  GZBH VARCHAR(40),    /*指向规则表的规则编号>>>用在Android 手机 lzm add 2011-09-23*/
  SYSCODE VARCHAR(40) DEFAULT '0',   /*>>>用在Android 手机 lzm add 2011-09-23
                              SYSCODE在  菜式类别id=1时，
                                1:1食
                                2:2食
                                3:3食
                                4:4食
                                5:5食
                                6:6食
                                7:7食
                                8:8食
                                9:9食
                                10:10食

                                11:赠送
                                12:招待

                                20:席数  --现在没有实现 syscode=20的席数功能

                              SYSCODE在  菜式类别id=2时(客人要求)，
                                取值只会等于0，表示普通syscode,而这个miclassid=2的菜式就是客人要求的菜式品种
                                0:普通
                              */
  WCONFIRM INTEGER DEFAULT 0,       /*是否需要重量确认 2012-2-22*/
  TEMPDISH INTEGER DEFAULT 0,       /*是否可以作为临时菜编号 2012-2-22*/
  OTHERPRICEID VARCHAR(40) DEFAULT NULL,      /*所属价格分类 lzm add 2012-4-19*/
  STOCKCOUNTSORI NUMERIC(15, 3) DEFAULT -1,   /*存量原始值 lzm add 2012-04-23*/
  WEBCHAT_TAG      INTEGER DEFAULT 0,      /*需要同步到 Web订餐(微信) lzm add 2014/3/13*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  STOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),        /*库存时间 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKNUM NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKORI NUMERIC(15,3) DEFAULT 0,  /*Web订餐(微信) 同步时的存量原始值 lzm add 2016-03-01*/
  WEBCHAT_SYNCSTOCKTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()), /*Web订餐(微信) 同步库存时间 lzm add 2016-03-01*/

  takeaway_Tag INTEGER DEFAULT 0,            /*外卖 外卖品种 lzm add 2018-07-30 06:57:38*/
  boxnum INTEGER DEFAULT 0,                  /*外卖 打包盒数量 lzm add 2018-07-30 06:57:38*/
  boxprice NUMERIC(15,3) DEFAULT 0,          /*外卖 打包盒单价 lzm add 2018-07-30 06:57:38*/
  minordercount INTEGER DEFAULT 0,           /*外卖 最小数量 lzm add 2018-07-30 06:57:38*/

  PRIMARY KEY (MENUITEMID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TCSL, Owner: SYSDBA */

CREATE TABLE HQ_ISSUE_TCSL   /*套餐选择  一个套餐组合为一条记录*/
(
  TCSLID        INTEGER NOT NULL,
  MENUITEMID    INTEGER NOT NULL,         /*对应的套餐品种编号*/
  SORTID        INTEGER,                  /*排序编号*/
  TCSLCOUNT     INTEGER,                  /*可选品种的数量*/
  TCSLLIMITPRICE        NUMERIC(15, 3),   /*价格上限*/
  TOUCHSCRID    INTEGER,
  COST          NUMERIC(15, 3),     /*成本*/
  KICKBACK      NUMERIC(15, 3),     /*提成*/
  PRICE         NUMERIC(15, 3),     /*在套餐中所占的价格*/
  CANREPEAT     INTEGER DEFAULT 0,  /*是否可以重复键入*/
  MAXINCOUNT    INTEGER DEFAULT 1,  /*最多可以键入的次数*/
  MININCOUNT    INTEGER DEFAULT 1,  /*最少可以键入的次数*/
  HAVEINCOUNT   INTEGER DEFAULT 0,  /*记录以选择的次数*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  TCSLNAME  VARCHAR(40),        /*名称 lzm add 2023-01-02 10:32:36*/
  TCSLMEMO  VARCHAR(100),       /*备注 lzm add 2023-01-02 10:32:41*/
  TCSL_EXTCOL JSON,             /*扩展信息 lzm add 2023-01-02 10:33:17
                                {  //留以后扩展用
                                }
                                */

  PRIMARY KEY (TCSLID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TCSL_DETAIL, Owner: SYSDBA */

CREATE TABLE HQ_ISSUE_TCSL_DETAIL   /*套餐选择详细*/
(
  CONTAINERID   INTEGER NOT NULL,
  TCSLID        INTEGER NOT NULL,  /*对应的套餐选择*/
  MENUITEMID    INTEGER,           /*可选项对应的品种编号*/
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(40),
  TOUCHSCRLINEID        INTEGER,
  TS_TSCHROW    INTEGER,
  TS_TSCHCOL    INTEGER,
  TS_TSCHHEIGHT INTEGER,
  TS_TSCHWIDTH  INTEGER,
  TS_TLEGEND    VARCHAR(100),
  TS_TLEGEND_OTHERLANGUAGE      VARCHAR(100),
  TS_TSCHFONT   VARCHAR(40) DEFAULT '宋体',
  TS_TSCHFONTSIZE       INTEGER,
  TS_TSNEXTSCR  INTEGER,
  TS_BALANCEPRICE       NUMERIC(15, 3),
  TS_TSCHCOLOR  VARCHAR(20),
  TS_TSCHFONTCOLOR      VARCHAR(20),
  TS_RESERVE01  VARCHAR(40),
  TS_RESERVE02  VARCHAR(40),
  TS_RESERVE03  VARCHAR(40),
  TS_RESERVE04  VARCHAR(40),
  TS_RESERVE05  VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (CONTAINERID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TABLE1, Owner: SYSDBA */

CREATE TABLE HQ_ISSUE_TABLE1     /*   菜式4维表(扩展价格表)   */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),    /* MIDETAIL菜式编号-MENUITEMID  */
  RESERVE02     VARCHAR(40),    /* 菜名-MENUITEMNAME,可填可不填*/
  RESERVE03     VARCHAR(40),    /*  1维 = 填入TABLE4中1维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE04     VARCHAR(40),    /*  2维 = 填入TABLE4中2维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE05     VARCHAR(40),    /*  3维 = 填入TABLE4中3维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE06     VARCHAR(40),    /*  4维 = 填入TABLE4中4维的行编号line id(TABLE4只是用于记录名称)*/
  RESERVE07     VARCHAR(40),    /*  价格  */
  RESERVE08     VARCHAR(40),    /*  数量  */
  RESERVE09     VARCHAR(40),    /*  (时间维) = TIMEPERIOD.TPID(SPID)*/
  RESERVE10     VARCHAR(40),    /*  条码 */
  RESERVE11     VARCHAR(40),    /*  打印机*/
  RESERVE12     VARCHAR(40),    /*  用餐方式编号 = DINMODES.MODEID*/
  RESERVE13     VARCHAR(40),    /*  排列编号*/
  RESERVE14     VARCHAR(40),    /*  其它类型, 1=会员价*/
  RESERVE15     VARCHAR(200),
  RESERVE16     VARCHAR(40),    /*  假日*/
  RESERVE17     VARCHAR(40),    /*  星期*/
  PRE_CLASS     VARCHAR(40),    /*  优惠价格类型(撞优惠类别)*/
  T1COST        VARCHAR(20),    /* 成本(注解:PDA点菜时不录入该值,在提交到服务端时根据选择的价格重新提取T1COST) lzm add 2010-06-09 */
  T1KICKBACK    VARCHAR(20),    /* 提成(注解:PDA点菜时不录入该值,在提交到服务端时根据选择的价格重新提取T1KICKBACK) lzm add 2010-06-09 */

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

/* Table: TABLE4, Owner: SYSDBA */
/* （例如 1维有:大,中,小 2维有:冷,热 就记录在该表内）*/

CREATE TABLE HQ_ISSUE_TABLE4    /*记录TABLE1的四个维的数据(即：本餐饮系统拥有的四维数据定义)*/
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),   /*1:一维;2:二维;3:三维;4:四维 */
  RESERVE02     VARCHAR(40),   /*各维的内容编号line id*/
  RESERVE03     VARCHAR(40),   /*名称 */
  RESERVE04     VARCHAR(40),   /*名称(英文)   */
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_MIPARINTERS  /*品种需要多份打印的打印信息表*/
(
  MIPRNID       SERIAL,
  MENUITEMID    INTEGER NOT NULL,
  PRINTCOUNT    INTEGER DEFAULT 0,
  LOGICPRNNAME  VARCHAR(100),
  HOLIDAY       VARCHAR(40),     /*假期*/
  TIMEPERIOD    VARCHAR(40),     /*时段*/
  DINMODES      VARCHAR(40),     /*用餐方式编号*/
  WEEK          VARCHAR(40),     /*星期*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MIPRNID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_WEB_MI_INFO  /*品种拥有的附加信息*/
(
  MENUITEMID INTEGER NOT NULL,  /*品种名称*/
  INFOITEMID INTEGER NOT NULL,  /*附加信息编号*/
  INFOLINEID INTEGER NOT NULL,  /*行号*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  INFOCLASSNAME VARCHAR(40) DEFAULT '',  /*分类名称 lzm add 2018-08-06 16:10:58*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID, MENUITEMID, INFOITEMID, INFOLINEID)
);

CREATE TABLE HQ_ISSUE_BUYSLGIVESL  /*买几送几*/
(
  SGID          INTEGER NOT NULL,
  SGMENUITEMID  VARCHAR(20) NOT NULL,     /*品种编号*/
  SGBUYSEVERAL  NUMERIC(15,3),   /*买几*/
  SGGIVESEVERAL NUMERIC(15,3),   /*送几*/
  SGHOLIDAY     VARCHAR(40),     /*假期*/
  SGWEEK        VARCHAR(40),     /*星期*/
  SGTIMEPERIOD  VARCHAR(40),     /*时段*/
  SGDISCOUNT    VARCHAR(40) DEFAULT '',     /*折扣金额(空或''代表-100%) ==> 10%（即：价格=10%） 10（即：价格=10元） -10%（即：减去10%） -10（即：减去10元）lzm add 2018-07-01 16:21:45*/
  SGVIP         VARCHAR(40) DEFAULT '',     /*会员卡种(多个时用,分割) lzm add 2018-07-01 16:21:41*/
  SGSHOPIDS     VARCHAR(40) DEFAULT '',     /*适合门店(多个时用,分割) lzm add 2018-07-01 16:24:10*/
  SGNAME        VARCHAR(40) DEFAULT '',     /*活动名称(从MIDETAIL_CampaignActivity来) lzm add 2018-07-01 16:32:55*/
  SGFROM        INTEGER DEFAULT 0,          /*来源 0=品种管理 1=来自营销活动*/
  SGMENUITEMNAME VARCHAR(100),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SGID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_MIDETAIL_NEXTMICLASS   /*品种对应的下一类别*/
(
  NMMENUITEMID  INTEGER NOT NULL,     /*品种编号*/
  NMLINEID      INTEGER NOT NULL,     /*顺序编号*/
  NMMICLASS     INTEGER DEFAULT 0,    /*候选类别编号*/
  NMCANREPEAT   INTEGER DEFAULT 1,    /*是否允许重复选择相同的品种*/
  NMMAXCOUNT    INTEGER DEFAULT 1,    /*最多选择次数*/
  NMMINCOUNT    INTEGER DEFAULT 1,    /*最少选择次数*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (NMMENUITEMID,NMLINEID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_MIDETAIL_SPLITPRICE   /*品种对应的大单分账*/
(
  SPMENUITEMID  INTEGER NOT NULL,          /*品种编号*/
  SPLINEID      INTEGER NOT NULL,          /*顺序编号*/
  SPITEMID      INTEGER DEFAULT 0,         /*分账的品种编号*/
  SPITEMNAME    VARCHAR(100),              /*分账的品种名称*/
  SPITEMPRICE   NUMERIC(15,3) DEFAULT 0,   /*分账的品种价格*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SPMENUITEMID,SPLINEID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_MIDETAIL_STOCK_ERP   /*品种对应的ERP存量*/ /*lzm add 2021-11-16 04:03:10*/
(
  MENUITEMID  INTEGER NOT NULL,            /*品种编号  当menuitemid-1时： STOCKNUM=0.000代表可以负库存销售， STOCKNUM=1.000代表不可以负库存销售*/
  STOCKNUM numeric(15,3) DEFAULT 0,        /*存量数量*/
  STOCKTIME timestamp default null,        /*存量的时间*/
  PRODUCT_ID integer default 0,            /*ERP商品的id*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,MENUITEMID)
);

CREATE TABLE HQ_ISSUE_MIWITHMI_CLASSSORT  /*有多个相同优惠类别时,那个优先*/
(
  MWMCID           SERIAL,
  MWMCLASSID       INTEGER NOT NULL,   /*(停用)类别id*/
  MWMCSORTCLASSID  INTEGER NOT NULL,   /*排列类别id*/
  MWMCSORTORDER    INTEGER DEFAULT 0,
  MWMCSORTCONDITION     INTEGER DEFAULT 0,  /*有两个相同类别品种时,那个优先.0=最低价优先,1=最高价优先*/
  MWMCLASSID_CHAR  VARCHAR(40),        /*类别ID*/
  MWMCNOTE         VARCHAR(40),        /*撞餐类别说明*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MWMCID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_DEPARTMENTINFO  /*部门信息*/
(
  DEPARTMENTID INTEGER NOT NULL,
  DEPARTMENTNAME  VARCHAR(40),
  DEPARTMENTNAME_LANGUAGE  VARCHAR(40),
  DEPTUSERCODE VARCHAR(30),             /*用户编号 lzm add 2009-08-29*/
  DEPT2DEPOTID INTEGER DEFAULT 0,       /*与部门挂钩的仓库编号 lzm add 2009-09-09*/
  LOGICPRNNAME VARCHAR(40),             /*部门对应的打印机 用于wpos的部门信息通知 lzm add 2011-10-10*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (DEPARTMENTID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_FAMILYGROUP /*报表辅助分类1*/
(
  FGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (FGID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_GENERATOR  /*编号*/
(
  GENERATORID   SERIAL,
  GENERATORNAME VARCHAR(40) NOT NULL ,
  VAL   NUMERIC(10,0) DEFAULT 0 NOT NULL ,
  VALCHAR       VARCHAR(40) DEFAULT '',
  VALTIME       TIMESTAMP,

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,GENERATORID)
);

CREATE TABLE HQ_ISSUE_MIHOLIDAY  /*(品种,服务费)的假期*/
(
  MIHID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  SDAY  VARCHAR(40),  /*开始日期*/
  EDAY  VARCHAR(40),  /*结束日期*/
  GROUPID  VARCHAR(10),  /*所属的组编号*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (MIHID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_MITIMEPERIOD /*(品种,服务费,折扣)的时段*/
(
  MITID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME VARCHAR(40),  /*开始时间*/
  ETIME VARCHAR(40),  /*结束时间*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (MITID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_MIMAKEUP  /*品种的原材料构成*/
(
  MENUITEMID    INTEGER NOT NULL,             /*品种编号*/
  MTID          VARCHAR(30) NOT NULL,         /*原材料用户编号，对应进销存原材料的UserCode*/
  AMOUNT        NUMERIC(15, 3) DEFAULT 0,     /*销售单价*/
  MMCOUNTS      NUMERIC(15, 3) DEFAULT 0,     /*数量*/
  UNIT          VARCHAR(30),                  /*单位1*/
  LINEID        INTEGER DEFAULT 0,            /*行号*/
  UNITOTHERCOUNTS  NUMERIC(15, 3) DEFAULT 0,  /*单位2数量*/
  DEPOTID       INTEGER DEFAULT 0,            /*仓库编号*/
  WAREID        INTEGER DEFAULT NULL,         /*原材料ID编号*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MENUITEMID,MTID,USER_ID,SHOPID,SHOPGUID)
);


--end--------------------------------需要同步的品种表-----------------------------------

--start--------------------------------会员信息-----------------------------------
CREATE TABLE HQ_ISSUE_ABUYER
(
  ABID  SERIAL,
  BUYERID       VARCHAR(40) DEFAULT '' NOT NULL,
  BUYERNAME     VARCHAR(200),          /*姓名*/
  BUYERADDRESS  VARCHAR(200),          /*地址*/
  BUYERTEL      VARCHAR(100),          /*手机*/
  BUYERSEX      VARCHAR(10),           /*性别*/
  BUYERZIP      VARCHAR(20),           /*邮编*/

  BUYERLANG     VARCHAR(40),           /*语言*/
  BUYERFAX     VARCHAR(40),            /*传真*/
  BUYEREMAIL   VARCHAR(40),            /*EMAIL*/
  BUYERPOSITION  VARCHAR(40),          /*职务*/
  BUYERCOMPAY  VARCHAR(40),            /*单位.公司名称*/
  BUYERTYPEID     VARCHAR(10),         /*客户类型编号(A卡,B卡,C卡,D卡,E卡,散客,团队,会议,长包公司,永久帐户...)*/
  BUYERCERTIFICATEID  VARCHAR(10),     /*证件类型编号(身份证,驾驶执照...)*/
  BUYERCERTIFICATENUM  VARCHAR(50),    /*证件号码*/
  BUYERNATIONALITYID  VARCHAR(10),     /*国籍编号(中国,美国,德国...)*/
  BUYERNATIVEPLACEID  VARCHAR(10),     /*籍贯编号(广州,北京,上海,成都...)*/
  BUYERBIRTHDAY  TIMESTAMP,            /*生日.出生日期*/
  BUYERTITLEID    VARCHAR(10),         /*称谓编号(先生,女士,夫人,小姐...)*/
  BUYERPASSPORTTYPEID  VARCHAR(10),    /*护照类型编号(...)*/
  BUYERPASSPORTNUM  VARCHAR(50),       /*护照号码*/
  BUYERVISATYPEID  VARCHAR(10),        /*签证类型编号(...)*/
  BUYERVISAVALIDDAY  TIMESTAMP,        /*签证有效日期*/
  BUYERIMAGEDIR  VARCHAR(50),          /*照片路径*/

  BUYERDEPUTY  VARCHAR(20),            /*企业代表人*/
  BUYERLIKEROOM  VARCHAR(50),          /*满意房间*/
  BUYERSERVICE  VARCHAR(100),          /*房间服务*/
  BUYERSPECIALNEED  VARCHAR(200),      /*特殊要求*/
  BUYERCONFERCON  VARCHAR(254),        /*协议内容*/
  BUYERNOTE1  VARCHAR(200),            /*备注*/
  BUYERISCONFER  INTEGER,              /*是否协议单位 0=否,1=是*/
  BUYERCLASS  INTEGER,                 /*所属宾客 0=内宾,1=外宾(1001=欧美 1002=亚洲),2=香港,3=台湾*/
  BUYERWRITEMAN  VARCHAR(200),         /*签单人*/
  BUYERCODE  VARCHAR(20),              /*会员代码*/
  BUYERPINYIN  VARCHAR(20),            /*拼音*/
  LASTCONSUMEDATE TIMESTAMP,           /*最后消费日期*/
  --BUYERROWSTATUS INTEGER DEFAULT 0,  /*数据状态: 0=新记录, 1=已同步*/

  ADDEMPNAME  VARCHAR(40),             /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,               /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),             /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),             /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,               /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),             /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),             /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,               /*同步时间VER7.2.0 X3*/

  --IDVALUE     VARCHAR(40),             /*卡号 lzm add 2010-05-07*/
  BUYERTEL1   varchar(100),            /*电话1 lzm add 2010-12-08*/
  BUYERTEL2   varchar(100),            /*电话2 lzm add 2010-12-08*/
  BUYERTEL3   varchar(100),            /*电话3 lzm add 2010-12-08*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY(ABID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_VIPDISCOUNT  /*会员积分对应的折扣*/
(
  VSEMPLASSID     INTEGER NOT NULL,      /*会员类别编号*/
  VSLINEID        INTEGER NOT NULL,      /*折扣行编号*/
  VSQ             INTEGER NOT NULL,      /*积分数*/
  VSDISCOUNT      VARCHAR(10) NOT NULL,  /*折扣  10=10元,10%=9折*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (VSEMPLASSID,VSLINEID,USER_ID,SHOPID,SHOPGUID)
);
CREATE TABLE HQ_ISSUE_TABLE6  /* 会员卡 VIP 积分管理 */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*累积消费额*/
  RESERVE02     VARCHAR(40),  /*会员券*/
  RESERVE03     VARCHAR(40),  /*对应VIP类别编号*/
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------会员信息-----------------------------------

--start--------------------------------台号信息-----------------------------------
CREATE TABLE HQ_ISSUE_ATABLESECTIONS  /*区域名称*/
(
  SECNUM      SERIAL,
  SECID       VARCHAR(10) DEFAULT '',
  SECNAME     VARCHAR(40),
  SECNAME_LANGUAGE  VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SECNUM,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_ATABLES
(
  ATABLESID     INTEGER NOT NULL,
  ATABLESNUM    INTEGER,             /* not use again */
  SEATCOUNT     INTEGER,             /*容许最大人数*/
  TABLEUSED     INTEGER DEFAULT 0,   /* 0空闲， 1被占用  newadd  2预订,3合桌(被合并到的,核心的),4拆台,5维修,6清洁,7预订,8过夜*/
  RESERVE01     VARCHAR(40),            /* 台号名称 use to remember the table name 不能有重复*/
  RESERVE02     VARCHAR(40),            /* 如为合桌或拆台,则记录是从那个台号合桌或拆台,格式:拆+台号,并+台号，如为预定则记录'Book'*/
  RESERVE03     VARCHAR(40),            /* 餐区,即台号分区显示*/
  RESERVE04     VARCHAR(40),            /* aTOUCHSCRLINEID*/
  RESERVE05     VARCHAR(40),            /* aTSCHID */
  SMSTABLEID    VARCHAR(10),            /*短信点菜的台号编号*/
  SORTORDER     INTEGER DEFAULT 0,      /*排列序号*/
  LOGICPRNNAME VARCHAR(100) DEFAULT '', /*要打印到的逻辑打印机*/

  BUILDINGNUM   VARCHAR(20),           /*楼号,那栋楼*/
  FLOORNUM      VARCHAR(20),           /*楼层*/
  ATABLECLASS   VARCHAR(20),           /*类别(房间,台号,厅,计时房间或椅号,散客区)*/
  ATABLETYPE    VARCHAR(20),           /*类型(标准,单人,双人,三人,四人,五人,普通套房,豪华套房)*/
  BEGINORDER    VARCHAR(40),           /*开房或台时要执行的命令*/
  BEGINMENUITEM VARCHAR(40),           /*开房或台时要消费的品种*/
  MINPRICE_MENUITEMID  VARCHAR(40),    /*最低消费对应的品种编号*/
  TABLEPRICE    NUMERIC(15, 3) DEFAULT 0,        /*房间价格                         100元  */
  COMPUTETIME   INTEGER DEFAULT 0,               /*房价计算时间(分钟)               60分钟:代表每小时100元   */
  UNITTIME      INTEGER DEFAULT 0,               /*房价最小单位(分钟)要小于计算时间 30分钟:代表半小时一计    */
  MINPRICE_NOTT INTEGER DEFAULT 0,         /*最低消费是否包括特价品种(T:) 0＝否，1＝是*/
  MINPRICE_MAN  INTEGER DEFAULT 0,         /*最低消费按人数算 0＝否，1＝是*/
  THETABLE_IST  INTEGER DEFAULT 0,         /*房价特价不打折 0＝否，1＝是*/
  THETABLE_ISF  INTEGER DEFAULT 0,         /*房价免服务费 0＝否，1＝是*/
  MINPRICE_NOTTABLE  INTEGER DEFAULT 0,    /*最低消费是否包括房价 0＝否，1＝是*/
  NEEDSUBTABLEID INTEGER DEFAULT 1,        /*同台多单时需要录入子台号*/
  UNITEATABLEID  VARCHAR(40),              /*合并台号的ID，用于并台*/
  TBLPRICE_MENUITEMID VARCHAR(40),         /*房价对应的品种编号*/
  TBLTOTALPAGEPRN  VARCHAR(40),            /*总单打印机*/
  ADDPARTYNUM   INTEGER DEFAULT 0,         /*允许搭台的数量. >1才会在前台弹出搭台窗口,例如6=(A,B,C,D,E,F)*/
  TRUNTOPRINT   VARCHAR(240),              /*打印机转向设置(一行设置一个打印机的转向) 例如:一楼厨房=二楼厨房 */
  TABLECOLOR    VARCHAR(40),               /*台号的颜色 空:还原颜色的正常显示 lzm add 2010-06-06*/
  WEB_TAG      INTEGER DEFAULT 0,          /*需要同步到web_atables lzm add 2011-03-30*/

  FWFMC VARCHAR(40),   /*服务费名称---->根据简单设置表的服务费名称得到相应的服务费率>>>用在Android 手机 lzm add 2011-09-23*/

  COMMISSIONVALUE NUMERIC(15, 3) DEFAULT 0,  /*帮订人的提成起始金额 lzm add 2011-10-12*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  KICHENPRINTER INTEGER DEFAULT 0,          /*是否出品打印机，目前用于上菜厨房打印 lzm add 2018-10-23 03:37:25*/
  QJPRINTER VARCHAR(100) DEFAULT '',        /*上菜时厨房需要打印的打印机，空=全部出品打印 非空=指定的逻辑打印机  lzm add 2018-10-23 03:39:06*/
  
  PRIMARY KEY (ATABLESID,USER_ID,SHOPID,SHOPGUID)
);
--end---------------------------------台号信息-----------------------------------

--start--------------------------------打印机信息-----------------------------------
CREATE TABLE HQ_ISSUE_APRINTERS
(
  PRINTERID     INTEGER NOT NULL,
  LOGICPRNNAME  VARCHAR(100), /*逻辑打印机名称*/
  PHYICPRNNAME  VARCHAR(100), /*系统打印机名称 OPOS(OPOSCOM1 OPOSCOM2 ..)*/
  RESERVE01     VARCHAR(40),  /*打印机所在的机器IP*/
  RESERVE02     VARCHAR(40),  /*打印机类型*/
  RESERVE03     VARCHAR(40),  /*打印方法:0=通过打印驱动程序 1=通过打印驱动程序发控制码打印 3=通过串并口直接打印  (作废->:0=driverrawprint,1=drivercodeprint,2=driverdocprint,3=oposprint)*/
  RESERVE04     VARCHAR(40),  /*候选1(曾经停用)*/
  RESERVE05     VARCHAR(40),  /*分单打印时的总单:一个品种一张单 0=否 1=是                      候选2(停用)*/
  RESERVE06     VARCHAR(40),  /*上菜不需要打印分单 //lzm modiry 2013-01-15                     候选3(停用)*/
  RESERVE07     VARCHAR(40),  /*候选4(停用)*/
  RESERVE08     VARCHAR(40),  /*打印失败的逻辑打印机跳单顺序
                                多个时用","分隔
                              */
  RESERVE09     VARCHAR(200),  /*总单打印机 多个时用逗号","分隔*/
  RESERVE10     VARCHAR(40),  /*单据抬头*/
  RESERVE11     VARCHAR(40),  /*打印机所在的机器名称(用于判断是否是本机) 空代表本地打印 */
  RESERVE12     VARCHAR(40),  /*打印端口(LPT1:,COM1)*/
  TOASPRINT     INTEGER DEFAULT 0, /*分单或总单打印(ToAllSinglePrint),0=总单打印,1=分单打印,2=先总单后分单,3=先分单后总单*/
  COMPARAM      VARCHAR(40),  /*串口参数*/
  TPPRINT       INTEGER DEFAULT 0, /*总单品种打印方法: 0=合并打印 1=按逻辑打印机分开打印*/
  TCALONEPRNINTP   INTEGER DEFAULT 0, /*总单的套餐需要单独打印: 0=不需要 1=需要单独打印*/
  PRNSTATUS     INTEGER,      /*打印机状态*/
  LABELPARAM    VARCHAR(200), /*标签打印机参数，用逗号分隔参数.*/
  TOTALPAGEM    INTEGER DEFAULT 3,    /*总单打印机的打印方式
                                        0=不打印
                                        1=打印到本打印机
                                        2=打印到台号指定的总单打印机
                                        3=打印到RESERVE09指定的打印机
                                      */
  WORKTYPE      INTEGER DEFAULT 0,    /*工作方式 0=需要打印 1=该打印机停止打印*/
  BITMAPFONT    INTEGER DEFAULT 0,    /*按位图方式打印所有文字*/

  PCOPYSINALL   INTEGER DEFAULT 1,    /*总单打印份数 lzm add 2009-08-01*/
  PCOPYSINSIN   INTEGER DEFAULT 1,    /*分单打印份数 lzm add 2009-08-01*/
  NEEDCHGTLE    INTEGER DEFAULT 0,    /*是否需要转台单 lzm add 2010-06-29 */
  HASTENPRN     VARCHAR(200),         /*催单打印机 lzm add 2010-08-19*/
  BEEPBEEP      INTEGER DEFAULT 0,    /*来单蜂鸣提醒 lzm add 2010-09-29*/
  VOIDOTHERPRN  VARCHAR(200),         /*取消单逻辑打印机 lzm add 2010-11-03*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (PRINTERID,USER_ID,SHOPID,SHOPGUID)
);
--end----------------------------------打印机信息-----------------------------------

--start--------------------------------节假日信息-----------------------------------
CREATE TABLE HQ_ISSUE_TIMEPERIOD  /*报表对应的时段*/
(
  TPID  INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME TIMESTAMP,
  ETIME TIMESTAMP,
  RESERVE01     VARCHAR(40),  /*当天的Start SPID*/
  RESERVE02     VARCHAR(40),  /*当天的End SPID,如为负数则为第二天的End SPID*/
  RESERVE03     VARCHAR(40),  /*开始时间*/
  RESERVE04     VARCHAR(40),  /*结束时间*/
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TPID,USER_ID,SHOPID,SHOPGUID)
);

--end----------------------------------节假日信息-----------------------------------

--start--------------------------------下拉框信息-----------------------------------
CREATE TABLE HQ_ISSUE_LISTCLASS  /*下拉项 */
(
  LCLAID   INTEGER NOT NULL,
  CAPTION  VARCHAR(40),
  CAPTION_LANGUAGE  VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (LCLAID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_LISTCONTENT  /*下拉内容*/
(
  LCLAID    INTEGER NOT NULL,
  LCONID    INTEGER NOT NULL,
  CONTENTS  VARCHAR(40),        /*下拉内容*/
  SHUTCUTKEY  VARCHAR(40),      /*下拉内容的缩写. 例如LCLAID=5时 代表该国家的简称*/
  OTHERINFO  VARCHAR(40),       /*下拉内容的相关信息
                              当:LCLAID=10时 0=不能进入该台,空和1=允许进入该台
                             */
  CONTENTS_LANGUAGE VARCHAR(40), /*英语*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY(LCLAID,LCONID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------下拉框信息-----------------------------------

--start--------------------------------界面信息-----------------------------------
CREATE TABLE HQ_ISSUE_TOUCHSCR  /*界面*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHNAME      VARCHAR(100),
  RESERVE01     VARCHAR(40),  /*界面属性  模板编号*/
  RESERVE02     VARCHAR(40),  /*子类别或子品种所在的界面*/
  RESERVE03     VARCHAR(40),  /*自动开单参数
                              (
                               AutoOpenChecks 开单类型[0：无；1：堂食；2：外送；3:外带]
                               ,WhenReOpenFalse 取已结单失败后是否开新单[0:否,1:是]
                               ,WhenPickupFalse 取没结单失败后是否开新单[0:否,1:是]
                               ,AfterQueryChecks 查单后是否开新单[0:否,1:是]
                               ,AfterServiceTotal 入单后是否开新单[0:否,1:是]
                               ,AfterTenderMedia 结帐后是否开新单[0:否,1:是]
                              )*/
  RESERVE04     VARCHAR(40),  /*是否需要复位登陆数据,0=false,1=true*/
  RESERVE05     VARCHAR(40),  /*是否需要弹出显示和相关参数
                                    位置1:空或0=false 1=true lzm modify 2010-07-21
                                    位置2:0=点击界面上的按钮后自动隐藏当前界面 1=不隐藏
                                    位置3:0=点击界面按钮后不隐藏当前界面 1=点击按钮后隐藏当前界面 lzm add 2010-10-10*/
  TSCHROW       INTEGER,
  TSCHCOL       INTEGER,
  TSCHHEIGHT    INTEGER,
  TSCHWIDTH     INTEGER,
  RELATE_TS01   INTEGER,  /*相关界面1*/
  RELATE_TS02   INTEGER,  /*相关界面2*/
  RELATE_TS03   INTEGER,  /*相关界面3*/
  RELATE_TS04   INTEGER,  /*相关界面4*/
  RELATE_TS05   INTEGER,  /*相关界面5*/
  RELATE_TS06   INTEGER,  /*相关界面6*/
  TSDETAILMAXLINEID     INTEGER DEFAULT 0,
  PTS   INTEGER,                /**/
  NTS   INTEGER,                /*做法1 做法2 做法3 ....做法N 所在的界面编号 0或空=无  lzm add 【2009-05-26】*/
  TSTIMESTAMP   TIMESTAMP,      /*修改时间*/
  PICTUREFILE   VARCHAR(240),   /*图片文件名称(包括路径)*/

  PANELMARGIN   VARCHAR(100),   /*LeftMargin,RightMargin,TopMargin,BottomMargin  lzm add 2011-11-22*/
  TITLETEXT     VARCHAR(100),   /*抬头内容  lzm add 2011-11-22*/
  TITLEFONT     VARCHAR(100),   /*抬头字体 charset,color,height,name,pitch,size,style  lzm add 2011-11-22*/
  BEVELWIDTH    INTEGER,        /*边框宽度 0=不显示边框 lzm add 2011-11-22*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TSCHID,USER_ID,SHOPID,SHOPGUID)
);
s
CREATE TABLE HQ_ISSUE_TSDETAIL  /*按钮*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHLINEID    INTEGER NOT NULL,
  TSCHROW       INTEGER,
  TSCHCOL       INTEGER,
  TSCHHEIGHT    INTEGER,
  TSCHWIDTH     INTEGER,
  TLEGEND       VARCHAR(100),                   /*按钮名称*/
  TSCHFONT      VARCHAR(40) DEFAULT 'arial',
  TSCHFONTSIZE  INTEGER,
  BCID  INTEGER,
  ANUMBER       INTEGER,
  ANUMERIC      INTEGER,                        /*not use 数据类型不对（快捷键）*/
  TSNEXTSCR     INTEGER,                        /*下一界面编号*/
  BALANCEPRICE  NUMERIC(15, 3),                 /*差价(-10=加10 10=减10)*/
  TSCHCOLOR     VARCHAR(20),
  TSCHFONTCOLOR VARCHAR(20),
  RESERVE01     VARCHAR(40),                    /*按钮类型
                                                  空或0=TFreebutton

                                                */
  RESERVE02     VARCHAR(40),                    /**/
  RESERVE03     VARCHAR(40),                    /*快捷键*/
  RESERVE04     VARCHAR(40),                    /*颜色模版编号*/
  RESERVE05     VARCHAR(40),                    /**/
  TLEGEND_LANGUAGE      VARCHAR(100),           /*按钮英文名称*/
  TSVISIBLE     INT DEFAULT 1,                  /*按钮是否显示*/
  TSDPARAMETER  TEXT,                           /*按钮参数*/
  BALANCETYPE INTEGER DEFAULT 0,                /*差价的类型 0:直接减, 1:百分比, 2:等于品种价格减去该价格的值*/
  VALIDATEUSERSCLASS VARCHAR(254),              /*不需授权用户组,多个用户组时用";"号分割*/
  PICTUREFILE VARCHAR(240),                     /*图片文件名称(包括路径)*/
  VMICLASS text,                                /*不需需要授权的类别编号,有多个时用";"号分割*/
  VOPERATE VARCHAR(240),                        /*需要授权的操作*/
  ONBEFOREEVENT VARCHAR(200),                   /*执行前需要运行的批处理 lzm add 20100503*/
  ONAFTEREVENT VARCHAR(200),                    /*执行后需要运行的批处理 lzm add 20100503*/
  PRINTTEMPLATE VARCHAR(200),                   /*该事件前台打印需要用到的打印模版 lzm add 20100503*/
  PRINTCOUNT VARCHAR(40),                       /*该事件的前台打印份数 lzm add 20100504*/
  EXTPARAM VARCHAR(240),                        /*按钮扩展参数 lzm add 20100504*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TSCHID, TSCHLINEID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_TABLE7  /* 前台界面 按钮颜色模块---->TSDETAIL  */
(
  TBID  INTEGER NOT NULL,
  RESERVE01     VARCHAR(40),  /*已停用：记录Button类型  0-TExplorerButton, 1-NewButton */
  RESERVE02     VARCHAR(40),  /* 名称*/
  RESERVE03     VARCHAR(40),  /*TSCHCOLOR 按钮颜色*/
  RESERVE04     VARCHAR(40),  /* Bitmap  对于TSDETAIL.RESERVE02=0 此项不起作用; 只取文件名,不取路径,路径定死为:client.exe所在的目录再加上\Picture,如c:\SuperTouch\Picture  */
  RESERVE05     VARCHAR(40),  /* down Bitmap  对于TSDETAIL.RESERVE02=0 此项不起作用; 只取文件名,不取路径,路径定死为:client.exe所在的目录再加上\Picture,如c:\SuperTouch\Picture  */
  RESERVE06     VARCHAR(40),  /*TSCHFONTname*/
  RESERVE07     VARCHAR(40),  /*TSCHFONTSIZE*/
  RESERVE08     VARCHAR(40),  /*TSCHFONTCOLOR*/
  RESERVE09     VARCHAR(40),  /*文字位置*/
  RESERVE10     VARCHAR(40),  /*图片位置*/
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200),
  /*BMPDOWN     BLOB SUB_TYPE 0 SEGMENT SIZE 80,*/
  /*BMP BLOB SUB_TYPE 0 SEGMENT SIZE 80,*/
  TSFONT1        VARCHAR(100),  /*font1的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT2        VARCHAR(100),  /*font2的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT3        VARCHAR(100),  /*font3的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT4        VARCHAR(100),  /*font4的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT5        VARCHAR(100),  /*font5的属性(charset,color,height,name,pitch,size,style)*/
  FONTSTYLE      INTEGER,    /*font.style 1=bold,2=ltalic,4=underline,8=strikeout*/
  PERLINEHAVEFONT  INTEGER DEFAULT 0,   /*每行文字用FONT而不是TSFONT1..TSFONT5*/
  BUTTONSTYLE    INTEGER DEFAULT 0,    /*按钮的类型(0=同系统按钮,1=Flat按钮,2=Class按钮,3=3D按钮)*/
  TEXTPOSITION    VARCHAR(20),    /*按钮文字的对齐方式*/
  GLYPHPOSITION    VARCHAR(20),    /*按钮图片的对齐方式*/
  BMPDOWN        VARCHAR(40),
  BMP            varchar(40),
  TransparentGlyph INTEGER DEFAULT 1,   /*图片背景透明*/
  FOLLOWSCREENTHEME INTEGER DEFAULT 1,  /*跟主题 0=否 1=是 lzm add 2011-11-21*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_TABLE9    /*批处理事件-快捷输入:*05开头+对应的事件ID*/
(
  TBID  INTEGER NOT NULL, /*引用ID*/
  RESERVE01     VARCHAR(40), /*执行事件命令类型:0-内部事件;1-外部的EXE*/
  RESERVE02     VARCHAR(40), /*注解具体命令*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  RESERVE06     VARCHAR(40),
  RESERVE07     VARCHAR(40),
  RESERVE08     VARCHAR(40),
  RESERVE09     VARCHAR(40),
  RESERVE10     VARCHAR(40),
  RESERVE11     VARCHAR(40),
  RESERVE12     VARCHAR(40),
  RESERVE13     VARCHAR(40),
  RESERVE14     VARCHAR(40),
  RESERVE15     VARCHAR(200), /*内容:内部事件---[功能号1,事件ID1{参数1}{参数2}..][功能号2,事件ID2{参数1}{参数2}..]..*/
                           /*     外部的EXE---具体路径{参数},可带参数    */
  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TBID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_SCREEN_THEME  /* 界面主题配置 lzm add 2011-11-19*/
(
  TBID  INTEGER NOT NULL,     /*主题编号*/
  CLASSID     VARCHAR(40),    /*主题界面编号
                                MICLASS=大类
                                MICLASSOTHER=小类
                                MIDETAIL=品种
                                MICLASSINFO=附加信息类别
                                MIDETAILINFO=附加信息
                                TABLE=台号
                                OTHER=其它
                                BACKROUND=底色*/
  CLASSNAME     VARCHAR(40),  /* 名称 */
  TSFONT0       VARCHAR(100), /*font0的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT1       VARCHAR(100), /*font1的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT2       VARCHAR(100), /*font2的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT3       VARCHAR(100), /*font3的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT4       VARCHAR(100), /*font4的属性(charset,color,height,name,pitch,size,style)*/
  TSFONT5       VARCHAR(100), /*font5的属性(charset,color,height,name,pitch,size,style)*/
  BTNCOLOR      VARCHAR(40),  /*底色*/
  PERLINEHAVEFONT  INTEGER DEFAULT 0,   /*每行文字用FONT而不是TSFONT1..TSFONT5*/
  BUTTONSTYLE    INTEGER DEFAULT 0,    /*按钮的类型(0=同系统按钮,1=Flat按钮,2=Class按钮,3=3D按钮)*/
  TEXTPOSITION    VARCHAR(20),    /*按钮文字的对齐方式*/
  GLYPHPOSITION    VARCHAR(20),    /*按钮图片的对齐方式*/
  TransparentGlyph INTEGER DEFAULT 1,   /*图片背景透明*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  BUTTONOTHER VARCHAR(200) DEFAULT '',   /*按钮其它属性逗号分隔 lzm add 2021-03-23 17:56:18
                                            (fillet=1[圆角 0=否 1=是],)
                                          */

  PRIMARY KEY (TBID,CLASSID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_TSDETAILFORM  /*按钮授权列表(用于非动态按钮的授权)*/
(
  TSCHID        INTEGER NOT NULL,
  TSCHLINEID    INTEGER NOT NULL,
  TLEGEND       VARCHAR(100) NOT NULL,        /*按钮名称(formname+buttonname)*/
  VALUSERSCLASS VARCHAR(40),                  /*授权用户组,多个用户组时用";"号分割*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (TSCHID, TSCHLINEID, TLEGEND,USER_ID,SHOPID,SHOPGUID)
);
CREATE TABLE HQ_ISSUE_GRIDCOLSETUP  /*表格列设置*/
(
  GCID          INTEGER NOT NULL,
  GCGRIDID      VARCHAR(254) NOT NULL,
  GCFIELDNAME   VARCHAR(60),
  GCSYSNAME     VARCHAR(60),
  GCUSERNAME    VARCHAR(60),
  GCCAPTION     VARCHAR(100),
  GCWIDTH       INTEGER DEFAULT 10,
  GCVISIBLE     INTEGER DEFAULT 1,
  GCCOLORDER    INTEGER DEFAULT 0,

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (GCID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------界面信息-----------------------------------

--start------------------------------班次信息-----------------------------------
CREATE TABLE HQ_ISSUE_SHIFTTIMEPERIOD /*收银员时段对应的班次*/
(
  STPID INTEGER NOT NULL,
  NAME  VARCHAR(40),
  STIME VARCHAR(40),  /*开始时间*/
  ETIME VARCHAR(40),  /*结束时间*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (STPID,USER_ID,SHOPID,SHOPGUID)
);
--end--------------------------------班次信息-----------------------------------

CREATE TABLE HQ_ISSUE_WEB_GROUP /*附加信息所属组信息 lzm add 2011-08-10*/
(
  WEB_GROUPID    INTEGER NOT NULL,   /*组号*/
  WEB_GROUPNAME  VARCHAR(40),        /*名称*/
  WEB_GROUPMEMO  VARCHAR(100),       /*备注*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  MENUITEMID INTEGER DEFAULT 0,   /*品种编号  //lzm add 2022-12-31 11:36:09 */
  WEB_EXTCOL JSON,   /*扩展信息  //lzm add 2022-12-31 11:36:09*
                      {"canrepeat": "0",   //是否可以重复键入
                       "maxincount": "1"   //最多可以键入的次数
                       "minincount": "1"   //最少可以键入的次数
                      }
                      */
  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,WEB_GROUPID)
);

--start------------------------------服务费-----------------------------------
CREATE TABLE HQ_ISSUE_SERVICEAUTO  /*服务费*/
(
  SAID          INTEGER NOT NULL,
  SANAME        VARCHAR(40),     /*服务费的名称*/
  SATYPE        INTEGER,         /*0=百分比 , 1=金额 */
  PERSAPRICE    NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTSAPRICE    NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  SAHOLIDAY     VARCHAR(40),     /*假期*/
  SATIMEPERIOD  VARCHAR(40),     /*时段*/
  SADINMODES    VARCHAR(40),     /*用餐方式编号*/
  SAWEEK        VARCHAR(40),     /*星期*/
  SACOMPUTTYPE  VARCHAR(10),     /*计算方式 1=开新单计, 2＝即时计*/
  LIDU  INTEGER,           /*
                             = 0; //对账单中的当前品种添加服务费
                             = 1; //代表对账单中的当前的品种添加服务费
                             = 2; //下一菜式要收服务费
                             = 3; //取消2方式定义的服务费
                             = 4; //对账单中的所有的菜项添加服务费
                           */
  BCID          INTEGER,
  ANUMBER       INTEGER,

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (SAID,USER_ID,SHOPID,SHOPGUID)
);
--end--------------------------------服务费-----------------------------------

--start------------------------------折扣-----------------------------------
CREATE TABLE HQ_ISSUE_DISCOUNT  /*折扣*/
(
  DISCOUNTID    INTEGER NOT NULL,
  DISCOUNTNAME  VARCHAR(40),
  DISCOUNTTYPE  INTEGER,         /*0=百分比, 1=金额*/
  PERDISCOUNT   NUMERIC(15, 3),  /*百分比金额，DISCOUNTTYPE＝0 时提取该值*/
  AMTDISCOUNT   NUMERIC(15, 3),  /*直接金额，DISCOUNTTYPE＝1 时提取该值*/
  LIDU  INTEGER,           /*
                             = 0; //整单打折
                             = 1; //行打折
                             = 2; //下一菜式要打折
                             = 3; //取消打折
                             = 4; //整单品种打折 (之前:不用授权的VIP卡打折)

                             //可以有5种不同的VIP折扣
                             = 11; //A卡折扣
                             = 12; //B卡折扣
                             = 13; //C卡折扣
                             = 14; //D卡折扣
                             = 15; //E卡折扣
                           */
  BCID  INTEGER,
  ANUMBER       INTEGER,
  RESERVE01     VARCHAR(40),   /* 是否优惠卡(即：是否可以打折)   0和空:非优惠卡,1:优惠卡 */
  RESERVE02     VARCHAR(40),   /*计算的方式 1=开新单计，2＝即时计*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  HOLIDAY       VARCHAR(40),     /*假期*/
  TIMEPERIOD    VARCHAR(40),     /*时段*/
  DINMODES      VARCHAR(40),     /*用餐方式编号*/
  WEEK          VARCHAR(40),     /*星期*/

  DISCOUNT_LEVEL INTEGER,   /*折扣级别>>>用在Android 手机 lzm add 2011-09-23*/
  REPORT_TYPE VARCHAR(40),   /*折扣类型 赠送 招待(现在没有使用这个域值)>>>用在Android 手机 lzm add 2011-09-23*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (USER_ID,SHOPID,SHOPGUID,DISCOUNTID)
);
--end--------------------------------折扣-----------------------------------

--start------------------------------用餐方式-----------------------------------
CREATE TABLE HQ_ISSUE_DINMODES
(
  MODEID        INTEGER NOT NULL,
  MODENAME      VARCHAR(100),       /*名称*/
  PERDISCOUNT   NUMERIC(15, 3),     /*折扣(停用)*/
  PERSERCHARGE  NUMERIC(15, 3),     /*服务费*/
  KICHENPRINTCOLOR      INTEGER DEFAULT 0, /**/
  RESERVE01     VARCHAR(40),        /*开单时自动点菜[菜式编号{数量}]..[]*/
  RESERVE02     VARCHAR(40),        /*开单时自动执行的命令[BCID,ANUMBER{界面编号}{按钮参数}]...[]*/
  RESERVE03     VARCHAR(40),        /* 单据类型,要结合RESERVE04:
                                       空和0=【RESERVE04="－"时为:销售单(餐饮的"堂吃"属于销售单)】,【RESERVE04="＋"时为:销售退单】;
                                       1=【RESERVE04="＋"时为:进货单】,【RESERVE04="－"时为:进货退单】;
                                       2=【盘点单,同时RESERVE04="=="】,【RESERVE04="=＋"时为:报益单】,【RESERVE04="=－"时为:报损单】;
                                       3=【RESERVE04="=＋"时为:退料单】,【RESERVE04="=－"时为:领料单】;

                                    */
  RESERVE04     VARCHAR(40),        /* 该单的品种为正数或负数 +:正数,-:负数,nil:不参与计算,空:负数,=:与库存一致*/
  RESERVE05     VARCHAR(40),        /* 预留 历史:停用->(点品种时要执行的命令[])*/
  MUSTCLASS1    VARCHAR(100),       /*必须点的品种类别1(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS2    VARCHAR(100),       /*必须点的品种类别2(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS3    VARCHAR(100),       /*必须点的品种类别3(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  MUSTCLASS4    VARCHAR(100),       /*必须点的品种类别4(一定要入该类别下的品种(例如:茶钱)等才能付款或印整单), 多个时用逗号分隔 例如: 201,203,204 */
  DMNEEDTABLE   INTEGER DEFAULT 1,  /*可以不录入台号 0=否,1=是*/
  DMNOTPERPAPER INTEGER DEFAULT 0,  /*不需要入单纸 lzm add 2010-05-15*/
  GENIDTYPE     INTEGER DEFAULT 0,  /*单号的产生方式 0=跟系统 1=顺序号 2=随机号 3=人工单号 lzm add 2011-05-23*/
  NOTPERPAPER   INTEGER DEFAULT 0,  /*不要厨房分单 0=否 1=是 lzm add 2012-07-10*/
  NOTSUMPAPER   INTEGER DEFAULT 0,  /*不要厨房总单 0=否 1=是 lzm add 2012-07-09*/
  NOTVOIDPAPER  INTEGER DEFAULT 0,  /*不需要退单纸 lzm add 2012-08-08*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (MODEID,USER_ID,SHOPID,SHOPGUID)
);
--end--------------------------------用餐方式-----------------------------------

--start------------------------------付款方式报表跟踪项-----------------------------------

CREATE TABLE HQ_ISSUE_TENDERMEDIA   /*付款类型*/
(
  MEDIAID       INTEGER NOT NULL,
  MEDIANAME     VARCHAR(40),
  BCID  INTEGER,
  ANUMBER       INTEGER,
  MEDIARATE     NUMERIC(15, 3),  /*汇换率*/
  RESERVE1      VARCHAR(40),     /*not use*/
  RESERVE2      VARCHAR(40),     /*付款类型:
                                   对应 LISTCONTENT 的 LCLAID=21
                                   '0'=现金, '1'=CGC(赠券) 【在系统汇总报表，中根据该类型分别统计“现金”和“赠券”的消费金额】*/
                                 /*老版本的方式(v5.2之前)： CASHER REPORT 中,是否CGC(赠券),'Y' OR  'N'   */
  RESERVE3      VARCHAR(40), /*
                             0:空:普通
                             1:会员券(即:积分)的付款方式【会员可以有消费积分，根据消费积分可以转换为会员券】
                             2:用礼券付款【需要记录礼券编号】(v5.2之后的礼券付款标志)
                             3:"记帐"(CHECKRST.RESERVE04记录ABUYER.BUYERID)
                             4:信用卡刷卡(CHECKRST.VISACARD_CARDNUM和CHECKRST.VISACARD_BILLNUM分别记录卡号和刷卡的帐单号)
                             5:订金
                             6:餐券付款【需要录入券额和数量】
                             7:银行积分付款 lzm add 【2009-06-21】
                             8:客户记账后的现金还款 lzm add 【2009-08-14】

                             9:IC卡记录消费金额的消费方式
                             10:IC卡充值的付款方式(金额数保存在IC卡上)  **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**

                             11:A卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             12:B卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             13:C卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             14:D卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**
                             15:E卡的付款方式                           **用于直接输入卡号付款,根据卡号提取付款的BCID,ANUMBER**

                             16:直接修改总积分付款  //lzm add 2011-08-02
                             17:直接修改可用积分付款  //lzm add 2011-08-02
                             18:积分折现操作 //lzm add 2011-08-05
                             19:VIP卡挂失后退款的付款方式 //lzm add 2012-07-04
                             20:VIP卡挂失后换卡,补卡-新卡的付款方式 //lzm add 2012-07-04

                             21:A卡积分折现付款 lzm add 2011-07-13
                             22:B卡积分折现付款 lzm add 2011-07-13
                             23:C卡积分折现付款 lzm add 2011-07-13
                             24:D卡积分折现付款 lzm add 2011-07-13
                             25:E卡积分折现付款 lzm add 2011-07-13

                             26:酒店会员卡付款 lzm add 2012-06-17
                             27:酒店转房帐付款 lzm add 2012-06-17
                             28:酒店挂账付款 lzm add 2012-06-17

                             29:IC卡还款 lzm add 2013-11-28
                             30:磁卡还款 lzm add 2013-11-28

                             31:VIP卡挂失后换卡,补卡-旧卡的付款方式 //lzm add 2015/5/22 星期五

                             32:支付宝支付
                             33:微信支付

                             100:消费日结标记 lzm add 2012-07-12

                             111:澳门通-售卡 lzm add 2013-02-26
                             112:澳门通-充值 lzm add 2013-02-26
                             113:澳门通-扣值 lzm add 2013-02-26
                             114:澳门通-结算 lzm add 2013-02-26
                             */
  RESERVE01     VARCHAR(40), /*(v5.2之前的礼券付款标志)是否礼券 标记为:L或l（需要录入礼券编号）*/
  RESERVE02     VARCHAR(40), /*固定付款金额*/
  RESERVE03     VARCHAR(40), /*对账额(折扣) 10%=9折 10=折掉10元 */
  RESERVE04     VARCHAR(40), /*最大允许的付款金额 50%=不能输入大于50%的账单金额 50=不能输入大于50元的金额 lzm modify 2009-08-07*/
  RESERVE05     VARCHAR(40), /*固定兑换后的金额 lzm add 2009-10-22*/
  NUMBER        VARCHAR(40), /*该付款的用户编号UserCode*/
  REPORTTYPE    VARCHAR(50) DEFAULT '', /*用于新总部系统 lzm add 2010-09-02*/

  DENOMINATION VARCHAR(40),    /*面额 >>>用在Android 手机 lzm add 2011-09-23*/
  REPORT_TYPE VARCHAR(40),     /*现金 信用卡  借记卡 支票 赠券 现金券 礼券 记账 其他 >>>用在Android 手机 lzm add 2011-09-23*/

  NEED_PAY_REMAIN INTEGER DEFAULT 0,  /*需要统计当前付款的账单余额 lzm add 2015-05-31*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (MEDIAID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_TRACKINGGROUP  /*报表跟踪项*/
(
  TGID  INTEGER NOT NULL,
  NAME  VARCHAR(100),
  ISDEFAULT     INTEGER,
  RESERVE01     VARCHAR(40),
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TGID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_TRACKINGGROUPITEM  /*报表跟踪项详细*/
(
  TGID  INTEGER NOT NULL,
  LINEID        INTEGER NOT NULL,
  BCID  INTEGER,                /*统计类别*/
  NUM   INTEGER,                /*内容编号*/
  APPENDCOL     VARCHAR(100),   /*说明信息*/
  RESERVE01     VARCHAR(40),    /*区域编号 A-Z //lzm add 2011-07-30*/
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (TGID, LINEID,USER_ID,SHOPID,SHOPGUID)
);

--end--------------------------------付款方式报表跟踪项-----------------------------------

CREATE TABLE HQ_ISSUE_EMPCLASS
(
  EMPCLASSID    INTEGER NOT NULL, /*会员EMPCLASSID=1..10000 VIP卡EMPCLASSID=10001..10005  lzm modify 分开接收员工和会员信息 2012-4-23*/
  EMPCLASSNAME  VARCHAR(40),   /*类别名称*/
  TSID  INTEGER,               /*登录到的界面编号*/
  ACCESSLEVEL   INTEGER,       /*
                               0-Admin管理权限,
                               1-Normal普通权限,
                               2-cFreeRight,
                               3-咨客开单,
                               4-桑那钟房,
                               5-技师,
                               6-客房管理员
                               7-服务员或吧女,用于推销酒水或其它品种的提成
                               8-划单员

                               等于以下值时，对应Discount表的:LIDU(凹度):可以知道该用户的折扣率
                               11=A卡
                               12=B卡
                               13=C卡
                               14=D卡
                               15=E卡
                               */
  RESERVE01     VARCHAR(40),   /*员工类型,-1=隐藏该用户,0=员工,1=VIP*/
  RESERVE02     VARCHAR(40),   /*普通、银、金卡、白金卡： Money
                               亦可作该卡的最低金额
                               */
  RESERVE03     VARCHAR(40),   /*卡的明细类型
                               0=普通员工磁卡
                               1=高级员工磁卡（有打折功能）
                               2=客户VIP磁卡（如果是：直接刷卡付款则金额记录在中心数据库；否则不记录在数据库,有打折功能,有会员积分功能）
                               3=客户IC卡（金额纪录在中心数据库,有打折功能,有会员积分功能）
                               4=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                               ?5=客户IC卡（金额纪录在IC卡上,有打折功能,有会员积分功能，消费金额记录在IC卡上）
                               */
  RESERVE04     TEXT,           /*YPOS的权限 lzm add 2018-12-04 03:14:40【之前是：2=管理库存权限,】
                              jb = {shopname:"",                      --店名
                                    loginuserdiscount_upperlimit:"",  --折扣上限   例如:10% 代表只能进行0%到10%的折扣
                                    loginuser_ql_discount_upperlimit; --例如:10 代表只能进行0到10的去零
                                    loginuserStorage:"",              --是否启用联机的库存管理   ""或0  不进过服务器    1使用服务器处理库存
                                    loginuserType:"",                 --5：系统管理员 4：老板   3：经理  2：财务人员  1：部长  0:普通业务员
                                    loginuserIsFreePrice:"",          --0:不启用   1:启用改价格功能
                                    loginuserMode:"",                 --0:没有PC    1:经过互联网下服务器PC    2:直接通过局域网连接PC
                                    jb:""                             --折扣级别  0是缺省级别，数字越高，级别越高
                                  }
                                */
  RESERVE05     VARCHAR(40),    /*要登录的界面,多个界面时用分号(";")分隔*/
  SMSTABLEID    VARCHAR(10),    /*短信台号*/
  BEFOREORDER   VARCHAR(100),    /*登陆时要执行的命令*/
  PCID          VARCHAR(40) DEFAULT '',  /*空=门店员工信息和门店VIP卡信息 */
  GRANTSTR      VARCHAR(200),            /*用户权限,拥有的权限用逗号分割
                                           [
                                           位置1:领料单是否允许修改单价 0=否1=是
                                           位置2:退料单是否允许修改单价 0=否1=是
                                           位置3:直拨单的供应商编号对应的单价是否允许修改
                                                (格式:  01;02=1 代表:只允许编号为01或02的供应商修改单价
                                                        01=1    代表:只允许编号为01的供应商时修改单价)
                                           位置4:进货单的供应商编号对应的单价是否允许修改
                                                (格式:  01;02=1 代表:只允许编号为01或02的供应商修改单价
                                                        01=1    代表:只允许编号为01的供应商时修改单价)
                                           ]*/
  MUSTWORKON    INTEGER DEFAULT 0,       /*必须上班才能登陆 0=否 1=是*/
  AFTERPRNBILLSCID  VARCHAR(40),         /*印整单后点击台号进入的界面*/

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  OPENBILLSCID  VARCHAR(40),            /*如果该单有内容则点击台号进入的界面*/
  MIDETAILSCID  VARCHAR(40),            /*该类员工使用的品种界面用逗号分割 500,600,1000,700*/

  LEVELID       INTEGER DEFAULT 0,      /*权限级别 对应授权级别表"LEVELCLASS"的LEVELID lzm add 2010-06-13*/
  AFTERTBLSCID  VARCHAR(40),            /*点击台号后进入的界面 lzm add 2010-07-26*/
  PHONECALLAUTO INTEGER DEFAULT 0,      /*自动弹出来电显示窗口的停留时间 0=不弹出来电窗口 -1=不自动关闭 lzm add 2010-12-21*/
  PRESENTITEM   INTEGER DEFAULT 0,      /*招待 0=不限制招待 >1=需要限制招待的份数 lzm add 2011-06-14*/
  PRESENTCTYPE  INTEGER DEFAULT 0,      /*招待的周期 0=按日计算 1=按周计算 2=按月计算 lzm add 2011-06-14*/

  PRESENTINUSE  INTEGER DEFAULT 0,      /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/
  STOCKALARM    INTEGER DEFAULT 0,      /*是否弹出库存警报 0=否 1=启用 lzm add 2011-12-26*/

  PRESENTAMOUNT  NUMERIC(15, 3),        /*限制招待的金额 0或空=不限制 lzm add 2013-09-02*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRESENTLIMIT VARCHAR(20),                 /*账单的招待上限 lzm add 2015-09-28*/

  PRIMARY KEY (EMPCLASSID,PCID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_EMPLOYEES /*EMPLOYEES与ABUYER是多对一的关系 通过BUYERID联系(即：一个人可以有多个VIP卡)*/
(
  EMPID INTEGER NOT NULL,       /*会员EMPID=1..10000 VIP卡EMPID>=10001 lzm modify 分开接收员工和会员信息 2012-4-23*/
  FIRSTNAME     VARCHAR(100),    /*姓名1*/
  LASTNAME      VARCHAR(100),    /*姓名2*/
  IDVALUE       VARCHAR(40),    /*卡号(即:密码)*/
  EMPCLASSID    INTEGER,
  RESERVE01     VARCHAR(40),    /*有效期  PeriodOfValidity 例如:20110101*/
  RESERVE02     VARCHAR(40),    /*地址 Address */
  RESERVE03     VARCHAR(40),    /*联系电话 Tel*/
  RESERVE04     VARCHAR(40),    /*邮编 ZipCode*/
  RESERVE05     VARCHAR(40),    /* ***lzm 作废 2013-05-24*** 用于积分 VIP卡消费累计总金额,即开卡以来的消费金额*/
  RESERVE11     VARCHAR(40),    /*用于积分 可用积分(或会员券)*/
  RESERVE12     VARCHAR(40),    /* ***lzm 作废 2013-05-24*** 用于积分 已经计算的VIP卡消费总额,即多少钱已兑换成积分(或会员券)*/
  RESERVE13     VARCHAR(40),    /*改为VIP的品种存量 之前:磁卡：剩余的 Money  */
  RESERVE14     VARCHAR(40),    /*会员卡的金额 Money*/
  RESERVE15     VARCHAR(40),    /*手机Mobile*/
  RESERVE16     VARCHAR(40),    /*传真Fax*/
  RESERVE17     VARCHAR(40),    /*公司名company*/
  RESERVE18     VARCHAR(40),    /*公司职务CoHeadship*/
  RESERVE19     VARCHAR(40),    /*台商会分会名ASSN*/
  RESERVE20     VARCHAR(40),    /*分会职务ASSNHeadship*/
  RESERVE21     VARCHAR(40),    /*人士Degree*/
  RESERVE22     VARCHAR(40),    /*生日Birthday */
  RESERVE23     VARCHAR(40),    /*语言   cn  en     */
  RESERVE24     VARCHAR(40),    /*UserCode 用户编号,比如技师的编号等*/
  RESERVE25     VARCHAR(40),    /*最后充值日期 lzm modify 2013-04-17*/
  BUYDATE       VARCHAR(10),    /*购卡日期*/
  ORDERID       INTEGER DEFAULT 0,     /*排列编号*/
  BUYERID       VARCHAR(40),    /*对应ABUYER的BUYERID  EMPLOYEES与ABUYER是多对一的关系(即：一个人可以有多个VIP卡)*/
  EMPPASSWORD   VARCHAR(128),   /*用户自己定义的密码*/
  LASTCONSUMEDATE  TIMESTAMP,   /*最后消费日期*/
  PCID          VARCHAR(40) DEFAULT '', /*空=门店员工信息和门店VIP卡信息(以前的总部系统用于区分总部员工和门店员工) */
  NOTADDINTERNAL   INTEGER DEFAULT 0,  /*不需要继续累积消费积分 0=需要继续累计 1=不需要继续累计*/
  JXCUSERID     VARCHAR(40),    /*改为进销存的客户或供应商名称 lzm modify 2011-12-13 (之前:进销存的用户ID)*/
  JXCPASSWORD   VARCHAR(40),    /*进销存的密码*/

  treeparent    INTEGER DEFAULT -1, /**/
  wage          NUMERIC DEFAULT 0,  /*基本工资*/
  dept          VARCHAR(20),        /*部门*/
  learning      VARCHAR(20),        /*学历名称*/
  isdeliver     INTEGER DEFAULT 0,  /* ***保留***(暂时被程序固定为1) 1=进销存高级用户 0=普通用户 (即之前的:是否配送中心员工) 就是进销存管理的员工管理的Admin*/
  comedate      TIMESTAMP,          /*入职时间*/
  sex           VARCHAR(10),        /*男女*/
  place         VARCHAR(30),        /*籍贯*/

  ADDEMPNAME  VARCHAR(40),              /*添加的员工名称VER7.2.0 X3*/
  ADDTIME     TIMESTAMP,                /*添加的时间VER7.2.0 X3*/
  ADDSHOPID   VARCHAR(20),              /*添加的店编号VER7.2.0 X3*/
  EDITEMPNAME VARCHAR(40),              /*最近修改的员工名称VER7.2.0 X3*/
  EDITTIME    TIMESTAMP,                /*最近修改的时间VER7.2.0 X3*/
  EDITSHOPID  VARCHAR(20),              /*最近修改的店编号VER7.2.0 X3*/
  SYNCEMPNAME VARCHAR(40),              /*同步的店编号VER7.2.0 X3*/
  SYNCTIME    TIMESTAMP,                /*同步时间VER7.2.0 X3*/

  TBLNAME     VARCHAR(40),              /*对应到的台号名称,用于现在用户只能操作的台号 lzm add 2010-08-13*/

  WEB_TAG      INTEGER DEFAULT 0,       /*需要同步到web_sysuser lzm add 2011-03-30*/

  DISCOUNT_LEVEL INTEGER,        /*员工或者会员的折扣级别---->根据折扣表得到该会员能够拥有的折扣>>>用在Android 手机 lzm add 2011-09-23*/
  TAX_DEFINE VARCHAR(40),        /*根据简单设置表的税率名称得到相应的税率>>>用在Android 手机 lzm add 2011-09-23*/

  PRESENTITEM   INTEGER DEFAULT NULL,  /*招待 空=跟类别设置 0=不限制招待 >1=需要限制招待的份数 lzm add 2011-06-14*/
  PRESENTCTYPE  INTEGER DEFAULT NULL,  /*招待的周期 空=跟类别设置 0=按日计算 1=按周计算 2=按月计算 lzm add 2011-06-14*/

  POINTSTODAY  NUMERIC(15,3) DEFAULT 0.0,       /*用于积分 今天的积分(用于积分次日生效的算法) lzm add 2011-07-10*/
  POINTSTOTAL   NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 累计总积分 lzm add 2011-07-05*/
  MONEYFPOINTS  NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 上月积分已折现金额(可当付款使用) lzm add 2011-07-05*/
  POINTSADDTIME TIMESTAMP,                      /*用于积分 最后获得积分的时间(用于上月积分需要兑换为现金的算法) lzm add 2011-07-11*/
  MONEYFPOINTSTIME TIMESTAMP,                   /*用于积分 上次积分折现的时间(用于上月积分需要兑换为现金的算法) lzm add 2011-07-11*/
  POINTSISUSED  NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 已兑换的积分 lzm add 2011-07-18*/
  --CANTRUNPOINTS NUMERIC(15,3) DEFAULT 0.0,      /*用于积分 现在可折现的积分(用于上月积分需要兑换为现金的算法) lzm add 2011-08-04*/

  PRESENTINUSE  INTEGER DEFAULT 0,     /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  AUDITLEVEL  INTEGER DEFAULT 1,       /*审核级别 1=一级审核(入单员就是一级审核员) lzm add 2011-10-30*/
  STOCKDEPOT  VARCHAR(40),             /*仓库编号(空:全部),用于限制用户只能操作的仓库 lzm add 2011-11-2*/

  WPOS_SN  VARCHAR(40),                /*点菜机的序列号 lzm add 2012-02-25*/
  CARDSTATE     INTEGER DEFAULT 0,     /*VIP卡的状态 0=在用 1=挂失 2=作废 3=黑名单 lzm add 2012-07-05*/
  RETURNBACK    INTEGER DEFAULT 0,     /*VIP卡已退款 0=否 1=是 lzm add 2012-07-05*/
  EXCHANGENEWCARD  VARCHAR(50),        /*VIP卡换卡,补卡对应的新卡号 lzm add 2012-07-05*/

  PRESENTAMOUNT  NUMERIC(15, 3),       /*限制招待的金额 空=跟类别设置 0=不限制 lzm add 2013-09-02*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRESENTLIMIT VARCHAR(20),                 /*账单的招待上限 lzm add 2015-09-28*/

  PRIMARY KEY (EMPID,PCID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_PRESENT_MICLASS_EMPCLASET  /*员工类别,可招待的品种类别和数量 lzm add 2011-06-14*/
(
  EMPCLASSID    INTEGER NOT NULL,     /*员工类别编号*/
  MICLASSID     INTEGER NOT NULL,     /*品种类别编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPCLASSID, MICLASSID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_PRESENT_MIDETAIL_EMPCLASET  /*员工类别,可招待的品种和数量 lzm add 2011-06-14*/
(
  EMPCLASSID    INTEGER NOT NULL,     /*员工类别编号*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPCLASSID, MENUITEMID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_PRESENT_MICLASS_EMPSET  /*员工,可招待的品种类别和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MICLASSID     INTEGER NOT NULL,     /*品种类别编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPID, MICLASSID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_PRESENT_MIDETAIL_EMPET  /*员工,可招待的品种和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  PRESENTCOUNT  INTEGER,              /*可以招待数量*/
  PRESENTINUSE  INTEGER DEFAULT 0,    /*招待是否启用 0=否 1=启用 lzm add 2011-09-23*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPID, MENUITEMID,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_PRESENT_MIDETAIL_EMPRUN  /*员工曾经已招待的品种和数量 lzm add 2011-06-14*/
(
  EMPID         INTEGER NOT NULL,     /*员工编号 =NULL:代表该行为员工类别的设置*/
  MENUITEMID    INTEGER NOT NULL,     /*品种编号*/
  SALEDATE      TIMESTAMP NOT NULL,   /*销售日期*/
  APRESENTCOUNT INTEGER,              /*已招待数量*/

  APRESENTAMOUNT NUMERIC(15, 3),      /*已招待金额 lzm add 2013-09-02*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (EMPID, MENUITEMID, SALEDATE,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_POINTS2MONEY  /*积分兑换金额转换表 lzm add 2011-07-05*/
(
  POINTS_S          INTEGER NOT NULL,       /*可用积分开始范围*/
  POINTS_E          INTEGER NOT NULL,       /*可用积分结束范围*/
  CONVER_RATE       VARCHAR(10) NOT NULL,   /*积分转金额比率*/
  MONEY_S           INTEGER,                /*可兑换金额开始范围(用于比较和查看)*/
  MONEY_E           INTEGER,                /*可兑换金额结束范围(用于比较和查看)*/
  MONEY_PER_POINTS  VARCHAR(20),            /*每分折算金额(用于比较和查看)*/
  REMARK            VARCHAR(100),           /*备注*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

  PRIMARY KEY (POINTS_S, POINTS_E, CONVER_RATE,USER_ID,SHOPID,SHOPGUID)
);

CREATE TABLE HQ_ISSUE_SYSTEMPARA    /*系统参数*/
(
  ID    SERIAL,
  NAME  VARCHAR(40),
  VAL   TEXT, /*old varchar(40), alter table SYSTEMPARA alter VAL type VARCHAR(240)*/
  RESERVE01     VARCHAR(40),  /*Section*/
  RESERVE02     VARCHAR(40),
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MDTIME        TIMESTAMP,    /*数据修改时间*/

  USER_ID INTEGER NOT NULL DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) NOT NULL DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) NOT NULL DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (ID)
);


CREATE TABLE HQ_ISSUE_SYSTEMPARA_400    /*400上设置的系统参数*/ /*lzm add 2021-11-18 12:46:28*/
(
  ID    SERIAL,
  NAME  VARCHAR(40),
  VAL   TEXT, /*old varchar(40), alter table SYSTEMPARA alter VAL type VARCHAR(240)*/
  RESERVE01     VARCHAR(40),  /*Section*/
  RESERVE02     VARCHAR(40),  /*file=更新到文件root\data\SystemPara.ini db=更新到SYSTEMPARA表*/
  RESERVE03     VARCHAR(40),
  RESERVE04     VARCHAR(40),
  RESERVE05     VARCHAR(40),
  MDTIME        TIMESTAMP,    /*数据修改时间*/

  USER_ID INTEGER DEFAULT 0,       /*集团号 lzm add 2015-09-16*/
  SHOPID  VARCHAR(40) DEFAULT '',  /*店编号 lzm add 2015-09-16*/
  SHOPGUID VARCHAR(200) DEFAULT '', /*店的GUID lzm add 2015-09-17*/
  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间 lzm add 2015-09-17*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间 lzm add 2015-09-17*/
  MODIFYUSER VARCHAR(40),                   /*修改人 lzm add 2015-09-17*/

 PRIMARY KEY (ID)
);


--创建时钟任务
--v_jobid:=select netval('pgagent.pga_job_jobid_seq');
--v_schid:=select netval('pgagent.pga_schedule_jscid_seq');
INSERT INTO pgagent.pga_job (jobid, jobjclid, jobname, jobdesc, jobenabled, jobhostagent)
SELECT v_jobid, jcl.jclid, 'wpos_run_history_command', '', true, ''
  FROM pgagent.pga_jobclass jcl WHERE jclname='Routine Maintenance';

INSERT INTO pgagent.pga_jobstep (jstid, jstjobid, jstname, jstdesc, jstenabled, jstkind, jstonerror, jstcode, jstdbname, jstconnstr)
  SELECT v_schid, v_jobid, 'wpos_run_history_command', '', true, 's', 'f', 'select wpos_run_history_command();', 'victorysvr', '';

INSERT INTO pgagent.pga_schedule (jscid, jscjobid, jscname, jscdesc, jscminutes, jschours, jscweekdays, jscmonthdays, jscmonths, jscenabled, jscstart, jscend)
  VALUES(v_schid, v_jobid, 'wpos_run_history_command', '', '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}', '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}', '{f,f,f,f,f,f,f}', '{f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f,f}', '{f,f,f,f,f,f,f,f,f,f,f,f}', true, '2011-09-25 00:00:00', NULL);

--end-----------------Android 的表-------------------------

create view report1_checks
  as select * from checks UNION select * from whole_checks;
create view report1_checkrst
  as select * from checkrst UNION select * from whole_checkrst;
create view report1_chkdetail
  as select * from chkdetail UNION select * from whole_chkdetail;
create view report1_chkdetail_ext
  as select * from chkdetail_ext UNION select * from whole_chkdetail_ext;

--CREATE UNIQUE INDEX DIX_BUYERID_ABUYER ON ABUYER (USER_ID,SHOPID,SHOPGUID,BUYERID);
--CREATE UNIQUE INDEX DIX_IDVALUE_EMPLOYEES ON EMPLOYEES (USER_ID,SHOPID,SHOPGUID,IDVALUE);
CREATE UNIQUE INDEX DIX_GENERATORNAME_GENERATOR ON GENERATOR (USER_ID,SHOPID,SHOPGUID,GENERATORNAME);
CREATE UNIQUE INDEX DIX_MIPRNID_MIPARINTERS ON MIPARINTERS (USER_ID,SHOPID,SHOPGUID,MIPRNID);
CREATE UNIQUE INDEX DIX_SECID_ATABLESECTIONS ON ATABLESECTIONS (USER_ID,SHOPID,SHOPGUID,SECID);
--CREATE UNIQUE INDEX DIX_BUYERNAME_ABUYER ON ABUYER (USER_ID,SHOPID,SHOPGUID,BUYERNAME);

/*
CREATE INDEX checks_idreserve3 ON checks (checkid, pcid, reserve3);
CREATE INDEX backup_checks_idreserve3 ON backup_checks (checkid, reserve3);
CREATE INDEX sum_checks_idreserve3 ON sum_checks (checkid, reserve3);
CREATE INDEX whole_checks_idreserve3 ON whole_checks (checkid, pcid, reserve3);
CREATE INDEX year_whole_checks_idreserve3 ON year_whole_checks (checkid, pcid, reserve3);

CREATE INDEX chkdetail_idreserve3 ON chkdetail (checkid, pcid, reserve3);
CREATE INDEX backup_chkdetail_idreserve3 ON backup_chkdetail (checkid, pcid, reserve3);
CREATE INDEX sum_chkdetail_idreserve3 ON sum_chkdetail (checkid, pcid, reserve3);
CREATE INDEX whole_chkdetail_idreserve3 ON whole_chkdetail (checkid, pcid, reserve3);
CREATE INDEX year_whole_chkdetail_idreserve3 ON year_whole_chkdetail (checkid, pcid, reserve3);

CREATE INDEX checkrst_idreserve3 ON checkrst (checkid, pcid, reserve3);
CREATE INDEX backup_checkrst_idreserve3 ON backup_checkrst (checkid, pcid, reserve3);
CREATE INDEX sum_checkrst_idreserve3 ON sum_checkrst (checkid, pcid, reserve3);
CREATE INDEX whole_checkrst_idreserve3 ON whole_checkrst (checkid, pcid, reserve3);
CREATE INDEX year_checkrst_idreserve3 ON year_checkrst (checkid, pcid, reserve3);

CREATE INDEX whole_checks_pcid on whole_checks(pcid);
CREATE INDEX whole_chkdetail_pcid on whole_chkdetail(pcid);
CREATE INDEX whole_checkrst_pcid on whole_checkrst(pcid);

CREATE INDEX INDEX_CHECKS_CHECKCLOSED ON CHECKS(CHECKCLOSED);
create index whole_checks_CHECKCLOSED on whole_checks(CHECKCLOSED);
create index whole_checks_RESERVE2 on whole_checks(RESERVE2);
create index whole_chkdetail_FAMILGID on whole_chkdetail(FAMILGID);
create index whole_chkdetail_MENUITEMID on whole_chkdetail(MENUITEMID);
*/

CREATE INDEX whole_checks_ymdpcid ON whole_checks(Y,M,D,PCID);
CREATE INDEX whole_checks_reserve3pcid ON whole_checks(reserve3,PCID);
--CREATE INDEX whole_checks_ymdpcidreserve2closed ON whole_checks(Y,M,D,PCID,RESERVE2,CHECKCLOSED);

CREATE INDEX MICLASS_MICLASSID ON MICLASS(MICLASSID);
CREATE INDEX MICLASS_PARENTMICLASS ON MICLASS(PARENTMICLASS);
CREATE INDEX MIDETAIL_MICLASSID ON MIDETAIL(MICLASSID);

/*
CREATE UNIQUE INDEX DIX_BARCODE_MIDETAIL ON MIDETAIL (BARCODE);

ALTER TABLE MIDETAIL ADD CONSTRAINT MIDETAIL_FK FOREIGN KEY (MICLASSID) REFERENCES MICLASS (MICLASSID) ON UPDATE CASCADE ON DELETE SET DEFAULT;
ALTER TABLE SALES_SUMERY_OTHER ADD CONSTRAINT SALES_SUMERY_OTHER_FK FOREIGN KEY (PCID, Y, M, D, MENUITEMID) REFERENCES SALES_SUMERY (PCID, Y, M, D, MENUITEMID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TCSL_DETAIL ADD CONSTRAINT TCSL_DETAIL_FK FOREIGN KEY (TCSLID) REFERENCES TCSL (TCSLID) ON UPDATE CASCADE ON DELETE CASCADE;
*/

/*
createlang --username=postgres "plpythonu" victorysvr
droplang --username=postgres "plpythonu" victorysvr
*/

insert into GENERATOR(GENERATORNAME,VAL) values ('BUTTONSIZE_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('BUTTONWIDTH_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('CCHECKNOTCLOSED_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('CHECKID_NUMBER_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('CNOTVOID_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('CVOIDOBJ_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('CVOID_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('DEFAULT_MODULE_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('DEFAULT_TS_COL_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('DEFAULT_TS_HEIGHT_GEN',28);
insert into GENERATOR(GENERATORNAME,VAL) values ('DEFAULT_TS_ROW_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('DEFAULT_TS_WIDTH_GEN',16);
insert into GENERATOR(GENERATORNAME,VAL) values ('DELAYTIME1000_GEN',1000);
insert into GENERATOR(GENERATORNAME,VAL) values ('EMPTY_MICLASS_FIRST_TS_GEN',400);
insert into GENERATOR(GENERATORNAME,VAL) values ('EMPTY_MICLASS_OTHER_TS_GEN',401);
insert into GENERATOR(GENERATORNAME,VAL) values ('EMPTY_MI_NOSUBCLASS_TS_GEN',404);
insert into GENERATOR(GENERATORNAME,VAL) values ('EMPTY_MI_TS_GEN',402);
insert into GENERATOR(GENERATORNAME,VAL) values ('GEN_CHECKID',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('GLOBALNUM_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('KEEPDAYS_BACKUP_GEN',62);
insert into GENERATOR(GENERATORNAME,VAL) values ('KEEPDAYS_SUM_GEN',62);
insert into GENERATOR(GENERATORNAME,VAL) values ('KEEPDAYS_WHOLE_GEN',93);
insert into GENERATOR(GENERATORNAME,VAL) values ('KEEPDAYS_YEARWHOLE_GEN',400);
insert into GENERATOR(GENERATORNAME,VAL) values ('LENGTH_PERITEM_GEN',4);
insert into GENERATOR(GENERATORNAME,VAL) values ('MAX_MI_GEN',2000);
insert into GENERATOR(GENERATORNAME,VAL) values ('MAX_PAGES_GEN',1000);
insert into GENERATOR(GENERATORNAME,VAL) values ('MAX_TC_GEN',3000);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSFIRST_FONTCOLOR_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSFIRST_FONTSIZE_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSFIRST_MIN_ANUMERIC_GEN',51);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_COL_GEN',13);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_FONTCOLOR_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_FONTSIZE_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_HEIGHT_GEN',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_MIN_ANUMERIC_GEN',63);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_ROW_GEN',10);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASSOTHER_WIDTH_GEN',12);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_COL_GEN',13);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_FIRST_MODULE_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_F_BUTTONHEIGHT_GEN',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_F_BUTTONWIDTH_GEN',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_HEIGHT_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_OTHER_MODULE_GEN',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_O_BUTTONHEIGHT_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_O_BUTTONWIDTH_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_ROW_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('MICLASS_WIDTH_GEN',12);
insert into GENERATOR(GENERATORNAME,VAL) values ('MIN_MICLASS_FIRST_GEN',500);
insert into GENERATOR(GENERATORNAME,VAL) values ('MIN_MICLASS_OTHER_GEN',600);
insert into GENERATOR(GENERATORNAME,VAL) values ('MIN_MI_GEN',1000);
insert into GENERATOR(GENERATORNAME,VAL) values ('MIN_TC_GEN',2000);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_APP_BUTTONHEIGHT_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_APP_BUTTONWIDTH_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_BUTTONHEIGHT_GEN',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_BUTTONWIDTH_GEN',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_COL_GEN',13);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_FONTCOLOR_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_FONTSIZE_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_HEIGHT_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_MIN_ANUMERIC_GEN',69);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_MODULE_GEN',4);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_NOSUBCLASS_COL_GEN',13);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_NOSUBCLASS_HEIGHT_GEN',12);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_NOSUBCLASS_ROW_GEN',10);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_NOSUBCLASS_WIDTH_GEN',12);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_RELATE_TS_DEFAULT1',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_RELATE_TS_DEFAULT2',3);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_RELATE_TS_DEFAULT3',4);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_RELATE_TS_DEFAULT4',10);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_ROW_GEN',14);
insert into GENERATOR(GENERATORNAME,VAL) values ('MI_WIDTH_GEN',12);
insert into GENERATOR(GENERATORNAME,VAL) values ('NEEDADDTOTG_GEN',7);
insert into GENERATOR(GENERATORNAME,VAL) values ('NEXT_MICLASS_FIRST_MODULE_GEN',25);
insert into GENERATOR(GENERATORNAME,VAL) values ('NEXT_MICLASS_OTHER_MODULE_GEN',27);
insert into GENERATOR(GENERATORNAME,VAL) values ('NEXT_MI_MODULE_GEN',29);
insert into GENERATOR(GENERATORNAME,VAL) values ('OBJ_BUTTONHEIGHT_GEN',4);
insert into GENERATOR(GENERATORNAME,VAL) values ('OBJ_BUTTONWIDTH_GEN',4);
insert into GENERATOR(GENERATORNAME,VAL) values ('PCID',1000);
insert into GENERATOR(GENERATORNAME,VAL) values ('PRE_MICLASS_FIRST_MODULE_GEN',24);
insert into GENERATOR(GENERATORNAME,VAL) values ('PRE_MICLASS_OTHER_MODULE_GEN',26);
insert into GENERATOR(GENERATORNAME,VAL) values ('PRE_MI_MODULE_GEN',28);
insert into GENERATOR(GENERATORNAME,VAL) values ('REPORT_COL_GEN',9);
insert into GENERATOR(GENERATORNAME,VAL) values ('REPORT_HEIGHT_GEN',16);
insert into GENERATOR(GENERATORNAME,VAL) values ('REPORT_ROW_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('REPORT_WIDTH_GEN',16);
insert into GENERATOR(GENERATORNAME,VAL) values ('TABLEBUTTON_LENGTH_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('TABLEBUTTON_MODULE_GEN',68);
insert into GENERATOR(GENERATORNAME,VAL) values ('TABLEBUTTON_TS_GEN',21);
insert into GENERATOR(GENERATORNAME,VAL) values ('TABLE_CLICKEVENT_GEN',208);
insert into GENERATOR(GENERATORNAME,VAL) values ('TABLE_CLICKEVENT_NEXTSCR_GEN',15);
insert into GENERATOR(GENERATORNAME,VAL) values ('TCSL_BUTTONHEIGHT_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('TCSL_BUTTONWIDTH_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('TCSL_DETAIL_GEN',741);
insert into GENERATOR(GENERATORNAME,VAL) values ('TCSL_DETAIL_MODULE_GEN',4);
insert into GENERATOR(GENERATORNAME,VAL) values ('TCSL_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('TG_CASHIER_FINANCIAL_GEN',2);
insert into GENERATOR(GENERATORNAME,VAL) values ('TG_DEFAULT_GEN',1);
insert into GENERATOR(GENERATORNAME,VAL) values ('TG_SYSTEM_FINANCIAL_GEN',1);

insert into GENERATOR(GENERATORNAME,VAL) values ('TRIGGER_ENABLED_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('TS_SHORTCUTKEY_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('ABUYERID_GEN',0);
insert into GENERATOR(GENERATORNAME,VAL) values ('TABLE10ID_GEN',0);
/*
insert into GENERATOR(GENERATORNAME,VAL) values ('PRE_PAGE_CHAR_GEN',);
insert into GENERATOR(GENERATORNAME,VAL) values ('NEXT_PAGE_CHAR_GEN',);
*/

insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('CANNOT_INSERT_MI','Cann''t Insert MenuItem to a MICLASS that have had subMICLASS.');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('CANNOT_INSERT_SUBMICLASS','Cann''t Insert subMICLASS to a MICLASS that have had Menuitem.');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('CHANGE_NOT_ALLOW', 'CHANGE NOT ALLOW.');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('ERROR_001', '还有帐单未结,不能结束营业日');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('ERROR_002', '今日的销售数据为空或已结,操作不成功');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('ERROR_003', 'Times of close the day <= 9');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('MI_CAN_NOT_ALLOW_TSDETAIL', 'MI CAN NOT ALLOW IN THIS TOUCH SCREEN.');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('TS500CANNOTDEL', ' THE 500 TOUCHSCR CAN NOT DELETE');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('VALUE_CANNOT_EMPTY', 'THIS VALUE CANNOT EMPTY.');
insert into EXCEPTION(EXCEPTIONNAME,VAL) values ('VALUE_NOT_ALLOW', 'VALUE NOT ALLOW.');

insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('001', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('002', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('003', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('004', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('005', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('006', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('007', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('008', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('009', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('010', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('011', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('012', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('013', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('014', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('015', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('016', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('017', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('018', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('019', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('020', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('021', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('022', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('023', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('024', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('025', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('026', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('027', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('028', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('029', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('030', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('031', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('032', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('033', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('034', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('035', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('036', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('037', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('038', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('039', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('040', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('041', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('042', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('043', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('044', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('045', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('046', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('047', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('048', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('049', '2006-08-01');
insert into SHOPS31DAYSUM(SHOPID,SHOPDATE) values ('050', '2006-08-01');

--alter table abuyer modify ABID  SERIAL
--繁体XP HOME使用序列号:JQ4T4-8VM63-6WFBK-KTT29-V8966
--13701561600张小


ALTER TABLE iccard_consume_info DROP CONSTRAINT iccard_consume_info_pkey;
ALTER TABLE sum_iccard_consume_info DROP CONSTRAINT sum_iccard_consume_info_pkey;
ALTER TABLE backup_iccard_consume_info DROP CONSTRAINT backup_iccard_consume_info_pkey;
ALTER TABLE whole_iccard_consume_info DROP CONSTRAINT whole_iccard_consume_info_pkey;
ALTER TABLE year_whole_iccard_consume_info DROP CONSTRAINT year_whole_iccard_consume_info_pkey;

ALTER TABLE iccard_consume_info
  ADD CONSTRAINT iccard_consume_info_pkey PRIMARY KEY(icinfo_iccardno, icinfo_thetime, checkid);
ALTER TABLE sum_iccard_consume_info
  ADD CONSTRAINT sum_iccard_consume_info_pkey PRIMARY KEY(icinfo_iccardno, icinfo_thetime, checkid);
ALTER TABLE backup_iccard_consume_info
  ADD CONSTRAINT backup_iccard_consume_info_pkey PRIMARY KEY(icinfo_iccardno, icinfo_thetime, checkid);
ALTER TABLE whole_iccard_consume_info
  ADD CONSTRAINT whole_iccard_consume_info_pkey PRIMARY KEY(icinfo_iccardno, icinfo_thetime, checkid);
ALTER TABLE year_whole_iccard_consume_info
  ADD CONSTRAINT year_whole_iccard_consume_info_pkey PRIMARY KEY(icinfo_iccardno, icinfo_thetime, checkid);


SELECT f.conname, pg_get_constraintdef(f.oid), t.relname,f.conkey
FROM pg_class t, pg_constraint f
WHERE f.conrelid = t.oid
AND f.contype = 'p'
AND t.relname = 'iccard_consume_info';

--函数
CREATE OR REPLACE FUNCTION getmenuitemname(aname varchar) RETURNS varchar AS $$
DECLARE
    ipos integer;
    ipos1 integer;
    ipos2 integer;
BEGIN
    ipos1 := strpos(aname, '-');
    ipos2 := strpos(aname, '(/');
    if ipos1 > 0 then
        if ipos2 > 0 then
	    if ipos1 > ipos2 then
	        ipos := ipos2;
	    else
	        ipos := ipos1;
	    end if;
	else
	    ipos := ipos1;
	end if;
    else
        if ipos2 > 0 then
	    ipos := ipos2;
	else
	    ipos := 0;
	end if;
    end if;

    if ipos = 0 then
        RETURN aname;
    else
        RETURN substr(aname, 1, ipos - 1);
    end if;
END;
$$ LANGUAGE plpgsql;
