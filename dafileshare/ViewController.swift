//
//  ViewController.swift
//  dafileshare
//
//  Created by William Xue on 4/14/20.
//  Copyright © 2020 Deskangel. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var serverUrl: NSTextField!
    @IBOutlet weak var btnCopy: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    @IBOutlet weak var promptLabel: NSTextField!
    
    public var task: Process = Process()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! DragDestinationView
        view.delegate = self
        
        serverUrl.isHidden = true
        btnCopy.isHidden = true
        btnCancel.isHidden = true
    }
    
    override func viewDidDisappear() {
//        print("viewDidDisappear")
        if self.task.isRunning {
            self.task.terminate()
         }
        super.viewDidDisappear()
    }
    
    @IBAction func onCopyButtonClicked(_ sender: Any) {
        let url = self.serverUrl.stringValue
        
        NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        NSPasteboard.general.setString(url, forType: NSPasteboard.PasteboardType.string)
    }
    
    @IBAction func onCancelButtonClicked(_ sender: Any) {
        if self.task.isRunning {
            self.task.terminate()
         }
    }
}

extension ViewController: FileDragDelegate {
    func didFinishDrag(_ filePath: String) {
        
        if (self.task.isRunning) {
            return
        }
        
//        runCommand(commandPath: "/usr/bin/killall", args: ["fileweb"])

        let appPath = Bundle.main.bundlePath;
        runCommandAsync(commandPath: "\(appPath)/Contents/MacOS/fileweb", args: [filePath], captureOutput: true)
    }
    
    func runCommand(commandPath:String, args: Array<String>, captureOutput: Bool = false) {
        self.task = Process()
        
        self.task.launchPath = commandPath;

        self.task.arguments = args;
        
        if (captureOutput) {
            self.captureStandarOutput(task: self.task)
        }

        self.task.launch()
        self.task.waitUntilExit()
        
        let status = self.task.terminationStatus
        if (status == 0) {
            print("done!!")
        } else {
            print("error")
        }
        
        DispatchQueue.main.async(execute: {
            self.serverUrl.stringValue = ""
            self.serverUrl.isHidden = true
            self.btnCopy.isHidden = true
            self.btnCancel.isHidden = true
            self.promptLabel.stringValue = "Drop file here"
        })
    }
    
    func runCommandAsync(commandPath:String, args: Array<String>, captureOutput: Bool = false) {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        
        taskQueue.async {
            self.runCommand(commandPath: commandPath, args: args, captureOutput: captureOutput)
        }
    }
    
    func captureStandarOutput(task: Process) {
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                                               object: outputPipe.fileHandleForReading, queue: nil,
                                               using: {(notification: Notification) in
                                                
                                                let output = outputPipe.fileHandleForReading.availableData
                                                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                                                if outputString != "" {
                                                    DispatchQueue.main.async(execute: {
                                                        print(">> " + outputString)
                                                        let url = self.extractUrl(content: outputString)
                                                        
                                                        if (!url.isEmpty) {
                                                            self.serverUrl.stringValue = url
                                                            self.serverUrl.isHidden = false
                                                            self.btnCopy.isHidden = false
                                                            self.btnCancel.isHidden = false
                                                            self.promptLabel.stringValue = "Sharing..."
                                                        }
                                                        
                                                        
                                                    })
                                                }
                                                
                                                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                                                
        })
    }
    
    func extractUrl(content: String) -> String {

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        
        if detector == nil {
            print("extractUrl error")
        }
        
        
        let matches = detector!.matches(in: content, options: .reportCompletion, range: NSMakeRange(0, content.count))
        
        for match in matches {
            return match.url!.absoluteString
        }
        
        return ""
    }
}

