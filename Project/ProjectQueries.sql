--מטלה 1

--בדיקת המידה הנפוצה ביותר עבור כל נעל
SELECT DISTINCT PR.Name, v.Size, [Num Of Orders]=Sum(OC.Quantity)
FROM dbo.PRODUCTS AS PR JOIN dbo.VERSIONS AS V ON V.ProductID = PR.ProductID 
	JOIN dbo.ORDERSCONTENT AS OC ON OC.ProductID = PR.ProductID
WHERE PR.CATEGORY = ('Shoe')
GROUP BY PR.Name, V.Size
ORDER BY [Num Of Orders] DESC

--בדיקת המדינות בהן נמכרו פחות מ-20,000 יחידות של אקססוריז ב5 השנים האחרונות.
SELECT Country= c.[Address-Country], [Num Of Units Ordered] = SUM(OC.Quantity)
FROM dbo.CUSTOMERS AS C JOIN dbo.CREDITCARDS AS CC ON CC.CustomerID = C.Email 
	JOIN dbo.ORDERS AS O ON O.CardNumber = CC.CardNumber
	JOIN dbo.ORDERSCONTENT AS OC ON OC.OrderID = O.OrderID
	JOIN dbo.PRODUCTS AS P ON P.ProductID = OC.ProductID
WHERE p.CATEGORY = ('Accessories') AND YEAR(o.OrderDate) BETWEEN '2016' AND '2021'
GROUP BY c.[Address-Country]
HAVING	SUM(OC.Quantity) < 200
ORDER BY [Num Of Units Ordered]

--הצגת מוצרים שלא נמכרו בשנתיים האחרונות
SELECT ProductID
FROM PRODUCTS 
WHERE ProductID NOT IN( SELECT ProductID
FROM dbo.ORDERSCONTENT AS oc JOIN dbo.ORDERS AS o ON o.OrderID = oc.OrderID
WHERE YEAR(o.OrderDate) BETWEEN 2019 AND 2021)

--בדיקת היחס בין סך כל ההכנסות של החברה לבין כל קטגוריה

SELECT P.CATEGORY, [Total Revenue] = SUM(V.Price*OC.Quantity), RATIO = 
 (SUM(V.Price*OC.Quantity)/ (SELECT
	 SUM(V.Price*oc.Quantity)
	FROM VERSIONS AS V JOIN ORDERSCONTENT AS OC ON V.ProductID=OC.ProductID
	JOIN ORDERS AS O ON OC.OrderID=O.OrderID
	JOIN PRODUCTS AS P ON P.ProductID=V.ProductID))
FROM VERSIONS AS V JOIN ORDERSCONTENT AS OC ON V.ProductID=OC.ProductID
	JOIN ORDERS AS O ON OC.OrderID=O.OrderID
	JOIN PRODUCTS AS P ON P.ProductID=V.ProductID
 GROUP BY P.CATEGORY


 --שאילתת Update

ALTER TABLE dbo.ORDERS
   ADD TotalPrice MONEY ;
   UPDATE dbo.ORDERS SET TotalPrice= ISNULL(TotalPrice,0);
	
UPDATE ORDERS SET TotalPrice = (SELECT SUM(V.Price*oc.Quantity)
FROM VERSIONS AS V JOIN ORDERSCONTENT AS OC ON V.ProductID=OC.ProductID 
WHERE OC.OrderID=ORDERS.OrderID
		)

-- שאילתת חיסור
SELECT  DISTINCT CustomerID
FROM dbo.ORDERS JOIN dbo.CREDITCARDS ON CREDITCARDS.CardNumber = ORDERS.CardNumber
EXCEPT
SELECT DISTINCT CustomerID
FROM dbo.CUSTOMINORDER JOIN dbo.ORDERS ON ORDERS.OrderID = CUSTOMINORDER.OrderID
	JOIN dbo.CREDITCARDS ON CREDITCARDS.CardNumber = ORDERS.CardNumber 


