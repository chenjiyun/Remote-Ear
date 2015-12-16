//
//  XHRemoteEarViewController.m
//  XHRemoteEar
//
//  Created by 陈小黑 on 15/11/7.
//  Copyright © 2015年 XH. All rights reserved.
//

#import "XHRemoteEarViewController.h"
#import "XHAudioSender.h"

@interface XHRemoteEarViewController ()

@property (nonatomic) XHAudioSender *audioSender;
@property (weak, nonatomic) IBOutlet UITextView *messagesRecieved;

@end

@implementation XHRemoteEarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messagesRecieved.editable = NO;
    self.audioSender = [[XHAudioSender alloc] init];
    
    __weak UITextView *weakMess = self.messagesRecieved;
    //Set the block
    self.audioSender.res.displayMessageBlock = ^(NSData *dat){
        //NSData *da = self.client.data;
        NSString *string = [[NSString alloc] initWithData:dat encoding:NSASCIIStringEncoding];
        weakMess.text = string;
    };
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)startToListenForConnect:(id)sender {
    [self.audioSender.res startListen];
}

- (IBAction)stopListening:(id)sender {
    [self.audioSender.res stopListen];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)sendAudio:(id)sender {
    if (self.audioSender.isRunning) {
        [self.audioSender stopSending];
    }
    [self.audioSender startSendAudio];
    
}
- (IBAction)stopSending:(id)sender {
    [self.audioSender stopSending];
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
