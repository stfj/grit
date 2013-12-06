#include "testApp.h"
#include "AnimationTemplates.h"

//features
bool retina;
bool iPad;
bool tall;

//screen
int scaleAmt;
float spriteScale;

int screenWidth;
int screenheight;

int tileSize;

//sprites
extern animation_t S_Card1To9;
extern animation_t S_Card10And10;
extern animation_t S_CardHeart1To9;
extern animation_t S_CardSpot;
extern animation_t S_CardBack;
extern animation_t S_RemainingCards;
extern animation_t S_RemainingCardX;
extern animation_t S_BG;
extern animation_t S_TurnMarker;

//--------------------------------------------------------------
void testApp::setup(){	
	// initialize the accelerometer
	ofxAccelerometer.setup();
	
	//If you want a landscape oreintation 
	//iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
	
	ofBackground(127,127,127);
	//peerPicker = new ofxMultiPeerConnector(@"GritGame");
	
	resetACards();
	
	//setup whatever
	if (ofGetWidth() % 768 != 0)
		iPad = false;
	else
		iPad = true;
	
	if(ofGetHeight() == 1136) // tall
		tall = true;
	else
		tall = false;
	
	if(ofGetHeight() == 2048 || ofGetHeight() == 960 || ofGetHeight() == 1136)
		retina = true;
	else
		retina = false;
	
	if(iPad){
		screenWidth = 1024/2;
		screenheight = 768/2;
	} else {
		screenWidth = 320;
		screenheight = 480;
		if(tall)
			screenheight = 568;
	}
	
	pointHitBoxSetup = false;
	
	selectedCard = -1;
	lockingSelectedCard = false;
	
	font.loadFont("PixelSplitter-Bold.ttf", 8);
	bigFont.loadFont("PixelSplitter-Bold.ttf", 32);
	notifierTime = 0;
	ofSetFrameRate(60);
	
	if(retina && iPad)
		scaleAmt = 4;
	else if(retina || iPad)
		scaleAmt = 2;
	else
		scaleAmt = 1;
	
	spriteScale = 1.0f/(float)scaleAmt;
	
	tileSize = 16 * scaleAmt;
	
	cardWidth = S_Card1To9.w*tileSize/scaleAmt;
	cardHeight = S_Card1To9.h*tileSize/scaleAmt;
	miniCardWidth = S_RemainingCards.w*tileSize/scaleAmt;
	miniCardHeight = S_RemainingCards.h*tileSize/scaleAmt;
	
	//load sprites
	sprites = new ofxSpriteSheetRenderer(11, 100, 0, tileSize);
	sprites->loadTexture("cards_"+ofToString(scaleAmt)+"x.png", 1024*scaleAmt, GL_LINEAR);
	sprites->constScale = spriteScale;
	
	for(int i=0;i<9;i++){
		cardSprites[i] = S_Card1To9;
		cardSprites[i].frame = i;
	}
	for(int i=0;i<2;i++){
		cardSprites[9+i] = S_Card10And10;
		cardSprites[9+i].frame = i;
	}
	for(int i=0;i<9;i++){
		cardSprites[11+i] = S_CardHeart1To9;
		cardSprites[11+i].frame = i;
	}
	
	ofEnableAlphaBlending();
	
	gameState = GS_TITLESCREEN;
	
	
	myName = ofxNSStringToString([[NSUUID UUID] UUIDString]);

	

	bluetooth = new ofxMultiPeerConnector(@"gritgame", myName, 1, 1);

	
	//-------------------------- start browsing for peers
	myPNum = -1;
	
	opName = "";
	opPNum = -1;
	
	resetData();
	
	gameState = GS_PEER_BROWSER;
	gotInit = false;
	sentInit = false;
	bluetooth->showPeerPicker();
	
	//initGameState();
	//gameState = GS_PLAY;
	
}

void testApp::resetData(){
	myPoints = 0;
	opPoints = 0;
	
	for(int c=0;c<4;c++){
		for(int p=0;p<2;p++){
			currentState.hands[c][p] = '.';
		}
	}
	
	for(int p=0;p<2;p++)
		currentState.lockedCard[p] = '.';
	
	for(int c = 0; c<3; c++){
		for(int p = 0; p<2; p++){
			for(int h = 0; h<9; h++){
				currentState.points[c][h][p] = '.';
			}
		}
	}
}

