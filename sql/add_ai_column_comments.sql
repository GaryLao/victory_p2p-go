-- PostgreSQL 核心表列注释 (AI推理生成)
-- 注释前缀 [AI] 表示由AI根据列名推理生成
-- 建议人工审核后再执行

-- ==========================================
-- aprinters 表 (打印机配置表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'aprinters' AND column_name = 'printerid') THEN EXECUTE 'COMMENT ON COLUMN aprinters.printerid IS ''[AI]打印机ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'aprinters' AND column_name = 'reserve07') THEN EXECUTE 'COMMENT ON COLUMN aprinters.reserve07 IS ''[AI]保留字段07'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'aprinters' AND column_name = 'reserve08') THEN EXECUTE 'COMMENT ON COLUMN aprinters.reserve08 IS ''[AI]保留字段08'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'aprinters' AND column_name = 'totalpagem') THEN EXECUTE 'COMMENT ON COLUMN aprinters.totalpagem IS ''[AI]总页数(打印机累计打印页数)'''; END IF; END $$;

-- ==========================================
-- atables 表 (餐台/台位表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'atables' AND column_name = 'atablesid') THEN EXECUTE 'COMMENT ON COLUMN atables.atablesid IS ''[AI]餐台ID'''; END IF; END $$;

-- ==========================================
-- checkrst 表 (账单付款记录表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'checkid') THEN EXECUTE 'COMMENT ON COLUMN checkrst.checkid IS ''[AI]关联的账单ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'lineid') THEN EXECUTE 'COMMENT ON COLUMN checkrst.lineid IS ''[AI]行号/序号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'y') THEN EXECUTE 'COMMENT ON COLUMN checkrst.y IS ''[AI]年份'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'm') THEN EXECUTE 'COMMENT ON COLUMN checkrst.m IS ''[AI]月份'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'd') THEN EXECUTE 'COMMENT ON COLUMN checkrst.d IS ''[AI]日期'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'pcid') THEN EXECUTE 'COMMENT ON COLUMN checkrst.pcid IS ''[AI]收银机/终端ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'icinfo_consumetype') THEN EXECUTE 'COMMENT ON COLUMN checkrst.icinfo_consumetype IS ''[AI]IC卡消费类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'lqnumber') THEN EXECUTE 'COMMENT ON COLUMN checkrst.lqnumber IS ''[AI]流水号/凭证号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'icinfo_beforebalance') THEN EXECUTE 'COMMENT ON COLUMN checkrst.icinfo_beforebalance IS ''[AI]IC卡消费前余额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'icinfo_menuitemid') THEN EXECUTE 'COMMENT ON COLUMN checkrst.icinfo_menuitemid IS ''[AI]IC卡关联品种ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'icinfo_menuitemname') THEN EXECUTE 'COMMENT ON COLUMN checkrst.icinfo_menuitemname IS ''[AI]IC卡关联品种名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'icinfo_menuitemamounts') THEN EXECUTE 'COMMENT ON COLUMN checkrst.icinfo_menuitemamounts IS ''[AI]IC卡关联品种金额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'hotel_instr') THEN EXECUTE 'COMMENT ON COLUMN checkrst.hotel_instr IS ''[AI]酒店接口返回信息'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'memo1') THEN EXECUTE 'COMMENT ON COLUMN checkrst.memo1 IS ''[AI]备注信息1'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checkrst' AND column_name = 'scpayclass') THEN EXECUTE 'COMMENT ON COLUMN checkrst.scpayclass IS ''[AI]扫码支付类别'''; END IF; END $$;

