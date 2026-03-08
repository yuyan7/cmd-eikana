//
//  ShortcutsController.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

class ShortcutsController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func mouseDown(with event: NSEvent) {
        AppState.shared.blurFocusedKeyField()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return AppState.shared.keyMappingCount()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let id = tableColumn?.identifier else { return nil }

        if let cell = tableView.makeView(withIdentifier: id, owner: nil) as? NSTableCellView {
            if id.rawValue == "input" || id.rawValue == "output" {
                guard let keyMapping = AppState.shared.keyMapping(at: row) else { return cell }
                let value = id.rawValue == "input" ? keyMapping.input : keyMapping.output
                
                guard let textField = cell.subviews[0] as? KeyTextField else { return cell }
                
                textField.stringValue = value.toString()
                textField.shortcut = value
                textField.saveAddress = (row: row, id: id.rawValue)
                textField.isAllowModifierOnly = id.rawValue == "input"
            }
            if id.rawValue == "mapping-menu" {
                guard let button = cell.subviews[0] as? MappingMenu else { return cell }
                
                button.row = row
                
                button.target = self
                button.action = #selector(ShortcutsController.remove(_:))
            }
        
            return cell
        }
        return nil
    }
    @objc func remove(_ sender: MappingMenu) {
        AppState.shared.blurFocusedKeyField()
        
        switch sender.selectedItem!.title {
        case "この項目を削除", "remove":
            sender.remove()
            break
        case "最上部に移動", "move to the top":
            sender.move(0)
            break
        case "1つ上に移動", "move one up":
            sender.move(sender.row! - 1)
            break
        case "1つ下に移動", "move one down":
            sender.move(sender.row! + 1)
            break
        case "最下部に移動", "move to bottom":
            sender.move(AppState.shared.keyMappingCount() - 1)
            break
        default:
            break
        }
        
        tableReload()
    }
    
    func tableReload() {
        tableView.reloadData()
        AppState.shared.saveKeyMappings()
    }
    
    @IBAction func quit(_ sender: AnyObject) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func addRow(_ sender: AnyObject) {
        AppState.shared.addKeyMapping(KeyMapping())
        tableReload()
    }
}
