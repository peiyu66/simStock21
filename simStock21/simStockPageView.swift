//
//  simStockPageView.swift
//  simStock21
//
//  Created by peiyu on 2020/6/28.
//  Copyright © 2020 peiyu. All rights reserved.
//

import SwiftUI

struct stockPageView: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @State var stock : Stock
    @State var prefix: String
    @State var showPrefixMsg:Bool = false
    @State var groupPrefixsOnly:Bool = true
    @State var filterIsOn = false

    func pageViewTools(_ geometry:GeometryProxy) -> some View {
        Group {
            if list.doubleColumn(hClass) {
                pageTools(stock: $stock, filterIsOn: $filterIsOn, cgWidth: geometry.size.width - 450)
            } else {
                prefixPicker(prefix:self.$prefix, stock:self.$stock, groupPrefixsOnly: self.$groupPrefixsOnly, cgWidth: geometry.size.width - 50)
            }
        }
    }
    
    func pageViewTitle(_ geometry:GeometryProxy) -> some View {
        Group {
            if list.doubleColumn(hClass) {
                pageTitle(stock: $stock, cgWidth: 350)
            } else {
                EmptyView()
            }
        }
    }
    
    var body: some View {
        GeometryReader { g in
            VStack (alignment: .center) {
                tradeListView(stock: self.$stock, prefix: self.$prefix, filterIsOn: $filterIsOn, groupPrefixsOnly: self.$groupPrefixsOnly, cgWidth: g.size.width)
                if !list.doubleColumn(hClass) {
                    Spacer()
                    stockPicker(prefix: self.$prefix, stock: self.$stock, groupPrefixsOnly: self.$groupPrefixsOnly)
                        .alert(isPresented: $showPrefixMsg) {
                            Alert(title: Text("提醒您"), message: Text("有多股的首字相同時，\n於畫面底處可按切換。"), dismissButton: .default(Text("知道了。")))
                        }
                }
            }
            .navigationBarItems(leading: pageViewTitle(g), trailing: pageViewTools(g))
            .onAppear {
                if !list.doubleColumn(hClass) && list.versionLast == "" && list.prefixStocks(prefix: prefix, group: (groupPrefixsOnly ? stock.group : nil)).count > 1 {
                    showPrefixMsg = true
                }
            }
        }
    }
}

struct runningMsg: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @State var padding:CGFloat = 0
    
    var body: some View {
        Text(list.runningMsg)
            .font(.body)
            .foregroundColor(.orange)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.bottom,padding)
    }
}

private func pickerIndexRange(index:Int, count:Int, max: Int) -> (from:Int, to:Int) {
    var from:Int = 0
    var to:Int = count - 1
    let center:Int = (max - 1) / 2
    
    if count > max {
        if index <= center {
            from = 0
            to = max - 1
        } else if index >= (count - center) {
            from = count - max
            to = count - 1
        } else {
            from = index - center
            to = index + center
        }
    }
    
    return(from,to)
}

struct prefixPicker: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var prefix: String
    @Binding var stock : Stock
    @Binding var groupPrefixsOnly:Bool
    @State var cgWidth:CGFloat
    
    var allPrefixs:[String] {
        (groupPrefixsOnly ? list.theGroupPrefixs(self.stock) : list.prefixs)
    }
    
    var maxCount:CGFloat {
        list.widthCG(hClass, CG: [7,15,17,30])
    }

    var prefixs:[String] {
        let prefixIndex = allPrefixs.firstIndex(of: prefix) ?? 0
        let index = pickerIndexRange(index: prefixIndex, count: allPrefixs.count, max: Int(maxCount))
        return Array(allPrefixs[index.from...index.to])
    }
    
    var groupLabel:String {
        " " + (self.groupPrefixsOnly ? (stock.group.count > 5 ? String(stock.group.prefix(2) + stock.group.suffix(3)) : stock.group) : "全部股")  + " "
    }

    var body: some View {
        HStack {
            Button(action: {
                self.groupPrefixsOnly = !self.groupPrefixsOnly
            }) {
                Text(groupLabel)
                    .font(.footnote)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue, lineWidth: 1))
            }
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded({ value in
                    if value.translation.width < 0, groupPrefixsOnly {
                        self.stock = list.shiftLeftGroup(stock)
                        self.prefix = self.stock.prefix
                    }
                    if value.translation.width > 0, groupPrefixsOnly {
                        self.stock = list.shiftRightGroup(stock)
                        self.prefix = self.stock.prefix
                    }
                    if value.translation.height < 0 {
                        // up
                    }
                    if value.translation.height > 0 {
                        // down
                    }
                }))

            if self.prefixs.first == allPrefixs.first {
                Text("|").foregroundColor(.gray).fixedSize()
            } else {
                Text("-").foregroundColor(.gray).fixedSize()
            }
            Picker("", selection: $prefix) {
                ForEach(self.prefixs, id:\.self) {prefix in
                    Text(prefix).tag(prefix)
                }
            }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .fixedSize()
                .onReceive([self.prefix].publisher.first()) { value in
                    if self.stock.prefix != self.prefix {
                        self.stock = self.list.prefixStocks(prefix: value, group: (groupPrefixsOnly ? stock.group : nil))[0]
                    }
                }
            if self.prefixs.last == allPrefixs.last {
                Text("|").foregroundColor(.gray).fixedSize()
            } else {
                Text("-").foregroundColor(.gray).fixedSize()
            }
        }
        .frame(width: cgWidth, alignment: .trailing)
    }
}

