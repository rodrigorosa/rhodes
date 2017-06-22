
#import "NotificationSingleton.h"
#import "Rhodes.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "common/RhodesApp.h"
#include "logging/RhoLog.h"

#undef DEFAULT_LOGCATEGORY
#define DEFAULT_LOGCATEGORY "Alert"

static UIAlertView *currentAlert = nil;
static BOOL is_current_alert_status = NO;

@interface AlertShowPopupTask : NSObject<UIAlertViewDelegate> {
    NSMutableArray *buttons;
    id<IMethodResult> callbackHolder;
}

@property (nonatomic,retain) NSMutableArray *buttons;

- (id)init;
- (void)dealloc;
- (void)setCallback:(id<IMethodResult>)value;
- (void)run:(NSValue*)v;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@implementation AlertShowPopupTask

@synthesize buttons;

- (id)init {
    callbackHolder = nil;
    buttons = nil;
    return self;
}

- (void)dealloc {
    callbackHolder = nil;
    self.buttons = nil;
    [super dealloc];
}

- (void)setCallback:(id<IMethodResult>)value {
    callbackHolder = value;
}

- (void)run:(NSObject*)v {
    
    NSString *title = @"Alert";
    NSString *message = @"";
    NSString *imagePath = nil;
    
	is_current_alert_status = NO;
	
    self.buttons = [NSMutableArray arrayWithCapacity:1];
    
    if ([v isKindOfClass:[NSString class]])
    {
        message = (NSString*)v;
        [buttons addObject:[NSMutableArray arrayWithObjects:@"OK", @"OK", nil]];
    }
    else if ([v isKindOfClass:[NSDictionary class]]) {
        NSDictionary* dict = (NSDictionary*)v;
        // dictionary
        NSEnumerator* enumerator = [dict keyEnumerator];
        NSObject* obj = nil;
        
        while ((obj = [enumerator nextObject]) != nil) {
            NSString* objKey = (NSString*)obj;
            NSObject* objVal = [dict objectForKey:objKey];
            NSString* objStr = @"";
            if ([objVal isKindOfClass:[NSString class]])
            {
                objStr = (NSString*)objVal;
            }
            
            if ([objKey isEqualToString:HK_TITLE]) {
                title = objStr;
            } else if ([objKey isEqualToString:HK_MESSAGE]) {
                message = objStr;
            } else if ([objKey isEqualToString:HK_ICON]) {
                imagePath = [[AppManager getApplicationsRootPath] stringByAppendingPathComponent:objStr];
            } else if ([objKey isEqualToString:@"status_type"]) {
                is_current_alert_status = YES;
            }
            else if ([objKey isEqualToString:HK_BUTTONS]) {
                
                if (![objVal isKindOfClass:[NSArray class]]) {
                    RAWLOG_ERROR("'buttons' should be array");
                    continue;
                }
                
                NSArray* arr = (NSArray*) objVal;
                
                for(id buttonVal in arr) {
                    NSString *itemId = nil;
                    NSString *itemTitle = nil;
                    
                    if ([buttonVal isKindOfClass:[NSString class]]) {
                        if ([(NSString*)buttonVal length] > 0)  {
                            itemId = (NSString*) buttonVal;
                            itemTitle = (NSString*) buttonVal;
                        }
                    } else if ([buttonVal isKindOfClass:[NSDictionary class]]) {
                        NSDictionary* btnDict = (NSDictionary*)buttonVal;
                        // get ID
                        NSObject* tmp = [btnDict objectForKey:@"id"];
                        if ([tmp isKindOfClass:[NSString class]]) {
                            itemId = (NSString*) tmp;
                        } else {
                            RAWLOG_ERROR("Illegal type of button id");
                        }
                        // get Titile
                        tmp = [btnDict objectForKey:@"title"];
                        if ([tmp isKindOfClass:[NSString class]]) {
                            itemTitle = (NSString*) tmp;
                        } else {
                            RAWLOG_ERROR("Illegal type of button title");
                        }
                    } else {
                        RAWLOG_ERROR("Illegal type of button item");
                    }
                    
                    if ((itemId == nil) || (itemTitle == nil)) {
                        RAWLOG_ERROR("Incomplete button item");
                        continue;
                    }
                    
                    NSMutableArray *btn = [NSMutableArray arrayWithCapacity:2];
                    [btn addObject:itemId];
                    [btn addObject:itemTitle];
                    [buttons addObject:btn];
                }
            }
        }
        if ([buttons count] <= 0) {
            [buttons addObject:[NSMutableArray arrayWithObjects:@"OK", @"OK", nil]];
        }
    }
    [v release];
    
	if ((currentAlert != nil) && (is_current_alert_status)) {
		currentAlert.message = message;
		return;
	}
	
    UIAlertView *alert = [[[UIAlertView alloc]
                           initWithTitle:title
                           message:message
                           delegate:self
                           cancelButtonTitle:nil
                           otherButtonTitles:nil] autorelease];
    

    // please note that there are no easy way to add image to popup
    // following code fails to addSubView
    /*if (imagePath) {
        
        UIImageView *tempImageView = [[UIImageView alloc]initWithFrame:CGRectMake(20,20,50,50)];
        tempImageView.image = [UIImage imageNamed:imagePath];
        [alert addSubView:tempImageView];
    }*/
        
        
    for (int i = 0, lim = [buttons count]; i < lim; ++i) {
        NSArray *btn = [buttons objectAtIndex:i];
        NSString *title = [btn objectAtIndex:1];
        [alert addButtonWithTitle:title];
    }
    
    [alert show];

    currentAlert = alert;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    currentAlert = nil;
	is_current_alert_status = NO;
    
    if (!callbackHolder)
        return;
    
    if (buttonIndex < 0 || buttonIndex >= [buttons count])
        return;
    
    NSArray *btn = [buttons objectAtIndex:buttonIndex];
    NSString *itemId = [[btn objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *itemTitle = [[btn objectAtIndex:1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableDictionary* callbackResult = [NSMutableDictionary dictionaryWithObjectsAndKeys:itemId, HK_BUTTON_ID, itemTitle, HK_BUTTON_TITLE, [NSNumber numberWithInt:buttonIndex], HK_BUTTON_INDEX, nil];
    
    [callbackHolder setResult:callbackResult];
    [self release];
}

@end

@interface AlertHidePopupTask : NSObject {}
+ (void)run;
@end

@implementation AlertHidePopupTask
+ (void)run {
    if (!currentAlert)
        return;
    [currentAlert dismissWithClickedButtonIndex:-1 animated:NO];
    currentAlert = nil;
	is_current_alert_status = NO;
}
@end


@interface AlertVibrateTask : NSObject {}
+ (void)run;
@end

@implementation AlertVibrateTask
+ (void)run {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}
@end

@interface AlertPlayFileTask : NSObject {}
+ (void)run:(NSString*)file :(NSString*)type;
@end

@implementation AlertPlayFileTask
+ (void)run:(NSString*)file :(NSString*)type {
    [[Rhodes sharedInstance] playStart:file mediaType:type];
}
@end

@implementation NotificationSingleton

-(void) showPopup:(NSDictionary*)propertyMap methodResult:(id<IMethodResult>)methodResult {
    id runnable = [[AlertShowPopupTask alloc] init];
    [propertyMap retain];
    if ([methodResult hasCallback])
    {
        [runnable setCallback:methodResult];
    }
    [Rhodes performOnUiThread:runnable arg:propertyMap wait:NO];
}

-(void) hidePopup:(id<IMethodResult>)methodResult {
    id runnable = [AlertHidePopupTask class];
    [Rhodes performOnUiThread:runnable wait:NO];
}

-(void) showStatus:(NSString*)title status_text:(NSString*)status_text hide_button_label:(NSString*)hide_button_label methodResult:(id<IMethodResult>)methodResult{
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, HK_TITLE, status_text, HK_MESSAGE, [NSNumber numberWithBool:true], @"status_type", [NSMutableArray arrayWithObject:hide_button_label], @"buttons",  nil];
    
    [params retain];
    id runnable = [[AlertShowPopupTask alloc] init];
    [Rhodes performOnUiThread:runnable arg:params wait:NO];
}

-(void) playFile:(NSString*)path media_type:(NSString*)media_type methodResult:(id<IMethodResult>)methodResult{
    id runnable = [AlertPlayFileTask class];
    [Rhodes performOnUiThread:runnable arg:path arg:media_type wait:NO];
}

-(void) beep:(NSDictionary*)propertyMap methodResult:(id<IMethodResult>)methodResult{
    // NYI
}

-(void) vibrate:(int)duration methodResult:(id<IMethodResult>)methodResult{
    id runnable = [AlertVibrateTask class];
    [Rhodes performOnUiThread:runnable wait:NO];
}

@end