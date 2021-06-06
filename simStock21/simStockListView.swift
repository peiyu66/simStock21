//
//  simStockListView.swift
//  simStock21
//
//  Created by peiyu on 2020/6/24.
//  Copyright © 2020 peiyu. All rights reserved.
//  

import SwiftUI

struct simStockListView: View {
    @Environment(\.horizontalSizeClass) var hClass
    @StateObject var list: simStockList
    @State var isChoosing = false           //進入了選取模式
    @State var isSearching:Bool = false     //進入了搜尋模式
    @State var checkedStocks: [Stock] = []  //已選取的股票們
    @State var editText:String = ""       //輸入的搜尋文字

    func sectionHeader(_ stocks:[Stock]) -> some View {
        HStack {
            if isChoosing {
                groupCheckbox(stocks: stocks, checkedStocks: self.$checkedStocks)
            }
            Text((stocks[0].group == "" ? "<搜尋結果>" : "[\(stocks[0].group)]"))
                .font(.headline)
        }
    }
    
    func sectionFooter(_ stocks:[Stock]) -> some View {
        Text(list.stocksSummary(stocks))
    }

    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                if !list.doubleColumn(hClass) {
                    Spacer()
                    SearchBar(editText: self.$editText, searchText: $list.searchText, isSearching: self.$isSearching)
                        .disabled(self.isChoosing || list.isRunning)
                    HStack(alignment: .bottom){
                        if self.isSearching && list.searchText != nil && !self.list.searchGotResults {
                            if list.searchTextInGroup {
                                Text("\(list.searchText?[0] ?? "搜尋的股票")已在股群中。")
                                    .foregroundColor(.orange)
                            } else {
                                Text("查無符合者，試以部分的代號或簡稱來查詢？")
                                    .foregroundColor(.orange)
                            }
                            Button("[知道了]") {
                                self.editText = ""
                                self.list.searchText = nil
                                self.isSearching = false
                            }
                        }
                    }
                        .font(.footnote)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                ScrollViewReader { sv in
                    List {
                        ForEach(list.groupStocks, id: \.self) { (stocks:[Stock]) in
                            Section(header: sectionHeader(stocks),footer: sectionFooter(stocks)) {
                                ForEach(stocks, id: \.self) { (stock:Stock) in
                                    stockCell(stock: stock, isChoosing: self.$isChoosing, isSearching: self.$isSearching, checkedStocks: self.$checkedStocks)
                                }
                                .onDelete(perform: { indexSet in
                                    let s = indexSet.map{stocks[$0]}
                                    self.list.moveStocks(s)
                                })
                                .deleteDisabled(isSearching || isChoosing || list.isRunning)
                            }
                        }
                    }
                    .listStyle(GroupedListStyle())
                    .onChange(of: isSearching) {_ in
                        sv.scrollTo(list.groupStocks[0])
                    }
                }   //ScrollViewReader
            }   //VStack
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: chooseCommand(isChoosing: self.$isChoosing, isSearching: self.$isSearching, checkedStocks: self.$checkedStocks, searchText: self.$editText), trailing: listTools(isChoosing: self.$isChoosing, isSearching: self.$isSearching, checkedStocks: self.$checkedStocks, searchText: self.$editText))
        }   //NavigationView
        .navigationViewSwitch(list.doubleColumn(hClass))
        .environmentObject(list)
    }   //body
}

extension View {
    func navigationViewSwitch(_ doubleColumn:Bool) -> AnyView {
        if doubleColumn {
            return AnyView(self.navigationViewStyle(DoubleColumnNavigationViewStyle()))
        } else {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        }
    }
}

struct logForm: View {
    @Binding var showLog: Bool

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                let logArray:[String] = simLog.logReportArray()
                let end:Int = logArray.count - 1
                LazyVStack(alignment: .leading) {
                    ForEach(0..<end, id:\.self) { i in
                        Text(logArray[i])
                    }
                        .font(.footnote)
                        .lineLimit(nil)
                }
                    .frame(alignment: .topLeading)
                    .padding()
            }
                .navigationBarTitle("Log")
                .navigationBarItems(trailing: cancel)
                .padding()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    
    var cancel: some View {
        Button("關閉") {
            self.showLog = false
        }
    }
}

