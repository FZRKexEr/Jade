import Foundation
import OSLog

// MARK: - UCI Command Types

/// UCI command types sent from GUI to engine
public enum UCICommand: Sendable, CustomStringConvertible, Equatable {
    // Engine control
    case uci
    case debug(Bool)
    case isready
    case setoption(id: String, value: String?)
    case register(String)
    case ucinewgame
    case quit

    // Position and search
    case position(fen: String?, moves: [String])
    case go(GoCommand)
    case stop
    case ponderhit

    public var description: String {
        switch self {
        case .uci:
            return "uci"
        case .debug(let on):
            return "debug \(on ? "on" : "off")"
        case .isready:
            return "isready"
        case .setoption(let id, let value):
            if let value = value {
                return "setoption name \(id) value \(value)"
            } else {
                return "setoption name \(id)"
            }
        case .register(let token):
            return "register \(token)"
        case .ucinewgame:
            return "ucinewgame"
        case .quit:
            return "quit"
        case .position(let fen, let moves):
            var result = "position "
            if let fen = fen {
                result += "fen \(fen)"
            } else {
                result += "startpos"
            }
            if !moves.isEmpty {
                result += " moves \(moves.joined(separator: " "))"
            }
            return result
        case .go(let command):
            return "go \(command)"
        case .stop:
            return "stop"
        case .ponderhit:
            return "ponderhit"
        }
    }
}

/// Go command sub-parameters
public enum GoCommand: Sendable, CustomStringConvertible, Equatable {
    case searchmoves([String])
    case ponder
    case wtime(Int)      // milliseconds
    case btime(Int)
    case winc(Int)
    case binc(Int)
    case movestogo(Int)
    case depth(Int)
    case nodes(Int)
    case mate(Int)
    case movetime(Int)   // milliseconds
    case infinite

    public var description: String {
        switch self {
        case .searchmoves(let moves):
            return "searchmoves \(moves.joined(separator: " "))"
        case .ponder:
            return "ponder"
        case .wtime(let ms):
            return "wtime \(ms)"
        case .btime(let ms):
            return "btime \(ms)"
        case .winc(let ms):
            return "winc \(ms)"
        case .binc(let ms):
            return "binc \(ms)"
        case .movestogo(let n):
            return "movestogo \(n)"
        case .depth(let n):
            return "depth \(n)"
        case .nodes(let n):
            return "nodes \(n)"
        case .mate(let n):
            return "mate \(n)"
        case .movetime(let ms):
            return "movetime \(ms)"
        case .infinite:
            return "infinite"
        }
    }
}

/// Multiple go command parameters
public struct GoParameters: Sendable, Equatable, CustomStringConvertible {
    public var searchmoves: [String]?
    public var ponder: Bool
    public var wtime: Int?
    public var btime: Int?
    public var winc: Int?
    public var binc: Int?
    public var movestogo: Int?
    public var depth: Int?
    public var nodes: Int?
    public var mate: Int?
    public var movetime: Int?
    public var infinite: Bool

    public init(
        searchmoves: [String]? = nil,
        ponder: Bool = false,
        wtime: Int? = nil,
        btime: Int? = nil,
        winc: Int? = nil,
        binc: Int? = nil,
        movestogo: Int? = nil,
        depth: Int? = nil,
        nodes: Int? = nil,
        mate: Int? = nil,
        movetime: Int? = nil,
        infinite: Bool = false
    ) {
        self.searchmoves = searchmoves
        self.ponder = ponder
        self.wtime = wtime
        self.btime = btime
        self.winc = winc
        self.binc = binc
        self.movestogo = movestogo
        self.depth = depth
        self.nodes = nodes
        self.mate = mate
        self.movetime = movetime
        self.infinite = infinite
    }

    public var description: String {
        var parts: [String] = []

        if let searchmoves = searchmoves, !searchmoves.isEmpty {
            parts.append("searchmoves \(searchmoves.joined(separator: " "))")
        }
        if ponder {
            parts.append("ponder")
        }
        if let wtime = wtime {
            parts.append("wtime \(wtime)")
        }
        if let btime = btime {
            parts.append("btime \(btime)")
        }
        if let winc = winc {
            parts.append("winc \(winc)")
        }
        if let binc = binc {
            parts.append("binc \(binc)")
        }
        if let movestogo = movestogo {
            parts.append("movestogo \(movestogo)")
        }
        if let depth = depth {
            parts.append("depth \(depth)")
        }
        if let nodes = nodes {
            parts.append("nodes \(nodes)")
        }
        if let mate = mate {
            parts.append("mate \(mate)")
        }
        if let movetime = movetime {
            parts.append("movetime \(movetime)")
        }
        if infinite {
            parts.append("infinite")
        }

        return parts.joined(separator: " ")
    }

