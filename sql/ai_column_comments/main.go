package main

/**
# 根据源代码分析，ai_column_comments 工具是一个基于数据库现有结构自动推理并生成列注释的辅助工具。

cd w:\Workspaces\GolandProjects\P2P\ai_column_comments

# 1. 设置连接串 (例如连接到 victorysvr 库)
$env:DATABASE_URL = "host=localhost port=5432 user=sysdba password=masterkey dbname=victorysvr sslmode=disable"

# 2. 运行并输出到 ai_comments.sql
.\ai_column_comments.exe ai_comments.sql

# 3. 查看生成结果 (可选)
Get-Content ai_comments.sql -Head 20
*/

import (
	"bufio"
	"database/sql"
	"fmt"
	"os"
	"regexp"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

// 常见列名到中文含义的映射
var columnNameMap = map[string]string{
	// 标识类
	"id":       "唯一标识ID",
	"uuid":     "唯一标识UUID",
	"guid":     "全局唯一标识符",
	"code":     "编码",
	"usercode": "用户编码",
	"pinyin":   "拼音首字母",
	"barcode":  "条形码",

	// 名称类
	"name":        "名称",
	"name1":       "名称1",
	"name2":       "名称2",
	"name3":       "名称3",
	"title":       "标题",
	"caption":     "标题",
	"label":       "标签",
	"description": "描述",
	"desc":        "描述",

	// 时间类
	"createtime":  "创建时间",
	"create_time": "创建时间",
	"inserttime":  "插入时间",
	"modifytime":  "修改时间",
	"modify_time": "修改时间",
	"updatetime":  "更新时间",
	"update_time": "更新时间",
	"deletetime":  "删除时间",
	"delete_time": "删除时间",
	"stime":       "开始时间",
	"etime":       "结束时间",
	"starttime":   "开始时间",
	"endtime":     "结束时间",
	"date":        "日期",
	"billdate":    "账单日期",
	"intime":      "录入时间",
	"outtime":     "输出时间",
	"uploadtime":  "上传时间",
	"sendtime":    "发送时间",
	"printtime":   "打印时间",
	"locktime":    "锁定时间",

	// 用户相关
	"userid":       "用户ID",
	"user_id":      "用户ID",
	"username":     "用户名",
	"empid":        "员工ID",
	"empname":      "员工名称",
	"employeid":    "员工ID",
	"employename":  "员工名称",
	"cashierid":    "收银员ID",
	"cashiername":  "收银员名称",
	"modifyuser":   "修改人",
	"createuser":   "创建人",
	"operatorid":   "操作员ID",
	"operatorname": "操作员名称",

	// 金额相关
	"price":      "单价",
	"amount":     "金额",
	"amounts":    "金额",
	"total":      "合计",
	"subtotal":   "小计",
	"ftotal":     "应付金额",
	"discount":   "折扣",
	"tax":        "税额",
	"cost":       "成本",
	"constprice": "成本价",
	"profit":     "利润",
	"balance":    "余额",
	"sum":        "总计",

	// 数量相关
	"qty":      "数量",
	"quantity": "数量",
	"counts":   "数量",
	"number":   "数量/编号",
	"count":    "计数",

	// 状态相关
	"status":   "状态",
	"state":    "状态",
	"type":     "类型",
	"mode":     "模式/类型",
	"flag":     "标志",
	"isvalid":  "是否有效",
	"isvoid":   "是否作废",
	"isuse":    "是否使用",
	"inuse":    "是否在用",
	"enabled":  "是否启用",
	"disabled": "是否禁用",
	"deleted":  "是否删除",
	"finish":   "是否完成",
	"closed":   "是否关闭",

	// 排序相关
	"sortorder": "排序顺序",
	"sort":      "排序/分类",
	"order":     "顺序",
	"sequence":  "序列号",
	"lineid":    "行号",
	"rowid":     "行ID",

	// 备注相关
	"memo":     "备注",
	"remark":   "备注",
	"note":     "备注",
	"notes":    "备注",
	"comment":  "注释",
	"comments": "注释",

	// 地址相关
	"address":  "地址",
	"addr":     "地址",
	"city":     "城市",
	"province": "省份",
	"country":  "国家",
	"area":     "地区/产地",
	"region":   "区域",
	"zipcode":  "邮编",
	"postcode": "邮编",

	// 联系方式
	"phone":  "电话",
	"tel":    "电话",
	"mobile": "手机",
	"fax":    "传真",
	"email":  "电子邮箱",
	"qq":     "QQ号",
	"wechat": "微信号",

	// 门店相关
	"shopid":   "门店编号",
	"shopname": "门店名称",
	"shopguid": "门店GUID",

	// 仓库库存
	"depotid":     "仓库ID",
	"depotname":   "仓库名称",
	"warehouseid": "仓库ID",
	"stock":       "库存",
	"stocknum":    "库存数量",

	// 商品品种
	"wareid":       "物料ID",
	"warename":     "物料名称",
	"menuitemid":   "品种ID",
	"menuitemname": "品种名称",
	"miclassid":    "品种类别ID",

	// 单位
	"unit":   "单位",
	"unit2":  "辅助单位",
	"unitid": "单位ID",
	"scale":  "换算比例",

	// 规格型号
	"model":  "型号",
	"spec":   "规格",
	"size":   "尺寸",
	"weight": "重量",
	"color":  "颜色",

	// 图片媒体
	"image":    "图片",
	"photo":    "照片",
	"picture":  "图片",
	"icon":     "图标",
	"url":      "URL地址",
	"path":     "路径",
	"file":     "文件",
	"filename": "文件名",

	// 设置配置
	"setting": "设置",
	"config":  "配置",
	"option":  "选项",
	"param":   "参数",
	"value":   "值",
	"value1":  "值1",
	"value2":  "值2",

	// 关联引用
	"parentid":   "父级ID",
	"parent_id":  "父级ID",
	"treeparent": "树形父节点",
	"checkid":    "账单ID",
	"indexid":    "索引ID",
	"otherid":    "其它关联ID",
	"reference":  "引用/参考",

	// 其它常见
	"ip":       "IP地址",
	"version":  "版本号",
	"level":    "级别",
	"priority": "优先级",
	"percent":  "百分比",
	"rate":     "比率",
	"ratio":    "比例",
	"limit":    "限制",
	"max":      "最大值",
	"min":      "最小值",
	"default":  "默认值",
}

// 列名前缀模式映射
var prefixPatterns = map[string]string{
	"is":      "是否",
	"has":     "是否有",
	"can":     "是否可以",
	"allow":   "是否允许",
	"enable":  "是否启用",
	"disable": "是否禁用",
	"need":    "是否需要",
	"show":    "是否显示",
	"hide":    "是否隐藏",
	"auto":    "自动",
	"default": "默认",
	"max":     "最大",
	"min":     "最小",
	"total":   "合计",
	"sum":     "总计",
	"avg":     "平均",
	"begin":   "期初/开始",
	"end":     "期末/结束",
	"old":     "旧的",
	"new":     "新的",
	"last":    "上次",
	"first":   "首次",
	"pre":     "前一个",
	"next":    "下一个",
}

// 列名后缀模式映射
var suffixPatterns = map[string]string{
	"id":      "ID",
	"name":    "名称",
	"code":    "编码",
	"num":     "编号/数量",
	"number":  "编号/数量",
	"count":   "计数",
	"counts":  "数量",
	"qty":     "数量",
	"time":    "时间",
	"date":    "日期",
	"price":   "价格",
	"amount":  "金额",
	"total":   "合计",
	"sum":     "总计",
	"rate":    "比率",
	"percent": "百分比",
	"status":  "状态",
	"state":   "状态",
	"type":    "类型",
	"mode":    "模式",
	"flag":    "标志",
	"level":   "级别",
	"order":   "顺序",
	"sort":    "排序",
	"memo":    "备注",
	"remark":  "备注",
	"desc":    "描述",
	"info":    "信息",
	"data":    "数据",
	"text":    "文本",
	"content": "内容",
	"url":     "URL地址",
	"path":    "路径",
	"file":    "文件",
	"image":   "图片",
	"photo":   "照片",
	"icon":    "图标",
	"json":    "JSON数据",
	"xml":     "XML数据",
	"html":    "HTML内容",
}

func main() {
	// 连接数据库
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		connStr = "host=localhost port=5432 user=postgres password=postgres dbname=victorypos sslmode=disable"
	}

	outputFile := "add_ai_column_comments.sql"
	if len(os.Args) >= 2 {
		outputFile = os.Args[1]
	}

	if err := generateAIComments(connStr, outputFile); err != nil {
		fmt.Printf("错误: %v\n", err)
		os.Exit(1)
	}
}

