
----change the output table 

----RFM
----select date in the billdate field

SELECT [CustomerCode],max([BillDate]) [Recency],count(distinct [BillDate]) [Frequency],sum(isnull([NetAmount],0)) [Monetary]
into [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]  ------output table
FROM [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]  -----input table
where [BillDate]<'2017-01-01 00:00:00.000'
group by [CustomerCode]
---- adding columns
alter table [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125] add [RecencyQuintiles] int,[FrequencyQuintiles] int,[MonetaryQuintiles] int,outliers int
---selecting outliers(1)
update [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]
set [Outliers]= case when [Frequency]>40 then 1 else 0 end 

---selecting outliers(2)
update [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]
set [Outliers]= case when [Monetary]>5000000 then 1 
when [Monetary]<=0 then 1 else 0 end
where [Outliers] =0
----putting outliers into another table (optional)
select * into [Kalyan_Temp].[dbo].[temp_sp_20170125_RFM_outliers] from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125] where [Outliers]=1

---deleting the outliers
delete from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125] where [Outliers]=1

---selecting recency---------------------------------
Declare @MaxDate datetime
set @MaxDate=(select max([Recency]) from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125])


select CustomerCode,[Recency],datediff(day,[Recency],@MaxDate)[RecencyRange],ROW_NUMBER() over(order by [Recency] desc) RowNumber
into #t
from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]
---
alter table #t add [RecencyQuintiles] int
---

