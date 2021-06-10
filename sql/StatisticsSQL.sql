DROP PROCEDURE IF EXISTS RecommandTest;
DROP PROCEDURE IF EXISTS Normal;
DROP PROCEDURE IF EXISTS PairedTTest;
DROP PROCEDURE IF EXISTS RepeatedMeasuresANOVA;
DROP FUNCTION IF EXISTS `Diff`;
DROP PROCEDURE IF EXISTS `Wilcoxon`;
DROP FUNCTION IF EXISTS `RankRow`;
DROP PROCEDURE IF EXISTS `Friedman`;


DELIMITER //
/****************
** Normal Test **
*****************/
CREATE PROCEDURE Normal(IN tableName varchar(25), IN columnName varchar(25))

BEGIN
	
	# Declare variable
	DECLARE count int DEFAULT 0;
	DECLARE mean FLOAT DEFAULT 0;
	DECLARE g1 FLOAT DEFAULT 0;
	DECLARE g2 FLOAT DEFAULT 0;
	DECLARE z1 FLOAT DEFAULT 0;
	DECLARE z2 FLOAT DEFAULT 0;
	DECLARE mu1 FLOAT DEFAULT 0;
	DECLARE mu2 FLOAT DEFAULT 0;
	DECLARE sigma1 FLOAT DEFAULT 0;
	DECLARE sigma2 FLOAT DEFAULT 0;
	DECLARE k_normal FLOAT DEFAULT 0;
	DECLARE p_normal FLOAT DEFAULT 0;
	DECLARE NormalResult varchar(10) DEFAULT "";
	DECLARE comment varchar(100) DEFAULT "";

	# Create table to call
	DROP TEMPORARY TABLE IF EXISTS ValueTable;
	SET @statement = CONCAT('CREATE TEMPORARY TABLE ValueTable SELECT ', columnName, ' AS value FROM ', tableName);
	PREPARE statement FROM @statement;
	EXECUTE statement;
	DEALLOCATE PREPARE statement;

	# Calculate count, mean
	SELECT COUNT(*), AVG(value) INTO count, mean FROM ValueTable;

	# Add 4 column to table
	ALTER TABLE ValueTable
	ADD COLUMN g1Up FLOAT,
	ADD COLUMN Down FLOAT,
	ADD COLUMN g2Up FLOAT;

	# Calculate each row's number for g1 & g2
	UPDATE ValueTable 
	SET 
		g1Up = POWER(value - mean, 3),
		Down = POWER(value - mean, 2),
		g2Up = POWER(value - mean, 4);

	# Calculate g1 & g2
	SELECT SUM(g1Up) / (POWER(COUNT(*), 3/2) * POWER(SUM(Down), 3/2)) INTO g1 FROM ValueTable;
	SELECT SUM(g2Up) / (POWER(COUNT(*), 2) * POWER(SUM(Down), 2)) INTO g2 FROM ValueTable;
	
	# Calculate mu2 & sigma1 & sigma2
	SELECT -6 / (COUNT(*) + 1) INTO mu2 FROM ValueTable;
	SELECT POWER(6 * (COUNT(*) - 2) / ((COUNT(*) + 1) * (COUNT(*) + 3)), 1/2) INTO sigma1 FROM ValueTable;
	SELECT POWER(24 * COUNT(*) * (COUNT(*) - 2) * (COUNT(*) - 3) / (POWER(COUNT(*) + 1, 2) * (COUNT(*) + 3) * (COUNT(*) + 5)), 1/2) INTO sigma2 FROM ValueTable;

	# Calculate z1 & z2
	SET z1 = (g1 - mu1) / sigma1;
	SET z2 = (g2 - mu2) / sigma2;

	# Calculate k
	SET k_normal = POWER(z1, 2) + POWER(z2, 2);

	# Find corresponding p of k
	SELECT COUNT(*) / 1000 INTO p_normal FROM ChiSquareTable WHERE k >= k_normal;

	# Set result values
	IF p_normal > 0.005 AND count < 20 THEN
		SET NormalResult = "True";
		SET comment = "Suggest treat as non-normal because of small sample size";
	ELSEIF p_normal > 0.005 THEN
		SET NormalResult = "True";
	ELSE
		SET NormalResult = "False";
	END IF;

	# Create reault table
	DROP TABLE IF EXISTS TestNormalResult;
	CREATE TABLE TestNormalResult (
		Normality varchar(10) NOT NULL,
		p float NOT NULL PRIMARY KEY,
		Comment varchar(100)
	);
	INSERT INTO TestNormalResult
	VALUES
	(NormalResult, p_normal, comment);

	SELECT * FROM TestNormalResult;