-----------------------------------------------------
-- מטלה 2
CREATE VIEW View_CountriesOrders AS 
SELECT   DISTINCT Country=  C.[Address-Country] ,ProductsOrdered=  SUM(oc.Quantity), [Year Of Orders] = YEAR(O.OrderDate)
FROM dbo.CUSTOMERS AS C JOIN dbo.CREDITCARDS AS CC ON CC.CustomerID = C.Email 
JOIN dbo.ORDERS AS O ON O.CardNumber = CC.CardNumber JOIN
dbo.ORDERSCONTENT AS OC ON OC.OrderID = O.OrderID
GROUP BY   C.[Address-Country], YEAR(O.OrderDate)

SELECT *
FROM View_CountriesOrders
WHERE ProductsOrdered<200 AND [Year Of Orders]='2020'
ORDER BY ProductsOrdered DESC

--פונקציות

--מחזירה ערך יחיד, מספר המוצרים בכל הזמנה
-- DROP FUNCTION NumOfProductsInOrders
CREATE FUNCTION NumOfProductsInOrders (@OID INT)
RETURNS	INT
AS	BEGIN
	DECLARE	@Sum INT
	SELECT @Sum=COUNT(DISTINCT ProductID)
	FROM ORDERSCONTENT
	WHERE OrderID=@OID
	RETURN @Sum
	END

	SELECT ORDERD=(dbo.NumOfProductsInOrders(1))
	FROM ORDERSCONTENT

--פונקציה המחזירה טבלה

--DROP FUNCTION CustomerOrders
CREATE FUNCTION CustomerOrders (@CID VARCHAR (50))
RETURNS @cOrders
TABLE ([orderID] VARCHAR(50), [Total Price] MONEY)
AS
BEGIN
INSERT @cOrders ([orderID], [Total Price])
SELECT O.OrderID, SUM(OC.Quantity*O.TotalPrice)
FROM ORDERSCONTENT AS OC JOIN ORDERS AS O ON O.OrderID = OC.OrderID JOIN dbo.CREDITCARDS AS CC ON CC.CardNumber = O.CardNumber
	JOIN dbo.CUSTOMERS AS CT ON CT.Email = CC.CustomerID
WHERE CC.CustomerID= @CID
GROUP BY O.OrderID
RETURN
END

SELECT *		
FROM dbo.CustomerOrders('MHVJJD@K3RSSC6MSFK.org.il')

--TRIGGER
--עדכון שדה Total Price

CREATE TRIGGER OrderTotalCost
ON orderscontent 
FOR INSERT,UPDATE,DELETE  AS 
UPDATE ORDERS
SET dbo.Orders.TOTALPRICE= (SELECT SUM(OC.Quantity*V.Price)
FROM dbo.ORDERSCONTENT AS OC JOIN dbo.VERSIONS AS V ON V.ProductID = OC.ProductID
	)
	WHERE Orders.OrderID IN (
	SELECT DISTINCT OrderID FROM INSERTED
	UNION
	SELECT DISTINCT OrderID FROM deleted
	)

   UPDATE dbo.ORDERSCONTENT
	SET Quantity=23
	WHERE ProductID=1 AND OrderID=2
--עלות לפני הוספה
	SELECT TotalPrice
	FROM dbo.ORDERS
	WHERE OrderID=2
--ביצוע הוספת כמות יחידות
	UPDATE dbo.ORDERSCONTENT
	SET Quantity=(	SELECT Quantity
	FROM dbo.ORDERSCONTENT
	WHERE OrderID=2)+2
	WHERE ProductID=1 AND OrderID=2
--בדיקת עליית עלות כוללת	
	SELECT TotalPrice
	FROM dbo.ORDERS
	WHERE OrderID=2


--פרוצדורה שמורה
CREATE PROCEDURE Set_Discount @Discount money , @Pid Int 
AS
UPDATE VERSIONS SET Price=Price-(Price*@Discount)

SELECT *
FROM dbo.VERSIONS
EXECUTE set_Discount 0.2,9



--------------------------------------------------
--מטלה 3