Declare @MaxRownumber bigint,@q1 int,@q2 int,@q3 int,@q4 int,@q5 int,@i int
set @MaxRownumber=(select max([RowNumber]) from #t)
set @q1=round(@MaxRownumber*.20,0)
set @q2=round(@MaxRownumber*.40,0)
set @q3=round(@MaxRownumber*.60,0)
set @q4=round(@MaxRownumber*.80,0)
set @q5=round(@MaxRownumber*1,0)


update #t
set [RecencyQuintiles]= case
when [RowNumber]>=0 and [RowNumber]<=@q1 then 5
when [RowNumber]>@q1 and [RowNumber]<=@q2 then 4
when [RowNumber]>@q2 and[RowNumber]<=@q3 then 3
when [RowNumber]>@q3 and [RowNumber]<=@q4 then 2
when [RowNumber]>@q4 then 1 end
--------
Declare @max int,@min int
set @max=(select max([RecencyRange]) from #t where [RecencyQuintiles]=5)
set @min=(select min([RecencyRange]) from #t where [RecencyQuintiles]=4)



if(@max=@min)
	begin
	update #t set [RecencyQuintiles]=5 where [RecencyRange]= @max
	end

--------

Declare @max1 int,@min1 int
set @max1=(select max([RecencyRange]) from #t where [RecencyQuintiles]=4)
set @min1=(select min([RecencyRange]) from #t where [RecencyQuintiles]=3)

select @max1,@min1

if(@max1=@min1)
	begin
	update #t set [RecencyQuintiles]=4 where [RecencyRange]= @max1
	end

--------
Declare @max2 int,@min2 int
set @max2=(select max([RecencyRange]) from #t where [RecencyQuintiles]=3)
set @min2=(select min([RecencyRange]) from #t where [RecencyQuintiles]=2)

select @max2,@min2

if(@max2=@min2)
	begin
	update #t set [RecencyQuintiles]=3 where [RecencyRange]= @max2
	end

--------
Declare @max3 int,@min3 int
set @max3=(select max([RecencyRange]) from #t where [RecencyQuintiles]=2)
set @min3=(select min([RecencyRange]) from #t where [RecencyQuintiles]=1)

select @max3,@min3

if(@max3=@min3)
	begin
	update #t set [RecencyQuintiles]=2 where [RecencyRange]= @max3
	end

----

update [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]
set [RecencyQuintiles]=b.[RecencyQuintiles]
from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125] a
inner join #t b on a.CustomerCode=b.CustomerCode

-----select top 100 * from #t
-----order by customercode

drop table #t

--------------------frequency quintiles-------------------------


select CustomerCode,[Frequency],ROW_NUMBER() over(order by [Frequency] asc) RowNumber
into #t
from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]

alter table #t add [Quintiles] int


update #t set [Quintiles]= 1 where [Frequency]=1
update #t set [Quintiles]= 2 where [Frequency]=2

---------------
Declare @MaxRownumber float,@MinRownumber float,@q1 int,@q2 int,@q3 int,@q4 int,@q5 int,@i int
set @MaxRownumber=(select count([RowNumber]) from #t where [Quintiles] is null)
--select round(@MaxRownumber/3,0)

set @MinRownumber=(select min([RowNumber]) from #t where [Quintiles] is null)


set @q1=(select min([RowNumber]) from #t where [Quintiles] is null)
set @q2=@q1+round(@MaxRownumber/3,0)
set @q3=@q2+round(@MaxRownumber/3,0)
set @q4=@q3+round(@MaxRownumber/3,0)


update #t
set [Quintiles]= case
when [RowNumber]>=@q1 and [RowNumber]<=@q2 then 3
when [RowNumber]>@q2 and [RowNumber]<=@q3 then 4
when [RowNumber]>@q3 and[RowNumber]<=@q4 then 5 end
where [Quintiles] is null


--select [Quintiles],count(*) from #t group by [Quintiles]

Declare @max float,@min float
set @max=(select max(round([Frequency],0)) from #t where [Quintiles]=3)
set @min=(select min(round([Frequency],0)) from #t where [Quintiles]=4)

select @max,@min

if(@max=@min)
	begin
	update #t set [Quintiles]=3 where round([Frequency],0)= @max
	end
----------

Declare @max1 float,@min1 float
set @max1=(select max(round([Frequency],0)) from #t where [Quintiles]=4)
set @min1=(select min(round([Frequency],0)) from #t where [Quintiles]=5)

select @max1,@min1

if(@max1=@min1)
	begin
	update #t set [Quintiles]=4 where round([Frequency],0)= @max1
	end

--------
	update [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]
set [FrequencyQuintiles]=b.[Quintiles]
from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125] a
inner join #t b on a.CustomerCode=b.CustomerCode

----select top 100 * from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]

drop table #t

-------------------monetary Quintiles ---------------------------------------


select CustomerCode,[Monetary],ROW_NUMBER() over(order by [Monetary] asc) RowNumber
into #t
from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]

alter table #t add [Quintiles] int

-----
Declare @MaxRownumber bigint,@q1 int,@q2 int,@q3 int,@q4 int,@q5 int,@i int
set @MaxRownumber=(select max([RowNumber]) from #t)
set @q1=round(@MaxRownumber*.20,0)
set @q2=round(@MaxRownumber*.40,0)
set @q3=round(@MaxRownumber*.60,0)
set @q4=round(@MaxRownumber*.80,0)
set @q5=round(@MaxRownumber*1,0)


update #t
set [Quintiles]= case
when [RowNumber]>=0 and [RowNumber]<=@q1 then 1
when [RowNumber]>@q1 and [RowNumber]<=@q2 then 2
when [RowNumber]>@q2 and[RowNumber]<=@q3 then 3
when [RowNumber]>@q3 and [RowNumber]<=@q4 then 4
when [RowNumber]>@q4 then 5 end
------
Declare @max float,@min float
set @max=(select max(round([Monetary],0)) from #t where [Quintiles]=1)
set @min=(select min(round([Monetary],0)) from #t where [Quintiles]=2)

select @max,@min

if(@max=@min)
	begin
	update #t set [Quintiles]=1 where round([Monetary],0)= @max
	end

--------
Declare @max1 float,@min1 float
set @max1=(select max(round([Monetary],0)) from #t where [Quintiles]=2)
set @min1=(select min(round([Monetary],0)) from #t where [Quintiles]=3)

select @max1,@min1

if(@max1=@min1)
	begin
	update #t set [Quintiles]=2 where round([Monetary],0)= @max1
	end
--------	
Declare @max2 float,@min2 float
set @max2=(select max(round([Monetary],0)) from #t where [Quintiles]=3)
set @min2=(select min(round([Monetary],0)) from #t where [Quintiles]=4)

select @max2,@min2

if(@max2=@min2)
	begin
	update #t set [Quintiles]=3 where round([Monetary],0)= @max2
	end
--------	
Declare @max3 float,@min3 float
set @max3=(select max(round([Monetary],0)) from #t where [Quintiles]=4)
set @min3=(select min(round([Monetary],0)) from #t where [Quintiles]=5)

select @max3,@min3

if(@max3=@min3)
	begin
	update #t set [Quintiles]=4 where round([Monetary],0)= @max3
	end
	
--------	
---select [Quintiles],count(*) from #t group by[Quintiles]


update [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]
set [MonetaryQuintiles]=b.[Quintiles]
from [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125] a
inner join #t b on a.CustomerCode=b.CustomerCode


drop table #t
-------creating final RFM table  
SELECT [CustomerCode]
      ,[Recency]
      ,[Frequency]
      ,[Monetary]
      ,[RecencyQuintiles]
      ,[FrequencyQuintiles]
      ,[MonetaryQuintiles]
      ,[Outliers]
                  ,([RecencyQuintiles]*0.5+[FrequencyQuintiles]*0.25+[MonetaryQuintiles]*0.25) as  "RFM_Final_SCORE"
                  ,case when ([RecencyQuintiles]*0.5+[FrequencyQuintiles]*0.25+[MonetaryQuintiles]*0.25) <=2 then 'RED'
                                                when ([RecencyQuintiles]*0.5+[FrequencyQuintiles]*0.25+[MonetaryQuintiles]*0.25) BETWEEN 2 and 2.8 then 'BRICK RED'       
                                                when ([RecencyQuintiles]*0.5+[FrequencyQuintiles]*0.25+[MonetaryQuintiles]*0.25) BETWEEN 3.5 and 4.5 then 'BLUE'
                                                when ([RecencyQuintiles]*0.5+[FrequencyQuintiles]*0.25+[MonetaryQuintiles]*0.25)>4.5 then 'GREEN'
                                                when ([RecencyQuintiles]*0.5+[FrequencyQuintiles]*0.25+[MonetaryQuintiles]*0.25) BETWEEN 2.8 AND 3.5 then 'YELLOW'
                                                END RFM_Colour
                                ,(cast ([RecencyQuintiles] as varchar(5))+cast([FrequencyQuintiles] as varchar(5))+cast([MonetaryQuintiles] as varchar(5))) AS "COMBINATION"
                  INTO [Kalyan_Temp].[dbo].[temp_sp_RFMV1_2016_20170125]    -----output table final table           
                  FROM [Kalyan_Temp].[dbo].[temp_sp_RFM_2016_20170125]


---select top 10 * from [Kalyan_Temp].[dbo].[temp_sp_RFMV1_2016_20170125]
---concat 
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-----RFM Finished
-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
----creating different tables for cleaning
SELECT distinct customerCode,[MobileNumberHash]
into [Kalyan_temp].[dbo].MobilePhoneCleaning_full_20170125
FROM [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
--where year(BillDate)<=2014


alter table [Kalyan_temp].[dbo].MobilePhoneCleaning_full_20170125
add [Mobile] varchar(50)

SELECT  distinct customerCode,[EmailIDHash]
into [Kalyan_temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
FROM [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
--where year(BillDate)<=2014

alter table [Kalyan_temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
add [Email] varchar(250)



SELECT distinct customerCode,[ResidencePhoneNoHash]
into [Kalyan_temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
FROM [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
--where year(BillDate)<=2014

alter table [Kalyan_temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
add [Phone] varchar(50)


select distinct CustomerCode,[JoinLocation_Updated]
into [Kalyan_temp].[dbo].[temp_sp_JoinLocationtransactiondata_full_20170125]
FROM [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
--where year(BillDate)<=2014


select distinct CustomerCode,[Area],[District],[State],[Pincode]
into [Kalyan_temp].[dbo].[temp_sp_Addresstransactiondata_full_20170125]
FROM [Kalyan_Master].[dbo].[tbl_Master_Capillary_JuelTransInfo]
--where year(BillDate)<=2014



update [Kalyan_temp].[dbo].[temp_sp_Addresstransactiondata_full_20170125]
set [Area]=''
where lower(area) like '%null%' or  lower(area) like '%test%'

update [Kalyan_temp].[dbo].[temp_sp_Addresstransactiondata_full_20170125]
set [District]=''
where lower([District]) like '%null%' or  lower([District]) like '%test%'

update [Kalyan_temp].[dbo].[temp_sp_Addresstransactiondata_full_20170125]
set [State]=''
where lower([State]) like '%null%' or  lower([State]) like '%test%'

update [Kalyan_temp].[dbo].[temp_sp_Addresstransactiondata_full_20170125]
set [Pincode]=''
where lower([Pincode]) like '%null%' or  lower([Pincode]) like '%test%'

----


alter table [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125
add [JoinLocation_Updated] varchar(100),[JoinLocation_UpdatedState] varchar(100)
,[JoinDate] datetime,[MobileNumber] varchar(100),[Email] varchar(300),[ResidencePhone] varchar(100)
,[STD code] varchar(100),[Area] varchar(100)
,[District] varchar(100),[State] varchar(100),[Pincode] varchar(20)

----------------hashed value joined
update [Kalyan_temp].dbo.MobilePhoneCleaning_full_20170125
set [Mobile]=b.[MobileNumber]
from [Kalyan_temp].dbo.MobilePhoneCleaning_full_20170125 a
inner join [Kalyan_PIIHash].[dbo].[tbl_Hashedvalue_MobileNumber] b
on a.[MobileNumberHash]=b.[HashedValue]

update [Kalyan_temp].dbo.temp_sp_ResidencePhonetransactiondata_full_20170125
set [Phone]=b.[ResidencePhoneNo]
from [Kalyan_temp].dbo.temp_sp_ResidencePhonetransactiondata_full_20170125 a
inner join [Kalyan_PIIHash].dbo.tbl_Hashedvalue_ResidencePhoneNo b
on a.[ResidencePhoneNoHash]=b.[HashedValue]

update [Kalyan_temp].dbo.temp_sp_Emailfromtransactiondata_full_20170125
set [Email]=b.[EmailID]
from [Kalyan_temp].[dbo].temp_sp_Emailfromtransactiondata_full_20170125 a
inner join [Kalyan_PIIHash].[dbo].[tbl_Hashedvalue_Emailid] b
on a.[EmailIDHash]=b.[HashedValue]

------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
---------------Phone cleaning script
------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
SELECT TOP 1000 *
  FROM [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
  
  alter table 
  [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
  add [Phone Back Up] varchar (50)
  
  update   [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
  set [Phone Back Up] = [Phone]
  
  

/*----------------------Moving the Phone from raw data to destination table-----------------------*/
SELECT distinct [CustomerCode] as 'ID' ,[ResidencePhoneNo] as 'Phone',[ResidencePhoneNo] as 'Phone Back Up' into [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]  
FROM [Kalyan_Temp].[dbo].[temp_sp_consumermelamapped_20161004]
where  len([ResidencePhoneNo])>=6

--Drop table [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
 
/*-------------altering the  destination table to accomadate all the required fields-------------------*/

alter table [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]  
add [Phone Validity] varchar(100),[std code] int--,[Mobile No] bigint,[Phone 2] bigint,[Phone 1] bigint

--alter table [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]  
--drop column [Phone Validity],[std code]--,[Mobile No],[Phone 2],[Phone 1]




/*-----------cleaning the phone field of special characters and alphabets for only those records which have special characters in them--------------------------*/


----removing special characters

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'!','')  where phone like '%!%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'@','')  where phone like '%@%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'#','')  where phone like '%#%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'$','')  where phone like '%$%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'&','')  where phone like '%&%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'*','')  where phone like '%*%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'(','')  where phone like '%(%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,')','')  where phone like '%)%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'-','')  where phone like '%-%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'+','')  where phone like '%+%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'=','')  where phone like '%=%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'{','')  where phone like '%{%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'}','')  where phone like '%}%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'[','')  where phone like '%[%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,']','')  where phone like '%]%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,':','')  where phone like '%:%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,';','')  where phone like '%;%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'/','')  where phone like '%/%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'?','')  where phone like '%?%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'.','')  where phone like '%.%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,',','')  where phone like '%,%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'>','')  where phone like '%>%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'<','')  where phone like '%<%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'`','')  where phone like '%`%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'~','')  where phone like '%~%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'[','')  where phone like '%[%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
----removing alphabets

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'a','')  where phone like '%a%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'b','')  where phone like '%b%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'c','')  where phone like '%c%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'d','')  where phone like '%d%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'e','')  where phone like '%e%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'f','')  where phone like '%f%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'g','')  where phone like '%g%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'h','')  where phone like '%h%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'i','')  where phone like '%i%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'j','')  where phone like '%j%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'k','')  where phone like '%k%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'l','')  where phone like '%l%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'m','')  where phone like '%m%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'n','')  where phone like '%n%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'o','')  where phone like '%o%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'p','')  where phone like '%p%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'q','')  where phone like '%q%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'r','')  where phone like '%r%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'s','')  where phone like '%s%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'t','')  where phone like '%t%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'u','')  where phone like '%u%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'v','')  where phone like '%v%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'w','')  where phone like '%w%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'x','')  where phone like '%x%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'y','')  where phone like '%y%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'z','')  where phone like '%z%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'�','')  where phone like '%�%'

----removing extra unnecessary spaces post cleaning the special characters and alphabets

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,' ','')  where phone like '% %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'  ','')  where phone like '%  %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'   ','')  where phone like '%   %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'    ','')  where phone like '%    %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'     ','')  where phone like '%     %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'      ','')  where phone like '%      %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'       ','')  where phone like '%       %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'        ','')  where phone like '%        %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'         ','')  where phone like '%         %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set phone=replace(phone,'          ','')  where phone like '%          %'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]  set phone=replace(phone,'	','')  where phone like '%	%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]  set phone=replace(phone,'�','')  where phone like '%�%'
update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]    set [phone]=ltrim(rtrim(phone))

select [customercode],[phone]   from [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125] where [phone] like '%[^0-9]%'
--update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
--set [phone]=
--where id=

/*----------------------determining the validity of the phone numbers--------------------*/

---invalid phone numbers

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125] set [Phone Validity]='Invalid- As the length is equal to 9' where len(Phone) in (9) and [Phone Validity] is null

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [Phone Validity]='Invalid- As the data has recursive number'
where phone like '000000%' or phone like '222222%' or  phone like '111111%'or  phone like '333333%' or  phone like '444444%'
or  phone like '666666%' or  phone like '555555%' or  phone like '77777777%' or  phone like '888888%' or  phone like '99999999%'
or  phone like '12345678%' and [Phone Validity] is null

----valid phone numbers

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125] set [Phone Validity]='Valid-Landline No as the length is 6,7,8' where len(Phone) in (6,7,8) and [Phone Validity] is null

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [std code]=left(phone,2),[Phone Validity]='Valid-Landline No as the length is 10 with STD code length as 2',phone=right(phone,8)
where [phone Validity] is null and len(phone) in (10) and left(phone,2)  in (11,20,22,33,40,44,80,79)

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [std code]=left(phone,3),[Phone Validity]='Valid-Landline No as the length is 10 with STD code length as 3',phone=right(phone,7)
where [phone Validity] is null and len(phone) in (10) and left(phone,3)  in 
(120,121,122,124,129,130,131,132,135,141,144,145,151,154,160,161,164,171,172,175,177,180,181,183,184,186,191,194,212,215,217,230,231,233,241,250,251,253,257,260,261,265,268,278,281,285,286,288,291,294,326,341,342,343,353,354,360,361,364,368,369,370,372,373,374,376,381,385,389,413,416,421,422,423,424,427,431,435,451,452,461,462,469,470,471,474,475,476,477,478,479,480,481,483,484,485,487,490,491,494,495,496,497,512,515,522,532,535,542,548,551,562,565,571,581,591,595,612,621,631,641,651,657,661,663,671,674,680
,891,884,883,878,877,870,866,863,861,836,832,831,824,821,820,816,788,771,761,755,751,747,744,734,733,731,724,721,712
)

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [std code]=left(phone,4),[Phone Validity]='Valid-Landline No as the length is 10 with STD code length as 4',phone=right(phone,6)
where [phone Validity] is null and len(phone) in (10) and left(phone,4)  in 
(1232,1233,1234,1237,1250,1251,1252,1253,1254,1255,1257,1258,1259,1262,1263,1267,1268,1274,1275,1276,1281,1282,1284,1285,1331,1332,1334,1336,1341,1342,1343,1344,1345,1346,1348,1360,1363,1364,1368,1370,1371,1372,1373,1374,1375,1376,1377,1378,1379,1381,1382,1386,1389,1392,1396,1398,1420,1421,1422,1423,1424,1425,1426,1427,1428,1429,1430,1431,1432,1433,1434,1435,1436,1437,1438,1460,1461,1462,1463,1464,1465,1466,1467,1468,1469,1470,1471,1472,1473,1474,1475,1476,1477,1478,1479,1480,1481,1482,1483,1484,1485,1486,1487,1488,1489,1491,1492,1493,1494,1495,1496,1497,1498,1499,1501,1502,1503,1504,1505,1506,1507,1508,1509,1520,1521,1522,1523,1526,1527,1528,1529,1531,1532,1533,1534,1535,1536,1537,1539,1552,1555,1559,1560,1561,1562,1563,1564,1565,1566,1567,1568,1569,1570,1571,1572,1573,1574,1575,1576,1577,1580,1581,1582,1583,1584,1585,1586,1587,1588,1589,1590,1591,1592,1593,1594,1595,1596,1624,1628,1632,1633,1634,1635,1636,1637,1638,1639,1651,1652,1655,1659,1662,1663,1664,1666,1667,1668,1669,1672,1675,1676,1679,1681,1682,1683,1684,1685,1686,1692,1693,1696,1697,1698,1702,1704,1731,1732,1733,1734,1735,1741,1743,1744,1745,1746,1748,1749,1762,1763,1764,1765,1781,1782,1783,1785,1786,1792,1795,1796,1799,1821,1822,1823,1824,1826,1828,1851,1852,1853,1858,1859,1870,1871,1872,1874,1875,1881,1882,1883,1884,1885,1886,1887,1892,1893,1894,1895,1896,1897,1899,1900,1902,1903,1904,1905,1906,1907,1908,1909,1921,1922,1923,1924,1931,1932,1933,1936,1951,1952,1954,1955,1956,1957,1958,1960,1962,1964,1965,1970,1972,1975,1976,1978,1980,1981,1982,1983,1985,1990,1991,1992,1995,1996,1997,1998,1999,2111,2112,2113,2114,2115,2117,2118,2119,2130,2132,2133,2135,2136,2137,2138,2139,2140,2141,2142,2143,2144,2145,2147,2148,2149,2160,2161,2162,2163,2164,2165,2166,2167,2168,2169,2181,2182,2183,2184,2185,2186,2187,2188,2189,2191,2192,2194,2320,2321,2322,2323,2324,2325,2326,2327,2328,2329,2341,2342,2343,2344,2345,2346,2347,2350,2351,2352,2353,2354,2355,2356,2357,2358,2359,2362,2363,2364,2365,2366,2367,2371,2372,2373,2375,2378,2381,2382,2383,2384,2385,2421,2422,2423,2424,2425,2426,2427,2428,2429,2430,2431,2432,2433,2435,2436,2437,2438,2439,2441,2442,2443,2444,2445,2446,2447,2451,2452,2453,2454,2455,2456,2457,2460,2461,2462,2463,2465,2466,2467,2468,2469,2471,2472,2473,2475,2477,2478,2481,2482,2483,2484,2485,2487,2488,2489,2520,2521,2522,2524,2525,2526,2527,2528,2529,2550,2551,2552,2553,2554,2555,2556,2557,2558,2559,2560,2561,2562,2563,2564,2565,2566,2567,2568,2569,2580,2582,2583,2584,2585,2586,2587,2588,2589,2591,2592,2593,2594,2595,2596,2597,2598,2599,2621,2622,2623,2624,2625,2626,2628,2629,2630,2631,2632,2633,2634,2637,2640,2641,2642,2643,2644,2645,2646,2649,2661,2662,2663,2664,2665,2666,2667,2668,2669,2670,2672,2673,2674,2675,2676,2677,2678,2679,2690,2691,2692,2694,2696,2697,2698,2699,2711,2712,2713,2714,2715,2716,2717,2718,2733,2734,2735,2737,2738,2739,2740,2742,2744,2746,2747,2748,2749,2751,2752,2753,2754,2755,2756,2757,2758,2759,2761,2762,2763,2764,2765,2766,2767,2770,2771,2772,2773,2774,2775,2778,2779,2791,2792,2793,2794,2795,2796,2797,2801,2803,2804,2806,2808,2820,2821,2822,2823,2824,2825,2826,2827,2828,2829,2830,2831,2832,2833,2834,2835,2836,2837,2838,2839,2841,2842,2843,2844,2845,2846,2847,2848,2849,2870,2871,2872,2873,2874,2875,2876,2877,2878,2891,2892,2893,2894,2895,2896,2897,2898,2900,2901,2902,2903,2904,2905,2906,2907,2908,2909,2920,2921,2922,2923,2924,2925,2926,2927,2928,2929,2930,2931,2932,2933,2934,2935,2936,2937,2938,2939,2950,2951,2952,2953,2954,2955,2956,2957,2958,2959,2960,2961,2962,2963,2964,2965,2966,2967,2968,2969,2970,2971,2972,2973,2974,2975,2976,2977,2978,2979,2980,2981,2982,2983,2984,2985,2986,2987,2988,2989,2990,2991,2992,2993,2994,2995,2996,2997,2998,2999,3010,3011,3012,3013,3014,3015,3016,3017,3018,3019,3174,3192,3193,3210,3211,3212,3213,3214,3215,3216,3217,3218,3220,3221,3222,3223,3224,3225,3227,3228,3229,3241,3242,3243,3244,3251,3252,3253,3254,3451,3452,3453,3454,3461,3462,3463,3465,3471,3472,3473,3474,3481,3482,3483,3484,3485,3511,3512,3513,3521,3522,3523,3524,3525,3526,3552,3561,3562,3563,3564,3565,3566,3581,3582,3583,3584,3592,3595,3621,3623,3624,3637,3638,3639,3650,3651,3652,3653,3654,3655,3656,3657,3658,3659,3661,3662,3663,3664,3665,3666,3667,3668,3669,3670,3671,3672,3673,3674,3675,3676,3677,3678,3711,3712,3713,3714,3715,3751,3752,3753,3754,3756,3758,3759,3771,3772,3774,3775,3776,3777,3778,3779,3780,3782,3783,3784,3785,3786,3787,3788,3789,3790,3791,3792,3793,3794,3795,3797,3798,3799,3800,3801,3802,3803,3804,3805,3806,3807,3808,3809,3821,3822,3823,3824,3825,3826,3830,3831,3834,3835,3836,3837,3838,3839,3841,3842,3843,3844,3845,3848,3860,3861,3862,3863,3865,3867,3869,3870,3871,3872,3873,3874,3876,3877,3878,3879,3880,4111,4112,4114,4115,4116,4118,4119,4142,4143,4144,4145,4146,4147,4149,4151,4153,4171,4172,4173,4174,4175,4177,4179,4181,4182,4183,4188,4202,4204,4252,4253,4254,4255,4256,4257,4258,4259,4262,4266,4268,4281,4282,4283,4285,4286,4287,4288,4290,4292,4294,4295,4296,4298,4320,4322,4323,4324,4326,4327,4328,4329,4331,4332,4333,4339,4341,4342,4343,4344,4346,4347,4348,4362,4364,4365,4366,4367,4368,4369,4371,4372,4373,4374,4542,4543,4544,4545,4546,4549,4551,4552,4553,4554,4561,4562,4563,4564,4565,4566,4567,4573,4574,4575,4576,4577,4630,4632,4633,4634,4635,4636,4637,4638,4639,4651,4652,4728,4733,4734,4735,4822,4828,4829,4862,4864,4865,4868,4869,4884,4885,4890,4891,4892,4893,4894,4895,4896,4897,4898,4899,4922,4923,4924,4926,4931,4933,4935,4936,4982,4985,4994,4997,4998,5111,5112,5113,5114,5115,5142,5143,5144,5162,5164,5165,5168,5170,5171,5172,5174,5175,5176,5178,5180,5181,5182,5183,5190,5191,5192,5194,5195,5198,5212,5240,5241,5244,5248,5250,5251,5252,5253,5254,5255,5260,5261,5262,5263,5264,5265,5270,5271,5273,5274,5275,5278,5280,5281,5282,5283,5284,5311,5313,5315,5317,5331,5332,5333,5334,5335,5341,5342,5343,5361,5362,5364,5368,5412,5413,5414,5440,5442,5443,5444,5445,5446,5447,5450,5451,5452,5453,5454,5460,5461,5462,5463,5464,5465,5466,5491,5493,5494,5495,5496,5497,5498,5521,5522,5523,5524,5525,5541,5542,5543,5544,5545,5546,5547,5548,5561,5563,5564,5566,5567,5568,5612,5613,5614,5640,5641,5642,5643,5644,5645,5646,5647,5648,5661,5662,5664,5671,5672,5673,5676,5677,5680,5681,5683,5688,5690,5691,5692,5694,5721,5722,5723,5724,5731,5732,5733,5734,5735,5736,5738,5740,5742,5744,5745,5821,5822,5823,5824,5825,5831,5832,5833,5834,5836,5841,5842,5843,5844,5850,5851,5852,5853,5854,5855,5861,5862,5863,5864,5865,5870,5871,5872,5873,5874,5875,5876,5880,5881,5882,5921,5922,5923,5924,5942,5943,5944,5945,5946,5947,5948,5949,5960,5961,5962,5963,5964,5965,5966,5967,6111,6112,6114,6115,6132,6135,6150,6151,6152,6153,6154,6155,6156,6157,6158,6159,6180,6181,6182,6183,6184,6185,6186,6187,6188,6189,6222,6223,6224,6226,6227,6228,6229,6242,6243,6244,6245,6246,6247,6250,6251,6252,6253,6254,6255,6256,6257,6258,6259,6271,6272,6273,6274,6275,6276,6277,6278,6279,6322,6323,6324,6325,6326,6327,6328,6331,6332,6336,6337,6341,6342,6344,6345,6346,6347,6348,6349,6420,6421,6422,6423,6424,6425,6426,6427,6428,6429,6431,6432,6433,6434,6435,6436,6437,6438,6451,6452,6453,6454,6455,6457,6459,6461,6462,6466,6467,6471,6473,6475,6476,6477,6478,6479,6522,6523,6524,6525,6526,6527,6528,6529,6530,6531,6532,6533,6534,6535,6536,6538,6539,6540,6541,6542,6543,6544,6545,6546,6547,6548,6549,6550,6551,6553,6554,6556,6557,6558,6559,6560,6561,6562,6563,6564,6565,6566,6567,6568,6569,6581,6582,6583,6584,6585,6586,6587,6588,6589,6591,6593,6594,6596,6597,6621,6622,6624,6625,6626,6640,6641,6642,6643,6644,6645,6646,6647,6648,6649,6651,6652,6653,6654,6655,6657,6670,6671,6672,6673,6675,6676,6677,6678,6679,6681,6682,6683,6684,6685,6721,6722,6723,6724,6725,6726,6727,6728,6729,6731,6732,6733,6735,6752,6753,6755,6756,6757,6758,6760,6761,6762,6763,6764,6765,6766,6767,6768,6769,6781,6782,6784,6786,6788,6791,6792,6793,6794,6795,6796,6797,6810,6811,6814,6815,6816,6817,6818,6819,6821,6822,6840,6841,6842,6843,6844,6845,6846,6847,6848,6849,6850,6852,6853,6854,6855,6856,6857,6858,6859,6860,6861,6862,6863,6864,6865,6866,6867,6868,6869
,8966,8965,8964,8963,8952,8947,8946,8945,8944,8942,8941,8938,8937,8936,8935,8934,8933,8932,8931,8924,8922,8869,8868,8865,8864,8863,8862,8857,8856,8855,8854,8852,8829,8823,8821,8819,8818,8816,8814,8813,8812,8811,8761,8753,8752,8751,8749,8748,8747,8746,8745,8744,8743,8742,8741,8740,8739,8738,8737,8736,8735,8734,8733,8732,8731,8730,8729,8728,8727,8725,8724,8723,8721,8720,8719,8718,8717,8716,8715,8713,8711,8710,8694,8693,8692,8691,8689,8685,8684,8683,8682,8681,8680,8678,8677,8676,8674,8673,8672,8671,8659,8656,8654,8649,8648,8647,8646,8645,8644,8643,8642,8641,8640,8629,8628,8627,8626,8625,8624,8623,8622,8621,8620,8599,8598,8596,8594,8593,8592,8589,8588,8587,8586,8585,8584,8583,8582,8581,8579,8578,8577,8576,8573,8572,8571,8570,8569,8568,8567,8566,8565,8564,8563,8562,8561,8560,8559,8558,8557,8556,8554,8552,8551,8550,8549,8548,8546,8545,8543,8542,8541,8540,8539,8538,8537,8536,8535,8534,8533,8532,8531,8525,8524,8523,8522,8520,8519,8518,8517,8516,8515,8514,8513,8512,8510,8506,8505,8504,8503,8502,8501,8499,8498,8497,8496,8495,8494,8493,8492,8491,8490,8488,8487,8485,8484,8483,8482,8481,8479,8478,8477,8476,8475,8474,8473,8472,8471,8470,8468,8467,8466,8465,8464,8463,8462,8461,8458,8457,8456,8455,8454,8452,8451,8450,8444,8443,8442,8441,8440,8426,8425,8424,8422,8419,8418,8417,8416,8415,8414,8413,8412,8411,8408,8407,8406,8405,8404,8403,8402,8399,8398,8397,8396,8395,8394,8393,8392,8391,8389,8388,8387,8386,8385,8384,8383,8382,8381,8380,8379,8378,8377,8376,8375,8373,8372,8371,8370,8359,8358,8357,8356,8355,8354,8353,8352,8351,8350,8346,8345,8343,8342,8339,8338,8337,8336,8335,8334,8333,8332,8331,8330,8304,8301,8289,8288,8284,8283,8282,8276,8274,8272,8267,8266,8265,8263,8262,8261,8259,8258,8257,8256,8255,8254,8253,8251,8236,8234,8232,8231,8230,8229,8228,8227,8226,8225,8224,8223,8222,8221,8199,8198,8196,8195,8194,8193,8192,8191,8190,8189,8188,8187,8186,8185,8184,8183,8182,8181,8180,8177,8176,8175,8174,8173,8172,8170,8159,8158,8157,8156,8155,8154,8153,8152,8151,8150,8139,8138,8137,8136,8135,8134,8133,8132,8131,8119,8118,8117,8113,8111,8110,7868,7867,7866,7865,7864,7863,7862,7861,7859,7858,7857,7856,7855,7854,7853,7852,7851,7850,7849,7848,7847,7846,7844,7843,7841,7840,7836,7835,7834,7833,7832,7831,7826,7825,7824,7823,7822,7821,7820,7819,7818,7817,7816,7815,7813,7812,7811,7810,7806,7805,7804,7803,7802,7801,7794,7793,7792,7791,7790,7789,7788,7787,7786,7785,7784,7783,7782,7781,7779,7778,7777,7776,7775,7774,7773,7772,7771,7770,7769,7768,7767,7766,7765,7764,7763,7762,7761,7759,7758,7757,7756,7755,7754,7753,7752,7751,7750,7749,7748,7747,7746,7745,7744,7743,7741,7740,7734,7733,7732,7731,7730,7729,7728,7727,7726,7725,7724,7723,7722,7721,7720,7707,7706,7705,7704,7703,7701,7700,7695,7694,7693,7692,7691,7690,7689,7688,7687,7686,7685,7684,7683,7682,7681,7680,7675,7674,7673,7672,7671,7670,7664,7663,7662,7661,7660,7659,7658,7657,7656,7655,7653,7652,7651,7650,7649,7648,7647,7646,7645,7644,7643,7642,7641,7640,7638,7637,7636,7635,7634,7633,7632,7630,7629,7628,7627,7626,7625,7624,7623,7622,7621,7609,7608,7606,7605,7604,7603,7601,7596,7595,7594,7593,7592,7591,7590,7586,7585,7584,7583,7582,7581,7580,7578,7577,7576,7575,7574,7573,7572,7571,7570,7565,7564,7563,7562,7561,7560,7548,7547,7546,7545,7544,7543,7542,7541,7540,7539,7538,7537,7536,7535,7534,7533,7532,7531,7530,7529,7528,7527,7526,7525,7524,7523,7522,7521,7497,7496,7495,7494,7493,7492,7491,7490,7487,7486,7485,7484,7482,7481,7480,7469,7468,7467,7466,7465,7464,7463,7462,7461,7460,7459,7458,7457,7456,7455,7454,7453,7452,7451,7450,7438,7437,7436,7435,7434,7433,7432,7431,7430,7427,7426,7425,7424,7423,7422,7421,7420,7414,7413,7412,7410,7395,7394,7393,7392,7391,7390,7375,7374,7372,7371,7370,7369,7368,7367,7366,7365,7364,7363,7362,7361,7360,7329,7328,7327,7326,7325,7324,7323,7322,7321,7320,7297,7296,7295,7294,7292,7291,7290,7289,7288,7287,7286,7285,7284,7283,7282,7281,7280,7279,7274,7273,7272,7271,7270,7269,7268,7267,7266,7265,7264,7263,7262,7261,7260,7258,7257,7256,7255,7254,7253,7252,7251,7239,7238,7237,7236,7235,7234,7233,7232,7231,7230,7229,7228,7227,7226,7225,7224,7223,7222,7221,7220,7203,7202,7201,7199,7198,7197,7196,7189,7187,7186,7185,7184,7183,7182,7181,7180,7179,7178,7177,7176,7175,7174,7173,7172,7171,7170,7169,7168,7167,7166,7165,7164,7162,7161,7160,7158,7157,7156,7155,7153,7152,7151,7149,7148,7147,7146,7145,7144,7143,7142,7141,7139,7138,7137,7136,7135,7134,7133,7132,7131,7118,7116,7115,7114,7113,7112,7109,7106,7105,7104,7103,7102,7100
)


update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [std code]=left(phone,3),[Phone Validity]='Valid-Landline No as the length is 11 with STD code length as 2',phone=right(phone,8)
where [phone Validity] is null and len(phone) in (11) and left(phone,3)  in (080,079,044,040,033,022,020,011)

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [std code]=left(phone,4),[Phone Validity]='Valid-Landline No as the length is 11 with STD code length as 3',phone=right(phone,7)
where [phone Validity] is null and len(phone) in (11) and left(phone,4)  in 
(0891,0884,0883,0878,0877,0870,0866,0863,0861,0836,0832,0831,0824,0821,0820,0816,0788,0771,0761,0755,0751,0747,0744,0734,0733,0731,0724,0721,0712,0680,0674,0671,0663,0661,0657,0651,0641,0631,0621,0612,0595,0591,0581,0571,0565,0562,0551,0548,0542,0535,0532,0522
,0515,0512,0497,0496,0495,0494,0491,0490,0487,0485,0484,0483,0481,0480,0479,0478,0477,0476,0475,0474,0471,0470,0469,0462,0461,0452,0451,0435,0431,0427,0424,0423,0422,0421,0416,0413,0389,0385,0381,0376,0374,0373,0372,0370,0369,0368,0364,0361,0360,0354,0353,0343,0342,0341,0326,0294,0291,0288,0286,0285,0281,0278,0268,0265,0261,0260,0257,0253,0251,0250,0241,0233,0231,0230,0217,0215,0212
,0194,0191,0186,0184,0183,0181,0180,0177,0175,0172,0171,0164,0161,0160,0154,0151,0145,0144,0141,0135,0132,0131,0130,0129,0124,0122,0121,0120
)

update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [std code]=left(phone,5),[Phone Validity]='Valid-Landline No as the length is 11 with STD code length as 4',phone=right(phone,6)
where [phone Validity] is null and len(phone) in (11) and left(phone,5)  in 
(
03638,03637,03624,03623,03621,03595,03592,03584,03583,03582,03581,03566,03565,03564,03563,03562,03561,03552,03526,03525,03524,03523,03522,03521,03513,03512,03511,03485,03484,03483,03482,03481,03474,03473,03472,03471,03465,03463,03462,03461,03454,03453,03452,03451,03254,03253,03252,03251,03244,03243,03242,03241,03229,03228,03227,03225,03224,03223,03222,03221,03220,03218,03217,03216,03215,03214,03213,03212,03211,03210,03193,03192,03174,03019,03018,03017
,03016,03015,03014,03013,03012,03011,03010,02999,02998,02997,02996,02995,02994,02993,02992,02991,02990,02989,02988,02987,02986,02985,02984,02983,02982,02981,02980,02979,02978,02977,02976,02975,02974,02973,02972,02971,02970,02969,02968,02967,02966,02965,02964,02963,02962,02961,02960,02959,02958,02957,02956,02955,02954,02953,02952,02951,02950,02939,02938,02937,02936,02935,02934,02933,02932,02931,02930,02929,02928,02927,02926,02925,02924,02923,02922,02921,02920
,02909,02908,02907,02906,02905,02904,02903,02902,02901,02900,02898,02897,02896,02895,02894,02893,02892,02891,02878,02877
,02876,02875,02874,02873,02872,02871,02870,02849,02848,02847,02846,02845,02844,02843,02842,02841,02839,02838,02837,02836,02835,02834,02833,02832,02831,02830,02829,02828,02827,02826,02825,02824,02823,02822,02821,02820,02808,02806,02804,02803,02801,02797,02796,02795,02794,02793,02792,02791,02779,02778,02775,02774,02773,02772,02771,02770,02767,02766,02765,02764,02763,02762,02761,02759,02758,02757,02756,02755,02754,02753,02752,02751,02749,02748,02747,02746,02744,02742,02740,02739,02738,02737,02735,02734,02733,02718,02717,02716,02715,02714,02713,02712,02711,02699,02698,02697,02696,02694,02692,02691,02690,02679,02678,02677,02676,02675,02674,02673,02672,02670,02669,02668,02667,02666,02665,02664,02663,02662,02661,02649,02646,02645,02644,02643,02642,02641,02640,02637,02634,02633,02632,02631,02630,02629,02628,02626,02625,02624,02623,02622,02621,02599,02598,02597,02596,02595,02594,02593,02592,02591,02589,02588,02587,02586,02585,02584,02583,02582,02580,02569,02568,02567,02566,02565,02564,02563,02562,02561,02560,02559,02558,02557,02556,02555,02554,02553,02552,02551,02550,02529,02528,02527,02526,02525,02524,02522,02521,02520,02489,02488,02487,02485,02484,02483,02482,02481,02478,02477,02475,02473,02472,02471,02469,02468,02467,02466,02465,02463,02462,02461,02460,02457,02456,02455,02454,02453,02452,02451,02447,02446,02445,02444,02443,02442,02441,02439,02438,02437,02436,02435,02433,02432,02431,02430,02429,02428,02427,02426,02425,02424,02423,02422,02421,02385,02384,02383,02382,02381,02378,02375,02373,02372,02371,02367,02366,02365,02364,02363,02362,02359,02358,02357,02356,02355,02354,02353,02352,02351,02350,02347,02346,02345,02344,02343,02342,02341,02329,02328,02327,02326,02325,02324,02323,02322,02321,02320,02194,02192,02191,02189,02188,02187,02186,02185,02184,02183,02182,02181,02169,02168,02167,02166,02165,02164,02163,02162,02161,02160,02149,02148,02147,02145,02144,02143,02142,02141,02140,02139,02138,02137,02136,02135,02133,02132,02130,02119,02118,02117,02115,02114,02113,02112,02111,01999,01998,01997,01996,01995,01992,01991,01990,01985,01983,01982,01981,01980,01978,01976,01975,01972,01970,01965,01964,01962,01960,01958,01957,01956,01955,01954,01952,01951,01936,01933,01932,01931,01924,01923,01922,01921,01909,01908,01907,01906,01905,01904,01903,01902,01900,01899,01897,01896,01895,01894,01893,01892,01887,01886,01885,01884,01883,01882,01881,01875,01874,01872,01871,01870,01859,01858,01853,01852,01851,01828,01826,01824,01823,01822,01821,01799,01796,01795,01792,01786,01785,01783,01782,01781,01765,01764,01763,01762,01749,01748,01746,01745,01744,01743,01741,01735,01734,01733,01732,01731,01704,01702,01698,01697,01696,01693,01692,01686,01685,01684,01683,01682,01681,01679,01676,01675,01672,01669,01668,01667,01666,01664,01663,01662,01659,01655,01652,01651,01639,01638,01637,01636,01635,01634,01633,01632,01628,01624,01596,01595,01594,01593,01592,01591,01590,01589,01588,01587,01586,01585,01584,01583,01582,01581,01580,01577,01576,01575,01574,01573,01572,01571,01570,01569,01568,01567,01566,01565,01564,01563,01562,01561,01560,01559,01555,01552,01539,01537,01536,01535,01534,01533,01532,01531,01529,01528,01527,01526,01523,01522,01521,01520,01509,01508,01507,01506,01505,01504,01503,01502,01501,01499,01498,01497,01496,01495,01494,01493,01492,01491,01489,01488,01487,01486,01485,01484,01483,01482,01481,01480,01479,01478,01477,01476,01475,01474,01473,01472,01471,01470,01469,01468,01467,01466,01465,01464,01463,01462,01461,01460,01438,01437,01436,01435,01434,01433,01432,01431,01430,01429,01428,01427,01426,01425,01424,01423,01422,01421,01420,01398,01396,01392,01389,01386,01382,01381,01379,01378,01377,01376,01375,01374,01373,01372,01371,01370,01368,01364,01363,01360,01348,01346,01345,01344,01343,01342,01341,01336,01334,01332,01331,01285,01284,01282,01281,01276,01275,01274,01268,01267,01263,01262,01259,01258,01257,01255,01254,01253,01252,01251,01250,01237,01234,01233,01232,08966,08965,08964,08963,08952,08947,08946,08945,08944,08942,08941,08938,08937,08936,08935,08934,08933,08932,08931,08924,08922,08869,08868,08865,08864,08863,08862,08857,08856,08855,08854,08852,08829,08823,08821,08819,08818,08816,08814,08813,08812,08811,08761,08753,08752,08751,08749,08748,08747,08746,08745,08744,08743,08742,08741,08740,08739,08738,08737,08736,08735,08734,08733,08732,08731,08730,08729,08728,08727,08725,08724,08723,08721,08720,08719,08718,08717,08716,08715,08713,08711,08710,08694,08693,08692,08691,08689,08685,08684,08683,08682,08681,08680,08678,08677,08676,08674,08673,08672,08671,08659,08656,08654,08649,08648,08647,08646,08645,08644,08643,08642,08641,08640,08629,08628,08627,08626,08625,08624,08623,08622,08621,08620,08599,08598,08596,08594,08593,08592,08589,08588,08587,08586,08585,08584,08583,08582,08581,08579,08578,08577,08576,08573,08572,08571,08570,08569,08568,08567,08566,08565,08564,08563,08562,08561,08560,08559,08558,08557,08556,08554,08552,08551,08550,08549,08548,08546,08545,08543,08542,08541,08540,08539,08538,08537,08536,08535,08534,08533,08532,08531,08525,08524,08523,08522,08520,08519,08518,08517,08516,08515,08514,08513,08512,08510,08506,08505,08504,08503,08502,08501,08499,08498,08497,08496,08495,08494,08493,08492,08491,08490,08488,08487,08485,08484,08483,08482,08481,08479,08478,08477,08476,08475,08474,08473,08472,08471,08470,08468,08467,08466,08465,08464,08463,08462,08461,08458,08457,08456,08455,08454,08452,08451,08450,08444,08443,08442,08441,08440,08426,08425,08424,08422,08419,08418,08417,08416,08415,08414,08413,08412,08411,08408,08407,08406,08405,08404,08403,08402,08399,08398,08397,08396,08395,08394,08393,08392,08391,08389,08388,08387,08386,08385,08384,08383,08382,08381,08380,08379,08378,08377,08376,08375,08373,08372,08371,08370,08359,08358,08357,08356,08355,08354,08353,08352,08351,08350,08346,08345,08343,08342,08339,08338,08337,08336,08335,08334,08333,08332,08331,08330,08304,08301,08289,08288,08284,08283,08282,08276,08274,08272,08267,08266,08265,08263,08262,08261,08259,08258,08257,08256,08255,08254,08253,08251,08236,08234,08232,08231,08230,08229,08228,08227,08226,08225,08224,08223,08222,08221,08199,08198,08196,08195,08194,08193,08192,08191,08190,08189,08188,08187,08186,08185,08184,08183,08182,08181,08180,08177,08176,08175,08174,08173,08172,08170,08159,08158,08157,08156,08155,08154,08153,08152,08151,08150,08139,08138,08137,08136,08135,08134,08133,08132,08131,08119,08118,08117,08113,08111,08110,07868,07867,07866,07865,07864,07863,07862,07861,07859,07858,07857,07856,07855,07854,07853,07852,07851,07850,07849,07848,07847,07846,07844,07843,07841,07840,07836,07835,07834,07833,07832,07831,07826,07825,07824,07823,07822,07821,07820,07819,07818,07817,07816,07815,07813,07812,07811,07810,07806,07805,07804,07803,07802,07801,07794,07793,07792,07791,07790,07789,07788,07787,07786,07785,07784,07783,07782,07781,07779,07778,07777,07776,07775,07774,07773,07772,07771,07770,07769,07768,07767,07766,07765,07764,07763,07762,07761,07759,07758,07757,07756,07755,07754,07753,07752,07751,07750,07749,07748,07747,07746,07745,07744,07743,07741,07740,07734,07733,07732,07731,07730,07729,07728,07727,07726,07725,07724,07723,07722,07721,07720,07707,07706,07705,07704,07703,07701,07700,07695,07694,07693,07692,07691,07690,07689,07688,07687,07686,07685,07684,07683,07682,07681,07680,07675,07674,07673,07672,07671,07670,07664,07663,07662,07661,07660,07659,07658,07657,07656,07655,07653,07652,07651,07650,07649,07648,07647,07646,07645,07644,07643,07642,07641,07640,07638,07637,07636,07635,07634,07633,07632,07630,07629,07628,07627,07626,07625,07624,07623,07622,07621,07609,07608,07606,07605,07604,07603,07601,07596,07595,07594,07593,07592,07591,07590,07586,07585,07584,07583,07582,07581,07580,07578,07577,07576,07575,07574,07573,07572,07571,07570,07565,07564,07563,07562,07561,07560,07548,07547,07546,07545,07544,07543,07542,07541,07540,07539,07538,07537,07536,07535,07534,07533,07532,07531,07530,07529,07528,07527,07526,07525,07524,07523,07522,07521,07497,07496,07495,07494,07493,07492,07491,07490,07487,07486,07485,07484,07482,07481,07480,07469,07468,07467,07466,07465,07464,07463,07462,07461,07460,07459,07458,07457,07456,07455,07454,07453,07452,07451,07450,07438,07437,07436,07435,07434,07433,07432,07431,07430,07427,07426,07425,07424,07423,07422,07421,07420,07414,07413,07412,07410,07395,07394,07393,07392,07391,07390,07375,07374,07372,07371,07370,07369,07368,07367,07366,07365,07364,07363,07362,07361,07360,07329,07328,07327,07326,07325,07324,07323,07322,07321,07320,07297,07296,07295,07294,07292,07291,07290,07289,07288,07287,07286,07285,07284,07283,07282,07281,07280,07279,07274,07273,07272,07271,07270,07269,07268,07267,07266,07265,07264,07263,07262,07261,07260,07258,07257,07256,07255,07254,07253,07252,07251,07239,07238,07237,07236,07235,07234,07233,07232,07231,07230,07229,07228,07227,07226,07225,07224,07223,07222,07221,07220,07203,07202,07201,07199,07198,07197,07196,07189,07187,07186,07185,07184,07183,07182,07181,07180,07179,07178,07177,07176,07175,07174,07173,07172,07171,07170,07169,07168,07167,07166,07165,07164,07162,07161,07160,07158,07157,07156,07155,07153,07152,07151,07149,07148,07147,07146,07145,07144,07143,07142,07141,07139,07138,07137,07136,07135,07134,07133,07132,07131,07118,07116,07115,07114,07113,07112,07109,07106,07105,07104,07103,07102,07100,06869,06868,06867,06866,06865,06864,06863,06862,06861,06860,06859,06858,06857,06856,06855,06854,06853,06852,06850,06849,06848,06847,06846,06845,06844,06843,06842,06841,06840,06822,06821,06819,06818,06817,06816,06815,06814,06811,06810,06797,06796,06795,06794,06793,06792,06791,06788,06786,06784,06782,06781,06769,06768,06767,06766,06765,06764,06763,06762,06761,06760,06758,06757,06756,06755,06753,06752,06735,06733,06732,06731,06729,06728,06727,06726,06725,06724,06723,06722,06721,06685,06684,06683,06682,06681,06679,06678,06677,06676,06675,06673,06672,06671,06670,06657,06655,06654,06653,06652,06651,06649,06648,06647,06646,06645,06644,06643,06642,06641,06640,06626,06625,06624,06622,06621,06597,06596,06594,06593,06591,06589,06588,06587,06586,06585,06584,06583,06582,06581,06569,06568,06567,06566,06565,06564,06563,06562,06561,06560,06559,06558,06557,06556,06554,06553,06551,06550,06549,06548,06547,06546,06545,06544,06543,06542,06541,06540,06539,06538,06536,06535,06534,06533,06532,06531,06530,06529,06528,06527,06526,06525,06524,06523,06522,06479,06478,06477,06476,06475,06473,06471,06467,06466,06462,06461,06459,06457,06455,06454,06453,06452,06451,06438,06437,06436,06435,06434,06433,06432,06431,06429,06428,06427,06426,06425,06424,06423,06422,06421,06420,06349,06348,06347,06346,06345,06344,06342,06341,06337,06336,06332,06331,06328,06327,06326,06325,06324,06323,06322,06279,06278,06277,06276,06275,06274,06273,06272,06271,06259,06258,06257,06256,06255,06254,06253,06252,06251,06250,06247,06246,06245,06244,06243,06242,06229,06228,06227,06226,06224,06223,06222,06189,06188,06187,06186,06185,06184,06183,06182,06181,06180,06159,06158,06157,06156,06155,06154,06153,06152,06151,06150,06135,06132,06115,06114,06112,06111,05967,05966,05965,05964,05963,05962,05961,05960,05949,05948,05947,05946,05945,05944,05943,05942,05924,05923,05922,05921,05882,05881,05880,05876,05875,05874,05873,05872,05871,05870,05865,05864,05863,05862,05861,05855,05854,05853,05852,05851,05850,05844,05843,05842,05841,05836,05834,05833,05832,05831,05825,05824,05823,05822,05821,05745,05744,05742,05740,05738,05736,05735,05734,05733,05732,05731,05724,05723,05722,05721,05694,05692,05691,05690,05688,05683,05681,05680,05677,05676,05673,05672,05671,05664,05662,05661,05648,05647,05646,05645,05644,05643,05642,05641,05640,05614,05613,05612,05568,05567,05566,05564,05563,05561,05548,05547,05546,05545,05544,05543,05542,05541,05525,05524,05523,05522,05521,05498,05497,05496,05495,05494,05493,05491,05466,05465,05464,05463,05462,05461,05460,05454,05453,05452,05451,05450,05447,05446,05445,05444,05443,05442,05440,05414,05413,05412,05368,05364,05362,05361,05343,05342,05341,05335,05334,05333,05332,05331,05317,05315,05313,05311,05284,05283,05282,05281,05280,05278,05275,05274,05273,05271,05270,05265,05264,05263,05262,05261,05260,05255,05254,05253,05252,05251,05250,05248,05244,05241,05240,05212,05198,05195,05194,05192,05191,05190,05183,05182,05181,05180,05178,05176,05175,05174,05172,05171,05170,05168,05165,05164,05162,05144,05143,05142,05115,05114,05113,05112,05111,04998,04997,04994,04985,04982,04936,04935,04933,04931,04926,04924,04923,04922,04899,04898,04897,04896,04895,04894,04893,04892,04891,04890,04885,04884,04869,04868,04865,04864,04862,04829,04828,04822,04735,04734,04733,04728,04652,04651,04639,04638,04637,04636,04635,04634,04633,04632,04630,04577,04576,04575,04574,04573,04567,04566,04565,04564,04563,04562,04561,04554,04553,04552,04551,04549,04546,04545,04544,04543,04542,04374,04373,04372,04371,04369,04368,04367,04366,04365,04364,04362,04348,04347,04346,04344,04343,04342,04341,04339,04333,04332,04331,04329,04328,04327,04326,04324,04323,04322,04320,04298,04296,04295,04294,04292,04290,04288,04287,04286,04285,04283,04282,04281,04268,04266,04262,04259,04258,04257,04256,04255,04254,04253,04252,04204,04202,04188,04183,04182,04181,04179,04177,04175,04174,04173,04172,04171,04153,04151,04149,04147,04146,04145,04144,04143,04142,04119,04118,04116,04115,04114,04112,04111,03880,03879,03878,03877,03876,03874,03873,03872,03871,03870,03869,03867,03865,03863,03862,03861,03860,03848,03845,03844,03843,03842,03841,03839,03838,03837,03836,03835,03834,03831,03830,03826,03825,03824,03823,03822,03821,03809,03808,03807,03806,03805,03804,03803,03802,03801,03800,03799,03798,03797,03795,03794,03793,03792,03791,03790,03789,03788,03787,03786,03785,03784,03783,03782,03780,03779,03778,03777,03776,03775,03774,03772,03771,03759,03758,03756,03754,03753,03752,03751,03715,03714,03713,03712,03711,03678,03677,03676,03675,03674,03673,03672,03671,03670,03669,03668,03667,03666,03665,03664,03663,03662,03661,03659,03658,03657,03656,03655,03654,03653,03652,03651,03650,03639
)



update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [STD code]=right(left([phone],4),2) ,[Phone Validity]='Valid-Landline No as the length is 12 with STD code length as 2',phone=right([phone],8)
where [phone Validity] is null and len(phone) in (12) and left(phone,4)  in (9111,9120,9122,9133,9140,9144,9180,9179)


update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [STD code]=right(left([phone],5),3) ,[Phone Validity]='Valid-Landline No as the length is 12 with STD code length as 3',[phone]=right([phone],7)
where [phone Validity] is null  and len(phone) in (12) and left(phone,5)  in 
(91120,91121,91122,91124,91129,91130,91131,91132,91135,91141,91144,91145,91151,91154,91160,91161,91164,91171,91172,91175,91177,91180,91181
,91183,91184,91186,91191,91194,91212,91215,91217,91230,91231,91233,91241,91250,91251,91253,91257,91260,91261,91265,91268,91278,91281,91285,91286,91288,91291,91294,91326,91341,91342,91343,91353,91354,91360,91361,91364,91368,91369,91370,91372,91373,91374,91376,91381,91385,91389,91413,91416,91421,91422,91423,91424,91427,91431,91435,91451,91452,91461,91462,91469,91470,91471,91474,91475,91476,91477,91478,91479,91480,91481,91483,91484,91485,91487,91490,91491,91494,91495,91496,91497,91512,91515,91522,91532,91535,91542,91548,91551,91562,91565,91571,91581,91591,91595,91612,91621,91631,91641,91651,91657,91661,91663,91671,91674,91680
,91891,91884,91883,91878,91877,91870,91866,91863,91861,91836,91832,91831,91824,91821,91820,91816,91788,91771,91761,91755,91751,91747,91744,91734,91733,91731,91724,91721,91712
)


update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [STD code]=right(left([phone],6),4) ,[Phone Validity]='Valid-Landline No as the length is 12 with STD code length as 4',[phone]=right([phone],6)
where [phone Validity] is null and  len(phone) in (12) and left(phone,6)  in 
(911232,911233,911234,911237,911250,911251,911252,911253,911254,911255,911257,911258,911259,911262,911263,911267,911268,911274,911275,911276,911281,911282,911284,911285,911331,911332,911334,911336,911341,911342,911343,911344,911345,911346,911348,911360,911363,911364,911368,911370,911371,911372,911373,911374,911375,911376,911377,911378,911379,911381,911382,911386,911389,911392,911396,911398,911420,911421,911422,911423,911424,911425,911426,911427,911428,911429,911430,911431,911432,911433,911434,911435,911436,911437,911438,911460,911461,911462,911463,911464,911465,911466,911467,911468,911469,911470,911471,911472,911473,911474,911475,911476,911477,911478,911479,911480,911481,911482,911483,911484,911485,911486,911487,911488,911489,911491,911492,911493,911494,911495,911496,911497,911498,911499,911501,911502,911503,911504,911505,911506,911507,911508,911509,911520,911521,911522,911523,911526,911527,911528,911529,911531,911532,911533,911534,911535,911536,911537,911539,911552,911555,911559,911560,911561,911562,911563,911564,911565,911566,911567,911568,911569,911570,911571,911572,911573,911574,911575,911576,911577,911580,911581,911582,911583,911584,911585,911586,911587,911588,911589,911590,911591,911592,911593,911594,911595,911596,911624,911628,911632,911633,911634,911635,911636,911637,911638,911639,911651,911652,911655,911659,911662,911663,911664,911666,911667,911668,911669,911672,911675,911676,911679,911681,911682,911683,911684,911685,911686,911692,911693,911696,911697,911698,911702,911704,911731,911732,911733,911734,911735,911741,911743,911744,911745,911746,911748,911749,911762,911763,911764,911765,911781,911782,911783,911785,911786,911792,911795,911796,911799,911821,911822,911823,911824,911826,911828,911851,911852,911853,911858,911859,911870,911871,911872,911874,911875,911881,911882,911883,911884,911885,911886,911887,911892,911893,911894,911895,911896,911897,911899,911900,911902,911903,911904,911905,911906,911907,911908,911909,911921,911922,911923,911924,911931,911932,911933,911936,911951,911952,911954,911955,911956,911957,911958,911960,911962,911964,911965,911970,911972,911975,911976,911978,911980,911981,911982,911983,911985,911990,911991,911992,911995,911996,911997,911998,911999,912111,912112,912113,912114,912115,912117,912118,912119,912130,912132,912133,912135,912136,912137,912138,912139,912140,912141,912142,912143,912144,912145,912147,912148,912149,912160,912161,912162,912163,912164,912165,912166,912167,912168,912169,912181,912182,912183,912184,912185,912186,912187,912188,912189,912191,912192,912194,912320,912321,912322,912323,912324,912325,912326,912327,912328,912329,912341,912342,912343,912344,912345,912346,912347,912350,912351,912352,912353,912354,912355,912356,912357,912358,912359,912362,912363,912364,912365,912366,912367,912371,912372,912373,912375,912378,912381,912382,912383,912384,912385,912421,912422,912423,912424,912425,912426,912427,912428,912429,912430,912431,912432,912433,912435,912436,912437,912438,912439,912441,912442,912443,912444,912445,912446,912447,912451,912452,912453,912454,912455,912456,912457,912460,912461,912462,912463,912465,912466,912467,912468,912469,912471,912472,912473,912475,912477,912478,912481,912482,912483,912484,912485,912487,912488,912489,912520,912521,912522,912524,912525,912526,912527,912528,912529,912550,912551,912552,912553,912554,912555,912556,912557,912558,912559,912560,912561,912562,912563,912564,912565,912566,912567,912568,912569,912580,912582,912583,912584,912585,912586,912587,912588,912589,912591,912592,912593,912594,912595,912596,912597,912598,912599,912621,912622,912623,912624,912625,912626,912628,912629,912630,912631,912632,912633,912634,912637,912640,912641,912642,912643,912644,912645,912646,912649,912661,912662,912663,912664,912665,912666,912667,912668,912669,912670,912672,912673,912674,912675,912676,912677,912678,912679,912690,912691,912692,912694,912696,912697,912698,912699,912711,912712,912713,912714,912715,912716,912717,912718,912733,912734,912735,912737,912738,912739,912740,912742,912744,912746,912747,912748,912749,912751,912752,912753,912754,912755,912756,912757,912758,912759,912761,912762,912763,912764,912765,912766,912767,912770,912771,912772,912773,912774,912775,912778,912779,912791,912792,912793,912794,912795,912796,912797,912801,912803,912804,912806,912808,912820,912821,912822,912823,912824,912825,912826,912827,912828,912829,912830,912831,912832,912833,912834,912835,912836,912837,912838,912839,912841,912842,912843,912844,912845,912846,912847,912848,912849,912870,912871,912872,912873,912874,912875,912876,912877,912878,912891,912892,912893,912894,912895,912896,912897,912898,912900,912901,912902,912903,912904,912905,912906,912907,912908,912909,912920,912921,912922,912923,912924,912925,912926,912927,912928,912929,912930,912931,912932,912933,912934,912935,912936,912937,912938,912939,912950,912951,912952,912953,912954,912955,912956,912957,912958,912959,912960,912961,912962,912963,912964,912965,912966,912967,912968,912969,912970,912971,912972,912973,912974,912975,912976,912977,912978,912979,912980,912981,912982,912983,912984,912985,912986,912987,912988,912989,912990,912991,912992,912993,912994,912995,912996,912997,912998,912999,913010,913011,913012,913013,913014,913015,913016,913017,913018,913019,913174,913192,913193,913210,913211,913212,913213,913214,913215,913216,913217,913218,913220,913221,913222,913223,913224,913225,913227,913228,913229,913241,913242,913243,913244,913251,913252,913253,913254,913451,913452,913453,913454,913461,913462,913463,913465,913471,913472,913473,913474,913481,913482,913483,913484,913485,913511,913512,913513,913521,913522,913523,913524,913525,913526,913552,913561,913562,913563,913564,913565,913566,913581,913582,913583,913584,913592,913595,913621,913623,913624,913637,913638,913639,913650,913651,913652,913653,913654,913655,913656,913657,913658,913659,913661,913662,913663,913664,913665,913666,913667,913668,913669,913670,913671,913672,913673,913674,913675,913676,913677,913678,913711,913712,913713,913714,913715,913751,913752,913753,913754,913756,913758,913759,913771,913772,913774,913775,913776,913777,913778,913779,913780,913782,913783,913784,913785,913786,913787,913788,913789,913790,913791,913792,913793,913794,913795,913797,913798,913799,913800,913801,913802,913803,913804,913805,913806,913807,913808,913809,913821,913822,913823,913824,913825,913826,913830,913831,913834,913835,913836,913837,913838,913839,913841,913842,913843,913844,913845,913848,913860,913861,913862,913863,913865,913867,913869,913870,913871,913872,913873,913874,913876,913877,913878,913879,913880,914111,914112,914114,914115,914116,914118,914119,914142,914143,914144,914145,914146,914147,914149,914151,914153,914171,914172,914173,914174,914175,914177,914179,914181,914182,914183,914188,914202,914204,914252,914253,914254,914255,914256,914257,914258,914259,914262,914266,914268,914281,914282,914283,914285,914286,914287,914288,914290,914292,914294,914295,914296,914298,914320,914322,914323,914324,914326,914327,914328,914329,914331,914332,914333,914339,914341,914342,914343,914344,914346,914347,914348,914362,914364,914365,914366,914367,914368,914369,914371,914372,914373,914374,914542,914543,914544,914545,914546,914549,914551,914552,914553,914554,914561,914562,914563,914564,914565,914566,914567,914573,914574,914575,914576,914577,914630,914632,914633,914634,914635,914636,914637,914638,914639,914651,914652,914728,914733,914734,914735,914822,914828,914829,914862,914864,914865,914868,914869,914884,914885,914890,914891,914892,914893,914894,914895,914896,914897,914898,914899,914922,914923,914924,914926,914931,914933,914935,914936,914982,914985,914994,914997,914998,915111,915112,915113,915114,915115,915142,915143,915144,915162,915164,915165,915168,915170,915171,915172,915174,915175,915176,915178,915180,915181,915182,915183,915190,915191,915192,915194,915195,915198,915212,915240,915241,915244,915248,915250,915251,915252,915253,915254,915255,915260,915261,915262,915263,915264,915265,915270,915271,915273,915274,915275,915278,915280,915281,915282,915283,915284,915311,915313,915315,915317,915331,915332,915333,915334,915335,915341,915342,915343,915361,915362,915364,915368,915412,915413,915414,915440,915442,915443,915444,915445,915446,915447,915450,915451,915452,915453,915454,915460,915461,915462,915463,915464,915465,915466,915491,915493,915494,915495,915496,915497,915498,915521,915522,915523,915524,915525,915541,915542,915543,915544,915545,915546,915547,915548,915561,915563,915564,915566,915567,915568,915612,915613,915614,915640,915641,915642,915643,915644,915645,915646,915647,915648,915661,915662,915664,915671,915672,915673,915676,915677,915680,915681,915683,915688,915690,915691,915692,915694,915721,915722,915723,915724,915731,915732,915733,915734,915735,915736,915738,915740,915742,915744,915745,915821,915822,915823,915824,915825,915831,915832,915833,915834,915836,915841,915842,915843,915844,915850,915851,915852,915853,915854,915855,915861,915862,915863,915864,915865,915870,915871,915872,915873,915874,915875,915876,915880,915881,915882,915921,915922,915923,915924,915942,915943,915944,915945,915946,915947,915948,915949,915960,915961,915962,915963,915964,915965,915966,915967,916111,916112,916114,916115,916132,916135,916150,916151,916152,916153,916154,916155,916156,916157,916158,916159,916180,916181,916182,916183,916184,916185,916186,916187,916188,916189,916222,916223,916224,916226,916227,916228,916229,916242,916243,916244,916245,916246,916247,916250,916251,916252,916253,916254,916255,916256,916257,916258,916259,916271,916272,916273,916274,916275,916276,916277,916278,916279,916322,916323,916324,916325,916326,916327,916328,916331,916332,916336,916337,916341,916342,916344,916345,916346,916347,916348,916349,916420,916421,916422,916423,916424,916425,916426,916427,916428,916429,916431,916432,916433,916434,916435,916436,916437,916438,916451,916452,916453,916454,916455,916457,916459,916461,916462,916466,916467,916471,916473,916475,916476,916477,916478,916479,916522,916523,916524,916525,916526,916527,916528,916529,916530,916531,916532,916533,916534,916535,916536,916538,916539,916540,916541,916542,916543,916544,916545,916546,916547,916548,916549,916550,916551,916553,916554,916556,916557,916558,916559,916560,916561,916562,916563,916564,916565,916566,916567,916568
,916569,916581,916582,916583,916584,916585,916586,916587,916588,916589,916591,916593,916594,916596,916597,916621,916622,916624,916625,916626,916640,916641,916642,916643,916644,916645,916646,916647,916648,916649,916651,916652,916653,916654,916655,916657,916670,916671,916672,916673,916675,916676,916677,916678,916679,916681,916682,916683,916684,916685,916721,916722,916723,916724,916725,916726,916727,916728,916729,916731,916732,916733,916735,916752,916753,916755,916756,916757,916758,916760,916761,916762,916763,916764,916765,916766,916767,916768,916769,916781,916782,916784,916786,916788,916791,916792,916793,916794,916795,916796,916797,916810,916811,916814,916815,916816,916817,916818,916819,916821,916822,916840,916841,916842,916843,916844,916845,916846,916847,916848,916849,916850,916852,916853,916854,916855,916856,916857,916858,916859,916860,916861,916862,916863,916864,916865,916866,916867,916868,916869
,918966,918965,918964,918963,918952,918947,918946,918945,918944,918942,918941,918938,918937,918936,918935,918934,918933,918932,918931,918924,918922,918869,918868,918865,918864,918863,918862,918857,918856,918855,918854,918852,918829,918823,918821,918819,918818,918816,918814,918813,918812,918811,918761,918753,918752,918751,918749,918748,918747,918746,918745,918744,918743,918742,918741,918740,918739,918738,918737,918736,918735,918734,918733,918732,918731,918730,918729,918728,918727,918725,918724,918723,918721,918720,918719,918718,918717,918716,918715,918713,918711,918710,918694,918693,918692,918691,918689,918685,918684,918683,918682,918681,918680,918678,918677,918676,918674,918673,918672,918671,918659,918656,918654,918649,918648,918647,918646,918645,918644,918643,918642,918641,918640,918629,918628,918627,918626,918625,918624,918623,918622,918621,918620,918599,918598,918596,918594,918593,918592,918589,918588,918587,918586,918585,918584,918583,918582,918581,918579,918578,918577,918576,918573,918572,918571,918570,918569,918568,918567,918566,918565,918564,918563,918562,918561,918560,918559,918558,918557,918556,918554,918552,918551,918550,918549,918548,918546,918545,918543,918542,918541,918540,918539,918538,918537,918536,918535,918534,918533,918532,918531,918525,918524,918523,918522,918520,918519,918518,918517,918516,918515,918514,918513,918512,918510,918506,918505,918504,918503,918502,918501,918499,918498,918497,918496,918495,918494,918493,918492,918491,918490,918488,918487,918485,918484,918483,918482,918481,918479,918478,918477,918476,918475,918474,918473,918472,918471,918470,918468,918467,918466,918465,918464,918463,918462,918461,918458,918457,918456,918455,918454,918452,918451,918450,918444,918443,918442,918441,918440,918426,918425,918424,918422,918419,918418,918417,918416,918415,918414,918413,918412,918411,918408,918407,918406,918405,918404,918403,918402,918399,918398,918397,918396,918395,918394,918393,918392,918391,918389,918388,918387,918386,918385,918384,918383,918382,918381,918380,918379,918378,918377,918376,918375,918373,918372,918371,918370,918359,918358,918357,918356,918355,918354,918353,918352,918351,918350,918346,918345,918343,918342,918339,918338,918337,918336,918335,918334,918333,918332,918331,918330,918304,918301,918289,918288,918284,918283,918282,918276,918274,918272,918267,918266,918265,918263,918262,918261,918259,918258,918257,918256,918255,918254,918253,918251,918236,918234,918232,918231,918230,918229,918228,918227,918226,918225,918224,918223,918222,918221,918199,918198,918196,918195,918194,918193,918192,918191,918190,918189,918188,918187,918186,918185,918184,918183,918182,918181,918180,918177,918176,918175,918174,918173,918172,918170,918159,918158,918157,918156,918155,918154,918153,918152,918151,918150,918139,918138,918137,918136,918135,918134,918133,918132,918131,918119,918118,918117,918113,918111,918110,917868,917867,917866,917865,917864,917863,917862,917861,917859,917858,917857,917856,917855,917854,917853,917852,917851,917850,917849,917848,917847,917846,917844,917843,917841,917840,917836,917835,917834,917833,917832,917831,917826,917825,917824,917823,917822,917821,917820,917819,917818,917817,917816,917815,917813,917812,917811,917810,917806,917805,917804,917803,917802,917801,917794,917793,917792,917791,917790,917789,917788,917787,917786,917785,917784,917783,917782,917781,917779,917778,917777,917776,917775,917774,917773,917772,917771,917770,917769,917768,917767,917766,917765,917764,917763,917762,917761,917759,917758,917757,917756,917755,917754,917753,917752,917751,917750,917749,917748,917747,917746,917745,917744,917743,917741,917740,917734,917733,917732,917731,917730,917729,917728,917727,917726,917725,917724,917723,917722,917721,917720,917707,917706,917705,917704,917703,917701,917700,917695,917694,917693,917692,917691,917690,917689,917688,917687,917686,917685,917684,917683,917682,917681,917680,917675,917674,917673,917672,917671,917670,917664,917663,917662,917661,917660,917659,917658,917657,917656,917655,917653,917652,917651,917650,917649,917648,917647,917646,917645,917644,917643,917642,917641,917640,917638,917637,917636,917635,917634,917633,917632,917630,917629,917628,917627,917626,917625,917624,917623,917622,917621,917609,917608,917606,917605,917604,917603,917601,917596,917595,917594,917593,917592,917591,917590,917586,917585,917584,917583,917582,917581,917580,917578,917577,917576,917575,917574,917573,917572,917571,917570,917565,917564,917563,917562,917561,917560,917548,917547,917546,917545,917544,917543,917542,917541,917540,917539,917538,917537,917536,917535,917534,917533,917532,917531,917530,917529,917528,917527,917526,917525,917524,917523,917522,917521,917497,917496,917495,917494,917493,917492,917491,917490,917487,917486,917485,917484,917482,917481,917480,917469,917468,917467,917466,917465,917464,917463,917462,917461,917460,917459,917458,917457,917456,917455,917454,917453,917452,917451,917450,917438,917437,917436,917435,917434,917433,917432,917431,917430,917427,917426,917425,917424,917423,917422,917421,917420,917414,917413,917412,917410,917395,917394,917393,917392,917391,917390,917375,917374,917372,917371,917370,917369,917368,917367,917366,917365,917364,917363,917362,917361,917360,917329,917328,917327,917326,917325,917324,917323,917322,917321,917320,917297,917296,917295,917294,917292,917291,917290,917289,917288,917287,917286,917285,917284,917283,917282,917281,917280,917279,917274,917273,917272,917271,917270,917269,917268,917267,917266,917265,917264,917263,917262,917261,917260,917258,917257,917256,917255,917254,917253,917252,917251,917239,917238,917237,917236,917235,917234,917233,917232,917231,917230,917229,917228,917227,917226,917225,917224,917223,917222,917221,917220,917203,917202,917201,917199,917198,917197,917196,917189,917187,917186,917185,917184,917183,917182,917181,917180,917179,917178,917177,917176,917175,917174,917173,917172,917171,917170,917169,917168,917167,917166,917165,917164,917162,917161,917160,917158,917157,917156,917155,917153,917152,917151,917149,917148,917147,917146,917145,917144,917143,917142,917141,917139,917138,917137,917136,917135,917134,917133,917132,917131,917118,917116,917115,917114,917113,917112,917109,917106,917105,917104,917103,917102,917100
)


-------mobile number in phone number field


update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [Phone Validity]='Valid- As the length is 10 and starts with 9,7,8'
where [Phone Validity] is null and len(phone) =(10) and left(phone,1)  in (9,7,8)


update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [Phone Validity]='Valid- As the length is 11 and starts with 09,07,08'
where [Phone Validity] is null and len(phone) =(11) and left(phone,2)  in (09,07,08)


update [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [Phone Validity]='Valid- As the length is 12 and starts with 919,917,918'
where [Phone Validity] is null and len(phone) =(12) and left(phone,3)  in (919,917,918)


update  [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]
set [Phone Validity]='Data Cleaning is required'
where [Phone Validity] is null


select [Phone Validity],count(*) from [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125] group by [Phone Validity]
select * from [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125] where [Phone Validity]='Data Cleaning is required'



select top 100 * --into [Kalyan_Temp].[dbo].[temp_sp_phoneCleaning_20161004]
from [Kalyan_Temp].[dbo].[temp_sp_ResidencePhonetransactiondata_full_20170125]

------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
---------------mobile cleaning script
------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
select top 100 * from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125

alter table [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
add [Mobile backup] varchar (50)

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile backup]= mobile

/*----------------------Moving the mobile from raw data to destination table-----------------------*/

--DROP table [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125

--insert into [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125(  [id]  ,[Mobile],[Mobile backup])
SELECT distinct CustomerCode  as 'ID' ,[MobileNumber] 'Mobile',[MobileNumber] 'Mobile backup'
into [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
FROM #temp
--where [JoinDate]>='2014-04-01 00:00:00.000'





--Drop table [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125


/*-------------altering the  destination table to accomadate all the required fields-------------------*/

alter table [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  
add [Mobile Validity] varchar(100),[Special Characters] char(1)
,[Alphabets] char(1),[Space] char(1),[IsMobile?] int,[IsLandline?] int,[Length Standardization] char(2),[Cleaning] char(1)
,[Status] varchar(20), [State Code] varchar(100) ,[Descrption] varchar(100),[Final Mobile] bigint
,[Is_Contactable_Pending_Validation] char(1),[Isrepeating] char(1),[Issamemobile_clean_unclean] char(1)


/*-----------cleaning the mobile field of special characters and alphabets for only those records which have special characters in them--------------------------*/


----removing special characters
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'[PP]',''),[Special Characters]='Y'  where Mobile like '%[PP]%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'!',''),[Special Characters]='Y'   where Mobile like '%!%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'@',''),[Special Characters]='Y'   where Mobile like '%@%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'#',''),[Special Characters]='Y'   where Mobile like '%#%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'$',''),[Special Characters]='Y'   where Mobile like '%$%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'&',''),[Special Characters]='Y'   where Mobile like '%&%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'*',''),[Special Characters]='Y'   where Mobile like '%*%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'(',''),[Special Characters]='Y'   where Mobile like '%(%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,')',''),[Special Characters]='Y'   where Mobile like '%)%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'-','') ,[Special Characters]='Y'  where Mobile like '%-%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'+',''),[Special Characters]='Y'   where Mobile like '%+%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'=',''),[Special Characters]='Y'   where Mobile like '%=%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'{','') ,[Special Characters]='Y'  where Mobile like '%{%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'}',''),[Special Characters]='Y'   where Mobile like '%}%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'[','') ,[Special Characters]='Y'  where Mobile like '%[%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,']','') ,[Special Characters]='Y'  where Mobile like '%]%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,':',''),[Special Characters]='Y'   where Mobile like '%:%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,';','') ,[Special Characters]='Y'  where Mobile like '%;%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'/',''),[Special Characters]='Y'   where Mobile like '%/%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'?','') ,[Special Characters]='Y'  where Mobile like '%?%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'.','') ,[Special Characters]='Y'  where Mobile like '%.%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,',','') ,[Special Characters]='Y'  where Mobile like '%,%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'>','') ,[Special Characters]='Y'  where Mobile like '%>%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'<','') ,[Special Characters]='Y'  where Mobile like '%<%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'`',''),[Special Characters]='Y'   where Mobile like '%`%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'~','') ,[Special Characters]='Y'  where Mobile like '%~%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'[','') ,[Special Characters]='Y'  where Mobile like '%[%'


----removing alphabets



update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'i','1'),[Alphabets]='Y'  where Mobile like '%[0-9]i[0-9]%' and len(Mobile) in (10) and left(mobile,1) in ('7','8','9')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'i','1'),[Alphabets]='Y'  where Mobile like '%[0-9]i[0-9]%' and len(Mobile) in (11) and left(mobile,2) in ('07','08','09')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'i','1'),[Alphabets]='Y'  where Mobile like '%[0-9]i[0-9]%' and len(Mobile) in (12) and left(mobile,3) in ('917','918','919')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'i','1'),[Alphabets]='Y'  where Mobile like '%[0-9]i[0-9]%' and len(Mobile) in (14) and left(mobile,5) in ('00918','00919','00917')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'i',''),[Alphabets]='Y'  where Mobile like '%i%' 

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'o','0'),[Alphabets]='Y'  where Mobile like '%[0-9]o[0-9]%' and len(Mobile) in (10) and left(mobile,1) in ('7','8','9')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'o','0'),[Alphabets]='Y'  where Mobile like '%[0-9]o[0-9]%' and len(Mobile) in (11) and left(mobile,2) in ('07','08','09','o7','o8','o9')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'o','0'),[Alphabets]='Y'  where Mobile like '%[0-9]o[0-9]%' and len(Mobile) in (12) and left(mobile,3) in ('917','918','919')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'o','0'),[Alphabets]='Y'  where Mobile like '%[0-9]o[0-9]%' and len(Mobile) in (14) and left(mobile,5) in ('00918','00919','00917','0o917','o0917','oo917','0o918','o0918','oo918','0o919','o0919','oo919')
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'o',''),[Alphabets]='Y'  where Mobile like '%o%' 



