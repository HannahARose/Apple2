import Foundation
extension Decimal {
    var int: Int {
        return NSDecimalNumber(decimal: self).intValue
    }
}

/** A class to convert the input text to a list of tokens
 */
public class Interpreter {
    public var demoProg = """
    10 GR
    20 H = RND(200)
    30 TGT = RND(350)+20
    40 G = -10
    99 COLOR = 3
    100 PLOT 0,(390-H)/10
    109 COLOR = 2
    110 PLOT 39,(390-TGT)/10
    111 PLOT 39,(((390-TGT)/10)+1)
    112 PLOT 39,(((390-TGT)/10)+2)
    113 PLOT 39,(((390-TGT)/10)-1)
    114 PLOT 39,(((390-TGT)/10)-2)
    200 PRINT "Enter x velocity"
    210 INPUT XVEL
    250 PRINT "Enter y velocity"
    260 INPUT YVEL
    499 COLOR = 4
    500 X = 30
    510 T = (100*X/XVEL)
    520 Y = (H+T*YVEL/100+G*T*T/10000)
    529 IF (((Y/10)>39) + (0>Y)) THEN GOTO 540
    530 PLOT X/10, (390-Y)/10
    540 X = (X + 30)
    550 IF 391 > X THEN GOTO 510
    600 IF ABS(Y-TGT)>20 THEN GOTO 700 : GOTO 800
    700 PRINT "YOU LOSE"
    710 GOTO 900
    800 PRINT "YOU WIN"
    810 GOTO 900
    900 PRINT "DO YOU WANT TO PLAY AGAIN?(Y:1, N:0)"
    910 INPUT AGAIN
    920 IF AGAIN THEN GOTO 10
    1000 PRINT "THANKS FOR PLAYING"
    1005 TEXT
    1010 END
    """
    
    public var intVars: [String:Int] = ["COLOR":1]
    public var strVars: [String:String] = [:]
    
    public var reservedWords: [String:Token] = [:]
    
    public var knownWords: [String:Token] = [:]
    
    public var currentProg: [Int: String] = [:]
    
    public var doneRunning = false
    public var currentLine = 0
    
    public var os: IntegerBasic?
    public var needsInput = false
    public var nextLine: String?
    public var inputLoc: IntVarToken!
    
    public var lines: [Int] = []
    public var line = 0
    public var isExecuting = false
    
    public var loopTimer: Timer!
    
    public func addOS(_ os: IntegerBasic) {
        self.os = os
    }
    
    // loop to execute program and get input without tying up thread
    public func inputLoop(_: Timer) {
        if !needsInput {
            if isExecuting {
                if doneRunning { isExecuting = false }
                if (line < lines.count) {
                    if let currentLine = currentProg[lines[line]] {
                        line += 1
                        let nextTokens = tokenize(text: currentLine)
                        //print(nextTokens)
                        _ = exec(nextTokens)
                    }
                } else {
                    if (!doneRunning) {
                        os!.print("*** NO END ERR")
                    }
                    isExecuting = false
                }
            } 
            return
        }
        if nextLine == nil {return}
        if let val: Int = Int(nextLine!) {
            intVars[inputLoc.name] = val
            needsInput = false
            nextLine = nil
            if let os = os {
                    if !isExecuting {
                    os.terminalScreen.setCharacterAt(x: 0, y: os.height-1, with: ">")
                    os.cursor.x = 1
                }
            }
        }
    }
    
    public func isInt(_ str: String) -> Bool {
        if let _ = Int(str) {
            return true
        }
        return false
    }
    
