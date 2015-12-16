//
//  XHRemoteEarClientViewController.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/12/4.
//  Copyright © 2015年 XH. All rights reserved.
//

#import "XHRemoteEarClientViewController.h"
#import "XHRemoteEarClient.h"
#import "XHAudioReciever.h"

@interface XHRemoteEarClientViewController ()

@property (nonatomic)XHAudioReciever *auRecieve;
@property (nonatomic)XHRemoteEarClient *reEarClient;

@end

@implementation XHRemoteEarClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.auRecieve = [[XHAudioReciever alloc] init];
    self.reEarClient = [[XHRemoteEarClient alloc] init];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)connectToHost:(id)sender {
    [self.reEarClient connectToHost];
}

- (IBAction)disconnect:(id)sender {
    [self.reEarClient stopStreams];
}

- (IBAction)openAudioFileStream:(id)sender {
    [self.auRecieve openAudioFileStream];
}

- (IBAction)stopAudioQueue:(id)sender {
    [self.auRecieve stopRecieving];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
