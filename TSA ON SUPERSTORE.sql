use [super]

SELECT * FROM [dbo].[train]
Order by [Order Date];

-- new column sales_next that displays the sales of the next row in the dataset

Select *,
LEAD(Sales) over (order by [Order Date]) AS sales_next,
CASE when Sales > LEAD(Sales) over (order by [Order Date]) then 'Decreased'
	 when Sales < LEAD(Sales) over (order by [Order Date]) then 'Increased'
	 END Decision
from dbo.train;

-- new column sales_previous to display the values of the row above a given row and also the percentage change

with tt1 As(
Select *,
LAG(Sales) over (order by [Order Date]) AS sales_previous,
CASE when Sales > LEAD(Sales) over (order by [Order Date]) then 'Increased'
	 when Sales < LEAD(Sales) over (order by [Order Date]) then 'Decreased'
	 END Decision
from dbo.train)

select sales, sales_previous, (((sales - sales_previous)/sales_previous) * 100), Decision AS Change
from tt1;

-- Rank the data based on sales in descending order 

Select *,
Rank() over(order by sales DESC) AS RNK
FROM dbo.train;

-- Daily Sales and average daily sales

SELECT [Order Date], sum(Sales) AS total_sales, avg(Sales) as avg_sales
From dbo.train
Group by [Order Date]
order by total_sales desc;

-- Monthly Sales and average monthly sales

select FORMAT([Order Date], 'yyyy-MM') AS Order_date, sum(sales) AS total_sales, avg(Sales) AS avg_sales
from dbo.train
group by FORMAT([Order Date], 'yyyy-MM')
Order by total_sales desc;

-- Change in discount in every 2 consecutive days

with temp_table1 AS(
Select [Order Date], avg(Discount) AS avg_discount
From dbo.train
Group by [Order Date])

Select t1.[Order Date] AS From_Date, t2.[Order Date] AS To_Date, (t2.avg_discount - t1.avg_discount) AS Change
From temp_table1 AS t1
INNER JOIN temp_table1 AS t2
ON t1.[Order Date] + 1 = t2.[Order Date]
Order by t1.[Order Date];

-- Moving averages os sales

with temp_table2 AS(
select FORMAT([Order Date], 'yyyy-MM') AS Order_date, sum(sales) Total_sales
from dbo.train
group by FORMAT([Order Date], 'yyyy-MM'))

Select Order_date, Total_sales,
avg(Total_sales) over(order by Order_date ROWS BETWEEN 2 Preceding and Current Row) AS [3_day_MA],
avg(Total_sales) over(order by Order_date ROWS BETWEEN 4 Preceding and Current Row) AS [5_day_MA],
avg(Total_sales) over(order by Order_date ROWS BETWEEN 6 Preceding and Current Row) AS [7_day_MA]
from temp_table2
order by Order_date;

-- linear regression 

with table1 as(
SELECT discount, avg(discount) over() as x_bar, profit, Avg(profit) over () as y_bar
From dbo.train ),

table2 as(
select (sum((x_bar - discount) * (y_bar - profit))/sum((x_bar - discount)*(x_bar - discount))) as slope, max(x_bar) as x__bar, max(y_bar) as y__bar
from table1),

table3 as(
select slope, (y__bar - (x__bar * slope)) AS intercept
from table2)

select [sub-category], sales, discount, ((Select intercept from table3) + (select slope from table3) * discount) as profit_trend,
avg(profit) over(partition by discount) AS avg_Profit
from dbo.train
order by discount;

