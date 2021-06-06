import csv

from mysql.connector import MySQLConnection


USR = "root"
PWD = ""


if __name__ == "__main__":
    db = MySQLConnection(user=USR, password=PWD, database="statisticsdb")
    cursor = db.cursor(dictionary=True)
    cursor.execute("DROP TABLE IF EXISTS T_Table")
    cursor.execute("""
        CREATE TABLE T_Table (
            df int NOT NULL,
            t float NOT NULL,
            p float NOT NULL,
            PRIMARY KEY (df, t)
        )
    """)

    with open("TTable.csv") as file:
        reader = csv.DictReader(file, fieldnames=["df", "t", "p"])
        for row in reader:
            cursor.execute(f"""
                INSERT INTO T_Table
                VALUES
                (
                    {row["df"]},
                    {row["t"]},
                    {row["p"]}
                )
            """)
        db.commit()

    cursor.close()
    db.close()
