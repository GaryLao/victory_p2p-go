CREATE TABLE TEMP_WARESTOCK_DISTRI  /*原材料分仓库存表  lzm add 2009-09-08*/
(
  StockYear integer,              /*年*/
  StockMonth integer,             /*月*/
  DepotID integer,                /*仓库编号*/
  WareID integer,                 /*原材料编号*/
  sort character varying(30),     /*类别名称*/
  WareName varchar(30),           /*原材料名称*/
  DepotName varchar(30),          /*仓库名称*/
  WareUserCode varchar(30),       /*原材料用户编号*/
  pinyin character varying(20),   /*拼音*/
  model character varying(30),    /*型号*/
  spec character varying(30),     /*规格*/
  area character varying(30),     /*产地*/
  unit character varying(30),     /*计量单位*/
  unit2 character varying(30),    /*辅助单位*/
  scale numeric DEFAULT 0,        /*计量单位与辅助单位的比率*/
  barcode character varying(50),  /*条码*/
  constprice numeric DEFAULT 0,   /*成本价*/
  up_limit numeric DEFAULT 0,     /*库存上限*/
  down_limit numeric DEFAULT 0,   /*库存下限*/
  memo varchar(100),              /*备注*/
  "mode" smallint DEFAULT 0,      /**/
  wxyrate numeric DEFAULT 0,         /*正常损益率*/
  unitother character varying(30),   /*计量单位2*/
  BeginQty1 numeric DEFAULT 0,          /*期初数量*/
  BeginQty2 numeric DEFAULT 0,          /*期初辅助单位2数量*/
  BeginQtyOther numeric DEFAULT 0,      /*期初单位2数量*/
  BeginSum numeric DEFAULT 0,           /*期初金额*/
  PurInQty1 numeric DEFAULT 0,          /*购进数量*/
  PurInQty2 numeric DEFAULT 0,          /**/
  PurInQtyOther numeric DEFAULT 0,      /**/
  PurInSum numeric DEFAULT 0,           /*购进金额*/
  PurBckQty1 numeric DEFAULT 0,         /*购退数量*/
  PurBckQty2 numeric DEFAULT 0,         /**/
  PurBckQtyOther numeric DEFAULT 0,     /**/
  PurBckSum numeric DEFAULT 0,          /*购退金额*/
  UseOutQty1 numeric DEFAULT 0,         /*领用数量*/
  UseOutQty2 numeric DEFAULT 0,         /**/
  UseOutQtyOther numeric DEFAULT 0,     /**/
  UseOutSum numeric DEFAULT 0,          /*领用金额*/
  UseBckQty1 numeric DEFAULT 0,         /*退领数量*/
  UseBckQty2 numeric DEFAULT 0,         /**/
  UseBckQtyOther numeric DEFAULT 0,     /**/
  UseBckSum numeric DEFAULT 0,          /*退领金额*/
  SalOutQty1 numeric DEFAULT 0,         /*销售数量*/
  SalOutQty2 numeric DEFAULT 0,         /**/
  SalOutQtyOther numeric DEFAULT 0,     /**/
  SalOutSum numeric DEFAULT 0,          /*销售金额*/
  SalBckQty1 numeric DEFAULT 0,         /*数量*/
  SalBckQty2 numeric DEFAULT 0,         /**/
  SalBckQtyOther numeric DEFAULT 0,     /**/
  SalBckSum numeric DEFAULT 0,          /*销退金额*/
  EndQty1 numeric DEFAULT NULL,            /*期末数量*/
  EndQty2 numeric DEFAULT NULL,            /**/
  EndQtyOther numeric DEFAULT NULL,        /**/
  EndSum numeric DEFAULT NULL,             /*期末金额*/
  CheckQty1 numeric DEFAULT 0,          /*盘点数量*/
  CheckQty2 numeric DEFAULT 0,          /**/
  CheckQtyOther numeric DEFAULT 0,      /**/
  CheckSum numeric DEFAULT 0,           /*盘点金额*/
  BalanceQty1 numeric DEFAULT 0,        /*盈亏数量*/
  BalanceQty2 numeric DEFAULT 0,        /**/
  BalanceQtyOther numeric DEFAULT 0,    /**/
  BalanceSum numeric DEFAULT 0,         /*盈亏金额*/
  BeginDate timestamp,                  /*开始日期*/
  EndDate timestamp,                    /*结束日期*/
  TurInQty1 numeric DEFAULT 0,          /*转入数量*/
  TurInQty2 numeric DEFAULT 0,          /**/
  TurInQtyOther numeric DEFAULT 0,      /**/
  TurInSum numeric DEFAULT 0,           /*转入金额*/
  TurOutQty1 numeric DEFAULT 0,         /*转出数量*/
  TurOutQty2 numeric DEFAULT 0,         /**/
  TurOutQtyOther numeric DEFAULT 0,     /**/
  TurOutSum numeric DEFAULT 0,          /*转出金额*/
  OthInQty1 numeric DEFAULT 0,          /*其它入数量*/
  OthInQty2 numeric DEFAULT 0,          /**/
  OthInQtyOther numeric DEFAULT 0,      /**/
  OthInSum numeric DEFAULT 0,           /*其它入金额*/
  OthOutQty1 numeric DEFAULT 0,         /*其它出数量*/
  OthOutQty2 numeric DEFAULT 0,         /**/
  OthOutQtyOther numeric DEFAULT 0,     /**/
  OthOutSum numeric DEFAULT 0,          /*其它出金额*/
  BomOutQty1 numeric DEFAULT 0,         /*原材料卡消耗数量 lzm add 2010-04-19*/
  BomOutQty2 numeric DEFAULT 0,         /*lzm add 2010-04-19*/
  BomOutQtyOther numeric DEFAULT 0,     /*lzm add 2010-04-19*/
  BomOutSum numeric DEFAULT 0,          /*原材料卡消耗金额lzm add 2010-04-19*/
  CheckBatchNo varchar(40) DEFAULT '',  /*当前的盘点批次lzm add 2016-09-06 06:18:42*/
  CONSTRAINT TEMP_WARESTOCK_DISTRI_pkey PRIMARY KEY (StockYear,StockMonth,DepotID,WareID)
);

CREATE TABLE TEMP_WARESTOCK_DOM  /*原材料消耗表  lzm add 2009-09-08*/
(
  StockYear integer,              /*年*/
  StockMonth integer,             /*月*/
  DepotID integer,                /*lzm 2010-04-17 改为部门编号(作废:仓库编号)*/
  WareID integer,                 /*原材料编号*/
  sort character varying(30),     /*类别名称*/
  WareName varchar(30),           /*原材料名称*/
  DepotName varchar(30),          /*仓库名称*/
  WareUserCode varchar(30),       /*原材料用户编号*/
  pinyin character varying(20),   /*拼音*/
  model character varying(30),    /*型号*/
  spec character varying(30),     /*规格*/
  area character varying(30),     /*产地*/
  unit character varying(30),     /*计量单位*/
  unit2 character varying(30),    /*辅助单位*/
  scale numeric DEFAULT 0,        /*计量单位与辅助单位的比率*/
  barcode character varying(50),  /*条码*/
  constprice numeric DEFAULT 0,   /*成本价*/
  up_limit numeric DEFAULT 0,     /*库存上限*/
  down_limit numeric DEFAULT 0,   /*库存下限*/
  memo varchar(100),              /*备注*/
  "mode" smallint DEFAULT 0,      /**/
  wxyrate numeric DEFAULT 0,         /*正常损益率*/
  unitother character varying(30),   /*计量单位2*/
  UseQty1 numeric DEFAULT 0,          /*消耗数量*/
  UseQty2 numeric DEFAULT 0,          /*消耗辅助单位2数量*/
  UseQtyOther numeric DEFAULT 0,      /*消耗单位2数量*/
  BomQty1 numeric DEFAULT 0,          /*标准(原材料卡)消耗数量 lzm add 2009-09-16*/
  BomQty2 numeric DEFAULT 0,          /*标准(原材料卡)消耗辅助单位2数量 lzm add 2009-09-16*/
  BomQtyOther numeric DEFAULT 0,      /*标准(原材料卡)消耗单位2数量 lzm add 2009-09-16*/
  UseSum numeric DEFAULT 0,           /*消耗金额 lzm add 2010-04-16*/
  BomSum numeric DEFAULT 0,           /*标准(原材料卡)消耗金额 lzm add 2010-04-16*/
  IncomeSum numeric DEFAULT 0,        /*门店前台营业收入 lzm add 2010-04-17*/
  Profit numeric DEFAULT 0,           /*利润 lzm add 2010-04-17*/
  CONSTRAINT TEMP_WARESTOCK_DOM_pkey PRIMARY KEY (StockYear,StockMonth,DepotID,WareID)
);

CREATE TABLE WHOLE_WARESTOCK_DISTRI  /*原材料分仓库存表  lzm add 2009-09-08*/
(
  StockYear integer,              /*年*/
  StockMonth integer,             /*月*/
  DepotID integer,                /*仓库编号*/
  WareID integer,                 /*原材料编号*/
  sort character varying(30),     /*类别名称*/
  WareName varchar(30),           /*原材料名称*/
  DepotName varchar(30),          /*仓库名称*/
  WareUserCode varchar(30),       /*原材料用户编号*/
  pinyin character varying(20),   /*拼音*/
  model character varying(30),    /*型号*/
  spec character varying(30),     /*规格*/
  area character varying(30),     /*产地*/
  unit character varying(30),     /*计量单位*/
  unit2 character varying(30),    /*辅助单位*/
  scale numeric DEFAULT 0,        /*计量单位与辅助单位的比率*/
  barcode character varying(50),  /*条码*/
  constprice numeric DEFAULT 0,   /*成本价*/
  up_limit numeric DEFAULT 0,     /*库存上限*/
  down_limit numeric DEFAULT 0,   /*库存下限*/
  memo varchar(100),              /*备注*/
  "mode" smallint DEFAULT 0,      /**/
  wxyrate numeric DEFAULT 0,         /*正常损益率*/
  unitother character varying(30),   /*计量单位2*/
  BeginQty1 numeric DEFAULT 0,          /*期初数量*/
  BeginQty2 numeric DEFAULT 0,          /*期初辅助单位2数量*/
  BeginQtyOther numeric DEFAULT 0,      /*期初单位2数量*/
  BeginSum numeric DEFAULT 0,           /*期初金额*/
  PurInQty1 numeric DEFAULT 0,          /*购进数量*/
  PurInQty2 numeric DEFAULT 0,          /**/
  PurInQtyOther numeric DEFAULT 0,      /**/
  PurInSum numeric DEFAULT 0,           /*购进金额*/
  PurBckQty1 numeric DEFAULT 0,         /*购退数量*/
  PurBckQty2 numeric DEFAULT 0,         /**/
  PurBckQtyOther numeric DEFAULT 0,     /**/
  PurBckSum numeric DEFAULT 0,          /*购退金额*/
  UseOutQty1 numeric DEFAULT 0,         /*领用数量*/
  UseOutQty2 numeric DEFAULT 0,         /**/
  UseOutQtyOther numeric DEFAULT 0,     /**/
  UseOutSum numeric DEFAULT 0,          /*领用金额*/
  UseBckQty1 numeric DEFAULT 0,         /*退领数量*/
  UseBckQty2 numeric DEFAULT 0,         /**/
  UseBckQtyOther numeric DEFAULT 0,     /**/
  UseBckSum numeric DEFAULT 0,          /*退领金额*/
  SalOutQty1 numeric DEFAULT 0,         /*销售数量*/
  SalOutQty2 numeric DEFAULT 0,         /**/
  SalOutQtyOther numeric DEFAULT 0,     /**/
  SalOutSum numeric DEFAULT 0,          /*销售金额*/
  SalBckQty1 numeric DEFAULT 0,         /*销退数量*/
  SalBckQty2 numeric DEFAULT 0,         /**/
  SalBckQtyOther numeric DEFAULT 0,     /**/
  SalBckSum numeric DEFAULT 0,          /*销退金额*/
  EndQty1 numeric DEFAULT NULL,            /*期末数量*/
  EndQty2 numeric DEFAULT NULL,            /**/
  EndQtyOther numeric DEFAULT NULL,        /**/
  EndSum numeric DEFAULT NULL,             /*期末金额*/
  CheckQty1 numeric DEFAULT 0,          /*盘点数量*/
  CheckQty2 numeric DEFAULT 0,          /**/
  CheckQtyOther numeric DEFAULT 0,      /**/
  CheckSum numeric DEFAULT 0,           /*盘点金额*/
  BalanceQty1 numeric DEFAULT 0,        /*盈亏数量*/
  BalanceQty2 numeric DEFAULT 0,        /**/
  BalanceQtyOther numeric DEFAULT 0,    /**/
  BalanceSum numeric DEFAULT 0,         /*盈亏金额*/
  BeginDate timestamp,                  /*开始日期*/
  EndDate timestamp,                    /*结束日期*/
  TurInQty1 numeric DEFAULT 0,          /*转入数量*/
  TurInQty2 numeric DEFAULT 0,          /**/
  TurInQtyOther numeric DEFAULT 0,      /**/
  TurInSum numeric DEFAULT 0,           /*转入金额*/
  TurOutQty1 numeric DEFAULT 0,         /*转出数量*/
  TurOutQty2 numeric DEFAULT 0,         /**/
  TurOutQtyOther numeric DEFAULT 0,     /**/
  TurOutSum numeric DEFAULT 0,          /*转出金额*/
  OthInQty1 numeric DEFAULT 0,          /*其它入数量*/
  OthInQty2 numeric DEFAULT 0,          /**/
  OthInQtyOther numeric DEFAULT 0,      /**/
  OthInSum numeric DEFAULT 0,           /*其它入金额*/
  OthOutQty1 numeric DEFAULT 0,         /*其它出数量*/
  OthOutQty2 numeric DEFAULT 0,         /**/
  OthOutQtyOther numeric DEFAULT 0,     /**/
  OthOutSum numeric DEFAULT 0,          /*其它出金额*/
  BomOutQty1 numeric DEFAULT 0,         /*原材料卡消耗数量 lzm add 2010-04-19*/
  BomOutQty2 numeric DEFAULT 0,         /*lzm add 2010-04-19*/
  BomOutQtyOther numeric DEFAULT 0,     /*lzm add 2010-04-19*/
  BomOutSum numeric DEFAULT 0,          /*原材料卡消耗金额lzm add 2010-04-19*/
  CheckBatchNo varchar(40) DEFAULT '',  /*当前的盘点批次lzm add 2016-09-06 06:18:42*/
  CONSTRAINT WHOLE_WARESTOCK_DISTRI_pkey PRIMARY KEY (StockYear,StockMonth,DepotID,WareID)
);

