// LockwrightHaptics ObjC++ bridge to Core Haptics (docs/TECH.md §2.1).
// Resistance = continuous CHHapticAdvancedPatternPlayer in a loop with dynamic
// parameters sent at <= 60 Hz; clicks = transient events in a separate player;
// engine.stoppedHandler/resetHandler restart the engine; UIImpactFeedbackGenerator
// fallback; devices without haptics (iPad) log only.
#import <Foundation/Foundation.h>
#import <CoreHaptics/CoreHaptics.h>
#import <AVFAudio/AVFAudio.h>
#import <UIKit/UIKit.h>

#include "lockwright_haptics/lockwright_haptics.h"

@interface LockwrightHapticsImpl : NSObject
@property (nonatomic, strong) CHHapticEngine *engine;
@property (nonatomic, strong) id<CHHapticAdvancedPatternPlayer> resistancePlayer;
@property (nonatomic, strong) id<CHHapticAdvancedPatternPlayer> transientPlayer;
@property (nonatomic, strong) UIImpactFeedbackGenerator *fallbackGenerator;
@property (nonatomic, assign) BOOL supportsCoreHaptics;
- (instancetype)init;
- (void)playEvent:(NSString *)event intensity:(float)intensity material:(NSString *)material;
- (void)beginContinuous:(NSString *)cid;
- (void)updateContinuous:(NSString *)cid intensity:(float)intensity sharpness:(float)sharpness;
- (void)endContinuous:(NSString *)cid;
- (void)stopAll;
- (NSDictionary *)capabilities;
@end

@implementation LockwrightHapticsImpl {
    BOOL _resistanceActive;
    float _resistanceIntensity;
    float _resistanceSharpness;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware.supportsHaptics;
        _resistanceActive = NO;
        _resistanceIntensity = 0.0f;
        _resistanceSharpness = 0.3f;
        if (_supportsCoreHaptics) {
            [self setupEngine];
        } else {
            _fallbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
            NSLog(@"[LockwrightHaptics] no Core Haptics (iPad?) — UIImpactFeedbackGenerator fallback / log only");
        }
        // Low-latency audio session: 5 ms IO buffer, .ambient mixes with system (TECH.md §1.6).
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryAmbient error:nil];
        [session setPreferredIOBufferDuration:0.005 error:nil];
    }
    return self;
}

- (void)setupEngine {
    NSError *engineErr = nil;
    _engine = [[CHHapticEngine alloc] initAndReturnError:&engineErr];
    __weak typeof(self) weakSelf = self;
    _engine.stoppedHandler = ^(CHHapticEngineStoppedReason reason) {
        NSLog(@"[LockwrightHaptics] engine stopped (%ld), restarting", (long)reason);
        [weakSelf restartEngine];
    };
    _engine.resetHandler = ^{ [weakSelf restartEngine]; };
    NSError *err = nil;
    [_engine startAndReturnError:&err];
    if (err) NSLog(@"[LockwrightHaptics] engine start error: %@", err);
    [self buildPlayers];
}

- (void)restartEngine {
    NSError *err = nil;
    [_engine startAndReturnError:&err];
    [self buildPlayers];
    if (_resistanceActive) [self sendResistanceParameters];
}

- (void)buildPlayers {
    // Continuous resistance: looped pattern with dynamic intensity/sharpness params.
    CHHapticEventParameter *inten = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:0.0f];
    CHHapticEventParameter *sharp = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.3f];
    CHHapticEvent *cont = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous
                                                       parameters:@[inten, sharp]
                                                     relativeTime:0 duration:1.0];
    NSError *err = nil;
    CHHapticPattern *resPattern = [[CHHapticPattern alloc] initWithEvents:@[cont] parameters:@[] error:&err];
    _resistancePlayer = [_engine createAdvancedPlayerWithPattern:resPattern error:&err];
    // Transients in a separate player so the intensity curve never scales clicks.
    CHHapticEvent *t = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticTransient
                                                     parameters:@[] relativeTime:0];
    CHHapticPattern *tPattern = [[CHHapticPattern alloc] initWithEvents:@[t] parameters:@[] error:&err];
    _transientPlayer = [_engine createAdvancedPlayerWithPattern:tPattern error:&err];
}

- (float)materialScale:(NSString *)material {
    if ([material isEqualToString:@"steel"]) return 1.05f;
    if ([material isEqualToString:@"iron"]) return 1.10f;
    if ([material isEqualToString:@"wood"]) return 0.90f;
    return 1.0f;
}

- (void)playEvent:(NSString *)event intensity:(float)intensity material:(NSString *)material {
    float i = intensity * [self materialScale:material];
    if (i <= 0.0f) return;
    if (!_supportsCoreHaptics) {
        [_fallbackGenerator impactOccurredWithIntensity:i];
        return;
    }
    float sharp = 0.7f;
    if ([event isEqualToString:@"set"]) sharp = 0.85f;
    else if ([event isEqualToString:@"false_set"]) sharp = 0.75f;
    else if ([event isEqualToString:@"overset"]) sharp = 0.10f;
    else if ([event isEqualToString:@"break"]) sharp = 1.0f;
    // transient pattern with absolute intensity/sharpness baked into the event
    NSError *err = nil;
    CHHapticEventParameter *pI = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:i];
    CHHapticEventParameter *pS = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:sharp];
    CHHapticEvent *e = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticTransient parameters:@[pI, pS] relativeTime:0];
    CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[e] parameters:@[] error:&err];
    NSError *err = nil;
    [_transientPlayer startAtTime:CHHapticTimeImmediate error:&err];
    (void)pattern;
}