-- ==========================================
-- checks 表 (账单主表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'checkid') THEN EXECUTE 'COMMENT ON COLUMN checks.checkid IS ''[AI]账单ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'empid') THEN EXECUTE 'COMMENT ON COLUMN checks.empid IS ''[AI]开单员工ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'covers') THEN EXECUTE 'COMMENT ON COLUMN checks.covers IS ''[AI]就餐人数'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'modeid') THEN EXECUTE 'COMMENT ON COLUMN checks.modeid IS ''[AI]用餐方式ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'reference') THEN EXECUTE 'COMMENT ON COLUMN checks.reference IS ''[AI]参考信息/关联单号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'sevchgamt') THEN EXECUTE 'COMMENT ON COLUMN checks.sevchgamt IS ''[AI]服务费金额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'servicechgappend') THEN EXECUTE 'COMMENT ON COLUMN checks.servicechgappend IS ''[AI]附加服务费'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'checktotal') THEN EXECUTE 'COMMENT ON COLUMN checks.checktotal IS ''[AI]账单总金额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'checkclosed') THEN EXECUTE 'COMMENT ON COLUMN checks.checkclosed IS ''[AI]账单是否已结账'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'checks' AND column_name = 'reserve2') THEN EXECUTE 'COMMENT ON COLUMN checks.reserve2 IS ''[AI]保留字段2'''; END IF; END $$;

-- ==========================================
-- chkdetail 表 (账单明细表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'checkid') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.checkid IS ''[AI]关联的账单ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'lineid') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.lineid IS ''[AI]行号/序号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'menuitemid') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.menuitemid IS ''[AI]品种ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'stmarker') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.stmarker IS ''[AI]状态标记'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'amtdiscount') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.amtdiscount IS ''[AI]折扣金额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'aname') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.aname IS ''[AI]品种名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'voidemployee') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.voidemployee IS ''[AI]作废操作员工'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'reserve1') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.reserve1 IS ''[AI]保留字段1'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'reserve2') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.reserve2 IS ''[AI]保留字段2'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'reserve3') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.reserve3 IS ''[AI]保留字段3(时间戳)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chkdetail' AND column_name = 'discountreason') THEN EXECUTE 'COMMENT ON COLUMN chkdetail.discountreason IS ''[AI]折扣原因'''; END IF; END $$;

-- ==========================================
-- miclass 表 (品种类别表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'miclassid') THEN EXECUTE 'COMMENT ON COLUMN miclass.miclassid IS ''[AI]品种类别ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'parentid') THEN EXECUTE 'COMMENT ON COLUMN miclass.parentid IS ''[AI]父类别ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'ts_reserve01') THEN EXECUTE 'COMMENT ON COLUMN miclass.ts_reserve01 IS ''[AI]触摸屏保留字段01'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'ts_reserve02') THEN EXECUTE 'COMMENT ON COLUMN miclass.ts_reserve02 IS ''[AI]触摸屏保留字段02'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'ts_reserve03') THEN EXECUTE 'COMMENT ON COLUMN miclass.ts_reserve03 IS ''[AI]触摸屏保留字段03'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'ts_reserve04') THEN EXECUTE 'COMMENT ON COLUMN miclass.ts_reserve04 IS ''[AI]触摸屏保留字段04'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'ts_reserve05') THEN EXECUTE 'COMMENT ON COLUMN miclass.ts_reserve05 IS ''[AI]触摸屏保留字段05'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'submitschid') THEN EXECUTE 'COMMENT ON COLUMN miclass.submitschid IS ''[AI]提交计划ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'miclass' AND column_name = 'micvisibled') THEN EXECUTE 'COMMENT ON COLUMN miclass.micvisibled IS ''[AI]类别是否可见'''; END IF; END $$;

