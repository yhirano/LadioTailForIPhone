//
//  AdLantisConversion.h
//  adlantis_iphone_sdk
//
//  Created on 10/3/12.
//
//

#import <Foundation/Foundation.h>

@interface AdLantisConversion : NSObject

+ (id)conversionWithTag:(NSString*)tag;

- (id)initWithTag:(NSString*)tag;

- (void)send;

- (NSString*)tag;

@end

@interface AdLantisConversionTest : AdLantisConversion

@end
