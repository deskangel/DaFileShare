//
//  ViewController.swift
//  dafileshare
//
//  Created by William Xue on 4/14/20.
//  Copyright © 2020 Deskangel. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    let task = Process()
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.view.delegate = self
        let view = self.view as! DragDestinationView
        view.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear() {
        if task.isRunning {
            task.terminate()
        }
       
        super.viewDidDisappear()
        
        print("exit")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController: FileDragDelegate {
    func didFinishDrag(_ filePath: String) {

        runCommand(filePath: filePath)
    }
    
    func runCommand(filePath: String) {
        let taskQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        
        taskQueue.async {
            let appPath = Bundle.main.bundlePath;
            
         
            self.task.launchPath = "\(appPath)/Contents/MacOS/fileweb";

            self.task.arguments = [filePath];
            
            self.captureStandarOutput(task: self.task)
            
            self.task.launch()
            self.task.waitUntilExit()
            
            let status = self.task.terminationStatus
            if (status == 0) {
                print("done!!")
            } else {
                print("error")
            }
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
                                                    })
                                                }
                                                
                                                outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                                                
        })
    }
}

