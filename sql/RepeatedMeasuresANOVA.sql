DROP PROCEDURE IF EXISTS RepeatedMeasuresANOVA;

DELIMITER $$

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
            N_", @n - 1, " DESC
        LIMIT 1
    ");
    PREPARE statement1 FROM @statement1;
    EXECUTE statement1;
    DEALLOCATE PREPARE statement1;

    SELECT @p INTO p;

    DROP TABLE TempTable;
    DROP TABLE ColumnName;
    DROP TABLE TransposeTempTable;
END$$

DELIMITER ;

-- CALL RepeatedMeasuresANOVA("UserNum", "normal", "normal", "normal", "pretest", "midtest", "posttest", @p);
-- SELECT ROUND(@p, 3) AS p;
