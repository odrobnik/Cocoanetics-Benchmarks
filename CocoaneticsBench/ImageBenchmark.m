//
//  ImageBenchmark.m
//  CocoaneticsBench
//
//  Created by Oliver Drobnik on 9/30/11.
//  Copyright 2011 Cocoanetics. All rights reserved.
//

#import "ImageBenchmark.h"

#import <ImageIO/ImageIO.h>

CGContextRef newBitmapContextSuitableForSize(CGSize size)
{
	int pixelsWide = size.width;
	int pixelsHigh = size.height;
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
	// void *          bitmapData;
	// int             bitmapByteCount;
    int             bitmapBytesPerRow;
	
	bitmapBytesPerRow   = (pixelsWide * 4); //4 
	// bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
	
	
	/* bitmapData = malloc( bitmapByteCount );
	 
	 memset(bitmapData, 0, bitmapByteCount);  // set memory to black, alpha 0
	 
	 if (bitmapData == NULL)
	 {
	 return NULL;
	 }
	 */
	colorSpace = CGColorSpaceCreateDeviceRGB();  	
	
	
	context = CGBitmapContextCreate ( NULL, //bitmapData, // let the device handle the memory
									 pixelsWide,
									 pixelsHigh,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease( colorSpace );
	
	
    if (context== NULL)
    {
		// free (bitmapData);
        return NULL;
    }
	
    return context;
}


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
			benchmarkModeString = [NSString stringWithFormat:@"PNG", _quality*100.0];
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
	
	[image drawAtPoint:CGPointZero];
	
	UIGraphicsEndImageContext();
}

- (void)drawImage:(UIImage *)image
{
	CGContextRef context = newBitmapContextSuitableForSize(image.size);
	CGContextSetShouldAntialias(context, NO);
	CGContextSetInterpolationQuality(context, kCGInterpolationNone);
	CGContextSetBlendMode(context, kCGBlendModeCopy);

	CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
	
	CGContextRelease(context);
}

- (UIImage *)sourceImage
{
//	if (!_mode)
//	{
//		return [UIImage imageNamed:_imageName];
//	}
	
	NSURL *url = [NSURL fileURLWithPath:_internalOverrideSourcePath?_internalOverrideSourcePath:_path];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImageSourceShouldCache];
	
	CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)url, (CFDictionaryRef)nil);
	CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (CFDictionaryRef)dict);
	
	UIImage *retImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CFRelease(source);
	
	return retImage;
//	return [UIImage imageWithContentsOfFile:_internalOverrideSourcePath?_internalOverrideSourcePath:_path];
}

- (void)run
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSDate *before = [NSDate date];
	UIImage *image = [self sourceImage];
	NSDate *after = [NSDate date];
	_timeForInit = [after timeIntervalSinceDate:before];
	
	
	before = [NSDate date];
	[self decompressImage:image];
	after = [NSDate date];
	_timeForDecompress = [after timeIntervalSinceDate:before];

	before = [NSDate date];
	[self drawImage:image];
	after = [NSDate date];
	_timeForDraw = [after timeIntervalSinceDate:before];

	_didRun = YES;
	
	[pool drain];
}


@end