struct listTools:View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var isChoosing:Bool            //進入了選取模式
    @Binding var isSearching:Bool           //進入了搜尋模式
    @Binding var checkedStocks: [Stock]     //已選取的股票們
    @Binding var searchText:String          //輸入的搜尋文字
    @State var showLog:Bool = false         //顯示log
    @State var showSetting:Bool = false
    @State var showInformation:Bool = false

    private func openUrl(_ url:String) {
        if let URL = URL(string: url) {
            if UIApplication.shared.canOpenURL(URL) {
                UIApplication.shared.open(URL, options:[:], completionHandler: nil)
            }
        }
    }

    var body: some View {
        HStack {
            Spacer()
            if isChoosing {
                Button("取消" + (list.widthClass(hClass).rawValue > 1 ? "選取模式" : "")) {
                    self.isChoosing = false
                    self.checkedStocks = []
                }
                .frame(minWidth: 80, alignment: .trailing)
            } else if self.list.searchGotResults {
                Button("放棄" + (list.widthClass(hClass).rawValue > 1 ? "搜尋結果" : "")) {
                    self.searchText = ""
                    self.list.searchText = nil
                    self.isSearching = false
                    self.isChoosing = false
                    self.checkedStocks = []
                }
                .frame(minWidth: 80, alignment: .trailing)
            } else if self.isSearching || self.list.isRunning {
                EmptyView()
            } else if !list.doubleColumn {
                Group {
                    Button(action: {self.showLog = true}) {
                        Image(systemName: "doc.text")
                    }
                    .padding(.trailing, list.widthCG(hClass, CG: [2,8]))
                    .sheet(isPresented: $showLog) {
                        logForm(showLog: self.$showLog)
                    }
                    Spacer()
                    Button(action: {self.showSetting = true}) {
                        Image(systemName: "wrench")
                    }
                    .sheet(isPresented: $showSetting) {
                        listSettingForm(showSetting: self.$showSetting, dateStart: self.list.simDefaults.start, moneyBase: self.list.simDefaults.money, autoInvest: self.list.simDefaults.invest)
                    }
                    .environmentObject(list)
                    Spacer()
                    Button(action: {self.showInformation = true}) {
                        Image(systemName: "questionmark.circle")
                    }
                    .actionSheet(isPresented: $showInformation) {
                        ActionSheet(title: Text("參考訊息"), message: Text("小確幸v\(list.versionNow)"),
                        buttons: [
                            .default(Text("小確幸網站")) {
                                self.openUrl("https://peiyu66.github.io/simStock21/")
                            },
                            .destructive(Text("沒事，不用了。"))
                        ])
                    }
                }
            }
        }   //HStack
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }   //body
}

struct chooseCommand:View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var isChoosing:Bool            //進入了選取模式
    @Binding var isSearching:Bool           //進入了搜尋模式
    @Binding var checkedStocks: [Stock]     //已選取的股票們
    @Binding var searchText:String          //輸入的搜尋文字
    @State var showFilter:Bool = false      //顯示pickerGroups

    var body: some View {
            HStack {
//                if !list.doubleColumn {
//                    Image(systemName: list.classIcon[list.widthClass(hClass).rawValue])
//                        .foregroundColor(isSearching || isChoosing ? Color(.darkGray) : .gray)
//                        .rotation3DEffect(.degrees(list.rotated.d), axis: (x: list.rotated.x, y: list.rotated.y, z: 0))
//                }
                if self.isChoosing || self.list.searchGotResults {
                    Text(list.widthClass(hClass).rawValue > 1 ? "請勾選" : "勾選")
                        .foregroundColor(Color(.darkGray))
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .padding(0)
                    if self.checkedStocks.count > 0 {
                        stockActionMenu(isChoosing: self.$isChoosing, isSearching: self.$isSearching, checkedStocks: self.$checkedStocks, searchText: self.$searchText)
                    } else {
                        Button("全選") {
                            for stocks in self.list.groupStocks {
                                if let s = stocks.first, (s.group == "" || !self.list.searchGotResults) {
                                    for stock in stocks {
                                        self.checkedStocks.append(stock)
                                    }
                                }
                            }
                        }
                    }
                } else if !self.isSearching {
                    if list.isRunning {
                        if !list.doubleColumn {
                            runningMsg()
                        }
                    } else {
                        Button("選取") {
                            self.isChoosing = true
                            self.searchText = ""
                            self.list.searchText = nil
                            self.isSearching = false
                        }
                    }
                }
                Spacer()
//                Text("\(UIScreen.main.bounds.width)")
            }   //HStack
            .frame(minWidth: list.widthCG(hClass, CG: [250,250,450,450,200]), alignment: .leading)  //太寬會造成旋轉後位移
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }

}