void testApp::resetACards(){
	for(int c=0;c<4;c++){
		aCards[c].card = currentState.hands[c][0];
		aCards[c].rot = -1;
		
		//aCards[c].loc.set(-100,-100);
		//aCards[c].layer = 0;
		//aCards[c].flip = 120;
		//aCards[c].card = 0;
	}
	
	for(int c=0;c<4;c++){
		aCards[c+4].card = currentState.hands[c][1];
		aCards[c+4].rot = -1;
		
		//aCards[c+4].loc.set(-100,-100);
		//aCards[c+4].layer = 0;
		//aCards[c+4].flip = 120;
		//aCards[c+4].card = 0;
	}
}
void testApp::setACardValue(char card, int x, int y, int rot, bool faceDown, int layer){
	int c = -1;
	for(int i=0;i<8;i++){
		if(aCards[i].card == card){
			c = i;
			break;
		}
	}
	
	if(c != -1)
	{
		if(aCards[c].rot == -1) // initialize
		{
			aCards[c].loc.set(x, y);
			aCards[c].rot = rot;
			aCards[c].flip = faceDown*120;
		}
		
		aCards[c].target.set(x, y);
		aCards[c].targetRot = rot;
		aCards[c].targetFlip = faceDown*120;
		aCards[c].layer = layer;
	}
}

bool testApp::drawACards()
{
	bool revealing = false;
	bool anyCardsMoving = false;
	
	for(int c=0;c<8;c++){ //first pass. movement
		
		if(aCards[c].rot != -1){
			
			aCards[c].loc -= (aCards[c].loc-aCards[c].target)/8;
			
			if(aCards[c].rot - aCards[c].targetRot > 180) // if its closer to spin the other way, do that
				aCards[c].rot -= (aCards[c].targetRot-aCards[c].rot)/4;
			else
				aCards[c].rot -= (aCards[c].rot-aCards[c].targetRot)/4;
			
			if(aCards[c].rot>=360) aCards[c].rot-=360;
			if(aCards[c].rot<0) aCards[c].rot+=360;
			
			if(aCards[c].flip < aCards[c].targetFlip) // flip to hide
				aCards[c].flip+=5;
			
			
			if(ABS(aCards[c].loc.x - aCards[c].target.x)>1 || ABS(aCards[c].loc.y - aCards[c].target.y)>1)
				anyCardsMoving = true;
				

		}
	}
	
	if(!anyCardsMoving){
		for(int c=0;c<8;c++){ // second pass, reveal
			
			if(aCards[c].rot != -1){
				if(aCards[c].flip > aCards[c].targetFlip)
					aCards[c].flip-=5;
				
			}
			
			if(aCards[c].flip != aCards[c].targetFlip)
				revealing = true;
		}
	}
	
	for(int c=0;c<8;c++){ // thrid pass, drawing
		
		if(aCards[c].rot != -1){
			animation_t * sprite;
			
			if(aCards[c].flip > 60)
				sprite = &S_CardBack;
			else
				sprite = &cardSprites[aCards[c].card];
			
			float xScale = 0;
			if(aCards[c].flip < 60)
				xScale = ofMap(aCards[c].flip, 0, 60, 1.0, 0);
			else if(aCards[c].flip > 60)
				xScale = ofMap(aCards[c].flip, 60, 120, 0, 1.0);
			
			//draw
			sprites->addRotatedScaledTile(sprite,
										  aCards[c].loc.x, aCards[c].loc.y,
										  0.5, 0.5,
										  aCards[c].layer, F_NONE, xScale, 1.0,
										  aCards[c].rot);
		}
	}
	
	return revealing || anyCardsMoving;
}

