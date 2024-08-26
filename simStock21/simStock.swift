//
//  simStock.swift
//  simStock21
//
//  Created by peiyu on 2020/6/24.
//  Copyright © 2020 peiyu. All rights reserved.
//

import Foundation 

struct simStock {
    
    let simTesting:Bool = false
    let simTestStart:Date? = twDateTime.dateFromString("2008/09/01")

    private(set) var stocks:[Stock] = []
    private let technical:simTechnical = simTechnical()

    init() {
        coreData.shared.switchDatabase(simTesting)
        if defaults.double(forKey: "simMoneyBase") == 0 {
            let dateStart = twDateTime.calendar.date(byAdding: .year, value: -3, to: twDateTime.startOfDay()) ?? Date.distantFuture
            setDefaults(start: dateStart, money: 70.0, invest: 2)
        }
        self.stocks = Stock.fetch(coreData.shared.context)
        if self.stocks.count == 0 {
            let group1:[(sId:String,sName:String)] = [
                (sId:"3653", sName:"健策"),
                (sId:"3037", sName:"欣興"),
                (sId:"8046", sName:"南電"),
                (sId:"2330", sName:"台積電")]
            self.newStock(stocks: group1, group: "股群_1")
            
            let group2:[(sId:String,sName:String)] = [
                (sId:"2324", sName:"仁寶"),
                (sId:"1301", sName:"台塑"),
                (sId:"1216", sName:"統一"),
                (sId:"2317", sName:"鴻海")]
            self.newStock(stocks: group2, group: "股群_2")
        }
    }
        
    mutating func fetchStocks(_ searchText:[String]?=nil) {
        self.stocks = Stock.fetch(coreData.shared.context, sId: searchText, sName: searchText)
    }
        
    mutating private func newStock(stocks:[(sId:String,sName:String)], group:String?=nil) {
        let context = coreData.shared.context
        for stock in stocks {
            let s = Stock.new(context, sId:stock.sId, sName:stock.sName, group: group)
            let simDefaults = self.simDefaults
            s.dateFirst = simDefaults.first
            s.dateStart = simDefaults.start
            s.simMoneyBase = simDefaults.money
        }
        try? context.save()
        self.fetchStocks()
        NSLog("new stocks added: \(stocks)")
    }
    
    func reloadNow(_ stocks: [Stock], action:simTechnical.simTechnicalAction) {
        if let context = stocks.first?.context {
            for stock in stocks {
                if stock.simInvestAuto == 0 {
                    stock.simInvestAuto = 2
                }
            }
            try? context.save()
        }
        self.technical.downloadTrades(stocks, requestAction: action, allStocks: self.stocks)
    }
    
    func simUpdateNow(action:simTechnical.simTechnicalAction?=nil) {
        technical.downloadStocks()    //更新股票代號和簡稱的對照表   doItNow: true
        technical.reviseCompanyInfo(self.stocks)
        DispatchQueue.global().async {
            self.technical.downloadTrades(self.stocks, requestAction: action)
        }

    }
    
    func invalidateTimer() {
        technical.invalidateTimer()
    }
    
    mutating func moveStocksToGroup(_ stocks:[Stock], group:String) {
        if let context = stocks.first?.context {
            var newStocks:[Stock] = []
            let simDefaults = self.simDefaults
            for stock in stocks {
                if stock.group == "" && group != "" {
                    if simDefaults.first < stock.dateFirst {
                        stock.dateFirst = simDefaults.first
                        stock.dateStart = simDefaults.start
                    }
                    stock.simMoneyBase = simDefaults.money
                    stock.simInvestUser = 0
                    stock.simInvestExceed = 0
                    stock.simMoneyLacked = false
                    stock.simReversed = false
                    newStocks.append(stock)
                }
                stock.group = group
                if group == "" {
                    self.stocks = self.stocks.filter{$0 != stock}
                }   //搜尋而加入新股不用append到self.stocks因為searchText在給值或清除時都會fetchStocks
            }
            try? context.save()
            if newStocks.count > 0 {
                let _ = technical.downloadTrades(newStocks, requestAction: .newTrades, allStocks: self.stocks)
            }
        }
    }
    