    /// Convert to array of GoCommand
    public func toCommands() -> [GoCommand] {
        var commands: [GoCommand] = []

        if let searchmoves = searchmoves, !searchmoves.isEmpty {
            commands.append(.searchmoves(searchmoves))
        }
        if ponder {
            commands.append(.ponder)
        }
        if let wtime = wtime {
            commands.append(.wtime(wtime))
        }
        if let btime = btime {
            commands.append(.btime(btime))
        }
        if let winc = winc {
            commands.append(.winc(winc))
        }
        if let binc = binc {
            commands.append(.binc(binc))
        }
        if let movestogo = movestogo {
            commands.append(.movestogo(movestogo))
        }
        if let depth = depth {
            commands.append(.depth(depth))
        }
        if let nodes = nodes {
            commands.append(.nodes(nodes))
        }
        if let mate = mate {
            commands.append(.mate(mate))
        }
        if let movetime = movetime {
            commands.append(.movetime(movetime))
        }
        if infinite {
            commands.append(.infinite)
        }

        return commands
    }
}

// MARK: - UCI Response Types

/// UCI response types received from engine to GUI
public enum UCIResponse: Sendable, CustomStringConvertible, Equatable {
    case id(IdInfo)
    case uciok
    case readyok
    case bestmove(String, ponder: String?)
    case copyprotection(CopyProtectionStatus)
    case registration(RegistrationStatus)
    case info(InfoData)
    case option(OptionConfig)

    public var description: String {
        switch self {
        case .id(let info):
            return "id \(info)"
        case .uciok:
            return "uciok"
        case .readyok:
            return "readyok"
        case .bestmove(let move, let ponder):
            if let ponder = ponder {
                return "bestmove \(move) ponder \(ponder)"
            } else {
                return "bestmove \(move)"
            }
        case .copyprotection(let status):
            return "copyprotection \(status)"
        case .registration(let status):
            return "registration \(status)"
        case .info(let data):
            return "info \(data)"
        case .option(let config):
            return "option \(config)"
        }
    }
}

// MARK: - Supporting Response Types

/// Engine identification information
public struct IdInfo: Sendable, Equatable, CustomStringConvertible {
    public let name: String?
    public let author: String?

    public init(name: String? = nil, author: String? = nil) {
        self.name = name
        self.author = author
    }

    public var description: String {
        var parts: [String] = []
        if let name = name {
            parts.append("name \(name)")
        }
        if let author = author {
            parts.append("author \(author)")
        }
        return parts.joined(separator: " ")
    }
}

/// Copy protection status
public enum CopyProtectionStatus: String, Sendable, Equatable, CustomStringConvertible {
    case checking
    case ok
    case error

    public var description: String {
        rawValue
    }
}

/// Registration status
public enum RegistrationStatus: String, Sendable, Equatable, CustomStringConvertible {
    case checking
    case ok
    case error

    public var description: String {
        rawValue
    }
}

/// Score information
public enum ScoreInfo: Sendable, Equatable, CustomStringConvertible {
    case cp(Int)              // centipawns (white positive)
    case mate(Int)            // mate in N moves (positive=white mates, negative=black mates)
    case lowerbound(Int)
    case upperbound(Int)

    public var description: String {
        switch self {
        case .cp(let score):
            return "cp \(score)"
        case .mate(let moves):
            return "mate \(moves)"
        case .lowerbound(let score):
            return "lowerbound \(score)"
        case .upperbound(let score):
            return "upperbound \(score)"
        }
    }

    /// Returns the numerical score value (for cp) or mate distance
    public var value: Int {
        switch self {
        case .cp(let v), .mate(let v), .lowerbound(let v), .upperbound(let v):
            return v
        }
    }
}

/// Info data from engine during search
public struct InfoData: Sendable, Equatable, CustomStringConvertible {
    public let depth: Int?                  // current depth
    public let seldepth: Int?               // selective search depth
    public let time: Int?                   // search time in ms
    public let nodes: Int?                  // nodes searched
    public let pv: [String]?                // principal variation
    public let multipv: Int?                // multipv index
    public let score: ScoreInfo?            // evaluation score
    public let currmove: String?            // current move being analyzed
    public let currmovenumber: Int?         // current move number
    public let hashfull: Int?               // hash table fill rate (0-1000)
    public let nps: Int?                    // nodes per second
    public let tbhits: Int?                 // tablebase hits
    public let sbhits: Int?                 // static evaluation hits
    public let cpuload: Int?                // CPU load
    public let string: String?              // custom string
    public let refutation: [String]?        // refutation line
    public let currline: [String]?          // current search line

