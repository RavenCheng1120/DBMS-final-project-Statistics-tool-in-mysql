import sys
import csv
import mysql.connector
from mysql.connector import Error
import pandas as pd

#--------------
# Connect To DB
#--------------
def connect_To_DB(hostName, dbName, usr, pwd):
	try:
		connection = mysql.connector.connect(
			host = hostName,    # 主機名稱
			database = dbName, #資料庫
			user = usr,         # 帳號
			password = pwd)  # 密碼

		cursor = connection.cursor()
		cursor.execute("USE " + dbName)
		connection.commit()

		### import tables
		T_table_data_insert(cursor, connection)
		print("T table insertion complete.")

		RepeatANOVA_data_insert(cursor, connection)
		print("Repeat ANOVA insertion complete.")

		Wilconxon_data_insert(cursor, connection)
		print("Wilconxon insertion complete.")

		Friedman_data_insert(cursor, connection)
		print("Friedman insertion complete.")

		import_ChiSquare("ChiSquareTable.csv", cursor, connection)
		print("Chi Square insertion complete.")

		print("Import table successfully.")

	except Error as e:
		print("Database connect fail：", e)

	finally:
		if (connection.is_connected()):
			cursor.close()
			connection.close()
			print("connection offline")


#-------------------------
# import ChiSquare table
#-------------------------
def create_table(cursor):
	cursor.execute("DROP TABLE IF EXISTS ChiSquareTable")
	cursor.execute("CREATE TABLE ChiSquareTable(\
						p float NOT NULL PRIMARY KEY, \
						k float NOT NULL)")

def insert_data(p, k, cursor, connection):
	cursor.execute("INSERT INTO ChiSquareTable VALUES (" + p + ", " + k + ")")
	connection.commit()

def import_ChiSquare(file, cursor, connection):
	create_table(cursor)
	f = open(file, "r", encoding="utf-8")
	for line in f:
		strings = line.split(',')
		insert_data(strings[0], strings[1][:-1], cursor, connection)


#----------------
# import T table
#----------------
def T_table_data_insert(cursor, connection):
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
		connection.commit()


#--------------------
# import Repeat ANOVA
#--------------------
def RepeatANOVA_data_insert(cursor, connection):
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


#-----------------------
# import Wilconxon table
#-----------------------
def Wilconxon_data_insert(cursor, connection):
	cursor.execute("DROP TABLE IF EXISTS Wilconxon_p_table")

	rowData = []
	pData = pd.read_csv('NewWilcoxonTable.csv')

	for row in pData:
		rowData.append(row)
	rowData = rowData[1:]

	# Create Table: 100 columns
	columnString = "CREATE TABLE Wilconxon_p_table (R_Value FLOAT NOT NULL, "
	for columnName in rowData:
		columnName = columnName.replace(".0", "")
		if columnName != '100':
			columnString += f"N_{columnName} FLOAT, "
		else:
			columnString += f"N_{columnName} FLOAT, PRIMARY KEY (R_Value))"
	cursor.execute(columnString)
	connection.commit()

	for r in pData.iterrows():
		insertString = "INSERT INTO Wilconxon_p_table VALUES ("
		for idx in range(0, pData.shape[1]):
			if idx == pData.shape[1]-1:
				insertString += f"{r[1][idx]})"
			else:
				insertString += f"{r[1][idx]}, "
		cursor.execute(insertString)
		connection.commit()


#----------------------
# import Friedman table
#----------------------
def Friedman_data_insert(cursor, connection):
	cursor.execute("DROP TABLE IF EXISTS Friedman_p_table")

	rowData = []
	pData = pd.read_csv('FriedmanANOVAtable.csv')
	# print(pData.shape) #(1000, 101)
	for row in pData:
		rowData.append(row)
	rowData = rowData[1:] # get the column names

	# Create Table: 100 columns
	columnString = "CREATE TABLE Friedman_p_table (P_Value FLOAT NOT NULL, "
	for columnName in rowData:
		if columnName != '103':
			columnString += f"N_{columnName} FLOAT, "
		else:
			columnString += f"N_{columnName} FLOAT, PRIMARY KEY (P_Value))"
	cursor.execute(columnString)
	connection.commit()

	for r in pData.iterrows():
		insertString = "INSERT INTO Friedman_p_table VALUES ("
		for idx in range(0, pData.shape[1]):
			if idx == pData.shape[1]-1:
				insertString += f"{r[1][idx]})"
			else:
				insertString += f"{r[1][idx]}, "
		cursor.execute(insertString)
		connection.commit()


#--------------
# Main function
#--------------
if __name__ == '__main__':
	if len(sys.argv) < 2:
		print('Error: no argument')
		sys.exit()

	hostName = sys.argv[1] if len(sys.argv) >= 2 else 'localhost'
	dbName = sys.argv[2] if len(sys.argv) >= 3 else 'statisticsdb'
	userName = sys.argv[3] if len(sys.argv) >= 4 else 'root'
	password = sys.argv[4] if len(sys.argv) >= 5 else 'abc'

	connect_To_DB(hostName, dbName, userName, password)