//--------------------------------------------------------------
void testApp::update(){
	sprites->clear();
	
	switch (gameState) {
		default:
		case GS_TITLESCREEN:
		{
			
			break;
		}
		case GS_PEER_BROWSER:
		{
			
			break;
		}
		case GS_WAIT_FOR_INIT:
		{
			if(gotInit && sentInit){
				gameState = GS_PLAY;
			}
			break;
		}
		case GS_PLAY:
		{
			if(currentState.historyIndex != 4)//if we're still in the game
			{
				if(currentState.whoseTurn == opPNum){
					sprites->addRotatedTile(&S_TurnMarker,
											0, 0,
											0, 0,
											0, F_VERT, 1.0,
											0);
				} else {
					sprites->addRotatedTile(&S_TurnMarker,
											0, screenheight,
											0, 1,
											0, F_NONE, 1.0,
											0);
				}
			}
			//figure out how to draw the board here....
			
			int cardSpacing = -cardWidth/4;
			int remainingCardSpacing = -miniCardWidth/4;
			
			int myHandY = screenheight;
			int opHandY = 0;
			
			
			int myNumCards = 0;
			for(int i=0;i<4;i++)
			{
				if(currentState.hands[i][myPNum] != '.')
					myNumCards++;
			}

			int opNumCards = 0;
			for(int i=0;i<4;i++)
			{
				if(currentState.hands[i][opPNum] != '.')
					opNumCards++;
			}
			
			
			int myHandOffset = (screenWidth - (cardWidth*myNumCards+cardSpacing*(myNumCards-1)))/2;
			int opHandOffset = (screenWidth - (cardWidth*opNumCards+cardSpacing*(opNumCards-1)))/2;
			
			
			int remainingCardOffset = (screenWidth - (miniCardWidth*12+remainingCardSpacing*11))/2;
			
			int opPointY = screenheight/2-miniCardHeight/2-cardHeight - 15;
			int myPointY = screenheight/2+miniCardHeight/2 + 15;
			int pointPileSpacing = 0;
			int cardStagger = 10;

			
			int pointOffset = (screenWidth - (cardWidth*3+pointPileSpacing*2))/2;

			
			// ok draw the cards! // eventually i need to redo all of this to support an external class that can be animated and stuff
			
			//bool ofxSpriteSheetRenderer::addRotatedTile(animation_t* sprite, float x, float y, float rX, float rY, int layer, flipDirection f, float scale, int rot, CollisionBox_t* collisionBox, int r, int g, int b, int alpha){

			//draw op hand
			int shift = 0;
			
			for(int c=0;c<4;c++){
				int rot = ofMap(c-shift, 0, opNumCards, 10, -10);
				if(rot<0) rot+=360;
				
				if(currentState.hands[c][opPNum] != '.')
				{
					/*sprites->addRotatedTile(&S_CardBack,
											opHandOffset+(c-shift)*cardWidth+(c-shift-1)*cardSpacing + cardWidth/4, opHandY,
											0.5, 0.5,
											0, F_NONE, 1.0,
											rot);*/
					
					setACardValue(currentState.hands[c][opPNum],
								  opHandOffset+(c-shift)*cardWidth+(c-shift-1)*cardSpacing + cardWidth/4,
								  opHandY,
								  rot,
								  true,
								  0);
				}
				else
					shift++;
			}
			
			//draw my hand
			int selShift = 0;
			shift = 0;
			for(int c=0;c<4;c++){
				int rot = ofMap(c-shift, 0, opNumCards, -10, 10);
				if(rot<0) rot+=360;
				
				hitbox_cards[c].set(-100, -100, 0, 0);
				
				if(currentState.hands[c][myPNum] != '.')
					if(c != selectedCard) //if not selected, draw the card
					{
						/*sprites->addRotatedTile(&cardSprites[currentState.hands[c][myPNum]],
												myHandOffset+(c-shift)*cardWidth+(c-shift-1)*cardSpacing + cardWidth/4, myHandY,
												0.5, 0.5,
												0, F_NONE, 1.0,
												rot);*/
						
						hitbox_cards[c].set(myHandOffset+(c-shift)*cardWidth+(c-shift-1)*cardSpacing + cardWidth/4 - cardWidth/2, myHandY - cardHeight/2, cardWidth, cardHeight);
						
						setACardValue(currentState.hands[c][myPNum],
									  myHandOffset+(c-shift)*cardWidth+(c-shift-1)*cardSpacing + cardWidth/4,
									  myHandY,
									  rot,
									  false,
									  0);
						
					} else { // store the shift so we can draw the card later (so it'll be on top)
						selShift = shift;
					}
				else
					shift++;
			}
			
			if(selectedCard != -1){ // draw the card on top!
				/*sprites->addRotatedTile(&cardSprites[currentState.hands[selectedCard][myPNum]],
										myHandOffset+(selectedCard-selShift)*cardWidth+(selectedCard-selShift-1)*cardSpacing + cardWidth/4, myHandY - cardHeight*0.4,
										0.5, 0.5,
										0, F_NONE, 1.0,
										lockingSelectedCard*90);*/
			
				
				hitbox_cards[selectedCard].set(myHandOffset+(selectedCard-selShift)*cardWidth+(selectedCard-selShift-1)*cardSpacing + cardWidth/4 - cardWidth/2, myHandY-cardHeight*0.9, cardWidth, cardHeight);
				
				setACardValue(currentState.hands[selectedCard][myPNum],
							  myHandOffset+(selectedCard-selShift)*cardWidth+(selectedCard-selShift-1)*cardSpacing + cardWidth/4,
							  myHandY - cardHeight*0.4,
							  lockingSelectedCard*90,
							  false,
							  1);
			}
			
			
			//draw points
			
			if(pointHitBoxSetup == false) //setup the hitboxes for the points
			{
				for(int c=0;c<3;c++){
						hitbox_points[c][opPNum].set(pointOffset+(cardWidth+pointPileSpacing)*c, opPointY, cardWidth, cardHeight);
						hitbox_points[c][myPNum].set(pointOffset+(cardWidth+pointPileSpacing)*c, myPointY, cardWidth, cardHeight);
				}
				
				
				pointHitBoxSetup = true;
			}
			for(int p=0;p<3;p++)
			{
				// op points
				sprites->addRotatedTile(&S_CardSpot,
										pointOffset+(cardWidth+pointPileSpacing)*p, opPointY,
										0, 0,
										0, F_NONE, 1.0,
										0);
				
				for(int h=0;h<9;h++){
					bool hidden = false;
					bool locked = false;
					if(currentState.points[p][h][opPNum] != '.')
					{
						if(currentState.points[p][h][opPNum] == currentState.cardPlayed[opPNum])
							hidden = true;
						
						if(currentState.points[p][h][opPNum] == currentState.cardPlayed[myPNum])
							hidden = true;
						
						if(currentState.points[p][h][opPNum] == currentState.lockedCard[myPNum]){
							hidden = true;
							locked = true;
						}
						
						int layer = h;
						if(locked)
							layer = 10;
						
						setACardValue(currentState.points[p][h][opPNum],
									  pointOffset+(cardWidth+pointPileSpacing)*p + cardWidth/2,
									  opPointY - cardStagger*h + cardHeight/2,
									  locked*90,
									  locked || hidden,
									  layer);
					}
										
					/*sprites->addRotatedTile(hidden ? &S_CardBack : &cardSprites[currentState.points[p][h][opPNum]],
											pointOffset+(cardWidth+pointPileSpacing)*p + cardWidth/2, opPointY - cardStagger*h + cardHeight/2,
											0.5, 0.5,
											locked, F_NONE, 1.0,
											locked*90);*/
					
					if(p==0 && h==0){
						sprites->addRotatedTile(&cardSprites[currentState.points[p][h][opPNum]],
												pointOffset+(cardWidth+pointPileSpacing)*p + cardWidth/2, opPointY - cardStagger*h + cardHeight/2,
												0.5, 0.5,
												0, F_NONE, 1.0,
												0);
					}
				}
				
				// my points
				
				sprites->addRotatedTile(&S_CardSpot,
										pointOffset+(cardWidth+pointPileSpacing)*p, myPointY,
										0, 0,
										0, F_NONE, 1.0,
										0);
				
				for(int h=0;h<9;h++){
					bool hidden = false;
					bool locked = false;
					if(currentState.points[p][h][myPNum] != '.')
					{
						if(currentState.points[p][h][myPNum] == currentState.cardPlayed[opPNum])
							hidden = true;
						
						if(currentState.points[p][h][myPNum] == currentState.cardPlayed[myPNum])
							hidden = true;
						
						if(currentState.points[p][h][myPNum] == currentState.lockedCard[opPNum]){
							hidden = true;
							locked = true;
						}
						
						int layer = h;
						if(locked)
							layer = 10;
						
						setACardValue(currentState.points[p][h][myPNum],
									  pointOffset+(cardWidth+pointPileSpacing)*p + cardWidth/2,
									  myPointY + cardStagger*h + cardHeight/2,
									  locked*90,
									  locked || hidden,
									  layer);
					}
					/*sprites->addRotatedTile(hidden ? &S_CardBack : &cardSprites[currentState.points[p][h][myPNum]],
											pointOffset+(cardWidth+pointPileSpacing)*p + cardWidth/2, myPointY + cardStagger*h + cardHeight/2,
											0.5, 0.5,
											locked, F_NONE, 1.0,
											locked*90);*/
					
					if(p==0 && h==0){
						sprites->addRotatedTile(&cardSprites[currentState.points[p][h][myPNum]],
												pointOffset+(cardWidth+pointPileSpacing)*p + cardWidth/2, myPointY + cardStagger*h + cardHeight/2,
												0.5, 0.5,
												0, F_NONE, 1.0,
												0);
					}
				}
			}
			
			//draw reference
			for(int c=0;c<12;c++)
			{
				bool cardKnown = false;
				for(int h=0;h<4;h++){
					if(c==11){
						if(currentState.hands[h][myPNum]> 10 && currentState.hands[h][myPNum] != '.') // heart
							cardKnown = true;
					} else {
						if(currentState.hands[h][myPNum] == c)
							cardKnown = true;
					}
				}
				
				for(int p=0;p<3;p++){
					for(int h=0;h<9;h++){
						
						//check my piles
						if(c==11){
							if(currentState.points[p][h][myPNum] != '.' && currentState.points[p][h][myPNum]> 10) // heart
							{
								if(currentState.points[p][h][myPNum] != currentState.lockedCard[opPNum] &&
								   currentState.points[p][h][myPNum] != currentState.cardPlayed[opPNum]) // make sure the card is not locked
									cardKnown = true;
							}
						}
						else
						{
							if(currentState.points[p][h][myPNum] == c)
							{
								if(currentState.points[p][h][myPNum] != currentState.lockedCard[opPNum] &&
								   currentState.points[p][h][myPNum] != currentState.cardPlayed[opPNum]) // make sure the card is not locked and not just played
									cardKnown = true;
							}
						}
						
						//check their piles
						if(c==11)
						{
							if(currentState.points[p][h][opPNum] != '.' && currentState.points[p][h][opPNum]> 10 &&
							   currentState.points[p][h][opPNum] != currentState.cardPlayed[opPNum]) // heart
								cardKnown = true;
						}
						else
						{
							if(currentState.points[p][h][opPNum] == c && currentState.points[p][h][opPNum] != currentState.cardPlayed[opPNum])
								cardKnown = true;
						}

					}
				}
				
				S_RemainingCards.frame = c;
				if(!cardKnown)
				{
					sprites->addRotatedTile(&S_RemainingCards,
											remainingCardOffset+c*miniCardWidth+(c-1)*remainingCardSpacing, screenheight/2,
											0, 0.5,
											0, F_NONE, 1.0,
											0);
				}
				else
				{
					sprites->addRotatedTile(&S_RemainingCards,
											remainingCardOffset+c*miniCardWidth+(c-1)*remainingCardSpacing, screenheight/2,
											0, 0.5,
											0, F_NONE, 1.0,
											0);
					
					sprites->addRotatedTile(&S_RemainingCardX,
											remainingCardOffset+c*miniCardWidth+(c-1)*remainingCardSpacing, screenheight/2,
											0, 0.5,
											0, F_NONE, 1.0,
											0);
				}
			}
			
			//draw animated cards:
			
			animationsAreHappening = drawACards();
			break;
		}
	}
	
}