    func deleteTrades(_ stocks:[Stock], oneMonth:Bool=false) {
        DispatchQueue.global().async {
            for stock in stocks {
                stock.deleteTrades(oneMonth: oneMonth)
            }
            DispatchQueue.main.async {
                let _ = self.technical.downloadTrades(stocks, requestAction: (stocks.count > 1 ? .allTrades : .newTrades), allStocks: self.stocks)    //allTrades才會提示等候訊息
            }
        }
    }

    func addInvest(_ trade: Trade) {
        if let context = trade.managedObjectContext {
            let trades = Trade.fetch(context, stock: trade.stock, userActions:true)
            if trade.simInvestByUser == 0 {
                if trade.simInvestAdded > 0 {
                    trade.simInvestByUser = -1
                } else if trade.simInvestAdded == 0 {
                    trade.simInvestByUser = 1
                }
                trade.stock.simInvestUser += 1
            } else {
//                trade.simInvestByUser = 0
//                trade.stock.simInvestUser -= 1
                trade.resetInvestByUser()
            }
            for tr in trades {
                if tr.date > trade.date {
                    tr.simReversed = ""
                    if tr.simInvestByUser != 0 {
//                        tr.simInvestByUser = 0
//                        tr.stock.simInvestUser -= 1
                        tr.resetInvestByUser()

                    }
                }
            }
            NSLog("\(trade.stock.sId)\(trade.stock.sName) simInvestUser: \(trade.stock.simInvestUser)")
            try? context.save()
            technical.downloadTrades([trade.stock], requestAction: .simUpdateAll, allStocks: self.stocks)
        }
    }
    
    func setReversed(_ trade: Trade) {
        if let context = trade.managedObjectContext {
            let trades = Trade.fetch(context, stock: trade.stock, userActions:true)
            let simQty = trade.simQty
            if trade.simReversed == "" {
                switch simQty.action {
                case "買":
                    if trade.invested > 0 {
                        trade.simReversed = "S+"
                    } else {
                        trade.simReversed = "B-"
                    }
                case "賣":
                    trade.simReversed = "S-"
                case "餘":
                    trade.simReversed = "S+"
                default:
                    trade.simReversed = "B+"
                }
                trade.stock.simReversed = true
                if trade.simInvestByUser != 0 {
                    trade.simInvestByUser = 0
                    trade.stock.simInvestUser -= 1
                }
                if trade.simInvestByUser != 0 {
                    trade.simInvestByUser = 0
                    trade.stock.simInvestUser -= 1
                }
            } else {
                trade.simReversed = ""
                trade.stock.simReversed = false
            }
            for tr in trades {
                if tr.date > trade.date {
                    tr.simReversed = ""
                    if tr.simInvestByUser != 0 {
//                        tr.simInvestByUser = 0
//                        tr.stock.simInvestUser -= 1
                        tr.resetInvestByUser()
                    }
                } else if tr.date < trade.date && tr.simReversed != "" {
                    tr.stock.simReversed = true
                }
            }
            try? context.save()
            technical.downloadTrades([trade.stock], requestAction: .simUpdateAll, allStocks: self.stocks)
        }
    }
    
    func settingStocks(_ stocks:[Stock],dateStart:Date,moneyBase:Double,autoInvest:Double) {
        var dateChanged:Bool = false
        for stock in stocks {
            if dateStart != stock.dateStart {
                stock.dateStart = dateStart
                let dtFirst = twDateTime.calendar.date(byAdding: .year, value: -1, to: dateStart) ?? stock.dateStart
                if dtFirst < stock.dateFirst {
                    stock.dateFirst = dtFirst
                }
                dateChanged = true
            }
            stock.simMoneyBase = moneyBase
            stock.simInvestAuto = autoInvest
            DispatchQueue.main.async {
                try? stock.context.save()
            }
        }
        if !simTesting {
            technical.downloadTrades(stocks, requestAction: (dateChanged ? .allTrades : .simResetAll), allStocks: self.stocks)
        }
    }
    
    var simDefaults:(first:Date,start:Date,money:Double,invest:Double) {
        let start = defaults.object(forKey: "simDateStart") as? Date ?? Date.distantFuture
        let money = defaults.double(forKey: "simMoneyBase")
        let invest = defaults.double(forKey: "simAutoInvest")
        let first = twDateTime.calendar.date(byAdding: .year, value: -1, to: start) ?? start
        return (first,start,money,invest)
    }
    
