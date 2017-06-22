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

#import <UIKit/UIKit.h>
#import "RhoMainView.h"
#import "RhoViewController.h"
#import "api_generator/iphone/IMethodResult.h"

@interface RhoUITabBarController : UITabBarController
{
	int bkgColor;
}

@property (nonatomic,assign) int bkgColor;

@end

@interface RhoCustomTabBarItem : UITabBarItem  
{
    UIImage *customHighlightedImage;
    UIImage *customStdImage;
}

@property (nonatomic, retain) UIImage *customHighlightedImage;
@property (nonatomic, retain) UIImage *customStdImage;

@end

@interface TabbedMainView : RhoViewController<RhoMainView> {
    UITabBarController *tabbar;
    NSArray *tabbarData;
    int tabindex;
    id<IMethodResult> on_change_tab_callback;
    CGRect rootFrame;
    BOOL invisible_tab_control;
}

@property (nonatomic,retain) UITabBarController *tabbar;
@property (nonatomic,retain) NSArray *tabbarData;
@property (nonatomic,assign) int tabindex;
@property (nonatomic,assign) id<IMethodResult> on_change_tab_callback;
@property (nonatomic,assign) BOOL invisible_tab_control;

- (id)initWithMainView:(id<RhoMainView>)v parent:(UIWindow*)p bar_info:(NSDictionary*)bar_info;

- (id<RhoWebView,NSObject>)getRhoWebView:(int)tab_index;
- (id<RhoWebView,NSObject>)detachRhoWebView;

- (void)onViewWillActivate:(RhoViewController*)view;

-(void)callCallback:(int)new_index;

@end