update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'a',''),[Alphabets]='Y'  where Mobile like '%a%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'b',''),[Alphabets]='Y'  where Mobile like '%b%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'c',''),[Alphabets]='Y'  where Mobile like '%c%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'d',''),[Alphabets]='Y'  where Mobile like '%d%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'e',''),[Alphabets]='Y'  where Mobile like '%e%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'f',''),[Alphabets]='Y'  where Mobile like '%f%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'g',''),[Alphabets]='Y'  where Mobile like '%g%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'h',''),[Alphabets]='Y'  where Mobile like '%h%'
--update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'i',''),[Alphabets]='Y'  where Mobile like '%i%' 
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'j',''),[Alphabets]='Y'  where Mobile like '%j%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'k',''),[Alphabets]='Y'  where Mobile like '%k%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'l',''),[Alphabets]='Y'  where Mobile like '%l%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'m',''),[Alphabets]='Y'  where Mobile like '%m%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'n',''),[Alphabets]='Y'  where Mobile like '%n%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'p',''),[Alphabets]='Y'  where Mobile like '%p%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'q',''),[Alphabets]='Y'  where Mobile like '%q%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'r',''),[Alphabets]='Y'  where Mobile like '%r%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'s',''),[Alphabets]='Y'  where Mobile like '%s%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'t',''),[Alphabets]='Y'  where Mobile like '%t%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'u',''),[Alphabets]='Y'  where Mobile like '%u%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'v',''),[Alphabets]='Y'  where Mobile like '%v%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'w',''),[Alphabets]='Y'  where Mobile like '%w%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'x',''),[Alphabets]='Y'  where Mobile like '%x%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'y',''),[Alphabets]='Y'  where Mobile like '%y%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'z',''),[Alphabets]='Y'  where Mobile like '%z%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125    set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125    set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125    set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125    set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125    set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125    set Mobile=replace(Mobile,'�',''),[Alphabets]='Y'  where Mobile like '%�%'

