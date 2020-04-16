//
//  ViewController.swift
//  dafileshare
//
//  Created by William Xue on 4/14/20.
//  Copyright © 2020 Deskangel. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        self.view.delegate = self
        let view = self.view as! DragDestinationView
        view.delegate = self
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController: FileDragDelegate {
    func didFinishDrag(_ filePath: String) {
        let url = NSURL(fileURLWithPath: filePath)
        
        print(url)
    }
}

