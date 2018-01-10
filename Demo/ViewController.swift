//
//  ViewController.swift
//  Demo
//
//  Created by Sam Smallman on 29/10/2017.
//  Copyright © 2017 artificeindustries. All rights reserved.
//

import Cocoa
import OSCKit


class ViewController: NSViewController, ClientDelegate {
    
    //    let server = Server()
    //    let parser = Parser()
    @IBOutlet var textView: NSTextView!
    
    let client = Client()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interfacse()
        
        //        server.port = 24601
        //        server.delegate = parser
        //        do {
        //            try server.startListening()
        //        } catch let error as NSError {
        //            print(error.localizedDescription)
        //        }
    }
    
    override func viewDidAppear() {
//        client.interface = "192.168.1.102"
        client.host = "192.168.1.101"
        client.port = 3032
        client.useTCP = true
        client.delegate = self
        do {
            try client.connect()
            print("Connecting")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    deinit {
        client.disconnect()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func clientDidConnect(client: Client) {
        print("CLient Did Connect")
    }
    
    func clientDidDisconnect(client: Client) {
        print("Client did Disconnect")
    }
    
    func interfacse() {
        for interface in Interface.allInterfaces() where !interface.isLoopback && interface.family == .ipv4 && interface.isRunning {
            textView.string += "\n*** Network Interface ***\n"
            textView.string += "Display Name: \(interface.displayName)\n"
            textView.string += "Name: \(interface.name)\n"
            textView.string += "IP Address: \(interface.address ?? "")\n"
            textView.string += "Subnet Mask: \(interface.netmask ?? "")\n"
            textView.string += "Broadcast Address: \(interface.broadcastAddress ?? "")\n"
            textView.string += "Display Text: \(interface.displayText)\n"
        }
    }
    
    
}


