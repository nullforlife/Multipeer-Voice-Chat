//
//  MultipeerHandler.swift
//  Multipeer Voice Chat
//
//  Created by Oskar Jönsson on 2016-10-10.
//  Copyright © 2016 Oskar Jönsson. All rights reserved.
//

import Foundation
import MultipeerConnectivity

/* Class for handling the Multipeer connectivity framework */


class MultipeerHandler : NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var peerID : MCPeerID!
    var mcSession : MCSession!
    var mcBrowser : MCNearbyServiceBrowser?
    var mcAdvertiser : MCNearbyServiceAdvertiser?
    
    var viewController : ViewController!
    
    
    init(sender: ViewController){
        super.init()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID!, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        viewController = sender
        
    }
    
    
    
    
    /* Methods for joining another peer's session or starting a session for other peer's to join */
    
    func startHosting() {
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: peerID!, discoveryInfo: nil, serviceType: "bt-voip")
        mcAdvertiser?.delegate = self
        mcAdvertiser?.startAdvertisingPeer()
    }
    
    func joinSession() {
        mcBrowser = MCNearbyServiceBrowser(peer: peerID!, serviceType: "bt-voip")
        mcBrowser?.delegate = self
        mcBrowser?.startBrowsingForPeers()
    }
    
    
    
    
    
    
    /* Delegate methods for advertising to peers */
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        //receives an invitation from a peer who wants to join an accepts the invite and let that peer join the session
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        
    }
    
    
    
    
    
    /* Delegate methods for browsing peers */
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        mcBrowser?.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
        mcBrowser?.stopBrowsingForPeers()
        mcAdvertiser?.stopAdvertisingPeer()
    }
    
    
    /* Delegate methods for receiving certificates and resources (images, videos, documents) */
    
    
    fileprivate func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
    
    
    /* Delegate method for checking wether peers connects or disconnects */
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        
        switch state {
        case MCSessionState.connected:
            print("Connected \(peerID.displayName)")
            
            DispatchQueue.main.async {
                self.viewController.onlineStatus.textColor = UIColor.green
            }
            
        case MCSessionState.connecting:
            print("Connecting \(peerID.displayName)")
            
            
        case MCSessionState.notConnected:
            print("Not connected\(peerID.displayName)")
            DispatchQueue.main.async {
                self.viewController.onlineStatus.textColor = UIColor.red
            }
            startHosting()
            joinSession()
        }
    }
    
    /* Delegate method for receiving data, i.e. a String as Data for chat functionality */
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    
    
    /* Delegate method for receiving streams */
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        if streamName == "voice" {
            
            viewController.inputStream = stream
            viewController.inputStream .delegate = viewController
            
            viewController.inputStream.schedule(in: RunLoop.main, forMode: .defaultRunLoopMode)
            viewController.inputStream.open()
            
        }
    }
    
    
}