struct stockPicker: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var prefix:String
    @Binding var stock :Stock
    @Binding var groupPrefixsOnly:Bool
    
    var allStocks:[Stock] {
        list.prefixStocks(prefix: self.prefix, group: (groupPrefixsOnly ? stock.group : nil))
    }
    
    var prefixStocks:[Stock] {
        let maxChars = Int(list.widthCG(hClass, CG: [3,7,9,13])) * 4
        let sNameCount = allStocks.map{$0.sName.count}
        var maxCount = maxChars / (sNameCount.max() ?? 1)
        if maxCount < 3 {
            maxCount = 3
        } else if maxCount % 2 == 0 {
            maxCount += 1
        }
        let stockIndex = allStocks.firstIndex(of: self.stock) ?? 0
        let index = pickerIndexRange(index: stockIndex, count: allStocks.count, max: (maxCount < 3 ? 3 : maxCount))
        return Array(allStocks[index.from...index.to])
    }

    var body: some View {
        VStack (alignment: .center) {
            if self.prefixStocks.count > 1 {
                HStack {
                    if self.prefixStocks.first == allStocks.first {
                        Text("|").foregroundColor(.gray).fixedSize()
                    } else {
                        Text("-").foregroundColor(.gray)
                    }
                    Picker("", selection: $stock) {
                        ForEach(self.prefixStocks, id:\.self.sId) { stock in
                            let sName = stock.sName
                            Text(sName.count > 6 ? String(sName.prefix(4) + sName.suffix(2)) : sName).tag(stock)
                        }
                    }
                        .pickerStyle(SegmentedPickerStyle())
                        .labelsHidden()
                        .fixedSize()
                    if self.prefixStocks.last == allStocks.last {
                        Text("|").foregroundColor(.gray).fixedSize()
                    } else {
                        Text("-").foregroundColor(.gray).fixedSize()
                    }
                }
            }
		}
    }
    
}


struct tradeListView: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var stock : Stock
    @Binding var prefix: String
    @Binding var filterIsOn:Bool
    @Binding var groupPrefixsOnly:Bool
    @State var cgWidth:CGFloat
    
    private func scrollToSelected(_ sv: ScrollViewProxy) {
        if let dt = list.selected {
            sv.scrollTo(dt)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            //== 表頭：股票名稱、模擬摘要 ==
            tradeHeading(stock: self.$stock, filterIsOn: self.$filterIsOn, cgWidth: cgWidth)
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onEnded({ value in
                        if value.translation.width < 0 {
                            self.stock = list.shiftLeftStock(stock, groupStocks: (groupPrefixsOnly ? list.theGroupStocks(self.stock) : nil))
                            self.prefix = self.stock.prefix
                        }
                        if value.translation.width > 0 {
                            self.stock = list.shiftRightStock(stock, groupStocks: (groupPrefixsOnly ? list.theGroupStocks(self.stock) : nil))
                            self.prefix = self.stock.prefix
                        }
                        if value.translation.height < 0 {
                            // up
                        }
                        if value.translation.height > 0 {
                            // down
                        }
                    }))
            //== 日交易明細列表 ==
            GeometryReader { g in
                ScrollViewReader { sv in
                    LazyVStack {
                        Divider().padding(0)
                        List (stock.trades.filter{self.filterIsOn == false || $0.simQtySell > 0 || $0.simQtyBuy > 0 || $0.simRuleInvest != "" || $0.date == $0.stock.dateFirst || $0.date == twDateTime.startOfDay()}, id:\.self.date) { trade in
                            tradeCell(stock: self.$stock, trade: trade)
                                .onTapGesture {
                                    if list.selected == trade.date {
                                        list.selected = nil
                                    } else {
                                        list.selected = trade.date
                                    }
                                 }
                        }
                        .listStyle(GroupedListStyle())
                        .frame(width: g.size.width - (list.doubleColumn(hClass) ? 40 : 0), height: g.size.height, alignment: .center)
                        .offset(x: 0, y: -5)
                    }
                    .background(Color(.systemGroupedBackground))
                    .onChange(of: stock) {_ in
                        scrollToSelected(sv)
                    }
                    .onChange(of: self.filterIsOn) {_ in
                        scrollToSelected(sv)
                    }
                }
                
            }
        }   //VStack
        .onAppear() {
            if list.selected == nil {
                list.selected = stock.lastTrade(stock.context)?.date
            }
        }
    }
}