//--------------------------------------------------------------
void testApp::draw(){
	switch (gameState) {
		default:
		case GS_TITLESCREEN:
		{
			glPushMatrix();
			glScalef(scaleAmt, scaleAmt, scaleAmt);
			{
				sprites->draw();
			}
			glPopMatrix();
			break;
		}
		case GS_PEER_BROWSER:
		{
			
			break;
		}
		case GS_WAIT_FOR_INIT:
		{
			glPushMatrix();
			glScalef(scaleAmt, scaleAmt, scaleAmt);
			{
				sprites->draw();
			}
			glPopMatrix();
			
			break;
		}
		case GS_PLAY:
		{
			glPushMatrix();
			glScalef(scaleAmt, scaleAmt, scaleAmt);
			{
				ofSetColor(255, 255, 255);
				sprites->draw();

				
				if(refigureScores && !animationsAreHappening){
					opPoints = getCurrentPoints(opPNum);
					myPoints = getCurrentPoints(myPNum);
					refigureScores = false;
				}
				//draw their points
				ofSetColor(0, 0, 0);
				font.drawString(ofToString(opPoints),  screenWidth/2 - font.stringWidth(ofToString(opPoints))/2, screenheight/2 - 25);
				
				//draw my Points
				ofSetColor(0, 0, 0);
				font.drawString(ofToString(myPoints), screenWidth/2 - font.stringWidth(ofToString(myPoints))/2, screenheight/2 + 30);
				
				//fuck notifications
				/*if(notifierTime > 0){
					string notification;
					if(currentState.historyIndex < 4)
						notification = "round " + ofToString(currentState.historyIndex+1);
					else
					{
						if(myPoints > opPoints && myPoints <=21){
							notification = "win! \n"+ofToString(myPoints)+" to "+ofToString(opPoints);
						} else if(myPoints < opPoints && myPoints > 21 && opPoints > 21){
							notification = "win! \n"+ofToString(myPoints)+" to "+ofToString(opPoints);
						} else if(myPoints == opPoints && myPoints == 21){
							notification = "draw! \n"+ofToString(myPoints)+" to "+ofToString(opPoints);
						} else {
							notification = "lose. \n"+ofToString(myPoints)+" to "+ofToString(opPoints);
						}
					}
					ofSetColor(0, 0, 0, ofMap(notifierTime, 0, 60, 0, 255));
					bigFont.drawString(notification, screenWidth/2 - bigFont.stringWidth(notification)/2-4, screenheight/2-4);

					ofSetColor(255, 255, 255, ofMap(notifierTime, 0, 60, 0, 255));
					bigFont.drawString(notification, screenWidth/2 - bigFont.stringWidth(notification)/2, screenheight/2);
					
					notifierTime--;
				}*/
			}
			glPopMatrix();
			
			break;
		}
	}
	
	
	/*glPushMatrix();
	glScalef(scaleAmt, scaleAmt, scaleAmt);
	{
		ofDrawBitmapString(ofToString(myPNum), 10, 50);
		ofDrawBitmapString(opName, 10, 60);
		ofDrawBitmapString(ofToString(gotInit), 10, 70);
		ofDrawBitmapString(ofToString(sentInit), 10, 80);
	}
	glPopMatrix();*/
	
}
int testApp::getCurrentPoints(int player){
	int numPoints = 0;
	for(int c = 0; c<3; c++){
		for(int hist = 8; hist>=0; hist--){
			if(currentState.points[c][hist][player] != '.')
			{
				if(currentState.points[c][hist][player] != currentState.cardPlayed[opPNum] &&
				   currentState.points[c][hist][player] != currentState.lockedCard[opPNum] &&
				   currentState.points[c][hist][player] != currentState.lockedCard[myPNum]) //if we can see the card
					numPoints += getCardValue(currentState.points[c][hist][player]);
				
				break;
			}
		}
	}
	return numPoints;
}

