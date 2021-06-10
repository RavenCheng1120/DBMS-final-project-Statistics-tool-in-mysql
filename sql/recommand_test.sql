DELIMITER //

DROP PROCEDURE IF EXISTS RecommandTest;
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
		INSERT INTO RecommandTable VALUES ("Paired T-test", 
			"CALL PairedTTest({PrimaryKey}, {Table1}, {Table2}, {Tabel1_Column}, {Tabel2_Column}, @p);");
	ELSEIF withinGroup IS TRUE AND numercial IS TRUE AND parametric IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("Repeated measures ANOVA", 
			"CALL RepeatedMeasuresANOVA({PrimaryKey}, {Table1}, {Table2}, {Table3}, {Tabel1_Column}, {Tabel2_Column}, {Tabel3_Column}, @p);");
	ELSEIF withinGroup IS TRUE AND numercial IS TRUE AND groupNum < 3 THEN
		INSERT INTO RecommandTable VALUES ("Wilcoxon's matched pairs signed rank test", 
			"CALL Wilcoxon({PrimaryKey_ID}, {Table1}, {Table2}, {Tabel1_Column}, {Tabel2_Column},  @Wilcoxon_p);");
	ELSEIF withinGroup IS TRUE AND numercial IS TRUE THEN
		INSERT INTO RecommandTable VALUES ("Friedman's ANOVA", 
			"CALL Friedman({PrimaryKey_ID}, {Table1}, {Table2}, {Table3}, {Tabel1_Column}, {Tabel2_Column}, {Tabel3_Column}, @Friedman_p);");
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

DELIMITER ;