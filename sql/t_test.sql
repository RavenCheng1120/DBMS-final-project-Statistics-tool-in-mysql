DROP PROCEDURE IF EXISTS PairedTTest;

DELIMITER $$

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

END$$

DELIMITER ;

-- CALL PairedTTest("UserNum", "normal", "normal", "pretest", "midtest", @p);
-- SELECT ROUND(@p, 3) AS p;
