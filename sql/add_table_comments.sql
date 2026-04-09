-- PostgreSQL 补充表注释 (AI推理生成)
-- 根据表结构和数据推理生成，注释前缀 [AI] 表示由AI推理生成
-- 用于没有在原始 SQL 文件中定义注释的表

-- 核心业务表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'atables') THEN EXECUTE 'COMMENT ON TABLE atables IS ''餐台/台位信息表，记录门店的台位、座位数、状态等信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'aprinters') THEN EXECUTE 'COMMENT ON TABLE aprinters IS ''打印机配置表，记录逻辑打印机和物理打印机的映射关系'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'acclevel') THEN EXECUTE 'COMMENT ON TABLE acclevel IS ''权限级别表，记录功能访问权限等级'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'abuyer') THEN EXECUTE 'COMMENT ON TABLE abuyer IS ''客户信息表，记录顾客姓名、联系方式、地址等信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'checks') THEN EXECUTE 'COMMENT ON TABLE checks IS ''账单主表，记录订单基本信息，如台号、金额、时间、服务员等'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chkdetail') THEN EXECUTE 'COMMENT ON TABLE chkdetail IS ''账单明细表，记录账单中每个品种的数量、价格、折扣等信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'checkrst') THEN EXECUTE 'COMMENT ON TABLE checkrst IS ''账单付款记录表，记录每笔账单的支付方式和金额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'checkoplog') THEN EXECUTE 'COMMENT ON TABLE checkoplog IS ''账单操作日志表，记录账单的操作历史'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chkdetail_ext') THEN EXECUTE 'COMMENT ON TABLE chkdetail_ext IS ''账单明细扩展表，记录账单明细的扩展信息'''; END IF; END $$;

-- 备份表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_checks') THEN EXECUTE 'COMMENT ON TABLE backup_checks IS ''账单主表备份，用于存储历史账单数据'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_chkdetail') THEN EXECUTE 'COMMENT ON TABLE backup_chkdetail IS ''账单明细表备份，用于存储历史账单明细数据'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_checkrst') THEN EXECUTE 'COMMENT ON TABLE backup_checkrst IS ''账单付款记录备份，用于存储历史付款记录'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_chkdetail_ext') THEN EXECUTE 'COMMENT ON TABLE backup_chkdetail_ext IS ''账单明细扩展表备份'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_checkoplog') THEN EXECUTE 'COMMENT ON TABLE backup_checkoplog IS ''账单操作日志备份'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE backup_iccard_consume_info IS ''IC卡消费记录备份'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_sales_sumery') THEN EXECUTE 'COMMENT ON TABLE backup_sales_sumery IS ''销售汇总备份表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'backup_sales_sumery_other') THEN EXECUTE 'COMMENT ON TABLE backup_sales_sumery_other IS ''其它销售汇总备份表'''; END IF; END $$;

-- 分析表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analyze_checks') THEN EXECUTE 'COMMENT ON TABLE analyze_checks IS ''账单分析表，用于数据分析和报表生成'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analyze_chkdetail') THEN EXECUTE 'COMMENT ON TABLE analyze_chkdetail IS ''账单明细分析表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analyze_checkrst') THEN EXECUTE 'COMMENT ON TABLE analyze_checkrst IS ''付款记录分析表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analyze_chkdetail_ext') THEN EXECUTE 'COMMENT ON TABLE analyze_chkdetail_ext IS ''账单明细扩展分析表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analyze_checkoplog') THEN EXECUTE 'COMMENT ON TABLE analyze_checkoplog IS ''账单操作日志分析表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analyze_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE analyze_iccard_consume_info IS ''IC卡消费记录分析表'''; END IF; END $$;

-- 账户/财务相关表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accountdef') THEN EXECUTE 'COMMENT ON TABLE accountdef IS ''账户定义表，定义财务账户类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accountindex') THEN EXECUTE 'COMMENT ON TABLE accountindex IS ''账户索引表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accounttable') THEN EXECUTE 'COMMENT ON TABLE accounttable IS ''账户数据表，记录账户明细'''; END IF; END $$;

-- 单据相关表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billexist') THEN EXECUTE 'COMMENT ON TABLE billexist IS ''单据存在标记表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billindex') THEN EXECUTE 'COMMENT ON TABLE billindex IS ''单据索引表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billmoney') THEN EXECUTE 'COMMENT ON TABLE billmoney IS ''单据金额表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billnumberdetail') THEN EXECUTE 'COMMENT ON TABLE billnumberdetail IS ''单据编号明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billparams') THEN EXECUTE 'COMMENT ON TABLE billparams IS ''单据参数表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billsale') THEN EXECUTE 'COMMENT ON TABLE billsale IS ''销售单据表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billsetup') THEN EXECUTE 'COMMENT ON TABLE billsetup IS ''单据设置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'billstock') THEN EXECUTE 'COMMENT ON TABLE billstock IS ''库存单据表'''; END IF; END $$;

