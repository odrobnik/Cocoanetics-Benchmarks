//
//  BatteryLogger.m
//  CocoaneticsBench
//
//  Created by Oliver Drobnik on 3/16/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

#import "BatteryLogger.h"

@interface BatteryLogger ()

- (void)batteryLevelChanged:(NSNotification *)notification;
- (void)batteryStateChanged:(NSNotification *)notification;

@end


@implementation BatteryLogger
{
}


+ (BatteryLogger *)sharedLogger
{
	static BatteryLogger *_sharedInstance = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[BatteryLogger alloc] init];
	});
	
	return _sharedInstance;
}

- (void)startLogging
{
	UIDevice *device = [UIDevice currentDevice];
	
	if ([device isBatteryMonitoringEnabled])
	{
		// already logging
		return;
	}
	
	[device setBatteryMonitoringEnabled:YES];
	
	NSNotificationCenter *notifications = [NSNotificationCenter defaultCenter];
	
	[notifications addObserver:self selector:@selector(batteryStateChanged:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
	[notifications addObserver:self selector:@selector(batteryLevelChanged:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
	
	// log initial
	[self batteryStateChanged:nil];
	[self batteryLevelChanged:nil];
}

- (void)stopLogging
{
	UIDevice *device = [UIDevice currentDevice];
	
	if (![device isBatteryMonitoringEnabled])
	{
		// already not logging
		return;
	}

	
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:NO];
	
	NSNotificationCenter *notifications = [NSNotificationCenter defaultCenter];
	
	[notifications removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
	[notifications removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
}

#pragma mark Notifications
- (void)batteryStateChanged:(NSNotification *)notification
{
	UIDevice *device = [UIDevice currentDevice];
	
	switch (device.batteryState) 
	{
		case UIDeviceBatteryStateUnknown:
			NSLog(@"State: Unknown");
			break;
			
		case UIDeviceBatteryStateUnplugged:
			NSLog(@"State: Unplugged");
			break;

		case UIDeviceBatteryStateCharging:
			NSLog(@"State: Charging");
			break;
			
		case UIDeviceBatteryStateFull:
			NSLog(@"State: Full");
			break;
	}
}

- (void)batteryLevelChanged:(NSNotification *)notification
{
	UIDevice *device = [UIDevice currentDevice];

	NSLog(@"Level: %0.2f%%", device.batteryLevel*100.0f);
}




@end