    public init(
        depth: Int? = nil,
        seldepth: Int? = nil,
        time: Int? = nil,
        nodes: Int? = nil,
        pv: [String]? = nil,
        multipv: Int? = nil,
        score: ScoreInfo? = nil,
        currmove: String? = nil,
        currmovenumber: Int? = nil,
        hashfull: Int? = nil,
        nps: Int? = nil,
        tbhits: Int? = nil,
        sbhits: Int? = nil,
        cpuload: Int? = nil,
        string: String? = nil,
        refutation: [String]? = nil,
        currline: [String]? = nil
    ) {
        self.depth = depth
        self.seldepth = seldepth
        self.time = time
        self.nodes = nodes
        self.pv = pv
        self.multipv = multipv
        self.score = score
        self.currmove = currmove
        self.currmovenumber = currmovenumber
        self.hashfull = hashfull
        self.nps = nps
        self.tbhits = tbhits
        self.sbhits = sbhits
        self.cpuload = cpuload
        self.string = string
        self.refutation = refutation
        self.currline = currline
    }

    public var description: String {
        var parts: [String] = []
        if let depth = depth { parts.append("depth \(depth)") }
        if let seldepth = seldepth { parts.append("seldepth \(seldepth)") }
        if let time = time { parts.append("time \(time)") }
        if let nodes = nodes { parts.append("nodes \(nodes)") }
        if let pv = pv { parts.append("pv \(pv.joined(separator: " "))") }
        if let multipv = multipv { parts.append("multipv \(multipv)") }
        if let score = score { parts.append("score \(score)") }
        if let currmove = currmove { parts.append("currmove \(currmove)") }
        if let currmovenumber = currmovenumber { parts.append("currmovenumber \(currmovenumber)") }
        if let hashfull = hashfull { parts.append("hashfull \(hashfull)") }
        if let nps = nps { parts.append("nps \(nps)") }
        if let tbhits = tbhits { parts.append("tbhits \(tbhits)") }
        if let sbhits = sbhits { parts.append("sbhits \(sbhits)") }
        if let cpuload = cpuload { parts.append("cpuload \(cpuload)") }
        if let string = string { parts.append("string \(string)") }
        if let refutation = refutation { parts.append("refutation \(refutation.joined(separator: " "))") }
        if let currline = currline { parts.append("currline \(currline.joined(separator: " "))") }
        return parts.joined(separator: " ")
    }
}

/// Option type for engine configuration
public enum OptionType: String, Sendable, Equatable, CustomStringConvertible {
    case check
    case spin
    case combo
    case button
    case string

    public var description: String {
        rawValue
    }
}

/// Engine option configuration
public struct OptionConfig: Sendable, Equatable, CustomStringConvertible {
    public let name: String
    public let type: OptionType
    public let defaultValue: String?
    public let min: Int?
    public let max: Int?
    public let varOptions: [String]?

