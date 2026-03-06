//
//  ExclusionAppsController.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class ExclusionAppsController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ExclusionAppsController.tableReload),
                                               name: NSApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return AppState.shared.exclusionAppsList.count + AppState.shared.activeAppsList.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let id = tableColumn!.identifier
        
        let isExclusion =  row < AppState.shared.exclusionAppsList.count
        
        if id.rawValue == "checkbox" {
            return isExclusion
        }
        
        let value = isExclusion ? AppState.shared.exclusionAppsList[row] : AppState.shared.activeAppsList[row - AppState.shared.exclusionAppsList.count]
        
        if id.rawValue == "appName" {
            return value.name
        }
        if id.rawValue == "appId" {
            return value.id
        }
        
        return nil
    }
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let id = tableColumn!.identifier
        let isExclusion =  row < AppState.shared.exclusionAppsList.count
        
        if id != NSUserInterfaceItemIdentifier(rawValue: "checkbox") {
            return
        }
        
        if isExclusion {
            let item = AppState.shared.exclusionAppsList.remove(at: row)
            AppState.shared.activeAppsList.insert(item, at: 0)
        }
        else {
            let item = AppState.shared.activeAppsList.remove(at: row - AppState.shared.exclusionAppsList.count)
            AppState.shared.exclusionAppsList.append(item)
        }
        
        AppState.shared.rebuildExclusionAppsDict()
        
        tableReload()
        AppState.shared.saveExclusionApps()
    }
    
    @objc func tableReload() {
        tableView.reloadData()
    }
}
