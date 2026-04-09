package main

/**
想生成 COMMENT ON 脚本？直接运行不带标记的命令。
想整理 SQL 格式或提取单表？用 -rewrite。
想从数据库倒出带注释的结构？用 -db-export。

# 读取 my_schema.sql 并生成 comments.sql
..\parse_comments\parse_comments.exe my_schema.sql comments.sql

# 导出 checks 表结构和注释
# parse_comments.exe -db-export <表名> <输出SQL文件> [DSN连接串(可选)]
..\parse_comments\parse_comments.exe -db-export checks export_checks.sql "host=localhost port=5432 user=sysdba password=masterkey dbname=victorysvr sslmode=disable"

# 重写 SQL 文件
# parse_comments.exe -rewrite <输入SQL文件> <输出SQL文件> [表名(可选)]
..\parse_comments\parse_comments.exe -rewrite create_victorysvr_posgresql.sql add_comments.sql
*/
import (
	"bufio"
	"database/sql"
	"fmt"
	"os"
	"regexp"
	"strings"

	_ "github.com/lib/pq"
)

// 基础表名 -> 派生表后缀的映射
var baseTables = map[string]string{
	"checks":        "_checks",
	"chkdetail":     "_chkdetail",
	"checkrst":      "_checkrst",
	"chkdetail_ext": "_chkdetail_ext",
	"checkoplog":    "_checkoplog",
}

// 表名 -> 列名 -> 注释 的映射
type TableColumnComments map[string]map[string]string

func main() {
	if len(os.Args) >= 2 {
		if os.Args[1] == "-rewrite" {
			if len(os.Args) < 4 {
				fmt.Println("用法: parse_comments.exe -rewrite <输入SQL文件> <输出SQL文件> [表名(可选)]")
				os.Exit(1)
			}

			tableName := ""
			if len(os.Args) >= 5 {
				tableName = strings.ToLower(os.Args[4])
			}

			if err := rewriteSQL(os.Args[2], os.Args[3], tableName); err != nil {
				fmt.Printf("重写失败: %v\n", err)
				os.Exit(1)
			}
			if tableName != "" {
				fmt.Printf("成功导出表 '%s' 到: %s\n", tableName, os.Args[3])
			} else {
				fmt.Printf("成功重写 SQL 文件: %s\n", os.Args[3])
			}
			return
		}

		if os.Args[1] == "-db-export" {
			if len(os.Args) < 4 {
				fmt.Println("用法: parse_comments.exe -db-export <表名> <输出SQL文件> [DSN(可选)]")
				os.Exit(1)
			}

			tableName := strings.ToLower(os.Args[2])
			outputFile := os.Args[3]
			dsn := ""
			if len(os.Args) >= 5 {
				dsn = os.Args[4]
			}

			if err := exportFromDB(tableName, outputFile, dsn); err != nil {
				fmt.Printf("导出失败: %v\n", err)
				os.Exit(1)
			}
			fmt.Printf("成功从数据库导出表 '%s' 到: %s\n", tableName, outputFile)
			return
		}
	}

	inputFile := "create_victorysvr_posgresql.sql"
	outputFile := "add_comments.sql"

	if len(os.Args) >= 2 {
		inputFile = os.Args[1]
	}
	if len(os.Args) >= 3 {
		outputFile = os.Args[2]
	}

	if err := parseComments(inputFile, outputFile); err != nil {
		fmt.Printf("错误: %v\n", err)
		os.Exit(1)
	}
}