-- 5 המדינות הרווחיות ביותר

CREATE VIEW top5inc AS 
SELECT  TOP 5 c.[Address-Country], [TOTAL INCOME]=SUM(OC.Quantity*O.TotalPrice)
FROM dbo.CREDITCARDS AS cc JOIN dbo.CUSTOMERS AS c ON c.Email = cc.CustomerID
    JOIN dbo.ORDERS AS O ON o.CardNumber = cc.CardNumber JOIN ORDERSCONTENT AS OC ON  OC.OrderID = o.OrderID		
	JOIN PRODUCTS AS P ON OC.ProductID=P.ProductID 
WHERE  YEAR(o.orderDate)>=2015 AND c.[Address-Country] IS NOT NULL
GROUP BY c.[Address-Country]
ORDER BY SUM(OC.Quantity*O.TotalPrice) DESC

--המדינות עם שיעור הרווח הנמוך ביותר

CREATE VIEW notprofitable AS 
SELECT  c.[Address-Country], [TOTAL INCOME]=SUM(OC.Quantity*O.TotalPrice)
FROM dbo.CREDITCARDS AS cc JOIN dbo.CUSTOMERS AS c ON c.Email = cc.CustomerID
    JOIN dbo.ORDERS AS O ON o.CardNumber = cc.CardNumber JOIN ORDERSCONTENT AS OC ON  OC.OrderID = o.OrderID		
	JOIN PRODUCTS AS P ON OC.ProductID=P.ProductID 
WHERE  YEAR(o.orderDate)>=2015 AND c.[Address-Country] IS NOT NULL 
GROUP BY c.[Address-Country]
HAVING SUM(OC.Quantity*O.TotalPrice)<2000000
ORDER BY SUM(OC.Quantity*O.TotalPrice) 

-- הכנסות לפי קטגוריות
CREATE VIEW IncomeByCategory AS
SELECT P.CATEGORY, [Total Income] = SUM(O.TotalPrice*OC.Quantity)
FROM PRODUCTS AS P JOIN ORDERSCONTENT AS OC ON P.ProductID=OC.ProductID
	JOIN ORDERS AS O ON O.OrderID=OC.OrderID
GROUP BY P.CATEGORY


--לוח מחוונים

	--DROP VIEW GeneralView
	CREATE VIEW GeneralView AS
	SELECT C.[Address-Country], [Year Of Order] = YEAR(O.OrderDate), [Month Of Order] = MONTH(O.OrderDate),
		[Num Of Orders]=SUM(O.OrderID),	[Total Income]=SUM(OC.Quantity*V.Price)
	FROM ORDERSCONTENT AS OC JOIN PRODUCTS AS P ON OC.ProductID=P.ProductID
		JOIN ORDERS AS O ON O.OrderID=OC.OrderID JOIN CREDITCARDS AS CC ON CC.CardNumber=O.CardNumber
		JOIN CUSTOMERS AS C ON C.Email=CC.CustomerID JOIN VERSIONS AS V ON V.ProductID=P.ProductID
	WHERE C.[Address-Country] IS NOT NULL
	GROUP BY C.[Address-Country], O.OrderDate

	--DROP VIEW AvaragePricePerOrder
	CREATE VIEW AvaragePricePerOrder AS
	SELECT DISTINCT MonthOnYear = MONTH(O.OrderDate), YearOfOrders = YEAR(O.OrderDate), 
		[Avarege Price Per Order] = AVG(O.TotalPrice), [Total Orders]=SUM(O.OrderID)
	FROM PRODUCTS AS P JOIN ORDERSCONTENT AS OC ON P.ProductID=OC.ProductID
		JOIN ORDERS AS O ON O.OrderID=OC.OrderID
	GROUP BY O.OrderDate, O.TotalPrice
	HAVING AVG(O.TotalPrice) IS NOT NULL



