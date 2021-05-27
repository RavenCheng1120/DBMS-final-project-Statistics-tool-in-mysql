# DBMS Final Project: Statistics tool in MySQL

## Wilcoxon Signed Rank Test

##### Call procedure format: 

````mysql
CALL Wilcoxon({PrimaryKey_ID}, {Table1}, {Table2}, {Tabel1_Column}, {Tabel2_Column});
````

> The primary key must be the same in Table1 and Table2 for the two tables to join. 

Sample code:

````mysql
CALL Wilcoxon('UserNum', 'conditionA', 'conditionC', 'Enjoyment', 'Enjoyment');
````

