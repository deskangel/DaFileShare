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
    @IBOutlet weak var qrImage: NSImageView!
    @IBOutlet weak var clientCount: NSTextField!
    
    @IBAction func donateMenuItemSelected(_ sender: Any) {
        let paypalUrl = URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=william%2exue%40gmail%2ecom&no_shipping=0&no_note=1&tax=0&currency_code=USD&lc=C2&bn=PP%2dDonationsBF&charset=UTF%2d8")!
        NSWorkspace.shared.open(paypalUrl)
    }
    
    public var task: Process = Process()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! DragDestinationView
        view.delegate = self
        
        initFileWeb()
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
    
    func initFileWeb() {
        serverUrl.isBordered = false
        serverUrl.isHidden = true
        btnCopy.isHidden = true
        btnCancel.isHidden = true
        clientCount.isHidden = true
    }
    
    func onFileWebDone() {
        self.serverUrl.stringValue = ""
        self.serverUrl.isHidden = true
        self.btnCopy.isHidden = true
        self.btnCancel.isHidden = true
        self.clientCount.isHidden = true
        self.promptLabel.stringValue = "Drop file here"
        self.qrImage.image = nil
    }
    
    func onFileWebGoing(url:String, count:String) {
        if (!url.isEmpty) {
            self.serverUrl.stringValue = url
            self.serverUrl.textColor = NSColor.white
            self.serverUrl.isHidden = false
            self.btnCopy.isHidden = false
            self.btnCancel.isHidden = false
            self.promptLabel.stringValue = "Sharing..."
            self.qrImage.image = self.createQRImage(content: url)
        }
        
        self.clientCount.isHidden = false
        self.clientCount.stringValue = count        
    }
    
    func onFileWebError(message:String) {
        self.promptLabel.stringValue = "Drop file here"
        self.qrImage.image = nil
        self.btnCopy.isHidden = true
        self.btnCancel.isHidden = true
        self.clientCount.isHidden = true
        
        if message.isEmpty {
            self.serverUrl.stringValue = ""
            self.serverUrl.isHidden = true
        } else {
            self.serverUrl.stringValue = message
            self.serverUrl.isHidden = false
            
            self.serverUrl.textColor = NSColor.red
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
            
            DispatchQueue.main.async(execute: {
                self.onFileWebDone()
            })

        } else {
            print("error")
            var message: String = ""
            switch status {
            case 1:
                message = "error: no path specified"
                break
            case 2:
                message = "error: path not supported"
                break
            case 3:
                message = "error: failed to retrieve ip address"
                break
            case 4:
                message = "error: failed to share the file"
                break
            default:
                break
            }
            DispatchQueue.main.async(execute: {
                self.onFileWebError(message: message);

            })
        }
        
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
                                                        let count = self.extractClientCount(content: outputString)
                                                        self.onFileWebGoing(url: url, count: count)
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
    
    func extractClientCount(content: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: "client count: [0-9]*")
            let results = regex.matches(in: content,
                                        range: NSRange(content.startIndex..., in: content))
            
            if results.last == nil {
                return "client count: 0"
            }
            
            return String(content[Range(results.last!.range, in: content)!])
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return "error"
        }
    }
    
    func generateOrgQRImage(content: String) -> CIImage? {
        let data = content.data(using: .utf8)
        
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        guard qrFilter != nil else {
            return nil
        }
        
        qrFilter!.setValue(data, forKey: "inputMessage")
        
        qrFilter!.setValue("H", forKey: "inputCorrectionLevel")
        
        return qrFilter!.outputImage
    }
    
    func createQRImage(content: String, size: NSSize = NSSize(width: 200, height: 200)) -> NSImage? {
        guard let originImage = generateOrgQRImage(content: content) else {
            return nil
        }
        
        let colorFilter = CIFilter(name: "CIFalseColor")
        
        colorFilter!.setValue(originImage, forKey: "inputImage")
        
        colorFilter!.setValue(CIColor.black, forKey: "inputColor0")
        colorFilter!.setValue(CIColor.white, forKey: "inputColor1")
        
        guard let colorImage = colorFilter?.outputImage?.transformed(by: CGAffineTransform(scaleX: size.width/originImage.extent.width, y: size.height/originImage.extent.height)) else {
            fatalError("failed to generate the colorImage")
        }
        
        let image = NSImage(cgImage: convertCIImageToCGImage(inputImage: colorImage)!, size: size)
        
//        if let fillImage = fillImage {
//            let fillRect = CGRect(x: (size.width - size.width/4)/2, y: (size.height - size.height/4)/2, width: size.width/4, height: size.height/4)
//            image.lockFocus()
//            fillImage.draw(in: fillRect)
//            image.unlockFocus()
//        }
        
        return image
        
    }
    
    private func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
}

