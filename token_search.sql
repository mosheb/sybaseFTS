drop proc token_search
go
create proc token_search
    @userinput varchar(60)

as

-- exec token_search 'JOHN SMITH'


create table #userTokens(utoken varchar(150) not null)

WHILE PATINDEX('%[^abcdefghijklmnopqrstuvwxyz ]%',@userinput) > 0
   SET @userinput=str_replace(@userinput, SUBSTRING(@userinput ,PATINDEX('%[^abcdefghijklmnopqrstuvwxyz ]%',@userinput), 1) ,' ')

WHILE PATINDEX('  ',@userinput) > 0
   SET @userinput=str_replace(@userinput, '  ',' ')

set @userinput=ltrim(rtrim(@userinput))

---------------------------------------------------------------------------------

declare @pos numeric(3,0)
declare @piece varchar(150)
declare @numTokens int

Set @pos = charindex(' ' , @userinput)

while @pos <> 0
begin

    SET @piece = LEFT(@userinput, @pos-1)

    if char_length(@piece)>2
        insert #userTokens
        select @piece
        where @piece not in (select utoken from #userTokens)

        SET @userinput = stuff(@userinput, 1, @pos, NULL)
        SET @pos = charindex(' ' , @userinput)

end

if char_length(@userinput)>2
    insert #userTokens
    select @userinput
    where @userinput not in (select utoken from #userTokens)

---------------------------------------------------------------------------------

select @numTokens = count(*) from #userTokens

select top 100 * 
into #results
from 
(
select 'rank'=1,t.id,'numfound'=count(*)
from title_tokens t
    ,#userTokens
where token = utoken
group by t.id
having count(*)>=@numTokens

union all

select 'rank'=2,t.id,'numfound'=count(*)
from title_tokens t (index tokenid)
    ,#userTokens
where token != utoken
    and token like utoken + '%'
group by t.id
having count(*)>=@numTokens
) dt
order by rank,numfound desc

select p.*
from #results r
    ,title_pretoken p
where p.id=r.id
order by rank,numfound desc