CREATE TABLE WHOLE_WARESTOCK_DOM  /*原材料消耗表  lzm add 2009-09-08*/
(
  StockYear integer,              /*年*/
  StockMonth integer,             /*月*/
  DepotID integer,                /*lzm 2010-04-17 改为部门编号(作废:仓库编号)*/
  WareID integer,                 /*原材料编号*/
  sort character varying(30),     /*类别名称*/
  WareName varchar(30),           /*原材料名称*/
  DepotName varchar(30),          /*仓库名称*/
  WareUserCode varchar(30),       /*原材料用户编号*/
  pinyin character varying(20),   /*拼音*/
  model character varying(30),    /*型号*/
  spec character varying(30),     /*规格*/
  area character varying(30),     /*产地*/
  unit character varying(30),     /*计量单位*/
  unit2 character varying(30),    /*辅助单位*/
  scale numeric DEFAULT 0,        /*计量单位与辅助单位的比率*/
  barcode character varying(50),  /*条码*/
  constprice numeric DEFAULT 0,   /*成本价*/
  up_limit numeric DEFAULT 0,     /*库存上限*/
  down_limit numeric DEFAULT 0,   /*库存下限*/
  memo varchar(100),              /*备注*/
  "mode" smallint DEFAULT 0,      /**/
  wxyrate numeric DEFAULT 0,          /*正常损益率*/
  unitother character varying(30),    /*计量单位2*/
  UseQty1 numeric DEFAULT 0,          /*消耗数量*/
  UseQty2 numeric DEFAULT 0,          /*消耗辅助单位2数量*/
  UseQtyOther numeric DEFAULT 0,      /*消耗单位2数量*/
  BomQty1 numeric DEFAULT 0,          /*标准(原材料卡)消耗数量 lzm add 2009-09-16*/
  BomQty2 numeric DEFAULT 0,          /*标准(原材料卡)消耗辅助单位2数量 lzm add 2009-09-16*/
  BomQtyOther numeric DEFAULT 0,      /*标准(原材料卡)消耗单位2数量 lzm add 2009-09-16*/
  UseSum numeric DEFAULT 0,           /*消耗金额 lzm add 2010-04-16*/
  BomSum numeric DEFAULT 0,           /*标准(原材料卡)消耗金额 lzm add 2010-04-16*/
  IncomeSum numeric DEFAULT 0,        /*门店前台营业收入 lzm add 2010-04-17*/
  Profit numeric DEFAULT 0,           /*利润 lzm add 2010-04-17*/
  CONSTRAINT WHOLE_WARESTOCK_DOM_pkey PRIMARY KEY (StockYear,StockMonth,DepotID,WareID)
);

-- Table: CalendarMonths

-- DROP TABLE CalendarMonths;

CREATE TABLE StockMonths    /*进销存期间 lzm add 2009-09-06*/
(
  StockYear integer,              /*年*/
  StockMonth integer,             /*月*/
  BeginDate timestamp,            /*开始日期*/
  EndDate timestamp,              /*结束日期*/
  IsWorking integer default 0,    /*是否当前月*/
  IsOpened integer default 0,     /*是否已月始*/
  IsClosed integer default 0,     /*是否已月结*/
  Remark varchar(30),             /*备注*/
  CONSTRAINT StockMonths_pkey PRIMARY KEY (StockYear,StockMonth)
);

-- Table: accountdef

-- DROP TABLE accountdef;

CREATE TABLE accountdef /*进销存账单信息说明*/
(
  id serial NOT NULL,
  "mode" smallint DEFAULT 0,
  memo character varying(100),
  subjectname character varying(50),  /*会计科目名称*/
  subjectid integer DEFAULT 0,        /*会计科目编号*/
  isdebit smallint DEFAULT 0,         /*是否借方*/
  iscredit smallint DEFAULT 0,        /*是否贷方*/
  percent numeric DEFAULT 0,          /*百分比*/
  finish integer DEFAULT 0,
  CONSTRAINT accountdef_pkey PRIMARY KEY (id)
);


-- Index: accountdef_id

-- DROP INDEX accountdef_id;

CREATE INDEX accountdef_id
  ON accountdef
  USING btree
  (id);

-- Index: accountdef_subjectid

-- DROP INDEX accountdef_subjectid;

CREATE INDEX accountdef_subjectid
  ON accountdef
  USING btree
  (subjectid);


-- Table: accountindex

-- DROP TABLE accountindex;

CREATE TABLE accountindex   /*财务记账凭证*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "mode" smallint DEFAULT 0,
  number numeric DEFAULT 0,
  usercode character varying(50),
  date timestamp without time zone,
  accessory integer DEFAULT 0,
  unitid integer DEFAULT 0,
  depotid integer DEFAULT 0,
  employeid1 integer DEFAULT 0,
  employeid2 integer DEFAULT 0,
  employeid3 integer DEFAULT 0,
  subjectid integer DEFAULT 0,
  memo character varying(100),
  finish integer DEFAULT 0,
  employename1 varchar(40) DEFAULT '',  --lzm add 2016-09-29 10:30:07
  employename2 varchar(40) DEFAULT '',  --lzm add 2016-09-29 10:30:07
  employename3 varchar(40) DEFAULT '',  --lzm add 2016-09-29 10:30:07
  CONSTRAINT accountindex_pkey PRIMARY KEY (id)
);


-- Index: accountindex_depotid

-- DROP INDEX accountindex_depotid;

CREATE INDEX accountindex_depotid
  ON accountindex
  USING btree
  (depotid);

-- Index: accountindex_employeid

-- DROP INDEX accountindex_employeid;

CREATE INDEX accountindex_employeid
  ON accountindex
  USING btree
  (employeid1);

-- Index: accountindex_id

-- DROP INDEX accountindex_id;

CREATE INDEX accountindex_id
  ON accountindex
  USING btree
  (id);

-- Index: accountindex_number

-- DROP INDEX accountindex_number;

CREATE INDEX accountindex_number
  ON accountindex
  USING btree
  (number);

-- Index: accountindex_subjectid

-- DROP INDEX accountindex_subjectid;

CREATE INDEX accountindex_subjectid
  ON accountindex
  USING btree
  (subjectid);

-- Index: accountindex_unitid

-- DROP INDEX accountindex_unitid;

CREATE INDEX accountindex_unitid
  ON accountindex
  USING btree
  (unitid);

-- Index: accountindex_usercode

-- DROP INDEX accountindex_usercode;

CREATE INDEX accountindex_usercode
  ON accountindex
  USING btree
  (usercode);


-- Table: accounttable

-- DROP TABLE accounttable;

CREATE TABLE accounttable  /*财务记账凭证详细*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  date timestamp without time zone,
  summary character varying(50),
  subjectname character varying(50),  /*会计科目名称*/
  subjectid integer DEFAULT 0,        /*会计科目编号*/
  debittotal numeric DEFAULT 0,       /*借方*/
  lendertotal numeric DEFAULT 0,      /*贷方*/
  finish integer DEFAULT 0,
  CONSTRAINT accounttable_pkey PRIMARY KEY (id)
);


-- Index: accounttable_id

-- DROP INDEX accounttable_id;

CREATE INDEX accounttable_id
  ON accounttable
  USING btree
  (id);

-- Index: accounttable_subjectid

-- DROP INDEX accounttable_subjectid;

CREATE INDEX accounttable_subjectid
  ON accounttable
  USING btree
  (subjectid);



-- Table: baseinfo

-- DROP TABLE baseinfo;

--mode:
--  BASE_AREA = 11;           //区域
--  BASE_DEPT = 12;           //部门
--  BASE_EMPLOYE_SORT = 13;   //员工类别
--  BASE_LEARNING = 14;       //学历
--  BASE_CASH_BANK = 15;      //现金银行
--  BASE_WARE_SORT = 16;      //原材料类别
--  BASE_WARE_UNIT = 17;      //原材料单位
--  BASE_INCOME_TYPE = 18;    //付款方式-银行
--  BASE_CURRENCY_STYLE = 19; //外币种类
--  BASE_INCOME_SORT = 20;    //收入支出类别
--  BASE_CHANGE_TYPE = 21;    //库存变动类型
--  BASE_NARRATE = 22;        //说明摘要
--  BASE_STOCK_ORDER = 23;    //库存批次
--  BASE_BACK_TYPE = 24;      //退货原因
--  BASE_DEPARTMENT = 25;     //部门 lzm add 【2009-09-12 05时】
--  BASE_DELIVERYSECTOR = 26; //配送部门 lzm add 【2011-10-27 16:13:30】
--  BASE_AUDITLEVEL = 27;     //审核级别名称 lzm add 【2011-10-27 16:13:30】
--  BASE_UNIT_GROUP = 28;     //所属用户组 lzm add 【2012-12-24 17:39:59】
--  BASE_BUYERNAME = 29;      //采购员 lzm add 【2013-01-05 15:28:23】

CREATE TABLE baseinfo /*系统基本资料信息*/
(
  id serial NOT NULL,
  treeparent integer DEFAULT 0,
  name1 character varying(100),
  name2 character varying(100),
  name3 character varying(100),
  value1 numeric DEFAULT 0,
  "mode" smallint DEFAULT 0,
  usercode varchar(50),          /*用户编号 lzm add 2009-08-27*/
  sortorder integer default 0,   /*排序顺序 lzm add 2013-04-06*/
  CONSTRAINT baseinfo_id_key UNIQUE (id)
);


-- Table: billexist

-- DROP TABLE billexist;

CREATE TABLE billexist  /*库存调整单据详细*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  date timestamp without time zone,  /* 采购日期(配送请购单) */
  billdate timestamp without time zone,
  "mode" smallint DEFAULT 0,
  billname character varying(50),
  warecode character varying(50),
  warename character varying(50),
  wareunit character varying(30),
  wareid integer DEFAULT 0,
  number numeric DEFAULT 0,    /*账单数量*/   /*盘点:库存数量  组装拆卸:实际用量 配送单:配送数量 请购单:计划采购*/
  tonumber numeric DEFAULT 0,                 /*盘点:盘点数量  组装拆卸:BOM用量 配送单:申配数量*/
  unnumber numeric DEFAULT 0,                 /*盘点:合计损益量 组装拆卸:与BOM的差额=实际用量-BOM用量(number-tonumber) 配送单:实收数量*/
  price numeric DEFAULT 0,     /*单价*/
  price1 numeric DEFAULT 0,
  constprice numeric DEFAULT 0,
  total numeric DEFAULT 0,
  taxrate numeric DEFAULT 0,
  taxprice numeric DEFAULT 0,
  taxtotal numeric DEFAULT 0,
  sum integer DEFAULT 0,
  otherid integer DEFAULT 0,
  memo character varying(100),
  finish integer DEFAULT 0,
  peici integer DEFAULT 0,        /*批次 用于计算成本(暂时没启用)*/
  "type" smallint DEFAULT 0,
  rscale numeric DEFAULT 0,       /*单位比率*/
  runit character varying(30),    /*账单单位*/
  subjectid integer DEFAULT 0,    /*会计科目*/
  bnumber numeric DEFAULT 0,      /*计量单位数量*/
  bprice numeric DEFAULT 0,       /*计量单位金额*/
  
  unpercent numeric DEFAULT 0,    /*盘点:损益率*/
  ingearxyrate integer DEFAULT 1, /*盘点:正常损益 0=否 1=是*/
  
  unnumber1 numeric DEFAULT 0,    /*盘点:定额损益*/
  unnumber2 numeric DEFAULT 0,    /*盘点:丢弃量*/
  unnumber3 numeric DEFAULT 0,    /*盘点:意外损耗*/
  unnumber4 numeric DEFAULT 0,    /*盘点:非正常损耗*/
  
  number2 numeric DEFAULT 0,         /*盘点:库存计量单位2数量*/
  runit2 character varying(30),      /*盘点:库存计量单位2名称*/
  tonumber2 numeric DEFAULT 0,       /*盘点:单位2盘点数量*/
  pcname varchar(50),                /*入单机的名称 例如: PC-201921 PDA-3819QI1 TM-DIWN81*/

  --lzm add 2011-12-30
  fnumber1 numeric DEFAULT 0,         /*配送单:采购数量(账单数量)  */
  fnumber2 numeric DEFAULT 0,         /*配送单:生产数量(账单数量) 请购单:应扣库存(账单数量)*/
  fnumber3 numeric DEFAULT 0,         /*配送单:现货数量(账单数量) 请购单:需采购量(账单数量)*/
  bfnumber1 numeric DEFAULT 0,        /*配送单:采购数量(计量单位数量)  */
  bfnumber2 numeric DEFAULT 0,        /*配送单:生产数量(计量单位数量) 请购单:应扣库存(计量单位数量)*/
  bfnumber3 numeric DEFAULT 0,        /*配送单:现货数量(计量单位数量) 请购单:需采购量(计量单位数量)*/

  linknum varchar(60),               /*单据的关联号(用于配送的成本计算) lzm add 2012-2-12*/
  lineid integer,                    /*行号(用于与BillNumberDetail关联) lzm add 2012-2-13*/

  btonumber numeric DEFAULT 0,   /*计量单位数量 lzm add 2012-2-16*/
  btoprice numeric DEFAULT 0,    /*计量单位金额 lzm add 2012-2-16*/
  bunnumber numeric DEFAULT 0,   /*计量单位数量 lzm add 2012-2-16*/
  bunprice numeric DEFAULT 0,    /*计量单位金额 lzm add 2012-2-16*/
  tototal numeric DEFAULT 0,     /*tonumber对应的小计金额*/
  untotal numeric DEFAULT 0,     /*unnumber对应的小计金额*/
  unprice numeric DEFAULT 0,     /*unnumber对应的单价 lzm add 2012-08-06*/
  
  Batchid varchar(40) default '', /*用于ioqueuelink的批号 lzm add 2012-08-21*/
  fifolink text[][],              /*与进货单挂钩的信息
                                   {{"批号","mode","单位","数量","单价","金额"},..,{}}
                                   lzm add 2012-08-23
                                  */
  outbnumber numeric default 0,       /*出货的数量 lzm add 2012-08-23*/
  outreturnbnumber numeric default 0, /*出货退回的数量 lzm add 2012-08-23*/
  memo1 varchar(240),                 /*备注1 lzm add 2012-08-30*/
  memo2 varchar(240),                 /*备注2 lzm add 2012-08-30*/
  momo3 varchar(240),                 /*备注3 lzm add 2012-08-30*/
  rowid integer,                      /*用于前台显示序号 lzm add 2012-09-04*/

  numberstr varchar(50),           /*混合单位数量(1件4包) lzm add 2013-01-10*/
  fnumber1str varchar(50),         /*混合单位数量(1件4包) 配送单:采购数量(账单数量) 请购单:计划采购(账单数量) lzm add 2013-01-10*/
  fnumber2str varchar(50),         /*混合单位数量(1件4包) 配送单:生产数量(账单数量) 请购单:应扣库存(账单数量) lzm add 2013-01-10*/
  fnumber3str varchar(50),         /*混合单位数量(1件4包) 配送单:现货数量(账单数量) 请购单:实际库存(账单数量) lzm add 2013-01-10*/

  usermodified varchar(40),        /*人工修改过 0或空=否 1=是 lzm add 2013-01-13*/
  linknumarray text[],             /*与该单关联的 linknum lzm add 2012-12-27*/

  detailcode varchar(60) default '',          /*配送计划单明细的唯一号[账单号+'_'+行号](用于计算配送成本) lzm add 2013-01-30*/
  linkrunit varchar(30) default '',           /*配送计划单的"单位"(用于计算配送成本) lzm add 2013-01-29*/
  linkprice varchar(30) default '',           /*配送计划单的"单价"(用于计算配送成本) lzm add 2013-01-29*/
  linkmemo varchar(100) default '',           /*配送计划单的"备注"(用于计算配送成本) lzm add 2013-01-29*/
  
  toprice numeric DEFAULT 0,       /*tonumber对应的单价 lzm add 2013-03-25*/
  rowid2 integer,                  /*用于前台排序操作 lzm add 2013-04-16*/
  indate timestamp,                /*进货日期(配送计划单) lzm add 2013-04-18*/
  outdate timestamp,               /*配送日期(配送计划单) lzm add 2013-04-18*/
  ichecked integer default 0,      /*用于批量选择操作 lzm add 2013-04-20*/
  stoptrigger integer default 0,   /*停止触发器 lzm add 2013-04-23*/

  jhnumber numeric DEFAULT 0,      /*进货数量(用于配送单计算利润) lzm add 2013-05-07*/
  jhprice numeric DEFAULT 0,       /*进货单价(用于配送单计算利润) lzm add 2013-05-07*/
  jhtotal numeric DEFAULT 0,       /*进货金额(用于配送单计算利润) lzm add 2013-05-07*/
  kcnumber numeric DEFAULT 0,      /*库存数量(用于配送单计算利润) lzm add 2013-05-07*/
  kcprice numeric DEFAULT 0,       /*库存单价(用于配送单计算利润) lzm add 2013-05-07*/
  kctotal numeric DEFAULT 0,       /*库存金额(用于配送单计算利润) lzm add 2013-05-07*/
  cbtotal numeric DEFAULT 0,       /*成本金额(用于配送单计算利润) lzm add 2013-05-07*/
  profits numeric DEFAULT 0,       /*利润金额(用于配送单计算利润) lzm add 2013-05-07*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号 lzm add 2015-11-23*/
  SHOPID  VARCHAR(40) DEFAULT '' NOT NULL,           /*店编号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID lzm add 2015-11-23*/

  CONSTRAINT billexist_pkey PRIMARY KEY (id)
);


