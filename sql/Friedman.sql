DELIMITER //
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
DROP PROCEDURE IF EXISTS `Friedman`//
CREATE PROCEDURE `Friedman`(IN uid varchar(25), IN table1 varchar(25), IN table2 varchar(25), IN table3 varchar(25), IN columnName1 varchar(25), IN columnName2 varchar(25), IN columnName3 varchar(25))
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

		SELECT * FROM RankTable;

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

		SELECT tValue2 AS T2;

	END//
DELIMITER ;