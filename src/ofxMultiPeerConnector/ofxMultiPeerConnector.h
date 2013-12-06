//
//  ofxMultiPeerConnector.h
//  Grit
//
//  Created by Zach Gage on 7/13/13.
//
//

#ifndef __Grit__ofxMultiPeerConnector__
#define __Grit__ofxMultiPeerConnector__

#include "ofMain.h"
#include "ofxiPhoneExtras.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "SessionContainer.h"


#pragma once

class ofxMultiPeerConnector;

@interface ofxMultiPeerDelegate : NSObject <MCBrowserViewControllerDelegate, SessionContainerDelegate>
{
	ofxMultiPeerConnector * owner;
}

- (ofxMultiPeerDelegate*) initWithOwner:(ofxMultiPeerConnector *) own;

@end


class ofxMultiPeerConnector {
	
public:
	
	ofxMultiPeerConnector(NSString * service, string user = "", int minP = kMCSessionMinimumNumberOfPeers, int maxP = kMCSessionMaximumNumberOfPeers);
	void showPeerPicker();
	~ofxMultiPeerConnector();
	
	ofxMultiPeerDelegate * delegate;
	SessionContainer * sessionContainer;
	
	bool sendData(void * data, int length);
	
	NSString * serviceName;
	string playerName;
	bool ready;
	int minPlayers;
	int maxPlayers;
};

#endif /* defined(__Grit__ofxMultiPeerConnector__) */