----removing extra unnecessary spaces post cleaning the special characters and alphabets


update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,' ','') ,[Space]='Y' where Mobile like '% %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'  ',''),[Space]='Y'  where Mobile like '%  %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'   ',''),[Space]='Y'  where Mobile like '%   %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'    ',''),[Space]='Y'  where Mobile like '%    %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'     ',''),[Space]='Y'  where Mobile like '%     %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'      ','') ,[Space]='Y' where Mobile like '%      %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'       ',''),[Space]='Y'  where Mobile like '%       %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'        ','') ,[Space]='Y' where Mobile like '%        %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'         ','') ,[Space]='Y' where Mobile like '%         %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'          ','') ,[Space]='Y' where Mobile like '%          %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,'      ',''),[Space]='Y'  where Mobile like '%      %'
update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set Mobile=replace(Mobile,' ',''),[Space]='Y'  where Mobile like '% %'

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set [Mobile]=ltrim(rtrim(Mobile))

--update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125  set cleaning='Y' where [Space]='Y' or [Alphabets]='Y' or [Special Characters]='Y'



--select * from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 where [mobile] like '%[a-z]%'


/*----------------------determining the validity of the mobile numbers--------------------*/


----where length is invalid 

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Invalid- As the length is equal to 0,1,2,3,4,5,9',[IsMobile?]=0
where len(Mobile) in (9,0,1,2,3,4,5)  and [Mobile Validity] is null