func generateAIComments(connStr, outputFile string) error {
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("连接数据库失败: %v", err)
	}
	defer db.Close()

	// 查询没有注释的列
	query := `
		SELECT c.table_name, c.column_name
		FROM information_schema.columns c
		LEFT JOIN (
			SELECT 
				pc.relname as table_name,
				a.attname as column_name,
				col_description(pc.oid, a.attnum) as comment
			FROM pg_class pc
			JOIN pg_attribute a ON a.attrelid = pc.oid
			JOIN pg_namespace n ON n.oid = pc.relnamespace
			WHERE n.nspname = 'public'
				AND a.attnum > 0
				AND NOT a.attisdropped
		) pc ON pc.table_name = c.table_name AND pc.column_name = c.column_name
		WHERE c.table_schema = 'public'
			AND (pc.comment IS NULL OR pc.comment = '')
		ORDER BY c.table_name, c.ordinal_position
	`

	rows, err := db.Query(query)
	if err != nil {
		return fmt.Errorf("查询失败: %v", err)
	}
	defer rows.Close()

	// 生成注释
	outFile, err := os.Create(outputFile)
	if err != nil {
		return fmt.Errorf("创建输出文件失败: %v", err)
	}
	defer outFile.Close()

	writer := bufio.NewWriter(outFile)
	writer.WriteString("-- PostgreSQL 列注释 (AI推理生成)\n")
	writer.WriteString("-- 注释前缀 [AI] 表示由AI根据列名推理生成\n")
	writer.WriteString("-- 生成时间: " + time.Now().Format("2006-01-02 15:04:05") + "\n\n")

	count := 0
	for rows.Next() {
		var tableName, columnName string
		if err := rows.Scan(&tableName, &columnName); err != nil {
			continue
		}

		comment := inferColumnComment(columnName)
		if comment != "" {
			stmt := formatColumnCommentWithAI(tableName, columnName, comment)
			writer.WriteString(stmt + "\n")
			count++
		}
	}

	writer.Flush()
	fmt.Printf("成功生成 %d 条 [AI] 列注释\n", count)
	fmt.Printf("输出文件: %s\n", outputFile)

	return nil
}

