//
//  simStockList.swift
//  simStock21
//
//  Created by peiyu on 2020/6/24.
//  Copyright © 2020 peiyu. All rights reserved.
//

import Foundation
import SwiftUI
import MobileCoreServices
import BackgroundTasks

class simStockList:ObservableObject {
    @Published private var isLandScape:Bool = UIScreen.main.bounds.width > UIScreen.main.bounds.height
    @Published var sim:simStock = simStock()
    @Published var runningMsg:String = ""
    @Published var selected:Date?
    @Published var pageStock:Stock?

    var versionNow:String
    var versionLast:String = ""
    var appJustActivated:Bool = false

    private let buildNo:String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    private let versionNo:String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    private let isPad  = UIDevice.current.userInterfaceIdiom == .pad

    var rotated:(d:Double,x:CGFloat, y:CGFloat) {
        let orient = UIDevice.current.orientation
         switch orient {
        case .portraitUpsideDown:
            return (180,1,0)
        case .landscapeLeft:
            return (0,0,0)
        case .landscapeRight:
            return (180,0,1)
        default:
            return (0,0,0)
        }
    }
    
    let classIcon:[String] = ["iphone","iphone.landscape","ipad","ipad.landscape","ipad"]
    
    enum WidthClass:Int, Comparable {
        static func < (lhs: WidthClass, rhs: WidthClass) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        case compact = 0
        case widePhone = 1
        case regular = 2
        case widePad = 3
    }
    
    
    var doubleColumn:Bool {
        return isPad && isLandScape && UIApplication.shared.isNotSplitOrSlideOver
    }
        
    func pageColumn(_ hClass:UserInterfaceSizeClass?) -> Bool {
        return hClass == .regular && doubleColumn
    }

    var currentWidthClass:WidthClass = .compact
    func widthClass(_ hClass:UserInterfaceSizeClass?) -> WidthClass {
        var wClass:WidthClass
        switch hClass {
        case .compact:
            if !isPad && isLandScape && UIApplication.shared.isNotSplitOrSlideOver {
                wClass = .widePhone
            } else {
                wClass = .compact
            }
        case .regular:
            if isPad && isLandScape && UIApplication.shared.isNotSplitOrSlideOver {
                wClass = .widePad
            } else if isPad {
                wClass = .regular
            } else {
                wClass = .widePhone
            }
        default:
            wClass = .compact
        }
        if currentWidthClass != wClass && (!isPad || wClass != .compact) { //排除.compact column的情形
            currentWidthClass = wClass
            NSLog("widthClass: \(wClass)")
        }
        return wClass
    }
    
    func widthCG(_ hClass:UserInterfaceSizeClass?, CG:[CGFloat]) -> CGFloat {
        let i = widthClass(hClass).rawValue
        if i < CG.count {
            return CG[i]
        } else if let cg = CG.last {
            return cg
        } else {
            return 0
        }
    }

