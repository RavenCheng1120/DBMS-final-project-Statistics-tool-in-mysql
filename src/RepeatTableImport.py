import mysql.connector
from mysql.connector import Error
import pandas as pd


def connect_To_DB():
    try:
        connection = mysql.connector.connect(
            host="localhost",
            database = "statisticsdb",
            user="root",
            password="",
        )

        cursor = connection.cursor()
        data_insert(cursor, connection)

    except Error as e:
        print("Database connect fail：", e)

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()


def data_insert(cursor, connection):
    cursor.execute("USE statisticsdb")
    cursor.execute("DROP TABLE IF EXISTS Repeated_p_table")

    rowData = []
    pData = pd.read_csv("RepeatANOVAtable.csv")
    for row in pData:
        rowData.append(row)
    rowData = rowData[1:] # get the column names

    columnString = "CREATE TABLE Repeated_p_table (P_Value FLOAT NOT NULL, "
    for columnName in rowData:
        columnString += f"N_{columnName} FLOAT, "
    columnString += " PRIMARY KEY (P_Value))"
    cursor.execute(columnString)
    connection.commit()

    for r in pData.iterrows():
        insertString = "INSERT INTO Repeated_p_table VALUES ("
        for idx in range(pData.shape[1]):
            if idx == pData.shape[1]-1:
                insertString += f"{r[1][idx]})"
            else:
                insertString += f"{r[1][idx]}, "
        cursor.execute(insertString)
        connection.commit()


if __name__ == "__main__":
    connect_To_DB()