-- Index: billexist_id

-- DROP INDEX billexist_id;

CREATE INDEX billexist_id
  ON billexist
  USING btree
  (id);

-- Index: billexist_indexid

-- DROP INDEX billexist_indexid;

CREATE INDEX billexist_indexid
  ON billexist
  USING btree
  (indexid);

-- Index: billexist_number

-- DROP INDEX billexist_number;

CREATE INDEX billexist_number
  ON billexist
  USING btree
  (number);

-- Index: billexist_orderid

-- DROP INDEX billexist_orderid;

CREATE INDEX billexist_orderid
  ON billexist
  USING btree
  (otherid);

-- Index: billexist_subjectid

-- DROP INDEX billexist_subjectid;

CREATE INDEX billexist_subjectid
  ON billexist
  USING btree
  (subjectid);

-- Index: billexist_warecode

-- DROP INDEX billexist_warecode;

CREATE INDEX billexist_warecode
  ON billexist
  USING btree
  (warecode);

-- Index: billexist_wareid

-- DROP INDEX billexist_wareid;

CREATE INDEX billexist_wareid
  ON billexist
  USING btree
  (wareid);

-- Table: billindex

-- DROP TABLE billindex;

CREATE TABLE billindex  /*账单总表*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "mode" smallint DEFAULT 0,       /*账单类型*/
  number numeric DEFAULT 0,        /*账单数量*/     /*食品加工:食品数量*/
  usercode character varying(50),  /*单号*/
  name character varying(50),      /*账单名称*/
  billdate timestamp without time zone,  /*账单日期*/
  todate timestamp without time zone,    /*收货日期 采购日期(配送请购单)*/
  date2 timestamp without time zone,     /**/
  unitid integer DEFAULT 0,         /*供应商或客户编号       单据查询时为:相关单位*/
  depotid integer DEFAULT 0,        /*仓库编号1*/
  depotid2 integer DEFAULT 0,       /*仓库编号2*/
  employeid integer DEFAULT 0,      /*经手人 对应employees的empid*/
  billmanid integer DEFAULT 0,      /*操作员(好像没有使用)*/
  wareid integer DEFAULT 0,         /*食品加工:食品ID*/
  changetype character varying(50),
  batchno character varying(50),          /*批号*/
  moneylimit numeric DEFAULT 0,
  price numeric DEFAULT 0,                /*单据*/       /*食品加工:食品价格*/
  total numeric DEFAULT 0,                /*金额*/
  rptotal numeric DEFAULT 0,
  moneysubid integer DEFAULT 0,
  moneymode character varying(20),        /*付款类型*/
  address character varying(100),
  memo character varying(240),            /*备注*/
  invoice character varying(20),          /*发票类型*/
  invoicenum character varying(50),       /*发票号*/
  finish integer DEFAULT 0,               /*是否已月结 0=否 1=是 (如果打了月结标志的单不不能再修改)*/
  isunite smallint DEFAULT 0,             /*是否加工合并 1=合并 2=拆卸*/
  "type" smallint DEFAULT 0,              /*1= 2=过账单 3=草稿单 4=被红冲 5=红冲*/
  orderusercode character varying(50),    /*相关帐单*/
  runit character varying(30),            /*品种单位*/
  rscale numeric DEFAULT 0,               /*品种单位和辅助单位的兑换率*/
  billtime timestamp without time zone,   /*账单时间*/
  bnumber numeric DEFAULT 0,              /*计量单位数量*/
  bprice numeric DEFAULT 0,               /*计量单位金额*/
  checkid integer default 0,              /*对应的前台销售账单"ID"  报益报损单:对应的盘点单*/
  reserve3 timestamp without time zone default date_trunc('second', current_timestamp),   /*对应的前台销售账单"日期"*/
  shopid varchar(40) default '',          /*对应的前台销售账单"店编号"*/
  departmentid integer DEFAULT 0,         /*部门编号*/
  parentusercode varchar(50),             /*所属用户编号 lzm add 2009-09-03*/
  departmentid2 integer DEFAULT 0,        /*部门2编号 lzm add 2010-04-06*/
  deliverysector integer DEFAULT 0,       /*配送部门 例如:工具,中厨,面包 等 lzm add 2011-10-27*/
  empname_audit1 varchar(100),            /*1级审核人名称(即制单人) lzm add 2011-10-28*/
  empname_audit2 varchar(100),            /*2级审核人名称 lzm add 2011-10-28*/
  empname_audit3 varchar(100),            /*3级审核人名称 lzm add 2011-10-28*/
  empname_audit4 varchar(100),            /*4级审核人名称 lzm add 2011-10-28*/
  empname_audit5 varchar(100),            /*5级审核人名称 lzm add 2011-10-28*/
  isnew integer default 0,                /*是否最新的报价单(用于采购单的供应商最新报价单) lzm add 2011-11-27*/
  pcname varchar(200),                    /*入单机的名称 例如: PC-201921 PDA-3819QI1 TM-DIWN81 lzm add 2011-12-14*/
  client_tj integer default 0,            /*客户是否已经提交单据(用于配送王的手机提交) lzm add 2011-12-14*/
  ps_status integer default 0,            /*配送状态 0=新单 1=正在配送 2=已配送*/
  linknum varchar(60),                    /*单据的关联号,如果是"采购计划单"只记录首个"配送单"的linknum lzm add 2011-12-30*/
  autocreate integer default 0,           /*该单是否系统自动产生(用于配送自动产生的生产计划单) 0=否 1=是(单据1) 2是(单据2) 100是(报损报益单)lzm add 2012-1-5*/
  otherconfirm integer default 0,         /*是否已进行发货确认操作(用于配送单的发货确认) lzm add 2012-01-05*/
  receiveconfirm integer default 0,       /*是否已进行实收数量确认(用于配送单的实收确认) lzm add 2012-2-16*/
  ichecked integer default 0,             /*用于批量选择操作 lzm add 2012-6-7*/
  needrebuild integer default 0,          /*是否需要重整数据,用于记录不是当前工作区间的账单 lzm add 2012-08-14*/
  unitgroup varchar(50),                  /*供应商或客户的组 lzm add 2012-12-26*/
  linknumarray text[],                    /*与该单关联的 linknum lzm add 2012-12-27*/
  buyername varchar(50),                  /*采购员 lzm add 2013-1-3*/
  otherstatus integer default 0,          /*账单的其它状态(用于改变账单颜色) 0=正常 1=已打印 2=已导入 lzm add 2013-03-08*/
  linknumarraysql text,                   /*linknumarray 从这个sql语句提取 lzm add 2013-04-09*/
  stoptrigger integer default 0,          /*停止触发器 lzm add 2013-04-23*/
  infreezestock integer default 0,        /*冻结库存时的账单 0=否 1=是 lzm add 2013-06-06*/
  rebuildsortid integer default 0,        /*用于解冻库存的重整账单 重整账单时的排列顺序(排序顺序为 billdate,billtime,rebuildsortid) lzm add 2013-06-06*/
  isfixedstock integer default 0,         /*是否已进行处理 0=否 1=该盘点单已进行库存调整 lzm add 2013-06-07*/
  rebuildsort timestamp without time zone,  /*用于解冻库存的重整账单 重整的排序日期(用于重整账单时的排列顺序)*/
  unionbillid integer default 0,          /*对应的 库存盘点单(合并调整库存)的id  lzm add 2016-09-15 06:18:28*/
  unioncheck integer default 0,           /*库存盘点单(合并调整库存) 0=否 1=是 lzm add 2016-09-15 07:47:55*/

  USER_ID INTEGER DEFAULT 0,              /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',       /*店的GUID lzm add 2015-11-23*/
  
  printcount integer default 0,           --打印次数 --lzm add 2025-11-30 15:14:17

  CONSTRAINT billindex_pkey PRIMARY KEY (id)
);


-- Index: billindex_billmanid

-- DROP INDEX billindex_billmanid;

CREATE INDEX billindex_billmanid
  ON billindex
  USING btree
  (billmanid);

-- Index: billindex_depotid

-- DROP INDEX billindex_depotid;

CREATE INDEX billindex_depotid
  ON billindex
  USING btree
  (depotid);

-- Index: billindex_employeid

-- DROP INDEX billindex_employeid;

CREATE INDEX billindex_employeid
  ON billindex
  USING btree
  (employeid);

-- Index: billindex_id

-- DROP INDEX billindex_id;

CREATE INDEX billindex_id
  ON billindex
  USING btree
  (id);

-- Index: billindex_invoicenum

-- DROP INDEX billindex_invoicenum;

CREATE INDEX billindex_invoicenum
  ON billindex
  USING btree
  (invoicenum);

-- Index: billindex_moneysubid

-- DROP INDEX billindex_moneysubid;

CREATE INDEX billindex_moneysubid
  ON billindex
  USING btree
  (moneysubid);

-- Index: billindex_number

-- DROP INDEX billindex_number;

CREATE INDEX billindex_number
  ON billindex
  USING btree
  (number);

-- Index: billindex_orderusercode

-- DROP INDEX billindex_orderusercode;

CREATE INDEX billindex_orderusercode
  ON billindex
  USING btree
  (orderusercode);

-- Index: billindex_unitid

-- DROP INDEX billindex_unitid;

CREATE INDEX billindex_unitid
  ON billindex
  USING btree
  (unitid);

-- Index: billindex_usercode

-- DROP INDEX billindex_usercode;

CREATE INDEX billindex_usercode
  ON billindex
  USING btree
  (usercode);

-- Index: billindex_wareid

-- DROP INDEX billindex_wareid;

CREATE INDEX billindex_wareid
  ON billindex
  USING btree
  (wareid);

-- Table: billmoney

-- DROP TABLE billmoney;

CREATE TABLE billmoney   /*费用或存款单详细*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  date timestamp without time zone,
  billdate timestamp without time zone,
  "mode" smallint DEFAULT 0,
  billname character varying(50),
  wareid integer DEFAULT 0,
  subjectid integer DEFAULT 0,
  number numeric DEFAULT 0,
  tonumber numeric DEFAULT 0,
  unnumber numeric DEFAULT 0,
  constprice numeric DEFAULT 0,
  price numeric DEFAULT 0,
  total numeric DEFAULT 0,
  sum integer DEFAULT 0,
  otherid integer DEFAULT 0,
  memo character varying(100),
  finish integer DEFAULT 0,
  "type" smallint DEFAULT 0,
  bnumber numeric DEFAULT 0,
  bprice numeric DEFAULT 0,
  number2 numeric DEFAULT 0,         /*计量单位2数量*/
  runit2 character varying(30),      /*计量单位2名称*/
  tonumber2 numeric DEFAULT 0,        /*单位2收货数量*/
  unnumber2 numeric DEFAULT 0,        /*单位2退货数量*/
  linknum varchar(60),               /*单据的关联号(用于配送的成本计算) lzm add 2012-2-12*/
  lineid integer,                    /*行号(用于与BillNumberDetail关联) lzm add 2012-2-13*/

  rowid integer,                   /*用于前台显示序号 lzm add 2013-04-16*/
  rowid2 integer,                  /*用于前台排序操作 lzm add 2013-04-16*/
  ichecked integer default 0,             /*用于批量选择操作 lzm add 2013-04-20*/
  stoptrigger integer default 0,          /*停在触发器 lzm add 2013-04-23*/
  CONSTRAINT billmoney_pkey PRIMARY KEY (id)
);


-- Index: billmoney_id

-- DROP INDEX billmoney_id;

CREATE INDEX billmoney_id
  ON billmoney
  USING btree
  (id);

-- Index: billmoney_subid

-- DROP INDEX billmoney_subid;

CREATE INDEX billmoney_subid
  ON billmoney
  USING btree
  (subjectid);

-- Table: billsale

-- DROP TABLE billsale;

CREATE TABLE billsale  /*原材料出库账单详细*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  date timestamp without time zone,
  billdate timestamp without time zone,
  "mode" smallint DEFAULT 0,
  billname character varying(50),
  warecode character varying(50),
  warename character varying(50),
  wareunit character varying(30),
  wareid integer DEFAULT 0,
  number numeric DEFAULT 0,
  tonumber numeric DEFAULT 0,
  unnumber numeric DEFAULT 0,
  constprice numeric DEFAULT 0,
  price1 numeric DEFAULT 0,
  price numeric DEFAULT 0,
  total numeric DEFAULT 0,
  taxrate numeric DEFAULT 0,
  taxprice numeric DEFAULT 0,
  taxtotal numeric DEFAULT 0,
  sum integer DEFAULT 0,
  otherid integer DEFAULT 0,
  memo character varying(100),
  finish integer DEFAULT 0,
  peici integer DEFAULT 0,           /*批次 用于计算成本(暂时没启用)*/
  "type" smallint DEFAULT 0,
  rscale numeric DEFAULT 0,
  runit character varying(30),
  subjectid integer DEFAULT 0,
  bnumber numeric DEFAULT 0,         /*计量单位数量*/
  bprice numeric DEFAULT 0,          /*计量单位金额*/
  number2 numeric DEFAULT 0,         /*计量单位2数量*/
  runit2 character varying(30),      /*计量单位2名称*/
  tonumber2 numeric DEFAULT 0,       /*单位2收货数量*/
  unnumber2 numeric DEFAULT 0,       /*单位2退货数量*/
  departmentid integer DEFAULT 0,    /*部门编号 lzm add 2010-04-19*/
  linknum varchar(60),               /*单据的关联号(用于配送的成本计算) lzm add 2012-2-12*/
  lineid integer,                    /*行号(用于与BillNumberDetail关联) lzm add 2012-2-13*/

  Batchid varchar(40) default '', /*用于ioqueuelink的批号 lzm add 2012-08-21*/
  fifolink text[][],              /*先进先出关系
                                   {{"批号","mode","单位","数量","单价","金额"},..,{}}
                                   lzm add 2012-08-23
                                  */
  outbnumber numeric default 0,       /*出货的数量 lzm add 2012-08-23*/
  outreturnbnumber numeric default 0, /*出货退回的数量 lzm add 2012-08-23*/
  memo1 varchar(240),                 /*备注1 lzm add 2012-08-30*/
  memo2 varchar(240),                 /*备注2 lzm add 2012-08-30*/
  momo3 varchar(240),                 /*备注3 lzm add 2012-08-30*/
  rowid integer,                      /*用于前台显示序号 lzm add 2012-09-04*/

  checkid integer default 0,              /*对应的前台销售账单"ID" lzm add 2013-03-12*/
  reserve3 timestamp without time zone default date_trunc('second', current_timestamp),   /*对应的前台销售账单"日期" lzm add 2013-03-12*/
  shopid varchar(40) default '',          /*对应的前台销售账单"店编号" lzm add 2013-03-12*/
  chkdetail_lineid integer,               /*对应的前台销售账单明细"行号" lzm add 2013-03-12*/

  rowid2 integer,                  /*用于前台排序操作 lzm add 2013-04-16*/
  ichecked integer default 0,             /*用于批量选择操作 lzm add 2013-04-20*/
  stoptrigger integer default 0,          /*停在触发器 lzm add 2013-04-23*/

  USER_ID INTEGER DEFAULT 0,                /*集团号 lzm add 2015-11-23*/
  SHOPGUID VARCHAR(200) DEFAULT '',          /*店的GUID lzm add 2015-11-23*/

  CONSTRAINT billsale_pkey PRIMARY KEY (id)
);


