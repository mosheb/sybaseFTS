
select 'sort'=1, f.*
into #res
from title_pretoken f
where acct='@acct'

insert #res
select 2,*
from title_pretoken f
where ssn='@ssn'

insert #res
select 3, f.*
from title_tokens t
    ,title_pretoken f
where f.id=t.id
    and token = '@token'

union all

select 4, f.*
from title_tokens t
    ,title_pretoken f
where f.id=t.id
    and token != '@token'
    and token like '@token%'

select *
from #res
order by 1