-- ==========================================
-- midetail 表 (品种明细表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'menuitemid') THEN EXECUTE 'COMMENT ON COLUMN midetail.menuitemid IS ''[AI]品种ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'miclassid') THEN EXECUTE 'COMMENT ON COLUMN midetail.miclassid IS ''[AI]所属类别ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'bcid') THEN EXECUTE 'COMMENT ON COLUMN midetail.bcid IS ''[AI]界面/按钮类别ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'anumber') THEN EXECUTE 'COMMENT ON COLUMN midetail.anumber IS ''[AI]界面/按钮编号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'prepcost') THEN EXECUTE 'COMMENT ON COLUMN midetail.prepcost IS ''[AI]预备成本/制作成本'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'reserve04') THEN EXECUTE 'COMMENT ON COLUMN midetail.reserve04 IS ''[AI]保留字段04'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'ts_tlegend') THEN EXECUTE 'COMMENT ON COLUMN midetail.ts_tlegend IS ''[AI]触摸屏图例/图标'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'ts_tlegend_otherlanguage') THEN EXECUTE 'COMMENT ON COLUMN midetail.ts_tlegend_otherlanguage IS ''[AI]触摸屏图例(其它语言)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'nextmiclassid') THEN EXECUTE 'COMMENT ON COLUMN midetail.nextmiclassid IS ''[AI]关联的下一级类别ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'balancetype') THEN EXECUTE 'COMMENT ON COLUMN midetail.balancetype IS ''[AI]余额类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'abcid') THEN EXECUTE 'COMMENT ON COLUMN midetail.abcid IS ''[AI]ABC分类ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'abc_discount_match_num') THEN EXECUTE 'COMMENT ON COLUMN midetail.abc_discount_match_num IS ''[AI]ABC折扣匹配数量'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'vc_rate') THEN EXECUTE 'COMMENT ON COLUMN midetail.vc_rate IS ''[AI]VIP卡折扣比率'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'xgdj') THEN EXECUTE 'COMMENT ON COLUMN midetail.xgdj IS ''[AI]相关单据/关联价格'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'yj') THEN EXECUTE 'COMMENT ON COLUMN midetail.yj IS ''[AI]原价/佣金'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'midetail' AND column_name = 'syscode') THEN EXECUTE 'COMMENT ON COLUMN midetail.syscode IS ''[AI]系统编码'''; END IF; END $$;

-- ==========================================
-- employees 表 (员工表) 如果存在
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'empid') THEN EXECUTE 'COMMENT ON COLUMN employees.empid IS ''[AI]员工ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'empname') THEN EXECUTE 'COMMENT ON COLUMN employees.empname IS ''[AI]员工姓名'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'empcode') THEN EXECUTE 'COMMENT ON COLUMN employees.empcode IS ''[AI]员工编号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'password') THEN EXECUTE 'COMMENT ON COLUMN employees.password IS ''[AI]登录密码'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'employees' AND column_name = 'accesslevel') THEN EXECUTE 'COMMENT ON COLUMN employees.accesslevel IS ''[AI]权限级别'''; END IF; END $$;

