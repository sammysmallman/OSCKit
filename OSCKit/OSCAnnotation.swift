//
//  OSCAnnotation.swift
//  OSCKit
//
//  Created by Sam Smallman on 29/10/2017.
//  Copyright © 2017 Sam Smallman. http://sammy.io
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Cocoa

extension String {
    /// An `NSRange` that represents the full range of the string.
    var nsrange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }
    var doubleValue: Double? {
        return Double(self)
    }
    var floatValue: Float? {
        return Float(self)
    }
    var integerValue: Int? {
        return Int(self)
    }
    var isNumber: Bool {
        if let _ = Double(self) {
            return true
        } else {
            return false
        }
    }
    
    func substring(with nsrange: NSRange) -> Substring? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return self[range]
    }
}

public class OSCAnnotation {
    
    public enum AnnotationStyle {
        // Equals/Comma Seperated Arguments: /an/address/pattern=1,3.142,"A string argument with spaces",String
        case equalsComma
        // Spaces Seperated Arguments: /an/address/pattern 1 3.142 "A string argument with spaces" String
        case spaces
    }
    
    public func isValid(annotation: String, with style: AnnotationStyle) -> Bool {
        switch style {
        case .equalsComma:
            let equalsCommaRegex = "^(\\/[^ \\#*,?\\[\\]{}=]+)((?:=\"[^\"]+\")|(?:=[^\\s\",]+)){0,1}((?:(?:,\"[^\"]+\")|(?:,[^\\s\"=,]+))*)"
            let predicate = NSPredicate(format: "SELF MATCHES %@", equalsCommaRegex)
            return predicate.evaluate(with: annotation)
        case .spaces:
            let spacesRegex = "^(\\/(?:[^ \\#*,?\\[\\]{}]+))((?:(?: \"[^\"]+\")|(?: (?:[^\\s\"])+))*)"
            let predicate = NSPredicate(format: "SELF MATCHES %@", spacesRegex)
            return predicate.evaluate(with: annotation)
        }
    }
    
    public static func oscMessage(for annotation: String, with style: AnnotationStyle) -> OSCMessage? {
        switch style {
        case .equalsComma:
            do {
                let equalsCommaRegex = "^(\\/[^ \\#*,?\\[\\]{}=]+)((?:=\"[^\"]+\")|(?:=[^\\s\",]+)){0,1}((?:(?:,\"[^\"]+\")|(?:,[^\\s\"=,]+))*)"
                let regularExpression = try NSRegularExpression(pattern: equalsCommaRegex, options: [])
                let matches = regularExpression.matches(in: annotation, options: [], range: annotation.nsrange)
                // There should only be one match. Range at index 1 will always be the address pattern. If there are arguments these will be found at index 2, prefaced with "=" and index 3 if there are more than one argument.
                var oscArguments: [Any] = []
                guard let match = matches.first, match.range == annotation.nsrange, let addressPattern = annotation.substring(with: match.range(at: 1)) else { return nil }
                if var argumentString = annotation.substring(with: match.range(at: 2)) {
                    // remove the "="
                    argumentString.removeFirst()
                    if let moreArguments = annotation.substring(with: match.range(at: 3)) {
                        argumentString += moreArguments
                    }
                    let argumentComponents = argumentString.components(separatedBy: ",")
                    for argument in argumentComponents {
                        if argument.isNumber {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            if let numberArgument = formatter.number(from: argument) {
                                oscArguments.append(numberArgument)
                            }
                        } else {
                            switch argument {
                            case "true":
                                oscArguments.append(OSCArgument.oscTrue)
                            case "false":
                                oscArguments.append(OSCArgument.oscFalse)
                            case "nil":
                                oscArguments.append(OSCArgument.oscNil)
                            case "impulse":
                                oscArguments.append(OSCArgument.oscImpulse)
                            default:
                                // if the argument is prefaced with quotation marks, the regex dictates the argument should close with them.
                                // Remove the quotation marks.
                                if argument.first == "\"" {
                                    var quoationMarkArgument = argument
                                    quoationMarkArgument.removeFirst()
                                    quoationMarkArgument.removeLast()
                                    oscArguments.append(quoationMarkArgument)
                                } else {
                                    oscArguments.append(argument)
                                }
                            }
                            
                        }
                    }
                }
                return OSCMessage(messageWithAddressPattern: String(addressPattern), arguments: oscArguments)
            } catch {
                return nil
            }
        case .spaces:
            do {
                let spacesRegex = "^(\\/(?:[^ \\#*,?\\[\\]{}]+))((?:(?: \"[^\"]+\")|(?: (?:[^\\s\"])+))*)"
                let regularExpression = try NSRegularExpression(pattern: spacesRegex, options: [])
                let matches = regularExpression.matches(in: annotation, options: [], range: annotation.nsrange)
                // There should only be one match. Range at index 1 will always be the address pattern. Range at index 2 will be the argument string prefaced with " "
                var oscArguments: [Any] = []
                guard let match = matches.first, match.range == annotation.nsrange, let addressPattern = annotation.substring(with: match.range(at: 1)), let argumentString = annotation.substring(with: match.range(at: 2)) else { return nil }
                let components = argumentString.components(separatedBy: "\"")
                var argumentsArray: [String] = []
                for (index, component) in components.enumerated() {
                    if index % 2 != 0 {
                        argumentsArray.append(component)
                    } else {
                        let arguments = component.split(separator: " ", omittingEmptySubsequences: true)
                        for element in arguments {
                            argumentsArray.append(String(element))
                        }
                    }
                }
                for argument in argumentsArray {
                    if argument.isNumber {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        if let numberArgument = formatter.number(from: argument) {
                            oscArguments.append(numberArgument)
                        }
                    } else {
                        switch argument {
                        case "true":
                            oscArguments.append(OSCArgument.oscTrue)
                        case "false":
                            oscArguments.append(OSCArgument.oscFalse)
                        case "nil":
                            oscArguments.append(OSCArgument.oscNil)
                        case "impulse":
                            oscArguments.append(OSCArgument.oscImpulse)
                        default:
                            // if the argument is prefaced with quotation marks, the regex dictates the argument should close with them.
                            // Remove the quotation marks.
                            if argument.first == "\"" {
                                var quoationMarkArgument = argument
                                quoationMarkArgument.removeFirst()
                                quoationMarkArgument.removeLast()
                                oscArguments.append(quoationMarkArgument)
                            } else {
                                oscArguments.append(argument)
                            }
                        }
                        
                    }
                }
                return OSCMessage(messageWithAddressPattern: String(addressPattern), arguments: oscArguments)
            } catch {
                return nil
            }
        }
    }
    
