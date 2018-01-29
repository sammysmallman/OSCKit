# OSCKit
A Swift framework for sending, receiving, and parsing OSC messages &amp; bundles.

Largely inspired and adapted from [Figure 53's F53OSC Library](https://github.com/Figure53/F53OSC). 

Added features include:
 * takeBundle() - OSCPacketDestinations are notified when an OSC bundle is received so that embedded messages and bundles can be acted upon asynchronously using the bundles timetag.
 * Multicasting - Servers can join & leave multicast groups.
 * OSC 1.0 & 1.1 Stream Framing.

For convenience, I've included a few public domain source files, Thanks and curiosity should rightfully be directed towards them:

[CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket).  
[Swift-Netutils](https://github.com/svdo/swift-netutils).



## Demo

Inluded is a small demo app "Demo"

## Quick Start
### OSC Client
#### Step 1
Import OSCKit framework into your project
```swift
import OSCKit
```
#### Step 2
Create client
```swift
let client = OSCClient()
client.interface = "en0"
client.host = "localhost"
client.port = 3001
client.useTCP = true
client.delegate = self
```
#### Step 3
Conform to the Client Delegate Protocol's 

OSCClientDelegate:
```swift
    func clientDidConnect(client: OSCClient) {
        print("Client did connect")
    }
    
    func clientDidDisconnect(client: OSCClient) {
        print("Client did disconnect")
    }
```    

OSCPacketDestination:
```swift
    func take(message: OSCMessage) {
        print("Received message - \(message.addressPattern)")
    }
    
    func take(bundle: OSCBundle) {
        print("Received bundle - time tag: \(bundle.timeTag.hex() elements: \(bundle.elements.count)")
    }
```   
#### Step 4
Create a message
```swift
let message = OSCMessage(messageWithAddressPattern: "/stamp/ping", arguments: [1, 3.142, "aStringArgument"])
```
#### Step 5
Send a message
```swift
client.send(packet: message)
```
