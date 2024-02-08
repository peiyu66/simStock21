//
//  IntentHandler.swift
//  simStockEx
//
//  Created by peiyu on 2021/5/22.
//  Copyright © 2021 peiyu. All rights reserved.
//

import Intents


class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is FindStocksIntent:
            return findStocksIntentHandler()
        case is GetTradesCSVIntent:
            return getTradesCSVIntentHandler()
        default:
            return self
        }
    }
}

class findStocksIntentHandler:NSObject, FindStocksIntentHandling {
    func handle(intent: FindStocksIntent, completion: @escaping (FindStocksIntentResponse) -> Void) {
        var keys:[String] = []
        for keyword in intent.keywords ?? [] {
            let subKeys1 = keyword.split(separator: ",")
            for sk1 in subKeys1 {
                let subKeys2 = String(sk1).split(separator: " ")
                for sk2 in subKeys2 {
                    keys.append(String(sk2))
                }
            }
        }
        var matchs:[StockInfo] = []
        let info = csvData.fetchStocksInfo()
        for s in info {
            for key in keys {
                if s.id.contains(key) || s.name.contains(key) || s.group.contains(key) {
                    let matched = StockInfo.init(identifier: nil, display: String(s.id + " " + s.name))
                    matched.id = s.id
                    matched.name = s.name
                    matched.group = s.group
                    matched.proport1 = s.proport1
                    matched.dateStart = twDateTime.calendar.dateComponents([.year,.month,.day], from: s.dateStart)
                    matchs.append(matched)
                    break
                }
            }
        }
        let response = FindStocksIntentResponse.init(code: .success, userActivity: nil)
        response.stocks = matchs
        completion(response)
    }
}

class getTradesCSVIntentHandler:NSObject, GetTradesCSVIntentHandling {
    func handle(intent: GetTradesCSVIntent, completion: @escaping (GetTradesCSVIntentResponse) -> Void) {
        var stocksInfo:csvData.StocksInfo = []
        if let stocks = intent.stocks {
            for s in stocks {
                var dateStart:Date {
                    if let d = s.dateStart {
                        return twDateTime.calendar.date(from: d) ?? Date.distantFuture
                    } else {
                        return Date.distantFuture
                    }
                }
                stocksInfo.append((s.id ?? "", s.name ?? "", s.group ?? "", s.proport1 ?? "", dateStart))
            }
        }
        let start:Date? = (intent.inToday as! Bool ? twDateTime.startOfDay() : nil)
        let combine:Bool = (intent.combine as! Bool ? true : false)
        let response = GetTradesCSVIntentResponse.init(code: .success, userActivity: nil)
        var files:[INFile] = []
        if combine {
            let csvText = csvData.csvTrans(stocksInfo, start: start)
            if let csvFile = csvData.csvToFile(csvText) {
                files.append(INFile(fileURL: csvFile, filename: nil, typeIdentifier: nil))
            }
        } else {
            for s in stocksInfo {
                let csvText = csvData.csvTrans([s], start: start)
                if let csvFile = csvData.csvToFile(csvText) {
                    files.append(INFile(fileURL: csvFile, filename: nil, typeIdentifier: nil))
                }
            }
        }
        response.trans = files
        completion(response)
    }
}