-- Index: billsale_id

-- DROP INDEX billsale_id;

CREATE INDEX billsale_id
  ON billsale
  USING btree
  (id);

-- Index: billsale_subjectid

-- DROP INDEX billsale_subjectid;

CREATE INDEX billsale_subjectid
  ON billsale
  USING btree
  (subjectid);

-- Index: billsale_warecode

-- DROP INDEX billsale_warecode;

CREATE INDEX billsale_warecode
  ON billsale
  USING btree
  (warecode);

-- Table: billsetup

-- DROP TABLE billsetup;

CREATE TABLE billsetup  /*库存单据详细列表配置*/
(
  id serial NOT NULL,
  userid integer DEFAULT 0,
  billname character varying(30),
  topname character varying(30),
  customname character varying(30),
  field character varying(30),
  display boolean,
  "read" boolean,
  nodisplay boolean,
  sysread boolean,
  width smallint DEFAULT 0,
  "mode" smallint DEFAULT 0,
  topname_language varchar(30),
  AuditLevel integer default 0,        /*用户的审核级别>=该审核级别才能查看 lzm add 2011-12-23*/
  ShowForUnit boolean,                 /*客户是否可以查看该域 lzm add 2012-1-5*/
  DisplayLevel integer default 0,      /*查看事件 0=所有事件都可以查看 lzm add 2013-05-09*/
  CONSTRAINT billsetup_pkey PRIMARY KEY (id)
);


-- Index: billsetup_id

-- DROP INDEX billsetup_id;

CREATE INDEX billsetup_id
  ON billsetup
  USING btree
  (id);

-- Index: billsetup_id1

-- DROP INDEX billsetup_id1;

CREATE INDEX billsetup_id1
  ON billsetup
  USING btree
  (userid);

-- Table: billparams

-- DROP TABLE billparams;

CREATE TABLE billparams  /*库存单据的参数 lzm add 2016-09-02 04:01:26*/
(
  id serial NOT NULL,
  "mode" smallint DEFAULT 0,
  billname character varying(30),
  pricefrom integer DEFAULT 0,  /*0=固定为0
                                  1=库存成本单价 
                                  2=商品设置的"参考进价" 
                                  3=最近一次进货价格(没有进货时取库存成本单价) 
                                  4=商品设置的"参考售价" 
                                  5=商品设置的"参考售价"
                                  100=手动选择*/
  CONSTRAINT billparams_pkey PRIMARY KEY (id)
);

-- Index: billparams_id

-- DROP INDEX billparams_id;

CREATE INDEX billparams_id
  ON billparams
  USING btree
  (id);

-- Table: billstock

-- DROP TABLE billstock;

CREATE TABLE billstock  /*原材料入库账单详细*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  date timestamp without time zone,
  billdate timestamp without time zone,  /**/
  "mode" smallint DEFAULT 0,         /*材料类别 暂时固定为102*/
  billname character varying(50),    
  warecode character varying(50),    /*材料用户编号*/
  warename character varying(50),    /*材料名称*/
  wareunit character varying(30),    /*材料单位*/
  wareid integer DEFAULT 0,          /*材料ID*/
  number numeric DEFAULT 0,          /*单位数量*/
  tonumber numeric DEFAULT 0,        /*收货数量(配送单) 总数量(进货单) */
  unnumber numeric DEFAULT 0,        /*退货数量(进货单) */
  constprice numeric DEFAULT 0,      /**/
  price1 numeric DEFAULT 0,
  price numeric DEFAULT 0,           /*单价*/
  total numeric DEFAULT 0,           /*金额*/
  "sum" integer DEFAULT 0,           /**/
  otherid integer DEFAULT 0,         /*已付款时 otherid>0*/
  memo character varying(100),       /*备注*/
  finish integer DEFAULT 0,          /*是否月结 0=否 1=是*/
  "type" smallint DEFAULT 0,         /*1= 2=过账单 3=草稿单*/
  rscale numeric DEFAULT 0,          /*单位转换比率*/
  runit character varying(30),       /*单位名称*/
  taxrate numeric DEFAULT 0,
  taxprice numeric DEFAULT 0,
  taxtotal numeric DEFAULT 0,
  peici integer DEFAULT 0,           /*批次 用于计算成本(暂时没启用)*/
  subjectid integer DEFAULT 0,
  bnumber numeric DEFAULT 0,         /*计量单位数量*/
  bprice numeric DEFAULT 0,          /*计量单位价格*/
  number2 numeric DEFAULT 0,         /*计量单位2数量*/
  runit2 character varying(30),      /*计量单位2名称*/
  tonumber2 numeric DEFAULT 0,       /*单位2收货数量*/
  unnumber2 numeric DEFAULT 0,       /*单位2退货数量*/
  unitid  integer DEFAULT 0,         /*供应商或客户编号(采购单,进货单,直拨单) lzm add 2011-11-27*/
  unitname varchar(50),              /*供应商或客户名称(采购单,进货单,直拨单) lzm add 2011-11-27*/
  linknum varchar(60),               /*单据的关联号(用于配送的成本计算) lzm add 2012-2-12*/
  lineid integer,                    /*行号(用于与BillNumberDetail关联) lzm add 2012-2-13*/
  unitusercode varchar(50),          /*供应商或客户 号码(采购单,进货单,直拨单) lzm add 2012-08-10*/
  lossnumber numeric DEFAULT 0,      /*损耗率(进货单) lzm add 2012-08-10*/
  usenumber numeric DEFAULT 0,       /*误差率(进货单) lzm add 2012-08-10*/

  Batchid varchar(40) default '', /*用于ioqueuelink的批号 lzm add 2012-08-21*/
  fifolink text[][],              /*先进先出关系
                                   {{"批号","mode","单位","数量","单价","金额"},..,{}}
                                   lzm add 2012-08-23
                                  */
  outbnumber numeric default 0,       /*出货的数量()  皮重(进货单) lzm add 2012-08-23*/
  outreturnbnumber numeric default 0, /*出货退回的数量 lzm add 2012-08-23*/
  memo1 varchar(240),                 /*备注1 lzm add 2012-08-30*/
  memo2 varchar(240),                 /*备注2 lzm add 2012-08-30*/
  momo3 varchar(240),                 /*备注3 lzm add 2012-08-30*/
  rowid integer,                      /*用于前台显示序号(控件问题) lzm add 2012-09-04*/

  usermodified varchar(40),           /*人工修改过 0或空=否 1=是 lzm add 2013-01-13*/
  linknumarray text[],                /*与该单关联的 linknum lzm add 2012-12-27*/

  detailcode varchar(60) default '',          /*配送计划单明细的唯一号[账单号+'_'+行号](用于计算配送成本) lzm add 2013-01-30*/
  linkrunit varchar(30) default '',           /*配送计划单的"单位"(用于计算配送成本) lzm add 2013-01-29*/
  linkprice varchar(30) default '',           /*配送计划单的"单价"(用于计算配送成本) lzm add 2013-01-29*/
  linkmemo varchar(100) default '',           /*配送计划单的"备注"(用于计算配送成本) lzm add 2013-01-29*/

  orinumber  numeric DEFAULT 0,               /*采购数量(进货单) lzm add 2013-04-06*/
  balancenumber numeric DEFAULT 0,            /*采购差额(进货单) lzm add 2013-04-06*/

  rowid2 integer,                  /*用于前台排序操作 lzm add 2013-04-16*/
  ichecked integer default 0,             /*用于批量选择操作 lzm add 2013-04-20*/
  stoptrigger integer default 0,          /*停在触发器 lzm add 2013-04-23*/
  
  ASSNumber numeric default 0,     /*A实收量(进货单 lzm add 2013-04-28)*/
  ACGNumber numeric default 0,     /*A采购量(进货单) lzm add 2013-04-28*/
  ACGPrice numeric default 0,      /*A采购单价(进货单) lzm add 2013-04-28*/
  BSSNumber numeric default 0,     /*B实收量(进货单) lzm add 2013-04-28*/
  BCGNumber numeric default 0,     /*B采购量(进货单) lzm add 2013-04-28*/
  BCGPrice numeric default 0,      /*B采购单价(进货单) lzm add 2013-04-28*/
  CSSNumber numeric default 0,     /*C实收量(进货单) lzm add 2013-04-28*/
  CCGNumber numeric default 0,     /*C采购量(进货单) lzm add 2013-04-28*/
  CCGPrice numeric default 0,      /*C采购单价(进货单) lzm add 2013-04-28*/

  UsePercentStr varchar(20),       /*误差率%(字符串表示)(进货单) lzm add 2013-04-28*/
  LossPercentStr varchar(20),      /*损耗率%(字符串表示)(进货单) lzm add 2013-04-28*/

  SSPrice numeric default 0,       /*总实收单价(进货单) lzm add 2013-04-28*/
  CGPrice numeric default 0,       /*总采购单价(进货单) lzm add 2013-04-28*/

  UseCounts numeric default 0,     /*误差数(进货单) lzm add 2013-04-28*/
  LossCounts numeric default 0,    /*损耗量(进货单) lzm add 2013-04-28*/

  CONSTRAINT billstock_pkey PRIMARY KEY (id)
);


-- Index: billstock_id

-- DROP INDEX billstock_id;

CREATE INDEX billstock_id
  ON billstock
  USING btree
  (id);

-- Index: billstock_indexid

-- DROP INDEX billstock_indexid;

CREATE INDEX billstock_indexid
  ON billstock
  USING btree
  (indexid);

-- Index: billstock_number

-- DROP INDEX billstock_number;

CREATE INDEX billstock_number
  ON billstock
  USING btree
  (number);

-- Index: billstock_orderid

-- DROP INDEX billstock_orderid;

CREATE INDEX billstock_orderid
  ON billstock
  USING btree
  (otherid);

-- Index: billstock_subjectid

-- DROP INDEX billstock_subjectid;

CREATE INDEX billstock_subjectid
  ON billstock
  USING btree
  (subjectid);

-- Index: billstock_warecode

-- DROP INDEX billstock_warecode;

CREATE INDEX billstock_warecode
  ON billstock
  USING btree
  (warecode);

-- Index: billstock_wareid

-- DROP INDEX billstock_wareid;

CREATE INDEX billstock_wareid
  ON billstock
  USING btree
  (wareid);

CREATE TABLE billnumberdetail  /*lzm comm 作废 2013-01-29   材料数量的细分(用于统计配送单的成本) lzm add 2012-02-12*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,          /*对应BillIndex的id*/
  lineid integer DEFAULT 0,           /*对应BillStock的lineid*/
  linknum varchar(60),                /*单据的关联号(用于配送的成本计算)*/
  dnumber numeric(15, 3) default 0,   /*细分数量*/
  bdnumber numeric(15, 3) default 0,  /*计量单位的细分数量*/
  unitid integer DEFAULT 0,           /*供应商或客户编号       单据查询时为:相关单位*/
  "mode" smallint DEFAULT 0,
  primary key (id)
);

CREATE TABLE ioqueuelink /*先进先出关系表 lzm add 2012-08-17*/
(
  id serial NOT NULL,
  wareid integer DEFAULT 0,          /*原材料ID*/
  warecode varchar(40),              /*用户编号*/
  linkdate timestamp default now(),  /*创建连接的日期*/
  linktype integer default 0,        /*0=有效连接 1=无效连接*/
  depotid integer DEFAULT 0,         /*仓库编号1*/

  inMode integer default 0,
  inBatchid varchar(40) default '',
  inUnit varchar(20),
  inQty numeric(15, 3) default 0,
  inPrice numeric(15, 3) default 0,
  inTotal numeric(15, 3) default 0,
  
  inReturnMode integer default 0,
  inReturnBatchid varchar(40) default '',
  inReturnUnit varchar(20),
  inRerutnQty numeric(15, 3) default 0,
  inReturnPrice numeric(15, 3) default 0,
  inReturnTotal numeric(15, 3) default 0,
  
  outMode integer default 0,
  outBatchid varchar(40) default '',
  outUnit varchar(20),
  outQty numeric(15, 3) default 0,
  outPrice numeric(15, 3) default 0,
  outTotal numeric(15, 3) default 0,
  
  outReturnMode integer default 0,
  outReturnBatchid varchar(40) default '',
  outReturnUnit varchar(20),
  outReturnQty numeric(15, 3) default 0,
  outReturnPrice numeric(15, 3) default 0,
  outReturnTotal numeric(15, 3) default 0
);

-- Table: chartsetup

-- DROP TABLE chartsetup;

CREATE TABLE chartsetup /*饼图设置*/
(
  id serial NOT NULL,
  billmode integer DEFAULT 0,
  charttype integer DEFAULT 0,
  chartfield1 character varying(50),
  chartfield2 character varying(50),
  CONSTRAINT chartsetup_pkey PRIMARY KEY (id)
);


-- Index: chartsetup_id

-- DROP INDEX chartsetup_id;

CREATE INDEX chartsetup_id
  ON chartsetup
  USING btree
  (id);

-- Table: checkwarestock

-- DROP TABLE checkwarestock;

CREATE TABLE checkwarestock    /*库存盘点表*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  wareid integer DEFAULT 0,
  depotid integer DEFAULT 0,
  number numeric DEFAULT 0,                /*计量单位1数量*/
  stockprice numeric DEFAULT 0,
  saleprice numeric DEFAULT 0,
  price integer DEFAULT 0,
  total integer DEFAULT 0,
  "order" integer DEFAULT 0,
  initial smallint DEFAULT 0,
  stockdate timestamp without time zone,
  number2 numeric DEFAULT 0,               /*计量单位2数量*/
  CONSTRAINT checkwarestock_pkey PRIMARY KEY (id)
);


-- Index: checkwarestock_id

-- DROP INDEX checkwarestock_id;

CREATE INDEX checkwarestock_id
  ON checkwarestock
  USING btree
  (id);

-- Table: closethemonth

-- DROP TABLE closethemonth;