struct stockActionMenu:View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var isChoosing:Bool            //進入了選取模式
    @Binding var isSearching:Bool           //進入了搜尋模式
    @Binding var checkedStocks: [Stock]     //已選取的股票們
    @Binding var searchText:String          //輸入的搜尋文字
    
    @State var shareText:String = ""        //要匯出的文字內容
    @State var showGroupMenu:Bool = false
    @State var showGroupFilter:Bool = false //顯示pickerGroups
    @State var showExport:Bool = false      //顯示匯出選單
    @State var showShare:Bool = false       //分享代號簡稱
    @State var deleteAll:Bool = false
    @State var showDeleteAlert:Bool = false
    @State var showMoveAlert:Bool = false
    @State var showReload:Bool = false

    private func isChoosingOff() {
        self.isSearching = false
        self.isChoosing = false
        self.checkedStocks = []
    }

    var body: some View {
        HStack {
            if self.list.searchGotResults {
                Button("加入" + (self.list.widthClass(hClass).rawValue > 1 ? "股群" : "")) {
                    self.showGroupFilter = true
                }
                .sheet(isPresented: self.$showGroupFilter) {
                    pickerGroups(checkedStocks: self.$checkedStocks, isChoosing: self.$isChoosing, isSearching: self.$isSearching, isMoving: self.$isChoosing, isPresented: self.$showGroupFilter, searchText: self.$searchText, newGroup: list.newGroupName)
                    }
                    .environmentObject(list)
            }
            if isChoosing {
                Button("股群" + (self.list.widthClass(hClass).rawValue > 1 ? "組成" : "")) {
                    self.showGroupMenu = true
                }
                .actionSheet(isPresented: self.$showGroupMenu) {
                        ActionSheet(title: Text("加入或移除股群"), message: Text("組成股群的行動？"), buttons: [
                            .default(Text("自股群移除")) {
                                self.showMoveAlert = true
                            },
                            .default(Text("+ 加入股群")) {
                                self.showGroupFilter = true
                            },
                            .destructive(Text("沒事，不用了。")) {
                                self.isChoosingOff()
                            }
                        ])
                    }
                .alert(isPresented: self.$showMoveAlert) {
                        Alert(title: Text("自股群移除"), message: Text("移除不會刪去歷史價，\n只不再更新、計算或復驗。"), primaryButton: .default(Text("移除"), action: {
                            self.list.moveStocks(self.checkedStocks)
                            self.isChoosingOff()
                        }), secondaryButton: .default(Text("取消"), action: {self.isChoosingOff()}))
                    }
                .sheet(isPresented: self.$showGroupFilter) {
                    pickerGroups(checkedStocks: self.$checkedStocks, isChoosing: self.$isChoosing, isSearching: self.$isSearching, isMoving: self.$isChoosing, isPresented: self.$showGroupFilter, searchText: self.$searchText, newGroup: list.newGroupName)
                    }
                    .environmentObject(list)
                Divider()
                Button((self.list.widthClass(hClass).rawValue > 1 ? "刪除或" : "") + "重算") {
                    self.showReload = true
                }
                .actionSheet(isPresented: self.$showReload) {
                        ActionSheet(title: Text("刪除或重算"), message: Text("內容和範圍？"), buttons: [
                            .default(Text("重算模擬")) {
                                self.list.reloadNow(self.checkedStocks, action: .simResetAll)
                                self.isChoosingOff()
                            },
                            .default(Text("重算技術數值")) {
                                self.list.reloadNow(self.checkedStocks, action: .tUpdateAll)
                                self.isChoosingOff()
                            },
                            .default(Text("刪除最後1個月")) {
                                self.deleteAll = false
                                self.showDeleteAlert = true
                            },
                            .default(Text("刪除全部")) {
                                self.deleteAll  = true
                                self.showDeleteAlert = true
                            },
//                            .default(Text("[TWSE復驗]")) {
//                                self.list.reviseWithTWSE(self.checkedStocks)
//                                self.isChoosingOff()
//                            },
                            .destructive(Text("沒事，不用了。")) {
                                self.isChoosingOff()
                            }
                        ])
                    }
                .alert(isPresented: self.$showDeleteAlert) {
                    Alert(title: Text("刪除\(deleteAll ? "全部" : "最後1個月")歷史價"), message: Text("刪除歷史價，再重新下載、計算。"), primaryButton: .default(Text("刪除"), action: {
                            self.list.deleteTrades(self.checkedStocks, oneMonth: !deleteAll)
                            self.isChoosingOff()
                        }), secondaryButton: .default(Text("取消"), action: {self.isChoosingOff()}))
                    }
                if !list.doubleColumn {
                    Divider()
                    Button("匯出" + (self.list.widthClass(hClass).rawValue > 1 ? "CSV" : "")) {
                        self.showExport = true
                    }
                    .actionSheet(isPresented: self.$showExport) {
                            ActionSheet(title: Text("匯出"), message: Text("文字內容？"), buttons: [
                                .default(Text("代號和名稱")) {
                                    self.shareText = csvData.csvStocksIdName(self.checkedStocks)
                                    self.showShare = true
                                },
                                .default(Text("逐月已實現" + (self.list.widthClass(hClass).rawValue > 0 ? "損益" : ""))) {
                                    self.shareText = csvData.csvMonthlyRoi(self.checkedStocks)
                                    self.showShare = true
                                },
                                .destructive(Text("沒事，不用了。")) {
                                    self.isChoosingOff()
                                }
                            ])
                        }
                        .sheet(isPresented: self.$showShare) {   //分享窗
                            ShareSheet(activityItems: [self.shareText]) { (activity, success, items, error) in
                                self.isChoosingOff()
                            }
                        }
                }
            }
        }
    }
}