------------------------------------------------
--מטלה 4
--כלי מורכב העושה שימוש בסמן 
--פרוצדורה עם לולאה שנותנת ללקוח קופון במידה וקנה החל מסכום מסויים שהצטבר במהלך כל ההזמנות שביצע

	--ALTER TABLE dbo.ORDERS DROP COLUMN Cupon
	ALTER TABLE dbo.ORDERS ADD useCupon DECIMAL(10,2) 
	--ALTER TABLE dbo.CUSTOMERS DROP COLUMN Cupon
	ALTER TABLE dbo.CUSTOMERS ADD Cupon DECIMAL(10,2)
	
	--DROP PROCEDURE SP_Cupon
	CREATE PROCEDURE SP_Cupon (@cupon5 int ,@cupon10 int ,@cupon20 int) 
	AS 
	DECLARE @cEmail varchar(50);
	DECLARE @Total_Price int;
	BEGIN
	DECLARE c1 CURSOR LOCAL FOR
	SELECT CC.CustomerID,TotalOrders=SUM(o.TotalPrice)
    FROM dbo.ORDERS AS o JOIN dbo.CREDITCARDS AS CC  ON CC.CardNumber = o.CardNumber
	GROUP BY CC.CustomerID

	OPEN c1 
	FETCH NEXT FROM c1 INTO @cEmail,@Total_Price
	WHILE (@@FETCH_STATUS=0)
	BEGIN
	UPDATE dbo.CUSTOMERS SET Cupon=(
	CASE WHEN @Total_Price BETWEEN @cupon5 AND @cupon10 THEN 0.05
	WHEN @Total_Price BETWEEN @cupon10 AND @cupon20 THEN 0.1
	WHEN @Total_Price>@cupon20 THEN 0.2 END)
    WHERE @cEmail=Email
	FETCH NEXT FROM c1 INTO @cEmail,@Total_Price
	END
	CLOSE c1
	DEALLOCATE c1
	END
	go
EXECUTE SP_Cupon 20000,50000,100000


--שילוב מערכתי של מספר כלים

--DROP TRIGGER UPDATE_Cupon
  CREATE TRIGGER Update_Cupon 
ON ORDERS
FOR INSERT AS

DECLARE @CUPON DECIMAL(10,2)
DECLARE @ORDER_ID INT 
SET @ORDER_ID=(SELECT inserted.orderID FROM INSERTED)
SET @cupon=(SELECT inserted.useCupon FROM inserted)

EXECUTE SP_CHECK_CUPON @ORDER_ID,@CUPON 
EXECUTE sp_update_totalPrice @ORDER_ID,@CUPON

 --DROP PROCEDURE SP_CHECK_CUPON
 CREATE PROCEDURE  SP_CHECK_CUPON @ORDER_ID int ,@CUPON decimal(10,2)
 AS 
IF (dbo.Check_IF_HAVECUPON(@ORDER_ID)=@CUPON)
UPDATE dbo.CUSTOMERS SET CUPON=0 
WHERE Email =(SELECT cc.customerID FROM dbo.ORDERS AS o JOIN dbo.CREDITCARDS
AS cc ON cc.CardNumber = o.CardNumber WHERE o.OrderID=@ORDER_ID)
ELSE 
UPDATE dbo.ORDERS SET useCupon=0
WHERE OrderID=@ORDER_ID

--drop PROCEDURE sp_update_totalPrice
CREATE PROCEDURE sp_update_totalPrice @ORDER_ID int ,@cupon decimal(10,2)
AS 
UPDATE dbo.ORDERS SET TotalPrice=TotalPrice*(1-@CUPON)
WHERE OrderID=@ORDER_ID

CREATE FUNCTION Check_IF_HAVECUPON(@OID INT) 
 RETURNS decimal(10,2)
 AS BEGIN 
 DECLARE @output DECIMAL(10,2) 
 (SELECT  @output=c.cupon 
 FROM dbo.ORDERS AS o JOIN dbo.CREDITCARDS AS cc ON cc.CardNumber = o.CardNumber JOIN dbo.CUSTOMERS
 AS c ON c.Email = cc.CustomerID
 WHERE o.OrderID=@OID)
 RETURN @output
 END

