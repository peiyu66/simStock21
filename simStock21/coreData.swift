//
//  coreData.swift
//  simStock21
//
//  Created by peiyu on 2020/6/24.
//  Copyright © 2020 peiyu. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI

public class coreData {

    static var shared = coreData()

    private init() {} // Prevent clients from creating another instance.
    
    private var dbName:String = "simStock21"
    
    public func switchDatabase(_ yes:Bool=false) {
        if  yes {
//            dbName = "simTest"
        }
    }

    lazy private var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "simStock21")
        //********* 為了extension共享此而將資料庫放在app groups
        let storeURL = URL.storeURL(for: "group.com.mystock.simStock21", databaseName: dbName)
        let storeDescription = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [storeDescription]
        //********* 以上，不需app groups時可移除
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
              fatalError("persistentContainer error \(storeDescription) \(error) \(error.userInfo)")
            }
        })
        return container
    }()

    lazy private var mainContext: NSManagedObjectContext = {
        let context = self.persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return context
    }()
    

    var context:NSManagedObjectContext {
        if Thread.current == Thread.main {
            return mainContext
        } else {
            let context = persistentContainer.newBackgroundContext()
            return context
        }
    }
    
}

public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }
        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}


public class Stock: NSManagedObject {
    
    static func fetchRequestStock (sId:[String]?=nil, sName:[String]?=nil, fetchLimit:Int?=nil) -> NSFetchRequest<Stock> {
        let fetchRequest = NSFetchRequest<Stock>(entityName: "Stock")
        var predicates:[NSPredicate] = []
        if let ids = sId {
            for sId in ids {
                let upperId = sId.localizedUppercase
                if ids.count == 1 && sName == nil {
                    predicates.append(NSPredicate(format: "sId == %@", upperId))
                } else {
                    predicates.append(NSPredicate(format: "sId CONTAINS %@", upperId))
                }
            }
        }
        if let names = sName {
            for sName in names {
                let upperName = sName.localizedUppercase
                predicates.append(NSPredicate(format: "sName CONTAINS %@", upperName))
            }
        }
        let grouping = NSPredicate(format: "group != %@", "")
        //合併以上條件為OR，或不搜尋sId,sName時只查回股群清單（過濾掉不在股群內的上市股）
        if predicates.count > 0 {
            if predicates.count > 1 { //只查sId時回傳就是該股即使不在股群內
                predicates.append(grouping)
            }
            fetchRequest.predicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
        } else {
            fetchRequest.predicate = grouping
        }
        //固定的排序
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sName", ascending: true)]
        if let limit = fetchLimit {
            fetchRequest.fetchLimit = limit
        }
        return fetchRequest
    }
    

