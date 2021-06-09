import mysql.connector

mydb = mysql.connector.connect(host="localhost", user="root", passwd="test123", auth_plugin='mysql_native_password')
mycursor = mydb.cursor()
mycursor.execute("use StatisticsDB")

def create_table():
	mycursor.execute("DROP TABLE IF EXISTS ChiSquareTable")
	mycursor.execute("CREATE TABLE ChiSquareTable(\
						p float NOT NULL PRIMARY KEY, \
						k float NOT NULL)")

def insert_data(p, k):
	mycursor.execute("INSERT INTO ChiSquareTable VALUES (" + p + ", " + k + ")")
	mydb.commit()

def inport_csv(file):
	create_table()
	f = open(file, "r", encoding="utf-8")
	for line in f:
		strings = line.split(',')
		insert_data(strings[0], strings[1][:-1])

if __name__ == '__main__':
	inport_csv("ChiSquareTable.csv")