-- 系统配置表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'baseinfo') THEN EXECUTE 'COMMENT ON TABLE baseinfo IS ''基础信息表，存储系统基础配置'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'base2infobill') THEN EXECUTE 'COMMENT ON TABLE base2infobill IS ''基础信息到单据的映射表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'btnfunc') THEN EXECUTE 'COMMENT ON TABLE btnfunc IS ''按钮功能配置表，定义界面按钮对应的功能'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'chartsetup') THEN EXECUTE 'COMMENT ON TABLE chartsetup IS ''图表设置表，用于报表图表配置'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'colsetup') THEN EXECUTE 'COMMENT ON TABLE colsetup IS ''列设置表，定义界面列的显示配置'''; END IF; END $$;

-- 业务规则表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'buyslgivesl') THEN EXECUTE 'COMMENT ON TABLE buyslgivesl IS ''买赠规则表，定义买多少送多少的促销规则'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cashertimeperiod') THEN EXECUTE 'COMMENT ON TABLE cashertimeperiod IS ''收银班次时间段表'''; END IF; END $$;

-- 日志和历史表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'checkidlog') THEN EXECUTE 'COMMENT ON TABLE checkidlog IS ''账单ID日志表，记录账单编号的使用历史'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'checkwarestock') THEN EXECUTE 'COMMENT ON TABLE checkwarestock IS ''账单库存核对表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'closethemonth') THEN EXECUTE 'COMMENT ON TABLE closethemonth IS ''月结表，记录月度结算状态'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'coaccountinfo') THEN EXECUTE 'COMMENT ON TABLE coaccountinfo IS ''公司账户信息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'beforefix_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE beforefix_iccard_consume_info IS ''IC卡消费记录修复前备份表'''; END IF; END $$;

-- 区域表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'atablesections') THEN EXECUTE 'COMMENT ON TABLE atablesections IS ''餐台区域表，定义餐厅的不同区域'''; END IF; END $$;

-- 数据分析相关表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_accounting_def') THEN EXECUTE 'COMMENT ON TABLE data_accounting_def IS ''会计科目定义表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_analyze') THEN EXECUTE 'COMMENT ON TABLE data_analyze IS ''数据分析表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_analyze_report') THEN EXECUTE 'COMMENT ON TABLE data_analyze_report IS ''分析报表数据'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_analyze_report_title') THEN EXECUTE 'COMMENT ON TABLE data_analyze_report_title IS ''分析报表标题配置'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_bills') THEN EXECUTE 'COMMENT ON TABLE data_bills IS ''单据数据表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_bills_detail') THEN EXECUTE 'COMMENT ON TABLE data_bills_detail IS ''单据明细数据表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_bills_payment') THEN EXECUTE 'COMMENT ON TABLE data_bills_payment IS ''单据付款数据表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'data_vip_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE data_vip_iccard_consume_info IS ''VIP IC卡消费信息数据表'''; END IF; END $$;

-- 配送相关表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'deliverysector') THEN EXECUTE 'COMMENT ON TABLE deliverysector IS ''配送区域表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'depot') THEN EXECUTE 'COMMENT ON TABLE depot IS ''仓库/库房表'''; END IF; END $$;

-- 用餐方式和员工表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'dinmodes') THEN EXECUTE 'COMMENT ON TABLE dinmodes IS ''用餐方式表（堂食、外卖、自取等）'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'empclass') THEN EXECUTE 'COMMENT ON TABLE empclass IS ''员工类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employe') THEN EXECUTE 'COMMENT ON TABLE employe IS ''员工信息表'''; END IF; END $$;

-- 导出表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'export_checks') THEN EXECUTE 'COMMENT ON TABLE export_checks IS ''账单导出表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'export_chkdetail') THEN EXECUTE 'COMMENT ON TABLE export_chkdetail IS ''账单明细导出表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'export_checkrst') THEN EXECUTE 'COMMENT ON TABLE export_checkrst IS ''付款记录导出表'''; END IF; END $$;

