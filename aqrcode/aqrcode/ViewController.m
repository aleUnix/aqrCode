//
//  ViewController.m
//  aqrcode
//
//  Created by Alessio Quattrocchi on 07/08/18.
//  Copyright © 2018 Alessio Quattrocchi. All rights reserved.
//

#import "ViewController.h"
//#import "ZBarSDK.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate, UITextViewDelegate>

@property (assign) BOOL isFirst;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *prevLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.resultTextView.delegate = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startScanning:(id)sender {

    self.isFirst=true;
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice: device error:&error];
    if ( input) {
        [session addInput: input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [session addOutput: output];
    
    output.metadataObjectTypes = [output availableMetadataObjectTypes];
    
    self.prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: session];
    _prevLayer.frame = self.view.bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer: _prevLayer];
    
    [ session startRunning];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
    
    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString:type])
            {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[_prevLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                highlightViewRect = barCodeObject.bounds;
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }
        if (detectionString != nil)
        {
            [self.prevLayer removeFromSuperlayer];
            if (self.isFirst) {
                self.isFirst=false;
                
                NSURL *url = [NSURL URLWithString: detectionString];
                if (url && url.scheme && url.host)
                {
                    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: detectionString
                                                                                           attributes:@{ NSLinkAttributeName: url }];
                    self.resultTextView.attributedText = attributedString;
                    
                } else{
                    NSAttributedString *attributedStringNoURL = [[NSAttributedString alloc] initWithString: detectionString];
                    _resultTextView.attributedText = attributedStringNoURL;
                }
                break;
            }
        }
        else
            _resultTextView.text = @"(none)";
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {

    NSDictionary *dict = [[NSDictionary alloc] init];
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.daledietrich.com"]];
    [[UIApplication sharedApplication] openURL: URL options: dict completionHandler:^(BOOL success) {
        
    }];

    
    return YES;
}


@end
