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

#ifdef __IPHONE_3_0

#import <MapKit/MapKit.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKReverseGeocoder.h>
#import "GoogleGeocoder.h"
#import "RhoViewController.h"

#include "ruby/ext/rho/rhoruby.h"


#import "MapViewManager.h" 

@interface RhoMapViewController : RhoViewController {
    UIView *mapView;
    UIToolbar* toolbar;
	UIView* savedMainView;
	UIViewController* savedMainViewController;
}

// 
@property (nonatomic,retain) UIView *savedMainView;
@property (nonatomic,retain) UIViewController *savedMainViewController;

+ (void)createMap:(rho_param*)params;
+ (void)closeMap;
+ (BOOL)isStarted;
+ (double)centerLatitude;
+ (double)centerLongitude;

- (void)close;
- (void)setParams:(rho_param*)params;

@end

#endif