
--====================================================
--Database restored AdventureWorks2019 (.bak file)
--This came with the pre-built tables and the schema
--====================================================


--======================================
--Exploring PK & FK between the tables
--======================================

SELECT 
    fk.name AS ForeignKey,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable
FROM sys.foreign_keys fk
-------------------------------------
SELECT 
    fk.name AS ForeignKey,
    OBJECT_NAME(fk.parent_object_id) AS ChildTable,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(fk.referenced_object_id) AS ParentTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ParentColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id


--========================================================================
--Selecting below specific tables from the overall available tables:
--========================================================================

--Picking-up Sales related tables to focus on Sales Analaysis:

--ProductCategory
--ProductSubCategory
--Product

--SalesOrderDetail
--SalesOrderHeader
--SalesTeritory
--Customers
--Address

--============================================================================
--Exploring each table for better understanding the dataset & the connectivity
--============================================================================


 --ProdCategory:
 --prodCat has only 4 categories
    Select * from production.ProductCategory
    Select count(*) from production.productcategory
--------------------------------------------------------------------------

  --ProdSubCategory:
  --prodSubCat (having 37 records, all prodSubCat_id (unique-37) available,
  -- and all prodCat_id (unique-4) are available)
  Select * from Production.ProductSubcategory
  Select count(*), count(distinct productcategoryID) as prodCat_id,
  count(distinct ProductSubcategoryID) as prodCatSub_id
  from Production.ProductSubcategory

     --productCategory & productSubcategory join (this has all, no gaps)
   Select cat.ProductCategoryID, subcat.ProductCategoryID,subcat.ProductSubcategoryID
   from Production.ProductCategory cat left join
   Production.ProductSubcategory subcat
   on cat.ProductCategoryID = subcat.ProductCategoryID


 -------------------------------------------------------------------------
  --Product:
  --(total records=504, unique-prod_id = 504, sub-cat_id = 37)
  --all sub_category are available.

  Select Top 3 * from Production.product

  Select count(*) as total, count(distinct productid) as distinct_prod_id,
  count(productid) as count_prod_id,
  count(distinct productsubcategoryid) as distinct_pro_sub_cat_id,
  count(productsubcategoryid) as count_pro_sub_cat_id from Production.Product

  -------------------------------------------------------------------------

  --SalesOrderDetail:
  --(this table is like order details, qty, prod, unit_price)
  --Product table and SalesOrderDetails can be linked on product_id
  --(select 504-266, 238 product_id can not be concluded for sales)
  --Total=121317, distinct_sale_ord_id = 31465, total_sale_ord_id =121317
--distinct_saleorder_detail_id = 121317,
--total_saleorder_detail_id = 121317,
--distinct_prod_id = 266, total_prod_id = 121317
  
  Select top 3 * from sales.SalesOrderDetail
  
  Select count(*) as total, count(distinct salesorderid) as distinct_sales_ord_id,
  count(salesorderid) as count_sales_ord_id,
  count(distinct salesorderdetailid) as distinct_saleorderDetail_id,
  count(salesorderdetailid) as count_saleorderDetail_id,
  count (distinct productid) as distinct_prod_id,
  count(productid) as count_product_id from sales.SalesOrderDetail

   --Product & SalesOrder join
   Select distinct prod.ProductID, ord.ProductID,
   prod.DiscontinuedDate, prod.SellEndDate
   from Production.product prod left join sales.SalesOrderDetail ord
   on prod.ProductID = ord.ProductID
   --where ord.productID is not null
   order by prod.ProductID

   --Products where sellDate available (98 products)
   Select * from Production.Product where SellEndDate is not null

   --ProdSubCategory & Prod join
   select distinct subcat.ProductCategoryID,subcat.ProductSubcategoryID,
   prod.ProductSubcategoryID,prod.ProductID, ord.ProductID
   from Production.ProductSubcategory subcat
   left join Production.Product prod 
   on subcat.ProductSubcategoryID = prod.ProductSubcategoryID
   left join sales.SalesOrderDetail ord
   on ord.ProductID = prod.ProductID
   where ord.ProductID is not null



 
 ------------------------------------------------------------------------------


 --SalesOrderHeader:
 --(this table is like order fullfilment details, total_amt, delivery_details etc)
 -- Select * from sales.salesorderheader

Select count(*) as total, count(distinct salesorderid) as distinct_sale_ord_id,
count(salesorderid) as count_sale_ord_id
from sales.salesorderheader


