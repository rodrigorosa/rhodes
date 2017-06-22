/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

 /**
  * Modifications made by Appcelerator, Inc. licensed under the
  * same license as above.
  */

#import "iPhoneSimulator.h"
#import "nsprintf.h"


NSString* const kSimulatorFrameworkRelativePath = @"Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/DVTiPhoneSimulatorRemoteClient.framework";
NSString* const kDVTFoundationRelativePath = @"../SharedFrameworks/DVTFoundation.framework";
NSString* const kDevToolsFoundationRelativePath = @"../OtherFrameworks/DevToolsFoundation.framework";
NSString* const kSimulatorRelativePath = @"Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app";


@interface DVTPlatform : NSObject
  +(BOOL)loadAllPlatformsReturningError:(id*)o;
@end



/**
 * A simple iPhoneSimulatorRemoteClient framework.
 */
@implementation iPhoneSimulator



// Helper to find a class by name and die if it isn't found.
-(Class) FindClassByName:(NSString*) nameOfClass {
    Class theClass = NSClassFromString(nameOfClass);
    if (!theClass) {
        nsfprintf(stderr,@"Failed to find class %@ at runtime.", nameOfClass);
        exit(EXIT_FAILURE);
    }
    return theClass;
}

// Loads the Simulator framework from the given developer dir.
-(NSBundle*) LoadSimulatorFramework:(NSString*) developerDir {
    // The Simulator framework depends on some of the other Xcode private
    // frameworks; manually load them first so everything can be linked up.
    NSString* dvtFoundationPath = [developerDir
                                   stringByAppendingPathComponent:kDVTFoundationRelativePath];
    NSBundle* dvtFoundationBundle =
    [NSBundle bundleWithPath:dvtFoundationPath];
    if (![dvtFoundationBundle load])
    return nil;
    
    NSString* devToolsFoundationPath = [developerDir
                                        stringByAppendingPathComponent:kDevToolsFoundationRelativePath];
    NSBundle* devToolsFoundationBundle =
    [NSBundle bundleWithPath:devToolsFoundationPath];
    if (![devToolsFoundationBundle load])
    return nil;
    
    // Prime DVTPlatform.
    NSError* error;
    Class DVTPlatformClass = [self FindClassByName:@"DVTPlatform"];
    if (![DVTPlatformClass loadAllPlatformsReturningError:&error]) {
        nsfprintf(stderr, @"Unable to loadAllPlatformsReturningError. Error: %@",
                  [error localizedDescription]);
        return nil;
    }
    
    NSString* simBundlePath = [developerDir
                               stringByAppendingPathComponent:kSimulatorFrameworkRelativePath];
    NSBundle* simBundle = [NSBundle bundleWithPath:simBundlePath];
    if (![simBundle load])
    return nil;
    return simBundle;
}