-- 固定资产表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fixedassets') THEN EXECUTE 'COMMENT ON TABLE fixedassets IS ''固定资产表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fixedassetsdec') THEN EXECUTE 'COMMENT ON TABLE fixedassetsdec IS ''固定资产减少表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fixedassetsplus') THEN EXECUTE 'COMMENT ON TABLE fixedassetsplus IS ''固定资产增加表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fixeddepreciate') THEN EXECUTE 'COMMENT ON TABLE fixeddepreciate IS ''固定资产折旧表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'fixedwork') THEN EXECUTE 'COMMENT ON TABLE fixedwork IS ''固定资产维修表'''; END IF; END $$;

-- 总部下发表 (hq_issue_*)
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_abuyer') THEN EXECUTE 'COMMENT ON TABLE hq_issue_abuyer IS ''总部下发-客户信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_aprinters') THEN EXECUTE 'COMMENT ON TABLE hq_issue_aprinters IS ''总部下发-打印机配置'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_atables') THEN EXECUTE 'COMMENT ON TABLE hq_issue_atables IS ''总部下发-餐台信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_cashertimeperiod') THEN EXECUTE 'COMMENT ON TABLE hq_issue_cashertimeperiod IS ''总部下发-收银班次时间段'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_data_definition') THEN EXECUTE 'COMMENT ON TABLE hq_issue_data_definition IS ''总部下发-数据定义'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_dinmodes') THEN EXECUTE 'COMMENT ON TABLE hq_issue_dinmodes IS ''总部下发-用餐方式'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_empclass') THEN EXECUTE 'COMMENT ON TABLE hq_issue_empclass IS ''总部下发-员工类别'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_helpbookpeople') THEN EXECUTE 'COMMENT ON TABLE hq_issue_helpbookpeople IS ''总部下发-预订联系人'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_helpbookposition') THEN EXECUTE 'COMMENT ON TABLE hq_issue_helpbookposition IS ''总部下发-预订职位'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_miclass') THEN EXECUTE 'COMMENT ON TABLE hq_issue_miclass IS ''总部下发-品种类别'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_midetail') THEN EXECUTE 'COMMENT ON TABLE hq_issue_midetail IS ''总部下发-品种明细'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_preferencial_treatment_class') THEN EXECUTE 'COMMENT ON TABLE hq_issue_preferencial_treatment_class IS ''总部下发-优惠类别'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_preferencial_treatment_rules') THEN EXECUTE 'COMMENT ON TABLE hq_issue_preferencial_treatment_rules IS ''总部下发-优惠规则'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_shop_cnf') THEN EXECUTE 'COMMENT ON TABLE hq_issue_shop_cnf IS ''总部下发-门店配置'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_table9') THEN EXECUTE 'COMMENT ON TABLE hq_issue_table9 IS ''总部下发-按钮命令配置'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'hq_issue_wpos_hqrd_db_version') THEN EXECUTE 'COMMENT ON TABLE hq_issue_wpos_hqrd_db_version IS ''总部下发-数据库版本'''; END IF; END $$;

-- 厨房绩效
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'kichen_performance') THEN EXECUTE 'COMMENT ON TABLE kichen_performance IS ''厨房绩效表，记录出品效率等数据'''; END IF; END $$;

-- 登录和菜单
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'login') THEN EXECUTE 'COMMENT ON TABLE login IS ''登录记录表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mainmenuclass') THEN EXECUTE 'COMMENT ON TABLE mainmenuclass IS ''主菜单类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'submenuclass') THEN EXECUTE 'COMMENT ON TABLE submenuclass IS ''子菜单类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'menudetail') THEN EXECUTE 'COMMENT ON TABLE menudetail IS ''菜单明细表'''; END IF; END $$;

-- 品种相关表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'miclass') THEN EXECUTE 'COMMENT ON TABLE miclass IS ''品种类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'midetail') THEN EXECUTE 'COMMENT ON TABLE midetail IS ''品种明细表，存储菜品/商品的详细信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'midetail_giveitem') THEN EXECUTE 'COMMENT ON TABLE midetail_giveitem IS ''品种赠送关联表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'vip_menuitem') THEN EXECUTE 'COMMENT ON TABLE vip_menuitem IS ''VIP会员专属品种表'''; END IF; END $$;

-- 消息和日志
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'msgs') THEN EXECUTE 'COMMENT ON TABLE msgs IS ''消息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mylog') THEN EXECUTE 'COMMENT ON TABLE mylog IS ''系统日志表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'operatelog') THEN EXECUTE 'COMMENT ON TABLE operatelog IS ''操作日志表'''; END IF; END $$;