--Grouping orders to check their count, based upon salesorderId
Select salesorderid, count(*) as total
from sales.SalesOrderDetail
group by SalesOrderID

--Sample salesOderId picked, to verify the SalesOrderDetails and SalesHeader tables
Select * from sales.SalesOrderDetail
where SalesOrderID = 43666

/*
Comparing all the orders pertaining to a specific SalesOrderId from the...
SalesOrderDetails table against the summed-up record...
of the same SalesOrderId from the SalesOrderHeader table.
*/

with cte1 as(
Select (OrderQty*UnitPrice) as costing from sales.SalesOrderDetail
where SalesOrderID = 43666)

Select sum(costing) as total_amount from cte1

Select SubTotal,TaxAmt,Freight,TotalDue from sales.SalesOrderHeader
where SalesOrderID = 43666
     

--===================================================================
--Exploratory Data Analysis Key Points
--===================================================================

--------------------
--ProductCategory Table EDA
--------------------
--Prod_Cat_1) How many product categories are there?

Select * from production.ProductCategory
Select distinct Name as Distinct_Product_Category from Production.ProductCategory

--Prod_Cat_2) Total revenue and order count by category 
--(which category earns the most?)

/*
To solve the above business requirement, our tables have to travel from...
ProductCategory table to all the way to the SalesOrderDetail table
There are total 4 categories, and it produces result for all 4.

LineTotal column is used from the SalesOrderDetails as it is the resulting one..
from the Quantity * UnitPrice
*/

Select cat.Name,
--Casting to decimal is important here as round alone will not work.
--boz, the LineTotal column in the table takes several precision points
Cast (Sum(ord.LineTotal) as decimal(15,2)) as Revenue, 
count(ord.SalesOrderID) as Order_Count
from Production.ProductCategory cat left join
Production.ProductSubcategory subcat
on cat.ProductCategoryID = subcat.ProductCategoryID
left join Production.Product prod 
on subcat.ProductSubcategoryID = prod.ProductSubcategoryID
left join sales.SalesOrderDetail ord on ord.ProductID = prod.ProductID
group by cat.Name
order by Revenue desc

--------------------
--ProductSubCategory Table EDA
--------------------
--Prod_Sub_Cat_1) How many product subcategories are there in total?

--ProductSubCategoryId is PK, hence distinct keyword not required:
Select count(productsubcategoryid) as total from Production.ProductSubcategory

--Prod_Sub_Cat_2) How many product subcategories are there for each category?

Select cat.Name, count(subcat.ProductSubcategoryID) as Sub_Cat_Count
from Production.ProductCategory cat left join Production.ProductSubcategory subcat
on cat.ProductCategoryID = subcat.ProductCategoryID
group by cat.Name


--Prod_Sub_Cat_3) Total revenue by subcategory (which subcategories drive each category's revenue?)

Select subcat.Name, 
Cast (sum(ord.LineTotal) as Decimal(15,2)) as Total_Revenue
from Production.ProductSubcategory subcat left join Production.Product prod
on subcat.ProductSubcategoryID = prod.ProductSubcategoryID
left join Sales.SalesOrderDetail ord on prod.ProductID = ord.ProductID
group by subcat.Name
order by Total_Revenue desc


--------------------
--Product Table EDA
--------------------
--Prod_1) Count of different types of products

Select count(ProductID) as Count_of_diff_products from Production.Product

--Prod_2) Which product color has the maximum number of products

Select color, count(productid) as count_of_prod from Production.Product
where color is not null group by color order by count_of_prod desc

Select count(*) product_count_Color_Null from Production.Product where color is null


--Prod_3) Relationship between MakeFlag, FinishedGoodsFlag, DaysToManufacture, and SafetyStockLevel

--Couldn't find anything meaningful connection between these all:
Select MakeFlag, FinishedGoodsFlag, DaysToManufacture, SafetyStockLevel from Production.Product

Select DaysToManufacture, SafetyStockLevel from Production.Product
group by daystomanufacture,  SafetyStockLevel
order by DaysToManufacture desc

--Prod_4) Product with highest margin (ListPrice vs StandardCost)

Select  distinct top 5 name, Cast ((ListPrice-StandardCost) as decimal(8,2)) as margin 
from Production.Product
order by margin desc

--Prod_5) Relationship between Class and StandardCost/ListPrice

--found direct positive association of standardCost and the class

Select class, min(standardcost) as min_cost, max(standardcost) as max_cost
from Production.Product 
where class is not null
and StandardCost !=0
group by class
order by max_cost desc