    public static func annotation(for message: OSCMessage, with style: AnnotationStyle, andType type: Bool) -> String {
        var string = message.addressPattern
        var argumentIndex = 0
        switch style {
        case .equalsComma:
            if message.typeTagString.count > 1 {
                string += "="
            }
            for typeTag in message.typeTagString {
                switch typeTag {
                case "s":
                    if let stringArg = message.arguments[argumentIndex] as? String {
                        if stringArg.contains(" ") {
                            string += "\"\(stringArg)\""
                        } else {
                            string += "\(stringArg)"
                        }
                        if type {
                            string += "(s),"
                        } else {
                            string += ","
                        }
                        argumentIndex += 1
                    }
                case "b":
                    if let blobArg = message.arguments[argumentIndex] as? Data {
                        string += "Bytes:\(blobArg.count)"
                        if type {
                            string += "(b),"
                        } else {
                            string += ","
                        }
                        argumentIndex += 1
                    }
                case "i":
                    if let intArg = message.arguments[argumentIndex] as? NSNumber {
                        string += "\(intArg)"
                        if type {
                            string += "(i),"
                        } else {
                            string += ","
                        }
                        argumentIndex += 1
                    }
                case "f":
                    if let floatArg = message.arguments[argumentIndex] as? NSNumber {
                        string += "\(floatArg)"
                        if type {
                            string += "(f),"
                        } else {
                            string += ","
                        }
                        argumentIndex += 1
                    }
                case "t":
                    if let timeTagArg = message.arguments[argumentIndex] as? OSCTimeTag {
                        string += "\(timeTagArg.hex())"
                        if type {
                            string += "(t),"
                        } else {
                            string += ","
                        }
                        argumentIndex += 1
                    }
                case "T":
                    string += "true"
                    if type {
                        string += "(T),"
                    } else {
                        string += ","
                    }
                case "F":
                    string += "false"
                    if type {
                        string += "(F),"
                    } else {
                        string += ","
                    }
                case "N":
                    string += "nil"
                    if type {
                        string += "(N),"
                    } else {
                        string += ","
                    }
                case "I":
                    string += "impulse"
                    if type {
                        string += "(I),"
                    } else {
                        string += ","
                    }
                default: break
                }
            }
            if message.typeTagString.count > 1 {
                string.removeLast()
            }
        case .spaces:
            for typeTag in message.typeTagString {
                switch typeTag {
                case "s":
                    if let stringArg = message.arguments[argumentIndex] as? String {
                        if stringArg.contains(" ") {
                            string += " \"\(stringArg)\""
                        } else {
                            string += " \(stringArg)"
                        }
                        if type {
                            string += "(s)"
                        }
                        argumentIndex += 1
                    }
                case "b":
                    if let blobArg = message.arguments[argumentIndex] as? Data {
                        string += " Bytes:\(blobArg.count)"
                        if type {
                            string += "(b)"
                        }
                        argumentIndex += 1
                    }
                case "i":
                    if let intArg = message.arguments[argumentIndex] as? NSNumber {
                        string += " \(intArg)"
                        if type {
                            string += "(i)"
                        }
                        argumentIndex += 1
                    }
                case "f":
                    if let floatArg = message.arguments[argumentIndex] as? NSNumber {
                        string += " \(floatArg)"
                        if type {
                            string += "(f)"
                        }
                        argumentIndex += 1
                    }
                case "t":
                    if let timeTagArg = message.arguments[argumentIndex] as? OSCTimeTag {
                        string += " \(timeTagArg.hex())"
                        if type {
                            string += "(t)"
                        }
                        argumentIndex += 1
                    }
                case "T":
                    string += " true"
                    if type {
                        string += "(T)"
                    }
                case "F":
                    string += " false"
                    if type {
                        string += "(F)"
                    }
                case "N":
                    string += " nil"
                    if type {
                        string += "(N)"
                    }
                case "I":
                    string += " impulse"
                    if type {
                        string += "(I)"
                    }
                default: break
                }
            }
        }
        return string
    }
    
    private func isNumeric(character: Character) -> Bool {
        return Double("\(character)") != nil
    }
    
    private func isNumeric(string: String) -> Bool {
        return Double(string) != nil
    }
    
}
