# simStock 小確幸股票模擬機

## 最近發佈的版本
* v0.9：[[點這裡]](itms-services://?action=download-manifest&url=https://github.com/peiyu66/simStock21/releases/download/latest/manifest.plist)，就會出現確認安裝的對話方塊。
    * 曾向作者登記為開發機，iOS14以上的iPhone或iPad才能安裝。
    * 上列[[點這裡]](itms-services://?action=download-manifest&url=https://github.com/peiyu66/simStock21/releases/download/latest/manifest.plist)的連結要在iOS設備連上[[github-pages]](https://peiyu66.github.io/simStock21/)才能點出確認安裝的對話方塊。

## 策略規則
   小確幸的策略是純技術面的短期投機買賣：
1. 低買高賣賺取價差，不考慮股息股利。
1. 縮短買賣週期（最短2天）與提升報酬率兩者取平衡。
1. 保本小賺維持現金流，優先於追求偶爾大賺。
1. 操作簡單不要複雜，只做多我是不懂做空啦。

## 買賣規則
1. 每次買進只使用現金的三分之一，即「起始本金」及兩次加碼備用金。
1. 每次買進時一次買足「起始本金」可買到的數量。
1. 賣時一次全部賣出結清。
1. 必要時可2次加碼。

## 選股原則
1. 熱門股優於傳統股。
1. 近3年的模擬，平均[實年報酬率](https://github.com/peiyu66/simStock21/wiki/年報酬率)在20%以上，平均週期在80天以內者（標示為紅色星星）。

## Q&A
### 誰適合使用小確幸？
* ✐✐✐ [小確幸適性評估](https://docs.google.com/forms/d/e/1FAIpQLSdzNyfMl5NP1sCSHSxoSCWqqdeAPSQbw4kAiwlCv0pzJkjgrg/viewform?usp=sf_link) ✐✐✐

### 小確幸沒有在App Store上架？
* App Store自2017年已不允許「個人」開發者上架含有「模擬賭博」內容的App。
* 小確幸下載的即時及歷史股價雖然是公開資料，若想上架卻應取得來源網站的許可。

### 如何安裝小確幸？
* 若有加入Apple Developer，就自己在Xcode直接建造直接安裝。
* 不然只好[向作者登記iPhone或iPad的序號](https://github.com/peiyu66/simStock21/wiki/加入小確幸)作為開發機，再從[[發佈的版本]](itms-services://?action=download-manifest&url=https://github.com/peiyu66/simStock21/releases/download/ipa/manifest.plist)下載及安裝(ipa)。
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
<a href="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-02-19%20at%2011.33.35.png"><img src="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-02-19%20at%2011.33.35.png" width="45%"></a>
<a href="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-02-19%20at%2011.34.12.png"><img src="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPad%20Pro%20(11-inch)%20(2nd%20generation)%20-%202021-02-19%20at%2011.34.12.png" width="45%"></a>
<br>

### iPhone 12
<br>
<a href="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.37.57.png"><img src="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.37.57.png" width="30%"></a>
<a href="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.38.01.png"><img src="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.38.01.png" width="60%"></a>
<br><br>
<a href="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.38.06.png"><img src="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.38.06.png" width="30%"></a>
<a href="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.38.30.png"><img src="https://github.com/peiyu66/simStock21/raw/main/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%2012%20-%202021-02-19%20at%2011.38.30.png" width="60%"></a>
<br>

## 實戰指南

### 模擬
把現金實際投入股市之前，應熟知小確幸的操作與模擬結果的意義。<br>
（畢竟小確幸不是程式交易。）

### 股群
只買1支股票就是賭，股群的組成是為了分類、互補。既可抵銷賠很深的風險，也可縮短收益週期，維持現金在手。

### 本金
本金須依模擬規則備足，並依模擬提示投入，不無謂冒險也勿臨陣退縮。

### 掛單
依模擬提示掛單。買單在12點半之後再掛才能接近或優於收盤價，賣單則開盤之初即時掛。

掛的價格應考慮內外盤比及五檔現況，以之推測最佳的成交價格，隨時調整，宜保守，忌追高。<br>
（依循策略，則賣低了比掛太高沒賣成好，掛低了買不到又比買太高好多了！）

### 結算
每完成一輪買賣應回顧檢討。每年應結算已實現損益、未實現損益、年報酬率，然後記錄、比較、分析歷年的變化是否符合預期。

<br>

_！！！小確幸不保證提供的資訊正確即時，亦不對你的投資決策負責。！！！_