    /** Splits the remaining text into tokens
     */
    public func tokenize(text: String) -> [Token] {
        if text.isEmpty {
            return []
        }
        
        // handle comments
        if text[text.startIndex..<(text.index(text.startIndex, offsetBy: 3, limitedBy: text.endIndex) ?? text.endIndex)] == "REM" {
            return []
        }
        
        // tokenize string literals
        if text.contains("\"") {
            let startIndex = text.firstIndex(of: "\"")!
            let textAfter = text[text.index(after:startIndex)...]
            
            
            guard textAfter.contains("\"") else {
                os!.print("*** Syntax Error")
                
                return []
            }
            
            
            let endIndex = textAfter.firstIndex(of: "\"")!
            var prevTokens = tokenize(text: String(text[..<startIndex]))
            let postTokens = tokenize(text: String(text[text.index(after: endIndex)...]))
            prevTokens.append(StrToken(text: String(text[text.index(after:startIndex)..<endIndex])))
            return prevTokens + postTokens
        }
        
        // remove whitespace
        var condensedText = text
        condensedText.removeAll(where: {(ch) in ch.isWhitespace})
        
        if condensedText.isEmpty { return [] }
        
        // tokenize reserved words
        for reservedWord in reservedWords.keys {
            var i = condensedText.startIndex
            if reservedWord.count>condensedText.count {
                continue
            }
            for _ in 0...condensedText.count-reservedWord.count {
                if String(condensedText[i..<condensedText.index(i, offsetBy: reservedWord.count)]) == reservedWord {
                    var prevTokens = tokenize(text: String(condensedText[..<i]))
                    let postTokens = tokenize(text: String(condensedText[condensedText.index(i, offsetBy: reservedWord.count)...]))
                    prevTokens.append(reservedWords[reservedWord]!)
                    return prevTokens+postTokens
                }
                i = condensedText.index(after: i)
            }
        }
        
        if isInt(String(condensedText[condensedText.startIndex])) {
            var i = condensedText.endIndex
            while !isInt(String(condensedText[condensedText.startIndex..<i])) {
                i = condensedText.index(before:i)
            }
            var postTokens: [Token] = i == condensedText.endIndex ? [] : tokenize(text: String(condensedText[condensedText.index(after: i)...]))
            postTokens.insert(IntToken(value: Int(String(condensedText[condensedText.startIndex..<i]))!), at: 0)
            return postTokens
        }
        
        // tokenize largest known word
        var i = condensedText.endIndex
        for _ in 0..<condensedText.count {
            
            if knownWords.keys.contains(String(condensedText[..<i])) {
                var postTokens = tokenize(text: String(condensedText[i...]))
                postTokens.insert(knownWords[String(condensedText[..<i])]!, at: 0)
                return postTokens
            }
            
            i = condensedText.index(before: i)
        }
        
        // assume next alphanumeric to be variable
        if condensedText[condensedText.startIndex].isLetter {
            let varname = condensedText.prefix(while: {(ch) in return ch.isLetter || ch.isNumber})
            
            if condensedText.contains("$") && condensedText.firstIndex(of: "$")! == varname.index(after: varname.endIndex) {
                var postTokens = tokenize(text: String(text[condensedText.index(varname.endIndex, offsetBy: 2)...]))
                postTokens.insert(StrVarToken(name: String(varname)+"$", ib:self), at: 0)
                return postTokens
            }
            var postTokens: [Token] = varname.endIndex == condensedText.endIndex ? [] : tokenize(text: String(text[condensedText.index(after: varname.endIndex)...]))
            postTokens.insert(IntVarToken(name: String(varname), ib:self), at: 0)
            return postTokens
        }
        
        return []
    }
    