//--------------------------------------------------------------
int testApp::getCardValue(char card){
	if(card<10)
		return (int)card+1; // 1-10 of clubs
	else if(card == 10)		// jack
		return 10;
	else					// 1-9 of hearts
		return (int)card-10;
}
//--------------------------------------------------------------
int testApp::calculateTurn(){
	
	int points[2];
	points[0] = points[1] = 0;
	int highCard[2];
	highCard[0] = highCard[1] = 0;
	
	for(int c = 0; c<3; c++){
		for(int p = 0; p<2; p++){
			for(int hist = 8; hist>=0; hist--){
				if(currentState.points[c][hist][p] != '.'){
					if(currentState.points[c][hist][p] != currentState.lockedCard[opPNum] &&
					   currentState.points[c][hist][p] != currentState.lockedCard[myPNum])
					{
						points[p] += getCardValue(currentState.points[c][hist][p]); //add to the total points;
						
						
						if(currentState.points[c][hist][p] > highCard[p]) // copy in the highcard
							highCard[p] = currentState.points[c][hist][p];
					}
					break;
				}
			}
		}
	}
	
	myPoints = points[myPNum];
	opPoints = points[opPNum];
	
	if(myPoints > opPoints) // i have more points, they play first.
		return opPNum;
	else if(opPoints > myPoints) // i have less points, i play first.
		return myPNum;
	else if(highCard[myPNum] > highCard[opPNum]) // equal points, but my highcard is higher. they play first
		return opPNum;
	else // equal points, but their highcard is higher. i play first.
		return myPNum;
}

