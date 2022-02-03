<p align="center">
    <img src="osckit-icon.svg" width="256" align="middle" alt=“OSCKit”/>
</p>

# OSCKit
The OSCKit package provides the classes needed for your apps to communicate among computers, sound synthesizers, and other multimedia devices via [OSC](http://opensoundcontrol.org/README.html) over an IP network. 

## Overview
Use the OSCKit package to create client or server objects. In its simplest form a client can send a packet, either a [Message](http://opensoundcontrol.org/spec-1_0.html#osc-messages) or [Bundle](http://opensoundcontrol.org/spec-1_0.html#osc-bundles) to a server. A server, when listening, can receive these packets and action upon them. Depending on a client or server using either UDP or TCP as a transport, there are varying levels of fuctionality and delegate methods for you to take advantage of.

OSCKit implements all required argument types as specified in [OSC 1.1](http://opensoundcontrol.org/files/2009-NIME-OSC-1.1.pdf).

An example project can be found in [OSCKitDemo](https://github.com/sammysmallman/OSCKitDemo).

## License
OSCKit is licensed under the GNU Affero General Public License, version 3. If you require a commercial license for an application that you would not like to trigger AGPLv3 obligations (e.g. open sourcing your application), please get in touch. The probability of obtaining a commerical license for free is high.

## Features

- UDP and TCP Transport options
- UDP Servers can join multicast groups
- UDP Clients can broadcast packets
- UDP Peer (A shared socket for sending and receiving OSC packets on)
- TCP Server with client management
- TCP Stream Framing
- OSC Bundles
- OSC Timetags

## Installation

#### Xcode 11+
[Add the package dependency](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) to your Xcode project using the following repository URL: 
``` 
https://github.com/SammySmallman/OSCKit
```
#### Swift Package Manager

Add the package dependency to your Package.swift and depend on "OSCKit" in the necessary targets:

```  swift
dependencies: [
    .package(url: "https://github.com/SammySmallman/OSCKit", .upToNextMajor(from: "3.1.0"))
]
```

#### App Sandbox Network Settings
- Enable Incoming Connections *(Required for OSCTcpClient, OSCTcpServer, OSCUdpPeer & OSCUdpServer)*
- Enable Outgoing Connections *(Required for OSCTcpClient, OSCTcpServer, OSCUdpPeer & OSCUdpClient)*

## Quick Start

<details closed>
  <summary>TCP Client</summary>
    <h4>Step 1</h4>
    
Import OSCKit into your project 
```swift
import OSCKit
```
    
<h4>Step 2</h4>
    
Create a client
```swift
let client = OSCTcpClient(host: "10.101.130.101",
                          port: 24601,
                          streamFraming: .SLIP,
                          delegate: self)
```
    
<h4>Step 3</h4>
    
Conform to the clients delegate protocol OSCTcpClientDelegate:
```swift
func client(_ client: OSCTcpClient,
            didConnectTo host: String,
            port: UInt16) {
    print("Client did connect to \(host):\(port)")
}

func client(_ client: OSCTcpClient,
            didDisconnectWith error: Error?) {
    if let error = error {
       print("Client did disconnect with error: \(error.localizedDescription)")
    } else {
       print("Client did disconnect")
    }
}

func client(_ client: OSCTcpClient,
            didSendPacket packet: OSCPacket) {
    print("Client did send packet")
}
    
func client(_ client: OSCTcpClient,
            didReceivePacket packet: OSCPacket) {
    print("Client did receive packet")
}
    
func client(_ client: OSCTcpClient,
            didReadData data: Data,
            with error: Error) {
    print("Client did read data with error: \(error.localizedDescription)"
}
```    
  
<h4>Step 4</h4>
    
Create an OSCPacket e.g. An OSC message:
```swift
do {
    let message = try OSCMessage(with: "/osc/kit", arguments: [1,
                                                               3.142,
                                                               "hello world!"])
} catch {
    print("Unable to create OSCMessage: \(error.localizedDescription)")
}
```
    
<h4>Step 5</h4>
    
Send the packet
```swift
client.send(message)
```
</details>
<details closed>
  <summary>TCP Server</summary>
    <h4>Step 1</h4>
    
Import OSCKit into your project 
```swift
import OSCKit
```
    
<h4>Step 2</h4>
    
Create a client
```swift
let server = OSCTcpServer(port: 24601,
                          streamFraming: .SLIP,
                          delegate: self)
```
    
<h4>Step 3</h4>
    
Conform to the servers delegate protocol OSCTcpServerDelegate:
```swift
func server(_ server: OSCTcpServer,
            didConnectToClientWithHost host: String,
            port: UInt16) {
    print("Server did connect to client \(host):\(port)")
}

func server(_ server: OSCTcpServer,
            didDisconnectFromClientWithHost host: String,
            port: UInt16) {
    print("Server did disconnect from client \(host):\(port)")
}

func server(_ server: OSCTcpServer,
            didReceivePacket packet: OSCPacket,
            fromHost host: String,
            port: UInt16) {
    print("Server did receive packet")
}
    
func server(_ server: OSCTcpServer,
            didSendPacket packet: OSCPacket,
            toClientWithHost host: String,
            port: UInt16) {
    print("Server did send packet to \(host):\(port)")
}
    
func server(_ server: OSCTcpServer,
            socketDidCloseWithError error: Error?) {
    if let error = error {
       print("Server did stop listening with error: \(error.localizedDescription)")
    } else {
       print("Server did stop listening")
    }
}
    
func server(_ server: OSCTcpServer,
            didReadData data: Data,
            with error: Error) {
    print("Server did read data with error: \(error.localizedDescription)")
}
```    
  
<h4>Step 4</h4>
    
Start listening for new connections and packets:
```swift
do {
    try server.startListening()
} catch {
    print(error.localizedDescription)
}
```
</details>
<details closed>
  <summary>UDP Client</summary>
    <h4>Step 1</h4>
    
Import OSCKit into your project 
```swift
import OSCKit
```
    
<h4>Step 2</h4>
    
Create a client
```swift
let client = OSCUdpClient(host: "10.101.130.101",
                          port: 24601,
                          delegate: self)
```
    
<h4>Step 3</h4>
    
Conform to the clients delegate protocol OSCUdpClientDelegate:
```swift
func client(_ client: OSCUdpClient,
            didSendPacket packet: OSCPacket,
            fromHost host: String?,
            port: UInt16?) {
    print("Client sent packet to \(client.host):\(client.port)")
}

func client(_ client: OSCUdpClient,
            didNotSendPacket packet: OSCPacket,
            fromHost host: String?,
            port: UInt16?,
            error: Error?) {
    print("Client did not send packet to \(client.host):\(client.port)")
}

func client(_ client: OSCUdpClient,
            socketDidCloseWithError error: Error) {
    print("Client Error: \(error.localizedDescription)")
}
```    
  
<h4>Step 4</h4>
    
Create an OSCPacket e.g. An OSC message:
```swift
do {
    let message = try OSCMessage(with: "/osc/kit", arguments: [1,
                                                               3.142,
                                                               "hello world!"])
} catch {
    print("Unable to create OSCMessage: \(error.localizedDescription)")
}

```
    
<h4>Step 5</h4>
    
Send the packet
```swift
client.send(message)
```
</details>
<details closed>
  <summary>UDP Server</summary>
    <h4>Step 1</h4>
    
Import OSCKit into your project 
```swift
import OSCKit
```
    
<h4>Step 2</h4>
    
Create a client
```swift
let server = OSCUdpServer(port: 24601,
                          delegate: self)
```
    
<h4>Step 3</h4>
    
Conform to the servers delegate protocol OSCUdpServerDelegate:
```swift
func server(_ server: OSCUdpServer,
            didReceivePacket packet: OSCPacket,
            fromHost host: String,
            port: UInt16) {
    print("Server did receive packet from \(host):\(port)")
}

func server(_ server: OSCUdpServer,
            socketDidCloseWithError error: Error?) {
    if let error = error {
       print("Server did stop listening with error: \(error.localizedDescription)")
    } else {
       print("Server did stop listening")
    }
}

func server(_ server: OSCUdpServer,
            didReadData data: Data,
            with error: Error) {
    print("Server did read data with error: \(error.localizedDescription)")
}
```    
  
<h4>Step 4</h4>
    
Start listening for packets:
```swift
do {
    try server.startListening()
} catch {
    print(error.localizedDescription)
}
```
</details>

<details closed>
  <summary>UDP Peer</summary>
    <h4>Step 1</h4>
    
Import OSCKit into your project
```swift
import OSCKit
```
    
<h4>Step 2</h4>
    
Create a peer
```swift
let peer = OSCUdpPeer(host: "10.101.130.101",
                      port: 24601,
                      hostPort: 3001)
```
    
<h4>Step 3</h4>
    
Conform to the peers delegate protocol OSCUdpPeerDelegate:
```swift
    func peer(_ peer: OSCUdpPeer, didReceivePacket packet: OSCPacket, fromHost host: String, port: UInt16) {
        print("Peer did receive packet from \(host):\(port)")
    }

    func peer(_ peer: OSCUdpPeer, didReadData data: Data, with error: Error) {
        print("Peer did read data with error: \(error.localizedDescription)")
    }

    func peer(_ peer: OSCUdpPeer, didSendPacket packet: OSCPacket, fromHost host: String?, port: UInt16?) {
        print("Peer sent packet to \(peer.host):\(peer.hostPort) from \(host):\(port)")
    }

    func peer(_ peer: OSCUdpPeer, didNotSendPacket packet: OSCPacket, fromHost host: String?, port: UInt16?, error: Error?) {
        print("Peer did not send packet to \(peer.host):\(peer.hostPort) from \(host):\(port)")
    }

    func peer(_ peer: OSCUdpPeer, socketDidCloseWithError error: Error?) {
        print("Peer Error: \(error.localizedDescription)")
    }
```
  
<h4>Step 4</h4>
    
Create an OSCPacket e.g. An OSC message:
```swift
do {
    let message = try OSCMessage(with: "/osc/kit", arguments: [1,
                                                               3.142,
                                                               "hello world!"])
} catch {
    print("Unable to create OSCMessage: \(error.localizedDescription)")
}
```
    
<h4>Step 5</h4>
    
Send the packet
```swift
peer.send(message)
```
</details>

## CoreOSC

OSCKit is supported by the infrastructural code provided by [CoreOSC](https://github.com/sammysmallman/CoreOSC). For more detailed information pertaining to the OSC objects that OSCKit uses, such as Address Patterns, Messages and Bundles, please direct all queries to [CoreOSC](https://github.com/sammysmallman/CoreOSC).

## Authors

**Sammy Smallman** - *Initial Work* - [SammySmallman](https://github.com/sammysmallman)

See also the list of [contributors](https://github.com/SammyTheHand/OSCKit/graphs/contributors) who participated in this project.

## Acknowledgments

* Socket library dependency [CocoaSyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)
* Network Interface library dependency [Swift-Netutils](https://github.com/svdo/swift-netutils).