--found direct positive association of ListPrice and the class

Select class, min(ListPrice) as min_price, max(ListPrice) as max_price
from Production.Product 
where class is not null
and ListPrice !=0
group by class
order by max_price desc

--found direct positive association of Margin (ListPrice - StandardCost) and the class

With margin_check as(
Select class,  Cast ((ListPrice-StandardCost) as decimal(8,2)) as margin
from Production.Product
where Class is not null and ListPrice-StandardCost !=0
)

Select class, min(margin) as min_margin, max(margin) as max_margin
from margin_check
group by Class
order by max_margin desc


--Prod_6) Anywhere SellEndDate is earlier than SellStartDate (data quality check)

Select * from Production.Product
where SellStartDate>SellEndDate

--Prod_7) Anywhere ModifiedDate falls outside the SellStartDate/SellEndDate window (data quality check)

--There are 98 product meeting this criteria, further investigation requied:
Select * from Production.Product
where ModifiedDate < SellStartDate
or ModifiedDate > SellEndDate

--21848 records are in salesOrderDetail for these 98 products
Select * from sales.SalesOrderDetail ord
where   exists(
Select 1 from Production.Product as p
where p.ProductID = ord.ProductID
and(
ModifiedDate < SellStartDate
or ModifiedDate > SellEndDate)
)

--Prod_8) Products that have never sold a single unit —
--broken down by category (already found: 238 products)

--Count
Select count(*) as prod_not_sold from(
Select prod.ProductID, prod.Name, ord.SalesOrderDetailID
from Production.Product prod left join sales.SalesOrderDetail ord
on prod.ProductID = ord.ProductID
where ord.SalesOrderDetailID is null) as notSOld

--Details
Select prod.ProductID, prod.Name, ord.SalesOrderDetailID
from Production.Product prod left join sales.SalesOrderDetail ord
on prod.ProductID = ord.ProductID
where ord.SalesOrderDetailID is null


------------------------------
--SalesOrderDetail Table EDA
------------------------------
--Sales_Detail_1) Product with most sold quantity

--Performed, even advance analysis, sold count, revenue and avg_revenue by product
Select prod.ProductID, sum(ord.OrderQty) as Total_Qty_Sold, 
cast(sum(ord.lineTotal) as decimal(12,2)) as Total_Revenue,
Cast((sum(ord.linetotal)/sum(ord.orderQty)) as decimal(12,2)) as Avg_Revenue
--(this is inner join, if used left join, then having clause would be required)
from Production.Product prod join sales.SalesOrderDetail ord 
on prod.ProductID = ord.ProductID
group by prod.ProductID
--(The below HAVING clause, would be required if Left Join  is used)
   --having sum(ord.orderqty) is not null  
order by Avg_Revenue desc

--Sales_Detail_2) Compare SalesOrderDetail.UnitPrice against current Product.
--ListPrice (has price changed since sale?)

--Quite surprising, that there are total 250 products (out of 266),
--approx 94% of the products got their prices changed.
--enven interesting fact is, all of these have their prices revised minimum 2 times..
-- and maximum of 1192 times.
--ProductID 897 where only 2 times the price is changed
--ProductID 712 where 1192 times the price is changed

--Total count of unique/distinct products in selling are = 266 
select count( distinct productid) from sales.SalesOrderDetail

--CTE to check the price changes
;With price_change as(
Select prod.ProductID, prod.Name, prod.ListPrice as Listed,
ord.UnitPrice as Selling_Price,
Cast((ord.UnitPrice-prod.ListPrice)as decimal(12,2)) as Price_Diff
from Production.Product prod inner join sales.SalesOrderDetail ord
on prod.ProductID = ord.ProductID
where prod.ListPrice <> ord.UnitPrice),

cte1 as(
Select *,
(Case 
When Price_Diff <0 then 'Down'
else 'Up'
End) as Change_Indicator  --this was created earlier, not in use now
from price_change)
--order by ProductID)

select ProductID, count(productid) as count_of_Product
from cte1
group by ProductID
order by count_of_Product desc

--Sales_Detail_3) Products with highest discounts, and % of line items
--that have no discount at all

--ProductIDs with max discount
Select ProductID, UnitPriceDiscount from sales.SalesOrderDetail
where UnitPriceDiscount = (Select max(UnitPriceDiscount) from sales.SalesOrderDetail)


--(there are total 266 distinct product count)
Select count(distinct productId) from sales.SalesOrderDetail

