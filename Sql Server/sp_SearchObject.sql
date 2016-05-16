
CREATE  PROCEDURE DBO.SP_SEARCHOBJECT   
(  
	@OBJECTNAME SYSNAME  
	, @XTYPE VARCHAR(2) = NULL  
	, @SPECIFIC BIT = 0  
	, @FIRSTFOUNDOBJECT VARCHAR(700) = NULL OUTPUT  
) 
AS  
BEGIN  
	SET NOCOUNT ON  
   
	DECLARE 
		@OBJECT VARCHAR(255)  
		, @DBNAME VARCHAR(255)  
		, @STRQUERY VARCHAR(1000)  
		, @STRWHERE VARCHAR(100)  
		, @CRLF CHAR(2)  
		, @CTMAX INT  
   
	SELECT 
		@OBJECT = PARSENAME(@OBJECTNAME, 1)  
		, @DBNAME = PARSENAME(@OBJECTNAME, 3)  
		, @STRWHERE = ''  
		, @CRLF = CHAR(13) + CHAR(10)  
   
	CREATE TABLE #RESULTS ( DBNAME VARCHAR(30), OBJECTNAME SYSNAME, XTYPE VARCHAR(2) )  
	-- DECLARE @RESULTS TABLE ( DBNAME VARCHAR(30), OBJECTNAME SYSNAME, XTYPE VARCHAR(2) )  
   
	IF @XTYPE IS NOT NULL  
		SELECT @STRWHERE = 'AND XTYPE = ''' + @XTYPE + ''''  
	ELSE  
		SELECT @STRWHERE = 'AND XTYPE IN (''U'',''V'',''P'',''FN'',''IF'',''TF'',''TR'')'  
   
	IF @DBNAME IS NOT NULL  
	BEGIN  
		SELECT @STRQUERY = 'SELECT ''' + @DBNAME + ''',NAME,XTYPE' + @CRLF  
		+ 'FROM [' + @DBNAME + ']..SYSOBJECTS WHERE NAME '  
		, @STRQUERY = @STRQUERY + CASE @SPECIFIC WHEN 0 THEN 'LIKE ''%' + @OBJECT + '%''' ELSE '= ''' + @OBJECT + '''' END  
		+ @CRLF + @STRWHERE  
	
		--  INSERT INTO #RESULTS  
		--  EXEC(@STRQUERY)   ---------------------------------------------------
  
		SET @STRQUERY = 'INSERT INTO #RESULTS ' + @STRQUERY
		EXEC (@STRQUERY)

	END  
	ELSE  
	BEGIN  
		SELECT ROWID = IDENTITY(INT,1,1), DBNAME = NAME  
		INTO #DATABASES  
		FROM MASTER..SYSDATABASES  
		--WHERE STATUS < 2048  
	
		SELECT @CTMAX = MAX(ROWID) FROM #DATABASES  
	
		WHILE @CTMAX > 0  
		BEGIN  
			SELECT @STRQUERY = 'SELECT ''' + DBNAME + ''',NAME,XTYPE' + @CRLF  
			+ 'FROM [' + DBNAME + ']..SYSOBJECTS WHERE NAME '  
			, @STRQUERY = @STRQUERY + CASE @SPECIFIC WHEN 0 THEN 'LIKE ''%' + @OBJECT + '%''' ELSE '= ''' + @OBJECT + '''' END  
			+ @CRLF + @STRWHERE  
			FROM #DATABASES   
			WHERE ROWID = @CTMAX  
	 
			--   INSERT INTO #RESULTS 
			--   EXEC(@STRQUERY)  

			SET @STRQUERY = 'INSERT INTO #RESULTS ' + @STRQUERY
			EXEC (@STRQUERY)
	 
			SELECT @CTMAX = @CTMAX - 1  
		END  
	END  
   
	IF @FIRSTFOUNDOBJECT IS NULL  
		SELECT DBNAME, XTYPE, OBJECTNAME  
		FROM #RESULTS   
		ORDER BY DBNAME, XTYPE, OBJECTNAME  
   
	SELECT TOP 1 @FIRSTFOUNDOBJECT = DBNAME + '.' + XTYPE + '.' + OBJECTNAME  
	FROM #RESULTS   
	ORDER BY DBNAME, XTYPE, OBJECTNAME  
END  
GO