#import "Log.h"
#import "IRKit.h"
#import "IRHTTPClient.h"
#import "IRViewCustomizer.h"

@interface IRKit ()

@property (nonatomic) id terminateObserver;
@property (nonatomic) id becomeActiveObserver;
@property (nonatomic) id enterBackgroundObserver;
@property (nonatomic, copy) NSString *apikey; // allow internal write

@end

@implementation IRKit

+ (instancetype)sharedInstance {
    static IRKit *instance;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        instance = [[IRKit alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    _peripherals = [[IRPeripherals alloc] init];

    __weak IRKit *_self = self;
    _terminateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *note) {
        LOG(@"terminating");
        [_self save];
    }];
    static bool first = YES;
    _becomeActiveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification *note) {
        LOG(@"became active");
        if (first) {
            // ensureRegistered.. should be called first time in startWithAPIKey:
            first = NO;
        }
        else {
            [IRHTTPClient ensureRegisteredAndCall:^(NSError *error) {
                    LOG(@"error: %@", error);
                }];
        }
    }];
    _enterBackgroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                                                 object:nil
                                                                                  queue:[NSOperationQueue mainQueue]
                                                                             usingBlock:^(NSNotification *note) {
        LOG(@"entered background");
    }];
    [IRViewCustomizer sharedInstance]; // init

    return self;
}

- (void)dealloc {
    LOG_CURRENT_METHOD;
    [[NSNotificationCenter defaultCenter] removeObserver:_terminateObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_becomeActiveObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_enterBackgroundObserver];
}

+ (void)startWithAPIKey:(NSString *)apikey {
    LOG_CURRENT_METHOD;
    [IRKit sharedInstance].apikey = apikey;

    [IRHTTPClient ensureRegisteredAndCall:^(NSError *error) {
        LOG(@"error: ", error);
        if (!error) {
            IRKitLog(@"successfully registered!");
        }
    }];
}

- (void)save {
    LOG_CURRENT_METHOD;
    [_peripherals save];
}

- (NSUInteger)countOfReadyPeripherals {
    LOG_CURRENT_METHOD;
    return _peripherals.countOfReadyPeripherals;
}

#pragma mark - Private

@end