//--------------------------------------------------------------
void testApp::initGameState(){
	
	vector<char> hearts;
	for(int i=11;i<20;i++)
		hearts.push_back(i);
	ofRandomize(hearts);
	
	vector<char> deck; // fill the deck
	for(int i=0;i<11;i++)
		deck.push_back(i);
	
	deck.push_back(hearts[0]);
	ofRandomize(deck);
	
	for(int i=0;i<deck.size();i++)
		cout<<(int)deck[i]<<endl;
	
	//ugh something is wrong here.
	//also i should change the locked location to instead be a locked number maybe? and just check cards to display against it?
	
	for(int c=0;c<4;c++){ // deal the hands
		for(int p=0;p<2;p++){
			currentState.hands[c][p] = deck[0];
			deck.erase(deck.begin());
		}
	}

	for(int p=0;p<2;p++){ // pull the last two cards
		currentState.points[0][0][p] = deck[0];
		deck.erase(deck.begin());
	}
	
	for(int p=0;p<2;p++){ // set the locked cards to none
		currentState.lockedCard[p] = '.';
	}
	
	currentState.historyIndex = -1; // set the history to -1 (0 in a moment)
	resetACards();
	advanceRound(); //send the other player the first turn
}

//--------------------------------------------------------------
void testApp::advanceRound(){
	currentState.historyIndex++; // increment the history count
	
	for(int p=0;p<2;p++){ // set the played cards to none
		currentState.cardPlayed[p] = '.';
		currentState.locationPlayed[p] = '.';
		currentState.playerPlayedOn[p] = '.';
	}
	
	currentState.numCardsPlayed = 0; //flag that no cards have been played
	
	currentState.whoseTurn = calculateTurn(); //figure out whose turn it is
	
	if(currentState.historyIndex == 4){ // game is over. unlock locked cards
		currentState.lockedCard[0] = currentState.lockedCard[1] = '.';
	}
	
	sendGamestate(); //send the gamestate to the other player
	
	selectedCard = -1;
	lockingSelectedCard = false;
	
	refigureScores = true;
	
	notifierTime = 120;
}