struct settingForm: View {
    @EnvironmentObject var list: simStockList
    @Binding var stock:Stock
    @Binding var showSetting: Bool
    @State var dateStart:Date
    @State var moneyBase:Double
    @State var autoInvest:Double
    @State var applyToGroup:Bool = false
    @State var applyToAll:Bool = false
    @State var saveToDefaults:Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("\(stock.sId)\(stock.sName)的設定").font(.title)) {
                    DatePicker(selection: $dateStart, in: (twDateTime.calendar.date(byAdding: .year, value: -15, to: Date()) ?? stock.dateFirst)...(twDateTime.calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()), displayedComponents: .date) {
                        Text("起始日期")
                    }
                    .environment(\.locale, Locale(identifier: "zh_Hant_TW"))
                    HStack {
                        Text(String(format:"起始本金%.f萬元",self.moneyBase))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: 180, alignment: .leading)
                        Slider(value: $moneyBase, in: 10...1000, step: 10)
                    }
                    HStack {
                        Text(self.autoInvest > 9 ? "自動無限加碼" : (self.autoInvest > 0 ? String(format:"自動%.0f次加碼", self.autoInvest) : "不自動加碼"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: 180, alignment: .leading)
                        Slider(value: $autoInvest, in: 0...10, step: 1)
                    }
                }
                Section(header: Text("擴大設定範圍").font(.title),footer: Text(self.list.simDefaults.text).font(.footnote)) {
                    Toggle("套用到全部股", isOn: $applyToAll)
                    .onReceive([self.applyToAll].publisher.first()) { (value) in
                        self.applyToGroup = value
                    }
                    Toggle("套用到同股群 [\(stock.group)]", isOn: $applyToGroup)
                        .disabled(self.applyToAll)
                    Toggle("作為新股預設值", isOn: $saveToDefaults)
                }

            }
            .navigationBarTitle("模擬設定")
            .navigationBarItems(leading: cancel, trailing: done)

        }
            .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var cancel: some View {
        Button("取消") {
            self.showSetting = false
        }
    }
    var done: some View {
        Button("確認") {
            DispatchQueue.global().async {
                self.list.applySetting(self.stock, dateStart: self.dateStart, moneyBase: self.moneyBase, autoInvest: self.autoInvest, applyToGroup: self.applyToGroup, applyToAll: self.applyToAll, saveToDefaults: self.saveToDefaults)
            }
            self.showSetting = false
        }
    }
    

    
}

struct pageTitle: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var stock: Stock
    @State var cgWidth:CGFloat
    var body: some View {
        VStack {
            if list.isRunning {
                runningMsg(padding: 4)
                    .frame(width:cgWidth, alignment: .leading)
            }
            HStack {
                Text("\(stock.sId) \(stock.sName)")
                    .font(.title)
                if list.widthClass(hClass) != .compact && stock.proport1.count > 0 {
                    Text("[\(stock.proport1)]")
                        .font(.footnote)
                        .padding(.top)
                }
            }
            .foregroundColor(list.isRunning ? .gray : .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(minWidth:cgWidth, alignment: .leading)
        }

    }
}

