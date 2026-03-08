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
        return AppState.shared.combinedAppCount()
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let id = tableColumn!.identifier
        
        guard let item = AppState.shared.combinedApp(at: row) else { return nil }
        let isExclusion = item.isExcluded
        let value = item.app

        if id.rawValue == "checkbox" {
            return isExclusion
        }
        
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
        
        if id != NSUserInterfaceItemIdentifier(rawValue: "checkbox") {
            return
        }

        AppState.shared.toggleExcludedApp(at: row)
        
        tableReload()
        AppState.shared.saveExcludedApps()
    }
    
    @objc func tableReload() {
        tableView.reloadData()
    }
}
