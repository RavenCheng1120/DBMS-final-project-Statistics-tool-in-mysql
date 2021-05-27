p-value: 先用其他程式語言算出精細的表(小數點後三位)，再直接用這個表來查


# 假說檢定：

1. 定出虛無假設(H0) 與 對立假設(H1)
    - H0與H1互補 
    - ex: 想知道兩組資料有無顯著差異
    - H0 = "兩組資料的平均數相等" (通常是我們想否決的)
    - H1 = "兩組資料的平均數不相等"
2. 選定想關注的統計量
    - 不同的檢定方法即關注不同的統計量
3. 計算p-value
    - p-value = "H0成立的前提下，我得到步驟2所得檢定量的機率"
4. 根據significance level決定是否reject H0
    - 通常設成0.05 or 0.01

舉例：我丟硬幣丟出了10次正面，0次背面，想聲稱此硬幣非公正硬幣
- H0 = "丟出正面的機率為1/2"
- H1 = "丟出正面的機率不為1/2"(two tail) or "丟出正面的機率大於1/2"(one tail)
- 統計量="丟出正面的次數"=10
- p = "H0成立的前提下，正面次數=5的機率" = (1/2)^10 = 0.001
- p<0.01，所以H0被否決，此硬幣非公正(統計上顯著)


p.s. 如果選擇0.05做為雙尾的significance level，那麼單尾的p-value必須小於0.025

# Paired T-test:
#### 前提：配對型資料(within subject)，數據間獨立(fully counterbalance)，服從常態分佈
H0 = "兩組資料的平均數相等"
H1 = "兩組資料的平均數不相等"

#### 統計量： $t=\left|\dfrac{\overline{X}_D}{s_D/\sqrt{n}}\right|$
$\overline{X}_D$ : 數據差的平均
$s_D$ : 數據差的標準差
(取絕對值是為了後續方便)

#### p-value="在H0成立時，根據T分布得到的t>我們算出的t"的機率

T分布: $f(t)=\dfrac{\Gamma(\frac{n}{2})}{\sqrt{(n-1)\pi}\Gamma(\frac{n-1}{2})}(1+\frac{t^2}{n-1})^{-\frac{n}{2}}$
(n為數據筆數)
給定數字a(像是我們算出來的t)，由T分布得到的t<a的機率為: $\int_{-\infty}^a f(u)du$

### Paired T-test流程:

1. 先計算兩組數據的兩兩差異，存成另一組數據X
2. 計算X的平均數與標準差
    -    $\overline{X}=\dfrac{\Sigma X}{n}$
    -    $s=\sqrt{\dfrac{\Sigma(X-\overline{X})}{n-1}}$
3. 計算t
    -    $t=\dfrac{\overline{X}}{s/\sqrt{n}}$
4. 計算p-value
    -    $p=\int_{-\infty}^t f(u)du$
    -    查表 https://www.sjsu.edu/faculty/gerstman/StatPrimer/t-table.pdf
    -    df=n-1
(查表只能告訴user他的p-value在哪個區間，要知道確切的值還是得靠自己算)
(自己算的話... 要研究一下近似算法或是implement數值積分)
5. 回報p-value與顯著與否

範例: https://www.statisticshowto.com/probability-and-statistics/t-test/

# sign test:
#### 前提：配對型資料(within subject)，數據間獨立(fully counterbalance)，不服從常態分佈或是為序數(ordinal)資料

H0 = "兩組資料的中位數相等"
H1 = "兩組資料的中位數不相等"

#### 統計量： M="$x_i>y_i$"的組數 或 "$x_i<y_i"$的組數
就是只看大小，然後計算數量。

#### p-value="在H0成立時，根據二項式分布得到的M=我們算出的M"的機率
在H0成立下(中位數相等)，x>y或x<y恰好符合二項式分布
$P(M)=C^n_M (\frac{1}{2})^n$

### sign test流程:
1. 先計算兩組數據的兩兩差異，差距為0剔除，剩下的存成另一組數據X 
2. 計算 M
    -    算>或<的組數
3. 計算p-value
    -    $P(M)=C^n_M (\frac{1}{2})^n$
4. 回報p-value與顯著與否



# Wilcoxon's matched pairs signed rank test:
#### 前提：配對型資料(within subject)，數據間獨立(fully counterbalance)，不服從常態分佈或是為序數(ordinal)資料，數據分布為對稱
H0 = "兩組資料的中位數相等"
H1 = "兩組資料的中位數不相等"

#### 統計量： $R=\min(R+,~R-)$
R+ : 所有正差異的數據之等級和
R- : 所有負差異的數據之等級和

### Wilcoxon's matched pairs signed rank test流程:

1. 先計算兩組數據的兩兩差異，差距為0剔除，剩下的存成另一組數據X
2. 將X以絕對值排序，然後賦予每一筆資料"等級"
    -    若排名相同，則取平均，見範例
    ![](https://i.imgur.com/MHdRaBu.png)
4. 計算 R+ 與 R-
    -    R+ = 所有正差距的等級和
    -    R- = 所有負差距的等級和
5. 取 R = min(R+, R-)
6. 計算p-value
    -    計算
    -    查表http://users.sussex.ac.uk/~grahamh/RM1web/WilcoxonTable2005.pdf
(查表只能告訴user他的p-value在哪個區間，要知道確切的值還是得靠自己算)
(如果扣除無差異的組數後仍超過20組，那麼可以有比較好算的近似法能算p-value)
7. 回報p-value與顯著與否



# 檢驗是否為常態分佈(Testing for Normality)
![](https://i.imgur.com/AtA9OYq.png)

(Kolmogorov-Smirnov and Shapiro-Wilk are availible in SPSS)