    public init(
        name: String,
        type: OptionType,
        defaultValue: String? = nil,
        min: Int? = nil,
        max: Int? = nil,
        varOptions: [String]? = nil
    ) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.min = min
        self.max = max
        self.varOptions = varOptions
    }

    public var description: String {
        var parts: [String] = []
        parts.append("name \(name)")
        parts.append("type \(type)")
        if let defaultValue = defaultValue {
            parts.append("default \(defaultValue)")
        }
        if let min = min {
            parts.append("min \(min)")
        }
        if let max = max {
            parts.append("max \(max)")
        }
        if let varOptions = varOptions {
            for option in varOptions {
                parts.append("var \(option)")
            }
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - UCI Parser

/// Parser for UCI protocol responses
public actor UCIParser {
    private let logger = Logger(subsystem: "com.chinesechess", category: "UCIParser")

    public init() {}

    /// Parse a UCI response line
    public func parse(_ line: String) throws -> UCIResponse {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw UCIError.parseError("Empty input line")
        }

        let tokens = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let command = tokens.first else {
            throw UCIError.parseError("No command found in line: \(trimmed)")
        }

        logger.debug("Parsing command: \(command)")

        switch command {
        case "id":
            return try parseId(tokens: Array(tokens.dropFirst()))
        case "uciok":
            return .uciok
        case "readyok":
            return .readyok
        case "bestmove":
            return try parseBestmove(tokens: Array(tokens.dropFirst()))
        case "copyprotection":
            return try parseCopyprotection(tokens: Array(tokens.dropFirst()))
        case "registration":
            return try parseRegistration(tokens: Array(tokens.dropFirst()))
        case "info":
            return try parseInfo(tokens: Array(tokens.dropFirst()))
        case "option":
            return try parseOption(tokens: Array(tokens.dropFirst()))
        default:
            throw UCIError.parseError("Unknown UCI command: \(command)")
        }
    }

    // MARK: - Private Parsing Methods

    private func parseId(tokens: [String]) throws -> UCIResponse {
        var name: String?
        var author: String?

        var i = 0
        while i < tokens.count {
            let token = tokens[i]
            if token == "name" && i + 1 < tokens.count {
                // Collect all remaining tokens until next keyword
                var nameParts: [String] = []
                i += 1
                while i < tokens.count && !isIdKeyword(tokens[i]) {
                    nameParts.append(tokens[i])
                    i += 1
                }
                name = nameParts.joined(separator: " ")
                continue
            } else if token == "author" && i + 1 < tokens.count {
                var authorParts: [String] = []
                i += 1
                while i < tokens.count && !isIdKeyword(tokens[i]) {
                    authorParts.append(tokens[i])
                    i += 1
                }
                author = authorParts.joined(separator: " ")
                continue
            }
            i += 1
        }

        return .id(IdInfo(name: name, author: author))
    }

    private func isIdKeyword(_ token: String) -> Bool {
        return token == "name" || token == "author"
    }

    private func parseBestmove(tokens: [String]) throws -> UCIResponse {
        guard let move = tokens.first else {
            throw UCIError.parseError("bestmove without move")
        }

        var ponder: String?
        if tokens.count >= 3 && tokens[1] == "ponder" {
            ponder = tokens[2]
        }

        return .bestmove(move, ponder: ponder)
    }

    private func parseCopyprotection(tokens: [String]) throws -> UCIResponse {
        guard let statusStr = tokens.first,
              let status = CopyProtectionStatus(rawValue: statusStr) else {
            throw UCIError.parseError("Invalid copyprotection status")
        }
        return .copyprotection(status)
    }

    private func parseRegistration(tokens: [String]) throws -> UCIResponse {
        guard let statusStr = tokens.first,
              let status = RegistrationStatus(rawValue: statusStr) else {
            throw UCIError.parseError("Invalid registration status")
        }
        return .registration(status)
    }

    private func parseInfo(tokens: [String]) throws -> UCIResponse {
        var depth: Int?
        var seldepth: Int?
        var time: Int?
        var nodes: Int?
        var pv: [String]?
        var multipv: Int?
        var score: ScoreInfo?
        var currmove: String?
        var currmovenumber: Int?
        var hashfull: Int?
        var nps: Int?
        var tbhits: Int?
        var sbhits: Int?
        var cpuload: Int?
        var string: String?
        var refutation: [String]?
        var currline: [String]?

        var i = 0
        while i < tokens.count {
            let token = tokens[i]

            switch token {
            case "depth":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    depth = value
                    i += 2
                    continue
                }
            case "seldepth":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    seldepth = value
                    i += 2
                    continue
                }
            case "time":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    time = value
                    i += 2
                    continue
                }
            case "nodes":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    nodes = value
                    i += 2
                    continue
                }
            case "pv":
                var pvMoves: [String] = []
                i += 1
                while i < tokens.count && !isInfoKeyword(tokens[i]) {
                    pvMoves.append(tokens[i])
                    i += 1
                }
                if !pvMoves.isEmpty {
                    pv = pvMoves
                }
                continue
            case "multipv":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    multipv = value
                    i += 2
                    continue
                }
            case "score":
                // Parse score with optional bound
                if i + 2 < tokens.count {
                    let scoreType = tokens[i + 1]
                    if let scoreValue = Int(tokens[i + 2]) {
                        switch scoreType {
                        case "cp":
                            score = .cp(scoreValue)
                        case "mate":
                            score = .mate(scoreValue)
                        case "lowerbound":
                            score = .lowerbound(scoreValue)
                        case "upperbound":
                            score = .upperbound(scoreValue)
                        default:
                            break
                        }
                    }
                    i += 3
                    continue
                }
            case "currmove":
                if i + 1 < tokens.count {
                    currmove = tokens[i + 1]
                    i += 2
                    continue
                }
            case "currmovenumber":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    currmovenumber = value
                    i += 2
                    continue
                }
            case "hashfull":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    hashfull = value
                    i += 2
                    continue
                }
            case "nps":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    nps = value
                    i += 2
                    continue
                }
            case "tbhits":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    tbhits = value
                    i += 2
                    continue
                }
            case "sbhits":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    sbhits = value
                    i += 2
                    continue
                }
            case "cpuload":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    cpuload = value
                    i += 2
                    continue
                }
            case "string":
                var stringParts: [String] = []
                i += 1
                while i < tokens.count {
                    stringParts.append(tokens[i])
                    i += 1
                }
                if !stringParts.isEmpty {
                    string = stringParts.joined(separator: " ")
                }
                continue
            case "refutation":
                var refutationMoves: [String] = []
                i += 1
                while i < tokens.count && tokens[i] != "currline" {
                    refutationMoves.append(tokens[i])
                    i += 1
                }
                if !refutationMoves.isEmpty {
                    refutation = refutationMoves
                }
                continue
            case "currline":
                var currlineMoves: [String] = []
                i += 1
                // Skip optional cpu number
                if i < tokens.count, let _ = Int(tokens[i]) {
                    i += 1
                }
                while i < tokens.count {
                    currlineMoves.append(tokens[i])
                    i += 1
                }
                if !currlineMoves.isEmpty {
                    currline = currlineMoves
                }
                continue
            default:
                break
            }

            i += 1
        }

        return .info(InfoData(
            depth: depth,
            seldepth: seldepth,
            time: time,
            nodes: nodes,
            pv: pv,
            multipv: multipv,
            score: score,
            currmove: currmove,
            currmovenumber: currmovenumber,
            hashfull: hashfull,
            nps: nps,
            tbhits: tbhits,
            sbhits: sbhits,
            cpuload: cpuload,
            string: string,
            refutation: refutation,
            currline: currline
        ))
    }

    private func isInfoKeyword(_ token: String) -> Bool {
        let keywords = [
            "depth", "seldepth", "time", "nodes", "pv", "multipv",
            "score", "currmove", "currmovenumber", "hashfull", "nps",
            "tbhits", "sbhits", "cpuload", "string", "refutation", "currline"
        ]
        return keywords.contains(token)
    }

    private func parseOption(tokens: [String]) throws -> UCIResponse {
        // Parse option line format: option name NAME type TYPE [default DEFAULT] [min MIN] [max MAX] [var VAR]...
        var i = 0
        var name: String?
        var type: OptionType?
        var defaultValue: String?
        var min: Int?
        var max: Int?
        var varOptions: [String] = []

        while i < tokens.count {
            let token = tokens[i]

            switch token {
            case "name":
                var nameParts: [String] = []
                i += 1
                while i < tokens.count && tokens[i] != "type" {
                    nameParts.append(tokens[i])
                    i += 1
                }
                if !nameParts.isEmpty {
                    name = nameParts.joined(separator: " ")
                }
                continue
            case "type":
                if i + 1 < tokens.count {
                    type = OptionType(rawValue: tokens[i + 1])
                    i += 2
                } else {
                    i += 1
                }
                continue
            case "default":
                if i + 1 < tokens.count {
                    defaultValue = tokens[i + 1]
                    i += 2
                } else {
                    i += 1
                }
                continue
            case "min":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    min = value
                    i += 2
                } else {
                    i += 1
                }
                continue
            case "max":
                if i + 1 < tokens.count, let value = Int(tokens[i + 1]) {
                    max = value
                    i += 2
                } else {
                    i += 1
                }
                continue
            case "var":
                if i + 1 < tokens.count {
                    varOptions.append(tokens[i + 1])
                    i += 2
                } else {
                    i += 1
                }
                continue
            default:
                i += 1
            }
        }

        guard let name = name else {
            throw UCIError.parseError("Option missing name: \(tokens.joined(separator: " "))")
        }
        guard let type = type else {
            throw UCIError.parseError("Option '\(name)' missing type")
        }

        return .option(OptionConfig(
            name: name,
            type: type,
            defaultValue: defaultValue,
            min: min,
            max: max,
            varOptions: varOptions.isEmpty ? nil : varOptions
        ))
    }
}

// MARK: - UCI Serializer

/// Serializer for UCI protocol commands
public actor UCISerializer {
    public init() {}

    /// Serialize a UCI command to a string
    public func serialize(_ command: UCICommand) -> String {
        return command.description
    }

    /// Serialize multiple go commands
    public func serializeGoCommands(_ commands: [GoCommand]) -> String {
        let parts = commands.map { $0.description }
        return "go \(parts.joined(separator: " "))"
    }

    /// Serialize go parameters
    public func serializeGoParameters(_ params: GoParameters) -> String {
        return "go \(params)"
    }
}