-- 新版数据表 (new_*)
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_abuyer') THEN EXECUTE 'COMMENT ON TABLE new_abuyer IS ''新版客户信息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_aprinters') THEN EXECUTE 'COMMENT ON TABLE new_aprinters IS ''新版打印机配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_atables') THEN EXECUTE 'COMMENT ON TABLE new_atables IS ''新版餐台信息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_cashertimeperiod') THEN EXECUTE 'COMMENT ON TABLE new_cashertimeperiod IS ''新版收银班次时间段表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_data_definition') THEN EXECUTE 'COMMENT ON TABLE new_data_definition IS ''新版数据定义表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_dinmodes') THEN EXECUTE 'COMMENT ON TABLE new_dinmodes IS ''新版用餐方式表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_empclass') THEN EXECUTE 'COMMENT ON TABLE new_empclass IS ''新版员工类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_helpbookpeople') THEN EXECUTE 'COMMENT ON TABLE new_helpbookpeople IS ''新版预订联系人表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_helpbookposition') THEN EXECUTE 'COMMENT ON TABLE new_helpbookposition IS ''新版预订职位表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_miclass') THEN EXECUTE 'COMMENT ON TABLE new_miclass IS ''新版品种类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_midetail') THEN EXECUTE 'COMMENT ON TABLE new_midetail IS ''新版品种明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_preferencial_treatment_class') THEN EXECUTE 'COMMENT ON TABLE new_preferencial_treatment_class IS ''新版优惠类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_preferencial_treatment_rules') THEN EXECUTE 'COMMENT ON TABLE new_preferencial_treatment_rules IS ''新版优惠规则表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_shop_cnf') THEN EXECUTE 'COMMENT ON TABLE new_shop_cnf IS ''新版门店配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_table9') THEN EXECUTE 'COMMENT ON TABLE new_table9 IS ''新版按钮命令配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'new_wpos_hqrd_db_version') THEN EXECUTE 'COMMENT ON TABLE new_wpos_hqrd_db_version IS ''新版数据库版本表'''; END IF; END $$;

-- 订单和支付
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ordercheck') THEN EXECUTE 'COMMENT ON TABLE ordercheck IS ''订单核对表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN EXECUTE 'COMMENT ON TABLE payments IS ''支付记录表'''; END IF; END $$;

-- 打印相关
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'printmodel') THEN EXECUTE 'COMMENT ON TABLE printmodel IS ''打印模板表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'printpool') THEN EXECUTE 'COMMENT ON TABLE printpool IS ''打印队列表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'printtemp') THEN EXECUTE 'COMMENT ON TABLE printtemp IS ''打印临时表'''; END IF; END $$;

-- 报表相关
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reporttemp') THEN EXECUTE 'COMMENT ON TABLE reporttemp IS ''报表临时表'''; END IF; END $$;

-- 销售汇总
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sales_sumery') THEN EXECUTE 'COMMENT ON TABLE sales_sumery IS ''销售汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sales_sumery_other') THEN EXECUTE 'COMMENT ON TABLE sales_sumery_other IS ''其它销售汇总表'''; END IF; END $$;

-- 系统配置
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'saveform') THEN EXECUTE 'COMMENT ON TABLE saveform IS ''表单保存配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'selfdefinesql') THEN EXECUTE 'COMMENT ON TABLE selfdefinesql IS ''自定义SQL表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shop_cnf') THEN EXECUTE 'COMMENT ON TABLE shop_cnf IS ''门店配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sqlexecute') THEN EXECUTE 'COMMENT ON TABLE sqlexecute IS ''SQL执行记录表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sysdef') THEN EXECUTE 'COMMENT ON TABLE sysdef IS ''系统定义表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'systemini') THEN EXECUTE 'COMMENT ON TABLE systemini IS ''系统INI配置表'''; END IF; END $$;

