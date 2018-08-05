//
//  ViewController.swift
//  Demo
//
//  Created by Sam Smallman on 29/10/2017.
//  Copyright © 2017 artificeindustries. All rights reserved.
//

import Cocoa
import OSCKit


class ViewController: NSViewController, OSCClientDelegate, OSCPacketDestination {
    
    let server = OSCServer()
    
    @IBOutlet var textView: NSTextView!
    
    let client = OSCClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interfaces()
        
        server.port = 24601
        server.delegate = self
        do {
            try server.startListening()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidAppear() {
        client.host = "172.20.10.2"
        //        client.interface = "en0"
        client.streamFraming = .PLH
        client.port = 3032
        client.useTCP = true
        client.delegate = self
        do {
            try client.connect()
            print("Connecting")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
//        let annotation = "/an/address/pattern=1,impulse,3.142,nil,\"a string argument with spaces\",string,true,false"
        let annotation = "/an/address/pattern \"the first string argument with spaces\" 1 impulse 3.142 nil \"a second string argument with spaces\" string true false \"a third string argument with spaces\""
        print("Annotation Input: \(annotation)")
        if let oscMessage = OSCAnnotation.oscMessage(for: annotation, with: .spaces) {
            print("Annotation Output: \(OSCAnnotation.annotation(for: oscMessage, with: .spaces, andType: true))")
        }
        
        //        let aMessage = OSCMessage(messageWithAddressPattern: "/stamp/is/here", arguments: [1,3.142,"string","string with spaces"])
        //        print(OSCAnnotation.annotation(for: aMessage, with: .equalsComma, andType: true))
        
    }
    
    //    deinit {
    //        client.disconnect()
    //    }

    
    func clientDidConnect(client: OSCClient) {
        print("CLient Did Connect")
    }
    
    func clientDidDisconnect(client: OSCClient) {
        print("Client did Disconnect")
    }
    
    func interfaces() {
        for interface in Interface.allInterfaces() where !interface.isLoopback && interface.family == .ipv4 && interface.isRunning {
            textView.string += "\n*** Network Interface ***\n"
            textView.string += "Display Name: \(interface.displayName)\n"
            textView.string += "Name: \(interface.name)\n"
            textView.string += "IP Address: \(interface.address ?? "")\n"
            textView.string += "Subnet Mask: \(interface.netmask ?? "")\n"
            textView.string += "Broadcast Address: \(interface.broadcastAddress ?? "")\n"
            textView.string += "Display Text: \(interface.displayText)\n\n"
        }
    }
    
    func take(bundle: OSCBundle) {
        textView.string += "[\(bundle.timeTag.hex())\n"
        var indent = 0
        write(bundle, withIndent: &indent)
        textView.string += "]\n\n"
    }
    
    func write(_ bundle: OSCBundle, withIndent indent: inout Int) {
        indent += 1
        let stringIndent = String(repeating: "\t", count: indent)
        for element in bundle.elements {
            if element is OSCMessage {
                guard let message = element as? OSCMessage else { return }
                write(message, withIndent: indent)
            } else if element is OSCBundle {
                guard let bundledBundle = element as? OSCBundle else { return }
                textView.string += "\(stringIndent)[\(bundle.timeTag.hex())\n"
                write(bundledBundle, withIndent: &indent)
                textView.string += "\(stringIndent)]\n"
            }
        }
        indent -= 1
    }
    
    func write(_ message: OSCMessage, withIndent indent: Int) {
        let stringIndent = String(repeating: "\t", count: indent)
        textView.string += "\(stringIndent)\(message.addressPattern)\n"
    }
    
    func take(message: OSCMessage) {
        write(message, withIndent: 0)
        textView.string += "\n"
    }
    
    @IBAction func clearLog(_ sender: Any) {
        textView.string = ""
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        let message = OSCMessage(messageWithAddressPattern: "/eos/ping", arguments: [])
        client.send(packet: message)
    }
}


