//
//  ImageBenchmark.h
//  CocoaneticsBench
//
//  Created by Oliver Drobnik on 9/30/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageBenchmark : NSObject
{
	NSString *_imageName;
	NSString *_path;
	NSString *_internalOverrideSourcePath;
	
	CGFloat _quality;
	NSString *_mode;
	
	
	NSTimeInterval _timeForInit;
	NSTimeInterval _timeForDecompress;	
	NSTimeInterval _timeForDraw;
	
	BOOL _didRun;
}

- (id)initWithCrushedPNGNamed:(NSString *)imageName;

- (void)prepareAsCrushedPNG;
- (void)prepareAsUncrushedPNG;
- (void)prepareAsJPEGSourceWithQuality:(CGFloat)quality;


- (void)run;

@end

CGContextRef newBitmapContextSuitableForSize(CGSize size);
