CREATE TABLE CHECKS
(
  CHECKID       INTEGER NOT NULL,
  EMPID INTEGER,
  COVERS        INTEGER,
  MODEID        INTEGER,
  ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/
  REFERENCE     VARCHAR(250),      /*外送单的相关信息 如果是ICCARD充值则记录该ICCARD的信息"ICCARD:(8762519301)0000->0000" 如果MODEID=盘点单，记录盘点的批号 或 用于总部的数据整理：'S1'=按用餐方式合计整天的营业数据到一张帐单*/
  SEVCHGAMT     NUMERIC(15, 3),    /* 自动的服务费(即品种服务费合计)＝SUBTOTAL*PERCENT*/
  SUBTOTAL      NUMERIC(15, 3),    /* 合计＝CHECKDETAIL的AAMOUNTS的和*/
  FTOTAL        NUMERIC(15, 3),    /* 应付金额＝SUBTOTAL-DISCOUNT(CHECK+ITEM)+SERVICECHARGE(自动+附加)+税*/
  STIME TIMESTAMP,                 /*开单时间*/
  ETIME TIMESTAMP,                 /*结帐时间 印整单和收银时 记录该时间*/
  SERVICECHGAPPEND      NUMERIC(15, 3),    /*附加的服务费＝SUBTOTAL*PERCENT (即:单个品种收服务费后 可以再对 品种的合计SUBTOTAL收服务费)*/
  CHECKTOTAL    NUMERIC(15, 3), /*已付款金额*/
  TEXTAPPEND    TEXT,           /*扩展信息1(合单分单的信息和折扣信息等等..)， 当以PRINTTITLE2开头时作为厨房单的抬头变量[16]打印 lzm modify varchar(250)->text 2013-02-27*/
  CHECKCLOSED   INTEGER,        /*帐单是否是已结帐单 0 :没结 1 :已结 2 :暂结单(挂单)【用于"已结单"和"没结单"里面隐藏该账单】 3 :【预留-没实现】预售单(不扣库存)【用于"已结单"和"没结单"里面隐藏该账单】*/
  ADJUSTAMOUNT  NUMERIC(15, 3), /*与上单的差额*/
  SPID  INTEGER,                /* 用作记录    服务段:1~48*/
  DISCOUNT      NUMERIC(15, 3), /* 附加的账单折扣=SUBTOTAL*PERCENT (即:单个品种打折后 可以再对 品种的合计SUBTOTAL打折)*/
  INUSE VARCHAR(1) DEFAULT 'F', /*T:正在使用,F:没有使用*/
  LOCKTIME      TIMESTAMP,      /*帐单开始锁定的时间*/
  CASHIERID     INTEGER,        /*收银员编号*/
  ISCARRIEDOVER INTEGER,        /*首次付款方式（记录付款方式的编号，用于“根据付款方式出报表”）*/
  ISADDORSPLIT  INTEGER,        /*lzm 2011-10-18 改为"是否咨客开台 100=咨客开台 其它值=非咨客开台"    之前:不使用*/
  RESERVE1      VARCHAR(40),    /*出单次数*/
  RESERVE2      INTEGER DEFAULT 0,    /*0=有效单据，1=无效单据【ADD OR SPLIT(合单,分单前或作废的单据,即:该单据为作废单不能参与计算或运作,报表也不包含该帐单)】 2=作废*/
  RESERVE3      TIMESTAMP,      /*保存销售数据的日期,如   19990130  ,六位的字符串*/
  RESERVE01     VARCHAR(40),    /*税1合计*/
  RESERVE02     VARCHAR(40),    /*磁卡或IC卡时：记录会员卡对应的'EMPID'  不是IDVALUE 微信会员卡时：为空字符串暂时没用【之前：记录扩展信息 //*/
  RESERVE03     VARCHAR(40),    /*折扣【5种VIP卡和第四种打折方式】: "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]"， N表示nil 【状态:全部为0】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE04     VARCHAR(40),    /*折扣【餐后点饮料、原品续杯、非原品续杯】 "/[状态]/[0或1或2]/[%或现金的数目或DISCOUNTID]" N表示nil 【状态: 纪录0或空:不打折，1：餐后点饮料、2：原品续杯、3：非原品续杯】/【 %为0, 现金为1, 折扣编号为2】*/
  RESERVE05     VARCHAR(40),    /*假帐 1=新的已结单, 由1更新到2=触发数据库触发器进行假帐处理并变为3, 3=处理完毕, 4=ReOpen的单据. (经过DBToFile程序后,由4更新到3,由1更新到2)  对于EXPORT_CHECKS表:1=新的已结单 2=导出到接口库成功 3=生成冲红单到接口成功*/
  RESERVE11     VARCHAR(40),    /*jaja 记录预定人使用时Table5相应记录的id值*/
  RESERVE12     VARCHAR(40),    /*先保留没有启用【之前：jaja 记录---挂单 PutUpBillClickEvent()已停用 ---  0或null:不是挂单; 1:挂单】*/
  RESERVE13     VARCHAR(40),    /*实收金额*/
  RESERVE14     VARCHAR(40),    /*EMPNAME开单员工名称*/
  RESERVE15     VARCHAR(40),    /*MODENAME用餐方式名称*/
  RESERVE16     VARCHAR(40),    /*CASHIERNAME收银员名称*/
  RESERVE17     VARCHAR(40),    /*ITEMDISCOUNT品种折扣合计*/
  RESERVE18     VARCHAR(40),    /*上传数据到总部: 1=新的已结单, 3=处理完毕, 4=ReOpen的单据 或 需要全部重传, 5=账单不完整不需要上传总部 6=日结时修改了账单日期需要重新上传或作废账单需要重传【旧：0或空=新的已结单没有上传，1=成功【再旧：记录BackUp成功=1】】*/
  RESERVE19     VARCHAR(40),    /*上次上传数据到总部的压缩方法【旧：记录MIS成功=1】: 空=之前没有上传过数据, 0=普通的ZLib, 1=VclZip里面的Zlib, 2=VclZip里面的zip, 3=不压缩, 10=经过MIME64编码  12=经过MIME64编码 和 VclZip里面的zip压缩*/
  RESERVE20     VARCHAR(40),    /*帐单类型(20050805) 营业报表只统计"普通账单"的记录（即：RESERVE20='' or RESERVE20='0' or RESERVE20 is NULL）  0或空=普通帐单 1=IC卡充值帐单 2=换礼品扣除会员券或积分(在功能 MinusCouponClickEvent 里设置)帐单 3=全VOID单 4=餐券入店记录-没做 5=从钱箱提取现金的帐单 6=收银交班帐单 7=客户记账后的还款帐单*/
  Y     INTEGER DEFAULT 2001 NOT NULL,
  M     INTEGER DEFAULT 1 NOT NULL,
  D     INTEGER DEFAULT 1 NOT NULL,
  PCID  VARCHAR(40) DEFAULT 'A' NOT NULL,
  BUYERID       VARCHAR(40),   /*团体消费时的格式为(GROUP:组号), 内容是空时为个人消费, 内容是GUID时为记录消费者编号*/
  RESERVE21     VARCHAR(40),   /*其它价格(卡种用户编号),用于判断:四维品种 和 1=全部会员 A=A会员 B=B会员 C=C会员 D=D会员 E=E会员*/           /*之前用于记录:老年*/
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
  CASHIERSHIFT  INTEGER DEFAULT 0,            /*收银班次，0=无班，对应班次表 SHIFTTIMEPERIOD*/
  MINPRICE      NUMERIC(15, 3),               /* ***会员当前账单得到的积分【之前是用于记录:"最低消费"】*/
  CHKDISCOUNTLIDU  INTEGER,                   /*账单折扣凹度 1=来自折扣表格(DISCOUNT),2=OPEN金额,3=OPEN百分比 用于计算CHECKDISCOUNT*/
  CHKSEVCHGAMTLIDU INTEGER,                   /*自动服务费凹度 1=来自服务费表格(SERCHARGE[好像停用了2025-09-23 03:00:41]),2=OPEN金额,3=OPEN百分比 用于计算SEVCHGAMT*/
  CHKSERVICECHGAPPENDLIDU INTEGER,            /*附加服务费凹度 1=来自服务费表格(SERCHARGE[好像停用了2025-09-23 03:00:45]),2=OPEN金额,3=OPEN百分比 用于计算SERVICECHGAPPEND*/
  CHKDISCOUNTORG   NUMERIC(15, 3),            /*账单折扣来源 当CHKDISCOUNTLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  CHKSEVCHGAMTORG  NUMERIC(15, 3),            /*自动服务费来源 当CHKSEVCHGAMTLIDU =1时:记录服务费编号,=2时:记录金额,=3时:记录百分比*/
  CHKSERVICECHGAPPENDORG  NUMERIC(15, 3),     /*附加服务费来源 当CHKSERVICECHGAPPENDLIDU =1时:记录折扣编号,=2时:记录金额,=3时:记录百分比*/
  SUBTABLENAME  VARCHAR(40) DEFAULT '',       /*用于记录拆台后的子台号名称*/
  MINPRICE_TAG  VARCHAR(20),                  /* ***原始单号*/
  THETABLE_TFX  VARCHAR(20),                  /* 并台的台号ID,用逗号分隔 (之前用于：房价TFX的标志  T:F:X: 是否"不打折","免服务费","不收税")*/
  TABLEDISCOUNT NUMERIC(15, 3),               /* ***参与积分的消费金额*/
  AMOUNTCHARGE  NUMERIC(15, 3),               /*帐单合计金额进位后的差额*/
  PDASTGUID VARCHAR(100),                     /*用于记录每次PDA通讯的GUID,判断上次已入单成功 当 "扣减积分"享会员价时: 用于记录相关账单的hqbuillguid*/
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
  ORDERTYPE     INTEGER,         /*报表没有对该域进行筛选  提示：在预订窗口确认后移到"backup_"开头的表内并通过CHECKGUID与运行库关联(backup_checks的pcid: 1=历史单 0=预订单) 0 :普通预订（用于backup_checks而且pcid=0） 1 :婚宴预订（用于backup_checks而且pcid=0） 2 :寿宴预订（用于backup_checks而且pcid=0）  3 :其他 5 :钱箱提现*/
  ORDERMENNEY   NUMERIC(15, 3),  /*定金,预付款*/
  CHECKGUID     VARCHAR(100),    /*GUID - 用于预订（backup_checks通过CHECKGUID与checks关联）*/
  CHGTOBILLCOUNT    INTEGER,     /*根据预定生成账单的次数*/
  MODIFYCOUNT     INTEGER,       /*根据预定修改的次数，  -- 会被撞餐用于临时记录循环的次数（次数过大强制退出撞餐算法），撞餐结束时恢复该值*/

  /**/
  PRINTDOCBILLNUM VARCHAR(100),       /*对应的打印帐单编号*/
  VIPPOINTSBEF NUMERIC(15, 3),        /*会员之前剩余积分*/
  VIPPOINTSUSE NUMERIC(15, 3),        /*会员本次使用积分*/
  VIPCARDDATE  VARCHAR(20),           /*有效日期 格式YYYYMMDD或空*/

  KTIME        TIMESTAMP,             /*入单时间,用于厨房划单系统的排序*/
  PAYMENTTIME  TIMESTAMP,             /*埋单时间*/

  CASHIERSHIFTNUM  VARCHAR(20),       /*收银班次确认批次 例如:BC20100420*/
  DISCOUNT_MATCH_PATH real[][],       /*用于撞餐和ABC的处理保存临时结果*/
  DISCOUNT_MATCH_AMOUNT NUMERIC(12, 2),         /*用于撞餐和ABC的处理保存临时结果*/
  BILLASSIGNTO  VARCHAR(40),          /*账单折扣负责人姓名,用于在收银单打印"责任人"(用于折扣的授权 "沙面玫瑰园")*/
  BILLDISCOUNTEMP  VARCHAR(20),       /*账单附加折扣的员工名称*/
  ITEMDISCOUNTEMP  VARCHAR(20),       /*人手点击全单项目折扣的员工名称(如果不为空代表不需要重新计算折扣)*/
  BILLDISCOUNTREASON   VARCHAR(40),   /*账单附加折扣的名称说明*/
  ITEMDISCOUNTNAME VARCHAR(40),       /*人手点击全单项目折扣名称，用于判断是否已"清除折扣"、是否"需要计算营销活动"。是否"重新计算营销活动"*/

  /*以下2个是用于预订台用的*/
  ORDEREXT1 text,             /*当ordertype=0,1,2时：{"partysize": 1, "TPI": {}} --TPI是第三方接口的英文简写*/
  ORDERDEMO text,             /*预定备注*/

  PT_TOTAL NUMERIC(12, 2),            /*用于折扣优惠 simon 2010-09-06*/
  PT_PATH REAL[][],                   /*用于折扣优惠 simon 2010-09-06*/

  INVOICENUM VARCHAR(200),                         /*发票号码,多个时用","分隔*/
  INVOICECOUNT   INTEGER DEFAULT 0,                /*发票张数*/
  INVOIDEAMOUNT  NUMERIC(15,3) DEFAULT 0,          /*发票金额*/

  WEBOFDIS     VARCHAR(10),           /*来自web的中奖券折扣 10%=九折*/
  WEBBILLS     INTEGER DEFAULT 0,     /*已送优惠券数量 空或0=没有送 >1=送了多少张优惠券*/

  ITEMDISCOUNT_TYPE   INTEGER DEFAULT 0,           /*全单品种折扣的方法 0=不允许打折的品种不能打折 1=不允许打折的品种也需要打折*/

  PAYMENTNAME  VARCHAR(40),           /*埋单的员工名称*/

  KICKBACKMANE  VARCHAR(40),          /*提成人名称*/
  VIPPOINTSTOTAL NUMERIC(15,3) DEFAULT 0,          /*会员累计总积分（目前只对磁卡生效）*/
  VIPOTHERS     VARCHAR(100),          /*记录微信会员的明细信息，用逗号分隔*/
  ABUYERNAME   VARCHAR(50),            /*会员名称*/

  CHANGETBLINFO  VARCHAR(40),          /*记录转台信息,例如:K3->F3->V3*/
  HELPBOOKNAME   VARCHAR(40),          /*帮订人(帮忙订台人)姓名,用于酒吧*/
  WEBBOOKID INTEGER,                   /*WebBook账单webBills的ID*/
  WEBBOOKUSERINFO  VARCHAR(240),       /*WebBook账单或酒店会员的 用户名,地址,电话 用`分隔*/

  LOCKTABLEINFO  VARCHAR(100),         /*台号锁定信息 用逗号分隔(锁台人,锁台所在的电脑编号)*/
  KICHENCLOSE INTEGER DEFAULT 0,       /*厨房划单已完成 空货0=否 1=是 lzm add 2013-9-16*/
  MINPRICEBALANCE NUMERIC(15,3) DEFAULT 0,       /*最低消费补差*/
  LOGTIME TIMESTAMP,                   /*LOG的时间（用于：同步澳门通的LOG时间到CHECKS的LOG时间）*/
  INTERFACE_MARKET VARCHAR(20),        /*用于 商场接口 lzm add 2015-4-7*/
  SCPAYCOUNTS integer default 0,       /*付款次数 用于支付宝微信付款 lzm add 2015/6/24 星期三*/
  CHKSTATUS integer default 0,         /*先保留没有启用 账单状态 0=点单 1=等待用户付款(已印收银单)*/

  USER_ID INTEGER DEFAULT 0 NOT NULL,                /*集团号*/
  SHOPGUID VARCHAR(200) DEFAULT '' NOT NULL,          /*店的GUID*/

  PKEYJSON_BCLOSETHEDAY TEXT DEFAULT '', /*用于24小时店,修改账单日期时记录日结前主键对应的值 json格式保存 例如 {"USER_ID":"0","SHOPID":"001"}*/
  HQBILLGUID  VARCHAR(100) DEFAULT '',   /*该账单的唯一标识(在hq_UploadBills.py内设置) 用于上传总部*/

  CONFIRMCODE VARCHAR(100) DEFAULT '',   /*校验码(用于微信点餐*/
  CHECKS_CARDCLASSTYPE INTEGER DEFAULT 0,         /*卡的类型 用于微信会员卡*/
--  SCPAYALPQRCODE VARCHAR(240) DEFAULT '',   /*支付宝预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYWXPQRCODE VARCHAR(240) DEFAULT '',   /*微信预支付的code_url lam add 2017-01-14 08:25:32*/
--  SCPAYQRAMOUNTS NUMERIC(15, 3),            /*预付的金额*/

  REOPENED INTEGER DEFAULT 0,               /*是否反结账 0=否 1=是*/
  REOPENCONTENT TEXT DEFAULT NULL,  /*[{"authorized":"授权人","operator":"操作员","optime":"操作时间","startamt":"初始金额","endamt":"结账金额","balance":"差额"}]*/
  REOPEN_BEFORE_FTOTAL NUMERIC(15, 3) DEFAULT 0,      /*反结账初始金额，用于计算 REOPENCONTENT->'balance'*/

  INSERTTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*插入时间*/
  MODIFYTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*修改时间*/
  UPLOADTIME TIMESTAMP without time zone DEFAULT date_trunc('second', NOW()),       /*上传时间*/

  EXTSUMINFO JSON,              --扩展的统计信息 {"promote_amount_balance": 0.00, "tc_amount_balance": 0.00} --lzm add 2019-06-19 01:44:37

  --PRIMARY KEY (PCID, Y, M, D, CHECKID)
  PRIMARY KEY (USER_ID, SHOPID, SHOPGUID, Y, M, D, CHECKID)
);
