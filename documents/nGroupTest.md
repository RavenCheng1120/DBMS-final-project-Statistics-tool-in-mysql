For parametric tests, there should be no outliers.

# Repeated Measures ANOVA:
Ref: 
https://www.spss-tutorials.com/repeated-measures-anova/
#### 前提：配對型資料(within subject)，數據間獨立(fully counterbalance)，服從常態分佈，滿足sphericity*(各pairwise間差距的變異數相等)
H0 = "各組資料的平均數相等"
H1 = "各組資料的平均數不相等" (或是說存在兩組資料的平均數不相等)

#### 統計量： $F=\dfrac{MS_{model}}{MS_{error}}$
$n$ : 人數
$k$ : 組數 (或condition數)
$X_{ij}$ : 第i個人第j組的分數
$X_{i.}$ : 第i個人所有分數的平均
$X_{.j}$ : 第j組所有分數的平均
$X_{..}$ : 所有分數的平均
$MS_{model}=\dfrac{SS_{model}}{k-1}$
$\displaystyle SS_{model}=n\Sigma_{j=1}^k(X_{.j}-X_{..})^2$
$MS_{error}=\dfrac{SS_{error}}{(k-1)(n-1)}$
$\displaystyle SS_{error}=\Sigma_{i=1}^n\Sigma_{j=1}^k(X_{ij}-X_{i.})^2-SS_{model}$

### Repeated Measures ANOVA流程:

(假設table有n-row，k-column，即row為受測者，column為condition)
1. 計算每個row的平均，另外存一個column($X_{i.}$)
2. 計算每個column的平均(包括1.的column)，另外存一個row($X_{.j},X_{..}$)
3. 計算F
    -    $F=\dfrac{MS_{model}}{MS_{error}}$
4. 計算p-value
    -    查表 
5. 回報p-value與顯著與否

### 補充
-    驗證sphericity: https://en.wikipedia.org/wiki/Mauchly%27s_sphericity_test
-    若不符合sphericity:
    -    Greenhouse–Geisser correction 或 Huynh–Feldt correction (根據 sphericity test statistic 的大小決定)
    -    改做 MANOVA (However, this procedure can be less powerful than using a repeated measures ANOVA, especially when sphericity violation is not large or sample sizes are small.[10] O’Brien and Kaiser[11] suggested that when you have a large violation of sphericity (i.e., epsilon < .70) and your sample size is greater than k + 10, then a MANOVA is more powerful; in other cases, repeated measures design should be selected.)


# Friedman test (Friedman ANOVA):
Ref:
https://en.wikipedia.org/wiki/Friedman_test#cite_note-4
https://www.itl.nist.gov/div898/software/dataplot/refman1/auxillar/friedman.htm
https://www.sciencedirect.com/topics/mathematics/friedman-test
#### 前提：配對型資料(within subject)，數據間獨立(fully counterbalance)，不服從常態分佈或是為序數(ordinal)資料

H0 = "各組資料的中位數相等"
H1 = "各組資料的中位數不相等"

#### 統計量： $T_1=\dfrac{(k-1)\Sigma_{j=1}^{k}(\hat{R}_j-\frac{n(k+1)}{2})^2}{A-C}$
$n$ : 人數
$k$ : 組數 (或condition數)
$R_{ij}$ : 第i個人第j組分數的rank
$\hat{R}_j=\Sigma_{i=1}^{n}R_{ij}$ : 第j組rank的總和
$A=\Sigma_{i=1}^{n}\Sigma_{j=1}^{k}(R_{ij})^2$ : 所有rank的平方和
$C=\dfrac{nk(k+1)^2}{4}$

(也有人推薦用$T_2=\dfrac{(n-1)T_1}{n(k-1)-T_1}$)

### Friedman test流程:
(假設table有n-row，k-column，即row為受測者，column為condition)
1. 對每個row的所有column做排名，存成另外k個column(或存新的table)
    -    若排名相同，則依類似方式取平均

範例:![](https://i.imgur.com/50WNOgz.png)

2. 計算 $T_1$ or $T_2$
    -    $T_1=\dfrac{(k-1)\Sigma_{j=1}^{k}(\hat{R}_j-\frac{n(k+1)}{2})^2}{A-C}$
    -    $T_2=\dfrac{(n-1)T_1}{n(k-1)-T_1}$
3. 計算p-value
    -    查表 by F-distribution
4. 回報p-value與顯著與否

"The T1 approximation is sometimes poor, so the T2 approximation is typically preferred."


# Shapiro-Wilk test (for normality):
ref:
https://en.wikipedia.org/wiki/Shapiro%E2%80%93Wilk_test

H0 = "此數據之母體服從常態分布"
H1 = "此數據之母體不服從常態分布"

#### 統計量： $W=\dfrac{(\Sigma_{i=i}^{n}a_ix_{(i)})^2}{\Sigma_{i=i}^{n}(x_i-\bar{x})^2}$
$n$ : 數據筆數
$(a_1,a_2,...,a_n)=\dfrac{m^TV^{-1}}{||m^TV^{-1}||}$，待補
$x_{(i)}$ : 第i筆數據的"順位"(rank)
$\bar{x}$ : 所有數據的平均

### Shapiro-Wilk test流程:

1. 將所有數據排序後，由小到大另建一個column存1~n ($x_{(i)}$)
2. 計算$a_i$
3. 計算 W
    -    $W=\dfrac{(\Sigma_{i=i}^{n}a_ix_{(i)})^2}{\Sigma_{i=i}^{n}(x_i-\bar{x})^2}$
4. 計算p-value
    -    查表
5. 回報p-value與顯著與否


