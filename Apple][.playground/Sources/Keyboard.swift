
import SpriteKit
import UIKit
import SwiftUI
import PlaygroundSupport

import Foundation

// arrays of keypresses
let unshiftKeys = [["1","2","3","4","5","6","7","8","9","0",":","-","~RESET"],["~ESC", "Q","W","E","R","T","Y","U","I","O","P","~REPT","~RETURN", "~RETURN"],["~CTRL","A","S","D","F","G","H","J","K","L",";","~left","~right"],["~SHIFT","~SHIFT","Z","X","C","V","B","N","M",",",".","/","~SHIFT","~SHIFT"],["~POWER"," "]]
let shiftKeys = [["!","\"","#","$","%","&","'","(",")","0","*","=","~RESET"],["~ESC", "Q","W","E","R","T","Y","U","I","O","@","~REPT","~RETURN", "~RETURN"],["~CTRL","A","S","D","F","~BELL","H","J","K","L","+","~left","~right"],["~SHIFT","~SHIFT","Z","X","C","V","B","^","M","<",">","?","~SHIFT","~SHIFT"],["~POWER"," "]]

// A view to take and handle key input
public class Keyboard: UIView, UIKeyInput {
    var shift = false
    var ctrl = false
    var os: IntegerBasic!
    var comp: AppleII!
    
    public func setOS(_ m: IntegerBasic) {
        os = m
    }
    public override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    // handle physical keyboard
    func addComp(comp: AppleII) {
        self.comp = comp
        
        comp.addKeyCommand(UIKeyCommand(input: "p", modifierFlags: .control, action: #selector(power)))
        
        becomeFirstResponder()
    }
    
    public func insertText(_ text: String) {
        if text == "\n" { os.type("~RETURN") 
            return
        }
        os.type(text.capitalized)
    }
    
    public func deleteBackward() {
        os.type("~left")
    }
    
    public var hasText = true
    
    
    // turn on
    @objc func power() {
        os.turnOn()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
        isMultipleTouchEnabled = true
    }
    
    // handle touches
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pos = touch.location(in: self)
            pressKey(at: Double(pos.x), Double(pos.y))
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pos = touch.location(in: self)
            unpressKey(at: Double(pos.x), Double(pos.y))
        }
    }
    
    func pressKey(at x: Double, _ y:  Double) {
        let (row,col) = mapTouch(at: x,y)
        if(col != -1 && col<shiftKeys[row].count) {
            switch (shiftKeys[row][col]) {
            case "~SHIFT":
                shift = true
            case "~CTRL":
                ctrl = true
            default:
                if (shift) {
                    os.type(shiftKeys[row][col])
                } else {
                    os.type(unshiftKeys[row][col])
                }
            }
        }
    }
    
    func unpressKey(at x: Double, _ y:  Double) {
        let (row,col) = mapTouch(at: x,y)
        if(col != -1 && col<shiftKeys[row].count) {
            switch (shiftKeys[row][col]) {
            case "~SHIFT":
                shift = false
            case "~CTRL":
                ctrl = false
            default:
                print("key released")
            }
        }
    }
    
    // convert location of touch to the position in the grid of keys
    func mapTouch(at x: Double, _ y: Double) -> (Int, Int) {
        let row = Int(floor((y)/25.0))
        var col = -1;
        switch(row) {
        case 0:
            col = Int(floor((x-15)/24.0))
        case 1:
            col = Int(floor((x)/24.0))
        case 2:
            col = Int(floor((x-5)/24.0))
        case 3:
            col = Int(floor((x+5)/24.0))
        case 4:
            if (x > 5 && x < 30 ) {
                col = 0
            }
            if ( x > 60 && x < 260) {
                col = 1
            }
        default:
            col = -1
            
        }
        return (row,col)
    }
}
