/*------------------------------------------------------------------------
* (The MIT License)
* 
* Copyright (c) 2008-2011 Rhomobile, Inc.
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
* 
* http://rhomobile.com
*------------------------------------------------------------------------*/

#import <Foundation/Foundation.h>

@interface LocationController : NSObject<CLLocationManagerDelegate> {
	CLLocationManager* _locationManager;
	NSTimer*  timer;
    int gps_callback_interval;
    BOOL isFirstUpdateFromPlatform;
    bool isErrorState;
    BOOL isEnabled;
	
@public	
	double _dLatitude, _dLongitude, _dAccuracy, _dAltitude, _dMinDistance, _dSpeed;
    int _iSatellites;
	bool _bKnownPosition;
    bool _bMinDistanceMode;
	
	//SEL onUpdateLocation;	
}

@property (nonatomic, retain) CLLocationManager *_locationManager;
@property (assign) SEL onUpdateLocation;

- (void) initLocationManager:(NSObject*)param;
- (void)  stop; 

- (void)doUpdateLocation;

- (double) getLatitude;
- (double) getLongitude;
- (double) getAccuracy;
- (double) getAltitude;
- (double) getSpeed;
- (int) getSatellites;
- (bool) isKnownPosition;
- (bool) isAvailable;

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation;

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error;

- (void)onTimerFired:(NSTimer*)theTimer; 

- (void)resetTimerWithNewInterval:(int)interval;

- (void)resetUpdateWithMinDistance:(double)minDistance;

+ (LocationController *)sharedInstance;

@end
