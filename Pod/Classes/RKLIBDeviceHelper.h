//
//  RKLIBDeviceHelper.h
//  Pods
//
//  Created by Ronny Meissner on 20/09/14.
//
//

#import <Foundation/Foundation.h>

@interface RKLIBDeviceHelper : NSObject
@property (assign) BOOL hasGPSSensor;
@property (assign) BOOL hasRetinaDisplay;
@property (assign) float systemVersion;
+ (instancetype)sharedHelperInstance;
+ (NSString *)currentlanguageCode;
+ (NSString *)separatedStringFromArray:(NSArray *)strings WithSeparationString:(NSString *)sep;
+ (UIImage *)snapshotFromView:(UIView *)view;
@end
