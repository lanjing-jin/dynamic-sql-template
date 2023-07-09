# dynamic-sql-template
SQL Server dynamic SQL templating solution

This project enables you to write dynamic SQL queries in the most intuitive way possible and similarly to how you would write normal SQL, using templates embedded in your SQL text as comments. If you have been writing dynamic SQL using string concatenation, and got tired of counting single quotes, and frustrated over difficulties in proof-reading and troubleshooting, you're in the right place. Start by copy-pasting the below examples and you'll be on your way to dynamic SQL greatness!

## Installation
This is a pure-SQL solution so installation is as simple as it can be: Run each of the SQL scripts found under the /sql folder under your target database, and you're done!

## Get started with these examples:

```sql
    declare @sql nvarchar(max)
    declare @sql2 nvarchar(max)

	select @sql = q1.sql_create_table, @sql2 = r.sql_truncate_table, @cmd_query1 = r.cmd_bcp1, @cmd_query2 = r.cmd_bcp2, @cmd_del_file = r.cmd_del_file
	from @table_update_task tut
	cross join ##edw_replicate_setting se
	join ##edw_replicate_source s on tut.source_id = s.source_id
	join edw.edw_replicate_catalog c on tut.source_id = c.source_id and tut.table_name = c.table_name
	join ##edw_replicate_table_info ti on tut.source_id = ti.source_id and tut.table_name = ti.table_name
	outer apply (
		select sql_create_table = ti.sql_create_target_table where ti.is_target_missing = 1
	) q1
	outer apply (
		select sql_truncate_table = [1], cmd_bcp1 = [2], cmd_bcp2 = [3], cmd_del_file = [4]
		from dbo.render_tag('table_update_1.tmp', (select
			do_truncate_target = case when ti.is_target_missing = 0 and (c.is_incremental = 0 or json_query(c.status_json, '$.update_progress') is null) then 1 else 0 end,
			ti.has_diff_table,
			bcp_diff_file = se.local_dir + '\table_update_qid_' + convert(varchar(10), tut.table_update_qid) + '_diff_' + tut.table_name,
			ti.target_table, ti.diff_table, se.local_db_name, ti.source_diff_table, s.server_name, s.[db_name], s.server_login, s.server_password
			for json path, without_array_wrapper, include_null_values
		)) x
		pivot (max(rendered) for ordinal in ([1], [2], [3], [4])) y
	) r

	/*<table_update_1.tmp>
		<do_truncate_target>
		truncate table <target_table/>
		</do_truncate_target>
	<-->
		<has_diff_table>
		bcp <diff_table/> out <bcp_diff_file/> -S localhost -d <local_db_name/> -T -n -C RAW
		</has_diff_table>
	<-->
		<has_diff_table>
		bcp <source_diff_table/> in <bcp_diff_file/> -S <server_name/> -d <db_name/> -n -C RAW
		<server_login>-U <server_login/> -P "<server_password/>"</server_login>
		<!server_login>-T</!server_login>
		</has_diff_table>
	<-->
		<has_diff_table>
		del /f /q <bcp_diff_file/>
		</has_diff_table>
	</table_update_1.tmp>*/

```
