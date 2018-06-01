# KTVVideoProcess

KTVVideoProcess is a High-Performance video effects processing framework. It's base on OpenGL ES, support asynchronous and multithread processing.


## Flow Chart

![KTVVideoProcess-Flow-Chart](http://oxl6mxy2t.bkt.clouddn.com/changba/KTVVideoProcess-flow-chart.jpg)


## Installation

#### Installation with CocoaPods

To integrate KTVVideoProcess into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
pod 'KTVVideoProcess', '~> 1.0.0'
```

Run `pod install`

#### Installation with Carthage

To integrate KTVVideoProcess into your Xcode project using Carthage, specify it in your Cartfile:

```ogdl
github "ChangbaDevs/KTVVideoProcess" ~> 1.0.0
```

Run `carthage update` to build the framework and drag the built `KTVVideoProcess.framework` into your Xcode project.


## Usage

- The Complete process needs three nodes: Source/Pipeline/Output.

### Source

- The responsibility of the source is the input data, like camera or media file.
- You can create a camera source like following:

```objc
self.captureSession = [[KTVVPCaptureSession alloc] init];
self.captureSession.pipeline = self.pipeline;
if (needAudio) {
    self.captureSession.audioEnable = YES;
    self.captureSession.audioOutput = frameWriter;
}
[self.captureSession start];
```

### Pipeline

- The pipeline is the real processor. It contains multiple filters inside.
- There are serial and concurrent two pipelines. The serial pipeline run on a separate thread, and it's only can process one task at the same time. The concurrent contains multiple serial pipeline, this means that it's can process multiple tasks at the same time. But when using concurrent pipeline, the timestamp of the output frame may not be continuous.
- You can create a serial pipeline like following:

```objc
NSArray <Class> * filterClasses = @[[KTVVPRGBFilter class],
                                    [KTVVPExposureFilter class],
                                    [KTVVPBrightnessFilter class],
                                    [KTVVPBlackAndWhiteFilter class],
                                    [KTVVPTransformFilter class]];
self.pipeline = [[KTVVPSerialPipeline alloc] initWithContext:self.context filterClasses:filterClasses];
__weak typeof(self) weakSelf = self;
[self.pipeline setFilterConfigurationCallback:^(__kindof KTVVPFilter * filter, NSInteger index) {
    __weak typeof(weakSelf) self = weakSelf;
    if ([filter isKindOfClass:[KTVVPRGBFilter class]]) {
        self.RGBFilter = filter;
        self.RGBFilter.enable = NO;
        self.RGBFilter.red = 0.8;
    } else if ([filter isKindOfClass:[KTVVPExposureFilter class]]) {
        self.exposureFilter = filter;
        self.exposureFilter.enable = NO;
        self.exposureFilter.exposure = 0.5;
    } else if ([filter isKindOfClass:[KTVVPBrightnessFilter class]]) {
        self.brightnessFilter = filter;
        self.brightnessFilter.enable = NO;
        self.brightnessFilter.brightness = 0.2;
    } else if ([filter isKindOfClass:[KTVVPBlackAndWhiteFilter class]]) {
        self.blackAndWhiteFilter = filter;
        self.blackAndWhiteFilter.enable = NO;
    }
}];
[self.pipeline setupIfNeeded];
```

### Output

- It's used to receive the results of pipeline.
- You can create a preview view or file writer like following:

```objc
// Preview View
self.frameView = [[KTVVPFrameView alloc] initWithContext:self.context];
self.frameView.frame = self.view.bounds;
[self.view addSubview:self.frameView];
[self.pipeline addOutput:self.frameView];

// File Writer
NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"KTVVideoProcess-temp.mov"];
self.frameWriter = [[KTVVPFrameWriter alloc] init];
self.frameWriter.outputFileURL = [NSURL fileURLWithPath:filePath];
self.frameWriter.videoOutputSize = KTVVPSizeMake(720, 1280);
self.frameWriter.videoEncodeDelayInterval = 0.0f;
if (needAudio) {
    self.frameWriter.audioEnable = YES;
}
[self.frameWriter setStartCallback:^(BOOL success) {
    NSLog(@"Record Started...");
}];
[self.frameWriter setFinishedCallback:^(BOOL success) {
    NSLog(@"Record Finished...");
}];
[self.frameWriter setCancelCallback:^(BOOL success) {
    NSLog(@"Record Canceled...");
}];
[self.frameWriter start];
if (needAudio) {
    self.captureSession.audioOutput = self.frameWriter;
}
[self.pipeline addOutput:self.frameWriter];
```

### Export

- It's used to process existing video.
- You can create a export session like following:

```objc
KTVVPExportSession * exportSession = [[KTVVPExportSession alloc] init];
exportSession.sourceURL = inputURL;
exportSession.destinationURL = outputURL;
exportSession.pipeline = pipeline;
[exportSession setCompletionCallback:^(NSURL * destinationURL, NSError * error) {
    NSLog(@"KTVVPExportSession Finished");
}];
[exportSession start];
```

### Background Mode

- You need to do something to avoid process runs in the background:

```objc
// Suspend the Source/Pieple/Output
self.captureSession.paused = YES;
[self.pipeline glFinish];
[self.frameWriter cancel];

// Wait until all operations are finished.
[self.pipeline waitUntilFinished];
[self.frameView waitUntilFinished];
[self.frameWriter waitUntilFinished];
```

## License

KTVVideoProcess is released under the MIT license.

## Feedback

- Email : libobjc@gmail.com
- Twitter : CoderSingle
- Weibo : 程序员Single
