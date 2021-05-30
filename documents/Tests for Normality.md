# Tests for Normality and Outliers


# D'Agostino's K-squared test (for normality):
ref:
https://en.wikipedia.org/wiki/D%27Agostino%27s_K-squared_test

H0 = "此數據之母體服從常態分布"
H1 = "此數據之母體不服從常態分布"

#### 統計量： $K=Z_1(g_1)^2+Z_2(g_2)^2$
$n$ : 數據筆數
$\bar{x}$ : 所有數據的平均
$g_1=\dfrac{\Sigma_{i=1}^{n}(x_i-\bar{x})^3}{n^{\frac{3}{2}}(\Sigma_{i=1}^{n}(x_i-\bar{x})^2)^{\frac{3}{2}}}$
$g_2=\dfrac{\Sigma_{i=1}^{n}(x_i-\bar{x})^4}{n^2(\Sigma_{i=1}^{n}(x_i-\bar{x})^2)^{2}}$

$Z_i(g_i)=\dfrac{g_i-\mu_i}{\sigma_i}$ ($g_i$ 的Z score轉換)
$\mu_1=0$
$\sigma_1=\sqrt{\dfrac{6(n-2)}{(n+1)(n+3)}}$
$\mu_2=\dfrac{-6}{n+1}$
$\sigma_2=\sqrt{\dfrac{24n(n-2)(n-3)}{(n+1)^2(n+3)(n+5)}}$



### D'Agostino's K-squared test流程:
1. 計算 K
    -    $K=Z_1(g_1)^2+Z_2(g_2)^2$
2. 計算p-value
    -    查表 by Chi-square distribution
3. 回報p-value與顯著與否
    -    p-value<$\alpha\implies$ 拒絕 $H_0\implies$ 此筆資料不服從常態分佈


#  test (for outliers):
ref:
https://www.itl.nist.gov/div898/handbook/eda/section3/eda35h.htm
Grubbs' Test: ask if the maximum / minimum data is an outlier
Tietjen-Moore Test: ask if the farest k data are outliers
Generalized ESD Test: ask the number of outliers

H0 = "此筆數據服從樣本之分布"
H1 = "此筆數據不服從樣本之分布"

#### 統計量：


###  test流程: