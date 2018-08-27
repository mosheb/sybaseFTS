--FIRST LOAD
--- make token table
--drop table tempdb..address_pretoken

--uses tempdb since it is much faster for 1st load

create table tempdb..address_pretoken(id numeric(8,0) identity not null, acct char(10) not null, address varchar(250) not null
    , ssn char(4) null, rr varchar(5) not null, dept varchar(5) not null)
with identity_gap = 20
go

insert tempdb..address_pretoken(acct, address, ssn) --last 4 digits, unhashed...?
select Acct_num
    ,Address
from name_and_address
go


--drop table address_pretoken
create table address_pretoken(id numeric(8,0) identity not null, acct char(10) not null, address varchar(250) not null
    , ssn char(4) null)
with identity_gap = 20
go

insert address_pretoken(acct,address,ssn)
select acct,address,ssn
from tempdb..address_pretoken

----------------------------------------------------------------------------------

create unique index ididx on address_pretoken(id)
create index ssnidx on address_pretoken(ssn)
create unique index acctidx on address_pretoken(acct)
go

--drop table tempdb..address_tokens
create table tempdb..address_tokens(id numeric(8,0) not null, token varchar(150) not null)

--drop proc addresstoken_1strun

----------------------------------------------------------------------------------

create proc addresstoken_1strun

as

set nocount on

----cursor -----------------------------
declare wotever_cursor cursor for
	select id,address from address_pretoken
    where address!='' and char_length(address)>2

declare @id numeric(8,0)
declare @pos numeric(3,0)
declare @piece varchar(150)
declare @string varchar(250)

open wotever_cursor

fetch wotever_cursor into @id,@string

if (@@sqlstatus = 2)
    close wotever_cursor
else
    while (@@sqlstatus = 0)
        begin

            WHILE PATINDEX('%[^abcdefghijklmnopqrstuvwxyz ]%',@string) > 0
               SET @string=str_replace(@string, SUBSTRING(@string ,PATINDEX('%[^abcdefghijklmnopqrstuvwxyz ]%',@string), 1) ,' ')

            WHILE PATINDEX('  ',@string) > 0
               SET @string=str_replace(@string, '  ',' ')

            set @string=ltrim(rtrim(@string))

            Set @pos = charindex(' ' , @string)

            while @pos <> 0
            begin

                SET @piece = LEFT(@string, @pos-1)

                if char_length(@piece)>2
                    insert tempdb..address_tokens
                    select @id, @piece

                    SET @string = stuff(@string, 1, @pos, NULL)
                    SET @pos = charindex(' ' , @string)

            end

            if char_length(@string)>2
                insert tempdb..address_tokens
                select @id, @string

            fetch wotever_cursor into @id,@string

		end

deallocate cursor wotever_cursor

go

exec addresstoken_1strun
go

--remove tokens that are too common ?
--generate noise word list:
--create index txtidx on tempdb..address_tokens(token)
--select token, count(*)
--from  tempdb..address_tokens
--group by token
--having count(*)>500
--order by 2 desc

delete tempdb..address_tokens
from noisewords
where token = noise
go

/*
create table address_tokens(id numeric(8,0) not null, token varchar(150) not null)
go

create unique index tokenid on intraday..address_tokens(token, id)
with ignore_dup_key
go
*/
insert intraday..address_tokens
select * from tempdb..address_tokens
go