----where length is invalid 

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Invalid- As the length is >14',[IsMobile?]=0
where len(Mobile) >14 and [Mobile Validity] is null


---------where numbers are recursive

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Invalid- As the data is recursive number',[IsMobile?]=0
where Mobile like '%000000000%' or Mobile like '%222222222%' or  Mobile like '%111111111%'or  Mobile like '%333333333%' or  Mobile like '%444444444%'
or  Mobile like '%6666666666%' or  Mobile like '%5555555555%' or  Mobile like '%777777777%' or  Mobile like '%888888888%' or  Mobile like '%999999999%'
or  Mobile like '12345678%'
and [Mobile Validity] is null

-------where  length is 10 and starts with 9,7,8

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Valid- As the length is 10 and starts with 9,7,8',[IsMobile?]=b.[IsMobile?],[Final Mobile]=right([Mobile],10)
from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 a
inner join [Kalyan_Master].[dbo].[tbl_Master_Mobile_Vs_Landline_First_4_Digits_Final] b
on left(a.Mobile,4)=b.[First 4 digits]
where len(a.Mobile)=10   and [Mobile Validity] is null

------where length is 11 and starts with 09,07,08

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Valid- As the length is 11 and starts with 09,07,08',[IsMobile?]=b.[IsMobile?]
,[Length Standardization]='Y',[Final Mobile]=right([Mobile],10)
from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 a
inner join [Kalyan_Master].[dbo].[tbl_Master_Mobile_Vs_Landline_First_4_Digits_Final] b
on substring(a.Mobile,2,4)=b.[First 4 digits]
where len(a.Mobile)=11 and left(a.Mobile,1)='0'  and [Mobile Validity] is null 