INSERT INTO dbo.ORDERS
	(
	    OrderID,
	    OrderDate,
	    ETA,
	    TotalPrice,
	    CardNumber,
		usecupon
	)
	VALUES
	(    501,         -- OrderID - int
	    GETDATE(), -- OrderDate - date
	    GETDATE(), -- ETA - date
	    200000,      -- TotalPrice - money
	    '5190554204475847',        -- CardNumber - varchar(20)
		0.2
	    )
		--DELETE FROM dbo.ORDERS WHERE OrderID=501

-- הצגה בהזמנה
SELECT *
		FROM dbo.ORDERS 
		WHERE  OrderID=501

-- מחיקת הקופון לאחר מימושו
SELECT *
FROM dbo.CUSTOMERS
WHERE Email='25MNA8W@QB70YL.com'


--דוח המושתת על שאילתה מקוננת מורכבת

--DROP VIEW VIEW_ORDER_TABLES
 CREATE VIEW View_Order_Tables AS 
 SELECT O.OrderID,CC.CustomerID,O.OrderDate,OC.ProductID,OC.Quantity,O.TotalPrice,CC.CardNumber
 FROM dbo.ORDERS AS O JOIN dbo.ORDERSCONTENT AS OC ON OC.OrderID = O.OrderID 
 JOIN dbo.CREDITCARDS AS CC ON CC.CardNumber = O.CardNumber

 SELECT Email,
 [Last Time Ordered]=(SELECT MAX(OrderDate)
 FROM VIEW_ORDER_TABLES
 WHERE CustomerID=customers.Email
 GROUP BY CustomerID),

 [Favorite Category]=(SELECT T.Category
 FROM (
 SELECT TOP 1 CustomerID,Category, QuantityOrdered=SUM(Quantity)
 FROM dbo.PRODUCTS AS p JOIN VIEW_ORDER_TABLES AS V ON P.ProductID=V.productID
 WHERE  CustomerID=dbo.CUSTOMERS.Email
 GROUP BY CustomerID,p.CATEGORY
 ORDER BY QuantityOrdered desc
 ) AS T
 )
 ,
 [Average Price of Orders]=CAST(ROUND((SELECT tot=(SUM(Quantity*v.Price)/COUNT(DISTINCT OrderID))
 FROM  VIEW_ORDER_TABLES AS VI JOIN dbo.VERSIONS AS v ON v.ProductID = vi.ProductID
 WHERE CustomerID=dbo.CUSTOMERS.Email
 GROUP BY CustomerID
 ),2)AS decimal(10,2)) ,
 
 [Num Of Searches]=(SELECT numOfSearches=COUNT(*) 
 FROM dbo.INTEREST
 WHERE Email=dbo.CUSTOMERS.Email
 GROUP BY Email
 ),
[num of Custom Orders]=ISNULL((
SELECT COUNT(*) 
FROM dbo.CUSTOMINORDER  AS CIO JOIN View_ORDER_Tables AS V ON cio.OrderID=v.orderID
WHERE CustomerID=dbo.CUSTOMERS.Email
GROUP BY CustomerID),0),

[Common Size]=(SELECT CIO.Size
FROM(SELECT TOP 1 CustomerID ,V.Size,[count sizes]=COUNT(V.Size)
FROM VIEW_ORDER_TABLES AS VI
JOIN dbo.VERSIONS AS V ON V.ProductID = VI.ProductID
WHERE CustomerID=dbo.CUSTOMERS.Email
GROUP BY CustomerID,V.Size
ORDER BY [count sizes] desc
) AS CIO
)

  FROM dbo.CUSTOMERS
  WHERE (SELECT MAX(o.OrderDate)
   FROM dbo.ORDERS AS o JOIN dbo.CREDITCARDS AS cc ON cc.CardNumber = o.CardNumber
   WHERE cc.CustomerID=customers.Email) IS NOT NULL
   ORDER BY [Average Price of Orders] DESC



