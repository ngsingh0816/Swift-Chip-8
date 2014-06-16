//
//  CPU.swift
//  Chip8
//
//  Created by Neil Singh on 6/15/14.
//  Copyright (c) 2014 Neil Singh. All rights reserved.
//

import Foundation

typealias u8 = UInt8
typealias u16 = UInt16
typealias u32 = UInt32
typealias s8 = Int8
typealias s16 = Int16
typealias s32 = Int32

var memory = UnsafePointer<u8>.null()
var pc: u16 = 0x0
var regs = Array<u8>(count:0x10, repeatedValue:0)
var sp: u8 = 0x0
var dt: u8 = 0x0
var st: u8 = 0x0
var I: u16 = 0x0
var keys = Array<Bool>(count:0x10, repeatedValue:false)
var paused = true
var stack = Array<u16>(count:0x10, repeatedValue:0)

let sprites: Array<u8> = [ 0xF0, 0x90, 0x90, 0x90, 0xF0,	// 0
    0x20, 0x60, 0x20, 0x20, 0x70,	// 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,	// 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,	// 3
    0x90, 0x90, 0xF0, 0x10, 0x10,	// 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,	// 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,	// 6
    0xF0, 0x10, 0x20, 0x40, 0x40,	// 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,	// 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,	// 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,	// A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,	// B
    0xF0, 0x80, 0x80, 0x80, 0xF0,	// C
    0xE0, 0x90, 0x90, 0x90, 0xE0,	// D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,	// E
    0xF0, 0x80, 0xF0, 0x80, 0x80,	// F
]

func CPUInit() {
    
    memory = UnsafePointer<u8>.alloc(0x1000)
    
    for z in 0..0x50 {
        memory[z] = sprites[z]
    }
    for z in 0x50..0x1000 {
        memory[z] = 0
    }
    
    pc = 0x200
    sp = 0x0
    for z in 0..0x10 {
        regs[z] = 0
        keys[z] = false
    }
    dt = 0x0
    st = 0x0
    I = 0x0
}

func CPUDealloc() {
    
    if memory {
        memory.dealloc(0x1000)
        memory = UnsafePointer<u8>.null()
    }
}