CREATE TABLE closethemonth   /*月结信息表 ******停用******    */
(
  id serial NOT NULL,
  closethemonthdate timestamp without time zone, /*月结日期*/
  "order" integer DEFAULT 0,             /*月结的次序编号*/
  startdate timestamp without time zone, /*开始日期*/
  enddate timestamp without time zone,   /*结束日期*/
  startwarestock numeric DEFAULT 0,      /*期初库存*/
  endwarestock numeric DEFAULT 0,        /*期末库存*/
  stock numeric DEFAULT 0,               /*进货金额*/
  stockback numeric DEFAULT 0,           /*退货金额*/
  income numeric DEFAULT 0,              /*门店前台营业收入*/
  profit numeric DEFAULT 0,              /*利润*/
  CONSTRAINT closethemonth_pkey PRIMARY KEY (id)
);


-- Index: closethemonth_id

-- DROP INDEX closethemonth_id;

CREATE INDEX closethemonth_id
  ON closethemonth
  USING btree
  (id);

-- Table: coaccountinfo

-- DROP TABLE coaccountinfo;

CREATE TABLE coaccountinfo   /*帐套信息表*/
(
  id serial NOT NULL,
  name character varying(50),
  linkman character varying(20),
  phone character varying(20),
  phonemove character varying(20),
  phonecall character varying(20),
  phonefax character varying(20),
  postalcode character varying(20),
  address character varying(100),
  banking character varying(50),
  accounts character varying(50),
  credit character varying(20),
  email character varying(50),
  www character varying(50),
  memo text,
  "mode" smallint DEFAULT 0,
  CONSTRAINT coaccountinfo_pkey PRIMARY KEY (id)
);


-- Index: coaccountinfo_id

-- DROP INDEX coaccountinfo_id;

CREATE INDEX coaccountinfo_id
  ON coaccountinfo
  USING btree
  (id);

-- Index: coaccountinfo_postalcode

-- DROP INDEX coaccountinfo_postalcode;

CREATE INDEX coaccountinfo_postalcode
  ON coaccountinfo
  USING btree
  (postalcode);

-- Table: colsetup

-- DROP TABLE colsetup;

CREATE TABLE colsetup   /*各单据的域定义*/
(
  id serial NOT NULL,
  caption character varying(50),
  fieldname character varying(50),
  sysname character varying(50),
  username character varying(50),
  visible integer DEFAULT 0,
  colorder integer DEFAULT 0,
  width integer DEFAULT 0,
  userid integer DEFAULT 0,
  CONSTRAINT colsetup_pkey PRIMARY KEY (id)
);


-- Index: colsetup_userid

-- DROP INDEX colsetup_userid;

CREATE INDEX colsetup_userid
  ON colsetup
  USING btree
  (userid);

-- Table: depot

-- DROP TABLE depot;

CREATE TABLE depot   /*仓库信息*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),
  pinyin character varying(20),
  shortname character varying(20),
  address character varying(100),
  "explain" character varying(100),
  memo text,
  "mode" smallint DEFAULT 0,
  shopid varchar(100),
  CONSTRAINT depot_pkey PRIMARY KEY (id)
);


-- Index: depot_id

-- DROP INDEX depot_id;

CREATE INDEX depot_id
  ON depot
  USING btree
  (id);

-- Index: depot_parentid

-- DROP INDEX depot_parentid;

CREATE INDEX depot_parentid
  ON depot
  USING btree
  (parentid);

-- Index: depot_rootid

-- DROP INDEX depot_rootid;

CREATE INDEX depot_rootid
  ON depot
  USING btree
  (rootid);

-- Index: depot_usercode

-- DROP INDEX depot_usercode;

CREATE INDEX depot_usercode
  ON depot
  USING btree
  (usercode);

CREATE TABLE deliverysector   /* ***作废*** 配送部门 lzm add 2011-10-27*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),
  pinyin character varying(20),
  shortname character varying(20),
  address character varying(100),
  "explain" character varying(100),
  memo text,
  "mode" smallint DEFAULT 0,
  CONSTRAINT deliverysector_pkey PRIMARY KEY (id)
);

CREATE TABLE base2infobill   /*账单基本配置信息 lzm add 2011-11-8*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),       /*账单名称*/
  memo character varying(200),      /*账单说明*/
  "mode" smallint DEFAULT 0,        /*账单类型*/
  useaudit integer default 0,       /*是否需要审核*/
  modeshort varchar(50),            /*账单类型简称 STOCK_ORDER_EDIT 等 lzm add 2011-12-13*/
  billshort varchar(20),            /*账单简称 lzm add 2011-12-13*/
  billtablename varchar(20),        /*对应的表格名称 例如 BILLEXIST BILLSALE BILLSTOCK lzm add 2012-07-03*/
  CONSTRAINT base2infobill_pkey PRIMARY KEY (id)
);

-- Table: employe

-- DROP TABLE employe;

CREATE TABLE employe  /*员工信息*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT -1,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,
  usercode character varying(50),
  "password" character varying(200),
  name character varying(50),
  pinyin character varying(20),
  comedate timestamp without time zone,
  dutydate timestamp without time zone,
  sex character varying(10),
  dept character varying(20),
  learning character varying(20),
  sort character varying(20),
  id_card character varying(20),
  place character varying(30),
  business character varying(20),
  wage numeric DEFAULT 0,
  phone character varying(20),
  phonemove character varying(20),
  phonecall character varying(20),
  phonefax character varying(20),
  postalcode character varying(20),
  address character varying(100),
  email character varying(50),
  memo text,
  "admin" integer DEFAULT 0,
  quit boolean,
  "mode" smallint DEFAULT 0,
  depotproperty character varying(30),
  CONSTRAINT employe_pkey PRIMARY KEY (id)
);


-- Index: employe_id

-- DROP INDEX employe_id;

CREATE INDEX employe_id
  ON employe
  USING btree
  (id);

-- Index: employe_id_card

-- DROP INDEX employe_id_card;

CREATE INDEX employe_id_card
  ON employe
  USING btree
  (id_card);

-- Index: employe_parentid

-- DROP INDEX employe_parentid;

CREATE INDEX employe_parentid
  ON employe
  USING btree
  (parentid);

-- Index: employe_postalcode

-- DROP INDEX employe_postalcode;

CREATE INDEX employe_postalcode
  ON employe
  USING btree
  (postalcode);

-- Index: employe_rootid

-- DROP INDEX employe_rootid;

CREATE INDEX employe_rootid
  ON employe
  USING btree
  (rootid);

-- Index: employe_usercode

-- DROP INDEX employe_usercode;

CREATE INDEX employe_usercode
  ON employe
  USING btree
  (usercode);

-- Table: fixedassets

-- DROP TABLE fixedassets;

CREATE TABLE fixedassets   /*固定资产*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  seedcount integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),
  pinyin character varying(20),
  shortname character varying(20),
  sort character varying(20),
  spec character varying(30),
  dept character varying(30),
  addmode character varying(30),
  usestatus character varying(30),
  bornvalue numeric DEFAULT 0,
  allabate numeric DEFAULT 0,
  netvalue numeric DEFAULT 0,
  indate timestamp without time zone,
  futupvalue numeric DEFAULT 0,
  futuvalue numeric DEFAULT 0,
  abatemode character varying(50),
  usemonth integer DEFAULT 0,
  countmonth integer DEFAULT 0,
  unit character varying(20),
  mabatemod integer DEFAULT 0,
  mabatevalue numeric DEFAULT 0,
  subjectid integer DEFAULT 0,
  subject character varying(30),
  address character varying(50),
  "delete" integer DEFAULT 0,
  period smallint DEFAULT 0,
  CONSTRAINT fixedassets_pkey PRIMARY KEY (id)
);


-- Index: fixedassets_id

-- DROP INDEX fixedassets_id;

CREATE INDEX fixedassets_id
  ON fixedassets
  USING btree
  (id);

-- Index: fixedassets_subjectid

-- DROP INDEX fixedassets_subjectid;

CREATE INDEX fixedassets_subjectid
  ON fixedassets
  USING btree
  (subjectid);

-- Index: fixedassets_usercode

-- DROP INDEX fixedassets_usercode;

CREATE INDEX fixedassets_usercode
  ON fixedassets
  USING btree
  (usercode);

-- Table: fixedassetsdec

-- DROP TABLE fixedassetsdec;

CREATE TABLE fixedassetsdec  /*固定资产减少*/
(
  id serial NOT NULL,
  treeparent integer DEFAULT 0,
  seedcount integer DEFAULT 0,
  pinyin character varying(20),
  fixedid integer DEFAULT 0,
  fixedcode character varying(30),
  fixedname character varying(30),
  decdate timestamp without time zone,
  decmode character varying(20),
  income numeric DEFAULT 0,
  outlay numeric DEFAULT 0,
  why character varying(50),
  CONSTRAINT fixedassetsdec_pkey PRIMARY KEY (id)
);


-- Index: fixedassetsdec_fixedcode

-- DROP INDEX fixedassetsdec_fixedcode;

CREATE INDEX fixedassetsdec_fixedcode
  ON fixedassetsdec
  USING btree
  (fixedcode);

-- Index: fixedassetsdec_fixedid

-- DROP INDEX fixedassetsdec_fixedid;

CREATE INDEX fixedassetsdec_fixedid
  ON fixedassetsdec
  USING btree
  (fixedid);

-- Index: fixedassetsdec_id

-- DROP INDEX fixedassetsdec_id;

CREATE INDEX fixedassetsdec_id
  ON fixedassetsdec
  USING btree
  (id);

-- Table: fixedassetsplus

-- DROP TABLE fixedassetsplus;

CREATE TABLE fixedassetsplus   /*固定资产的其它信息*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  fixedid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),
  pinyin character varying(20),
  spec character varying(30),
  unit character varying(30),
  number numeric DEFAULT 0,
  money numeric DEFAULT 0,
  usedate timestamp without time zone,
  memo character varying(100),
  CONSTRAINT fixedassetsplus_pkey PRIMARY KEY (id)
);


-- Index: fixedassetsplus_fixedid

-- DROP INDEX fixedassetsplus_fixedid;

CREATE INDEX fixedassetsplus_fixedid
  ON fixedassetsplus
  USING btree
  (fixedid);

-- Index: fixedassetsplus_id

-- DROP INDEX fixedassetsplus_id;

CREATE INDEX fixedassetsplus_id
  ON fixedassetsplus
  USING btree
  (id);

-- Index: fixedassetsplus_number

-- DROP INDEX fixedassetsplus_number;

CREATE INDEX fixedassetsplus_number
  ON fixedassetsplus
  USING btree
  (number);

-- Index: fixedassetsplus_usercode

-- DROP INDEX fixedassetsplus_usercode;

CREATE INDEX fixedassetsplus_usercode
  ON fixedassetsplus
  USING btree
  (usercode);

-- Table: fixeddepreciate

-- DROP TABLE fixeddepreciate;

CREATE TABLE fixeddepreciate  /*固定资产折旧*/
(
  id serial NOT NULL,
  fixid smallint DEFAULT 0,
  period smallint DEFAULT 0,
  date timestamp without time zone,
  mabatemod integer DEFAULT 0,
  mabatevalue numeric DEFAULT 0,
  acountid integer DEFAULT 0,
  memo character varying(100),
  CONSTRAINT fixeddepreciate_pkey PRIMARY KEY (id)
);


-- Index: fixeddepreciate_acountid

-- DROP INDEX fixeddepreciate_acountid;

CREATE INDEX fixeddepreciate_acountid
  ON fixeddepreciate
  USING btree
  (acountid);

-- Index: fixeddepreciate_id

-- DROP INDEX fixeddepreciate_id;

CREATE INDEX fixeddepreciate_id
  ON fixeddepreciate
  USING btree
  (id);

-- Index: fixeddepreciate_usercode

-- DROP INDEX fixeddepreciate_usercode;

CREATE INDEX fixeddepreciate_usercode
  ON fixeddepreciate
  USING btree
  (period);

-- Table: fixedwork

-- DROP TABLE fixedwork;

CREATE TABLE fixedwork  /*固定资产工作量录入信息*/
(
  id serial NOT NULL,
  fixid integer DEFAULT 0,
  "work" numeric DEFAULT 0,
  period integer DEFAULT 0,
  CONSTRAINT fixedwork_pkey PRIMARY KEY (id)
);


-- Index: fixedwork_id

-- DROP INDEX fixedwork_id;

CREATE INDEX fixedwork_id
  ON fixedwork
  USING btree
  (id);

-- Table: "login"

-- DROP TABLE "login";

CREATE TABLE "login"    /*登陆用户名和密码*/
(
  id serial NOT NULL,
  name character varying(50),
  coname character varying(50),
  path character varying(255),
  CONSTRAINT login_pkey PRIMARY KEY (id)
);


-- Table: operatelog

-- DROP TABLE operatelog;

CREATE TABLE operatelog    /*操作日志*/
(
  id serial NOT NULL,
  date timestamp without time zone,
  pcname character varying(200),
  employee character varying(200),
  operate character varying(200),
  CONSTRAINT operatelog_pkey PRIMARY KEY (id)
);


-- Index: operatelog_id

-- DROP INDEX operatelog_id;

CREATE INDEX operatelog_id
  ON operatelog
  USING btree
  (id);

-- Table: printtemp

-- DROP TABLE printtemp;

CREATE TABLE printtemp    /*打印临时表*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT -1,
  field1 character varying(50),
  field2 character varying(50),
  field3 character varying(50),
  field4 character varying(50),
  field5 character varying(50),
  field6 character varying(50),
  field7 character varying(50),
  field8 character varying(50),
  field9 character varying(50),
  field10 character varying(50),
  CONSTRAINT printtemp_pkey PRIMARY KEY (id)
);


-- Index: printtemp_id

-- DROP INDEX printtemp_id;

CREATE INDEX printtemp_id
  ON printtemp
  USING btree
  (id);

CREATE TABLE printmodel    /*打印模板表 lzm add 2013-04-21*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT -1,
  reportname varchar(200),            /*报表名称*/
  modelname varchar(200),             /*模版名称*/
  CONSTRAINT printtemp_pkey PRIMARY KEY (id)
);

-- Table: saveform

-- DROP TABLE saveform;

CREATE TABLE saveform    /*窗口位置信息*/
(
  id serial NOT NULL,
  caption character varying(50),
  top integer DEFAULT 0,
  "left" integer DEFAULT 0,
  width integer DEFAULT 0,
  height integer DEFAULT 0,
  state character varying(20),
  gridvband integer DEFAULT 0,
  CONSTRAINT saveform_pkey PRIMARY KEY (id)
);


-- Index: saveform_id

-- DROP INDEX saveform_id;

CREATE INDEX saveform_id
  ON saveform
  USING btree
  (id);

-- Table: selfdefinesql

-- DROP TABLE selfdefinesql;

CREATE TABLE selfdefinesql    /*系统需要用到的sql语句定义*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  name character varying(50),
  caption character varying(150),
  topfieldcaption character varying(255),
  topfieldwidth character varying(255),
  topfieldprintchart character varying(255),
  topfieldbandcaption character varying(255),
  topfieldbandindex character varying(255),
  topfieldpubmask character varying(255),
  topfieldcolsum character varying(255),
  topfield character varying(255),
  sqltext text,
  loaddate smallint DEFAULT 0,
  loaddepot1 smallint DEFAULT 0,
  loaddepot2 smallint DEFAULT 0,
  CONSTRAINT selfdefinesql_pkey PRIMARY KEY (id)
);


-- Index: selfdefinesql_id

-- DROP INDEX selfdefinesql_id;

CREATE INDEX selfdefinesql_id
  ON selfdefinesql
  USING btree
  (id);

-- Index: selfdefinesql_indexid

-- DROP INDEX selfdefinesql_indexid;

CREATE INDEX selfdefinesql_indexid
  ON selfdefinesql
  USING btree
  (indexid);

-- Table: sqlexecute

-- DROP TABLE sqlexecute;

CREATE TABLE sqlexecute   /*系统sql语句执行表*/
(
  id serial NOT NULL,
  indexid integer DEFAULT 0,
  name character varying(50),
  caption character varying(150),
  topfield character varying(255),
  sumfield character varying(255),
  sqltext text,
  CONSTRAINT sqlexecute_pkey PRIMARY KEY (id)
);