END //


/*******************
** Recommand Test **
********************/
CREATE PROCEDURE RecommandTest(
	IN withinGroup BOOL, 
	IN numercial BOOL,
	IN parametric BOOL, 
	IN groupNum int
)

BEGIN
	
	DROP TABLE IF EXISTS RecommandTable;
	CREATE TABLE RecommandTable(
		recommandTest varchar(50) DEFAULT "",
		functionUsage varchar(200) DEFAULT "",
		PRIMARY KEY(recommandTest)
	);

	IF withinGroup IS TRUE AND numercial IS TRUE AND parametric IS TRUE AND groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("Paired T-test", "CALL PairedTTest({PrimaryKey}, {Table1}, {Tabel1_Column}, {Table2}, {Tabel2_Column}, @t, @p);");
	ELSEIF withinGroup IS TRUE AND numercial IS TRUE AND parametric IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("Repeated measures ANOVA", "CALL RepeatedMeasuresANOVA({PrimaryKey}, {Table1}, {Table2}, {Table3}, {Tabel1_Column}, {Tabel2_Column}, {Tabel3_Column}, @p);");
	ELSEIF withinGroup IS TRUE AND numercial IS TRUE AND groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("Wilcoxon's matched pairs signed rank test", "CALL Wilcoxon({PrimaryKey_ID}, {Table1}, {Table2}, {Tabel1_Column}, {Tabel2_Column});");
	ELSEIF withinGroup IS TRUE AND numercial IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("Friedman's ANOVA", "CALL Friedman({PrimaryKey_ID}, {Table1}, {Table2}, {Table3}, {Tabel1_Column}, {Tabel2_Column}, {Tabel3_Column});");
	ELSEIF withinGroup IS TRUE AND groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("McNemar's test", "");
		INSERT INTO RecommandTable VALUES ("McNemar's test exact variants", "");
	ELSEIF withinGroup IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("Chchran's Q test", "");

	ELSEIF numercial IS TRUE AND parametric IS TRUE AND groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("Unpaired T-test", "");
	ELSEIF numercial IS TRUE AND parametric IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("ANOVA", "");
		INSERT INTO RecommandTable VALUES ("F-test", "");
	ELSEIF numercial IS TRUE AND groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("Mean-Whitney U test", "");
		INSERT INTO RecommandTable VALUES ("Willcoxon's rank sum test", "");
	ELSEIF numercial IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("Kruskal-Wallis H test", "");
	ELSEIF groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("Chi-square test", "");
		INSERT INTO RecommandTable VALUES ("Fisher's exact test", "");
	ELSE
		INSERT INTO RecommandTable VALUES ("Chi-square test", "");
	END IF;

	SELECT * FROM RecommandTable;

END //




