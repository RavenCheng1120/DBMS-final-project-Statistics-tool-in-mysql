DELIMITER //

DROP PROCEDURE IF EXISTS Normal;
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

DELIMITER ;