struct pageTools:View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var stock : Stock
    @State var showReload:Bool = false
    @State var deleteAll:Bool = false
    @State var showDeleteAlert:Bool = false
    @State var showSetting: Bool = false
    @State var showInformation:Bool = false
    @State var showLog:Bool = false
    @Binding var filterIsOn:Bool
    @State var cgWidth:CGFloat

    private func openUrl(_ url:String) {
        if let URL = URL(string: url) {
            if UIApplication.shared.canOpenURL(URL) {
                UIApplication.shared.open(URL, options:[:], completionHandler: nil)
            }
        }
    }
    
    var body: some View {
        HStack {
            //== 工具按鈕 1 == 過濾交易模擬
            Button(action: {self.filterIsOn = !self.filterIsOn}) {
                if self.filterIsOn {
                    Image(systemName: "square.2.stack.3d")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "square.3.stack.3d")
                }
            }
            .padding(.trailing, list.widthCG(hClass, CG: [2,8]))
                
            //== 工具按鈕 2 == 查看log
            Button(action: {self.showLog = true}) {
                Image(systemName: "doc.text")
            }
            .sheet(isPresented: $showLog) {
                logForm(showLog: self.$showLog)
            }

            //== 工具按鈕 3 == 設定
            Button(action: {self.showSetting = true}) {
                Image(systemName: "wrench")
            }
            .disabled(list.isRunning)
            .sheet(isPresented: $showSetting) {
                settingForm(stock: self.$stock, showSetting: self.$showSetting, dateStart: self.stock.dateStart, moneyBase: self.stock.simMoneyBase, autoInvest: self.stock.simInvestAuto)
                    .environmentObject(list)
            }
            
            //== 工具按鈕 4 == 刪除或重算
//            Spacer()
            Button(action: {self.showReload = true}) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(list.isRunning)
            .actionSheet(isPresented: $showReload) {
                ActionSheet(title: Text("立即更新"), message: Text("刪除或重算？"), buttons: [
                    .default(Text("重算模擬")) {
                        self.list.reloadNow([self.stock], action: .simResetAll)
                    },
                    .default(Text("重算技術數值")) {
                        self.list.reloadNow([self.stock], action: .tUpdateAll)
                    },
                    .default(Text("刪除最後1個月")) {
                        self.deleteAll = false
                        self.showDeleteAlert = true
                    },
                    .default(Text("刪除全部")) {
                        self.deleteAll = true
                        self.showDeleteAlert = true
                    },
//                                .default(Text("[TWSE復驗]")) {
//                                    self.list.reviseWithTWSE([self.stock])
//                                },
                    .destructive(Text("沒事，不用了。"))
                ])
            }
            .alert(isPresented: self.$showDeleteAlert) {
                Alert(title: Text("刪除\(deleteAll ? "全部" : "最後1個月")歷史價"), message: Text("刪除歷史價，再重新下載、計算。"), primaryButton: .default(Text("刪除"), action: {
                        self.list.deleteTrades([self.stock], oneMonth: !deleteAll)
                }), secondaryButton: .default(Text("取消"), action: {showDeleteAlert = false}))
            }
            
            //== 工具按鈕 5 == 參考訊息
//            Spacer()
            Button(action: {self.showInformation = true}) {
                Image(systemName: "questionmark.circle")
            }
            .actionSheet(isPresented: $showInformation) {
                ActionSheet(title: Text("參考訊息"), message: Text("小確幸v\(list.versionNow)"),
                buttons: [
                    .default(Text("小確幸網站")) {
                        self.openUrl("https://peiyu66.github.io/simStock21/")
                    },
                    .default(Text("鉅亨個股走勢")) {
                        self.openUrl("https://invest.cnyes.com/twstock/tws/" + self.stock.sId)
                    },
                    .default(Text("Yahoo!技術分析")) {
                        self.openUrl("https://tw.stock.yahoo.com/q/ta?s=" + self.stock.sId)
                    },
                    .destructive(Text("沒事，不用了。"))
                ])
            }
        } //工具按鈕的HStack
        .frame(width: cgWidth, alignment: .trailing)
        .font(.body)
    }
}