    static func fetch (_ context:NSManagedObjectContext, sId:[String]?=nil, sName:[String]?=nil, fetchLimit:Int?=nil) -> [Stock] {
        let fetchRequest = self.fetchRequestStock(sId: sId, sName: sName, fetchLimit: fetchLimit)
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    static func new(_ context:NSManagedObjectContext, sId:String, sName:String?=nil, group:String?=nil) -> Stock {
        let stocks = fetch(context, sId:[sId])
        if stocks.count == 0 {
            let stock = Stock(context: context)
            stock.sId    = sId
            stock.sName  = sName ?? sId
            stock.group = group ?? ""
            return stock
        } else {
            for (index,stock) in stocks.enumerated() {
                if let sName = sName {
                    stock.sName = sName
                }
                if let group = group {
                    stock.group = group
                }
                if index > 0 {
                    NSLog("\(stock.sId)\(stock.sName) 重複\(index)???")
                }
            }
        }
        return stocks[0]

    }
    
    var context:NSManagedObjectContext {
        return self.managedObjectContext ?? coreData.shared.context
    }
    
    func save() {
        DispatchQueue.main.async {
            try? self.context.save()
        }        
    }


//}
//
//extension Stock {
//
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<Stock> {
//        return NSFetchRequest<Stock>(entityName: "Stock")
//    }


    @NSManaged public var sId: String
    @NSManaged public var sName: String
    @NSManaged public var group: String
    @NSManaged public var p10Action: String?
    @NSManaged public var p10Date: Date?
    @NSManaged public var p10L: String   //五檔試算
    @NSManaged public var p10H: String   //五檔試算
    @NSManaged public var p10Rule: String?
    @NSManaged public var proport: String?  //營收比重
    @NSManaged public var dateFirst: Date   //歷史價格起始
    @NSManaged public var dateStart: Date   //模擬交易起始
    @NSManaged public var simInvestAuto:Double      //自動加碼次數：0～9，10為無限次
    @NSManaged public var simInvestExceed:Double    //自動加碼超次：跌太深自動超次加碼
    @NSManaged public var simInvestUser:Double      //user變更加碼次數
    @NSManaged public var simMoneyBase: Double      //每次投入本金額度
    @NSManaged public var simMoneyLacked: Bool        //本金不足？
    @NSManaged public var simReversed:Bool          //反轉買賣
    @NSManaged public var stockTrades: Set<Trade>?
    
    func p10Reset() {
        self.p10Action = nil
        self.p10Date = nil
        self.p10L = ""
        self.p10H = ""
        self.p10Rule = nil
    }
    
    var moneyBase:Double {
        self.simMoneyBase * 10000
    }
    
    var prefix:String {
        String(sName.first ?? Character(""))
    }
    
    var trades:[Trade] {
        let context = coreData.shared.context   //不一定只給swiftui用的
        return Trade.fetch(context, stock: self, asc: false)
    }
    
    func firstTrade(_ context:NSManagedObjectContext) -> Trade? {
        let trades = Trade.fetch(context, stock: self, fetchLimit: 1, asc: true)
        return trades.first
    }
    
    func lastTrade(_ context:NSManagedObjectContext, date:Date?=nil) -> Trade? {
        let trades = Trade.fetch(context, stock: self, end: date, fetchLimit: 1, asc: false)
        return trades.first
    }
    
    func deleteTrades(oneMonth:Bool=false) {
        let context = coreData.shared.context
        var mStart:Date? = nil
        if oneMonth {
            if let last = self.lastTrade(context) {
                mStart = twDateTime.startOfMonth(last.date)
            }
        }
        let trades = Trade.fetch(context, stock: self, start: mStart)
        NSLog("\(self.sId)\(self.sName) 刪除trades:共\(trades.count)筆")
        for trade in trades {
            context.delete(trade)
        }
        try? context.save()
    }

    var years:Double {
        var years = Date().timeIntervalSince(self.dateStart) / 86400 / 365
        if years < 1 {
            years = 1
        }
        return years
    }
    
    var dateRequestStart:Date { //起始模擬日往前1年，作為分析數值的基礎
        return twDateTime.calendar.date(byAdding: .year, value: -1, to: self.dateStart) ?? self.dateStart
    }
    
    var dateRequestTWSE:Date? {
        let yesterday = (twDateTime.calendar.date(byAdding: .day, value: -1, to: twDateTime.endOfDay()) ?? Date.distantFuture)
        let twseStart:Date = twDateTime.dateFromString("2010/01/01")! //TWSE只能查到2010之後
        let dStart:Date = dateRequestStart < twseStart ? twseStart : dateRequestStart
        let context = coreData.shared.context
        if let trade = Trade.fetch(context, stock: self, end: yesterday, TWSE: false, fetchLimit: 1, asc: false).first {
            if trade.date >= dStart { //2010之前的沒得查
                return trade.date
            }
        } else if let trade = self.trades.last {
            if let d = twDateTime.calendar.dateComponents([.day], from: dStart, to: trade.date).day, d > 10 {
                if let s = twDateTime.calendar.date(byAdding: .month, value: -1, to: trade.date), d > 30 {
                    let s0 = twDateTime.startOfMonth(s)
                    return s0
                }
                if let d1 = twDateTime.calendar.dateComponents([.day], from: dStart, to: trade.date).day, d1 > 10 {
                    return dStart
                }
            }
        }
        return nil
    }
    
    var proport1:String {
        if let proport = self.proport {
            if let range = proport.range(of: "(.+?)[0-9|.|%|,|(]+?", options: .regularExpression) {
                let endIndex = proport.index(range.upperBound, offsetBy: -1)
                var item0 = String(proport[..<endIndex])
                if let r = item0.last, (r == "," || r == "及" || r == "-") {
                    item0 = String(item0.dropLast())
                }
                return item0
            }
            return proport
        }
        return ""
    }
    
    
    
//    @objc(addTradeObject:)
//    @NSManaged public func addToTrade(_ value: Trade)
//
//    @objc(removeTradeObject:)
//    @NSManaged public func removeFromTrade(_ value: Trade)
//
//    @objc(addTrade:)
//    @NSManaged public func addToTrade(_ values: NSSet)
//
//    @objc(removeTrade:)
//    @NSManaged public func removeFromTrade(_ values: NSSet)

}


@objc(Trade)
public class Trade: NSManagedObject {
    static func fetchRequest (stock:Stock, start:Date?=nil, end:Date?=nil, TWSE:Bool?=nil, userActions:Bool?=nil, fetchLimit:Int?=nil, asc:Bool=false) -> NSFetchRequest<Trade> {
        var predicates:[NSPredicate] = []
        predicates.append(NSPredicate(format: "stock == %@", stock))
        if let dtS = start {
            predicates.append(NSPredicate(format: "dateTime >= %@", dtS as CVarArg))
        }
        if let dtE = end {
            predicates.append(NSPredicate(format: "dateTime <= %@", dtE as CVarArg))
        }
        if let t = TWSE {
            predicates.append(NSPredicate(format: "dataSource \(t ? "==" : "!=") %@", "TWSE"))
        }
        if let r = userActions, r == true  {    //過濾出反轉買賣的trades
            var subPred:[NSPredicate] = []
            subPred.append(NSPredicate(format: "simReversed != %@", ""))
            subPred.append(NSPredicate(format: "simInvestByUser != %@", 0))
            predicates.append(NSCompoundPredicate(type: .or, subpredicates: subPred))
        }
        let fetchRequest = NSFetchRequest<Trade>(entityName: "Trade")
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "stock", ascending: true), NSSortDescriptor(key: "dateTime", ascending: asc)]
        if let limit = fetchLimit {
            fetchRequest.fetchLimit = limit
        }
        fetchRequest.returnsObjectsAsFaults = false
        return fetchRequest
    }
    
