# DBMS Final Project: Statistics tool in MySQL

## Paired T-Test
- Build T-Table:
```
python3 src/build_t_table.py
```
> You should set your db password in `src/build_t_table.py` first.

- Call procedure format: 
```sql
CALL PairedTTest({PrimaryKey}, {Table1}, {Tabel1_Column}, {Table2}, {Tabel2_Column}, @t, @p);
```
> The primary key must be the same in Table1 and Table2 for the two tables to join. 

- Sample code:
```sql
CALL PairedTTest('UserNum', 'normal', 'Pretest', 'normal', 'Midtest', @t, @p);
SELECT @t, @p;
```



## Wilcoxon Signed Rank Test

- Build P-table:

First, process the "wilcoxonTable.csv" to a new format. The following code will produce a new csv file called "NewWilcoxonTable.csv".

```python
python3 src/processWilcoxonTable.py
```

Then type this code in the console to import csv table into your database. The table data will be stored in a "Wilconxon_p_table". The R_value (primary key) is the Wilcoxon result R, and the column name is the N number (data amount). You can find a corresponding **p** value with a R_value and N.

> Remember to change the user info in the python file.

```python
python3 src/WilcoxonTableImport.py
```



- Call procedure format: 

````mysql
CALL Wilcoxon({PrimaryKey_ID}, {Table1}, {Table2}, {Tabel1_Column}, {Tabel2_Column},  @Wilcoxon_p);
````

> The primary key must be the same in Table1 and Table2 for the two tables to join. 

- Sample code:

````mysql
CALL Wilcoxon('UserNum', 'conditionA', 'conditionC', 'Enjoyment', 'Enjoyment', @Wilcoxon_p);
SELECT @Wilcoxon_p;
````



## Friedman's ANOVA

- Call procedure format: 

```mysql
CALL Friedman({PrimaryKey_ID}, {Table1}, {Table2}, {Table3}, {Tabel1_Column}, {Tabel2_Column}, {Tabel3_Column});
```

- Sample code:

```mysql
CALL Friedman('UserNum', 'conditionA', 'conditionB', 'conditionC', 'Enjoyment', 'Enjoyment', 'Enjoyment');
```

