/***** Store Function and Store Procedure *****/
-- Calculate difference between two values
DELIMITER //
DROP FUNCTION IF EXISTS `Diff`//
CREATE FUNCTION Diff(param1 float, param2 float) RETURNS float DETERMINISTIC
	BEGIN
	DECLARE difference float;
	SET difference = param2 - param1;
	RETURN difference;
	END //

-- Wilconxon algorithm
DROP PROCEDURE IF EXISTS `Wilcoxon`//
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


/***** main *****/
-- CALL Wilcoxon('UserNum', 'conditionA', 'conditionC', 'Immersion', 'Immersion', @Wilcoxon_p);
-- SELECT ROUND(@Wilcoxon_p,3) AS p;