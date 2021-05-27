from mysql.connector import MySQLConnection
import numpy as np
from scipy import stats
from tqdm import tqdm


USR = "root"
PWD = ""


if __name__ == "__main__":
    df_list = list(range(1, 100)) + list(range(100, 1000, 100)) + [1000, 10000, 100000]
    p_list = list(np.arange(0.500, 0.000, -0.001))

    t_table = []
    for df in tqdm(df_list):
        t = 0
        for p in p_list:
            p = round(p, 3)

            while stats.t.sf(t, df) > p:
                if t > 10:
                    t += 0.01
                    t = round(t, 2)
                else:
                    t += 0.001
                    t = round(t, 3)

            p_ceil = stats.t.sf(t, df)
            if t > 10:
                p_floor = stats.t.sf(t - 0.01, df)
            else:
                p_floor = stats.t.sf(t - 0.001, df)

            if abs(p - p_ceil) <= abs(p - p_floor):
                t_table.append({"df": df, "t": t, "p": p})
            else:
                if t > 10:
                    t_table.append({"df": df, "t": round(t - 0.01, 2), "p": p})
                else:
                    t_table.append({"df": df, "t": round(t - 0.001, 3), "p": p})

    db = MySQLConnection(user=USR, password=PWD, database="statisticsdb")
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        CREATE TABLE T_Table (
            df int NOT NULL,
            t float NOT NULL,
            p float NOT NULL,
            PRIMARY KEY (df, t)
        )
    """)

    for row in t_table:
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
