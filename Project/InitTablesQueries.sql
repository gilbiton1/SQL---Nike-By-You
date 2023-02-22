---CREATE tables

CREATE 	TABLE 	CUSTOMERS (
	Email	Varchar(50)	NOT NULL,
	Password	Varchar (20) NOT NULL,	
	Birthdate	Date  NULL,
	[Address-Country]		Varchar (20) NULL,
	[Address-City]		Varchar (50) NULL,
	[Address-PostalCode]	Varchar (20) NULL,
	Currency	Varchar (20) NULL,
	CONSTRAINT pk_Email PRIMARY KEY (Email),
-- 
	)
		ALTER TABLE CUSTOMERS
		ADD CONSTRAINT ck_Password CHECK(DATALENGTH(Password)>=8)
	ALTER TABLE CUSTOMERS
	ADD CONSTRAINT ck_date 
	CHECK (Birthdate< GETDATE());-- check that give valid date
	ALTER TABLE CUSTOMERS 
	ADD CONSTRAINT ck_Email CHECK (Email LIKE '%@%.%');

	CREATE 	TABLE 	PRODUCTS (
	ProductID	int	NOT NULL ,
	Name	Varchar (30) NOT NULL,
	CONSTRAINT pk_ProductID PRIMARY KEY (ProductID),
	CATEGORY	Varchar(30) NOT NULL,

	)
	CREATE TABLE CREDITCARDS (
	CardNumber  VARCHAR(20) NOT NULL ,
	OwnerID		int NOT NULL,
	Expiration	Date NOT NULL,
	CVV			int		NOT NULL,
	CustomerID	Varchar(50)		NOT NULL,
	CONSTRAINT pk_CardNumber PRIMARY KEY (CardNumber),
	CONSTRAINT ck_NumOFDigits CHECK (DATALENGTH(CardNumber) <=16)--check valid number

	)
	ALTER TABLE CREDITCARDS
	ADD CONSTRAINT fk_CDCustomer FOREIGN KEY(CustomerID) REFERENCES CUSTOMERS(Email);


	ALTER TABLE CREDITCARDS
	ADD CONSTRAINT ck_Expiration CHECK (Expiration>GetDate())

	CREATE	TABLE	ORDERS (
	OrderID		int		NOT NULL	 ,
	OrderDate	Date	NOT NULL,
	ETA		Date		NOT NULL,-- we assume that ETA set by the employees
	TotalPrice	Money	NOT NULL,
	CardNumber	VARCHAR(20)	NOT NULL,
	CONSTRAINT pk_OrderID PRIMARY KEY (OrderID),
	)
	ALTER TABLE ORDERS--
	ADD CONSTRAINT fk_CardNum FOREIGN KEY(CardNumber) REFERENCES CREDITCARDS(CardNumber);

	ALTER TABLE ORDERS
	ADD CONSTRAINT ck_price CHECK (TotalPrice>0);-- price must be higher then zero
	
	CREATE	TABLE	ORDERSCONTENT (
	OrderID		int		NOT NULL	 ,
	ProductID	int		NOT NULL,
	Quantity	int		NULL,
	CONSTRAINT pk_ORDERSCONTENT PRIMARY KEY (ProductID,OrderID),
	)
	ALTER TABLE ORDERSCONTENT--
	ADD	CONSTRAINT fk_OrderContentID FOREIGN KEY(OrderID) REFERENCES ORDERS(OrderID) ;

	ALTER TABLE ORDERSCONTENT--
	ADD CONSTRAINT fk_ProductContentID FOREIGN KEY(ProductID) REFERENCES PRODUCTS(ProductID);

	ALTER TABLE ORDERSCONTENT
	ADD CONSTRAINT ck_Quantity CHECK (Quantity>0);-- while make an order the quantity must be more then 1

	CREATE TABLE VERSIONS (
	ProductID int NOT NULL,
	Size	Decimal(10,2)	 NOT NULL,-- 
	Color	Varchar(20) NOT NULL,
	Price	Decimal(10,2)  NULL,
	CONSTRAINT pk_VERSIONS PRIMARY KEY (ProductID,Size,Color),
	)
	ALTER TABLE VERSIONS
	ADD 	CONSTRAINT fk_VersionsProductID FOREIGN KEY(ProductID) REFERENCES PRODUCTS(ProductID);

	ALTER TABLE VERSIONS
	ADD CONSTRAINT ck_Vprice CHECK (Price>0);

	CREATE TABLE CUSTOM (
	ProductID int NOT NULL,
	Size	Decimal(10,2) NOT NULL,
	Color	Varchar(20) NOT NULL,
	Material VARCHAR(30) NOT NULL,
	[color-sole] VARCHAR(20) NOT NULL,
	[color-tongue] VARCHAR(20) NOT NULL,
	[color-heel] VARCHAR(20) NOT NULL,
	PersonalizationContent Varchar(50)  NULL,
	CONSTRAINT pk_CUSTOM PRIMARY KEY (ProductID,Size,Color,[color-sole],[color-tongue],[color-heel])
	)
	ALTER TABLE CUSTOM
	ADD CONSTRAINT fk_CVERSIONS FOREIGN KEY(ProductID,Size, Color)
	REFERENCES VERSIONS(ProductID,Size, Color);

	CREATE TABLE INTEREST (
	Email	Varchar(50) NOT NULL,
	ProductID int NOT NULL,
	Size	Decimal(10,2)	 NOT NULL,
	Color	Varchar(20) NOT NULL,
	CONSTRAINT pk_IEmail PRIMARY KEY (Email,ProductID,Size,Color),
	)

	ALTER TABLE INTEREST
	ADD CONSTRAINT fk_IEmail FOREIGN KEY(Email) REFERENCES CUSTOMERS(Email);

		ALTER TABLE INTEREST
	ADD CONSTRAINT fk_ISizeAndColor FOREIGN KEY(ProductID,Size,Color) REFERENCES VERSIONS(ProductID,Size,Color);

	CREATE TABLE CUSTOMINORDER (
	ProductID int NOT NULL,
	Size	Decimal(10,2) NOT NULL,
	Color	Varchar(20) NOT NULL,
	OrderID		int		NOT NULL	 ,
	[color-sole] VARCHAR(20) NOT NULL,
	[color-tongue] VARCHAR(20) NOT NULL,
	[color-heel] VARCHAR(20) NOT NULL,
	Quantity	int		NULL,
	CONSTRAINT pk_cio PRIMARY KEY (ProductID, Size, Color,OrderID,[color-sole],[color-tongue],[color-heel]),
	)

	ALTER TABLE dbo.CUSTOMINORDER
	ADD CONSTRAINT FK_CIOCUSTOM FOREIGN KEY(ProductID, Size, Color,[color-sole],[color-tongue],[color-heel])
	REFERENCES dbo.CUSTOM(ProductID, Size, Color,[color-sole],[color-tongue],[color-heel]);

	ALTER TABLE dbo.CUSTOMINORDER
	ADD CONSTRAINT FK_CIOORDER FOREIGN KEY(OrderID)
	REFERENCES dbo.ORDERS(OrderID);

	CREATE TABLE COUNTRIES (
	Country Varchar(20) NOT NULL PRIMARY KEY
	)

	ALTER TABLE CUSTOMERS
	ADD CONSTRAINT fk_Countries FOREIGN KEY ([Address-Country]) REFERENCES COUNTRIES (Country);
	
	CREATE TABLE CURRENCIES (
	Currency Varchar(20) NOT NULL PRIMARY KEY,
	)
	
	ALTER TABLE CUSTOMERS
	ADD CONSTRAINT fk_Currencies FOREIGN KEY (Currency) REFERENCES CURRENCIES(Currency);

		CREATE TABLE Categories (
	Category VARCHAR(30) NOT NULL PRIMARY KEY,
	)
	ALTER TABLE PRODUCTS
	ADD CONSTRAINT fk_CategoriesLP FOREIGN KEY (Category) REFERENCES Categories(Category);
	

Create TABLE Sizes (
	Size Decimal(10,2) NOT NULL Primary KEY )
	ALTER TABLE VERSIONS
	ADD CONSTRAINT fk_SizesLP FOREIGN KEY (Size) REFERENCES Sizes (Size)

	ALTER TABLE dbo.ORDERS ADD useCupon DECIMAL(10,2) 

	ALTER TABLE dbo.CUSTOMERS ADD Cupon DECIMAL(10,2)
	-----------------------------------------------------
	--delete  tables code
	DROP TABLE CUSTOMINORDER;
	DROP TABLE CUSTOM;
	DROP TABLE INTEREST;
	DROP TABLE VERSIONS;
	DROP TABLE Sizes;	
	DROP TABLE ORDERSCONTENT;
	DROP TABLE ORDERS;	
	DROP TABLE CREDITCARDS;
	DROP TABLE CUSTOMERS;
	DROP TABLE COUNTRIES;					
	DROP TABLE CURRENCIES
	DROP TABLE PRODUCTS;
	DROP TABLE Categories;

	-------------------------------------------------