-- ==========================================
-- billindex 表 (账单索引/总表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'id') THEN EXECUTE 'COMMENT ON COLUMN billindex.id IS ''[AI]单据ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'treeparent') THEN EXECUTE 'COMMENT ON COLUMN billindex.treeparent IS ''[AI]树形父节点'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'mode') THEN EXECUTE 'COMMENT ON COLUMN billindex.mode IS ''[AI]单据类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'number') THEN EXECUTE 'COMMENT ON COLUMN billindex.number IS ''[AI]单据数量'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'usercode') THEN EXECUTE 'COMMENT ON COLUMN billindex.usercode IS ''[AI]单据编号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'name') THEN EXECUTE 'COMMENT ON COLUMN billindex.name IS ''[AI]单据名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'unitid') THEN EXECUTE 'COMMENT ON COLUMN billindex.unitid IS ''[AI]供应商/客户ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'depotid') THEN EXECUTE 'COMMENT ON COLUMN billindex.depotid IS ''[AI]仓库ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'depotid2') THEN EXECUTE 'COMMENT ON COLUMN billindex.depotid2 IS ''[AI]仓库ID2(调拨目标仓库)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'employeid') THEN EXECUTE 'COMMENT ON COLUMN billindex.employeid IS ''[AI]经手人ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'billmanid') THEN EXECUTE 'COMMENT ON COLUMN billindex.billmanid IS ''[AI]制单人ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'wareid') THEN EXECUTE 'COMMENT ON COLUMN billindex.wareid IS ''[AI]物料ID(食品加工用)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'batchno') THEN EXECUTE 'COMMENT ON COLUMN billindex.batchno IS ''[AI]批号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'price') THEN EXECUTE 'COMMENT ON COLUMN billindex.price IS ''[AI]单价'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'total') THEN EXECUTE 'COMMENT ON COLUMN billindex.total IS ''[AI]金额合计'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'moneymode') THEN EXECUTE 'COMMENT ON COLUMN billindex.moneymode IS ''[AI]付款类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'memo') THEN EXECUTE 'COMMENT ON COLUMN billindex.memo IS ''[AI]备注'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'invoice') THEN EXECUTE 'COMMENT ON COLUMN billindex.invoice IS ''[AI]发票类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'invoicenum') THEN EXECUTE 'COMMENT ON COLUMN billindex.invoicenum IS ''[AI]发票号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'finish') THEN EXECUTE 'COMMENT ON COLUMN billindex.finish IS ''[AI]是否已月结'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'isunite') THEN EXECUTE 'COMMENT ON COLUMN billindex.isunite IS ''[AI]是否加工合并/拆卸'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billindex' AND column_name = 'type') THEN EXECUTE 'COMMENT ON COLUMN billindex.type IS ''[AI]单据状态(草稿/过账/红冲等)'''; END IF; END $$;

-- ==========================================
-- billexist 表 (单据明细表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'id') THEN EXECUTE 'COMMENT ON COLUMN billexist.id IS ''[AI]明细ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'indexid') THEN EXECUTE 'COMMENT ON COLUMN billexist.indexid IS ''[AI]关联的单据ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'billdate') THEN EXECUTE 'COMMENT ON COLUMN billexist.billdate IS ''[AI]单据日期'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'mode') THEN EXECUTE 'COMMENT ON COLUMN billexist.mode IS ''[AI]单据类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'billname') THEN EXECUTE 'COMMENT ON COLUMN billexist.billname IS ''[AI]单据名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'warecode') THEN EXECUTE 'COMMENT ON COLUMN billexist.warecode IS ''[AI]物料编码'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'warename') THEN EXECUTE 'COMMENT ON COLUMN billexist.warename IS ''[AI]物料名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'wareunit') THEN EXECUTE 'COMMENT ON COLUMN billexist.wareunit IS ''[AI]物料单位'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'wareid') THEN EXECUTE 'COMMENT ON COLUMN billexist.wareid IS ''[AI]物料ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'price1') THEN EXECUTE 'COMMENT ON COLUMN billexist.price1 IS ''[AI]价格1'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'constprice') THEN EXECUTE 'COMMENT ON COLUMN billexist.constprice IS ''[AI]成本价'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'total') THEN EXECUTE 'COMMENT ON COLUMN billexist.total IS ''[AI]金额小计'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'taxrate') THEN EXECUTE 'COMMENT ON COLUMN billexist.taxrate IS ''[AI]税率'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'taxprice') THEN EXECUTE 'COMMENT ON COLUMN billexist.taxprice IS ''[AI]含税单价'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'taxtotal') THEN EXECUTE 'COMMENT ON COLUMN billexist.taxtotal IS ''[AI]含税金额'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'sum') THEN EXECUTE 'COMMENT ON COLUMN billexist.sum IS ''[AI]总计'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'otherid') THEN EXECUTE 'COMMENT ON COLUMN billexist.otherid IS ''[AI]关联其它ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'memo') THEN EXECUTE 'COMMENT ON COLUMN billexist.memo IS ''[AI]备注'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'finish') THEN EXECUTE 'COMMENT ON COLUMN billexist.finish IS ''[AI]是否完成'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'billexist' AND column_name = 'type') THEN EXECUTE 'COMMENT ON COLUMN billexist.type IS ''[AI]类型'''; END IF; END $$;

-- ==========================================
-- depot 表 (仓库表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'depotid') THEN EXECUTE 'COMMENT ON COLUMN depot.depotid IS ''[AI]仓库ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'depotname') THEN EXECUTE 'COMMENT ON COLUMN depot.depotname IS ''[AI]仓库名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'depotcode') THEN EXECUTE 'COMMENT ON COLUMN depot.depotcode IS ''[AI]仓库编码'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'address') THEN EXECUTE 'COMMENT ON COLUMN depot.address IS ''[AI]仓库地址'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'manager') THEN EXECUTE 'COMMENT ON COLUMN depot.manager IS ''[AI]仓库管理员'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'tel') THEN EXECUTE 'COMMENT ON COLUMN depot.tel IS ''[AI]联系电话'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'depot' AND column_name = 'memo') THEN EXECUTE 'COMMENT ON COLUMN depot.memo IS ''[AI]备注'''; END IF; END $$;