func CPUExecute(cycles: Int, view: SwiftView) -> Bool {
    
    var cy = cycles
    let rect = view.bounds
    var ret = false
    while cy > 0 {
        
        let highByte: u16 = u16(memory[Int(pc)])
        let lowByte: u16 = u16(memory[Int(pc + 1)])
        pc += 2
        let opcode = lowByte | (highByte << 8)
        let addr = opcode & 0xFFF
        let n = opcode & 0xF
        let x = Int(highByte & 0xF)
        let highNib = (highByte >> 4) & 0xF
        let y = Int((lowByte >> 4) & 0xF)
        let kk = u8(lowByte)
        
        if highByte == 0 {
            // CLS
            if lowByte == 0xE0 {
                view.clearDisplay()
                ret = true
            }
            else if lowByte == 0xEE {   // Ret
                var tempSP = Int(sp--)
                pc = stack[tempSP]
            }
        }
        else if highNib == 0x1 {    // JMP
            pc = addr
        }
        else if highNib == 0x2 {    // CALL
            var tempSP = Int(++sp)
            stack[tempSP] = pc
            pc = addr
        }
        else if highNib == 0x3 {    // SE VX, BYTE
            if regs[x] == kk {
                pc += 2
            }
        }
        else if highNib == 0x4 {    // SNE VX, BYTE
            if regs[x] != kk {
                pc += 2
            }
        }
        else if highNib == 0x5 {    // SE VX, VY
            if regs[x] == regs[y] {
                pc += 2
            }
        }
        else if highNib == 0x6 {    // LD VX, BYTE
            regs[x] = kk
        }
        else if highNib == 0x7 {    // ADD VX, BYTE
            regs[x] = regs[x] &+ kk
        }
        else if highNib == 0x8 {
            let low = lowByte & 0xF
            if low == 0x0 {         // LD VX, VY
                regs[x] = regs[y]
            }
            else if low == 0x1 {    // OR VX, VY
                regs[x] |= regs[y]
            }
            else if low == 0x2 {    // AND VX, VY
                regs[x] &= regs[y]
            }
            else if low == 0x3 {    // XOR VX, VY
                regs[x] ^= regs[y]
            }
            else if low == 0x4 {    // ADD VX, VY
                regs[15] = (u16(regs[x]) + u16(regs[y]) > 255) ? 1 : 0
                regs[x] = regs[x] &+ regs[y]
            }
            else if low == 0x5 {    // SUB VX, VY
                regs[15] = (regs[x] > regs[y]) ? 1 : 0
                regs[x] = regs[x] &- regs[y]
            }
            else if low == 0x6 {    // SHR VX
                regs[15] = regs[x] & 0x1
                regs[x] = regs[x] &/ 2
            }
            else if low == 0x7 {    // SUB VY, VX
                regs[15] = (regs[y] > regs[x]) ? 1 : 0
                regs[x] = regs[y] &- regs[x]
            }
            else if low == 0xE {    // SHL VX
                regs[15] = (regs[x] >> 7) & 0x1
                regs[x] = regs[x] &* 2
            }
        }
        else if highNib == 0x9 {    // SNE VX, VY
            if regs[x] != regs[y] {
                pc += 2
            }
        }
        else if highNib == 0xA {    // LD I, Addr
           I = addr
        }
        else if highNib == 0xB {    // JP V0, Addr
            pc = u16(regs[0]) + addr
        }
        else if highNib == 0xC {    // RND VX, BYTE
            var num = arc4random_uniform(256)
            regs[x] = u8(num) & kk
        }
        else if highNib == 0xD {    // Draw VX, VY, Nibble
            for var z = u16(0); z < n; z++ {
                var found = false
                var sprite = Int(memory[Int(I + z)])
                for t in 0..8 {
                    var set = (sprite >> (7 - t)) & 0x1
                    var prev = view.pixel(Int(regs[x]) + t, yLoc:Int(regs[y]) + Int(z))
                    if set == 1 {
                        view.togglePixel(Int(regs[x]) + t, yLoc:Int(regs[y]) + Int(z))
                        if prev {
                            found = true
                        }
                    }
                }
                regs[15] = found ? 1 : 0
            }
            ret = true
        }
        else if highNib == 0xE {
            if lowByte == 0x9E {        // SKP VX
                if keys[Int(regs[x])] {
                    pc += 2
                }
            }
            else if lowByte == 0xA1 {   // SKNP VX
                if !keys[Int(regs[x])] {
                    pc += 2
                }
            }
        }
        else if highNib == 0xF {
            if lowByte == 0x07 {        // LD VX, DT
                regs[x] = dt
            }
            else if lowByte == 0x0A {   // LD VX, K
                var found = false
                for z in 0..0x10 {
                    if keys[z] {
                        found = true
                        regs[x] = u8(z)
                        break;
                    }
                }
                if !found {
                    pc -= 2
                }
            }
            else if lowByte == 0x15 {   // LD DT, VX
                dt = regs[x]
            }
            else if lowByte == 0x18 {   // LD ST, VX
                st = regs[x]
            }
            else if lowByte == 0x1E {   // ADD I, VX
                I = I &+ u16(regs[x])
            }
            else if lowByte == 0x29 {   // LD F, VX
                I = u16(regs[x]) &* 5
            }
            else if lowByte == 0x33 {   // LD B, VX
                memory[Int(I) + 0] = regs[x] &/ 100
                memory[Int(I) + 1] = regs[x] &/ 10
                memory[Int(I) + 2] = regs[x] &/ 1
            }
            else if lowByte == 0x55 {   // LD [I], VX
                for z in 0..regs[x] {
                    memory[Int(I++)] = regs[Int(z)]
                }
            }
            else if lowByte == 0x65 {   // LD VX, [I]
                for z in 0..regs[x] {
                    regs[Int(z)] = memory[Int(I++)]
                }
            }
        }
        
        cy--;
    }
    return ret
}

