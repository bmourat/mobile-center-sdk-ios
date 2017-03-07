/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>

#import <CoreFoundation/CoreFoundation.h>

#import "MS_Reachability.h"

#pragma mark IPv6 Support

NSString *kMSReachabilityChangedNotification = @"kMSNetworkReachabilityChangedNotification";

#pragma mark - Supporting functions

#define kShouldPrintReachabilityFlags 0

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char *comment) {
#if kShouldPrintReachabilityFlags

  NSLog(@"Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n", (flags & kSCNetworkReachabilityFlagsIsWWAN) ? 'W' : '-',
        (flags & kSCNetworkReachabilityFlagsReachable) ? 'R' : '-',

        (flags & kSCNetworkReachabilityFlagsTransientConnection) ? 't' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? 'c' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) ? 'C' : '-',
        (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
        (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ? 'D' : '-',
        (flags & kSCNetworkReachabilityFlagsIsLocalAddress) ? 'l' : '-',
        (flags & kSCNetworkReachabilityFlagsIsDirect) ? 'd' : '-', comment);
#endif
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
#pragma unused(target, flags)
  NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
  NSCAssert([(__bridge NSObject *)info isKindOfClass:[MS_Reachability class]],
            @"info was wrong class in ReachabilityCallback");

  MS_Reachability *noteObject = (__bridge MS_Reachability *)info;
  // Post a notification to notify the client that the network reachability changed.
  [[NSNotificationCenter defaultCenter] postNotificationName:kMSReachabilityChangedNotification object:noteObject];
}

#pragma mark - Reachability extension

@interface MS_Reachability()

@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;

@end

#pragma mark - Reachability implementation

@implementation MS_Reachability {
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName {
  MS_Reachability *returnValue = NULL;

  const char * utf8HostName = [hostName UTF8String];
  if (!utf8HostName) {
    return returnValue;
  }

  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, (const char *_Nonnull) utf8HostName);
  if (reachability != NULL) {
    returnValue = [[self alloc] init];
    if (returnValue != NULL) {
      returnValue.reachabilityRef = reachability;
    } else {
      CFRelease(reachability);
    }
  }
  return returnValue;
}

+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress {
  SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, hostAddress);

  MS_Reachability *returnValue = NULL;

  if (reachability != NULL) {
    returnValue = [[self alloc] init];
    if (returnValue != NULL) {
      returnValue.reachabilityRef = reachability;
    } else {
      CFRelease(reachability);
    }
  }
  return returnValue;
}

+ (instancetype)reachabilityForInternetConnection {
  struct sockaddr_in zeroAddress;
  bzero(&zeroAddress, sizeof(zeroAddress));
  zeroAddress.sin_len = sizeof(zeroAddress);
  zeroAddress.sin_family = AF_INET;

  return [self reachabilityWithAddress:(const struct sockaddr *)&zeroAddress];
}

#pragma mark reachabilityForLocalWiFi
// reachabilityForLocalWiFi has been removed from the sample.  See ReadMe.md for more information.
//+ (instancetype)reachabilityForLocalWiFi

#pragma mark - Start and stop notifier

- (BOOL)startNotifier {
  BOOL returnValue = NO;
  SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

  if (SCNetworkReachabilitySetCallback(self.reachabilityRef, ReachabilityCallback, &context)) {
    if (SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
      returnValue = YES;
    }
  }

  return returnValue;
}

- (void)stopNotifier {
  if (self.reachabilityRef != NULL) {
    SCNetworkReachabilityUnscheduleFromRunLoop(self.reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  }
}

- (void)dealloc {
  [self stopNotifier];
  if (self.reachabilityRef != NULL) {
    CFRelease(self.reachabilityRef);
  }
}

#pragma mark - Network Flag Handling

- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
  PrintReachabilityFlags(flags, "networkStatusForFlags");
  if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
    // The target host is not reachable.
    return NotReachable;
  }

  NetworkStatus returnValue = NotReachable;

  if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
    /*
If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
*/
    returnValue = ReachableViaWiFi;
  }

  if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
       (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
    /*
     ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or
     higher APIs...
     */

    if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
      /*
       ... and no [user] intervention is needed...
       */
      returnValue = ReachableViaWiFi;
    }
  }

  if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
    /*
... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
*/
    returnValue = ReachableViaWWAN;
  }

  return returnValue;
}

- (BOOL)connectionRequired {
  NSAssert(self.reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
    return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
  }

  return NO;
}

- (NetworkStatus)currentReachabilityStatus {
  NSAssert(self.reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
  NetworkStatus returnValue = NotReachable;
  SCNetworkReachabilityFlags flags;

  if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
    returnValue = [self networkStatusForFlags:flags];
  }

  return returnValue;
}

@end