- (void)beginContinuous:(NSString *)cid {
    if (!_supportsCoreHaptics || ![cid isEqualToString:@"tension_resistance"]) return;
    _resistanceActive = YES;
    NSError *err = nil;
    [_resistancePlayer startAtTime:CHHapticTimeImmediate error:&err];
    [self sendResistanceParameters];
}

- (void)updateContinuous:(NSString *)cid intensity:(float)intensity sharpness:(float)sharpness {
    if (![cid isEqualToString:@"tension_resistance"]) return;
    _resistanceIntensity = intensity;
    _resistanceSharpness = sharpness;
    [self sendResistanceParameters];
}

- (void)sendResistanceParameters {
    if (!_resistanceActive || !_resistancePlayer) return;
    CHHapticDynamicParameter *pI = [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:_resistanceIntensity];
    CHHapticDynamicParameter *pS = [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:_resistanceSharpness];
    NSError *err = nil;
    [_resistancePlayer sendParameters:@[pI, pS] atTime:CHHapticTimeImmediate error:&err];
}

- (void)endContinuous:(NSString *)cid {
    if (![cid isEqualToString:@"tension_resistance"]) return;
    _resistanceActive = NO;
    NSError *err = nil;
    [_resistancePlayer stopAtTime:CHHapticTimeImmediate error:&err];
}

- (void)stopAll {
    _resistanceActive = NO;
    [_resistancePlayer stopAtTime:CHHapticTimeImmediate error:nil];
    [_transientPlayer stopAtTime:CHHapticTimeImmediate error:nil];
}

- (NSDictionary *)capabilities {
    return @{
        @"tier": _supportsCoreHaptics ? @"H3" : @"H1",
        @"primitives": @[@"ALL"],
        @"amplitude_control": @YES,
        @"envelope": @YES,
        @"native": @YES
    };
}

@end

namespace lockwright {

void LockwrightHaptics::_bind_methods() {
	godot::ClassDB::bind_method(godot::D_METHOD("play", "event", "intensity", "material"), &LockwrightHaptics::play);
	godot::ClassDB::bind_method(godot::D_METHOD("begin_continuous", "id"), &LockwrightHaptics::begin_continuous);
	godot::ClassDB::bind_method(godot::D_METHOD("update_continuous", "id", "intensity", "sharpness"), &LockwrightHaptics::update_continuous);
	godot::ClassDB::bind_method(godot::D_METHOD("end_continuous", "id"), &LockwrightHaptics::end_continuous);
	godot::ClassDB::bind_method(godot::D_METHOD("capabilities"), &LockwrightHaptics::capabilities);
	godot::ClassDB::bind_method(godot::D_METHOD("stop_all"), &LockwrightHaptics::stop_all);
}

LockwrightHaptics::LockwrightHaptics() {
	engine_impl = (void *)CFBridgingRetain([[LockwrightHapticsImpl alloc] init]);
}

LockwrightHaptics::~LockwrightHaptics() {
	if (engine_impl) {
		LockwrightHapticsImpl *impl = (LockwrightHapticsImpl *)CFBridgingRelease(engine_impl);
		[impl stopAll];
		engine_impl = nullptr;
	}
}

void LockwrightHaptics::play(const godot::StringName &event, double intensity, const godot::StringName &material) {
	[(__bridge LockwrightHapticsImpl *)engine_impl playEvent:(__bridge NSString *)godot::String(event).utf8().get_data()
	                                                  intensity:(float)intensity
	                                                   material:(__bridge NSString *)godot::String(material).utf8().get_data()];
}

void LockwrightHaptics::begin_continuous(const godot::StringName &id) {
	[(__bridge LockwrightHapticsImpl *)engine_impl beginContinuous:(__bridge NSString *)godot::String(id).utf8().get_data()];
}

void LockwrightHaptics::update_continuous(const godot::StringName &id, double intensity, double sharpness) {
	[(__bridge LockwrightHapticsImpl *)engine_impl updateContinuous:(__bridge NSString *)godot::String(id).utf8().get_data()
	                                                      intensity:(float)intensity
	                                                      sharpness:(float)sharpness];
}

void LockwrightHaptics::end_continuous(const godot::StringName &id) {
	[(__bridge LockwrightHapticsImpl *)engine_impl endContinuous:(__bridge NSString *)godot::String(id).utf8().get_data()];
}

godot::Dictionary LockwrightHaptics::capabilities() const {
	NSDictionary *d = [(__bridge LockwrightHapticsImpl *)engine_impl capabilities];
	godot::Dictionary out;
	for (NSString *key in d) {
		out[godot::String(key)] = godot::String([d[key] description]);
	}
	return out;
}

void LockwrightHaptics::stop_all() {
	[(__bridge LockwrightHapticsImpl *)engine_impl stopAll];
}

} // namespace lockwright
