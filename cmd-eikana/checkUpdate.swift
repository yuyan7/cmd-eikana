//
//  checkUpdate.swift
//  ⌘英かな
//
//  MIT License
//  Copyright (c) 2016 iMasanari
//

import Cocoa

func checkUpdate(_ callback: ((_ isNewVer: Bool?) -> Void)? = nil) {
    let url = URL(string: "https://api.github.com/repos/yuyan7/cmd-eikana/releases/latest")!
    let request = URLRequest(url: url)
    
    let handler = { (data:Data?, res:URLResponse?, error:Error?) -> Void in
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        var newVersion = ""
        var description = ""
        var releaseUrl = "https://github.com/yuyan7/cmd-eikana/releases"
        
        do {
            if let data = data,
               let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                // GitHub APIからタグ名を取得（例: "v2.2.3-arm" -> "2.2.3"）
                if let tagName = json["tag_name"] as? String {
                    // "v"プレフィックスを除去し、"-arm"や"-intel"などのサフィックスも除去
                    let versionPart = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                    if let hyphenIndex = versionPart.firstIndex(of: "-") {
                        newVersion = String(versionPart[..<hyphenIndex])
                    } else {
                        newVersion = versionPart
                    }
                }
                description = json["body"] as? String ?? ""
                
                if let htmlUrl = json["html_url"] as? String {
                    releaseUrl = htmlUrl
                }
            }
        } catch let error as NSError {
            print(error.debugDescription)
            return;
        }
        
        let isAbleUpdate: Bool? = (newVersion == "") ? nil : newVersion != version
        
        if isAbleUpdate == true {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "⌘英かな ver.\(newVersion) が利用可能です"
                alert.informativeText = description
                alert.addButton(withTitle: "Download")
                alert.addButton(withTitle: "Cancel")
                // alert.showsSuppressionButton = true;
                let ret = alert.runModal()
                
                if (ret == NSApplication.ModalResponse.alertFirstButtonReturn) {
                    NSWorkspace.shared.open(URL(string: releaseUrl)!)
                }
            }
        }
        
        if let callback = callback {
            DispatchQueue.main.async {
                callback(isAbleUpdate)
            }
        }
    }
    
    //NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main, completionHandler: handler)
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    let task = session.dataTask(with: request, completionHandler: handler)
    task.resume()
}
