-------  ADVANCED SQL -----

--SELECT * FROM  dbo.rank


-------------------------------------------Ranking

SELECT *,
RANK() OVER(ORDER BY SALES DESC) RNK,
DENSE_RANK() OVER(ORDER BY SALES DESC) DENSE_RNK,
ROW_NUMBER() OVER(ORDER BY SALES DESC) ROWNUM
FROM  dbo.rank




-------------------------------------------Partitioning

SELECT *,
RANK() OVER(partition by department order by salary DESC) RNK,
DENSE_RANK() OVER(partition by department order by salary DESC) DENSE_RNK,
ROW_NUMBER() OVER(partition by department order by salary DESC) ROWNUM
FROM  dbo.rankp

/*
---------------------------------rows between function
Trying to get the sum of todays sales+yesterdays sales and tomorrows sales using the rows between function

-If you know exact number of days you want to us":*/

SELECT *, 
sum(Sales) over(order by Month rows between 1 preceding and 1 following )[total_sales_YTT]

FROM dbo.rowsBetween


-----------------------------------------sum function
SELECT *, 
sum(Sales) over(order by Month rows between unbounded preceding and unbounded following )[total_sales_YTT]
FROM dbo.rowsBetween

---If you want to have a sum of all previous rows up until the current column:
SELECT *, 
sum(Sales) over(order by Month rows between unbounded preceding and current row)[total_sales_YTT]
FROM dbo.rowsBetween


------------------------------------FIRST VALUE,LAST VALUE, NTH VALUE
SELECT *,
FIRST_VALUE(salary) OVER(partition by department order by salary ) firstValue,
LAST_VALUE(salary) OVER(partition by department order by salary DESC) lastValue
--Nth_VALUE(salary,5) OVER(partition by department order by salary rows between unbounded preceding and unbounded following) nthValue
FROM  dbo.rankp


-------------------------------------Avg function
 select Sales,MONTH,
 avg(sales) over(order by Month rows between 2 preceding and current row) as ThreeDayAvg,
 avg(sales) over(order by Month rows between 4 preceding and current row) as FiveDayAvg
 from dbo.sales
 
 --------------------------------------COMBINING TABLES THAT HAVEW NOTHING IN COMMON

 create table department(name varchar (50));
 insert into department(name)
 values('Engeneering'),
 ('IT'),
 ('Medicine'),
 ('Finance')

  --select * from department

 create table shift(ID varchar (50));
 insert into shift(ID)
 values('Morning'),
 ('Afternoon'),
 ('Night')

 create table Country(c varchar (50));
 insert into Country(c)
 values('US'),
 ('SA'),
 ('UK')

 ---------------------------------------------cross join
select d.*,
case 
when d.ID='Morning' then '08.00 am to 11.59 am'
when d.ID='Night' then '08.00 pm to 11.59 pm'
else '12: 00 pm to 07:59 pm'
end as shitf_timings
from
(select a.*,b.*,c.* from department a,shift b, Country c)d;
 */