-----where length is 12 and starts with 919,917,918

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Valid- As the length is 12 and starts with 919,917,918',[IsMobile?]=b.[IsMobile?]
,[Length Standardization]='Y',[Final Mobile]=right([Mobile],10)
from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 a
inner join [Kalyan_Master].[dbo].[tbl_Master_Mobile_Vs_Landline_First_4_Digits_Final] b
on substring(a.Mobile,3,4)=b.[First 4 digits]
where len(a.Mobile)=12  and left(a.Mobile,2)='91' and [Mobile Validity] is null 


-----where length is 14 and starts with 919,917,918

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Valid- As the length is 14 and starts with 00919,00917,00918'
,[IsMobile?]=b.[IsMobile?],[Length Standardization]='Y',[Final Mobile]=right([Mobile],10)
from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 a
inner join [Kalyan_Master].[dbo].[tbl_Master_Mobile_Vs_Landline_First_4_Digits_Final] b
on substring(a.Mobile,5,4)=b.[First 4 digits]
where len(a.Mobile)=14    and left(a.Mobile,4)='0091'


------all other cases setting mobile valid to invalid

update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125
set [Mobile Validity]='Invalid',[IsMobile?]=0--,[Final Mobile]=[Mobile]
where [IsMobile?] is null -- and [Mobile Validity] is null 