    public func exec(_ tokens: [Token]) -> [Any] {
        guard tokens.count > 0 else { return [] }
        
        //print("xc")
        //print(tokens)
        
        
        var vals: [Any] = []
        
        var tokenList = tokens
        
        var i = 0
        while i<tokenList.count-1 {
            let token = tokenList[i]
            
            if token.type == .Symbol {
                if (token as! SymbToken).symbol == "(" {
                    var depth = 1
                    for j in i+1..<tokenList.count {
                        let token2 = tokenList[j]
                        if(token2.type == .Symbol) {
                            if (token2 as! SymbToken).symbol == "(" {
                                depth += 1
                            }
                            
                            if (token2 as! SymbToken).symbol == ")" {
                                depth -= 1
                                
                                if depth == 0 {
                                    let enclosed = Array(tokenList[i+1..<j])
                                    if (i > 0 && tokenList[i-1].type == .Function && (tokenList[i-1] as! FuncToken).encloses == true && (tokenList[i-1] as! FuncToken).params.count == 0) {
                                        var token = tokenList[i-1] as! FuncToken
                                        token.params = enclosed
                                        tokenList = (i>1 ? Array(tokenList[0..<(i-1)]) : [] as [Token]) + Array(repeating: token, count: 1) + (j<tokenList.count-1 ? Array(tokenList[(j+1)...]) : [])
                                    }
                                    else {
                                        tokenList = (i>0 ? Array(tokenList[0..<i]) : [] as [Token]) + (EnToken(enclosed: enclosed, ib: self).evaluate() as! [Token]) + (j<tokenList.count-1 ? Array(tokenList[(j+1)...]) : [])
                                    }
                                    i = 0
                                    break
                                }
                            }
                        }
                    }
                }
            }
            i+=1
        }
        
        for prec in 0...5 {
            i = 0;
            
            while i < tokenList.count {
                if tokenList[i].type == .Operator {
                    var token = tokenList[i] as! OpToken
                    if token.precedence == prec || (token.precedence == -1 && (prec == 3 || (prec == 0 && (i==0 || !(tokenList[i-1].type == .Int && tokenList[i-1].type == .IntVar))))) {
                        if i > 0 { token.lparams = Array(tokenList[0..<i]) }
                        if tokenList.count > i+1 { token.rparams = Array(tokenList[(i+1)...]) }
                        tokenList = token.evaluate() as! [Token]
                        i = 0
                    }
                }
                i+=1
            }
        }
        //print("operators operated")
        
        i = tokenList.count-1
        
        while i >= 0  {
            //print(i)
            if tokenList[i].type == .Function {
                var token = tokenList[i] as! FuncToken
                if !token.encloses {
                    if tokenList.count > 1 {
                        token.params = Array(tokenList[1...])
                    }
                    tokenList.removeSubrange(i..<tokenList.count)
                } else {
                    tokenList.remove(at: i)
                }
                if let v = token.evaluate() { tokenList.append(v as! Token) }
            }
            i -= 1
        }
        
        for t in tokenList {
            if let v = t.evaluate() { vals.append(v) }
        }
        
        //print("functions run")
        return vals
    }
    
    public func execProg() {
        doneRunning = false;
        lines = Array(currentProg.keys)
        lines.sort(by: <)
        line = 0
        isExecuting = true
    }
    
