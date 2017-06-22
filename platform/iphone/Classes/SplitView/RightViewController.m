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

#import "RightViewController.h"
#import "SimpleMainView.h"
#import "Rhodes.h"
#import "AppManager.h"

#include "common/RhodesApp.h"
#include "logging/RhoLog.h"

#include "NativeBar.h"

#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "RightViewController"

void rho_webview_refresh(int index);


@interface RhoRightItem : NSObject {
@public
    NSString *url;
	SimpleMainView* view;
    BOOL loaded;
    BOOL reload;
}

@property (retain) NSString *url;
@property (retain) SimpleMainView *view;
@property (assign) BOOL loaded;
@property (assign) BOOL reload;

- (id)init;
- (void)dealloc;

@end

@implementation RhoRightItem

@synthesize url, loaded, reload, view;

- (id)init {
    url = nil;
	view = nil;
    loaded = NO;
    reload = NO;
    return self;
}

- (void)dealloc {
    [url release];
	[view release];
    [super dealloc];
}

@end





@implementation RightViewController

@synthesize itemsData, tabindex, on_change_tab_callback;

- (id)initWithItems:(NSDictionary*)bar_info parent:(SplittedMainView*)parent {
	self = [self initWithNibName:nil bundle:nil];

	CGRect rect = CGRectMake(0,0,200,200);//self.view.frame;
	
	NSArray* items = (NSArray*)[bar_info objectForKey:NATIVE_BAR_ITEMS];
	
    int count = [items count];
	
    NSMutableArray *tabs = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSString *initUrl = nil;
    
	BOOL is_load_initial_url = YES;
	int tab_to_initial_select = -1;
    
    for (int i = 0; i < count; ++i) {
		NSDictionary* item = (NSDictionary*)[items objectAtIndex:i];
        
        NSString *label = (NSString*)[item objectForKey:NATIVE_BAR_ITEM_LABEL];
        NSString *url = (NSString*)[item objectForKey:NATIVE_BAR_ITEM_ACTION];
        NSString *icon = (NSString*)[item objectForKey:NATIVE_BAR_ITEM_ICON];
        NSString *reload = (NSString*)[item objectForKey:NATIVE_BAR_ITEM_RELOAD];
		NSString *use_current_view_for_tab = (NSString*)[item objectForKey:NATIVE_BAR_ITEM_USE_CURRENT_VIEW_FOR_TAB];
        
		
		BOOL is_use_current_view_for_tab = NO;
		if (use_current_view_for_tab != nil) {
			if ([use_current_view_for_tab caseInsensitiveCompare:@"true"] == NSOrderedSame) {
				is_use_current_view_for_tab = YES;
            }
        }
        
        if (!initUrl)
            initUrl = url;
        
        if (label && url && icon) {
            RhoRightItem *td = [[RhoRightItem alloc] init];
            td.url = url;
            td.reload = [reload isEqualToString:@"true"];
            
			td.loaded = is_use_current_view_for_tab;
			
			/*if (is_use_current_view_for_tab) {
				td.url = [[parent getCreationTimeMainView] currentLocation:-1];
			}*/
			
			if (is_use_current_view_for_tab) {
				//web_bkg_color = nil;
				is_load_initial_url = NO;
				tab_to_initial_select = i;
			}
            
            SimpleMainView *subController = nil;
            //SimpleMainView *subController = [[SimpleMainView alloc] initWithParentView:parent.view frame:rect];
            if (is_use_current_view_for_tab) {
                subController = [[SimpleMainView alloc] initWithParentView:parent.view frame:rect rhowebview:[[parent getCreationTimeMainView] detachRhoWebView]];
            }
            else {
                subController = [[SimpleMainView alloc] initWithParentView:parent.view frame:rect];
            }
            
            
			subController.title = label;
			//subController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            
			td.view = subController;
            subController.thisTabIndex = [tabs count];
            
            [tabs addObject:td];
            
            [td release];
            [subController release];
        }
    }
    
	NSDictionary* global_properties = (NSDictionary*)[bar_info objectForKey:NATIVE_BAR_PROPERTIES];
	if (global_properties != nil) {
		//background_color = (NSString*)[global_properties objectForKey:NATIVE_BAR_BACKGOUND_COLOR];
		//selected_color = (NSString*)[global_properties objectForKey:NATIVE_BAR_SELECTED_COLOR];
        
        self.on_change_tab_callback = (id<IMethodResult>)[global_properties objectForKey:NATIVE_BAR_ON_CHANGE_TAB_CALLBACK];
        if (self.on_change_tab_callback != nil) {
            //[self.on_change_tab_callback release];
        }
	}
    
    
    self.itemsData = tabs;
    [tabs release];
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.view.autoresizesSubviews = YES;
	
    self.tabindex = 0;
    //if (initUrl){
    //    [self navigateRedirect:initUrl tab:0];
	//	RhoRightItem *ri = [self.itemsData objectAtIndex:tabindex];
	//	ri.loaded = YES;
	//}
    
    
	/*if (initUrl && is_load_initial_url) {
        [self navigateRedirect:initUrl tab:0];
		RhoRightItem *ri = [self.itemsData objectAtIndex:tabindex];
		ri.loaded = YES;

    }*/
	if (tab_to_initial_select >= 0) {
		self.tabindex = tab_to_initial_select;
	}
    
    
	// set first tab
	/*SimpleMainView* v = (SimpleMainView*)[[self.itemsData objectAtIndex:0] view];
	if (v != NULL) {
		[v navigateRedirect:initUrl tab:0];
		[self.view addSubview:v.view];
		[self.view setNeedsLayout];
		[v.view setNeedsDisplay];
        [self callCallback:0];
	}*/
	
	return self;
}


