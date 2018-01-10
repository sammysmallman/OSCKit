# OSCKit
A Swift framework for sending, receiving, and parsing OSC messages &amp; bundles.

Largely inspired and adapted from [Figure 53's F53OSC Library](https://github.com/Figure53/F53OSC). 

Added features include:
 * takeBundle() - OSCPacketDestinations are notified when an OSC bundle is received as well as individual OSC Messages with takeMessage()
 * Multicasting - Server can join multicast group.
 * OSC 1.0 & 1.1 Stream Framing.

For convenience, we've included a few public domain source files:

[CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket).  
[Swift-Netutils](https://github.com/svdo/swift-netutils).

Thanks and curiosity should rightfully be directed to towards them.

## Demo

Inluded is a small demo app "Demp"
