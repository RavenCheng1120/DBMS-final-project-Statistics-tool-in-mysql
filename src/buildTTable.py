import csv

import numpy as np
from scipy import stats
from tqdm import tqdm


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
    
    with open("TTable.csv", "w") as file:
        writer = csv.DictWriter(file, fieldnames=["df", "t", "p"])
        writer.writeheader()
        writer.writerows(t_table)