    init() {
        versionNow = versionNo + (buildNo == "0" ? "" : "(\(buildNo))")
        NotificationCenter.default.addObserver(self, selector: #selector(self.onViewWillTransition), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appNotification), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setRequestStatus), name: NSNotification.Name("requestRunning") , object: nil)
    }
        
    var searchText:[String]? = nil {    //搜尋String以空格逗號分離為關鍵字Array
        didSet {
            sim.fetchStocks(searchText)
        }
    }
    
    var searchTextInGroup:Bool {    //單詞的搜尋目標已在股群內？
        if let search = searchText, search.count == 1 {
            if sim.stocks.map({$0.sId}).contains(search[0]) || sim.stocks.map({$0.sName}).contains(search[0]) {
                return true
            }
        }
        return false
    }
    
    private var prefixedStocks:[[Stock]] {
        Dictionary(grouping: sim.stocks) { (stock:Stock)  in
            stock.prefix
        }.values
            .map{$0.map{$0}.sorted{$0.sName < $1.sName}}
            .sorted {$0[0].prefix < $1[0].prefix}
    }
    
    var prefixs:[String] {
        prefixedStocks.map{$0[0].prefix}
    }
    
    func theGroupStocks(_ stock:Stock) -> [Stock] {
        return sim.stocks.filter{$0.group == stock.group}.sorted{$0.sName < $1.sName}
    }
    
    func theGroupPrefixs(_ stock:Stock) -> [String] {
        var thePrefixs:[String] = []
        let stocks = theGroupStocks(stock)
        for s in stocks {
            if let p = thePrefixs.last, s.prefix == p {
                //首字重複不取
            } else {
                thePrefixs.append(s.prefix)
            }
        }
        return thePrefixs
    }
    
    func shiftRightStock(_ stock:Stock, groupStocks:[Stock]?=nil) -> Stock {
        let stocks = groupStocks ?? sim.stocks
        if let i = stocks.firstIndex(of: stock) {
            if i > 0 {
                return stocks[i - 1]
            } else {
                return stocks[stocks.count - 1]
            }
        }
        return stock
    }
    
    func shiftLeftStock(_ stock:Stock, groupStocks:[Stock]?=nil) -> Stock {
        let stocks = groupStocks ?? sim.stocks
        if let i = stocks.firstIndex(of: stock) {
            if i < stocks.count - 1 {
                return stocks[i + 1]
            } else {
                return stocks[0]
            }
        }
        return stock
    }
    
    func shiftLeftGroup(_ stock:Stock) -> Stock {
        if let i = groups.firstIndex(of: stock.group) {
            if i < groups.count - 1 {
                return groupStocks[i + 1][0]
            } else {
                return groupStocks[0][0]
            }
        }
        return stock
    }
    
    func shiftRightGroup(_ stock:Stock) -> Stock {
        if let i = groups.firstIndex(of: stock.group) {
            if i > 0 {
                return groupStocks[i - 1][0]
            } else {
                return groupStocks[groups.count - 1][0]
            }
        }
        return stock
    }

    
    func prefixStocks(prefix:String, group:String?=nil) -> [Stock] {
        if let g = group {
            return prefixedStocks.filter{$0[0].prefix == prefix}[0].filter{$0.group == g}
        }
        return prefixedStocks.filter{$0[0].prefix == prefix}[0]
    }
        
    var groupStocks:[[Stock]] {
        return sim.groupStocks
    }
    
    var groups:[String] {
        groupStocks.map{$0[0].group}.filter{$0 != ""}
    }
    
    var newGroupName:String {
        var nameInGroup:String = "股群_"
        var numberInGroup:Int = 0
        for groupName in self.groups {
            if let numbersRange = groupName.rangeOfCharacter(from: .decimalDigits) {
                let n = Int(groupName[numbersRange.lowerBound..<numbersRange.upperBound]) ?? 0
                if n > numberInGroup {
                    nameInGroup = String(groupName[..<numbersRange.lowerBound])
                    numberInGroup = n
                }
            }
        }
        return (nameInGroup + String(numberInGroup + 1))
    }
        
    var searchGotResults:Bool { //查無搜尋目標？
        if let firstGroup = groupStocks.first?[0].group, firstGroup == "" {
            return true
        }
        return false
    }
    
    var isRunning:Bool {
        self.runningMsg.count > 0
    }
    
    func deleteTrades(_ stocks:[Stock], oneMonth:Bool=false) {
        sim.deleteTrades(stocks, oneMonth: oneMonth)
    }

    func moveStocks(_ stocks:[Stock], toGroup:String = "") {
        sim.moveStocksToGroup(stocks, group:toGroup)
    }
    
    func addInvest(_ trade: Trade) {
        sim.addInvest(trade)
    }
    
    func setReversed(_ trade: Trade) {
        sim.setReversed(trade)
    }

    var simDefaults:(first:Date,start:Date,money:Double,invest:Double,text:String) {
        let defaults = sim.simDefaults
        let startX = twDateTime.stringFromDate(defaults.start,format: "起始日yyyy/MM/dd")
        let moneyX = String(format:"起始本金%.f萬元",defaults.money)
        let investX = (defaults.invest > 9 ? "自動無限加碼" : (defaults.invest > 0 ? String(format:"自動%.0f次加碼", defaults.invest) : ""))
        let txt = "新股預設：\(startX) \(moneyX) \(investX)"
        return (defaults.first, defaults.start, defaults.money, defaults.invest, txt)
    }
    
    func stocksSummary(_ stocks:[Stock]) -> String {
        let summary = sim.stocksSummary(stocks)
        let count = String(format:"%.f支股 ",summary.count)
        let roi = String(format:"平均年報酬:%.1f%% ",summary.roi)
        let days = String(format:"平均週期:%.f天",summary.days)
        return "\(count) \(roi) \(days)"
    }
    
    func reloadNow(_ stocks: [Stock], action:simTechnical.simTechnicalAction) {
        return sim.reloadNow(stocks, action: action)
    }
    
    func applySetting (_ stock:Stock?=nil, dateStart:Date,moneyBase:Double,autoInvest:Double, applyToGroup:Bool?=false, applyToAll:Bool, saveToDefaults:Bool) {
        var stocks:[Stock] = []
        if applyToAll {
            stocks = self.sim.stocks
        } else if let st = stock {
            if let ag = applyToGroup, ag == true {
                for g in sim.groupStocks {
                    if g[0].group == st.group {
                        for s in g {
                            stocks.append(s)
                        }
                    }
                }
            } else {
                stocks = [st]
            }
        }
    
//        if let st = stock {
//            if applyToAll {
//                stocks = sim.stocks
//            } else if let ag = applyToGroup, ag == true {
//                for g in groupStocks {
//                    if g[0].group == st.group {
//                        for s in g {
//                            stocks.append(s)
//                        }
//                    }
//                }
//            } else {
//                stocks.append(st)
//            }
//        }
        if stocks.count > 0 {
            sim.settingStocks(stocks, dateStart: dateStart, moneyBase: moneyBase, autoInvest: autoInvest)
        }
        if saveToDefaults {
            sim.setDefaults(start: dateStart, money: moneyBase, invest: autoInvest)
        }
    }
    
    @objc private func onViewWillTransition(_ notification: Notification) {
        if UIDevice.current.orientation.isValidInterfaceOrientation {
            if UIDevice.current.orientation.isLandscape {
                self.isLandScape = true
            } else if !UIDevice.current.orientation.isFlat {
                if self.isLandScape {   //由橫轉直時
                    self.selected = nil
                }
                self.isLandScape = false
            }
//            NSLog("\(isLandScape ? "LandScape" : "Portrait")")
        } else {
            self.isLandScape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        }
    }

    @objc private func setRequestStatus(_ notification: Notification) {
        if let userInfo = notification.userInfo, let msg = userInfo["msg"] as? String {
            runningMsg = ""
            if msg == "" {   //股價更新完畢自動展開最新一筆
                if let stock = pageStock, self.appJustActivated {
                    self.selected = stock.lastTrade(coreData.shared.context)?.date
                    self.appJustActivated = false
                }
            } else if msg == "pass!" {
                self.appJustActivated = false
            } else {
                runningMsg = msg
            }
        }
    }

    @objc private func appNotification(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            simLog.addLog ("=== appDidBecomeActive v\(versionNow) ===")
            simLog.shrinkLog(200)
            self.versionLast = defaults.string(forKey: "simStockVersion") ?? ""
            if sim.simTesting {
                sim.runTest()
            } else {
                defaults.set(versionNow, forKey: "simStockVersion")
                var action:simTechnical.simTechnicalAction? {
                    if defaults.bool(forKey: "simResetAll") {
                        defaults.removeObject(forKey: "simResetAll")
                        return .simResetAll
                    } else if defaults.bool(forKey: "simUpdateAll") {
                        defaults.removeObject(forKey: "simUpdateAll")
                        return .simUpdateAll
                    } else if versionLast != versionNow {
//                        let lastNo = (versionLast == "" ? "" : versionLast.split(separator: ".")[0])
//                        let thisNo = versionNow.split(separator: ".")[0]
                        if buildNo == "0" || versionLast == "" {
                            return .tUpdateAll      //改版後需要重算技術值時，應另起版號其build為0
                        } else {
                            return .simUpdateAll    //否則就只會更新模擬，不清除反轉和加碼，即使另起新版其build不為0或留空
                        }
                    }
                    return nil  //其他由現況來判斷
                }
                self.appJustActivated = true
                sim.simUpdateNow(action: action)
            }
        case UIApplication.willResignActiveNotification:
            simLog.addLog ("=== appWillResignActive ===")
            self.sim.invalidateTimer()
        default:
            break
        }

    }
    
//    func reviseWithTWSE(_ stocks:[Stock]?=nil, bgTask:BGTask?=nil) {
//        let requestStocks = stocks ?? sim.stocks
//        DispatchQueue.global().async {
//            self.bgRequest.reviseWithTWSE(requestStocks, bgTask: bgTask)
//        }
//    }
    
}

extension UIApplication {
    public var isNotSplitOrSlideOver: Bool {
        guard let window = self.windows.filter({ $0.isKeyWindow }).first else { return false }
        return (window.frame.width == window.screen.bounds.width)
    }
}