func parseComments(inputFile, outputFile string) error {
	// 第一遍：收集所有表的列注释
	tableComments, tableDescriptions, err := collectAllComments(inputFile)
	if err != nil {
		return err
	}

	// 第二遍：生成 COMMENT 语句，应用继承规则
	comments, err := generateComments(inputFile, tableComments, tableDescriptions)
	if err != nil {
		return err
	}

	// 写入输出文件
	outFile, err := os.Create(outputFile)
	if err != nil {
		return fmt.Errorf("无法创建输出文件: %v", err)
	}
	defer outFile.Close()

	writer := bufio.NewWriter(outFile)
	writer.WriteString("-- PostgreSQL COMMENT 语句\n")
	writer.WriteString("-- 自动生成，用于将表和列的注释添加到数据库元数据\n")
	writer.WriteString(fmt.Sprintf("-- 生成自: %s\n", inputFile))
	writer.WriteString("-- 注意：以 _checks, _chkdetail, _checkrst, _chkdetail_ext 结尾的表使用基础表的注释\n\n")

	for _, comment := range comments {
		writer.WriteString(comment + "\n")
	}
	writer.Flush()

	fmt.Printf("成功生成 %d 条 COMMENT 语句\n", len(comments))
	fmt.Printf("输出文件: %s\n", outputFile)

	return nil
}

