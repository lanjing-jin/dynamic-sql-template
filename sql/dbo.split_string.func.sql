-- dynamic-sql-templating
-- Open source project: https://github.com/lanjing-jin/dynamic-sql-template
-- Author: Lanjing Jin
--
create or alter function dbo.split_string (
	@string varchar(max),
	@delimiter varchar(255)
)
returns table
as return
	select convert(varchar(max), [value]) [value], [key] + 1 ordinal
	from openjson(json_query('["' + replace(string_escape(@string,'json'), string_escape(@delimiter,'json'), '","') + '"]'))
go