-- 库存相关
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stockmonths') THEN EXECUTE 'COMMENT ON TABLE stockmonths IS ''月度库存表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ware') THEN EXECUTE 'COMMENT ON TABLE ware IS ''物料/商品表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'warebom') THEN EXECUTE 'COMMENT ON TABLE warebom IS ''物料BOM清单表（配方表）'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'warefillstock') THEN EXECUTE 'COMMENT ON TABLE warefillstock IS ''补货表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'warestock') THEN EXECUTE 'COMMENT ON TABLE warestock IS ''库存表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'warestock0') THEN EXECUTE 'COMMENT ON TABLE warestock0 IS ''期初库存表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'warestockforsales') THEN EXECUTE 'COMMENT ON TABLE warestockforsales IS ''销售库存表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wareunitprice') THEN EXECUTE 'COMMENT ON TABLE wareunitprice IS ''物料单价表'''; END IF; END $$;

-- 汇总表 (sum_*)
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_checks') THEN EXECUTE 'COMMENT ON TABLE sum_checks IS ''账单汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_chkdetail') THEN EXECUTE 'COMMENT ON TABLE sum_chkdetail IS ''账单明细汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_checkrst') THEN EXECUTE 'COMMENT ON TABLE sum_checkrst IS ''付款记录汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_chkdetail_ext') THEN EXECUTE 'COMMENT ON TABLE sum_chkdetail_ext IS ''账单明细扩展汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE sum_iccard_consume_info IS ''IC卡消费汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_sales_sumery') THEN EXECUTE 'COMMENT ON TABLE sum_sales_sumery IS ''销售汇总的汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sum_sales_sumery_other') THEN EXECUTE 'COMMENT ON TABLE sum_sales_sumery_other IS ''其它销售汇总的汇总表'''; END IF; END $$;

-- 全量表 (whole_*)
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_checks') THEN EXECUTE 'COMMENT ON TABLE whole_checks IS ''全量账单表，存储所有历史账单'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_chkdetail') THEN EXECUTE 'COMMENT ON TABLE whole_chkdetail IS ''全量账单明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_checkrst') THEN EXECUTE 'COMMENT ON TABLE whole_checkrst IS ''全量付款记录表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_chkdetail_ext') THEN EXECUTE 'COMMENT ON TABLE whole_chkdetail_ext IS ''全量账单明细扩展表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE whole_iccard_consume_info IS ''全量IC卡消费信息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_sales_sumery') THEN EXECUTE 'COMMENT ON TABLE whole_sales_sumery IS ''全量销售汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_sales_sumery_other') THEN EXECUTE 'COMMENT ON TABLE whole_sales_sumery_other IS ''全量其它销售汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_unitmoney') THEN EXECUTE 'COMMENT ON TABLE whole_unitmoney IS ''全量单位金额表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_warestock_distri') THEN EXECUTE 'COMMENT ON TABLE whole_warestock_distri IS ''全量库存分布表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'whole_warestock_dom') THEN EXECUTE 'COMMENT ON TABLE whole_warestock_dom IS ''全量库存日报表'''; END IF; END $$;

-- 年度全量表 (year_whole_*)
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_checks') THEN EXECUTE 'COMMENT ON TABLE year_whole_checks IS ''年度全量账单表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_chkdetail') THEN EXECUTE 'COMMENT ON TABLE year_whole_chkdetail IS ''年度全量账单明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_checkrst') THEN EXECUTE 'COMMENT ON TABLE year_whole_checkrst IS ''年度全量付款记录表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_chkdetail_ext') THEN EXECUTE 'COMMENT ON TABLE year_whole_chkdetail_ext IS ''年度全量账单明细扩展表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_iccard_consume_info') THEN EXECUTE 'COMMENT ON TABLE year_whole_iccard_consume_info IS ''年度全量IC卡消费信息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_sales_sumery') THEN EXECUTE 'COMMENT ON TABLE year_whole_sales_sumery IS ''年度全量销售汇总表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'year_whole_sales_sumery_other') THEN EXECUTE 'COMMENT ON TABLE year_whole_sales_sumery_other IS ''年度全量其它销售汇总表'''; END IF; END $$;