struct pickerGroups:View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var checkedStocks: [Stock]
    @Binding var isChoosing:Bool            //進入了選取模式
    @Binding var isSearching:Bool           //進入了搜尋模式
    @Binding var isMoving:Bool
    @Binding var isPresented:Bool
    @Binding var searchText:String
    @State   var newGroup:String //= "股群_"
    @State   var groupPicked:String = "新增股群"
    
    func allOneGroup(_ group:String) -> Bool {  //選取的股都來自同股群，就別讓原股群被重複選為將要加入的股群
        for stock in checkedStocks {
            if stock.group != group  {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text((list.widthClass(hClass).rawValue > 0 ? "選取的股票要" : "") + "加入「新的股群」或「既有股群」？"), footer: Text(self.groupPicked == "新增股群" ? "加入新增的[\(self.newGroup)]。" : "加入[\(self.groupPicked)]。")) {
                    Group {
                        ForEach(self.list.groups, id: \.self) { (gName:String) in
                            HStack {
                                if self.groupPicked == gName {
                                    Image(systemName: "checkmark")
                                } else {
                                    Text("    ")
                                }
                                Text(gName)
                                    .onTapGesture {
                                        self.groupPicked = gName
                                    }
                            }
                            .foregroundColor(self.groupPicked == gName ? .red : (allOneGroup(gName) ? .gray : .primary))
                            .disabled(allOneGroup(gName))
                        }
                        HStack {
                            if self.groupPicked == "新增股群" {
                                Image(systemName: "checkmark")
                            } else {
                                Text("    ")
                            }
                            Text("新增股群")
                                .onTapGesture {
                                    self.groupPicked = "新增股群"
                                }
                            Group {
                                Spacer()
                                Text("：")
                                TextField("輸入股群名稱", text: self.$newGroup, onEditingChanged: { _ in    //began or end (bool)
                                    }, onCommit: {
                                    })
                                .frame(height: 40)
                                .padding([.leading, .trailing], 10)
                                .foregroundColor(Color(.darkGray))
                                .background(Color(.systemGray6))
                                .minimumScaleFactor(0.8)
                                .cornerRadius(8)
                                Spacer()
                            }
                            .disabled(self.groupPicked != "新增股群")
                            .foregroundColor(.primary)

                        }
                        .foregroundColor(self.groupPicked == "新增股群" ? .red : .primary)
                    }
                }
            }
            .navigationBarTitle("加入股群")
            .navigationBarItems(leading: cancel, trailing: done)

        }
            .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var cancel: some View {
        Button("取消") {
            self.isPresented = false
            self.isMoving = false
            self.searchText = ""
            self.list.searchText = nil
            self.checkedStocks = []            
            self.isChoosing = false
            self.isSearching = false
        }
    }
    var done: some View {
        Group {
            if self.groupPicked != "新增股群" || self.newGroup != "" {
                Button("確認") {
                    let toGroup:String = (self.groupPicked != "新增股群" ? self.groupPicked : self.newGroup)
                    self.list.moveStocks(self.checkedStocks, toGroup: toGroup)
                    self.isPresented = false
                    self.isMoving = false
                    self.searchText = ""
                    self.list.searchText = nil
                    self.checkedStocks = []
                    self.isChoosing = false
                    self.isSearching = false
                }
            }
        }
    }


}

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void

    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = [    //標為註解以排除可用的，留下不要的
                    .addToReadingList,
                    .airDrop,
                    .assignToContact,
    //                .copyToPasteboard,
    //                .mail,
    //                .markupAsPDF,   //iOS11之後才有
    //                .message,
                    .openInIBooks,
                    .postToFacebook,
                    .postToFlickr,
                    .postToTencentWeibo,
                    .postToTwitter,
                    .postToVimeo,
                    .postToWeibo,
                    .print,
                    .saveToCameraRoll]
    let callback: Callback

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
    
    static func dismantleUIViewController(_ uiViewController: Self.UIViewControllerType, coordinator: Self.Coordinator) {
    }
}

