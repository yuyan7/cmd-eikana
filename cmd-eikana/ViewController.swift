//
//  ViewController.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var showIcon: NSButton!
    @IBOutlet weak var launchAtStartup: NSButton!
    @IBOutlet weak var checkUpdateAtLaunch: NSButton!
    @IBOutlet weak var updateButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let showIconState = userDefaults.object(forKey: "showIcon")
        showIcon.state = NSControl.StateValue(rawValue: (showIconState as? Int) ?? 1)
        
        if #available(OSX 10.12, *) {
        } else {
            showIcon.title += "（macOS Sierraのみ）"
            showIcon.isEnabled = false
        }
        
        launchAtStartup.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "launchAtStartup"))
        checkUpdateAtLaunch.state = NSControl.StateValue(rawValue: userDefaults.integer(forKey: "checkUpdateAtLaunch"))
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @available(OSX 10.12, *)
    @IBAction func clickShowIcon(_ sender: AnyObject) {
        AppState.shared.setStatusItemVisible(showIcon.state == NSControl.StateValue.on)
        userDefaults.set(showIcon.state, forKey: "showIcon")
    }
    @IBAction func clickLaunchAtStartup(_ sender: AnyObject) {
        setLaunchAtStartup(launchAtStartup.state == NSControl.StateValue.on)
        userDefaults.set(launchAtStartup.state, forKey: "launchAtStartup")
    }
    @IBAction func clickCheckUpdateAtLaunch(_ sender: AnyObject) {
        userDefaults.set(checkUpdateAtLaunch.state, forKey: "checkUpdateAtLaunch")
    }
    @IBAction func test(_ sender: Any) {
        
    }
    
    @IBAction func checkUpdateButton(_ sender: AnyObject) {
        updateButton.isEnabled = false
        checkUpdate({ [weak self] (isNewVer: Bool?) -> Void in
            guard let self = self else { return }
            self.updateButton.isEnabled = true
            if isNewVer == nil {
                let alert = NSAlert()
                
                alert.messageText = "通信に失敗しました"
                alert.informativeText = "時間をおいて試してください"
                
                alert.runModal()
            }
            else if isNewVer == false {
                let alert = NSAlert()
                
                alert.messageText = "最新バージョンです"
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                alert.informativeText = "ver.\(version)"
                
                alert.runModal()
            }
        })
    }
}