--select [Mobile Validity],count(*) from Kalyan.[dbo].[Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 
--group by [Mobile Validity]

--select distinct left([Mobile Validity],1),left([Final Mobile],1),len([Final Mobile]) from Kalyan.[dbo].[Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 
--where [IsMobile?]=1

--select count(*) from Kalyan.[dbo].[Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 
--where [IsMobile?]=1

--select count(distinct [Final Mobile]),count(distinct id) from Kalyan.[dbo].[Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 
--where [Mobile Validity] like 'Valid%'

--select count(distinct id) from Kalyan.[dbo].[Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 




update [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 
set [IsMobile?]=1
where [Mobile Validity] like 'Valid%'



select distinct cast([Final Mobile] as varchar(15)) [Mobile] into [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125_finalMobiles
  from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125 
where [Mobile Validity] like 'Valid%'

select * into [Kalyan_Temp].[dbo].[MobilePhoneCleaning_20161004]
from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125

select top 100 * from [Kalyan_Temp].[dbo].MobilePhoneCleaning_full_20170125

------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
---------------email cleaning script
------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
SELECT distinct customercode as 'ID' ,[EmailID] 'Email'
into [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]  
FROM [Kalyan_Temp].[dbo].[temp_sp_consumermelamapped_20161004]
where len([EmailID])>=5


--Drop table [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]  
/*--------------Altering th table with additional columns--------------------------*/
alter table [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] 
add [Email_Validity] varchar(30)

--alter table [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]  
--Drop column [Email_Validity] 


/*---------------cleaning the email id---------------------------*/

update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=ltrim(rtrim([Email]))
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],' ','')where Email like '% %'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'  ','')where Email like '%  %'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'   ','')where Email like '%   %'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'    ','')where Email like '%    %'


update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],',com','.com') where (Email like'%,com') 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@com','.com') where (Email like'%@com') 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@.','@') where [email] like '%@.[a-zA-z0-9]%.[a-zA-z0-9]%' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'hotmal','hotmail') where [email] like '%hotmal%' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'gamil','gmail') where [email] like '%gamil%' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'gmil','gmail') where [email] like '%gmil%' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'ridiff','rediff') where [email] like '%ridiff%' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'gmailvom','gmail.com') where [email] like '%gmailvom' 