-- Web相关表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_ad') THEN EXECUTE 'COMMENT ON TABLE web_ad IS ''Web广告表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_atables') THEN EXECUTE 'COMMENT ON TABLE web_atables IS ''Web餐台表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_billdetail') THEN EXECUTE 'COMMENT ON TABLE web_billdetail IS ''Web账单明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_bills') THEN EXECUTE 'COMMENT ON TABLE web_bills IS ''Web账单表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_config') THEN EXECUTE 'COMMENT ON TABLE web_config IS ''Web配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_discount') THEN EXECUTE 'COMMENT ON TABLE web_discount IS ''Web折扣表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_message') THEN EXECUTE 'COMMENT ON TABLE web_message IS ''Web消息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_miclass') THEN EXECUTE 'COMMENT ON TABLE web_miclass IS ''Web品种类别表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_midetail') THEN EXECUTE 'COMMENT ON TABLE web_midetail IS ''Web品种明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'web_sysuser') THEN EXECUTE 'COMMENT ON TABLE web_sysuser IS ''Web系统用户表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'webbilldetail') THEN EXECUTE 'COMMENT ON TABLE webbilldetail IS ''微信/Web账单明细表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'webbillpayback') THEN EXECUTE 'COMMENT ON TABLE webbillpayback IS ''微信/Web退款记录表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'webbillpayment') THEN EXECUTE 'COMMENT ON TABLE webbillpayment IS ''微信/Web支付记录表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'webbills') THEN EXECUTE 'COMMENT ON TABLE webbills IS ''微信/Web订单表'''; END IF; END $$;

-- 工资相关
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wageitem') THEN EXECUTE 'COMMENT ON TABLE wageitem IS ''工资项目表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wageorder') THEN EXECUTE 'COMMENT ON TABLE wageorder IS ''工资单表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wagetable') THEN EXECUTE 'COMMENT ON TABLE wagetable IS ''工资表'''; END IF; END $$;

-- 其它表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subject') THEN EXECUTE 'COMMENT ON TABLE subject IS ''科目表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'table9') THEN EXECUTE 'COMMENT ON TABLE table9 IS ''按钮命令配置表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tablearea') THEN EXECUTE 'COMMENT ON TABLE tablearea IS ''餐台区域表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'terminal_info') THEN EXECUTE 'COMMENT ON TABLE terminal_info IS ''终端设备信息表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tp_company_staff') THEN EXECUTE 'COMMENT ON TABLE tp_company_staff IS ''第三方公司员工表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'troute') THEN EXECUTE 'COMMENT ON TABLE troute IS ''配送路线表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'troute_unit') THEN EXECUTE 'COMMENT ON TABLE troute_unit IS ''配送路线单元表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'unit') THEN EXECUTE 'COMMENT ON TABLE unit IS ''单位表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'unitmoney') THEN EXECUTE 'COMMENT ON TABLE unitmoney IS ''单位金额表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'userlimit') THEN EXECUTE 'COMMENT ON TABLE userlimit IS ''用户权限表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'outport_frag') THEN EXECUTE 'COMMENT ON TABLE outport_frag IS ''导出片段表'''; END IF; END $$;

-- PowerBuilder系统表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pbcatcol') THEN EXECUTE 'COMMENT ON TABLE pbcatcol IS ''PowerBuilder系统表-列定义'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pbcatedt') THEN EXECUTE 'COMMENT ON TABLE pbcatedt IS ''PowerBuilder系统表-编辑样式'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pbcatfmt') THEN EXECUTE 'COMMENT ON TABLE pbcatfmt IS ''PowerBuilder系统表-格式定义'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pbcattbl') THEN EXECUTE 'COMMENT ON TABLE pbcattbl IS ''PowerBuilder系统表-表定义'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pbcatvld') THEN EXECUTE 'COMMENT ON TABLE pbcatvld IS ''PowerBuilder系统表-验证规则'''; END IF; END $$;

-- WPOS相关
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wpos_bl600_dish_txt') THEN EXECUTE 'COMMENT ON TABLE wpos_bl600_dish_txt IS ''WPOS BL600打印机菜品文本'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'wpos_bl600_dset_txt') THEN EXECUTE 'COMMENT ON TABLE wpos_bl600_dset_txt IS ''WPOS BL600打印机数据集文本'''; END IF; END $$;

-- 临时表
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'temp1') THEN EXECUTE 'COMMENT ON TABLE temp1 IS ''临时表1'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'temp_warestock_distri') THEN EXECUTE 'COMMENT ON TABLE temp_warestock_distri IS ''库存分布临时表'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'temp_warestock_dom') THEN EXECUTE 'COMMENT ON TABLE temp_warestock_dom IS ''库存日报临时表'''; END IF; END $$;
