# dynamic-sql-template
SQL Server dynamic SQL templating solution

This project aims to let you to write dynamic SQL queries in the simplest, most intuitive way, similarly to how you would write normal SQL, using templates embedded in your regular SQL text (as comments). If you have been writing dynamic SQL using string concatenation, and got tired of counting single quotes and string concatenation, and frustrated over difficulties in proof-reading and troubleshooting, you're in the right place.

## Installation
Run each of the SQL scripts found under the /sql folder under your target database, and that's it!

## Examples

### Example 1

Render a template by supplying arguments as literal values:

```sql
declare @sql nvarchar(max)

-- Build the dynamic SQL:
select @sql = rendered
from dbo.render_tag('dynamic_sql_templ', (select
    col_list = 'person_id, date_of_birth, first_name, last_name, employer',
    table_name = 't_person',
    pk_col_list = 'person_id',
    do_order = 1
    for json path, without_array_wrapper, include_null_values
)) x
-- Use the dynamic SQL:
print @sql
--exec sp_executesql @sql

-- Dynamic SQL template. Place anywhere in the same function, stored procedure, or ad-hoc query:
/*
<dynamic_sql_templ>
    select <col_list/> from <table_name/>
    <do_order>
    order by <pk_col_list/>
    </do_order>
</dynamic_sql_templ>
*/
```

Output:
```
select person_id, date_of_birth, first_name, last_name, employer from t_person

order by person_id
```

Note:
1. To define a text replacement field, put the field name in a HTML self-closing tag, e.g. `<table_name/>`.
2. To define a conditional block, surround the block with a pair of opening/closing HTML tags named after the condition variable, e.g. `<do_order>...</do_order>`.
3. Supply values of the named replacement fields and conditions in the JSON argument to render_tag().

### Example 2

Render a `select ... from ... order by ...` statement for each table in the current database. The order by clause will be based on the primary key columns of each table, omitted if the table doesn't have a primary key:

```sql
select x.*
from sys.tables t
outer apply (
    select STRING_AGG(c.name, ',') within group (order by c.column_id) col_list
    from sys.columns c
    where c.object_id = t.object_id
) a1 -- column list
outer apply (
    select STRING_AGG(c.name, ',') within group (order by ic.index_column_id) pk_col_list, count(*) pk_width
    from sys.columns c
    join sys.index_columns ic on c.object_id = ic.object_id and c.column_id = ic.column_id
    join sys.indexes i on ic.object_id=i.object_id and ic.index_id=i.index_id
    where c.object_id = t.object_id and i.is_primary_key = 1
) a2 -- PK column list
outer apply dbo.render_tag('dynamic_sql_templ', (select
    col_list,
    t.name table_name,
    pk_col_list,
    do_order = case when a2.pk_width>0 then 1 else 0 end
    for json path, without_array_wrapper, include_null_values
)) x

-- Dynamic SQL template. Place anywhere in the same function, stored procedure, or ad-hoc query:
/*
<dynamic_sql_templ>
    select <col_list/> from <table_name/>
    <do_order>
    order by <pk_col_list/>
    </do_order>
</dynamic_sql_templ>
*/
```