update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'gmail.com','@gmail.com') where Email like '%gmail.com' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'gmail,com','@gmail.com') where Email like '%gmail,com' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@gmail','@gmail.com') where Email like '%@gmail' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@.gmail.com','@gmail.com') where Email like '%@.gmail.com'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@.gmail,com','@gmail.com') where Email like '%@.gmail,com' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@gmail,com','@gmail.com') where Email like '%@gmail,com' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@gmailcom','@gmail.com') where Email like '%@gmailcom' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@gmailvom','@gmail.com') where Email like '%@gmailvom' 

update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@.yahoo.com','@yahoo.com') where Email like '%@.yahoo.com'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@.yahoo,com','@yahoo.com') where Email like '%@.yahoo,com' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'yahoo','@yahoo.com') where Email like '%yahoo' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'yahoo','@yahoo') where Email like '%yahoo%' and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'yahoo.com','@yahoo.com') where Email like '%yahoo.com' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'yahoo,com','@yahoo.com') where Email like '%yahoo,com' and  (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'.yahoo','@yahoo') where (Email like'%.yahoo%') and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@yahoo,com','@yahoo.com') where Email like '%@yahoo,com' 
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@.yahoo','@yahoo') where (Email like'%@.yahoo%') and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@yahoo','@yahoo.com') where Email like '%@yahoo' and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)


update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'hotmail','@hotmail') where Email like '%hotmail%' and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@hotmail','@hotmail.com') where Email like '%@hotmail' and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)

update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'redif','rediff') where Email like '%redifmail%'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'rediff','@rediff') where Email like '%rediff%' and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=0)
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'@rediffmail','@rediffmail.com') where Email like '%@rediffmail' and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)

update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=ltrim(rtrim([Email]))
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],' ','')where Email like '% %'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'  ','')where Email like '%  %'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'   ','')where Email like '%   %'
update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125] set [Email]=replace([Email],'    ','')where Email like '%    %'



/*----------------------Checking the validity of the email id-----------------------*/

update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
set [Email_Validity]='Valid'
where Email like '%[a-zA-z0-9_\-..!#$&*/{}:;+]@[a-zA-z0-9]%.[a-zA-z0-9]%'
and (LEN(Email)-LEN(REPLACE(Email, '@', ''))=1)

update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
set [Email_Validity]='Invalid/Cleaning Required'
where [Email_Validity] is null


--select * from [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
--where [Email_Validity] ='Valid' 


--update [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
--set email=''
--where id=''

select * ---into [Kalyan_temp].[dbo].[temp_sp_EmailCleaning_20161004]
from [Kalyan_Temp].[dbo].[temp_sp_Emailfromtransactiondata_full_20170125]
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--------mapping values to rfm table
------------------------------------------------------------------------------
update [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125
set [MobileNumber]=b.[Mobile]
from [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125 a
inner join [Kalyan_temp].dbo.MobilePhoneCleaning_full_20170125 b on a.CustomerCode=b.customercode
where b.[Mobile Validity] like 'Valid%'

update [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125
set [Email]=b.[Email]
from [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125 a
inner join [Kalyan_Temp].dbo.temp_sp_Emailfromtransactiondata_full_20170125 b on a.CustomerCode=b.[customerCode]
where b.[Email_Validity]='Valid'


update [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125
set [ResidencePhone]=b.Phone
from [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125 a
inner join [Kalyan_Temp].dbo.temp_sp_ResidencePhonetransactiondata_full_20170125 b on a.CustomerCode=b.[customerCode]
where b.[Phone Validity] like 'Valid%'


update [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125
set [Area]=b.[Area],[District]=b.[District],[State]=b.[State],[Pincode]=b.[Pincode]
from [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125 a
inner join [Kalyan_temp].dbo.temp_sp_Addresstransactiondata_full_20170125 b on a.CustomerCode=b.CustomerCode


update [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125
set [JoinLocation_Updated]=b.[JoinLocation_Updated]
from [Kalyan_Temp].dbo.temp_sp_RFMV1_2016_20170125 a
inner join [Kalyan_temp].dbo.temp_sp_JoinLocationtransactiondata_full_20170125 b on a.CustomerCode=b.CustomerCode


------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [Area]='' where [Area] is null or [Area]='null' 

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [District]='' where [District] is null or [District]='null' 

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [State]='' where [State] is null or [State]='null' 

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [Pincode]='' where [Pincode] is null or [Pincode]='null' 

--------------------------------
alter table [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
add [MobileScore] varchar(100),[AddressScore] varchar(100),
    [EmailScore] varchar(100),[ResidencePhoneScore] varchar(100),
    [MelaScore] varchar(100)

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [MobileScore]= case when len([MobileNumber])>0 then 1 else 0 end  

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [AddressScore]= case when (len([Area])>0 and len([District])>0 and len([State])>0 and len([Pincode])>0) then 1 else 0 end  

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [EmailScore]= case when len([Email])>0  then 1 else 0 end  

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [ResidencePhoneScore]= case when len([ResidencePhone])>0 then 1 else 0 end  

update [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125
set [MelaScore]= ([MobileScore]*55)+([EmailScore]*30)+([AddressScore]*5)+([ResidencePhoneScore]*10)


select top 100 * from [Kalyan_Temp].[dbo].temp_sp_RFMV1_2016_20170125

