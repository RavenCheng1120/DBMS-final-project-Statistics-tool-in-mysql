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

##### Call procedure format: 

````mysql
CALL Wilcoxon({PrimaryKey_ID}, {Table1}, {Table2}, {Tabel1_Column}, {Tabel2_Column});
````

> The primary key must be the same in Table1 and Table2 for the two tables to join. 

Sample code:

````mysql
CALL Wilcoxon('UserNum', 'conditionA', 'conditionC', 'Enjoyment', 'Enjoyment');
````

