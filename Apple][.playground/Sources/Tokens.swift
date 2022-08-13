import Foundation

public enum TokenType {
    case Int
    case String
    case variable
    case Function
    case IntVar
    case StrVar
    case Operator
    case Enclosure
    case Symbol
    case LineNumber
}

public protocol Token {
    func asString() -> String
    func evaluate() -> Any?
    var type: TokenType { get }
}

public struct IntToken: Token {
    
    
    public let type = TokenType.Int
    
    public var value: Int
    
    public func asString() -> String {
        return String(value)
    }
    
    public func evaluate() -> Any? {
        if abs(value) > 32767 {
            print("*** >32767 ERR")
            return nil
        }
        return value
    }
    
    public init(value: Int) {
        self.value = value
    }
}

public struct LNToken: Token {
    
    
    public let type = TokenType.LineNumber
    
    public var value: Int
    
    public func asString() -> String {
        return String(value)
    }
    
    public func evaluate() -> Any? {
        if abs(value) > 32767 {
            print("*** >32767 ERR")
            return nil
        }
        return value
    }
    
    public init(value: Int) {
        self.value = value
    }
}

public struct StrToken: Token {
    public let type = TokenType.String
    
    public var text: String
    
    public func asString() -> String {
        return text
    }
    
    public func evaluate() -> Any? {
        return text
    }
    
    public init(text: String) {
        self.text = text
    }
}

public struct FuncToken: Token {
    public let type = TokenType.Function
    
    public var exec: ([Any]) -> Token?
    public var params: [Token]
    
    public var ib: Interpreter
    public var encloses = false
    
    public func asString() -> String {
        return String(describing: self)
    }
    
    public func evaluate() -> Any? {
        let vals = ib.exec(params)
        //print ("Evaluating")
        //print (vals)
        return exec(vals)
    }
    
    public init(exec: @escaping ([Any]) -> Token?, params: [Token], ib: Interpreter) {
        self.exec = exec
        self.params = params
        self.ib = ib
    }
    
    public init(exec: @escaping ([Any]) -> Token?, params: [Token], ib: Interpreter, encloses: Bool) {
        self.exec = exec
        self.params = params
        self.ib = ib
        self.encloses = encloses
    }
}

public struct IntVarToken: Token {
    public let type = TokenType.IntVar
    
    public var ib: Interpreter
    
    public var name: String
    
    public func asString() -> String {
        return name
    }
    
    public func evaluate() -> Any? {
        return ib.intVars[name] ?? 0
    }
    
    public init(name: String, ib: Interpreter) {
        self.name = name
        self.ib = ib
    }
}

public struct StrVarToken: Token {
    public let type = TokenType.StrVar
    
    public var ib: Interpreter
    
    public var name: String
    
    public func asString() -> String {
        return name
    }
    
    public func evaluate() -> Any? {
        return ib.strVars[name] ?? ""
    }
    
    public init(name: String, ib: Interpreter) {
        self.name = name
        self.ib = ib
    }
}

public struct OpToken: Token {
    public let type = TokenType.Operator
    
    public var exec: ([Token],[Token],Interpreter) -> [Token]
    public var lparams: [Token] = []
    public var rparams: [Token] = []
    public var ib: Interpreter
    public var precedence: Int
    
    public func asString() -> String {
        return String(describing: self)
    }
    
    public func evaluate() -> Any? {
        return exec(lparams, rparams, ib)
    }
    
    public init(prec:Int, exec: @escaping ([Token],[Token],Interpreter) -> [Token], ib: Interpreter) {
        self.precedence = prec
        self.ib = ib
        self.exec = exec
    }
}

public struct EnToken: Token {
    public let type = TokenType.Enclosure
    
    public var enclosed: [Token]
    
    public var ib: Interpreter
    
    public func asString() -> String {
        return String(describing: self)
    }
    
    public func evaluate() -> Any? {
        return Array(repeating: IntToken(value:ib.exec(enclosed)[0]as!Int),count: 1)
    }
    
    public init(enclosed: [Token], ib: Interpreter) {
        self.enclosed = enclosed
        self.ib = ib
    }
}

public struct SymbToken: Token {
    public let type = TokenType.Symbol
    
    public let symbol: String
    
    public func asString() -> String {
        return String(describing: self)
    }
    
    public func evaluate() -> Any? {
        print("error symb is not string")
    }
    
    public init(symbol: String) {
        self.symbol = symbol
    }
}