    static func fetch (_ context:NSManagedObjectContext, stock:Stock, start:Date?=nil, end:Date?=nil, TWSE:Bool?=nil, userActions:Bool?=nil, fetchLimit:Int?=nil, asc:Bool=false) -> [Trade] {
        let fetchRequest = self.fetchRequest(stock: stock, start: start, end: end, TWSE: TWSE, userActions: userActions, fetchLimit: fetchLimit, asc: asc)
        
            let contextCurrency = (context.concurrencyType == .mainQueueConcurrencyType ? "main" : "private")
            let threadCurrency = (Thread.current == Thread.main ? "main" : "private")
            if contextCurrency != threadCurrency {
                simLog.addLog("!!!context:\(contextCurrency), but thread:\(threadCurrency)")
            }
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    static func trade (_ context:NSManagedObjectContext, stock:Stock, date:Date) -> Trade {
        let dtS = twDateTime.startOfDay(date)
        let dtE = twDateTime.endOfDay(date)
        let fetchRequest = self.fetchRequest(stock: stock, start: dtS, end: dtE ,fetchLimit: 1, asc: true)
        if let trades = try? context.fetch(fetchRequest), let trade = trades.first, trade.date == dtS {
            for (i, t) in trades.enumerated() {
                if i > 0 {
                    context.delete(t)
                    let dt = twDateTime.stringFromDate(t.dateTime)
                    simLog.addLog("!!!duplicated trade was deleted: \(stock.sId)\(stock.sName) \(dt)")
                }
            }
            return trade
        } else {
            let trade = Trade(context: context)
            if let s = Stock.fetch(context, sId:[stock.sId]).first {
                trade.stock = s
            }
            return trade
        }
        
    }


//    static func new(_ context:NSManagedObjectContext, stock:Stock, dateTime:Date) -> Trade {
//        let trade = Trade(context: context)
//        trade.stock = stock
//        trade.dateTime = dateTime
//        return trade
//    }

//}
//
//extension Trade {
//
//    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trade> {
//        return NSFetchRequest<Trade>(entityName: "Trade")
//    }

    @NSManaged public var dataSource: String        //價格來源
    @NSManaged public var dateTime: Date            //成交/收盤時間
    @NSManaged public var priceClose: Double        //成交/收盤價
    @NSManaged public var priceHigh: Double         //最高價
    @NSManaged public var priceLow: Double          //最低價
    @NSManaged public var priceOpen: Double         //開盤價
    @NSManaged public var priceVolume: Double       //成交量
    @NSManaged public var rollAmtCost: Double
    @NSManaged public var rollAmtProfit: Double
    @NSManaged public var rollAmtRoi: Double
    @NSManaged public var rollDays: Double
    @NSManaged public var rollRounds: Double
    @NSManaged public var simAmtBalance: Double
    @NSManaged public var simAmtCost: Double
    @NSManaged public var simAmtProfit: Double
    @NSManaged public var simAmtRoi: Double
    @NSManaged public var simDays: Double           //持股日數
    @NSManaged public var simInvestAdded: Double    //自動加碼
    @NSManaged public var simInvestByUser: Double   //玩家變更加碼
    @NSManaged public var simInvestTimes: Double    //本金倍數：初始1倍+加碼次數
    @NSManaged public var simQtyBuy: Double         //買入張數
    @NSManaged public var simQtyInventory: Double   //庫存張數
    @NSManaged public var simQtySell: Double        //賣出張數
    @NSManaged public var simReversed:String        //反轉行動
    @NSManaged public var simRule:String            //模擬預定
    @NSManaged public var simRuleBuy:String         //模擬行動：高買H或低賣L
    @NSManaged public var simRuleInvest:String      //模擬行動：加碼
    @NSManaged public var simUnitCost: Double       //成本單價
    @NSManaged public var simUnitRoi: Double
    @NSManaged public var tHighDiff: Double         //最高價差比
    @NSManaged public var tHighDiff125: Double      //0.5年內的最高價與收盤價跌幅比率
    @NSManaged public var tHighDiff250: Double      //1.0年內的最高價與收盤價跌幅比率
    @NSManaged public var tHighDiffZ125: Double      //0.5年內的tHighDiff125標準差分
    @NSManaged public var tHighDiffZ250: Double      //1.0年內的tHighDiff250標準差分
    @NSManaged public var tHighMax9: Double         //9天內的最高價
    @NSManaged public var tKdD: Double              //K,D,J
    @NSManaged public var tKdDZ125: Double          //0.5年標準差分
    @NSManaged public var tKdDZ250: Double          //1.0年標準差分
    @NSManaged public var tKdJ: Double
    @NSManaged public var tKdJZ125: Double          //0.5年標準差分
    @NSManaged public var tKdJZ250: Double          //1.0年標準差分
    @NSManaged public var tKdK: Double
    @NSManaged public var tKdKMax9: Double
    @NSManaged public var tKdKMin9: Double
    @NSManaged public var tKdKZ125: Double          //0.5年標準差分
    @NSManaged public var tKdKZ250: Double          //1.0年標準差分
    @NSManaged public var tLowDiff: Double          //最低價差比
    @NSManaged public var tLowDiff125: Double       //0.5年內的最低價與收盤價跌幅比率
    @NSManaged public var tLowDiff250: Double       //1.0年內的最低價與收盤價跌幅比率
    @NSManaged public var tLowDiffZ125: Double       //0.5年內的tLowDiffZ125標準差分
    @NSManaged public var tLowDiffZ250: Double       //1.0年內的tLowDiff250標準差分
    @NSManaged public var tLowMin9: Double          //9天內的最低價
    @NSManaged public var tMa20: Double             //20天均價
    @NSManaged public var tMa20Days: Double         //Ma20延續漲跌天數
    @NSManaged public var tMa20Diff: Double
    @NSManaged public var tMa20DiffMax9: Double
    @NSManaged public var tMa20DiffMin9: Double
    @NSManaged public var tMa20DiffZ125: Double     //Ma20Diff於0.5年標準差分
    @NSManaged public var tMa20DiffZ250: Double     //Ma20Diff於1.0年標準差分
    @NSManaged public var tMa60: Double             //60天均價
    @NSManaged public var tMa60Days: Double         //Ma60延續漲跌天數
    @NSManaged public var tMa60Diff: Double         //現價對Ma60差比
    @NSManaged public var tMa60DiffMax9: Double     //Ma60Diff於9天內最高
    @NSManaged public var tMa60DiffMin9: Double     //Ma60Diff於9天內最低
    @NSManaged public var tMa60DiffZ125: Double     //Ma60Diff於0.5年標準差分
    @NSManaged public var tMa60DiffZ250: Double     //Ma60Diff於1.0年標準差分
    @NSManaged public var tOsc: Double              //Macd的Osc
    @NSManaged public var tOscEma12: Double
    @NSManaged public var tOscEma26: Double
    @NSManaged public var tOscMacd9: Double
    @NSManaged public var tOscMax9: Double
    @NSManaged public var tOscMin9: Double
    @NSManaged public var tOscZ125: Double          //0.5年標準差分
    @NSManaged public var tOscZ250: Double          //1.0年標準差分
    @NSManaged public var tPriceZ125: Double
    @NSManaged public var tPriceZ250: Double
    @NSManaged public var tUpdated: Bool
    @NSManaged public var stock: Stock
    @NSManaged public var tVolMax9: Double
    @NSManaged public var tVolMin9: Double
    @NSManaged public var tVolZ125: Double
    @NSManaged public var tVolZ250: Double

    var date:Date {
        twDateTime.startOfDay(dateTime)
    }
    
    var years:Double {
        var years:Double = 1
        let stock:Stock? = self.stock   //刪除trades時，UI參考的舊trade.stock會是nil
        let y = (date.timeIntervalSince(stock?.dateStart ?? Date.distantFuture) / 86400 / 365)
        if y >= 1 {
            years = y
        }
        return years
    }
        
    var days:Double {
        if self.rollRounds <= 1 {
            return self.rollDays
        } else {
            let prevRounds = (self.rollRounds - (self.simQtyInventory > 0 ? 1 : 0))
            let prevDays = (self.rollDays - (self.simQtyInventory > 0 ? self.simDays : 0)) / prevRounds
            return (self.simDays > prevDays ? self.rollDays / self.rollRounds : prevDays)
        }
    }
    
    var roi:Double {    //實年保酬率：未使用的加碼備用金應不計入成本，而取每輪買賣使用到的現金乘以天數佔比合計為成本。
        return self.rollAmtRoi / self.years //用以評估該股的熱門程度或獲益效率，是選股的參考數值。
    }
    
    var baseRoi:Double {    //真年報酬率：即使未使用到加碼備用金，該備用金也不能任意挪用，故應計入成本才是真正的報酬率。
        let stock:Stock? = self.stock
        if let s = stock, s.simInvestAuto < 10 {
            let base = (s.simInvestAuto + 1) * s.simMoneyBase * 10000
            return (100 * self.rollAmtProfit / base / self.years)    //用以評估小確幸的策略和程式模擬交易的效率。
        } else {
            return 0
        }
    }
        
    enum Grade:Int, Comparable {
        static func < (lhs: Trade.Grade, rhs: Trade.Grade) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        case wow  = 3
        case high = 2
        case fine = 1
        case none = 0
        case weak = -1
        case low  = -2
        case damn = -3
    }
    var grade:Grade {
        if self.rollRounds > 2 || self.days > 360 {
            if self.days < 65 && self.roi > 20 {
                return .wow
            } else if self.days < 65 && self.roi > 10 {
                return .high
            } else if self.days < 70 && self.roi > 5 {
                return .fine
            } else if self.days > 180 || self.roi < -20 {
                    return .damn
            } else if self.days > 120 || self.roi < -10 {
                return .low //雖然還沒有使用到low，但改變low的集合就會影響到weak的集合
            } else if self.days > 60 || self.roi < -1 {
                return .weak
            }
        }
        return .none
    
    }
    
    func byGrade (_ values:[Double], L:Grade?=nil, H:Grade?=nil) -> Double {
        let l = L ?? .weak
        let h = H ?? .high
        if self.grade <= l {
            return values.first ?? 0
        } else if self.grade >= h {
            return values.last ?? 0
        } else if values.count == 3 {
            return values[1]
        } else if H != nil && L == nil {
            return values.first ?? 0    //指定H省略L時，意即H以外都歸第1個數值
        } else {
            return values.last ?? 0     //不指定H，高於.weak或指定的L都歸最後1個數值
        }
    }

    
    func gradeIcon(gray:Bool=false) -> some View  {
        var color:Color {
            if gray {
                return .gray
            } else if self.stock.simMoneyLacked {
                return Color(.darkGray)
            } else if self.grade.rawValue > 0 {
                return .red
            } else if self.grade.rawValue < 0 {
                return .green
            } else {
                return .gray
            }
        }
        switch self.grade {
        case .wow:
            return Image(systemName: "star.square.fill")
                .foregroundColor(color)
        case .damn:
            return Image(systemName: "3.square")
                .foregroundColor(color)
        case .high, .low:
            return Image(systemName: "2.square")
                .foregroundColor(color)
        case .fine, .weak:
            return Image(systemName: "1.square")
                .foregroundColor(color)
        default:
            return Image(systemName: "0.square")
                .foregroundColor(.gray)
        }
    }
    
    var invested:Double {
        return self.simInvestByUser + self.simInvestAdded
    }
    
    func resetInvestByUser () {
        self.simInvestByUser = 0
        if self.stock.simInvestUser > 0 {
            self.stock.simInvestUser -= 1
        } else {
            simLog.addLog("bug: \(self.stock.sId)\(self.stock.sName) \(twDateTime.stringFromDate(self.dateTime)) stock.simInvestUser = \(self.stock.simInvestUser) ???")
            self.stock.simInvestUser = 0
        }
    }

    
    var simQty:(action:String,qty:Double,roi:Double) {
        if self.simQtySell > 0 {
            return ("賣", simQtySell, simAmtRoi)
        } else if self.simQtyBuy > 0 {
            return ("買", simQtyBuy, simAmtRoi)
        } else if self.simQtyInventory > 0 {
            return ("餘", simQtyInventory, simAmtRoi)
        } else {
            return ("", 0, 0)
        }
    }
        
    enum colorScheme {
        case price  //開盤、最高、最低、收盤價
        case time   //盤中的日期、時間、收盤價
        case ruleR  //收盤價的圓框
        case ruleB  //收盤價的背景
        case ruleF  //收盤價的文字
        case rule   //只供ruleR, ruleB, qty的延伸規則
        case qty    //買、賣的狀態
    }
    
    func color (_ scheme: colorScheme, gray:Bool=false, price:Double?=nil) -> Color {
        if gray {
            if scheme == .ruleB || (scheme == .ruleR && self.simRule != "L" && self.simRule != "H") {
                return .clear
            } else {
                return .gray
            }
        }
        let thePrice:Double = price ?? self.priceClose  //專用於開盤、最高、最低3個價，或收盤價為nil
        let stock:Stock? = self.stock   //刪除trades時，UI參考的舊trade.stock會是nil
        let p10Action:String = stock?.p10Action ?? ""
        let p10Rule:String? = stock?.p10Rule
        let p10Date:Date = stock?.p10Date ?? Date.distantFuture
        switch scheme {
        case .price:
            if p10Action == "" || p10Date != self.date {
                if self.tLowDiff == 10 && self.priceLow == thePrice {
                    return .green
                } else  if self.tHighDiff == 10 && self.priceHigh == thePrice {
                    return .red
                }
            }
            return self.color(price == nil ? .ruleF : .time)
            
        case .time:
            if twDateTime.inMarketingTime(self.dateTime) {
                return Color(UIColor.purple)
            } else if self.simRule == "_" {
                return .gray
            } else {
                return .primary
            }
        case .rule:
            let rule = (p10Action != "買" || p10Date != self.date ? self.simRule : (p10Rule ?? self.simRule))
            switch rule {
            case "L":
                return .green
            case "H":
                return .red
            default:
                if self.simRuleInvest == "A" {
                    return .green
                } else if self.simInvestByUser > 0 {
                    return .orange
                }
                return .primary
            }
        case .ruleF:
            if p10Action != "" && p10Date == self.date {
                return .white
            } else {
                return self.color(.time)
            }
        case .ruleB:
            if p10Action != "" && p10Date == self.date {
                if p10Rule == "B" || p10Rule == "S" {
                    return .gray
                } else if p10Action == "賣" {    //反轉而買或賣
                    return .blue
                } else {
                    return self.color(.rule)
                }
            } else {
                return .clear
            }
        case .ruleR:
            if self.simRule == "L" || self.simRule == "H" {
                return self.color(.rule)
            } else {
                return .clear
            }
        case .qty:
            switch self.simQty.action {
            case "賣":
                return .blue
            case "買":
                return self.color(.rule)
            default:
                return .primary
            }
        }
    }
    
    func resetSimValues() {
        self.simAmtCost = 0
        self.simAmtProfit = 0
        self.simAmtRoi = 0
        self.simDays = 0
        self.simQtyBuy = 0         //買入張數
        self.simQtyInventory = 0   //庫存張數
        self.simQtySell = 0        //賣出張數
        self.simUnitCost = 0       //成本單價
        self.simUnitRoi = 0
        self.simRule = ""
        self.simRuleBuy = ""
        self.simRuleInvest = ""
        self.simInvestAdded = 0
        //模擬中不能清除反轉或加碼，只由.tUpdateAll或.simResetAll負責清除
    }
    
    func setDefaultValues() {
        self.rollAmtCost = 0
        self.rollAmtProfit = 0
        self.rollAmtRoi = 0
        self.rollDays = 0
        self.rollRounds = 0
        
        self.resetSimValues()
        if self.simInvestByUser != 0 {
//            self.simInvestByUser = 0
//            self.stock.simInvestUser -= 1
            self.resetInvestByUser()
        }
//        self.simInvestAdded = 0
        self.simInvestTimes = 0
        self.simAmtBalance = 0
        self.simReversed = ""
    }
}