//--------------------------------------------------------------
void testApp::advanceTurn(){
	currentState.numCardsPlayed++; //add to cards played
	currentState.whoseTurn = !currentState.whoseTurn; //make it be the other persons turn
	sendGamestate();
	
	selectedCard = -1;
	lockingSelectedCard = false;
}

//--------------------------------------------------------------
void testApp::addCardToPoints(char card, char location, char p){
	for(int hist = 8; hist>=0; hist--)
	{
		if(hist == 0){// if we're at the start, place the card here
			currentState.points[location][hist][p] = card;
		}
		else
		{
			if(currentState.points[location][hist-1][p] != '.'){ //if the next place isn't empty, place the card here
				currentState.points[location][hist][p] = card;
				break;
			}
		}
	}
}

//--------------------------------------------------------------
void testApp::exit(){

}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
	switch (gameState) {
		default:
		case GS_TITLESCREEN:
		{
			break;
		}
		case GS_PEER_BROWSER:
		{
			
			break;
		}
		case GS_WAIT_FOR_INIT:
		{
			
			break;
		}
		case GS_PLAY:
		{
			if(currentState.historyIndex != 4) // pre game over
			{
				if(currentState.whoseTurn == myPNum){
					int x = touch.x/scaleAmt;
					int y = touch.y/scaleAmt;
					
					if(y>screenheight-cardHeight)
					{
						if(selectedCard != -1 && hitbox_cards[selectedCard].inside(x, y)){
							if(currentState.lockedCard[myPNum] == '.')
								lockingSelectedCard = !lockingSelectedCard;
						}
						else
						{
							for(int c=0;c<4;c++){
								if(c!=selectedCard){
									if(hitbox_cards[c].inside(x, y)){
										selectedCard = c;
										lockingSelectedCard = false;
										break;
									}
								}
							}
						}
					} else if(selectedCard != -1){
						if(y<screenheight/2) // playing to opponent
						{
							for(int c=0;c<3;c++){
								if(hitbox_points[c][opPNum].inside(x, y)){
									bool legal = true;
									
									if(currentState.locationPlayed[opPNum] == c && currentState.playerPlayedOn[opPNum] == opPNum)
										legal = false; // cant play where op just played
									
									char mostRecentCardInStack = ','; //check to see if we're trying to play over a locked card
									for(int j=8;j>=0;j--)
									{
										if(currentState.points[c][j][opPNum] != '.'){
											mostRecentCardInStack = currentState.points[c][j][opPNum];
											break;
										}
									}
									
									if(currentState.lockedCard[myPNum] == mostRecentCardInStack)
										legal = false;
									
									if(legal){
										currentState.playerPlayedOn[myPNum] = opPNum;
										currentState.locationPlayed[myPNum] = c;
										currentState.cardPlayed[myPNum]		= currentState.hands[selectedCard][myPNum];
										
										if(lockingSelectedCard)
											currentState.lockedCard[myPNum] = currentState.cardPlayed[myPNum];
										
										currentState.hands[selectedCard][myPNum] = '.';
										addCardToPoints(currentState.cardPlayed[myPNum], currentState.locationPlayed[myPNum], currentState.playerPlayedOn[myPNum]);
										advanceTurn();
									}
									
									break;
								}
							}
						}
						else // playing to own cards
						{
							for(int c=0;c<3;c++){
								if(hitbox_points[c][myPNum].inside(x, y)){
									bool legal = true;
									
									if(lockingSelectedCard)
										legal = false; // cant lock on yourself
									
									if(currentState.locationPlayed[opPNum] == c && currentState.playerPlayedOn[opPNum] == myPNum)
										legal = false; // cant play where op just played
									
									char mostRecentCardInStack = ','; //check to see if we're trying to play over a locked card
									for(int j=8;j>=0;j--)
									{
										if(currentState.points[c][j][myPNum] != '.'){
											mostRecentCardInStack = currentState.points[c][j][myPNum];
											break;
										}
									}
									
									if(currentState.lockedCard[opPNum] == mostRecentCardInStack)
										legal = false;
									
									if(legal){
										currentState.playerPlayedOn[myPNum] = myPNum;
										currentState.locationPlayed[myPNum] = c;
										currentState.cardPlayed[myPNum]		= currentState.hands[selectedCard][myPNum];
										currentState.hands[selectedCard][myPNum] = '.';
										addCardToPoints(currentState.cardPlayed[myPNum], currentState.locationPlayed[myPNum], currentState.playerPlayedOn[myPNum]);
										advanceTurn();
									}
									
									break;
								}
							}
						}
					}
				}
			}
			break;
		}
	}
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){
	if(currentState.historyIndex == 4 && gameState == GS_PLAY){
		resetData();
		initGameState();
	}
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){

}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}