-- ==========================================
-- ware 表 (物料/商品表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'id') THEN EXECUTE 'COMMENT ON COLUMN ware.id IS ''[AI]物料ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'treeparent') THEN EXECUTE 'COMMENT ON COLUMN ware.treeparent IS ''[AI]树形父节点(类别ID)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'name') THEN EXECUTE 'COMMENT ON COLUMN ware.name IS ''[AI]物料名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'usercode') THEN EXECUTE 'COMMENT ON COLUMN ware.usercode IS ''[AI]物料编码'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'pinyin') THEN EXECUTE 'COMMENT ON COLUMN ware.pinyin IS ''[AI]拼音首字母'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'model') THEN EXECUTE 'COMMENT ON COLUMN ware.model IS ''[AI]型号'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'spec') THEN EXECUTE 'COMMENT ON COLUMN ware.spec IS ''[AI]规格'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'area') THEN EXECUTE 'COMMENT ON COLUMN ware.area IS ''[AI]产地'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'unit') THEN EXECUTE 'COMMENT ON COLUMN ware.unit IS ''[AI]计量单位'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'unit2') THEN EXECUTE 'COMMENT ON COLUMN ware.unit2 IS ''[AI]辅助单位'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'scale') THEN EXECUTE 'COMMENT ON COLUMN ware.scale IS ''[AI]单位换算比例'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'barcode') THEN EXECUTE 'COMMENT ON COLUMN ware.barcode IS ''[AI]条形码'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'price') THEN EXECUTE 'COMMENT ON COLUMN ware.price IS ''[AI]销售价'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'constprice') THEN EXECUTE 'COMMENT ON COLUMN ware.constprice IS ''[AI]成本价'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'up_limit') THEN EXECUTE 'COMMENT ON COLUMN ware.up_limit IS ''[AI]库存上限'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'down_limit') THEN EXECUTE 'COMMENT ON COLUMN ware.down_limit IS ''[AI]库存下限'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'memo') THEN EXECUTE 'COMMENT ON COLUMN ware.memo IS ''[AI]备注'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'use') THEN EXECUTE 'COMMENT ON COLUMN ware.use IS ''[AI]是否启用'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'mode') THEN EXECUTE 'COMMENT ON COLUMN ware.mode IS ''[AI]物料类型'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'depotproperty') THEN EXECUTE 'COMMENT ON COLUMN ware.depotproperty IS ''[AI]仓库属性'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'autofillstock') THEN EXECUTE 'COMMENT ON COLUMN ware.autofillstock IS ''[AI]是否自动补货'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'wxyrate') THEN EXECUTE 'COMMENT ON COLUMN ware.wxyrate IS ''[AI]正常损耗率'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'unitother') THEN EXECUTE 'COMMENT ON COLUMN ware.unitother IS ''[AI]其它计量单位'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'deliverysector') THEN EXECUTE 'COMMENT ON COLUMN ware.deliverysector IS ''[AI]配送部门'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'package') THEN EXECUTE 'COMMENT ON COLUMN ware.package IS ''[AI]包装'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'storageconditions') THEN EXECUTE 'COMMENT ON COLUMN ware.storageconditions IS ''[AI]存储条件'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'brand') THEN EXECUTE 'COMMENT ON COLUMN ware.brand IS ''[AI]品牌'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'period') THEN EXECUTE 'COMMENT ON COLUMN ware.period IS ''[AI]保质期'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'gift') THEN EXECUTE 'COMMENT ON COLUMN ware.gift IS ''[AI]是否赠品'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ware' AND column_name = 'sortorder') THEN EXECUTE 'COMMENT ON COLUMN ware.sortorder IS ''[AI]排序顺序'''; END IF; END $$;