struct listSettingForm: View {
    @EnvironmentObject var list: simStockList
    @Binding var showSetting: Bool
    @State var dateStart:Date
    @State var moneyBase:Double
    @State var autoInvest:Double
    @State var applyToAll:Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新股預設").font(.title)) {
                    DatePicker(selection: $dateStart, in: (twDateTime.calendar.date(byAdding: .year, value: -15, to: Date()) ?? self.list.simDefaults.first)...(twDateTime.calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()), displayedComponents: .date) {
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
                Section(header: Text("股群設定").font(.title),footer: Text(self.list.simDefaults.text).font(.footnote)) {
                    Toggle("套用到全部股", isOn: $applyToAll)
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
                self.list.applySetting(dateStart: self.dateStart, moneyBase: self.moneyBase, autoInvest: self.autoInvest, applyToAll: self.applyToAll, saveToDefaults: true)
            }
            self.showSetting = false
        }
    }
    

    
}



















struct groupCheckbox: View {
    @State var isChecked:Bool = false
    @State var stocks : [Stock]
    @Binding var checkedStocks:[Stock]
    
    
    private func checkGroup() {
        self.isChecked = !self.isChecked
        if self.isChecked {
            self.checkedStocks += stocks
        } else {
            self.checkedStocks = self.checkedStocks.filter{!stocks.contains($0)}
        }
    }

    var body: some View {
        Group {
            Button(action: checkGroup) {
                Image(systemName: isChecked ? "checkmark.square" : "square")
            }
        }
    }
}


