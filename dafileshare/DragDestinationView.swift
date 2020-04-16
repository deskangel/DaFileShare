//
//  DragDestinationView.swift
//  dafileshare
//
//  Created by William Xue on 4/14/20.
//  Copyright © 2020 Deskangel. All rights reserved.
//

import Cocoa
protocol FileDragDelegate : class{
   
    func didFinishDrag(_ filePath:String)
    
}

class DragDestinationView: NSView {
    
    weak var delegate: FileDragDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let sourceDragMask = sender.draggingSourceOperationMask
        
        let pboard = sender.draggingPasteboard
        
        let dragTypes = pboard.types! as NSArray
        if dragTypes.contains(NSPasteboard.PasteboardType.fileURL) {
            if sourceDragMask.contains([.link]) {
                return .link
            }
            
            if sourceDragMask.contains([.copy]) {
                return .copy
            }
        }
        
        return .generic
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        let dragTypes = pboard.types! as NSArray
        if dragTypes.contains(NSPasteboard.PasteboardType.fileURL) {
            let files = pboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as! [String]
            let numberOfFiles = files.count
            if numberOfFiles > 0 {
                let filePath = files[0] as String
                if let delegate = self.delegate {
                    NSLog("file path \(filePath)")
                    delegate.didFinishDrag(filePath)
                }
            }
        }
        
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
