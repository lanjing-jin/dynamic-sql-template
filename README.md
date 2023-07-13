# dynamic-sql-template
SQL Server dynamic SQL templating solution

This project aims to let you to write dynamic SQL queries in the simplest, most intuitive way, similarly to how you would write normal SQL, using templates embedded in your regular SQL text (as comments). If you have been writing dynamic SQL using string concatenation, and got tired of counting single quotes and string concatenation, and frustrated over difficulties in proof-reading and troubleshooting, you're in the right place.

## Installation
Run each of the SQL scripts found under the /sql folder under your target database, and that's it!

## Examples

### Simple example

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