//bluetooth multiplayer -----------

void testApp::connected(){
	cout<<"connected!"<<endl;
	bluetooth->ready = true;
	sendInit();
}
void testApp::connecting(){
	cout<<"connecting!"<<endl;
}
void testApp::disconnected(){
	cout<<"disconnected!"<<endl;
	bluetooth->ready = false;
}

void testApp::recievedData(const void * data, int dataLength){
	if(dataLength == sizeof(initInfo)) {
		initInfo packet;
		memcpy(&packet, data, dataLength);
		
		opName = "";
		
		for(int i=0;i<100;i++){
			if(packet.GCName[i]=='.')
				break;
			else{
				opName += packet.GCName[i];
			}
		}
		
		if(myName > opName){
			myPNum = 0;
			opPNum = 1;
		}
		else{
			myPNum = 1;
			opPNum = 0;
		}
		
		gotInit = true;
		
		if(myPNum == 0)
			initGameState();
	}
	else if(dataLength == sizeof(gamestateInfo)) {
		gamestateInfo packet;
		memcpy(&packet, data, dataLength);
		
		//gameStates.push_back(packet); //log all of the gamestates, although right now im not using this, things are just quickly updating
		
		currentState = packet;
		
		if(currentState.numCardsPlayed==0) // find out points
		{
			refigureScores = true;
			notifierTime = 60;
			
			if(currentState.historyIndex == 0)
				resetACards();
		}
		
		
		if(currentState.numCardsPlayed==2){ // reveal the cards // this doesnt need to happen anymore
			//for(int p=0;p<2;p++){
			//	addCardToPoints(currentState.cardPlayed[p], currentState.locationPlayed[p], currentState.playerPlayedOn[p]);
			//}
			
			advanceRound();
		}
	}
}

void testApp::sendInit(){
	initInfo packet;

	for(int i=0;i<MIN(myName.size(), 100);i++)
		packet.GCName[i] = myName[i];
	
	packet.GCName[MIN(myName.size(), 99)] = '.';
	if(bluetooth->ready){
		bluetooth->sendData((void *)&packet, sizeof(initInfo));
	}
	
	sentInit = true;
	gameState = GS_WAIT_FOR_INIT;
}

void testApp::sendGamestate(){
	gamestateInfo packet = currentState;
	
	if(bluetooth->ready)
		bluetooth->sendData((void *)&packet, sizeof(gamestateInfo));
}