// Finds the developer dir via xcode-select or the DEVELOPER_DIR environment
// variable.
NSString* FindDeveloperDir() {
    // Check the env first.
    NSDictionary* env = [[NSProcessInfo processInfo] environment];
    NSString* developerDir = [env objectForKey:@"DEVELOPER_DIR"];
    if ([developerDir length] > 0)
    return developerDir;
    
    // Go look for it via xcode-select.
    NSTask* xcodeSelectTask = [[[NSTask alloc] init] autorelease];
    [xcodeSelectTask setLaunchPath:@"/usr/bin/xcode-select"];
    [xcodeSelectTask setArguments:[NSArray arrayWithObject:@"-print-path"]];
    
    NSPipe* outputPipe = [NSPipe pipe];
    [xcodeSelectTask setStandardOutput:outputPipe];
    NSFileHandle* outputFile = [outputPipe fileHandleForReading];
    
    [xcodeSelectTask launch];
    NSData* outputData = [outputFile readDataToEndOfFile];
    [xcodeSelectTask terminate];
    
    NSString* output =
    [[[NSString alloc] initWithData:outputData
                           encoding:NSUTF8StringEncoding] autorelease];
    output = [output stringByTrimmingCharactersInSet:
              [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([output length] == 0)
    output = nil;
    return output;
}



/**
 * Print usage.
 */
- (void) printUsage {
    fprintf(stderr, "Usage: iphonesim <options> <command> ...\n");
    fprintf(stderr, "Commands:\n");
    fprintf(stderr, "  showsdks\n");
    fprintf(stderr, "  launch <application path> [sdkversion] [family] [logout file path] [uuid]\n");
}


/**
 * List available SDK roots.
 */
- (int) showSDKs {
    NSArray *roots = [DTiPhoneSimulatorSystemRoot knownRoots];

    nsprintf(@"Simulator SDK Roots:");
    for (DTiPhoneSimulatorSystemRoot *root in roots) {
        nsfprintf(stderr, @"'%@' (%@)\n\t%@", [root sdkDisplayName], [root sdkVersion], [root sdkRootPath]);
    }

    return EXIT_SUCCESS;
}

- (void) session: (DTiPhoneSimulatorSession *) session didEndWithError: (NSError *) error {
    nsprintf(@"Session did end with error %@", error);
    
    if (error != nil)
        exit(EXIT_FAILURE);

    exit(EXIT_SUCCESS);
}


- (void) session: (DTiPhoneSimulatorSession *) session didStart: (BOOL) started withError: (NSError *) error {
    if (started) {
        nsprintf(@"Session started");
    } else {
        nsprintf(@"Session could not be started: %@", error);
        exit(EXIT_FAILURE);
    }
}


/**
 * Launch the given Simulator binary.
 */
- (int) launchApp: (NSString *) path withFamily:(NSString*)family logout:(NSString*)logout uuid:(NSString*)uuid{
    DTiPhoneSimulatorApplicationSpecifier *appSpec;
    DTiPhoneSimulatorSessionConfig *config;
    DTiPhoneSimulatorSession *session;
    NSError *error;

    /* Create the app specifier */
    appSpec = [DTiPhoneSimulatorApplicationSpecifier specifierWithApplicationPath: path];
    if (appSpec == nil) {
        nsprintf(@"Could not load application specification for %s", path);
        return EXIT_FAILURE;
    }
    nsprintf(@"App Spec: %@", appSpec);

    /* Load the default SDK root */
    
    nsprintf(@"SDK Root: %@", sdkRoot);

    /* Set up the session configuration */
    config = [[[DTiPhoneSimulatorSessionConfig alloc] init] autorelease];
    [config setApplicationToSimulateOnStart: appSpec];
    [config setSimulatedSystemRoot: sdkRoot];
    [config setSimulatedApplicationShouldWaitForDebugger: NO];

	if (logout != nil) {
		nsprintf(@"using logout file: %@",logout);
		[config setSimulatedApplicationStdErrPath:logout];	
		[config setSimulatedApplicationStdOutPath:logout];	
	}
	
    [config setSimulatedApplicationLaunchArgs: [NSArray array]];
    [config setSimulatedApplicationLaunchEnvironment: [NSDictionary dictionary]];

    [config setLocalizedClientName: @"Rhodes Developer"];

	// this was introduced in 3.2 of SDK
	if ([config respondsToSelector:@selector(setSimulatedDeviceFamily:)])
	{
		if (family == nil)
		{
			family = @"iphone";
		}

		nsprintf(@"using device family %@",family);

		if ([family isEqualToString:@"ipad"])
		{
			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:2]];
            [config setSimulatedDeviceInfoName:@"iPad"];
		}
		else
		{
            [config setSimulatedDeviceInfoName:@"iPhone"];
			if ([family isEqualToString:@"iphone4"])
			{
				[config setSimulatedDeviceFamily:[NSNumber numberWithInt:3]];
			}
			else
			{
				[config setSimulatedDeviceFamily:[NSNumber numberWithInt:1]];
			}
		}
	}
    
    

    /* Start the session */
    session = [[[DTiPhoneSimulatorSession alloc] init] autorelease];
    [session setDelegate: self];
    [session setSimulatedApplicationPID: [NSNumber numberWithInt: 35]];
	if (uuid!=nil)
	{
		[session setUuid:uuid];
	}

    if (![session requestStartWithConfig: config timeout: 180 error: &error]) {
        nsprintf(@"Could not start simulator session: %@", error);
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}


/**
 * Execute 'main'
 */
- (void) runWithArgc: (int) argc argv: (char **) argv {
    /* Read the command */
    if (argc < 2) {
        [self printUsage];
        exit(EXIT_FAILURE);
    }

    NSString* developerDir = FindDeveloperDir();
    if (!developerDir) {
        nsprintf(@"Unable to find developer directory.");
        exit(EXIT_FAILURE);
    }
    [self LoadSimulatorFramework:developerDir];
    
    if (strcmp(argv[1], "showsdks") == 0) {
        exit([self showSDKs]);
    }
    else if (strcmp(argv[1], "launch") == 0) {
        /* Requires an additional argument */
        if (argc < 3) {
            fprintf(stderr, "Missing application path argument\n");
            [self printUsage];
            exit(EXIT_FAILURE);
        }
        if (argc > 3) {
            NSString* ver = [NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding];
            NSArray *roots = [DTiPhoneSimulatorSystemRoot knownRoots];
            for (DTiPhoneSimulatorSystemRoot *root in roots) {
                NSString *v = [root sdkVersion];
                if ([v isEqualToString:ver])
                {
                    sdkRoot = root;
                    break;
                }
            }
            if (sdkRoot == nil)
            {
                fprintf(stderr,"Unknown or unsupported SDK version: %s\n",argv[3]);
                [self showSDKs];
                exit(EXIT_FAILURE);
            }
        }
        else {
            sdkRoot = [DTiPhoneSimulatorSystemRoot defaultRoot];
        }

        /* Don't exit, adds to runloop */
		NSString *family = nil;
		NSString *uuid = nil;
		NSString *logout = nil;
		if (argc > 4)
		{
			family = [NSString stringWithUTF8String:argv[4]];
		}
		if (argc > 5)
		{
			logout = [NSString stringWithUTF8String:argv[5]];
		}
		if (argc > 6)
		{
			uuid = [NSString stringWithUTF8String:argv[5]];
		}
        [self launchApp: [NSString stringWithUTF8String: argv[2]] withFamily:family logout:logout uuid:uuid];
    } else {
        fprintf(stderr, "Unknown command\n");
        [self printUsage];
        exit(EXIT_FAILURE);
    }
}

@end
