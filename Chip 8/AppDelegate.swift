//
//  AppDelegate.swift
//  Chip 8
//
//  Created by Neil Singh on 6/15/14.
//  Copyright (c) 2014 Neil Singh. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var window: NSWindow
    @IBOutlet var view: AnyObject

    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        window.makeFirstResponder(view as SwiftView)
        NSTimer.scheduledTimerWithTimeInterval(1 / 60.0, target: self, selector: Selector("updateView") , userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
        CPUDealloc()
    }
    
    func updateView() {
        if paused {
            return
        }
        
        if CPUExecute(17, view as SwiftView) {   // 17 = 1000 / 60
            view.setNeedsDisplayInRect(view.bounds)
        }
        
        if dt != 0 {
            dt--
        }
        if st != 0 {
        //    NSBeep()  // Disable for now (it's really annoying)
            st--
        }
    }
    
    @IBAction func openFile(sender: AnyObject) {
        var openPanel = NSOpenPanel()
        if openPanel.runModal() == 1 {
            var file = fopen(openPanel.filename().bridgeToObjectiveC().UTF8String, "r")
            if file {
                fseek(file, 0, SEEK_END)
                var size = Int(ftell(file))
                rewind(file)
                if size < 0xE00 {
                    CPUDealloc()
                    CPUInit()
                    (view as SwiftView).clearDisplay()
                    var buffer = UnsafePointer<u8>.alloc(size)
                    fread(buffer, 1, UInt(size), file)
                    for z in 0..size {
                        memory[0x200 + z] = buffer[z]
                    }
                    buffer.dealloc(size)
                    paused = false
                }
                fclose(file)
            }
        }
    }
}