struct tradeHeading:View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var stock : Stock
    @Binding var filterIsOn:Bool
    @State var cgWidth:CGFloat

    var totalSummary: (profit:String, roi:String, days:String) {
        if let trade = stock.lastTrade(stock.context), trade.rollRounds > 0 {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency   //貨幣格式
            numberFormatter.maximumFractionDigits = 0
            let rollAmtProfit = "累計損益" + (numberFormatter.string(for: trade.rollAmtProfit) ?? "$0")
            let rollAmtRoi = String(format:"年報酬率%.1f%%",trade.rollAmtRoi/stock.years)
            let rollDays = String(format:"平均週期%.f天",trade.days)
            return (rollAmtProfit,rollAmtRoi,rollDays)
        }
        return ("","","尚無模擬交易")
    }

    var body: some View {
        VStack {
            if !list.doubleColumn {
                HStack(alignment: .top) {
                    pageTitle(stock: $stock, cgWidth: cgWidth - 200)
                    Spacer(minLength: 30)
                    pageTools(stock: $stock, filterIsOn: $filterIsOn, cgWidth: 120)
                }   //sId,sName,工具按鈕的整個HStack
                .font(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding()
            }   //Group （表頭）
            VStack(alignment: .trailing) {
                if stock.simMoneyLacked {
                    Text("起始本金不足 ↓↓↓ 模擬結果可能失真")
                        .foregroundColor(.red)
                }
                HStack {
                    Spacer()
                    Text(String(format:"期間%.1f年", stock.years))
                    Text(stock.simMoneyBase > 0 ? String(format:"起始本金%.f萬元",stock.simMoneyBase) : "")
                    HStack {
                        if stock.simInvestAuto == 10 {
                            Text("自動無限加碼")
                                .foregroundColor(.red)
                        } else if stock.simInvestAuto > 0 {
                            if stock.simInvestExceed > 0 {
                                Text(String(format:"自動"))
                                + Text(String(format:"%.0f+%.0f", stock.simInvestAuto, stock.simInvestExceed))
                                    .foregroundColor(.red)
                                + Text("次加碼")
                            } else {
                                Text(String(format:"自動%.0f次加碼", stock.simInvestAuto))
                            }
                        } else {
                            Text("不自動加碼")
                        }
                    }
                }
                HStack {
                    Spacer()
                    if let trade = stock.lastTrade(stock.context), trade.days > 0 {
                        trade.gradeIcon()
                            .frame(width:25, alignment: .trailing)
                    } else {
                        EmptyView()
                    }
                    Text("\(totalSummary.roi) \(totalSummary.days) \(totalSummary.profit)")
                }
            }
            .font(.callout)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.trailing)
        }
    }
}


