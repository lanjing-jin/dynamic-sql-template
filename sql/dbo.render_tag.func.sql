-- dynamic-sql-templating
-- Open source project: https://github.com/lanjing-jin/dynamic-sql-template
-- Author: Lanjing Jin
--
create or alter function dbo.render_tag (
	@tag varchar(255),
	@args_json nvarchar(max)
)
returns table
as return
	with cte as (select top 1 [text] from (
		select t.[text] from sys.dm_exec_cached_plans p
		cross apply sys.dm_exec_sql_text(p.plan_handle) t
		cross apply sys.dm_exec_plan_attributes(p.plan_handle) a
		where a.attribute = 'objectid' and a.value = @@procid
		union all
		select m.[definition] from tempdb.sys.sql_modules m
		where m.object_id = @@procid
	) t)
	select r.*
	from cte t
	cross apply (select
		label1 = '<' + @tag + '>',
		label2 = '</' + @tag + '>'
	) c1
	cross apply (select
		pos0 = charindex(label1, [text]),
		pos2 = charindex(label2, [text])
	) c2
	cross apply (select pos1 = pos0 + len(label1)) c3
	cross apply (select templ = substring([text], pos1, pos2 - pos1)) c4
	cross apply dbo.render(templ, @args_json) r
	where pos0 > 0 and pos2 > pos1
go
