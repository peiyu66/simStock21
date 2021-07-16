# simStock 小確幸股票模擬機

## 最近發佈的版本
* v1.0：[[點這裡]](itms-services://?action=download-manifest&url=https://github.com/peiyu66/simStock21/releases/download/latest/manifest.plist)，就會出現確認安裝的對話方塊。
    * 曾向作者登記為開發機，iOS14以上的iPhone或iPad才能安裝。
    * 上列[[點這裡]](itms-services://?action=download-manifest&url=https://github.com/peiyu66/simStock21/releases/download/latest/manifest.plist)的連結要在iOS設備連上[[github-pages]](https://peiyu66.github.io/simStock21/)才能點出確認安裝的對話方塊。

## 策略規則
   小確幸的策略是純技術面的短期投機買賣：
1. 低買高賣賺取價差，不考慮股息股利。
1. 致力縮短買賣週期（最短2天），但也與提升報酬率取平衡。
1. 保本小賺維持現金流，優先於追求偶爾大賺。
1. 要簡單、容易評估、容易實現。

## 買賣規則
1. 每次買進只使用現金的三分之一，即「起始本金」及兩次加碼備用金。
1. 每次買進時一次買足「起始本金」可買到的數量。
1. 賣時一次全部賣出結清。
1. 必要時2次加碼。

## 選股原則
1. 熱門股優於傳統股。
1. 近3年的模擬，平均[實年報酬率](https://github.com/peiyu66/simStock21/wiki/年報酬率)在20%以上，平均週期在65天以內者（標示為紅色星星）。

## Q&A
### 誰適合使用小確幸？
* ✐✐✐ [小確幸適性評估](https://docs.google.com/forms/d/e/1FAIpQLSdzNyfMl5NP1sCSHSxoSCWqqdeAPSQbw4kAiwlCv0pzJkjgrg/viewform?usp=sf_link) ✐✐✐

### 小確幸沒有在App Store上架？
* App Store自2017年已不允許「個人」開發者上架含有「模擬賭博」內容的App。
* 小確幸下載的即時及歷史股價雖然是公開資料，若想上架理應取得來源網站的許可。

### 如何安裝小確幸？
* 若有加入Apple Developer，就自己在Xcode直接建造直接安裝。
* 不然只好[向作者登記iPhone或iPad的序號](https://github.com/peiyu66/simStock21/wiki/加入小確幸)作為開發機，再從[[github-pages]](https://peiyu66.github.io/simStock21/)下載及安裝(ipa)。
* 可以在XCode直接建成mac版本，但只能在macOS Catalina (10.15)以上才能執行。

### 有些股票找不到？
* 只有上市股票才能被搜尋到，小確幸不模擬上櫃股票。
* 如果股票已經在股群之內，就不會重複列在搜尋結果。

### 如何買賣？
小確幸根據模擬規則自動模擬買賣行動，你不能決定什麼時候買多少、什麼時候賣多少。但你可以就模擬結果使用日期左側的圓形按鈕，更改其買賣時機。
<br>

## 其他說明
參閱[WIKI](https://github.com/peiyu66/simStock21/wiki)。

## 截圖
截自XCode simulator。

### iPad Pro 11吋
<br>

<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-06-03%20at%2010.12.55.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-06-03%20at%2010.12.55.png" width="45%"></a> 
<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-06-03%20at%2010.13.02.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-06-03%20at%2010.13.02.png" width="45%"></a><br>

<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-06-03%20at%2010.13.26.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-06-03%20at%2010.13.26.png" width="90%"></a>
<br>

### iPhone 12 mini
<br>
<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.16.47.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.16.47.png" width="30%"></a> 
<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.16.52.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.16.52.png" width="60%"></a>
<br>

<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.23.04.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.23.04.png" width="30%"></a> 
<a href="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.23.16.png"><img src="https://github.com/peiyu66/simStock21/raw/main/20210603/Simulator%20Screen%20Shot%20-%20iPhone%2012%20mini%20-%202021-06-03%20at%2012.23.16.png" width="60%"></a>
<br>
<br>
