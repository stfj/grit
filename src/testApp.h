#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

#include "ofxSpriteSheetRenderer.h"
#include "ofxMultiPeerConnector.h"

struct initInfo {
	char GCName[100];
};

struct gamestateInfo {
	//board
	char hands[4][2];
	char points[3][9][2];
	char lockedCard[2];
	
	
	//mid turn structures
	char cardPlayed[2];
	char locationPlayed[2];
	char playerPlayedOn[2];

	int whoseTurn;
	int numCardsPlayed;
	
	//------------------
	
	int historyIndex;
};

struct animatedCard {
	char card;
	ofPoint loc;
	ofPoint target;
	float rot;
	float targetRot;
	
	float flip;
	float targetFlip;
	int layer;
};


// ugh probably i have to rethink some of this logic for locking. probably the game should just retain a gamestate, and the players should shuffle a gamestate back and forth instead of having this moveInfo structure. simplify this whole thing

enum GAME_STATE {GS_TITLESCREEN=0, GS_PEER_BROWSER, GS_WAIT_FOR_INIT, GS_PLAY};

class testApp : public ofxiPhoneApp{
	
    public:
        void setup();
		void resetData();
        void update();
        void draw();
        void exit();
	
		void sendInitData();
		void initGameState();
		void advanceRound();
		void advanceTurn();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
	
		void connected();
		void connecting();
		void disconnected();
	
		int getCardValue(char card);
		int calculateTurn();
		int getCurrentPoints(int player);
	
		void addCardToPoints(char card, char location, char playerPlayedOn);
	
		void resetACards();
		bool drawACards();
		void setACardValue(char card, int x, int y, int rot, bool faceDown, int layer);
	
		//helpful into
		float cardWidth;
		float cardHeight;
		float miniCardWidth;
		float miniCardHeight;
	
		//local data ------------------------------------------------
		
		string myName;
		int myPNum;
		int myPoints;
	
		string opName;
		int opPNum;
		int opPoints;
	
		bool refigureScores;
		bool animationsAreHappening;
	
		gamestateInfo currentState;
	
		bool myTurn;
	
		int selectedCard;
		bool lockingSelectedCard;
		
		GAME_STATE gameState;
		bool gotInit;
		bool sentInit;
	
		ofTrueTypeFont font;
		ofTrueTypeFont bigFont;
		int notifierTime;
	
		ofRectangle hitbox_cards[4];
		ofRectangle hitbox_points[3][2];
		bool pointHitBoxSetup;
	
		animatedCard aCards[8];

		//sprites ---------------------------------------------------
	
		ofxSpriteSheetRenderer * sprites;
	
		animation_t cardSprites[20];
	
		//bluetooth -------------------------------------------------
	
		//ofxMultiPeerConnector * peerPicker;
	
		vector<gamestateInfo> gameStates;
	
		void recievedData(const void * data, int dataLength);
		void sendInit();
		void sendGamestate();
	
		ofxMultiPeerConnector * bluetooth;
	
};