--This proved, that each product has got discount sometime
;With cte1 as(
Select ProductID, UnitPriceDiscount,
Row_Number() Over(partition by productId order by unitPriceDiscount) as row_num
from sales.SalesOrderDetail
),

cte2 as(
Select ProductID, sum(row_num) as sum_row from cte1
group by ProductID)

Select * from cte2 where sum_row >1


--Sales_Detail_4) Realized revenue using OrderQty*UnitPrice*(1-UnitPriceDiscount)
--vs raw list-price revenue — how much does the discount actually cost?

--Details around all 266 products:
Select ProductID,
Cast(Sum(UnitPrice*OrderQty) as decimal(12,2)) as Revenue,
Cast(Sum(UnitPrice*UnitPriceDiscount) as decimal(12,2))  as Discounted_Amount,
Cast(Sum(UnitPrice*(1-UnitPriceDiscount)) as decimal(12,2)) as Revenue_after_discount
from sales.SalesOrderDetail
group by ProductID
order by Discounted_Amount desc

--Total, Revenue, Discounted Amount and Realized Revenue
With revenue_details as(
Select ProductID,
Cast(Sum(UnitPrice*OrderQty) as decimal(12,2)) as Revenue,
Cast(Sum(UnitPrice*UnitPriceDiscount) as decimal(12,2))  as Discounted_Amount,
Cast(Sum(UnitPrice*(1-UnitPriceDiscount)) as decimal(12,2)) as Revenue_after_discount
from sales.SalesOrderDetail
group by ProductID)

Select sum(revenue) as Total_Revenue, sum(discounted_amount) as Total_Discounted_Amt,
sum(Revenue_after_discount) as Total_Revenue_After_Discount
from revenue_details

--Sales_Detail_5) Distribution of line items per order 
--(do most orders have 1 product, or many?)
Select SalesOrderDetailID, OrderQty
from sales.SalesOrderDetail
order by OrderQty desc

Select OrderQty, count(SalesOrderDetailID) as Order_Counts
from sales.SalesOrderDetail
group by OrderQty
order by Order_Counts desc

--Avg Order per Shipment
;With Avg_orders_per_shipment as(
Select Count(distinct ord.SalesOrderDetailID) as orders_count,
Count(distinct head.SalesOrderID) as shipped_ord_count
from sales.SalesOrderDetail ord join sales.SalesOrderHeader head
on ord.SalesOrderID = head.SalesOrderID)

Select cast(orders_count as decimal(10,2))/
shipped_ord_count as Avg_Ord_Count from Avg_orders_per_shipment

------------------------------
--SalesOrderHeader Table EDA
------------------------------
--Sales_Head_1) Any order shipped on or after DueDate (causing delay)

--None of the shipment matching this:
Select * from sales.SalesOrderHeader
where ShipDate >= DueDate

--Sales_Head_2) Average days from OrderDate to DueDate (planned delivery window)
Select AVG(DATEDIFF(day,OrderDate, DueDate)) as days_count
from sales.SalesOrderHeader

--Sales_Head_3) Average days from OrderDate to ShipDate (actual shipment time)
Select AVG(DATEDIFF(day,OrderDate, ShipDate)) as days_count
from sales.SalesOrderHeader

--Avg Shipment days planned
Select AVG(DATEDIFF(day,ShipDate, DueDate)) as days_count
from sales.SalesOrderHeader

--Sales_Head_4) How many are online orders vs offline

--Online & Offline Order Percentage:
Select
Sum(Case when OnlineOrderFlag = 0 then 1 else 0 end) as 'Offline_Ord_Count',
Sum(Case when OnlineOrderFlag = 1 then 1 else 0 end) as 'Online_Ord_Count',
count(*) as Total_Orders_Type,
Cast((Sum(Case when OnlineOrderFlag = 0 then 1 else 0 end)*100.0/count(*))
as decimal(5,2))as 'Offline',
Cast((Sum(Case when OnlineOrderFlag = 1 then 1 else 0 end)*100.0/count(*))
as decimal(5,2)) as 'Online'
 from sales.SalesOrderHeader


--Sales_Head_5) Most used shipping method

select distinct shipmethodid from sales.SalesOrderHeader

Select ShipMethodID, count(*) as Method_Count from sales.SalesOrderHeader
group by ShipMethodID

--Sales_Head_6) Total revenue by year and by quarter — is growth steady, seasonal, 
--or concentrated?

Select top 3 * from sales.SalesOrderHeader