-- Index: sqlexecute_id

-- DROP INDEX sqlexecute_id;

CREATE INDEX sqlexecute_id
  ON sqlexecute
  USING btree
  (id);

-- Index: sqlexecute_indexid

-- DROP INDEX sqlexecute_indexid;

CREATE INDEX sqlexecute_indexid
  ON sqlexecute
  USING btree
  (indexid);

-- Table: subject

-- DROP TABLE subject;

CREATE TABLE subject    /*会计科目*/
(
  id serial NOT NULL,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  treeparent integer DEFAULT 0,
  rootid integer DEFAULT 0,
  classid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),
  shortname character varying(50),
  "order" smallint DEFAULT 0,
  currency smallint DEFAULT 0,
  currencyname character varying(50),
  pinyin character varying(20),
  direction character varying(10),
  cashflow character varying(10),
  memo character varying(255),
  quit integer DEFAULT 0,
  "mode" smallint DEFAULT 0,
  CONSTRAINT subject_pkey PRIMARY KEY (id)
);


-- Index: subject_classid

-- DROP INDEX subject_classid;

CREATE INDEX subject_classid
  ON subject
  USING btree
  (classid);

-- Index: subject_id

-- DROP INDEX subject_id;

CREATE INDEX subject_id
  ON subject
  USING btree
  (id);

-- Index: subject_parentid

-- DROP INDEX subject_parentid;

CREATE INDEX subject_parentid
  ON subject
  USING btree
  (treeparent);

-- Index: subject_rootid

-- DROP INDEX subject_rootid;

CREATE INDEX subject_rootid
  ON subject
  USING btree
  (rootid);

-- Index: subject_usercode

-- DROP INDEX subject_usercode;

CREATE INDEX subject_usercode
  ON subject
  USING btree
  (usercode);

-- Table: sysdef

-- DROP TABLE sysdef;

CREATE TABLE sysdef   /*系统内部使用-保存每个单据的顺序号最大值,用于生产下一序列号*/
(
  id serial NOT NULL,
  name character varying(30),
  string character varying(30),
  date timestamp without time zone,
  number numeric DEFAULT 0,
  "float" integer DEFAULT 0,
  "mode" smallint DEFAULT 0,
  CONSTRAINT sysdef_key UNIQUE (id)
);


-- Index: sysdef_number

-- DROP INDEX sysdef_number;

CREATE INDEX sysdef_number
  ON sysdef
  USING btree
  (number);

-- Table: systemini

-- DROP TABLE systemini;

CREATE TABLE systemini    /*系统参数设定*/
(
  id serial NOT NULL,
  sname character varying(20),
  svalue character varying(150),
  smemo character varying(50),
  mtime timestamp without time zone default now(),  /*修改时间*/
  CONSTRAINT systemini_pkey PRIMARY KEY (id)
);


-- Index: systemini_id

-- DROP INDEX systemini_id;

CREATE INDEX systemini_id
  ON systemini
  USING btree
  (id);

--------------------------------------------
CREATE TABLE troute /*行车线路定义 lzm add 2011-12-25*/
(
  id serial NOT NULL,
  treeparent integer DEFAULT 0,
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(100),
  memo character varying(255),
  CONSTRAINT troute_pkey PRIMARY KEY (id)
);

--------------------------------------------
CREATE TABLE troute_unit  /*客户所属的行车路线 lzm add 2011-12-25*/
(
  id serial NOT NULL,
  trouteid integer DEFAULT 0,
  unitid integer DEFAULT 0,
  CONSTRAINT troute_unit_pkey PRIMARY KEY (id)
);

--------------------------------------------
-- Table: unit

-- DROP TABLE unit;

--mode:
--  BASE_CLIENT = 41;     //客户
--  BASE_PROVIDE = 42;    //供应商

CREATE TABLE unit   /*供应商或客户资料*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,
  usercode character varying(50),
  name character varying(50),
  pinyin character varying(20),
  shortname character varying(20),
  areaname character varying(50),
  linkman character varying(20),
  phone character varying(20),
  phonemove character varying(20),
  phonecall character varying(20),
  phonefax character varying(20),
  postalcode character varying(20),
  address character varying(100),
  banking character varying(50),
  accounts character varying(50),
  credit character varying(20),       /*信誉度*/
  email character varying(50),
  www character varying(50),
  memo text,
  "mode" smallint DEFAULT 0,
  receive numeric DEFAULT 0,            /*[lzm modify 作废 2012-08-12] 期初应收*/
  payable numeric DEFAULT 0,            /*[lzm modify 作废 2012-08-12] 期初应付*/
  weight varchar(20),                   /*权值(用于录入采购单时选择供应商的条件) lzm add 2011-11-27*/
  passwd varchar(20),                   /* ***作废(改为用employees内的idvalue lzm modify 2011-12-13)***  密码 lzm add 2011-12-3*/
  depotname varchar(50),                /* ***作废(改为用employees内的stockdepot lzm modify 2011-12-13)***  客户配送对应的仓库名称 lzm add 2011-12-12*/
  groupname varchar(50),                /*所属用户组 lzm add 2012-12-24*/
  priority varchar(20),                 /*优先级别 lzm add 2013-01-01*/
  ps_addvalue varchar(20),              /*配送加价(10代表加10元  10%代表加价10%) lzm add 2013-01-04*/
  DirectStore integer DEFAULT 0,        /*直营店 lzm add 2013-1-6*/
  FromPriceOrTotal integer DEFAULT 0,   /*价格公式, 用于:"进货单" 0=价格公式跟系统参数 1=录入单价得金额 2=录入金额得单价 lzm add 2013-03-23*/
  ClassPropery varchar(50),             /*分类属性 lzm add 2013-3-29*/
  PriceReadOnly integer DEFAULT 0,      /*单价不允许修改 0=否 1=是 lzm add 2017-06-08 02:46:54*/
  CONSTRAINT unit_pkey PRIMARY KEY (id)
);


-- Index: unit_id

-- DROP INDEX unit_id;

CREATE INDEX unit_id
  ON unit
  USING btree
  (id);

-- Index: unit_parentid

-- DROP INDEX unit_parentid;

CREATE INDEX unit_parentid
  ON unit
  USING btree
  (parentid);

-- Index: unit_postalcode

-- DROP INDEX unit_postalcode;

CREATE INDEX unit_postalcode
  ON unit
  USING btree
  (postalcode);

-- Index: unit_rootid

-- DROP INDEX unit_rootid;

CREATE INDEX unit_rootid
  ON unit
  USING btree
  (rootid);

-- Index: unit_usercode

-- DROP INDEX unit_usercode;

CREATE INDEX unit_usercode
  ON unit
  USING btree
  (usercode);

-- Table: unitmoney

-- DROP TABLE unitmoney;

CREATE TABLE unitmoney  /*[lzm modify 作废 2012-08-12] 当前每个 客户或供应商资料的应收应付款 的小计表*/
(
  id serial NOT NULL,
  unitid integer DEFAULT 0,
  period integer DEFAULT 0,             /*期号*/
  date timestamp without time zone,     /*登记日期*/
  offdate timestamp without time zone,
  artotal0 numeric DEFAULT 0,           /*期初应收应付*/
  artotal numeric DEFAULT 0,            /*应付应收金额*/
  doartotal numeric DEFAULT 0,          /*已收已付金额*/
  overartotal numeric DEFAULT 0,        /*期末应收应付*/
  CONSTRAINT unitmoney_pkey PRIMARY KEY (id)
);


-- Index: unitmoney_id

-- DROP INDEX unitmoney_id;

CREATE INDEX unitmoney_id
  ON unitmoney
  USING btree
  (id);

CREATE TABLE whole_unitmoney  /*历史每个 客户或供应商资料的应收应付款 的小计表 lzm add 2011-12-18*/
(
  id serial NOT NULL,
  unityear integer not null,            /*年*/
  unitmonth integer not null,           /*月*/
  unitid integer DEFAULT 0,             /*客户或供应商ID*/
  period integer DEFAULT 0,             /*期号*/
  date timestamp without time zone,     /*登记日期*/
  offdate timestamp without time zone,
  artotal0 numeric DEFAULT 0,           /*期初应收应付*/
  artotal numeric DEFAULT 0,            /*应收应付金额*/
  doartotal numeric DEFAULT 0,          /*已收已付金额*/
  overartotal numeric DEFAULT 0,        /*期末应收应付*/
  is0 integer DEFAULT 0,                /*是否营业前的应收应付金额("年结"时标记,重整应收应付时不能删除该记录) lzm add 2012-08-14*/
  depotid integer DEFAULT 0,            /*仓库编号 lzm add 2016-09-19 01:33:47*/
  CONSTRAINT whole_unitmoney_pkey PRIMARY KEY (id)
);

-- Table: userlimit

-- DROP TABLE userlimit;

CREATE TABLE userlimit   /*员工权限设置*/
(
  id serial NOT NULL,
  userid integer DEFAULT 0,
  limitstr character varying(255),
  CONSTRAINT userlimit_pkey PRIMARY KEY (id)
);


-- Index: userlimit_userid

-- DROP INDEX userlimit_userid;

CREATE INDEX userlimit_userid
  ON userlimit
  USING btree
  (userid);

-- Table: wageitem

-- DROP TABLE wageitem;

CREATE TABLE wageitem    /*工资项目定义*/
(
  id serial NOT NULL,
  treeparent integer DEFAULT 0,
  seedcount integer DEFAULT 0,
  name character varying(100),
  "type" character varying(100),
  state character varying(50),
  canexp character varying(50),
  expression character varying(255),
  fieldname character varying(100),
  "order" integer DEFAULT 0,
  memo character varying(255),
  CONSTRAINT wageitem_pkey PRIMARY KEY (id)
);


-- Index: wageitem_id

-- DROP INDEX wageitem_id;

CREATE INDEX wageitem_id
  ON wageitem
  USING btree
  (id);

-- Table: wageorder

-- DROP TABLE wageorder;

CREATE TABLE wageorder    /*工资工序*/
(
  id serial NOT NULL,
  treeparent integer DEFAULT 0,
  seedcount integer DEFAULT 0,
  wageorder character varying(100),
  wagekind character varying(100),
  wageprice integer DEFAULT 0,
  memo text,
  CONSTRAINT wageorder_pkey PRIMARY KEY (id)
);


-- Index: wageorder_id

-- DROP INDEX wageorder_id;

CREATE INDEX wageorder_id
  ON wageorder
  USING btree
  (id);

-- Table: wagetable

-- DROP TABLE wagetable;

CREATE TABLE wagetable    /*工资数据设置*/
(
  id serial NOT NULL,
  treeparent integer DEFAULT 0,
  employeid integer DEFAULT 0,
  signature character varying(100),
  memo character varying(255),
  period integer DEFAULT 0,
  a0 numeric DEFAULT 0,
  a1 numeric DEFAULT 0,
  a2 numeric DEFAULT 0,
  a3 numeric DEFAULT 0,
  a4 numeric DEFAULT 0,
  a5 numeric DEFAULT 0,
  a6 numeric DEFAULT 0,
  a7 numeric DEFAULT 0,
  a8 numeric DEFAULT 0,
  a9 numeric DEFAULT 0,
  a10 numeric DEFAULT 0,
  a11 numeric DEFAULT 0,
  a12 numeric DEFAULT 0,
  a13 numeric DEFAULT 0,
  a14 numeric DEFAULT 0,
  a15 numeric DEFAULT 0,
  a16 numeric DEFAULT 0,
  a17 numeric DEFAULT 0,
  a18 numeric DEFAULT 0,
  a19 numeric DEFAULT 0,
  a20 numeric DEFAULT 0,
  a21 numeric DEFAULT 0,
  a22 numeric DEFAULT 0,
  a23 numeric DEFAULT 0,
  a24 numeric DEFAULT 0,
  a25 numeric DEFAULT 0,
  a26 numeric DEFAULT 0,
  a27 numeric DEFAULT 0,
  a28 numeric DEFAULT 0,
  a29 numeric DEFAULT 0,
  a30 numeric DEFAULT 0,
  CONSTRAINT wagetable_pkey PRIMARY KEY (id)
);


-- Index: wagetable_id

-- DROP INDEX wagetable_id;

CREATE INDEX wagetable_id
  ON wagetable
  USING btree
  (id);

-- Table: ware

-- DROP TABLE ware;

CREATE TABLE ware   /*原材料表*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  "level" character varying(50),
  seedcount integer DEFAULT 0,
  parentid integer DEFAULT 0,
  rootid integer DEFAULT 0,           /**/
  usercode character varying(50),     /*用户编号*/
  name character varying(100),        /*名称*/
  shortname character varying(100),   /*简称*/
  pinyin character varying(20),       /*拼音码*/
  model character varying(30),        /*型号*/
  spec character varying(30),         /*规格*/
  area character varying(30),         /**/
  "type" character varying(30),       /**/
  unit character varying(30),     /*计量单位*/
  unit2 character varying(30),    /*辅助单位*/
  scale numeric DEFAULT 0,        /*计量单位与辅助单位的比率*/
  sort character varying(30),     /*所属原材料分类*/
  barcode character varying(50),  /*条码*/
  pos_price numeric DEFAULT 0,    /*参考售价*/
  pos_purch numeric DEFAULT 0,    /*参考进价*/
  constprice numeric DEFAULT 0,   /*成本价*/
  price1 numeric DEFAULT 0,       /*预设售价1*/
  price2 numeric DEFAULT 0,       /*预设售价2*/
  price3 numeric DEFAULT 0,       /*预设售价3*/
  price4 numeric DEFAULT 0,       /*预设售价4*/
  up_limit numeric DEFAULT 0,     /*库存上限*/
  down_limit numeric DEFAULT 0,   /*库存下限*/
  memo text,
  use boolean,
  "mode" smallint DEFAULT 0,
  depotproperty character varying(30),  /* ***作废***(配送属性 之前用作填写配送单时只能录入相应仓库的原材料) */
  autofillstock integer DEFAULT 0,      /*是否自动填写进货单数量 如果是则需要填写表warefillstock的内容*/
  wxyrate numeric DEFAULT 0,            /*正常损益率*/
  unitother character varying(30),      /*计量单位2*/
  --menuitemid varchar(30),             /*对应的菜式编号 如果有对应的菜式编号则用户不能修改usercode 将由系统来维护*/
  DeliverySector varchar(30),           /*配送部门 lzm add 2011-10-27*/

  --lzm add 2011-12-18
  Package varchar(50),                  /*包装*/
  StorageConditions varchar(50),        /*保存条件*/
  Brand varchar(50),                    /*品牌*/
  Period varchar(50),                   /*有效期*/
  Other1 varchar(50),                   /*其它1*/

  Gift integer default 0,               /*赠品 lzm add 2013-04-07*/
  sortorder varchar(50),                /*排列顺序 lzm add 2013-04-11*/
  UseRatioUp numeric,                   /*利用率上限 lzm add 2013-05-02*/
  LossRatioUp numeric,                  /*损耗率上限 lzm add 2013-05-02*/
  pricemax1 numeric default 0,          /*配送的单价上限 0或空=不限制 lzm add 2013-05-28*/

  CONSTRAINT ware_pkey PRIMARY KEY (id)
);


