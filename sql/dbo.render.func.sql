-- dynamic-sql-templating
-- Open source project: https://github.com/lanjing-jin/dynamic-sql-template
-- Author: Lanjing Jin
--
create or alter function dbo.render (
	@templ nvarchar(max),
	@args_json nvarchar(max)
)
returns @results table(rendered varchar(max), ordinal int, template varchar(max), args_json nvarchar(max))
as begin
	declare @text nvarchar(max) = @templ, @label1 varchar(255), @label2 varchar(255),
		@pos int, @pos1 int, @pos2 int, @key varchar(255), @value varchar(max), @type int, @cond bit
	declare CURS cursor local for select [key], [value], [type] from openjson(@args_json)
	open CURS
	fetch next from CURS into @key, @value, @type
	while @@fetch_status = 0 begin
		if @type = 0 select @cond = 0, @value = '' -- null
		else if @type = 1 select @cond = case when @value <> '' then 1 else 0 end -- string
		else if @type = 2 select @cond = case when convert(real, @value) <> 0 then 1 else 0 end -- number
		else if @type = 3 select @cond = case when @value = 'true' then 1 else 0 end, @value = case when @value = 'true' then '1' else '0' end -- bit / boolean
		else if @type = 4 select @cond = 1, @value = '[JSON Array]'
		else if @type = 5 select @cond = 1, @value = '{JSON Object}'

		select @label1 = '<' + @key + '/>', @pos = 1
		while 1 = 1 begin
			select @pos1 = charindex(@label1, @text, @pos)
			if @pos1 = 0 break
			select @text = stuff(@text, @pos1, len(@label1), @value), @pos = @pos1
		end
		select @label1 = '<' + @key + '>', @label2 = '</' + @key + '>', @pos = 1 -- true
		while 1 = 1 begin
			select @pos1 = charindex(@label1, @text, @pos)
			if @pos1 = 0 break
			select @pos2 = charindex(@label2, @text, @pos1 + len(@label1))
			if @pos2 = 0 break
			select @text = case when @cond = 0
				then stuff(@text, @pos1, @pos2 - @pos1 + len(@label2), '')
				else stuff(stuff(@text, @pos2, len(@label2), ''), @pos1, len(@label1), '')
			end, @pos = @pos1
		end
		select @label1 = '<!' + @key + '>', @label2 = '</!' + @key + '>', @pos = 1 -- false
		while 1 = 1 begin
			select @pos1 = charindex(@label1, @text, @pos)
			if @pos1 = 0 break
			select @pos2 = charindex(@label2, @text, @pos1 + len(@label1))
			if @pos2 = 0 break
			select @text = case when @cond = 1
				then stuff(@text, @pos1, @pos2 - @pos1 + len(@label2), '')
				else stuff(stuff(@text, @pos2, len(@label2), ''), @pos1, len(@label1), '')
			end, @pos = @pos1
		end
		fetch next from CURS into @key, @value, @type
	end
	close CURS
	deallocate CURS

	insert into @results
	select r.[value], r.ordinal, t.[value], @args_json
	from dbo.split_string(@text, '<-->') r
	join dbo.split_string(@templ, '<-->') t on r.ordinal = t.ordinal
	return
end
go
