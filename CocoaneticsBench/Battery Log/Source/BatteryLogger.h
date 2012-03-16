//
//  BatteryLogger.h
//  CocoaneticsBench
//
//  Created by Oliver Drobnik on 3/16/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BatteryLogger : NSObject

+ (BatteryLogger *)sharedLogger;

- (void)startLogging;
- (void)stopLogging;

@end