// inferColumnComment 根据列名推理注释
func inferColumnComment(columnName string) string {
	lowerName := strings.ToLower(columnName)

	// 直接匹配
	if comment, ok := columnNameMap[lowerName]; ok {
		return comment
	}

	// 处理 reserve 类型的列
	if strings.HasPrefix(lowerName, "reserve") {
		num := strings.TrimPrefix(lowerName, "reserve")
		if num != "" {
			return fmt.Sprintf("保留字段%s", num)
		}
		return "保留字段"
	}

	// 处理 ts_ 前缀 (timestamp)
	if strings.HasPrefix(lowerName, "ts_") {
		rest := strings.TrimPrefix(lowerName, "ts_")
		if subComment := inferColumnComment(rest); subComment != "" {
			return "时间戳_" + subComment
		}
	}

	// 检查前缀模式
	for prefix, meaning := range prefixPatterns {
		if strings.HasPrefix(lowerName, prefix) {
			rest := strings.TrimPrefix(lowerName, prefix)
			rest = strings.TrimPrefix(rest, "_")
			if subComment := inferColumnComment(rest); subComment != "" {
				return meaning + subComment
			}
			// 尝试后缀匹配
			for suffix, suffixMeaning := range suffixPatterns {
				if strings.HasSuffix(lowerName, suffix) {
					middle := strings.TrimSuffix(rest, suffix)
					middle = strings.TrimSuffix(middle, "_")
					if middle == "" {
						return meaning + suffixMeaning
					}
				}
			}
		}
	}

	// 检查后缀模式
	for suffix, meaning := range suffixPatterns {
		if strings.HasSuffix(lowerName, suffix) {
			prefix := strings.TrimSuffix(lowerName, suffix)
			prefix = strings.TrimSuffix(prefix, "_")
			if prefix != "" {
				return prefix + meaning
			}
			return meaning
		}
	}

	// 尝试分词处理 (驼峰或下划线)
	words := splitColumnName(columnName)
	if len(words) > 1 {
		var commentParts []string
		for _, word := range words {
			if subComment := inferColumnComment(word); subComment != "" {
				commentParts = append(commentParts, subComment)
			} else {
				commentParts = append(commentParts, word)
			}
		}
		return strings.Join(commentParts, "_")
	}

	return ""
}

// splitColumnName 分割列名
func splitColumnName(name string) []string {
	// 先按下划线分割
	if strings.Contains(name, "_") {
		return strings.Split(name, "_")
	}

	// 处理驼峰命名
	re := regexp.MustCompile(`[A-Z][^A-Z]*`)
	matches := re.FindAllString(name, -1)
	if len(matches) > 0 {
		return matches
	}

	return []string{name}
}

func formatColumnCommentWithAI(tableName, columnName, comment string) string {
	escapedComment := strings.ReplaceAll("[AI]"+comment, "'", "''''")
	return fmt.Sprintf(`DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = '%s' AND column_name = '%s') THEN EXECUTE 'COMMENT ON COLUMN %s.%s IS ''%s'''; END IF; END $$;`,
		tableName, columnName, tableName, columnName, escapedComment)
}