-- ==========================================
-- warestock 表 (库存表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'warestock' AND column_name = 'id') THEN EXECUTE 'COMMENT ON COLUMN warestock.id IS ''[AI]库存记录ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'warestock' AND column_name = 'treeparent') THEN EXECUTE 'COMMENT ON COLUMN warestock.treeparent IS ''[AI]树形父节点'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'warestock' AND column_name = 'initial') THEN EXECUTE 'COMMENT ON COLUMN warestock.initial IS ''[AI]是否期初库存'''; END IF; END $$;

-- ==========================================
-- unit 表 (供应商/客户单位表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'id') THEN EXECUTE 'COMMENT ON COLUMN unit.id IS ''[AI]单位ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'treeparent') THEN EXECUTE 'COMMENT ON COLUMN unit.treeparent IS ''[AI]树形父节点(分类)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'name') THEN EXECUTE 'COMMENT ON COLUMN unit.name IS ''[AI]单位名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'usercode') THEN EXECUTE 'COMMENT ON COLUMN unit.usercode IS ''[AI]单位编码'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'address') THEN EXECUTE 'COMMENT ON COLUMN unit.address IS ''[AI]地址'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'contact') THEN EXECUTE 'COMMENT ON COLUMN unit.contact IS ''[AI]联系人'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'tel') THEN EXECUTE 'COMMENT ON COLUMN unit.tel IS ''[AI]电话'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'fax') THEN EXECUTE 'COMMENT ON COLUMN unit.fax IS ''[AI]传真'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'email') THEN EXECUTE 'COMMENT ON COLUMN unit.email IS ''[AI]电子邮箱'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'memo') THEN EXECUTE 'COMMENT ON COLUMN unit.memo IS ''[AI]备注'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'unit' AND column_name = 'mode') THEN EXECUTE 'COMMENT ON COLUMN unit.mode IS ''[AI]单位类型(供应商/客户)'''; END IF; END $$;

-- ==========================================
-- tendermedia 表 (付款方式表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tendermedia' AND column_name = 'tmid') THEN EXECUTE 'COMMENT ON COLUMN tendermedia.tmid IS ''[AI]付款方式ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tendermedia' AND column_name = 'tmname') THEN EXECUTE 'COMMENT ON COLUMN tendermedia.tmname IS ''[AI]付款方式名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tendermedia' AND column_name = 'tmsname') THEN EXECUTE 'COMMENT ON COLUMN tendermedia.tmsname IS ''[AI]付款方式简称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tendermedia' AND column_name = 'tmtype') THEN EXECUTE 'COMMENT ON COLUMN tendermedia.tmtype IS ''[AI]付款方式类型'''; END IF; END $$;

-- ==========================================
-- discount 表 (折扣表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'discount' AND column_name = 'discountid') THEN EXECUTE 'COMMENT ON COLUMN discount.discountid IS ''[AI]折扣ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'discount' AND column_name = 'discountname') THEN EXECUTE 'COMMENT ON COLUMN discount.discountname IS ''[AI]折扣名称'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'discount' AND column_name = 'discountpercent') THEN EXECUTE 'COMMENT ON COLUMN discount.discountpercent IS ''[AI]折扣百分比'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'discount' AND column_name = 'discountamount') THEN EXECUTE 'COMMENT ON COLUMN discount.discountamount IS ''[AI]折扣金额'''; END IF; END $$;

-- ==========================================
-- dinmodes 表 (用餐方式表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dinmodes' AND column_name = 'modeid') THEN EXECUTE 'COMMENT ON COLUMN dinmodes.modeid IS ''[AI]用餐方式ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'dinmodes' AND column_name = 'modename') THEN EXECUTE 'COMMENT ON COLUMN dinmodes.modename IS ''[AI]用餐方式名称(堂食/外卖/自取等)'''; END IF; END $$;

-- ==========================================
-- touchscr 表 (触摸屏配置表)
-- ==========================================
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'touchscr' AND column_name = 'tsid') THEN EXECUTE 'COMMENT ON COLUMN touchscr.tsid IS ''[AI]触摸屏配置ID(主键)'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'touchscr' AND column_name = 'bcid') THEN EXECUTE 'COMMENT ON COLUMN touchscr.bcid IS ''[AI]界面/按钮类别ID'''; END IF; END $$;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'touchscr' AND column_name = 'anumber') THEN EXECUTE 'COMMENT ON COLUMN touchscr.anumber IS ''[AI]按钮编号'''; END IF; END $$;

