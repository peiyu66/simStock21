//
//  simDataRequest.swift
//  simStock21
//
//  Created by peiyu on 2020/7/11.
//  Copyright © 2020 peiyu. All rights reserved.
//

import UIKit
import BackgroundTasks

class backgroundRequest {
    
    private let technical:simTechnical = simTechnical()

    func reviseWithTWSE(_ stocks:[Stock], bgTask:BGTask?=nil) {
        var tasks = stocks

        var timeRemain:String {
            if bgTask != nil && UIApplication.shared.backgroundTimeRemaining < 500 {
                return String(format:"剩餘時間: %.3fs",UIApplication.shared.backgroundTimeRemaining)
            }
            return ""
        }

        if let task = bgTask {
            task.expirationHandler = { [self] in
                technical.continueTWSE = false
                simLog.addLog("BGTask expired. \(timeRemain)")
                task.setTaskCompleted(success: false)
            }
        }
        
        func submitBGTask() {
            if UIApplication.shared.backgroundTimeRemaining < 500 {
                let request = BGProcessingTaskRequest(identifier: "com.mystock.simStock21.BGTask")
                request.earliestBeginDate = Date(timeIntervalSinceNow: 320) //背景預留時間
                request.requiresNetworkConnectivity = true
                try? BGTaskScheduler.shared.submit(request)
                simLog.addLog("BGTask submitted again.")
            }
        }
        
        func requestTWSE(_ requestStocks:[Stock], bgTask:BGTask?=nil) {
            var requests = requestStocks
            let stockGroup:DispatchGroup = DispatchGroup()
            if let stock = requests.first {
                if let dateStart = stock.dateRequestTWSE  {
                    stockGroup.enter()
                    let progress = technical.progressTWSE ?? 0
                    let delay:Int = (progress % 5 == 0 ? 9 : 3) + (progress % 7 == 0 ? 3 : 0)
                    technical.progressTWSE = tasks.count - requests.count + 1
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(delay)) {
                        self.technical.twseRequest(stock: stock, dateStart: dateStart, stockGroup: stockGroup)
                    }
                    if dateStart == twDateTime.yesterday() {
                        requests.append(stock)  //復驗是到昨天，可能只有1筆，就再多排一次
                        tasks.append(stock)
                        technical.countTWSE = tasks.count
                    }
                } else {
//                    stockGroup.enter()
//                    stockGroup.leave()
                    simLog.addLog("TWSE \(stock.sId)\(stock.sName) 略。 繼續？\(technical.continueTWSE)")
                }
            }
            stockGroup.wait()
            if technical.continueTWSE {
                requests.removeFirst()
                if requests.count > 0 {
                    requestTWSE(requests, bgTask: bgTask)
                } else {
                    technical.progressTWSE = nil
                    simLog.addLog("TWSE(\(tasks.count))完成。 \(timeRemain)")
                    if let task = bgTask {
                        task.setTaskCompleted(success: true)
                    }
                }
            } else {
                simLog.addLog("TWSE(\(technical.progressTWSE ?? 0)/\(tasks.count))中斷！ \(timeRemain)")
                technical.continueTWSE = true
                technical.progressTWSE = nil
                if let task = bgTask {
                    task.setTaskCompleted(success: false)
                }
            }
        }
        
        requestTWSE(tasks)
    }
    

}
