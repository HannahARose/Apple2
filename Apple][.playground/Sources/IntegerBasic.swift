

import Foundation


// a type to store the cursor information
struct Cursor {
    var x: Int
    var y: Int
    var isBlinking: Bool
    var isVisible: Bool
}

// A class to handle the text output of the system
class TerminalScreen {
    public var screen: String
    var height: Int
    var width: Int
    var blankRow: String
    
    init(height: Int, width: Int) {
        self.height = height
        self.width = width
        blankRow = ""
        for _ in 0..<width {
            blankRow = blankRow + " "
        }
        screen = ""
        for _ in 0..<height {
            screen = screen + blankRow + "\n"
        }
        screen.replaceSubrange(screen.index(before: screen.endIndex)..<screen.endIndex,with: "")
    }
    
    func characterAt(x: Int, y: Int) -> Character {
        print(x)
        print(y)
        let pos = y*(width+1)+x
        guard pos<screen.count else {
            return "\u{0}"
        }
        return screen[screen.index(screen.startIndex, offsetBy: pos)]
    }
    
    func lineTo(x: Int, y: Int) -> String {
        let pos1 = y*(width+1)
        let pos2 = y*(width+1)+x
        return String(screen[screen.index(screen.startIndex, offsetBy: pos1)..<screen.index(screen.startIndex, offsetBy: pos2)])
    }
    
    func setCharacterAt(x: Int, y: Int, with char: Character) {
        let pos = y*(width+1)+x
        guard pos<screen.count else {
            return
        }
        screen.replaceSubrange(screen.index(screen.startIndex, offsetBy: pos)...screen.index(screen.startIndex, offsetBy: pos), with: String(char))
        
    }
    
    func scrollUp() {
        screen.replaceSubrange(screen.startIndex...screen.index(screen.startIndex, offsetBy: width), with: "")
        screen = screen + "\n" + blankRow
    }
}

// the "operating system" to coordinate the monitors with the interpreter
public class IntegerBasic {
    var textMonitor: TextMonitor!
    var terminalScreen: TerminalScreen
    var gm: GraphicsMonitor!
    var width = 20
    var height = 15
    
    public var interpreter: Interpreter
    
    var loopTimer: Timer!
    
    var cursor = Cursor(x: 1, y: 14, isBlinking: true, isVisible: true)
    
    var on = false
    var bootTime: NSDate
    
    init(height: Int, width: Int) {
        self.height = height
        self.width = width
        
        interpreter = Interpreter()
        
        terminalScreen = TerminalScreen(height: height, width: width)
        
        terminalScreen.setCharacterAt(x: 0, y: height-1, with: ">")
        
        cursor = Cursor(x: 1, y: height-1, isBlinking: true, isVisible: true)
        
        bootTime = NSDate()
        
        interpreter.os = self
        //lastPrint = NSDate()
    }
    
    func printScreen() {
        
        let temp = terminalScreen.characterAt(x: cursor.x, y: cursor.y)
        if cursor.isVisible {
            terminalScreen.setCharacterAt(x: cursor.x, y: cursor.y, with: "\u{2588}")
        }
        
        textMonitor.text = terminalScreen.screen
        
        terminalScreen.setCharacterAt(x: cursor.x, y: cursor.y, with: temp)
        //lastPrint.addingTimeInterval(0.5)
    }
    
    func turnOn() {
        if !on {
            on = true
            loopTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: {(timer) in self.mainLoop(timer)})
        }
    }
    
    func setTextMonitor(_ m: TextMonitor) {
        textMonitor = m
    }
    
    func setGM(_ gm: GraphicsMonitor) {
        self.gm = gm
    }
    
    func mainLoop(_: Timer) {
        if cursor.isBlinking {
            cursor.isVisible = (Int(bootTime.timeIntervalSinceNow) & 1 ) == 0
        }
        printScreen()
    }
    
    public func print(_ item: Any) {
        terminalScreen.scrollUp()
        cursor.x = 0
        let text = String(describing: item)
        for c in text {
            type(String(c))
        }
        terminalScreen.scrollUp()
        cursor.x = 0
    }
    
    public func print(_ item: Any, terminator: String) {
        let text = String(describing: item)
        for c in text {
            type(String(c))
        }
        for c in terminator {
            type(String(c))
        }
    }
    
    public func type(_ char: String) {
        if (char[char.startIndex] == "~") {
            switch(char) {
            case "~RETURN":
                var nl = terminalScreen.lineTo(x: cursor.x, y: cursor.y)
                Swift.print(nl)
                if(interpreter.needsInput) {
                    interpreter.nextLine = nl
                } else {
                    if nl.count > 1 {
                        nl = String(nl[nl.index(after: nl.startIndex)...])
                        if interpreter.isInt(String(nl[nl.startIndex])) {
                            var i = nl.endIndex
                            while !interpreter.isInt(String(nl[nl.startIndex..<i])) {
                                i = nl.index(before:i)
                            }
                            let ln = Int(String(nl[nl.startIndex..<i]))!
                            interpreter.currentProg[ln] = (i == nl.endIndex) ? nil : String(nl[nl.index(after: i)...])
                        } else {
                            let nextTokens = interpreter.tokenize(text: nl)
                            _ = interpreter.exec(nextTokens)
                        }
                    }
                }
                terminalScreen.scrollUp()
                cursor.x = 0
                if(!interpreter.needsInput) {
                    terminalScreen.setCharacterAt(x: 0, y: height-1, with: ">")
                    cursor.x = 1
                }
            case "~left":
                if cursor.x > 0 {
                    cursor.x -= 1
                }
            case "~right":
                if cursor.x < width-1 {
                    cursor.x += 1
                }
            case "~ESC":
                interpreter.doneRunning = true
            case "~RESET":
                interpreter.doneRunning = true
            case "~POWER":
                turnOn()
            default: break
                
            }
        } else {
            terminalScreen.setCharacterAt(x: cursor.x, y: cursor.y, with: char[char.startIndex])
            cursor.x += 1
            if cursor.x == width {
                cursor.x = 0
                terminalScreen.scrollUp()
            }
            
        }
    }
}
