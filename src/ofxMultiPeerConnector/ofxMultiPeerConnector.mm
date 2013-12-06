//
//  ofxMultiPeerConnector.mm
//  Grit
//
//  Created by Zach Gage on 7/13/13.
//
//

#include "ofxMultiPeerConnector.h"
#include "testApp.h"

@implementation ofxMultiPeerDelegate

-(ofxMultiPeerDelegate*)initWithOwner:(ofxMultiPeerConnector *)own{
	if(self = 	[super init]) {
		owner = own;
	}
	return self;
}

// go through these below and turn the session delegates into a way to just pass generic data and drop it onto a vector, turn the browser methods to actually drop stuff. also remove all the transcript stuff from the session container

#pragma mark - MCBrowserViewControllerDelegate methods

// Override this method to filter out peers based on application specific needs
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    return YES;
}

// Override this to know when the user has pressed the "done" button in the MCBrowserViewController
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    //[browserViewController dismissViewControllerAnimated:YES completion:nil];
	[browserViewController resignFirstResponder];
	[browserViewController.view removeFromSuperview];
	[browserViewController release];	
}

// Override this to know when the user has pressed the "cancel" button in the MCBrowserViewController
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    //[browserViewController dismissViewControllerAnimated:YES completion:nil];
	[browserViewController resignFirstResponder];
	[browserViewController.view removeFromSuperview];
	[browserViewController release];
}

#pragma mark - SessionContainerDelegate

- (void)recievedData:(NSData *)data
{
	testApp * cppDelegate = (testApp *)ofGetAppPtr();
	cppDelegate->recievedData([data bytes], [data length]);
}
/*- (void)receivedTranscript:(Transcript *)transcript
{
    // Add to table view data source and update on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
		//[self insertTranscript:transcript];
    });
}

- (void)updateTranscript:(Transcript *)transcript
{
    // Find the data source index of the progress transcript
    //NSNumber *index = [_imageNameIndex objectForKey:transcript.imageName];
    //NSUInteger idx = [index unsignedLongValue];
    // Replace the progress transcript with the image transcript
    //[_transcripts replaceObjectAtIndex:idx withObject:transcript];
	
    // Reload this particular table view row on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        //[self.tableView reloadRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}*/


@end


ofxMultiPeerConnector::ofxMultiPeerConnector(NSString* service, string user, int minP, int maxP)
{
	
	serviceName = service;
	playerName = user;
	ready = false;
	
	delegate = [[ofxMultiPeerDelegate alloc] initWithOwner:this];
	
	if(user==""){
		playerName = ofxNSStringToString([[NSUUID UUID] UUIDString]);
	}
		
	sessionContainer = [[SessionContainer alloc] initWithDisplayName:ofxStringToNSString(playerName) serviceType:service];
	// Set this view controller as the SessionContainer delegate so we can display incoming Transcripts and session state changes in our table view.
	sessionContainer.delegate = delegate;
	
	minPlayers = minP;
	maxPlayers = maxP;
}

ofxMultiPeerConnector::~ofxMultiPeerConnector()
{
	[delegate release];
	[sessionContainer release];
}

void ofxMultiPeerConnector::showPeerPicker()
{
	MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:serviceName session:sessionContainer.session];
	
	browserViewController.minimumNumberOfPeers = minPlayers;
	browserViewController.maximumNumberOfPeers = maxPlayers;
	
	browserViewController.delegate = delegate;
	
	//[self presentViewController:browserViewController animated:YES completion:nil];
	[ofxiPhoneGetGLParentView() addSubview:browserViewController.view];
}

bool ofxMultiPeerConnector::sendData(void * data, int length)
{
	return [sessionContainer sendData:[NSData dataWithBytes:data length:length]];
}





