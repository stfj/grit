/*
 *  ofxiPhoneImagePicker.cpp
 *  iPhone UIImagePicker Example
 *
 *  Created by Zach Gage on 3/1/09.
 *  Copyright 2009 stfj. All rights reserved.
 *
 */

#import "ofxiPhoneGameKit.h"
#include "testApp.h"

//C++ class implementations

//--------------------------------------------------------------
ofxiPhoneGameKit::ofxiPhoneGameKit()
{
	gameKit = nil;
	connected = false;
	peerPickerOpen = false;
	server=false;
}

//--------------------------------------------------------------
ofxiPhoneGameKit::~ofxiPhoneGameKit()
{
	if(gameKit != nil)
		[gameKit release];
}

//----------------------------------------------------------------

void ofxiPhoneGameKit::resetCoinFlipComplete()
{
	[gameKit resetCointFlipComplete];
}
void ofxiPhoneGameKit::addListener(testApp * delegate)
{
	gameKit = [[ofxiPhoneGameKitObjCDelegate alloc] initWithDelegate:delegate andGameKit:this];
}

//----------------------------------------------------------------

void ofxiPhoneGameKit::addListener(testApp * delegate, string name)
{
	gameKit = [[ofxiPhoneGameKitObjCDelegate alloc] initWithDelegate:delegate andGameKit:this andName:name];
}

//----------------------------------------------------------------
bool ofxiPhoneGameKit::sendData(void * dataToSend, int length)
{
	if(readyToSendData)
	{
		[gameKit sendData:[NSData dataWithBytes:dataToSend length:length]];
		return true;
	}
	else
		return false;
}

//----------------------------------------------------------------

bool ofxiPhoneGameKit::isReady()
{
	return readyToSendData;
}

//----------------------------------------------------------------
void ofxiPhoneGameKit::showPeerPicker()
{
	connected = false;
	peerPickerOpen = false;
	server=false;
	[gameKit showPeerPicker];
}

//----------------------------------------------------------------

bool ofxiPhoneGameKit::isConnected()
{
	return connected;
}
//----------------------------------------------------------------
bool ofxiPhoneGameKit::isServer()
{
	return server;
}
//----------------------------------------------------------------

bool ofxiPhoneGameKit::isPeerPickerOpen()
{
	return peerPickerOpen;
}
//----------------------------------------------------------------

void ofxiPhoneGameKit::setConnected(bool b)
{
	connected = b;
}
//----------------------------------------------------------------
void ofxiPhoneGameKit::setServer(bool s)
{
	server=s;
}
//----------------------------------------------------------------
void ofxiPhoneGameKit::disconnect()
{
	[gameKit disconnect];
}
//----------------------------------------------------------------
void ofxiPhoneGameKit::setReady(bool r)
{
	readyToSendData = r;
}
//----------------------------------------------------------------

void ofxiPhoneGameKit::setPeerPickerOpen(bool b)
{
	peerPickerOpen = b;
}
//----------------------------------------------------------------


// CLASS IMPLEMENTATIONS--------------objc------------------------
//----------------------------------------------------------------
@implementation ofxiPhoneGameKitObjCDelegate

@synthesize mSession;

- (id) initWithDelegate:(testApp *) _cppDelegate andGameKit:(ofxiPhoneGameKit *)_gameKit
{
	if(self = [super init])
	{
		cppDelegate = _cppDelegate;
		sessionName = @"ofxiPhone";
		gameKit = _gameKit;
		mPeers=[[NSMutableArray alloc] init];
		coinFlipComplete = false;
		myCoinFlipNumber = ofRandomuf(); // generate a number between 0 and 1 to decide who is acting as the server.
	}
	return self;
}

- (id) initWithDelegate:(testApp *) _cppDelegate andGameKit:(ofxiPhoneGameKit *)_gameKit andName:(string)name
{
	if(self = [super init])
	{
		cppDelegate = _cppDelegate;
		//mPicker=[[GKPeerPickerController alloc] init];
		//mPicker.delegate=self;
		//mPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby | GKPeerPickerConnectionTypeOnline;
		
		mPeers=[[NSMutableArray alloc] init];
		coinFlipComplete = false;
		myCoinFlipNumber = ofRandomuf(); // generate a number between 0 and 1 to decide who is acting as the server.
		
		if(sessionName!=nil)
			[sessionName release];
		sessionName = [[NSString alloc] initWithCString: name.c_str()];
		gameKit=_gameKit;
	}
	return self;
}
//--------------------------------------------------------------

- (void)dealloc 
{ 
	if(sessionName!=nil)
		[sessionName release];
	[mPeers release];
	[super dealloc];
}

//--------------------------------------------------------------

- (void) sendData:(NSData *)dataToSend
{
	[mSession sendData:dataToSend toPeers:mPeers withDataMode:GKSendDataReliable error:nil];
}

