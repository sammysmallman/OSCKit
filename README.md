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

Inluded is a small demo app "Demp"