- (void)loadView {
	CGRect rect = CGRectMake(0,0,200,200);//self.view.frame;
	UIView* v = [[UIView alloc] initWithFrame:rect];;
	self.view = v;
	[v release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#ifdef __IPHONE_6_0
- (BOOL)shouldAutorotate
{
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
#endif

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[[self getSimpleView:-1] didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


-(void)callCallback:(int)new_index {
    // call callback
    if (self.on_change_tab_callback != nil) {
        NSMutableDictionary* result = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", new_index], @"tab_index", [NSString stringWithFormat:@"%d", new_index], @"tabIndex", nil];
        [self.on_change_tab_callback setResult:result];
    }
}

- (SimpleMainView*) getSimpleView:(int)index {
	if ((index < 0) || (index >= [self.itemsData count])) {
		index = -1;
	}
	if (index == -1) {
		index = self.tabindex;
	}
	return [[self.itemsData objectAtIndex:index] view];
}


- (void)loadHTMLString:(NSString*)data {
	SimpleMainView* v = [self getSimpleView:-1];
	[v loadHTMLString:data];
}

- (void)back:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	[v back:index];
}

- (void)forward:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	[v forward:index];
}

- (void)navigate:(NSString*)url tab:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	[v navigate:url tab:index];
}

- (void)navigateRedirect:(NSString*)url tab:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	[v navigateRedirect:url tab:index];
}

- (void)reload:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	[v reload:index];
}

-(void)openNativeView:(UIView*)nv_view tab_index:(int)tab_index {
	SimpleMainView* v = [self getSimpleView:tab_index];
	[v openNativeView:nv_view tab_index:-1];
}

-(void)closeNativeView:(int)tab_index {
	SimpleMainView* v = [self getSimpleView:tab_index];
	[v closeNativeView:-1];
}


- (void)executeJs:(NSString*)js tab:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	[v executeJs:js tab:index];
}

- (NSString*)currentLocation:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	return [v currentLocation:index];
}

- (NSString*)get_current_url:(int)index {
	SimpleMainView* v = [self getSimpleView:index];
	return [v get_current_url:index];
}


- (void)switchTabCommand:(SimpleMainView*)new_v {
	int index = 0;
	int i;
	for (i = 0; i < [self.itemsData count]; i++) {
		if ([[self.itemsData objectAtIndex:i] view] == new_v) {
			index = i;
		}
	}
	SimpleMainView* cur_v = [self getSimpleView:tabindex];
	tabindex = index;
    RhoRightItem *ri = [self.itemsData objectAtIndex:tabindex];
    if (!ri.loaded || ri.reload) {
        if ( !ri.loaded )
        {
            const char *s = [ri.url UTF8String];
            rho_rhodesapp_load_url(s);
            ri.loaded = YES;
        }else if (ri.reload)
        {
            rho_webview_refresh(tabindex);
        }
    }
	if (cur_v == new_v) {
		return;
	}
	CGRect myframe = self.view.bounds;
	new_v.view.frame = myframe;
	[cur_v.view removeFromSuperview];
	[self.view addSubview:new_v.view];
	[self.view setNeedsLayout];
    [self callCallback:index];    
}

- (void)switchTab:(int)index {
	SimpleMainView* new_v = [self getSimpleView:index];
	[self performSelectorOnMainThread:@selector(switchTabCommand:) withObject:new_v waitUntilDone:NO];	
}

- (int)activeTab {
	return tabindex;
}

- (void)addNavBar:(NSString*)title left:(NSArray*)left right:(NSArray*)right {
	SimpleMainView* v = [self getSimpleView:index];
	[v addNavBar:title left:left right:right];
}

- (void)removeNavBar {
	SimpleMainView* v = [self getSimpleView:index];
	[v removeNavBar];
}


- (id<RhoWebView,NSObject>)getRhoWebView:(int)tab_index {
    SimpleMainView* v = [self getSimpleView:index];
    return [v getRhoWebView:tab_index];
}

- (id<RhoWebView,NSObject>)detachRhoWebView {
    SimpleMainView* v = [self getSimpleView:-1];
    return [v detachRhoWebView];
}

- (void)dealloc {
	[itemsData release];
    [super dealloc];
}








@end