/******************
** Paired T Test **
*******************/
CREATE PROCEDURE PairedTTest(
    IN uidColumnName varchar(64),
    IN table1 varchar(64),
    IN table2 varchar(64),
    IN columnName1 varchar(64),
    IN columnName2 varchar(64),
    OUT p float
)
BEGIN
    DROP TABLE IF EXISTS TempTable;

    SET @statement1 = CONCAT("
        CREATE TABLE
            TempTable
        SELECT 
            t1.", columnName1, " AS column1,
            t2.", columnName2, " AS column2
        FROM
            ", table1, " AS t1
        JOIN
            ", table2, " AS t2
        USING
            ( ", uidColumnName, " );
    ");

    PREPARE statement1 FROM @statement1;
	EXECUTE statement1;
    DEALLOCATE PREPARE statement1;

    WITH 
    X AS (
        SELECT
            column1 - column2 AS X
        FROM
            TempTable
    ),
    stats AS (
        SELECT
            AVG(X) AS X_bar,
            STDDEV_SAMP(X) AS s,
            COUNT(X) AS n
        FROM
            X
    ),
    t AS (
        SELECT
            X_bar / (s / SQRT(n)) AS t
        FROM
            stats
    ),
    df AS (
        SELECT
            n - 1 AS df
        FROM
            stats AS s,
            (
                SELECT DISTINCT df FROM T_Table
            ) AS df_cand
        ORDER BY
            ABS(s.n - 1 - df_cand.df) ASC
        LIMIT 1
    )
    SELECT
        -- t.t,
        -- df.df,
        tt.p
    INTO
        p
    FROM
        t, df
    JOIN
        T_Table AS tt
    USING
        ( df )
    WHERE
        tt.t <= t.t
    ORDER BY
        tt.p ASC
    LIMIT 1;

    DROP TABLE TempTable;

END//


/****************************
** Repeated Measures ANOVA **
*****************************/
CREATE PROCEDURE RepeatedMeasuresANOVA(
    IN keyName varchar(64),
    IN table1 varchar(64),
    IN table2 varchar(64),
    IN table3 varchar(64),
    IN column1 varchar(64),
    IN column2 varchar(64),
    IN column3 varchar(64),
    OUT p float
)
BEGIN
    DECLARE col_name varchar(64);
    DECLARE done INT DEFAULT FALSE;

    DECLARE column_names CURSOR FOR
        SELECT
            column1 AS column_name
        UNION ALL
        SELECT
            column2 AS column_name
        UNION ALL
        SELECT
            column3 AS column_name
    ;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    DROP TABLE IF EXISTS TempTable;
    SET @statement1 = CONCAT("
        CREATE TABLE
            TempTable
        SELECT
            ", keyName, " AS _key,
            t1.", column1, ",
            t2.", column2, ",
            t3.", column3, "
        FROM
            ", table1, " AS t1
        JOIN
            ", table2, " AS t2
        USING
            ( ", keyName, " )
        JOIN
            ", table3, " AS t3
        USING
            ( ", keyName, " )
    ");
    PREPARE statement1 FROM @statement1;
    EXECUTE statement1;
    DEALLOCATE PREPARE statement1;

    DROP TABLE IF EXISTS ColumnName;
    CREATE TABLE ColumnName
    SELECT
        column_name
    FROM
        information_schema.columns
    WHERE
        table_name = "TempTable"
    ;
    
    OPEN column_names;
    SET @case_str = "";
    a: LOOP
        IF done THEN
            CLOSE column_names;
            LEAVE a;
        END IF;

        FETCH column_names INTO col_name;
        -- SELECT col_name;
        SET @case_str = CONCAT(@case_str, "WHEN '", col_name, "' THEN ", col_name, "\n");
    END LOOP a;

    DROP TABLE IF EXISTS TransposeTempTable;
    SET @statement1 = CONCAT("
        CREATE TABLE
            TransposeTempTable
        SELECT
            _key,
            column_name,
            CASE column_name 
                ", @case_str ,"
            END AS value
        FROM
            TempTable
        CROSS JOIN
            ColumnName
        WHERE
            column_name != '_key'
    ");
    PREPARE statement1 FROM @statement1;
    EXECUTE statement1;
    DEALLOCATE PREPARE statement1;

    SET @F = "";
    SET @n = "";
    WITH
    n AS (
        SELECT
            COUNT(1) AS n
        FROM
            TempTable
    ),
    k AS (
        SELECT
            COUNT(1) AS k
        FROM
            ColumnName
    ),
    row_avg AS (
        SELECT
            _key,
            AVG(value) AS row_avg
        FROM
            TransposeTempTable
        GROUP BY
            _key
    ),
    col_avg AS (
        SELECT
            column_name,
            AVG(value) AS col_avg
        FROM
            TransposeTempTable
        GROUP BY
            column_name
    ),
    all_avg AS (
        SELECT
            AVG(col_avg) AS all_avg
        FROM
            col_avg
    ),
    pre_ss_model AS (
        SELECT
            SUM(POWER(col_avg - all_avg, 2)) AS pre_ss_model
        FROM
            col_avg, all_avg
    ),
    ss_model AS (
        SELECT
            n * pre_ss_model AS ss_model
        FROM
            pre_ss_model, n
    ),
    ms_model AS (
        SELECT
            ss_model / (k - 1) AS ms_model
        FROM
            ss_model, k
    ),
    pre_ss_error AS ( 
        SELECT
            SUM(POWER(value - row_avg, 2)) AS pre_ss_error
        FROM
            TransposeTempTable
        JOIN
            row_avg
        USING
            ( _key )
    ),
    ss_error AS (
        SELECT
            pre_ss_error - ss_model AS ss_error
        FROM
            pre_ss_error, ss_model
    ),
    ms_error AS (
        SELECT
            ss_error / ((k - 1) * (n - 1)) AS ms_error
        FROM
            ss_error, k, n
    )
    SELECT
        ms_model / ms_error AS F,
        n
    INTO
        @F,
        @n
    FROM
        ms_model, ms_error, n;

    SET @statement1 = CONCAT("
        SELECT
            P_Value
        INTO
            @p
        FROM
            Repeated_p_table
        WHERE
            N_", @n - 1 , " <= ", @F, "
        ORDER BY
            P_Value ASC
        LIMIT 1
    ");
    PREPARE statement1 FROM @statement1;
    EXECUTE statement1;
    DEALLOCATE PREPARE statement1;

    SELECT @p INTO p;

    DROP TABLE TempTable;
    DROP TABLE ColumnName;
    DROP TABLE TransposeTempTable;
END//



/*************
** Wilcoxon **
**************/
-- Calculate difference between two values

CREATE FUNCTION Diff(param1 float, param2 float) RETURNS float DETERMINISTIC
	BEGIN
	DECLARE difference float;
	SET difference = param2 - param1;
	RETURN difference;
	END //

-- Wilconxon algorithm
CREATE PROCEDURE `Wilcoxon`(IN uid varchar(25), IN table1 varchar(25), IN table2 varchar(25), IN columnName1 varchar(25), IN columnName2 varchar(25), OUT p FLOAT(4,3))
	BEGIN
		-- set up variables
		DECLARE totalRowNumber INT DEFAULT 1;
		DECLARE negativeM FLOAT DEFAULT 0;
		DECLARE positiveM FLOAT DEFAULT 0;
		DECLARE rValue FLOAT DEFAULT 0;
		DECLARE pColumnName varchar(20);

		DROP TEMPORARY TABLE IF EXISTS `TempTable`;
		DROP TABLE IF EXISTS `RankTable`;
		CREATE TABLE RankTable(
			UserID int NOT NULL,
			Difference float,
			Absolute float,
			Ranking float,
			PRIMARY KEY(UserID)
		);

		-- Get difference between column1 and column2
		SET @statement1 = CONCAT('CREATE TEMPORARY TABLE TempTable SELECT t1.', uid ,' AS UserID, t1.', columnName1, ' AS column1, t2.', columnName2, ' AS column2, Diff(t1.', columnName1, ', t2.', columnName2, ') AS difference FROM ', table1, ' AS t1, ', table2, ' AS t2 WHERE t1.', uid ,' = t2.', uid ,';');
		PREPARE stmt1 FROM @statement1;
		EXECUTE stmt1;
		DEALLOCATE PREPARE stmt1;

		-- Get absolute difference value & remove 0
		INSERT INTO RankTable(UserID, Difference, Absolute)
		SELECT UserID, Difference, ABS(Difference)
		FROM TempTable
		WHERE ABS(Difference) > 0;

		DROP TEMPORARY TABLE TempTable;

		--  count rows
		SELECT COUNT(*)
		INTO totalRowNumber
		FROM RankTable;

		-- Set default rank
		SET @var:=0;
		UPDATE RankTable SET Ranking=(@var:=@var+1) ORDER BY Absolute ASC;
		ALTER TABLE RankTable AUTO_INCREMENT=1; 


		-- Group the same value together for the ranking
		CREATE TEMPORARY TABLE TempTable
		SELECT rt.Absolute AS AbsoluteGroup, COUNT(rt.Absolute) AS Total, SUM(rt.Ranking)/COUNT(rt.Absolute) AS TiedRank
		FROM RankTable AS rt
		GROUP BY rt.Absolute
		ORDER BY AbsoluteGroup;

		-- Update the ranking
		UPDATE RankTable AS rt, (SELECT * FROM TempTable) AS tempt
		SET rt.Ranking = tempt.TiedRank
		WHERE tempt.AbsoluteGroup = rt.Absolute;

		-- Select ranking if its difference is negative (M-)
		SELECT SUM(rt.Ranking) INTO negativeM
		FROM RankTable AS rt
		WHERE rt.Difference < 0;

		-- Select ranking if its difference is positive (M+)
		SELECT SUM(rt.Ranking) INTO positiveM
		FROM RankTable AS rt
		WHERE rt.Difference > 0;

		-- Choose the smaller number as R
		IF positiveM > negativeM THEN
			SET rValue = negativeM;
		ELSEIF positiveM <= negativeM THEN
			SET rValue = positiveM;
		END IF;


		-- SELECT rValue; 
		SET pColumnName = concat('N', '_', CAST(totalRowNumber AS CHAR(5)));
		SET @result_p := 1.11;
		SET @prepS = CONCAT('SELECT Min(', pColumnName, ') INTO @result_p FROM Wilconxon_p_table WHERE R_Value >= ', rValue);
		PREPARE stmt FROM @prepS;
		EXECUTE stmt;

		SELECT @result_p INTO p;
		
		DROP TEMPORARY TABLE TempTable;
		DROP TABLE RankTable;
	END//


/********************
** Friedman's Test **
*********************/
CREATE FUNCTION RankRow(col1 float, col2 float, col3 float) RETURNS float DETERMINISTIC
	BEGIN
	DECLARE rankNumber float;
		IF col1 < col2 THEN
			IF col1 < col3 THEN
				SET rankNumber = 1;
			ELSEIF col1 > col3 THEN
				SET rankNumber = 2;
			ELSEIF col1 = col3 THEN
				SET rankNumber = 1.5;
			END IF;
		ELSEIF col1 > col2 THEN
			IF col1 < col3 THEN
				SET rankNumber = 2;
			ELSEIF col1 > col3 THEN
				SET rankNumber = 3;
			ELSEIF col1 = col3 THEN
				SET rankNumber = 2.5;
			END IF;
		ELSEIF col1 = col2 THEN
			IF col1 < col3 THEN
				SET rankNumber = 1.5;
			ELSEIF col1 > col3 THEN
				SET rankNumber = 2.5;
			ELSEIF col1 = col3 THEN
				SET rankNumber = 2;
			END IF;
		END IF;
	RETURN rankNumber;
	END //

-- Friedman's ANOVA
CREATE PROCEDURE `Friedman`(IN uid varchar(25), IN table1 varchar(25), IN table2 varchar(25), IN table3 varchar(25), IN columnName1 varchar(25), IN columnName2 varchar(25), IN columnName3 varchar(25), OUT p FLOAT(4,3))
	BEGIN
		DECLARE sumCol1 FLOAT DEFAULT 0;
		DECLARE sumCol2 FLOAT DEFAULT 0;
		DECLARE sumCol3 FLOAT DEFAULT 0;
		DECLARE powSum FLOAT DEFAULT 0;

		DECLARE cValue FLOAT DEFAULT 0;
		DECLARE tValue1 FLOAT DEFAULT 0;
		DECLARE tValue2 FLOAT DEFAULT 0;
		DECLARE tempValue FLOAT DEFAULT 0;
		DECLARE totalRowNumber INT DEFAULT 1;

		DROP TEMPORARY TABLE IF EXISTS `TempTable`;
		DROP TABLE IF EXISTS `RankTable`;
		CREATE TABLE RankTable(
			UserID int NOT NULL,
			Ranking1 float DEFAULT 1,
			Ranking2 float DEFAULT 2,
			Ranking3 float DEFAULT 3,
			PRIMARY KEY(UserID)
		);

		-- Get difference between column1 and column2
		SET @statement2 = CONCAT('CREATE TEMPORARY TABLE TempTable SELECT t1.', uid ,' AS UserID, t1.', columnName1, ' AS column1, t2.', columnName2, ' AS column2, t3.', columnName3, ' AS column3 FROM ', table1, ' AS t1, ', table2, ' AS t2, ', table3, ' AS t3 WHERE t1.', uid ,' = t2.', uid ,' AND t1.', uid ,' = t3.', uid ,';');
		PREPARE stmt2 FROM @statement2;
		EXECUTE stmt2;
		DEALLOCATE PREPARE stmt2;

		-- Rank each row: 1-3
		INSERT INTO RankTable(UserID, Ranking1, Ranking2, Ranking3)
		SELECT UserID, RankRow(column1, column2, column3) AS r1, RankRow(column2, column1, column3) AS r2, RankRow(column3, column2, column1) AS r3
		FROM TempTable;

		-- summed rank in each column
		SELECT SUM(Ranking1), SUM(Ranking2), SUM(Ranking3)
		INTO sumCol1, sumCol2, sumCol3
		FROM RankTable; 

		-- quadratic sum of all ranks: A
		SELECT SUM(POWER(Ranking1, 2)+ POWER(Ranking2, 2)+POWER(Ranking3, 2))
		INTO powSum
		FROM RankTable; 

		--  count rows: B
		SELECT COUNT(*)
		INTO totalRowNumber
		FROM RankTable;

		-- calculate C
		SET cValue = (totalRowNumber * 3 * POWER(3+1, 2))/4;
		-- calculate T1
		SET tempValue = POWER(sumCol1-totalRowNumber*(3+1)/2, 2) + POWER(sumCol2-totalRowNumber*(3+1)/2, 2) + POWER(sumCol3-totalRowNumber*(3+1)/2, 2);
		SET tValue1 = ((3-1) * tempValue) /(powSum-cValue);
		-- calculate T2 using T1
		SET tValue2 = ((totalRowNumber-1)*tValue1) / (totalRowNumber*(3-1) - tValue1);

		-- SELECT tValue2 AS T2;

		SET @pColumnName = concat('N', '_', CAST(totalRowNumber AS CHAR(5)));
		SET @result_p := 1.11;
		SET @prepS = CONCAT('SELECT Count(', @pColumnName, ')*0.001 INTO @result_p FROM Friedman_p_table WHERE ', @pColumnName, ' > ', tValue2,'');
		PREPARE stmt FROM @prepS;
		EXECUTE stmt;

		SELECT @result_p INTO p;

		DROP TEMPORARY TABLE TempTable;
		DROP TABLE RankTable;
	END//

DELIMITER ;