// collectAllComments 收集所有表的列注释
func collectAllComments(inputFile string) (TableColumnComments, map[string]string, error) {
	file, err := os.Open(inputFile)
	if err != nil {
		return nil, nil, fmt.Errorf("无法打开文件: %v", err)
	}
	defer file.Close()

	tableComments := make(TableColumnComments)
	tableDescriptions := make(map[string]string) // 表级别的注释

	scanner := bufio.NewScanner(file)
	var currentTable string
	inCreateTable := false

	// Multi-line comment state
	var inBlockComment bool
	var commentBuilder strings.Builder
	var pendingColumn string
	var pendingTable string

	createTableRe := regexp.MustCompile(`(?i)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["']?(\w+)["']?`)
	columnRe := regexp.MustCompile(`^\s*["']?(\w+)["']?\s+`)
	endTableRe := regexp.MustCompile(`^\s*\)\s*;?\s*$`)

	skipKeywords := getSkipKeywords()

	for scanner.Scan() {
		line := scanner.Text()
		lineStripped := strings.TrimSpace(line)

		// Handle multi-line block comment continuation
		if inBlockComment {
			endIdx := strings.Index(line, "*/")
			if endIdx != -1 {
				commentBuilder.WriteString(" " + strings.TrimSpace(line[:endIdx]))
				fullComment := cleanComment(commentBuilder.String())

				if pendingColumn != "" && currentTable != "" {
					if tableComments[currentTable] == nil {
						tableComments[currentTable] = make(map[string]string)
					}
					tableComments[currentTable][pendingColumn] = fullComment
				} else if pendingTable != "" {
					tableDescriptions[pendingTable] = fullComment
				}

				inBlockComment = false
				pendingColumn = ""
				pendingTable = ""
				commentBuilder.Reset()
			} else {
				commentBuilder.WriteString(" " + strings.TrimSpace(line))
			}
			continue
		}

		if matches := createTableRe.FindStringSubmatch(lineStripped); len(matches) > 1 {
			currentTable = strings.ToLower(matches[1])
			inCreateTable = true
			if tableComments[currentTable] == nil {
				tableComments[currentTable] = make(map[string]string)
			}

			// Check for comments
			dashIdx := strings.Index(line, "--")
			blockIdx := strings.Index(line, "/*")
			hasDash := dashIdx != -1
			hasBlock := blockIdx != -1

			if hasDash && (!hasBlock || dashIdx < blockIdx) {
				comment := line[dashIdx+2:]
				tableDescriptions[currentTable] = cleanComment(comment)
			} else if hasBlock {
				if endIdx := strings.Index(line, "*/"); endIdx != -1 {
					comment := line[blockIdx+2 : endIdx]
					tableDescriptions[currentTable] = cleanComment(comment)
				} else {
					inBlockComment = true
					pendingTable = currentTable
					commentBuilder.WriteString(strings.TrimSpace(line[blockIdx+2:]))
				}
			}
			continue
		}

		if inCreateTable && endTableRe.MatchString(lineStripped) {
			inCreateTable = false
			continue
		}

		if inCreateTable && regexp.MustCompile(`(?i)^\s*(PRIMARY\s+KEY|CONSTRAINT|UNIQUE|FOREIGN\s+KEY|CHECK)\b`).MatchString(lineStripped) {
			continue
		}

		if inCreateTable && currentTable != "" {
			if matches := columnRe.FindStringSubmatch(lineStripped); len(matches) > 1 {
				columnName := strings.ToLower(matches[1])

				if skipKeywords[strings.ToUpper(columnName)] {
					continue
				}

				// Check for comments
				dashIdx := strings.Index(line, "--")
				blockIdx := strings.Index(line, "/*")
				hasDash := dashIdx != -1
				hasBlock := blockIdx != -1

				if hasDash && (!hasBlock || dashIdx < blockIdx) {
					comment := line[dashIdx+2:]
					tableComments[currentTable][columnName] = cleanComment(comment)
				} else if hasBlock {
					if endIdx := strings.Index(line, "*/"); endIdx != -1 {
						comment := line[blockIdx+2 : endIdx]
						tableComments[currentTable][columnName] = cleanComment(comment)
					} else {
						inBlockComment = true
						pendingColumn = columnName
						commentBuilder.WriteString(strings.TrimSpace(line[blockIdx+2:]))
					}
				}
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, nil, fmt.Errorf("读取文件错误: %v", err)
	}

	return tableComments, tableDescriptions, nil
}

// generateComments 生成 COMMENT 语句，应用继承规则
func generateComments(inputFile string, baseTableComments TableColumnComments, tableDescriptions map[string]string) ([]string, error) {
	file, err := os.Open(inputFile)
	if err != nil {
		return nil, fmt.Errorf("无法打开文件: %v", err)
	}
	defer file.Close()

	var comments []string
	scanner := bufio.NewScanner(file)
	var currentTable string
	inCreateTable := false
	processedColumns := make(map[string]map[string]bool) // 记录已处理的列

	createTableRe := regexp.MustCompile(`(?i)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["']?(\w+)["']?`)
	columnRe := regexp.MustCompile(`^\s*["']?(\w+)["']?\s+`)
	lineCommentRe := regexp.MustCompile(`--\s*(.+?)\s*$`)
	blockCommentRe := regexp.MustCompile(`/\*\s*([^*]*)\s*\*/`)
	endTableRe := regexp.MustCompile(`^\s*\)\s*;?\s*$`)

	skipKeywords := getSkipKeywords()

	for scanner.Scan() {
		line := scanner.Text()
		lineStripped := strings.TrimSpace(line)

		if matches := createTableRe.FindStringSubmatch(lineStripped); len(matches) > 1 {
			currentTable = strings.ToLower(matches[1])
			inCreateTable = true
			processedColumns[currentTable] = make(map[string]bool)

			// 生成表级别的注释
			if tableDesc, ok := tableDescriptions[currentTable]; ok {
				comments = append(comments, formatTableComment(currentTable, tableDesc))
			}
			continue
		}

		if inCreateTable && endTableRe.MatchString(lineStripped) {
			inCreateTable = false
			continue
		}

		if inCreateTable && regexp.MustCompile(`(?i)^\s*(PRIMARY\s+KEY|CONSTRAINT|UNIQUE|FOREIGN\s+KEY|CHECK)\b`).MatchString(lineStripped) {
			continue
		}

		if inCreateTable && currentTable != "" {
			if matches := columnRe.FindStringSubmatch(lineStripped); len(matches) > 1 {
				columnName := strings.ToLower(matches[1])

				if skipKeywords[strings.ToUpper(columnName)] {
					continue
				}

				// 避免重复处理同一个列
				if processedColumns[currentTable][columnName] {
					continue
				}
				processedColumns[currentTable][columnName] = true

				// 确定使用哪个表的注释
				columnComment := getColumnComment(currentTable, columnName, baseTableComments, lineCommentRe, blockCommentRe, line)
				if columnComment != "" {
					comments = append(comments, formatColumnComment(currentTable, columnName, columnComment))
				}
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("读取文件错误: %v", err)
	}

	return comments, nil
}

// getColumnComment 获取列的注释，应用继承规则
func getColumnComment(tableName, columnName string, baseTableComments TableColumnComments, lineCommentRe, blockCommentRe *regexp.Regexp, line string) string {
	// 检查是否是派生表（以 _checks, _chkdetail, _checkrst, _chkdetail_ext 结尾）
	baseTable := getBaseTable(tableName)

	if baseTable != "" {
		// 是派生表，优先使用基础表的注释
		if baseColumns, ok := baseTableComments[baseTable]; ok {
			if comment, ok := baseColumns[columnName]; ok {
				return comment
			}
		}
	}

	// 使用当前表自己的注释
	if tableColumns, ok := baseTableComments[tableName]; ok {
		if comment, ok := tableColumns[columnName]; ok {
			return comment
		}
	}

	return ""
}

// getBaseTable 检查表名是否是派生表，返回基础表名
func getBaseTable(tableName string) string {
	for baseTable, suffix := range baseTables {
		if strings.HasSuffix(tableName, suffix) && tableName != baseTable {
			return baseTable
		}
	}
	return ""
}

func extractComment(line string, lineCommentRe, blockCommentRe *regexp.Regexp) string {
	if matches := lineCommentRe.FindStringSubmatch(line); len(matches) > 1 {
		return strings.TrimSpace(matches[1])
	}
	if matches := blockCommentRe.FindStringSubmatch(line); len(matches) > 1 {
		return strings.TrimSpace(matches[1])
	}
	return ""
}

func cleanComment(comment string) string {
	if comment == "" {
		return ""
	}

	if idx := strings.Index(comment, "\n"); idx >= 0 {
		comment = comment[:idx]
	}
	if idx := strings.Index(comment, "\r"); idx >= 0 {
		comment = comment[:idx]
	}

	lzmRe := regexp.MustCompile(`(?i)\s*[-–—]*\s*lzm\s+(add|modify|update)\s+\d{4}[-/]\d{2}[-/]\d{2}.*$`)
	comment = lzmRe.ReplaceAllString(comment, "")

	comment = strings.TrimRight(comment, " ,;，；。")
	// Fix for comments ending in // which causes //*/
	comment = strings.TrimSuffix(comment, "//")
	comment = strings.TrimSpace(comment)

	if len(comment) < 1 || comment == "--" || comment == "/*" || comment == "*/" || comment == "-" || comment == "/" || comment == "*" {
		return ""
	}

	return comment
}

func escapeSql(text string) string {
	return strings.ReplaceAll(text, "'", "''")
}

// escapeSqlForExecute 在 EXECUTE 语句内部，单引号需要四重转义
func escapeSqlForExecute(text string) string {
	return strings.ReplaceAll(text, "'", "''''")
}

// formatTableComment 生成带有表存在性检查的 COMMENT ON TABLE 语句
func formatTableComment(tableName, comment string) string {
	return fmt.Sprintf(`DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '%s') THEN EXECUTE 'COMMENT ON TABLE %s IS ''%s'''; END IF; END $$;`,
		tableName, tableName, escapeSqlForExecute(comment))
}

// formatColumnComment 生成带有列存在性检查的 COMMENT ON COLUMN 语句
func formatColumnComment(tableName, columnName, comment string) string {
	return fmt.Sprintf(`DO $$ BEGIN IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = '%s' AND column_name = '%s') THEN EXECUTE 'COMMENT ON COLUMN %s.%s IS ''%s'''; END IF; END $$;`,
		tableName, columnName, tableName, columnName, escapeSqlForExecute(comment))
}

func getSkipKeywords() map[string]bool {
	return map[string]bool{
		"PRIMARY":    true,
		"CONSTRAINT": true,
		"UNIQUE":     true,
		"FOREIGN":    true,
		"CHECK":      true,
		"INDEX":      true,
		"CREATE":     true,
		"ALTER":      true,
		"DROP":       true,
		"INSERT":     true,
		"UPDATE":     true,
		"DELETE":     true,
		"SELECT":     true,
		"FROM":       true,
		"WHERE":      true,
		"AND":        true,
		"OR":         true,
		"ON":         true,
	}
}

func rewriteSQL(inputFile, outputFile, filterTable string) error {
	file, err := os.Open(inputFile)
	if err != nil {
		return err
	}
	defer file.Close()

	outFile, err := os.Create(outputFile)
	if err != nil {
		return err
	}
	defer outFile.Close()

	writer := bufio.NewWriter(outFile)
	defer writer.Flush()

	scanner := bufio.NewScanner(file)

	var inBlockComment bool
	var commentBuilder strings.Builder
	var linePrefix string

	createTableRe := regexp.MustCompile(`(?i)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?["']?(\w+)["']?`)
	endTableRe := regexp.MustCompile(`^\s*\)\s*;?\s*$`)

	printing := true
	if filterTable != "" {
		printing = false
	}

	for scanner.Scan() {
		line := scanner.Text()
		lineStripped := strings.TrimSpace(line)

		if matches := createTableRe.FindStringSubmatch(lineStripped); len(matches) > 1 {
			if filterTable != "" {
				currentTable := strings.ToLower(matches[1])
				printing = (currentTable == filterTable)
			}
		}

		if !printing {
			continue
		}

		if inBlockComment {
			endIdx := strings.Index(line, "*/")
			if endIdx != -1 {
				commentBuilder.WriteString(" " + strings.TrimSpace(line[:endIdx]))
				fullComment := cleanComment(commentBuilder.String())

				suffix := line[endIdx+2:]
				fmt.Fprintf(writer, "%s/*%s*/%s\n", linePrefix, fullComment, suffix)

				inBlockComment = false
				commentBuilder.Reset()
				linePrefix = ""
			} else {
				commentBuilder.WriteString(" " + strings.TrimSpace(line))
			}
			continue
		}

		blockIdx := strings.Index(line, "/*")
		if blockIdx != -1 {
			endIdx := strings.Index(line, "*/")
			if endIdx != -1 && endIdx > blockIdx {
				rawComment := line[blockIdx+2 : endIdx]
				cleaned := cleanComment(rawComment)

				newLine := line[:blockIdx] + "/*" + cleaned + "*/" + line[endIdx+2:]
				fmt.Fprintln(writer, newLine)
			} else {
				inBlockComment = true
				linePrefix = line[:blockIdx]
				commentBuilder.WriteString(strings.TrimSpace(line[blockIdx+2:]))
			}
			continue
		}

		fmt.Fprintln(writer, line)

		if filterTable != "" && endTableRe.MatchString(lineStripped) {
			printing = false
		}
	}

	return scanner.Err()
}

func exportFromDB(tableName, outputFile, dsn string) error {
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		dsn = "host=localhost port=5432 user=postgres password=postgres dbname=victorypos sslmode=disable"
	}

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return fmt.Errorf("连接数据库失败: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		return fmt.Errorf("ping数据库失败: %v", err)
	}

	// 1. 获取表级注释
	var tableComment sql.NullString
	err = db.QueryRow(`
		SELECT pg_catalog.obj_description(c.oid, 'pg_class')
		FROM pg_catalog.pg_class c
		JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
		WHERE c.relname = $1 AND n.nspname = 'public'
	`, tableName).Scan(&tableComment)
	if err != nil && err != sql.ErrNoRows {
		return fmt.Errorf("查询表注释失败: %v", err)
	}

	// 2. 获取列信息
	rows, err := db.Query(`
		SELECT 
			a.attname AS column_name,
			pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
			(SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid) for 128)
			 FROM pg_catalog.pg_attrdef d
			 WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) AS default_value,
			a.attnotnull AS not_null,
			pg_catalog.col_description(c.oid, a.attnum) AS comment
		FROM pg_catalog.pg_attribute a
		JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
		JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
		WHERE c.relname = $1 AND n.nspname = 'public' AND a.attnum > 0 AND NOT a.attisdropped
		ORDER BY a.attnum
	`, tableName)
	if err != nil {
		return fmt.Errorf("查询列信息失败: %v", err)
	}
	defer rows.Close()

	outFile, err := os.Create(outputFile)
	if err != nil {
		return err
	}
	defer outFile.Close()

	writer := bufio.NewWriter(outFile)
	defer writer.Flush()

	// 写入 CREATE TABLE
	createHeader := fmt.Sprintf("CREATE TABLE %s", strings.ToUpper(tableName))
	if tableComment.Valid && tableComment.String != "" {
		createHeader += fmt.Sprintf(" /*%s*/", cleanComment(tableComment.String))
	}
	writer.WriteString(createHeader + "\n(\n")

	var colDefs []string
	for rows.Next() {
		var colName, dataType string
		var defaultValue sql.NullString
		var notNull bool
		var comment sql.NullString

		if err := rows.Scan(&colName, &dataType, &defaultValue, &notNull, &comment); err != nil {
			return err
		}

		upperType := strings.ToUpper(dataType)
		upperType = strings.ReplaceAll(upperType, "CHARACTER VARYING", "VARCHAR")

		def := fmt.Sprintf("  %-13s %s", strings.ToUpper(colName), upperType)
		if notNull {
			def += " NOT NULL"
		}
		if defaultValue.Valid {
			// 清理默认值中的类型转换
			defVal := defaultValue.String
			defVal = strings.ReplaceAll(defVal, "::character varying", "")
			defVal = strings.ReplaceAll(defVal, "::text", "")
			def += " DEFAULT " + defVal
		}

		// 逗号在 SQL 中列定义之间需要（除了最后一行）。
		// 我们先收集所有定义，最后拼接，处理逗号。
		// 这里先存对象？或者 string？
		// Append comment
		if comment.Valid && comment.String != "" {
			// clean comment
			clean := cleanComment(comment.String)
			if clean != "" {
				// 为了对齐，可以计算长度，但此处简化
				// JXC 风格：注释在末尾
				// def += "," // 稍后加
				// def += fmt.Sprintf(" /*%s*/", clean)
				// Wait, if I append Comment to string, I might separate comment from comma?
				// SQL: `col type, /*...*/` OR `col type /*...*/,`?
				// Parser usually ignores comments.
				// user source: `col type, /*...*/`
				// So comma comes BEFORE comment usually?
				// Source Step 571: `ATABLESID     INTEGER,           /*对应 ATABLES 中的 ATABLESID*/`
				// Yes, comma then comment.
			}
		}

		colDefs = append(colDefs, def+"|MATCH_COMMENT|"+comment.String) // Temporary separator
	}

	for i, colDef := range colDefs {
		parts := strings.Split(colDef, "|MATCH_COMMENT|")
		code := parts[0]
		rawComm := parts[1]

		suffix := ""
		if i < len(colDefs)-1 {
			suffix = ","
		}

		line := code + suffix
		if rawComm != "" {
			clean := cleanComment(rawComm)
			if clean != "" {
				// Pad with spaces for alignment?
				// Simple padding
				if len(line) < 30 {
					line += strings.Repeat(" ", 30-len(line))
				}
				line += fmt.Sprintf(" /*%s*/", clean)
			}
		}

		writer.WriteString(line + "\n")
	}

	writer.WriteString(");\n")
	return nil
}
