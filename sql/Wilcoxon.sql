/***** Store Function and Store Procedure *****/
-- Calculate difference between two values
DELIMITER //
CREATE FUNCTION Diff(param1 float, param2 float) RETURNS float DETERMINISTIC

BEGIN
DECLARE difference float;
SET difference = param2 - param1;
RETURN difference;
END //

-- Wilconxon algorithm
DROP PROCEDURE IF EXISTS `Wilcoxon`//
CREATE PROCEDURE `Wilcoxon`(IN uid varchar(25), IN table1 varchar(25), IN table2 varchar(25), IN columnName1 varchar(25), IN columnName2 varchar(25))
	BEGIN
		-- set up variables
		DECLARE totalRowNumber INT DEFAULT 1;
		DECLARE negativeM FLOAT DEFAULT 0;
		DECLARE positiveM FLOAT DEFAULT 0;

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

		ALTER TABLE RankTable ORDER BY Absolute ASC;

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

		SELECT * FROM TempTable;

		-- Update the ranking
		UPDATE RankTable AS rt, (SELECT * FROM TempTable) AS tempt
		SET rt.Ranking = tempt.TiedRank
		WHERE tempt.AbsoluteGroup = rt.Absolute;

		SELECT * FROM RankTable ORDER BY Absolute ASC;

		-- Select ranking if its difference is negative (M-)
		SELECT SUM(rt.Ranking) INTO negativeM
		FROM RankTable AS rt
		WHERE rt.Difference < 0;

		-- Select ranking if its difference is positive (M+)
		SELECT SUM(rt.Ranking) INTO positiveM
		FROM RankTable AS rt
		WHERE rt.Difference > 0;

		SELECT positiveM;
		SELECT negativeM;
		
		DROP TEMPORARY TABLE TempTable;
		DROP TABLE RankTable;
	END//
DELIMITER ;