struct stockCell : View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @ObservedObject var stock : Stock
    @State private var stock0: Stock?
    @Binding var isChoosing:Bool
    @Binding var isSearching:Bool
    @Binding var checkedStocks:[Stock]
    @State   var prefix:String = ""
    
    private func checkStock() {
        if self.checkedStocks.contains(self.stock) {
            self.checkedStocks.removeAll(where: {$0 == stock})
        } else {
            self.checkedStocks.append(stock)
        }
    }
    
    var body: some View {
        HStack {
            if isChoosing || (isSearching && stock.group == "") {
                Button(action: checkStock) {
                    Image(systemName: self.checkedStocks.contains(self.stock) ? "checkmark.square" : "square")
                }
            }
            Group {
                Text(stock.sId)
                    .font(list.widthClass(hClass) == .compact ? .callout : .body)
                    .frame(width : (isSearching && stock.group == "" ? 80.0 : list.widthCG(hClass, CG: [40,60,80,80,50])), alignment: .leading)
                Text(stock.sName)
                    .frame(width : (isSearching && stock.group == "" ? 120.0 : list.widthCG(hClass, CG: [70,90,120,120,80])), alignment: .leading)
            }
                .lineLimit(2)
                .foregroundColor(list.isRunning ? .gray : .primary)
            if stock.group != "" {
                Group {
                    if let trade = stock.lastTrade(stock.context) {
                        lastTrade(stock: self.stock, trade: trade, isChoosing: self.$isChoosing, isSearching: self.$isSearching)
                    } else {
                        EmptyView()
                    }
                }
                if !isChoosing && !isSearching {
                    NavigationLink(destination: stockPageView(stock: stock, prefix: stock.prefix), tag: stock, selection: self.$stock0) {
                        EmptyView()
                    }
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundColor(self.checkedStocks.contains(stock) ? .orange : (isSearching && stock.group != "" ? .gray : .primary))
        .onAppear() {
            if list.doubleColumn {
                self.stock0 = list.groupStocks[0][0]
            }
        }
    }
}

struct lastTrade: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @ObservedObject var stock : Stock
    @ObservedObject var trade:Trade
    @Binding var isChoosing:Bool
    @Binding var isSearching:Bool
    

    var body: some View {
        HStack{
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
            .frame(width: list.widthCG(hClass, CG: [70,90,110,110,90]), alignment: .center)
            .foregroundColor(trade.color(.price, gray: (isChoosing || isSearching)))
            .background(RoundedRectangle(cornerRadius: 20).fill(trade.color(.ruleB, gray: (isChoosing || isSearching))))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(trade.color(.ruleR, gray: (isChoosing || isSearching)), lineWidth: 1)
            )
            if list.widthClass(hClass).rawValue > 0 {
                Text(trade.simQty.action)
                    .frame(width: list.widthCG(hClass, CG: [0,20,30]), alignment: .center)
                    .foregroundColor(trade.color(.qty, gray: (isChoosing || isSearching)))
                Text(trade.simQty.qty > 0 ? String(format:"%.f",trade.simQty.qty) : "")
                    .frame(width: list.widthCG(hClass, CG: [0,30,40]), alignment: .center)
                    .foregroundColor(trade.color(.qty, gray: (isChoosing || isSearching)))
                Text(String(format:"%.1f年",stock.years))
                    .frame(width: list.widthCG(hClass, CG: [0,40,65]), alignment: .trailing)
            }
            if trade.days > 0 {
                if list.widthClass(hClass).rawValue >= 0 {
                    Text(String(format:"%.f天",trade.days))
                        .foregroundColor(stock.simReversed ? .blue : .primary)
                        .frame(width: list.widthCG(hClass, CG: [40,50,65]), alignment: .trailing)
                    Text(String(format:"%.1f%%",trade.rollAmtRoi/stock.years))
                        .foregroundColor(stock.simInvestUser > 0 ? .blue : .primary)
                        .frame(width: list.widthCG(hClass, CG: [40,50,65]), alignment: .trailing)
                    if list.widthClass(hClass).rawValue > 0 {
                        Text(trade.baseRoi > 0 ? String(format:"%.1f%%",trade.baseRoi) : "")
                            .foregroundColor(.gray)
                            .frame(width: 65.0, alignment: .trailing)
                    }
                }
                trade.gradeIcon(gray:isChoosing || isSearching)
                    .frame(width:25, alignment: .trailing)
            } else {
                EmptyView()
            }
            Spacer()
        }   //HStack
        .font(list.widthClass(hClass) == .compact && !list.doubleColumn ? .footnote : .body)
        .foregroundColor(isChoosing || isSearching ? .gray : .primary)
    }
}




struct SearchBar: View {
    @Environment(\.horizontalSizeClass) var hClass
    @EnvironmentObject var list: simStockList
    @Binding var editText: String
    @Binding var searchText:[String]?
    @Binding var isSearching:Bool
    @State var isEditing:Bool = false
    
    var title:String {
        if list.widthClass(hClass).rawValue > 0 {
            return "以代號或簡稱來搜尋尚未加入股群的上市股票"
        } else {
            return "以代號或簡稱來搜尋上市股票"
        }
    }

    //來自： https://www.appcoda.com/swiftui-search-bar/
    var body: some View {
        HStack {
            TextField(title, text: $editText    /*, onEditingChanged: { editing in
                if !editing {
                    self.isEditing = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)  // Dismiss the keyboard
                }
            } */, onCommit: {
                self.searchText = self.editText.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "  ", with: " ").replacingOccurrences(of: "  ", with: " ").components(separatedBy: " ")
                self.isEditing = false
                self.isSearching = true
            })
                .padding(7)
                .padding(.horizontal, 25)
                .lineLimit(nil)
                .minimumScaleFactor(0.8)
                .background(Color(.systemGray6))
//                .keyboardType(.webSearch)
                .cornerRadius(8)
                .onTapGesture {
                    self.isEditing = true
                    self.isSearching = true
                }
                .overlay(
                   HStack {
                       Image(systemName: "magnifyingglass")
                           .foregroundColor(.gray)
                           .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                           .padding(.leading, 8)
                
                       if isEditing {
                            Button(action: {
                                self.editText = ""
                                self.searchText = nil
                                self.isSearching = true
                           })
                           {
                                Image(systemName: "multiply.circle.fill")
                                   .foregroundColor(.gray)
                                   .padding(.trailing, 8)
                           }
                       }
                   }
                )
                .padding(.horizontal, 10)
            if isEditing && isSearching {
                Button(action: {
                    self.isSearching = false
                    self.isEditing = false
                    self.editText = ""
                    self.searchText = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)  // Dismiss the keyboard
                })
                {
                    Text("取消")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}