    public init() {
        let ib = self
        
        ib.reservedWords["PRINT"] = FuncToken(exec: {(params) in
            // print("PRINT")
            for p in params {
                ib.os!.print(p)
            }
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["GR"] = FuncToken(exec: {(params) in
            // print("PRINT")
            if let os = ib.os {
                os.gm.isHidden = false
                for colorN in 0..<os.gm.colorGrids.count {
                    os.gm.colorGrids[colorN].removeAll()
                }
            }
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["TEXT"] = FuncToken(exec: {(params) in
            // print("PRINT")
            if let os = ib.os {
                os.gm.isHidden = true
            }
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["INPUT"] = OpToken(prec: 0,exec: {(lparams, rparams, ib) in
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            let rparam = rparams.first!
            switch rparam.type {
            case .IntVar:
                //print("assigning")
                //print(rparams)
                let inputLoc = rparam as! IntVarToken
                    //let nextLine = readLine()!
                    ib.needsInput = true
                    ib.inputLoc = inputLoc
                return []
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        
        ib.reservedWords["PLOT"] = OpToken(prec: 0,exec: {(lparams, rparams, ib) in
            if( rparams.count == 0 )  {
                ib.os!.print("if error")
                return []
            }
            
            var i = 0
            while i < rparams.count && (rparams[i].type != .Symbol || (rparams[i] as! SymbToken).symbol != ",") {
                i += 1
            }
            
            let comLoc = i
            
            guard(comLoc<rparams.count-1) else {
                ib.os!.print("error")
                return []
            }
            
            let xTokens = Array(rparams[0..<comLoc])
            let yTokens = Array(rparams[(comLoc+1)...])
            
            let x = ib.exec(xTokens)[0] as! Int
            
            let y = ib.exec(yTokens)[0] as! Int
            
            if let os = ib.os {
                os.gm.drawRect(color: ib.intVars["COLOR"]!, at: x, y)
            }
            
            return []
        }, ib: ib)
        
        ib.reservedWords["IF"] = OpToken(prec: 0,exec: {(lparams, rparams, ib) in
            if( rparams.count == 0 )  {
                ib.os!.print("if error")
                return []
            }
            
            var i = 0
            while i < rparams.count && (rparams[i].type != .Symbol || (rparams[i] as! SymbToken).symbol != "THEN") {
                i += 1
            }
            
            let thenLoc = i
            
            guard(thenLoc<rparams.count-1) else {
                ib.os!.print("error")
                return []
            }
            
            while i < rparams.count && (rparams[i].type != .Symbol || (rparams[i] as! SymbToken).symbol != ":") {
                i += 1
            }
            
            let colonLoc = i
            
            let condTokens = Array(rparams[0..<thenLoc])
            let expTokensTrue = Array(rparams[thenLoc+1..<colonLoc])
            let expTokensFalse: [Token] = ((colonLoc+1)>=rparams.count) ? [] : Array(rparams[(colonLoc+1)...])
            
            let cond = ib.exec(condTokens)[0]
            
            if !((cond as? Int) == 0) {
                _ = ib.exec(expTokensTrue)
            } else {
                _ = ib.exec(expTokensFalse)
            }
            return []
        }, ib: ib)
        
        ib.reservedWords["RND"] = FuncToken(exec: {(params) in
            return IntToken(value: Int.random(in: 0..<(params[0]as! Int)))
        }, params: [], ib: ib, encloses: true)
        
        ib.reservedWords["ABS"] = FuncToken(exec: {(params) in
            return IntToken(value:  abs(params[0]as! Int))
        }, params: [], ib: ib, encloses: true)
        
        ib.reservedWords["NEW"] = FuncToken(exec: {(params) in
            ib.currentProg = [:]
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["LOAD"] = FuncToken(exec: {(params) in
            for line in ib.demoProg.split(separator: "\n") {
                let nl = String(line)
                if ib.isInt(String(nl[nl.startIndex])) {
                    var i = nl.endIndex
                    while !ib.isInt(String(nl[nl.startIndex..<i])) {
                        i = nl.index(before:i)
                    }
                    let ln = Int(String(nl[nl.startIndex..<i]))!
                    ib.currentProg[ln] = (i == nl.endIndex) ? nil : String(nl[nl.index(after: i)...])
                } else {
                    let nextTokens = ib.tokenize(text: nl)
                    _ = ib.exec(nextTokens)
                }
            }
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["LIST"] = FuncToken(exec: {(params) in
            var lines = Array(ib.currentProg.keys)
            lines.sort(by: <)
            for p in lines {
                ib.os!.print(p, terminator:" ")
                ib.os!.print(ib.currentProg[p]!)
            }
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["RUN"] = FuncToken(exec: {(params) in
            ib.execProg()
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["END"] = FuncToken(exec: {(params) in
            ib.doneRunning = true
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["GOTO"] = FuncToken(exec: {(params) in
            ib.line = ib.lines.firstIndex(of: params[0] as! Int) ?? ib.line
            return nil
        }, params: [], ib: ib)
        
        ib.reservedWords["("] = SymbToken(symbol: "(")
        ib.reservedWords[")"] = SymbToken(symbol: ")")
        ib.reservedWords["THEN"] = SymbToken(symbol: "THEN")
        ib.reservedWords[":"] = SymbToken(symbol: ":")
        ib.reservedWords[","] = SymbToken(symbol: ",")
        
        //OPERATORS
        ib.reservedWords["+"] = OpToken(prec: 3,exec: {(lp, rp, ib) in
            let lparams: [Token] = lp
            var rparams: [Token] = rp
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            var lparam = lparams.last!
            var rparamToken = rparams.first!
            if (rparamToken.type == .Function) {
                rparams = ib.exec(rparams) as! [Token]
                rparamToken = rparams.first!
            }
            if (lparam.type == .Function) {
                lparam = (lparam.evaluate() as! Token)
            }
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value + (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) + (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value + (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) + (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords["-"] = OpToken(prec: -1,exec: {(lparams, rparams, ib) in
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            let lparam = lparams.last ?? SymbToken(symbol: "X")
            let rparamToken = rparams.first!
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value - (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) - (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    return lparams + Array(repeating: IntToken(value: 0 - (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value - (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) - (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    return lparams + Array(repeating: IntToken(value: 0 - (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords["*"] = OpToken(prec: 2,exec: {(lp, rp, ib) in
            let lparams: [Token] = lp
            var rparams: [Token] = rp
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            var lparam = lparams.last!
            var rparamToken = rparams.first!
            if (rparamToken.type == .Function) {
                rparams = ib.exec(rparams) as! [Token]
                rparamToken = rparams.first!
            }
            if (lparam.type == .Function) {
                lparam = (lparam.evaluate() as! Token)
            }
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value * (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) * (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value * (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) * (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords["/"] = OpToken(prec: 2,exec: {(lp, rp, ib) in
            let lparams: [Token] = lp
            var rparams: [Token] = rp
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            var lparam = lparams.last!
            var rparamToken = rparams.first!
            if (rparamToken.type == .Function) {
                rparams = ib.exec(rparams) as! [Token]
                rparamToken = rparams.first!
            }
            if (lparam.type == .Function) {
                lparam = (lparam.evaluate() as! Token)
            }
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value / (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) / (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value / (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) / (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords["MOD"] = OpToken(prec: 2,exec: {(lparams, rparams, ib) in
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            let lparam = lparams.last!
            let rparamToken = rparams.first!
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value % (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) % (rparamToken as! IntToken).value) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value % (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) % (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords[">"] = OpToken(prec: 5,exec: {(lp, rp, ib) in
            let lparams: [Token] = lp
            var rparams: [Token] = rp
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            var lparam = lparams.last!
            var rparamToken = rparams.first!
            if (rparamToken.type == .Function) {
                rparams = ib.exec(rparams) as! [Token]
                rparamToken = rparams.first!
            }
            if (lparam.type == .Function) {
                lparam = (lparam.evaluate() as! Token)
            }
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value > (rparamToken as! IntToken).value ? 1 : 0) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) > (rparamToken as! IntToken).value ? 1 : 0 ) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (lparam as! IntToken).value > (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0) ? 1 : 0) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (ib.intVars[(lparam as! IntVarToken).name] ?? 0) > (ib.intVars[(rparamToken as! IntVarToken).name] ?? 0) ? 1 : 0) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords["^"] = OpToken(prec: 1,exec: {(lparams, rparams, ib) in
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            let lparam = lparams.last!
            let rparamToken = rparams.first!
            switch rparamToken.type{
            case .Int:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (pow(Decimal((lparam as! IntToken).value), (rparamToken as! IntToken).value)).int) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (pow(Decimal(ib.intVars[(lparam as! IntVarToken).name] ?? 0), (rparamToken as! IntToken).value)).int) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            case .IntVar:
                switch lparam.type {
                case .Int:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (pow(Decimal((lparam as! IntToken).value), ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)).int) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                case .IntVar:
                    return (lparams.count > 1 ? Array(lparams[0..<lparams.count-1]) : []) + Array(repeating: IntToken(value: (pow(Decimal(ib.intVars[(lparam as! IntVarToken).name] ?? 0), ib.intVars[(rparamToken as! IntVarToken).name] ?? 0)).int) as Token, count: 1) + (rparams.count > 1 ? Array(rparams[1...]) : []) 
                default:
                    ib.os!.print("add error")
                    return []
                }
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        ib.reservedWords["="] = OpToken(prec: 4,exec: {(lparams, rparams, ib) in
            if( lparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            if( rparams.count == 0 )  {
                ib.os!.print("add error")
                return []
            }
            let lparam = lparams.last!
            switch lparam.type {
            case .IntVar:
                //print("assigning")
                //print(rparams)
                ib.intVars[((lparam as! IntVarToken).name)] = (ib.exec(rparams)[0] as? Int) ?? ib.intVars[((lparam as! IntVarToken).name)]
                return []
            default:
                ib.os!.print("add error")
                return []
            }
        }, ib: ib)
        
        loopTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true, block: {(timer) in self.inputLoop(timer)})
    }
}