-- Index: ware_barcode

-- DROP INDEX ware_barcode;

CREATE INDEX ware_barcode
  ON ware
  USING btree
  (barcode);

-- Index: ware_depotid

-- DROP INDEX ware_depotid;

CREATE INDEX ware_depotid
  ON ware
  USING btree
  (depotproperty);

-- Index: ware_id

-- DROP INDEX ware_id;

CREATE INDEX ware_id
  ON ware
  USING btree
  (id);

-- Index: ware_parentid

-- DROP INDEX ware_parentid;

CREATE INDEX ware_parentid
  ON ware
  USING btree
  (parentid);

-- Index: ware_rootid

-- DROP INDEX ware_rootid;

CREATE INDEX ware_rootid
  ON ware
  USING btree
  (rootid);

-- Index: ware_usercode

-- DROP INDEX ware_usercode;

CREATE INDEX ware_usercode
  ON ware
  USING btree
  (usercode);

--------------------------------------------------------------------
CREATE TABLE warebom   /*原材料BOM表 lzm add 2011-12-20*/
(
  wareid integer NOT NULL,              /*商品ID*/
  bomwareid integer NOT NULL,           /*BOM材料ID*/
  bomcount numeric(15,3) default 0,     /*BOM材料数量*/
  sortorder integer default 0,          /*排列顺序*/
  comwarecode varchar(30),              /*  保留  */
  bomwarecode varchar(30),              /*BOM材料usercode*/
  CONSTRAINT warebom_pkey PRIMARY KEY (wareid, bomwareid)
);

--------------------------------------------------------------------
CREATE TABLE wareunitprice   /*原材料客户价格表*/
(
  wareid integer NOT NULL,    /*商品ID*/
  unitid integer NOT NULL,    /*客户ID*/
  amounts numeric(15,3) default 0,
  CONSTRAINT wareunitprice_pkey PRIMARY KEY (wareid, unitid)
);

--------------------------------------------------------------------
-- Table: warefillstock
-- DROP TABLE warefillstock;

CREATE TABLE warefillstock   /*原材料自动进货数量的设定*/
(
  wareid integer NOT NULL,
  depotid integer NOT NULL,
  fillcounts numeric,
  CONSTRAINT warefillstock_pkey PRIMARY KEY (wareid, depotid)
);


-- Table: warestock

-- DROP TABLE warestock;

CREATE TABLE warestock    /*原材料库存情况*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  wareid integer DEFAULT 0,                /*原材料编号*/
  depotid integer DEFAULT 0,               /*仓库编号*/
  number numeric DEFAULT 0,                /*数量*/
  stockprice numeric DEFAULT 0,            /*成本单价，库存单价(用于录入出货单时的单价)*/
  saleprice numeric DEFAULT 0,             /*销售单价*/
  price numeric DEFAULT 0,                 /*  批次单价 用于先进先出 后进先出法 的成本计算*/
  total numeric DEFAULT 0,                 /*成本合计，库存金额(录入出货单时的金额合计)*/
  "order" integer DEFAULT 0,               /*  批次 用于先进先出 后进先出法 的成本计算(暂时没启用)*/
  initial smallint DEFAULT 0,              /**/
  stockdate timestamp without time zone,   /*更新原材料信息日期*/
  number2 numeric DEFAULT 0,               /*计量单位2数量*/
  memo character varying(100),             /*备注 lzm add 2010-04-02*/
  CONSTRAINT warestock_pkey PRIMARY KEY (id)
);


-- Index: warestock_id

-- DROP INDEX warestock_id;

CREATE INDEX warestock_id
  ON warestock
  USING btree
  (id);

-- Table: warestock0

-- DROP TABLE warestock0;

CREATE TABLE warestock0    /*期初库存情况*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  wareid integer DEFAULT 0,                /*原材料编号*/
  depotid integer DEFAULT 0,               /*仓库编号*/
  number numeric DEFAULT 0,                /*数量*/
  stockprice numeric DEFAULT 0,            /*成本单价*/
  saleprice numeric DEFAULT 0,             /*销售单价*/
  price numeric DEFAULT 0,                 /*  批次单价 用于先进先出 后进先出法 的成本计算*/
  total numeric DEFAULT 0,                 /*成本合计*/
  "order" integer DEFAULT 0,               /*  批次 用于先进先出 后进先出法 的成本计算(暂时没启用)*/
  initial smallint DEFAULT 0,
  stockdate timestamp without time zone,   /*更新原材料信息日期*/
  number2 numeric DEFAULT 0,               /*计量单位2数量*/
  memo character varying(100),             /*备注 lzm add 2010-04-02*/
  CONSTRAINT warestock0_pkey PRIMARY KEY (id)
);


-- Index: warestock0_id

-- DROP INDEX warestock0_id;

CREATE INDEX warestock0_id
  ON warestock0
  USING btree
  (id);

-- Table: warestockforsales

-- DROP TABLE warestockforsales;

CREATE TABLE warestockforsales   /*销售单的原材料消耗统计表*/
(
  id serial NOT NULL,
  treeparent smallint DEFAULT 0,
  wareid integer DEFAULT 0,                /*原材料编号*/
  depotid integer DEFAULT 0,               /*仓库编号*/
  number numeric DEFAULT 0,                /*数量*/
  stockprice numeric DEFAULT 0,            /*成本单价*/
  saleprice numeric DEFAULT 0,             /*销售单价*/
  price numeric DEFAULT 0,                 /*  批次单价 用于先进先出 后进先出法 的成本计算*/
  total numeric DEFAULT 0,                 /*成本合计*/
  "order" integer DEFAULT 0,               /*  批次 用于先进先出 后进先出法 的成本计算(暂时没启用)*/
  initial smallint DEFAULT 0,
  stockdate timestamp without time zone,   /*更新原材料信息日期*/
  number2 numeric DEFAULT 0,               /*计量单位2数量*/
  CONSTRAINT warestockforsales_pkey PRIMARY KEY (id)
);


-- Index: warestockforsales_id

-- DROP INDEX warestockforsales_id;

CREATE INDEX warestockforsales_id
  ON warestockforsales
  USING btree
  (id);

--CREATE TABLE AUDIT_EMPLOYEES  /*审核级别 最多5级 lzm add 2011-10-29*/
--(
--  id serial not null,
--  AUDITLEVEL    INTEGER NOT NULL,        /*审核级别*/
--  AUDITEMPNAME  VARCHAR(40) NOT NULL,    /*审核级别的员工名称*/
--  CONSTRAINT audit_employees_pkey PRIMARY KEY (id)
--);


--CREATE TABLE WAREFILLSTOCK
--(
--  WAREID      INTEGER NOT NULL,
--  DEPOTID     INTEGER NOT NULL,
--  FILLCOUNTS  NUMERIC,
--  PRIMARY KEY (WAREID, DEPOTID)
--);
--
--CREATE TABLE WARE
--(
--  ID INTEGER SERIAL,
--  TREEPARENT SMALLINT,
--  LEVEL CHARACTER VARYING(50),
--  SEEDCOUNT INTEGER,
--  PARENTID INTEGER,
--  ROOTID INTEGER,
--  USERCODE CHARACTER VARYING(50),
--  NAME CHARACTER VARYING(50),
--  SHORTNAME CHARACTER VARYING(20),
--  PINYIN CHARACTER VARYING(20),
--  MODEL CHARACTER VARYING(30),
--  SPEC CHARACTER VARYING(30),
--  AREA CHARACTER VARYING(30),
--  TYPE CHARACTER VARYING(30),
--  UNIT CHARACTER VARYING(30),
--  UNIT2 CHARACTER VARYING(30),
--  SCALE DOUBLE PRECISION,
--  SORT CHARACTER VARYING(30),
--  BARCODE CHARACTER VARYING(50),
--  POS_PRICE DOUBLE PRECISION,
--  POS_PURCH DOUBLE PRECISION,
--  CONSTPRICE DOUBLE PRECISION,
--  PRICE1 DOUBLE PRECISION,
--  PRICE2 DOUBLE PRECISION,
--  PRICE3 DOUBLE PRECISION,
--  PRICE4 DOUBLE PRECISION,
--  UP_LIMIT DOUBLE PRECISION,
--  DOWN_LIMIT DOUBLE PRECISION,
--  MEMO TEXT,
--  USE BOOLEAN,
--  MODE SMALLINT,
--  DEPOTPROPERTY CHARACTER VARYING(30),
--  AUTOFILLSTOCK SMALLINT
--  PRIMARY KEY (ID)
--); 