//--------------------------------------------------------------

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
	testApp * cppDelegate = (testApp *)ofGetAppPtr();
	
	
	if(data != NULL)
	{
		gameKit->setReady(true);
		cppDelegate->recievedData([data bytes], [data length]); // if we've figured out the server, pass along the data to the app
		/*if(coinFlipComplete)
			cppDelegate->recievedData([data bytes], [data length]); // if we've figured out the server, pass along the data to the app
		else
		{// time to figure out who is acting as the server.
			
			setupInformation setup;
			memcpy(&setup,[data bytes],[data length]);
			
			
			if(myCoinFlipNumber > setup.coinFlip)
			{
				gameKit->setServer(true);
				coinFlipComplete = true;
				gameKit->setReady(true);
				
			}
			else if(myCoinFlipNumber <= setup.coinFlip)
			{
				gameKit->setServer(false);
				coinFlipComplete = true;
				gameKit->setReady(true);
				
			}
			else // equal picks, flip again. // not using the coin flip anyway, seems to be messing stuff up for some reason, so im gonna turn it off
			{
				myCoinFlipNumber = ofRandomuf(); // generate a number between 0 and 1 to decide who is acting as the server.
				
				setupInformation p;
				p.coinFlip = myCoinFlipNumber;
				p.randomSeed = ofRandom(0,100);
				myRandomSeed = p.randomSeed;
				p.iPhone = false; // iPad
				
				if(ofGetWidth() == 320 || ofGetWidth() == 640)
					p.iPhone = true; // iPhone
				
				[self sendData:[NSData dataWithBytes:(void *)&p length:sizeof(setupInformation)] ];
			}
		}
	} else {
		gameKit->setServer(false);
		coinFlipComplete = true;
		gameKit->setReady(true);
		
		//ofSeedRandom(setup.randomSeed);
		cppDelegate->startRushAssaultMode();
		// start anyway?
	}*/

}

//----------------------------------------------------------------

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type
{		
	
	GKSession* session = [[GKSession alloc] initWithSessionID:sessionName displayName:nil sessionMode:GKSessionModePeer];
    [session autorelease];
    return session;
}

//----------------------------------------------------------------

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
	
	testApp * cppDelegate = (testApp *)ofGetAppPtr();
	//testApp * cppDelegate = &app->game;
	
	switch (state)
    {
        case GKPeerStateConnected:
		{
			cppDelegate->playingiPhone = false;
			[mPeers addObject:peerID];
			gameKit->setConnected(true);
			cout<<"connected!"<<endl;
			
			//flip coin
			setupInformation p;
			p.coinFlip = myCoinFlipNumber;
			p.randomSeed = ofRandom(0,100);
			myRandomSeed = p.randomSeed;
			p.iPhone = false; // iPad
			
			if(ofGetWidth() == 320 || ofGetWidth() == 640)
				p.iPhone = true; // iPhone
			
			[self sendData:[NSData dataWithBytes:(void *)&p length:sizeof(setupInformation)] ];
			
			
			break;
		}
        case GKPeerStateDisconnected:
		{
			[mPeers removeObject:peerID];
			gameKit->setConnected(false);
			cout<<"disconnected!"<<endl;
			
			//reset coin flip
			coinFlipComplete = false;
			gameKit->setReady(false);
			break;
		}
    }
}

- (void)disconnect
{
	if(mSession != nil) 
	{
		[mSession disconnectFromAllPeers]; 
		mSession.available = NO; 
		[mSession setDataReceiveHandler: nil withContext: NULL]; 
		mSession.delegate = nil; 
	}
	
	gameKit->setConnected(false);
	cout<<"disconnected!"<<endl;
	coinFlipComplete = false;
	gameKit->setReady(false);
	[mPeers release];
	mPeers=[[NSMutableArray alloc] init];
}

//----------------------------------------------------------------

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
	
	// Use a retaining property to take ownership of the session.
    self.mSession = session;
	// Assumes our object will also become the session's delegate.
    session.delegate = self;
    [session setDataReceiveHandler: self withContext:nil];
	// Remove the picker.
    picker.delegate = nil;
    [picker dismiss];
    [picker autorelease];
	gameKit->setPeerPickerOpen(false);
}

//----------------------------------------------------------------

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker
{
	picker.delegate = nil;
    [picker autorelease]; 
	
	gameKit->setPeerPickerOpen(false);
}

//----------------------------------------------------------------

- (void) resetCoinFlipComplete
{
	coinFlipComplete = false;
}

- (void) showPeerPicker
{
	[self resetCoinFlipComplete];
	
	GKPeerPickerController *mPicker;
	mPicker=[[GKPeerPickerController alloc] init];
	mPicker.delegate=self;
	
	[mPicker show];
	gameKit->setPeerPickerOpen(true);
}

- (void) session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
}

@end