struct tradeCell: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var stock: Stock    //用@State會造成P10更新怪異
    @ObservedObject var trade:Trade
    
    private func textSize(textStyle: UIFont.TextStyle) -> CGFloat {
       return UIFont.preferredFont(forTextStyle: textStyle).pointSize
    }
    
    var simSummary: some View {
        Group {
            if trade.simRule != "_" {
                VStack(alignment: .leading,spacing: 2) {
                    Text(String(format:"%.f輪 \(trade.simRuleBuy)",trade.rollRounds))
                    Text("本金餘額")
                    Text("單輪成本")
                 }
                .font(.custom("Courier", size: textSize(textStyle: .footnote)))
                VStack(alignment: .trailing,spacing: 2) {
                    if trade.simDays > 0 {
                        Text(String(format:"平均%.f天",trade.days))
                    } else {
                        Text("")
                    }
                    Text(String(format:"%.f萬元",trade.simAmtBalance/10000))
                    Text(String(format:"%.1f萬元",trade.rollAmtCost/10000))
                }
                Spacer()
                VStack(alignment: .leading,spacing: 2) {
                    if trade.simDays > 0 {
                        Text("本輪報酬")
                        Text("本輪損益")
                        Text("本輪成本")
                    } else {
                        Text("")
                        Text("")
                        Text("")
                    }
                }
                .font(.custom("Courier", size: textSize(textStyle: .footnote)))
                VStack(alignment: .trailing,spacing: 2) {
                    if trade.simDays > 0 {
                        Text(String(format:"%.1f%%",trade.simAmtRoi))
                        Text(String(format:"%.f仟元",trade.simAmtProfit/1000))
                        Text(String(format:"%.1f萬元",trade.simAmtCost/10000))
                    } else {
                        Text("")
                        Text("")
                        Text("")
                    }
                }
                .frame(minWidth: 55)
                Spacer()
                VStack(alignment: .leading,spacing: 2) {
                    Text("實年報酬")
                    Text("真年報酬")
                    if trade.simDays > 0 {
                        Text("單位成本")
                    }
                }
                    .font(.custom("Courier", size: textSize(textStyle: .footnote)))
                VStack(alignment: .trailing,spacing: 2) {
                    Text(String(format:"%.1f%%",trade.rollAmtRoi/stock.years))
                    Text(String(format:"%.1f%%",trade.baseRoi))
                    if trade.simDays > 0 {
                        Text(String(format:"%.2f元",trade.simUnitCost))
                    }
                }
                Spacer()
            } else {   //if trade.simRule != "_"
                EmptyView()
            }
        }
        .font(.custom("Courier", size: textSize(textStyle: .footnote)))

    }
    
    var priceAndKDJ: some View {
        Group {
            VStack(alignment: .leading,spacing: 2) {
                Text("開盤")
                Text(trade.tHighDiff == 10 ? "漲停" : "最高")
                    .foregroundColor(trade.tHighDiff == 10 ? .red : .primary)
                Text(trade.tLowDiff == 10 ? "跌停" : "最低")
                    .foregroundColor(trade.tLowDiff == 10 ? .green : .primary)
            }
            VStack(alignment: .trailing,spacing: 2) {
                Text(String(format:"%.2f",trade.priceOpen))
                    .foregroundColor(trade.color(.price, price:trade.priceOpen))
                Text(String(format:"%.2f",trade.priceHigh))
                    .foregroundColor(trade.tHighDiff > 7.5 ? .red : trade.color(.price, price:trade.priceHigh))
                Text(String(format:"%.2f",trade.priceLow))
                    .foregroundColor(trade.tLowDiff == 10 ? .green : trade.color(.price, price:trade.priceLow))
            }
            .frame(minWidth: 55 , alignment: .trailing)
            

            Spacer()
            VStack(alignment: .leading,spacing: 2) {
                Text(twDateTime.inMarketingTime(trade.dateTime) ? "成交" : "收盤")
                    .foregroundColor(trade.color(.time))
                Text("MA20")
                Text("MA60")
            }
            VStack(alignment: .trailing,spacing: 2) {
                Text(String(format:"%.2f",trade.priceClose))
                    .foregroundColor(trade.color(.price, price:trade.priceClose))
                Text(String(format:"%.2f",trade.tMa20))
                Text(String(format:"%.2f",trade.tMa60))
            }
            .frame(minWidth: 55 , alignment: .trailing)
            Spacer()
        }
        .font(.custom("Courier", size: textSize(textStyle: .callout)))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                //== 1反轉 ==
                Group {
                    if trade.simRule != "_" {
                        Image(systemName: trade.simReversed == "" ? "circle" : "circle.fill")
                            .foregroundColor(self.list.isRunning ? .gray : .blue)
                            .onTapGesture {
                                if !self.list.isRunning {
                                    self.list.setReversed(self.trade)
                                }
                            }
                    } else {
                        Text("")
                    }
                }
                .frame(width: 20, alignment: .center)
                //== 2日期,3單價 ==
                Text(twDateTime.stringFromDate(trade.dateTime))
                    .foregroundColor(trade.color(.time))
                    .frame(width: list.widthCG(hClass, CG: [80,128]), alignment: .leading)
                HStack (spacing:2){
                    Text("  ")
                    Text(String(format:"%.2f",trade.priceClose))
                    if trade.tLowDiff == 10 && trade.priceClose == trade.priceLow {
                        Image(systemName: "arrow.down.to.line")
                    } else if trade.tHighDiff == 10 && trade.priceClose == trade.priceHigh {
                        Image(systemName: "arrow.up.to.line")
                    } else {
                        Text("  ")
                    }
                }
                    .frame(width: list.widthCG(hClass, CG: [70,110]), alignment: .center)
                    .foregroundColor(trade.color(.price))
                    .background(RoundedRectangle(cornerRadius: 20).fill(trade.color(.ruleB)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(trade.color(.ruleR), lineWidth: 1)
                    )


                //== 4買賣,5數量 ==
                Text(trade.simQty.action)
                    .frame(width: list.widthCG(hClass, CG: [16,24]), alignment: .center)
                    .foregroundColor(trade.color(.qty))
                Text(trade.simQty.qty > 0 ? String(format:"%.f",trade.simQty.qty) : "")
                    .frame(width: list.widthCG(hClass, CG: [32,56]), alignment: .center)
                    .foregroundColor(trade.color(.qty))
                //== 6天數,7成本價,8報酬率 ==
                if trade.simQtyInventory > 0 || trade.simQtySell > 0 {
                    Text(String(format:"%.f天",trade.simDays))
                        .frame(width: list.widthCG(hClass, CG: [44,56]), alignment: .trailing)
                    if self.list.widthClass(hClass) != .compact {
                        Text(String(format:"%.2f",trade.simUnitCost))
                            .frame(width: 56.0, alignment: .trailing)
                            .foregroundColor(.gray)
                            .font(.callout)
                    }
                    if self.list.widthClass(hClass) != .compact || trade.simQtySell > 0 {
                        Text(String(format:"%.1f%%",trade.simAmtRoi))
                            .frame(width: list.widthCG(hClass, CG: [44,56]), alignment: .trailing)
                            .foregroundColor(trade.simQtySell > 0 ? trade.color(.qty) : .gray)
                            .font(trade.simQtySell > 0 ? .body : .callout)
                    }
                } else {
                    EmptyView()
                }
                //== 9加碼 ==
                if trade.simRuleInvest == "A" {
                    Text((trade.invested > 0 ? "已加碼" + (list.widthClass(hClass) != .compact ? String(format:"(%.f)",trade.simInvestTimes - 1) : "") : "請加碼") + (trade.simInvestByUser > 0 ? "+" : (trade.simInvestByUser < 0 ? "-" : " ")))
                        .foregroundColor(self.list.isRunning ? .gray : .blue)
                        .font(.callout)
                        .frame(width: list.widthCG(hClass, CG: [44,88]), alignment: .leading)
                        .onTapGesture {
                            if !self.list.isRunning {
                                self.list.addInvest(self.trade)
                            }
                        }
                } else {
                    EmptyView()
                }
            }   //HStack
                .font(.body)
            if list.selected == trade.date {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("").frame(width: 20.0, alignment: .center)
                            Text(twDateTime.stringFromDate(trade.dateTime, format: "EEE HH:mm:ss"))
                            .frame(width: list.widthCG(hClass, CG: [80,128]), alignment: .leading)
                        }
                        HStack {
                            Text("").frame(width: 20.0, alignment: .center)
                            Text(trade.dataSource)
                            .frame(width: list.widthCG(hClass, CG: [80,128]), alignment: .leading)
                        }
                    }
                        .font(.caption)
                        .foregroundColor(trade.color(.time))
                    //== 五檔價格試算建議 ==
                    if list.widthClass(hClass) != .compact {
                        VStack(alignment: .leading, spacing: 2) {
                            if let p10Date = stock.p10Date, trade.date == p10Date {
                                HStack {
                                    let L = stock.p10L.split(separator: "|")
                                    ForEach(L.indices, id:\.self) { i in
                                        Group {
                                            if i > 0 {
                                                Divider()
                                            }
                                            Text(L[i])
                                        }
                                    }
                                }
                                HStack {
                                    let H = stock.p10H.split(separator: "|")
                                    ForEach(H.indices, id:\.self) { i in
                                        Group {
                                            if i > 0 {
                                                Divider()
                                            }
                                            Text(H[i])
                                        }
                                    }
                                }
                            }
                        }
                            .font(.custom("Courier", size: textSize(textStyle: .footnote)))
                            .foregroundColor(trade.color(.ruleB))
                            .padding(8)
                    }
                }
                Spacer()
                //== 單價和模擬摘要 ==
                if list.widthClass(hClass) == .compact {
                    VStack {
                        HStack {
                            Text("").frame(width: 20.0, alignment: .center)
                            self.priceAndKDJ
                        }
                        Spacer()
                        HStack {
                            Text("").frame(width: 20.0, alignment: .center)
                            self.simSummary
                        }
                    }
                } else {
                    HStack (alignment: .center) {
                        Text("").frame(width: 20.0, alignment: .center)
                        self.priceAndKDJ
                        self.simSummary
                    }
                }
                Spacer()    //以下是擴充技術數值
                if list.widthClass(hClass) != .compact {
                    HStack {
                        Text("").frame(width: 20.0, alignment: .center)
                        Group {
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("")
                                Text("value")
                                Text("max9")
                                .foregroundColor(trade.tMa20DiffMax9 == trade.tMa20Diff || trade.tMa60DiffMax9 == trade.tMa60Diff || trade.tOscMax9 == trade.tOsc || trade.tKdKMax9 == trade.tKdK ? .red : .primary)
                                Text("min9")
                                .foregroundColor(trade.tMa20DiffMin9 == trade.tMa20Diff || trade.tMa60DiffMin9 == trade.tMa60Diff || trade.tOscMin9 == trade.tOsc || trade.tKdKMin9 == trade.tKdK ? .red : .primary)
                                Text("z125")
                                Text("z250")
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("ma20x")
                                Text(String(format:"%.2f",trade.tMa20Diff))
                                Text(String(format:"%.2f",trade.tMa20DiffMax9))
                                    .foregroundColor(trade.tMa20DiffMax9 == trade.tMa20Diff ? .red : .primary)
                                Text(String(format:"%.2f",trade.tMa20DiffMin9))
                                    .foregroundColor(trade.tMa20DiffMin9 == trade.tMa20Diff ? .green : .primary)
                                Text(String(format:"%.2f",trade.tMa20DiffZ125))
                                Text(String(format:"%.2f",trade.tMa20DiffZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("ma60x")
                                Text(String(format:"%.2f",trade.tMa60Diff))
                                Text(String(format:"%.2f",trade.tMa60DiffMax9))
                                .foregroundColor(trade.tMa60DiffMax9 == trade.tMa60Diff ? .red : .primary)
                                Text(String(format:"%.2f",trade.tMa60DiffMin9))
                                .foregroundColor(trade.tMa60DiffMin9 == trade.tMa60Diff ? .green : .primary)
                                Text(String(format:"%.2f",trade.tMa60DiffZ125))
                                Text(String(format:"%.2f",trade.tMa60DiffZ250))
                            }
                        }
                        Group {
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("osc")
                                Text(String(format:"%.2f",trade.tOsc))
                                Text(String(format:"%.2f",trade.tOscMax9))
                                .foregroundColor(trade.tOscMax9 == trade.tOsc ? .red : .primary)
                                Text(String(format:"%.2f",trade.tOscMin9))
                                .foregroundColor(trade.tOscMin9 == trade.tOsc ? .green : .primary)
                                Text(String(format:"%.2f",trade.tOscZ125))
                                Text(String(format:"%.2f",trade.tOscZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("k")
                                Text(String(format:"%.2f",trade.tKdK))
                                Text(String(format:"%.2f",trade.tKdKMax9))
                                .foregroundColor(trade.tKdKMax9 == trade.tKdK ? .red : .primary)
                                Text(String(format:"%.2f",trade.tKdKMin9))
                                .foregroundColor(trade.tKdKMin9 == trade.tKdK ? .green : .primary)
                                Text(String(format:"%.2f",trade.tKdKZ125))
                                Text(String(format:"%.2f",trade.tKdKZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("d")
                                Text(String(format:"%.2f",trade.tKdD))
                                Text("-")
                                Text("-")
                                Text(String(format:"%.2f",trade.tKdDZ125))
                                Text(String(format:"%.2f",trade.tKdDZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("j")
                                Text(String(format:"%.2f",trade.tKdJ))
                                Text("-")
                                Text("-")
                                Text(String(format:"%.2f",trade.tKdJZ125))
                                Text(String(format:"%.2f",trade.tKdJZ250))
                            }
                        }
                        Group {
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("high")
                                Text(String(format:"%.2f",trade.tHighDiff))
                                Text(String(format:"%.2f",trade.tHighDiff125))
                                    .foregroundColor(trade.tHighDiff125 == 0 ? .red : .gray)
                                Text(String(format:"%.2f",trade.tHighDiff250))
                                    .foregroundColor(trade.tHighDiff250 == 0 ? .red : .gray)
                                Text(String(format:"%.2f",trade.tHighDiffZ125))
                                Text(String(format:"%.2f",trade.tHighDiffZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("low")
                                Text(String(format:"%.2f",trade.tLowDiff))
                                Text(String(format:"%.2f",trade.tLowDiff125))
                                    .foregroundColor(trade.tLowDiff125 == 0 ? .green : .gray)
                                Text(String(format:"%.2f",trade.tLowDiff250))
                                    .foregroundColor(trade.tLowDiff250 == 0 ? .green : .gray)
                                Text(String(format:"%.2f",trade.tLowDiffZ125))
                                Text(String(format:"%.2f",trade.tLowDiffZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("price")
                                Text(String(format:"%.2f",trade.priceClose))
                                Text(String(format:"%.2f",trade.tHighMax9))
                                    .foregroundColor(trade.tHighMax9 == trade.priceClose ? .red : .primary)
                                Text(String(format:"%.2f",trade.tLowMin9))
                                    .foregroundColor(trade.tLowMin9 == trade.priceClose ? .green : .primary)
                                Text(String(format:"%.2f",trade.tPriceZ125))
                                Text(String(format:"%.2f",trade.tPriceZ250))
                            }
                            Spacer()
                            VStack(alignment: .trailing,spacing: 2) {
                                Text("volume")
                                Text(String(format:"%.0f",trade.priceVolume))
                                Text(String(format:"%.0f",trade.tVolMax9))
                                    .foregroundColor(trade.tVolMax9 == trade.priceVolume ? .red : .primary)
                                Text(String(format:"%.0f",trade.tVolMin9))
                                    .foregroundColor(trade.tVolMin9 == trade.priceVolume ? .green : .primary)
                                Text(String(format:"%.2f",trade.tVolZ125))
                                Text(String(format:"%.2f",trade.tVolZ250))
                            }
                        }
                        Spacer()
                    }   //HStack
                        .font(.custom("Courier", size: textSize(textStyle: .footnote)))
                }
            }   //If
        }   //VStack
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

}