/*
  //基础资料{10-20}
  BASE_AREA = 11;           //区域
  BASE_DEPT = 12;           //部门
  BASE_EMPLOYE_SORT = 13;   //员工类别
  BASE_LEARNING = 14;       //学历
  BASE_CASH_BANK = 15;      //现金银行
  BASE_WARE_SORT = 16;      //原材料类别
  BASE_WARE_UNIT = 17;      //原材料单位
  BASE_INCOME_TYPE = 18;    //付款方式-银行
  BASE_CURRENCY_STYLE = 19; //外币种类
  BASE_INCOME_SORT = 20;    //收入支出类别
  BASE_CHANGE_TYPE = 21;    //库存变动类型
  BASE_NARRATE = 22;        //说明摘要
  BASE_STOCK_ORDER = 23;    //库存批次
  BASE_BACK_TYPE = 24;      //退货原因
  BASE_DEPARTMENT = 25;     //部门 lzm add 【2009-09-12 05时】
  BASE_DELIVERYSECTOR = 26; //配送部门 lzm add 【2011-10-27 16:13:30】
  BASE_AUDITLEVEL = 27;     //审核级别名称 lzm add 【2011-10-27 16:13:30】
  BASE_UNIT_GROUP = 28;     //所属用户组 lzm add 【2012-12-24 17:39:59】
  BASE_BUYERNAME = 29;      //采购员 lzm add 【2013-01-05 15:28:23】

  //固定资产
  BASE_FIXED_SORT = 31;
  BASE_FIXED_MODE = 32;
  BASE_FIXED_USE = 33;
  
  //复杂基础资料{20-30}
  BASE_CLIENT = 41;     //客户
  BASE_PROVIDE = 42;    //供应商
  BASE_EMPLOYE = 43;    //员工
  BASE_WARE = 44;       //原材料
  BASE_DEPOT = 45;      //仓库
  BASE_SUBJECT = 46;    //会计科目
  BASE_BILL = 47;       //账单基本信息 lzm add 【2011-11-08 17:07:11】
  BASE_TROUTE = 48;     //行车路线 lzm add 【2011-12-25 15:56:32】

  //固定资产
  BASE_FIXED_ADD = 51;
  BASE_FIXED_DEC = 52;
  BASE_FIXED_WORK = 53;
  BASE_FIXED_DEPRECIATE = 54;
  BASE_FIXED_UN_DEPRECIAT = 55;
  //工资管理
  BASE_WAGE_KIND = 56;              //种类
  BASE_WAGE_PROCEDURE = 57;         //工序
  BASE_WAGE_ITEM = 58;              //工资项目
  WAGE_DATA_INPUT = 59;             //工资数据录入

  //进货单编辑{100-110}
  STOCK_EDIT_BEGIN = 100;
  STOCK_ORDER_EDIT = 101;           //进货订单
  STOCK_FORMAL_EDIT = 102;          //进货单
  STOCK_MONEY_EDIT = 103;           //进货付款单
  STOCK_BACK_EDIT = 104;            //进货退货单
  STOCK_INDEPT_EDIT = 105;          //部门进货直拨单
  STOCK_INDEPTBACK_EDIT = 106;      //部门进货直拨单退货单
  STOCK_QUOTE_EDIT = 107;           //报价单   lzm add 【2011-11-25 14:45:46】
  STOCK_PURCHASE_EDIT = 108;        //采购单  lzm add 【2011-11-25 14:45:46】
  STOCK_PURCHASE_PLAN_EDIT = 109;   //采购计划单 lzm add 【2012-01-01 18:30:50】
  STOCK_EDIT_END = 110;

  //销售单编辑{110-120}
  SALE_EDIT_BEGIN = 110;
  SALE_ORDER_EDIT = 111;            //销售订单
  SALE_FORMAL_EDIT = 112;           //销售单
  SALE_MONEY_EDIT = 113;            //销售收款单
  SALE_READY_EDIT = 114;            //现款销售单(用于根据原材料卡扣库存)
  SALE_BACK_EDIT = 115;             //销售退货单
  SALE_POS_EDIT = 116;              //零售单(POS)

  //门店相关 
  SALE_SHOP_EDIT_BEGIN = 117;
  SALE_SHOP_FORMAL_EDIT = 118;      //门店出仓单
  SALE_SHOP_BACK_EDIT = 119;        //门店出仓退货单
  
  SALE_SHOP_EDIT_END = 120;
  SALE_EDIT_END = 120;
  
  //库存单据 {120-139}
  EXIST_EDIT_BEGIN = 120;
  EXIST_DRAW = 121;                 //领料单(部门)
  EXIST_RETURN = 122;               //退料单(部门)
  EXIST_LOSING = 123;               //报损单
  EXIST_INCREASE = 124;             //报溢单
  EXIST_PRESENT = 125;              //赠送单
  EXIST_GAIN = 126;                 //获赠单
  EXIST_ENTER_DEPOT = 127;          //产品进仓单
  EXIST_CHECK_LIST = 128;           //库存盘点单
  EXIST_DEPT_CHECKLIST = 129;       //部门库存盘点单  //lzm add 2025-07-09 20:53:44
  EXIST_CHANGE_PRICE = 130;         //存货调价单
  EXIST_EXCHANGE = 131;             //仓库同价调拨单
  EXIST_PRICE_EXCHANGE = 132;       //仓库变价调拨单
  EXIST_ASSEMBLY = 133;             //食品加工(之前:组装拆卸)单
  EXIST_OTHER = 134;                //库存变动单
  EXIST_DEPART_EXCHANGE = 135;      //部门调拨单 lzm add 【2010-04-07 13:47:14】
  EXIST_ASSEMBLY_DRAW = 136;        //加工领料单   //lzm add 【2011-12-22 15:24:53】
  EXIST_ASSEMBLY_RETURN = 137;      //加工退料单  //lzm add 【2011-12-22 15:24:53】
  EXIST_ASSEMBLY_ENTER = 138;       //加工品进仓单  //lzm add 【2011-12-22 15:24:53】
  EXIST_ASSEMBLY_PLAN = 139;        //加工计划单  //lzm add 【2012-01-01 18:31:36】
  EXIST_EDIT_END = 140;

  //钱流单据 {141-145}
  MONEY_EDIT_BEGIN = 141;
  MONEY_EXPENSES = 142;             //其它费用单
  MONEY_INCOME = 143;               //其它收入单
  MONEY_DEPOSIT = 144;              //银行存取款
  MONEY_EDIT_END = 145;

  //进货单查询{150-160}
  STOCK_ORDER_BILL = 151;           //进货订单查询
  STOCK_FORMAL_BILL = 152;          //进货单查询
  STOCK_MONEY_BILL = 153;           //进货付款单查询
  STOCK_BACK_BILL = 154;            //进货退货单查询
  STOCK_INDEPT_BILL = 155;          //部门直拨单查询
  STOCK_INDEPTBACK_BILL = 156;      //部门直拨退货单查询
  STOCK_QUOTE_BILL = 157;           //报价单查询     //lzm add 【2011-11-25 14:45:46】
  STOCK_PURCHASE_BILL = 158;        //采购单查询     //lzm add 【2011-11-25 14:45:46】
  STOCK_PURCHASE_PLAN_BILL = 159;   //采购计划单查询 //lzm add 【2012-01-02 13:15:05】
  ALL_STOCK_BILL = 160;             //所有进货单查询 //lzm modify ALL_STOCK_BILL = 155    

  //销售单查询{160-170}
  SALE_ORDER_BILL = 161;            //销售订单查询
  SALE_FORMAL_BILL = 162;           //销售单查询
  SALE_MONEY_BILL = 163;            //销售收款单查询
  SALE_READY_BILL = 164;            //现款销售单查询
  SALE_BACK_BILL = 165;             //销售退货单查询
  SALE_POS_BILL = 166;              //零售单(POS)查询

  SALE_SHOP_FORMAL_BILL = 167;      //门店出仓单查询
  SALE_SHOP_BACK_BILL = 168;        //门店出仓退货单查询
  ALL_SALE_BILL = 169;              //所有销售单查询
  ALL_SALE_SHOP_BILL = 170;         //所有门店出库单查询

  //库存单据查询
  EXIST_DRAW_BILL = 171;            //部门领料单查询
  EXIST_RETURN_BILL = 172;          //部门退料单查询
  EXIST_LOSING_BILL = 173;          //报损单查询
  EXIST_INCREASE_BILL = 174;        //报溢单查询
  EXIST_PRESENT_BILL = 175;         //赠送单查询
  EXIST_GAIN_BILL = 176;            //获赠单查询
  EXIST_ENTER_DEPOT_BILL = 177;     //产品进仓单查询
  EXIST_CHECK_LIST_BILL = 178;      //库存盘点查询
  EXIST_DEPT_CHECKLIST_BILL = 179;  //库存盘点查询  //lzm add 2025-07-09 20:55:36
  EXIST_CHANGE_PRICE_BILL = 180;    //存货调价单查询
  EXIST_EXCHANGE_BILL = 181;        //仓库调拨查询
  EXIST_PRICE_EXCHANGE_BILL = 182;  //仓库变价调拨查询
  EXIST_ASSEMBLY_BILL = 183;        //食品加工单查询
  EXIST_OTHER_BILL = 184;           //库存变动单查询
  EXIST_DEPART_EXCHANGE_BILL = 185; //部门调拨单查询 //lzm add 【2010-04-07 14:19:50】
  EXIST_ASSEMBLY_DRAW_BILL = 186;   //加工领料单查询  //lzm add 【2011-12-22 15:24:53】
  EXIST_ASSEMBLY_RETURN_BILL = 187; //加工退料单查询  //lzm add 【2011-12-22 15:24:53】
  EXIST_ASSEMBLY_ENTER_BILL = 188;  //加工品进仓单查询  //lzm add 【2011-12-22 15:24:53】
  EXIST_ASSEMBLY_PLAN_BILL = 189;   //加工计划单查询  //lzm add 【2012-01-02 20:44:18】
  ALL_EXIST_BILL = 190;             //lzm modify 【2010-04-07 14:19:24】  ALL_EXIST_BILL = 184;
  
  //钱流单据查询
  MONEY_EXPENSES_BILL = 196;  //old:185    //其它费用单查询
  MONEY_INCOME_BILL = 197;    //old:186    //其它收入单查询
  MONEY_DEPOSIT_BILL = 198;   //old:187    //银行存款单查询
  ALL_MONEY_BILL = 199;       //old:188    //所有钱流单查询

  //配送单据
  //前提: 每个原材料都需要定义对应的"配送部门"
  //
  //  1-> 门店录入"配送申请单"(可以根据前台销售的万元用量录入 或 选择之前的配送单)
  //  2-> 总部分别根据"配送部门"录入对应的"配送计划单"(可以根据门店的"配送申请单"录入)【注:配送计划单永远是草稿状态。同时生成billindex的linknum用关联单据统计成本】
  //  3-> 过账"配送计划单"时根据 "用户组" 和 "采购员" 自动拆分成对应的"配送请购单"(即:相同的"用户组"和"采购员"的原材料放在一张"配送请购单")
  //      注："配送请购单"的 应扣库存 和 需采购量 根据现在的库存自动调整
  //  4-> 配送员根据"配送请购单"出去采购
  //  5-> 总部录入进货单(可以根据"配送请购合并单"录入) 【注:"配送请购合并单"是: 根据"采购员"合并,每行一个品种。"配送请购单"的需采购量>0时，"配送请购合并单"才会有数据】
  //
  //  6-> 总部录入配送单(可以根据"配送计划明细单"录入)
  //  7-> 总部调出"配送单"进行发货确认
  //  8-> 货送到门店后门店人员或总部人员调出"配送单"进行实收数量确认【注:确认实收数量后 总仓扣库存 门店仓加库存】
  //
  DELIVERY_EDIT_BEGIN = 210;
  DELIVERY_ORDER_EDIT = 211;   //配送申请单配送
  DELIVERY_FORMAL_EDIT = 212;  //配送单
  DELIVERY_BACK_EDIT = 213;    //配送退货单
  DELIVERY_PLAN_EDIT = 214;    //配送计划单 //lzm add 【2012-09-25 14:34:37】  //配送计划单永远是草稿状态【2013-04-18 15:26:01】
  DELIVERY_BUY_EDIT = 215;     //配送请购单 //lzm add 【2013-01-02 00:28:09】
  DELIVERY_EDIT_END = 220;

  //配送单查询
  DELIVERY_BILL_BEGIN = 220;   
  DELIVERY_ORDER_BILL = 221;   //配送申请单查询
  DELIVERY_FORMAL_BILL = 222;  //配送单查询
  DELIVERY_BACK_BILL = 223;    //配送退货单查询
  DELIVERY_PLAN_BILL = 224;    //配送计划单查询 //lzm add 【2012-09-25 14:35:25】
  DELIVERY_BUY_BILL = 225;     //配送采购单查询 //lzm add 【2013-01-02 00:39:41】
  ALL_DELIVERY_BILL = 226;

  //lzm add 【2010-03-27 12:07:39】
  ALL_ALL_BILL = 300;         //需要查询所有单据

  //各种查询统计
  WARE_STOCK_QUERY = 301;             //商品库存统计表
  WARE_STOCK_DISTRIBUTE = 302;        //商品库存分仓统计表
  WARE_STOCK_PRICE_EDIT = 303;        //商品物价管理
  WARE_STOCK_EDIT = 304;              //期初库存修改
  WARE_FORSALES_QUERY = 305;          //商品销售统计表
  WARE_STOCK_CHECK_EDIT = 306;        //商品库存盘点表 lzm add 【2009-09-07 16时】
  WARE_STOCK_DEPT_CHECKEDIT = 307;    //商品部门库存盘点表 lzm add 2025-07-09 23:16:29
  //WARE_STOCK_QUERY_DETAIL = 308;    //商品库存统计明细表 lzm add 【2010-03-26 18:32:36】
  //------------------------------------
  WARE_STOCK_ORDER_COLLECT = 311; //商品采购订单汇总表
  EMPLOYE_STOCK_ORDER_COLLECT = 312; //业务员采购订单汇总表
  CLIENT_STOCK_ORDER_COLLECT = 313; //供应商供货订单汇总表
  //------------------------------------
  WARE_SALE_ORDER_COLLECT = 314; //商品销售订单汇总表
  EMPLOYE_SALE_ORDER_COLLECT = 315; //业务员销售订单汇总表
  CLIENT_SALE_ORDER_COLLECT = 316; //客户销售订单汇总表
  //------------------------------------
  EMPLOYE_STOCK_COLLECT = 321; //业务员采购汇总表
  WARE_STOCK_COLLECT = 322; //商品采购汇总表
  PROVIDE_STOCK_COLLECT = 323; //供应商供货汇总表
  EMPLOYE_STOCK_DETAILED = 324; //业务员采购明细表
  WARE_STOCK_DETAILED = 325; //商品采购明细表
  PROVIDE_STOCK_DETAILED = 326; //供应商供货明细表
  //------------------------------------
  WARE_SALE_COLLECT = 331; //商品销售汇总表
  EMPLOYE_SALE_COLLECT = 332; //业务员销售汇总表
  CLIENT_SALE_COLLECT = 333; //客户销售汇总表
  WARE_SALE_DETAILED = 334; //商品销售明细表
  EMPLOYE_SALE_DETAILED = 335; //业务员销售明细表
  CLIENT_SALE_DETAILED = 336; //客户销售明细表
  WARE_SALE_HAVE_TONUMBER_DETAILED = 337; //商品销售实收不符明细
  
  WARE_IO_COLLECT = 338;  //商品进出情况汇总表(***停用***)

  //------------------------------------
  WARE_SALE_PROFIT = 341; //商品销售利润表
  EMPLOYE_SALE_PROFIT = 342; //业务员销售利润表
  CLIENT_SALE_PROFIT = 343; //客户销售利润表
  //-------------------------------------
  CLIENT_RECEIPT_QUERY = 345; //客户应收查询
  PROVIDE_PAYABLE_QUERY = 346; //供应商应付查询
  CLIENT_RECEIPT_DETAILED = 347; //应收款明细
  PROVIDE_PAYABLE_DETAILED = 348; //应付款明细
  //-------------------------------------
  QUERY_FIXED_BILL = 351; //固定资产清单
  QUERY_FIXED_DEPRECIATE = 352; //固定资产折旧表
  QUERY_FIXED_PILE_DEPRECIATE = 353; //固定资产累计折旧余额表
  QUERY_FIXED_WORK = 354; //固定资产工作量查询
  //-------------------------------------
  QUERY_WAGE_LEARNING = 355; //员工结构分析
  QUERY_WAGE_PRINT_BAR = 356; //打印工资条
  QUERY_WAGE_PRINT_TAB = 357; //打印工资发放表
  QUERY_WAGE_PRINT_SUM = 358; //打印工资汇总表
  //-------------------------------------
  //权限控制用
  CHANGE_PASSWORD = 360; //修改密码
  OPERATE_LOG = 361; //操作日志
  ACCOUNT_INFO = 362; //账套选项
  SET_START_ACCOUNT = 363; //启用账套
  USER_LIMIT_FORM = 364; //权限控制
  SYSTEM_RESET = 365; //系统重建
  ACCOUNT_START = 367; //启用账套
  //-------------------------------------
  //月利润报表
  MONTH_PROFIT = 370; //月利润报表
  SELFDEFINE_SQL = 371; // 自定义报表
  //-------------------------------------

  //lzm add 【2009-09-27 02时】
  WARE_INOUT_REPORT = 380;      //原材料进出情况报表
//  WARE_DEPARTMENT_REPORT = 381; //部门领料单报表(没做)
//  WARE_INDEPT_REPORT = 382;     //直拨单报表(没做)
//  WARE_EXCHANGE_REPORT = 383;   //调拨报表(没做)

  WARE_INDEPT_COLLECT = 384;    //直拨单汇总
  WARE_INDEPT_DETAIL = 385;     //直拨单明细
  WARE_DRAW_COLLECT = 386;      //部门领料单汇总
  WARE_DRAW_DETAIL = 387;       //部门领料单明细
  WARE_DEPART_EXCHANGE_COLLECT = 388;  //部门调拨单汇总  //lzm add 【2010-04-14 11:35:21】
  WARE_DEPART_EXCHANGE_DETAIL = 389;   //部门调拨单明细  //lzm add 【2010-04-14 11:35:21】
  WARE_USE_COLLECT = 390;              //商品消耗汇总表 lzm add 【2009-09-16 19时】

  DELIVERY_STOCK_DETAILED = 400;    //配送明细表 lzm add 【2011-12-15 09:01:25】
  DELIVERY_STOCK_COLLECT = 401;     //配送汇总表 lzm add 【2011-12-15 09:01:25】
  DELIVERY_DAYMONEY_COLLECT = 402;  //配送金额日汇总表 lzm add 【2011-12-15 09:01:25】

  EXIST_ASSEMBLY_COLLECT = 403;     //食品加工汇总表 lzm add 【2011-12-23 23:56:38】
  WARE_TROUTE_DETAIL = 404;         //行车线路配送明细表 lzm add 【2011-12-25 21:55:45】
  DELIVERY_FORMAL_COLLECT = 405;    //配送单利润汇总表 lzm add 【2011-12-30 11:22:32】
  DELIVERY_FORMAL_SPLIT = 406;      //配送分货单 lzm add 【2012-02-17 15:11:35】
  DELIVERY_CLIENT_PRICE = 407;      //客户商品配送价格单(可以修改客户价) lzm add 【2012-02-17 15:11:35】
  STOCK_PURCHASE_PLAN_DETAILED = 408; //采购计划单明细表 lzm add 【2012-08-30 14:22:14】
  EXIST_LOSING_DETAILED = 409;      //报损单明细表 lzm add 【2012-09-01 01:16:21】
  DELIVERY_PLAN_SPLIT = 410;        //配送计划分货单 lzm add 【2012-09-25 14:42:47】
  DELIVERY_BUY_COMBINED = 411;      //配送请购合并单 lzm add 【2013-03-29 01:28:38】
  DELIVERY_PLAN_EDIT_DETAIL = 412;  //配送计划单明细 lzm add 【2013-04-20 09:01:35】
  DELIVERY_FORMAL_ALERT = 413;      //配送进货警报表 lzm add 【2013-05-02 00:49:09】
  DELIVERY_CLIENT_LIST = 414;       //商品配送客户一览表 lzm add 【2013-05-11 00:40:03】
  DELIVERY_BUY_PLAN_DETAIL = 415;   //配送请购品种对应的配送计划单明细 lzm add 【2013-06-19 17:25:08】
  //-------------------------------------

  //记账凭证
  ACCOUNT_VOUCHER_EDIT = 1000; //lzm modify 【2010-04-07 14:25:02】 ACCOUNT_VOUCHER_EDIT = 190;

  //记账凭证查询(1100-1120)
  ACCOUNT_VOUCHER_BILL_BEGIN = 1100; //old:195
  ACCOUNT_VOUCHER_QUERY = 1101;      //old:196
  ALL_ACCOUNT_VOUCHER_BILL = 1120;   //old:200
  //---------------------------------------

  //单据配置
  BILL_ALL_SETUP = 2000; //old:200
  //----------------------------------------

  
  //所属类型,用于UpdateStock   lzm add 【2009-09-20 00时】
  cInOutType_PurIn = 1;      //购进
  cInOutType_PurBck = 2;     //购退
  cInOutType_UseOut = 3;     //领用
  cInOutType_UseBck = 4;     //领退
  cInOutType_SalOut = 5;     //销售
  cInOutType_SalBck = 6;     //销退
  cInOutType_Check = 7;      //盘点
  cInOutType_Balance = 8;    //损益
  cInOutType_TurIn = 9;      //转入
  cInOutType_TurOut = 10;    //转出
  cInOutType_OthIn = 11;     //其它入
  cInOutType_OthOut = 12;    //其它出
  cInOutType_BomOut = 13;    //原材料卡消耗  //lzm add 【2010-04-19 01时】
*/