Select year(orderDate) as years, ceiling(sum(subTotal)) as total_revenue 
from sales.SalesOrderHeader
group by year(orderDate)
order by years

--Sales_Head_7) Average order value (SubTotal) trend across the 3 years
Select year(orderDate) as years, ceiling(sum(subTotal)) as total_revenue,
count(SalesOrderID) as Order_Count,
ceiling(sum(subTotal)/count(SalesOrderID)) as Avg_Order_Value
from sales.SalesOrderHeader
group by year(orderDate)
order by years

------------------------------
--Customer Table EDA
------------------------------
--Cust_1) Total customers, and how many are Store-linked vs individual
--(StoreID null or not)

--random check
Select count(customerID) from sales.Customer where StoreID is null
Select count(customerID) from sales.Customer where StoreID is not null

--random check
Select count(distinct customerId) from sales.Customer
Select count(distinct storeID) from sales.Customer

--Creating VIEW:
--Details around Store linked and Non-Store linked Customers 

Create View vw_customer_store_linkage as

Select
Sum(Case when storeID is not null then 1 else 0 end) as Store_linked_cmr,
Sum(Case when storeID is null then 1 else 0 end) as Non_store_cmr,
count(customerID) as Total_cmr,
cast((Sum(Case when storeID is not null then 1 else 0 end)*100.0/count(customerID)) as decimal(5,2))
as Store_linked_cmr_Percent,
cast((Sum(Case when storeID is null then 1 else 0 end)*100.0/count(customerID)) as decimal(5,2))
as Non_store_cmr_Percent
from sales.Customer 


--(this takes only a summary in one column, where each row can be utilized as a standalone metric)
Select * from vw_customer_store_linkage

--(19820 records, 7 columns, 1 table)
select * from sales.Customer 

--Cust_2) Customers with zero orders (never purchased) vs active customers


--Customers Never Ordered
Select cust.customerID, count(head.SalesOrderID) as order_count
from sales.Customer cust left join sales.SalesOrderHeader head
on cust.CustomerID = head.CustomerID
--below is null, can bring out customers, who never bought
--where head.CustomerID is null 
group by cust.CustomerID
order by order_count desc

--Cust_3) Customer with highest order count and highest total revenue


--Creating VIEW:
Create View vw_customers_orders_revenue as

Select cust.customerID, count(head.SalesOrderID) as order_count,
Cast(sum(head.SubTotal) as decimal(10,2)) as order_value
from sales.Customer cust left join sales.SalesOrderHeader head
on cust.CustomerID = head.CustomerID
group by cust.CustomerID

Select * from sales.Customer
Select * from vw_customers_orders_revenue

Create view vw_store_customer_count as
Select storeId , count(customerId) as customer_count from sales.Customer
group by storeId


------------------------------
--SalesTerritory Table EDA
------------------------------
--Terr_1) Order count and revenue by territory

Select terr.Name, count(head.SalesOrderID) as order_count,
cast(sum(head.SubTotal) as decimal(12,2)) as total_revenue
from sales.SalesTerritory terr left join sales.SalesOrderHeader head
on terr.TerritoryID = head.TerritoryID
group by terr.Name

--Terr_2) Does SalesTerritory's own SalesYTD/SalesLastYear
--match your recalculated revenue from SalesOrderHeader?
--(sanity-check, same idea as the discount check)

--Need to modify above question, not logical check, terr not having date wise:

--Creating VIEW:

Create View vw_territories_yearly_orders_revenues as
Select terr.Name,year(orderDate) as Yrs, count(head.SalesOrderID) as order_count,
cast(sum(head.SubTotal) as decimal(12,2)) as total_revenue
from sales.SalesTerritory terr left join sales.SalesOrderHeader head
on terr.TerritoryID = head.TerritoryID
group by year(orderDate), terr.Name

Select * from vw_territories_yearly_orders_revenues 

------------------------------
--SalesPerson Table EDA
------------------------------
--SP_1) Sales person with highest order count and highest revenue
    
Select  SalesPersonID, count(SalesOrderID) as order_count,
cast(sum(SubTotal) as decimal(12,2)) as total_revenue
from sales.SalesOrderHeader
where SalesPersonID is not null
group by SalesPersonID
order by total_revenue desc



------------------------------
--Address / Person Table EDA
------------------------------

--Addr_1) Distribution of customers by country/state/city (where are customers located?)

--Creating VIEW:
Create View vw_customer_distribution_cities as
Select city, count(*) as count_person from Person.Address
group by city

Select * from vw_customer_distribution_cities
