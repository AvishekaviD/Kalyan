/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [ID]
      ,[Name]
      ,[Name_bk]
      ,[Salutation]
      ,[Initial]
      ,[First]
      ,[Middle]
      ,[Middle 1]
      ,[Last]
      ,[No of Spaces]
      ,[cleaning process]
      ,[type of error]
  FROM [Kalyan_Temp].[dbo].[name_cleaned_20160923]
  
  select count(distinct [customercode]) from [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
 
 ---separeting state 
 ---null state
 --drop table #statenull 
  
     select * into #statenull
 from [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
 where state is null or state = 'NA' or state = '' or state = 'NULL'
 
 select count(distinct [CustomerCode]) from #statenull
 
 --not null state
 --drop table #statenotnull
  
   select * into #statenotnull
 from [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
 where state is not null and state <> 'NA' and state <> '' and state <> 'NULL'
 
  select count(distinct [CustomerCode]) from #statenotnull
 
 --- adding records to the cleaned names
 ---null state
-- drop table #stateupdatednull
   select distinct a.* ,b.[JoinStoreState_BasisCustomerCode] as joinstate,b.[State]as resstate
 into #stateupdatednull
 from [Kalyan_Temp].[dbo].[name_cleaned_20160923] as a
 inner join #statenull as b
 on a.[ID]=b.[CustomerCode]
 
 ---not null state
--  drop table #stateupdated
   select distinct a.* ,b.[JoinStoreState_BasisCustomerCode] as joinstate,b.[State]as resstate
 into #stateupdated
 from [Kalyan_Temp].[dbo].[name_cleaned_20160923] as a
 inner join #statenotnull as b
 on a.[ID]=b.[CustomerCode]
 
 --state by last name
 --null state
 drop table #statelastnull
   select a.*,b.[state] as Statelast
 into #statelastnull
 from #stateupdatednull as a
 left join [Kalyan_Temp].[dbo].[sp_lastname_20160923] as b
 on a.last=b.[Last name]
 
 select count (id) from #statelastnull
 where statelast is not null
 
 --not null state
 drop table #statelast
    select a.*,b.[state] as Statelast
 into #statelast
 from #stateupdated as a
 left join [Kalyan_Temp].[dbo].[sp_lastname_20160923] as b
 on a.last=b.[Last name]
 
 select count (id) from #statelast
 where statelast is not null
 
 ---updating by residence state
 --null state no need to update as state is already null
 
 --drop table #statelastnull
 
 ---  update #statelastnull
 ---set statelast=resstate
--- where statelast is null
 
 select count(id) from #statelastnull
 where statelast is not null
 ---not null state
 
 drop table #statelast
 
   update #statelast
 set statelast=resstate
 where statelast is null
 
  select count(id) from #statelast
 where statelast is not null
 
 ---updating by join state
 --null state
    update #statelastnull
 set statelast=joinstate
 where statelast is null
 
 select count(distinct id) from #statelastnull
 where statelast is not null
 
 ---not null state
    update #statelast
 set statelast=joinstate
 where statelast is null
 
  select count(id) from #statelast
 where statelast is not null
 
 ---state done totally
 --joining both state files
 
 ---drop table #finalstate
 select * into #finalstate from
(select * from #statelast
union
select * from #statelastnull 
where id not in (select id from #statelast)) as a
 
 select count(id) from #finalstate
 where statelast is not null
 
 select top 100 *  from #finalstate
  ---finalstate contains both the files
 
 ---mapping religion by last name
    select a.*,b.[Religion] as reglast
 into #reglast
 from #finalstate as a
 left join [Kalyan_Temp].[dbo].[sp_lastname_20160923] as b
 on a.last=b.[Last name]
 
 select top 100 * from #reglast
 select count(distinct id) from #reglast where
 reglast is not null
 
 ---religion by first name
 drop table #regfirst
 
 select a.*,b.[Religion] as regfirst
 into #regfirst
 from #reglast as a
 left join [Kalyan_Temp].[dbo].[sp_Firstname_20160923] as b
 on a.first=b.[First]
 
 select count(distinct id) from #regfirst
 where regfirst is not null
 
 select count(distinct id) from #regfirst
 where regfirst <> reglast
 
  select top 100 * from #regfirst
 where regfirst <> reglast
 
update #regfirst
set  regfirst=reglast
where regfirst is null



update #regfirst
set  regfirst=reglast
where (regfirst <> reglast) and (reglast is not null)

select count(distinct id) from #regfirst
where regfirst is not null
 
 
 
 
 
 --taking first name and counting them
 drop table #regnotnull
 
   select first,count(distinct regfirst) as cnt
 into #cnt1
 from #regfirst
 where regfirst is not null
 group by first
 
  
 --selecting only unique first (having cnt =1)
  select * 
 into #cnt2
 from #cnt1
 where cnt=1
 
 ---selecting names from already mapped religion
   select * into #regnotnull
 from #regfirst
 where regfirst is not null
 
 --adding religions to the list of first names
 
 --drop table #regcnt
   select distinct a.first,b.regfirst into #regcnt
 from #cnt2 as a
 left join #regnotnull as b
 on a.first=b.first
 
 select top 100 * from #regcnt

 
 ---appending the table to regfirst
   select a.* , b.regfirst as regfinal
 into #regfinal
 from #regfirst as a
 left join #regcnt as b
 on a.first=b.first
 
 
 select top 100 * from #regfinal
 --updating religion according to first name
   update #regfinal
 set regfirst=regfinal
 where regfirst is null
 
 select * 
 into [Kalyan_Temp].[dbo].[temp_sp_Ethnicity_20160923_3]
 from #regfinal
 
 select count(distinct id)
from #regfinal
where
regfirst is not null 

select top 100 * from #regfinal
---- finally done regfinal is the file
----regfirst is the column for religion 
----statelast is the column for state



select id,count(distinct statelast) as stcnt,
count(distinct regfirst) as recnt
into #temp
from #regfinal
group by id

select distinct id, stcnt from #temp
where stcnt > 1
order by stcnt desc


select distinct id, recnt from #temp
where recnt > 1
order by recnt desc







 