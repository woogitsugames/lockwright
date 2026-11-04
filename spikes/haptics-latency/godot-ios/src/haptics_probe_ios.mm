#include "haptics_probe_ios.h"

#import <CoreHaptics/CoreHaptics.h>
#import <QuartzCore/QuartzCore.h>

#include <godot_cpp/core/class_db.hpp>

@interface LWProbeImpl : NSObject
@property(nonatomic, strong) CHHapticEngine* engine;
@property(nonatomic, strong) id<CHHapticAdvancedPatternPlayer> continuous;
@property(nonatomic) int resets;
@property(nonatomic) int stops;
@property(nonatomic) BOOL supported;
@end

@implementation LWProbeImpl
- (instancetype)init {
  if ((self = [super init])) {
    _supported = CHHapticEngine.capabilitiesForHardware.supportsHaptics;
    if (_supported) [self start];
  }
  return self;
}
- (void)start {
  NSError* err = nil;
  _engine = [[CHHapticEngine alloc] initAndReturnError:&err];
  if (!_engine) return;
  _engine.playsHapticsOnly = YES;
  _engine.autoShutdownEnabled = NO;
  __weak LWProbeImpl* weakSelf = self;
  _engine.stoppedHandler = ^(CHHapticEngineStoppedReason reason) { weakSelf.stops += 1; };
  _engine.resetHandler = ^{
    LWProbeImpl* s = weakSelf;
    if (!s) return;
    [s.engine startAndReturnError:nil];
    [s makeContinuous];
    s.resets += 1;
  };
  [_engine startAndReturnError:&err];
  [self makeContinuous];
}
- (void)makeContinuous {
  CHHapticEventParameter* i = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:1.0];
  CHHapticEventParameter* s = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.3];
  CHHapticEvent* ev = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous parameters:@[ i, s ] relativeTime:0 duration:30];
  CHHapticPattern* p = [[CHHapticPattern alloc] initWithEvents:@[ ev ] parameters:@[] error:nil];
  if (!p) return;
  _continuous = [_engine createAdvancedPlayerWithPattern:p error:nil];
  _continuous.loopEnabled = YES;
}
@end

namespace lw {

using namespace godot;

LockwrightHapticsProbeIOS::LockwrightHapticsProbeIOS() {
  impl_ = (__bridge_retained void*)[[LWProbeImpl alloc] init];
}

LockwrightHapticsProbeIOS::~LockwrightHapticsProbeIOS() {
  if (impl_) {
    LWProbeImpl* p = (__bridge_transfer LWProbeImpl*)impl_;
    [p.continuous stopAtTime:CHHapticTimeImmediate error:nil];
    [p.engine stopWithCompletionHandler:nil];
    impl_ = nullptr;
  }
}

static LWProbeImpl* P(void* v) { return (__bridge LWProbeImpl*)v; }

Dictionary LockwrightHapticsProbeIOS::transient(double intensity, double sharpness) {
  const double t0 = CACurrentMediaTime();
  LWProbeImpl* p = P(impl_);
  if (p.engine) {
    CHHapticEventParameter* i = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:(float)intensity];
    CHHapticEventParameter* s = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:(float)sharpness];
    CHHapticEvent* ev = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticTransient parameters:@[ i, s ] relativeTime:0];
    CHHapticPattern* pat = [[CHHapticPattern alloc] initWithEvents:@[ ev ] parameters:@[] error:nil];
    id<CHHapticPatternPlayer> pl = [p.engine createPlayerWithPattern:pat error:nil];
    [pl startAtTime:CHHapticTimeImmediate error:nil];
  }
  const double t1 = CACurrentMediaTime();
  Dictionary d;
  d["call_s"] = t0;  // CACurrentMediaTime = UITouch.timestamp clock
  d["return_s"] = t1;
  d["call_us"] = (t1 - t0) * 1e6;
  return d;
}

void LockwrightHapticsProbeIOS::continuous_start() {
  [P(impl_).continuous startAtTime:CHHapticTimeImmediate error:nil];
}

double LockwrightHapticsProbeIOS::continuous_update(double intensity, double sharpness) {
  const double t0 = CACurrentMediaTime();
  CHHapticDynamicParameter* i = [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticDynamicParameterIDHapticIntensityControl value:(float)intensity relativeTime:0];
  CHHapticDynamicParameter* s = [[CHHapticDynamicParameter alloc] initWithParameterID:CHHapticDynamicParameterIDHapticSharpnessControl value:(float)(sharpness - 0.3) relativeTime:0];
  [P(impl_).continuous sendParameters:@[ i, s ] atTime:CHHapticTimeImmediate error:nil];
  return t0;
}

void LockwrightHapticsProbeIOS::continuous_stop() {
  [P(impl_).continuous stopAtTime:CHHapticTimeImmediate error:nil];
}

Dictionary LockwrightHapticsProbeIOS::capabilities() {
  LWProbeImpl* p = P(impl_);
  Dictionary d;
  d["tier"] = p.supported ? "H3" : "H0";
  d["engine"] = p.engine != nil;
  d["resets"] = p.resets;
  d["stops"] = p.stops;
  return d;
}

void LockwrightHapticsProbeIOS::_bind_methods() {
  ClassDB::bind_method(D_METHOD("transient", "intensity", "sharpness"), &LockwrightHapticsProbeIOS::transient);
  ClassDB::bind_method(D_METHOD("continuous_start"), &LockwrightHapticsProbeIOS::continuous_start);
  ClassDB::bind_method(D_METHOD("continuous_update", "intensity", "sharpness"), &LockwrightHapticsProbeIOS::continuous_update);
  ClassDB::bind_method(D_METHOD("continuous_stop"), &LockwrightHapticsProbeIOS::continuous_stop);
  ClassDB::bind_method(D_METHOD("capabilities"), &LockwrightHapticsProbeIOS::capabilities);
}

}  // namespace lw
