//
//  ImageBenchmark.m
//  CocoaneticsBench
//
//  Created by Oliver Drobnik on 9/30/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "ImageBenchmark.h"

#import <ImageIO/ImageIO.h>


// enable the following line to benchmark HW decompression
//#define USE_CIIMAGE


@implementation ImageBenchmark

- (id)initWithCrushedPNGNamed:(NSString *)imageName
{
	self = [super init];
	if (self)
	{
		_path =  [[[NSBundle mainBundle] pathForResource:imageName ofType:@"png"] copy];
		_imageName = [imageName copy];
	}
	
	return self;
}

- (void)dealloc
{
	[_path release];
	[_imageName release];
	[_internalOverrideSourcePath release];
	
	[super dealloc];
}


- (NSString *)description
{
	NSString *fileName = [_path lastPathComponent];
	
	if (_didRun)
	{
		NSString *benchmarkModeString = nil;
		
		if (!_mode)
		{
			benchmarkModeString = @"Crushed PNG";
		}
		else if ([_mode isEqualToString:@"JPG"])
		{
			benchmarkModeString = [NSString stringWithFormat:@"JPG %.0f%%", _quality*100.0];
		}
		else if ([_mode isEqualToString:@"PNG"])
		{
			benchmarkModeString = [NSString stringWithFormat:@"PNG"];
		}
		
		return [NSString stringWithFormat:@"%@ (%@) init: %.0f ms decompress: %.0f ms draw: %.0f ms total %.0f ms", fileName, benchmarkModeString, _timeForInit*1000.0, _timeForDecompress*1000.0, _timeForDraw*1000.0, (_timeForInit + _timeForDecompress + _timeForDraw) * 1000.0];
	}
	else
	{
		return [NSString stringWithFormat:@"%@ not run", fileName];
	}
}

- (void)prepareAsCrushedPNG
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *fileName = [[[_path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"crushed.png"];
	
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];	
	NSString *cacheImagePath = [cachesPath stringByAppendingPathComponent:fileName];	
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath:cacheImagePath])
	{
		[fileManager copyItemAtPath:_path toPath:cacheImagePath error:NULL];
	}
	
	[_internalOverrideSourcePath release];
	_internalOverrideSourcePath = [cacheImagePath copy];
	
	[_mode release];
	_mode = nil;
	_quality = 0;
	
	[pool drain];

}

- (void)prepareAsUncrushedPNG
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *fileName = [[[_path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"uncrushed.png"];
	
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];	
	NSString *cacheImagePath = [cachesPath stringByAppendingPathComponent:fileName];
	
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath:cacheImagePath])
	{
		UIImage *image = [UIImage imageWithContentsOfFile:_path];
		UIGraphicsBeginImageContext(image.size);
		
		[image drawAtPoint:CGPointZero];
		
		UIImage *rawImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		NSData *imageData = UIImagePNGRepresentation(rawImage);
		
		
		[imageData writeToFile:cacheImagePath atomically:NO];
	}
	
	[_internalOverrideSourcePath release];
	_internalOverrideSourcePath = [cacheImagePath copy];
	
	[_mode release];
	_mode = @"PNG";
	_quality = 0;
	
	[pool drain];
}

- (void)prepareAsJPEGSourceWithQuality:(CGFloat)quality
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *fileName = [[[_path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithFormat:@"%.0f.jpg", quality*100.0]];
	
	NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];	
	NSString *cacheImagePath = [cachesPath stringByAppendingPathComponent:fileName];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (![fileManager fileExistsAtPath:cacheImagePath])
	{
		UIImage *image = [UIImage imageWithContentsOfFile:_path];
		UIGraphicsBeginImageContext(image.size);
		
		[image drawAtPoint:CGPointZero];
		
		UIImage *rawImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		NSData *imageData = UIImageJPEGRepresentation(rawImage, quality);
		
		
		[imageData writeToFile:cacheImagePath atomically:NO];
	}
	
	[_internalOverrideSourcePath release];
	_internalOverrideSourcePath = [cacheImagePath copy];
	
	[_mode release];
	_mode = @"JPG";
	_quality = quality;
	
	[pool drain];
}

- (void)decompressImage:(UIImage *)image
{
	UIGraphicsBeginImageContext(CGSizeMake(1, 1));
	
	//[image drawAtPoint:CGPointZero];
	
	UIGraphicsEndImageContext();
}

- (void)drawImage:(UIImage *)image
{
	UIGraphicsBeginImageContext(image.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetShouldAntialias(context, NO);
	CGContextSetInterpolationQuality(context, kCGInterpolationNone);
	CGContextSetBlendMode(context, kCGBlendModeCopy);

	CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
	
	UIGraphicsEndImageContext();
}

- (UIImage *)sourceImage
{
	NSURL *url = [NSURL fileURLWithPath:_internalOverrideSourcePath?_internalOverrideSourcePath:_path];

	
#ifdef USE_CIIMAGE
	CIImage *ciImage = [CIImage imageWithContentsOfURL:url];
	
	UIImage *retImage = [UIImage imageWithCIImage:ciImage];
#else
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImageSourceShouldCache];
	
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, (CFDictionaryRef)nil);
	CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)dict);
	
	UIImage *retImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CFRelease(source);
#endif

	return retImage;
}

- (void)run
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	CFAbsoluteTime before = CFAbsoluteTimeGetCurrent();
	UIImage *image = [self sourceImage];
	CFAbsoluteTime after = CFAbsoluteTimeGetCurrent();
	_timeForInit = after - before;
	
#ifndef USE_CIIMAGE
	// for CIImage->UIImage the decompression already took place in init
	before = CFAbsoluteTimeGetCurrent();
	[self decompressImage:image];
	after = CFAbsoluteTimeGetCurrent();
	_timeForDecompress = after - before;
#endif

	before = CFAbsoluteTimeGetCurrent();
	[self drawImage:image];
	after = CFAbsoluteTimeGetCurrent();
	_timeForDraw = after - before;

	_didRun = YES;
	
	[pool drain];
}


@end
