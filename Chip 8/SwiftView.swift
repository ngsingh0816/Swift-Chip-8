//
//  SwiftView.swift
//  Chip8
//
//  Created by Neil Singh on 6/15/14.
//  Copyright (c) 2014 Neil Singh. All rights reserved.
//

import Cocoa

class SwiftView : NSView {
    
    var pixels = UnsafePointer<Bool>.alloc(64 * 32)
    
    init(coder: NSCoder!) {
        for z in 0..2048 {
            pixels[z] = false
        }
        super.init(coder: coder)
    }
    
    deinit {
        pixels.dealloc(64 * 32)
    }
    
    func togglePixel(xLoc: Int, yLoc: Int) {
        pixels[xLoc + (yLoc * 64)] = !pixels[xLoc + (yLoc * 64)]
    }
    
    func pixel(xLoc: Int, yLoc: Int) -> Bool {
        return pixels[xLoc + (yLoc * 64)]
    }
    
    func clearDisplay() {
        for z in 0..2048 {
            pixels[z] = false
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        self.lockFocusIfCanDraw()
        // Clear to black
        NSColor.blackColor().set()
        NSBezierPath(rect: dirtyRect).fill()
        NSColor.whiteColor().set()
        
        for yVar in 0..32 {
            for xVar in 0..64 {
                if pixels[xVar + (yVar * 64)] {
                    NSBezierPath(rect: NSMakeRect(CGFloat(xVar) * bounds.width / 64, bounds.height - (CGFloat(yVar + 1) * bounds.height / 32), bounds.width / 64, bounds.width / 32)).fill()
                }
            }
        }
        self.unlockFocus()
    }
    
    // 1-9, a-f ASCII
    let keyNames = [ 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102 ];
    
    override func keyDown(theEvent: NSEvent!) {
        var key = Int(theEvent.characters.bridgeToObjectiveC().characterAtIndex(0))
        for z in 0..0x10 {
            if key == keyNames[z] {
                keys[z] = true
            }
        }
    }
    
    override func keyUp(theEvent: NSEvent!)  {
        var key = Int(theEvent.characters.bridgeToObjectiveC().characterAtIndex(0))
        for z in 0..0x10 {
            if key == keyNames[z] {
                keys[z] = false
            }
        }
    }
}