    func setDefaults(start:Date,money:Double,invest:Double) {
        defaults.set(start, forKey: "simDateStart")
        defaults.set(money, forKey: "simMoneyBase")
        defaults.set(invest,forKey: "simAutoInvest")
    }
    
//    var t00:Stock? {
//        let t00 = stocks.filter{$0.sId == "t00"}
//        if t00.count > 0 {
//            return t00[0]
//        }
//        return nil
//    }
    
        
    var groupStocks:[[Stock]] {
        Dictionary(grouping: stocks) { (stock:Stock)  in
            stock.group
        }.values
            .map{$0.map{$0}.sorted{$0.sName < $1.sName}}
            .sorted {$0[0].group < $1[0].group}
    }
    
    func stocksSummary(_ stocks:[Stock], date:Date?=nil) -> (count:Double, roi:Double, days:Double) {
        if stocks.count == 0 {
            return (0,0,0)
        }
        var sumRoi:Double = 0
        var sumDays:Double = 0
        for stock in stocks {
            if let trade = stock.lastTrade(stock.context, date: date) {
                sumRoi += (trade.rollAmtRoi / stock.years)
                sumDays += trade.days
            }
        }
        let count = Double(stocks.count)
        let roi = sumRoi / count
        let days = sumDays / count
        return (count, roi, days)
    }
    
    func runTest() {
        defaults.set(true, forKey: "simUpdateAll")
        let start = self.simTestStart ?? (twDateTime.calendar.date(byAdding: .year, value: -15, to: twDateTime.startOfDay()) ?? Date.distantPast)   //測試15年內每年的模擬3年的成績
        NSLog("")
        NSLog("== simTesting \(twDateTime.stringFromDate(start)) ==")
        var groupRoi:String = ""
        var groupDays:String = ""
        for g in 0...(groupStocks.count - 1) {
            let stocks = groupStocks[g]
            let result = testStocks(stocks, start: start)
            groupRoi = groupRoi + (groupRoi.count > 0 ? ",, " : "") + result.roi
            groupDays = groupDays + (groupDays.count > 0 ? ",, " : "") + result.days
        }
        print("\n")
        print(groupRoi)
        print(groupDays)
        print("\n")
        NSLog("== simTesting finished. ==")
        NSLog("")
    }
    
    private func testStocks(_ stocks:[Stock], start:Date) -> (roi:String, days:String) {
        var roi:String = ""
        var days:String = ""
        let years:Int = Int(round(Date().timeIntervalSince(start) / 86400 / 365))
        print("\n\n\(stocks[0].group)：(\(stocks.count)) 自\(twDateTime.stringFromDate(start,format:"yyyy"))第\(years)年起 ... ", terminator:"")
        var nextYear:Date = start
        while nextYear <= (twDateTime.calendar.date(byAdding: .year, value: -1, to: twDateTime.startOfDay()) ?? Date.distantPast) {
            settingStocks(stocks, dateStart: nextYear, moneyBase: 500, autoInvest: 2)
            for stock in stocks {
                technical.technicalUpdate(stock: stock, action: .simTesting)
            }
            let endYear = (twDateTime.calendar.date(byAdding: .year, value: 3, to: nextYear) ?? Date.distantFuture)
            let summary = stocksSummary(stocks, date: endYear)
            roi = String(format:"%.1f", summary.roi) + (roi.count > 0 ? ", " : "") + roi
            days = String(format:"%.f", summary.days) + (days.count > 0 ? ", " : "") + days
            print("\(twDateTime.stringFromDate(nextYear, format: "yyyy"))" + String(format:"(%.1f/%.f) ",summary.roi,summary.days), terminator:"")
            nextYear = (twDateTime.calendar.date(byAdding: .year, value: 1, to: nextYear) ?? Date.distantPast)
        }
        return (roi,days)
    }
    
//    var stocksJSON: Data? { try? JSONEncoder().encode(stocks) }
//    init?(stocksJSON: Data?) {
//        if let json = stocksJSON, let s = try? JSONDecoder().decode(Array<Stock>.self, from: json) {
//            stocks = s
//        } else {
//            stocks = []
//        }
//    }
    

    
}

