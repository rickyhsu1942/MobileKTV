//
//  MyApplication.m
//  carolokAPPiPhone
//
//  Created by iscom on 2014/9/18.
//  Copyright (c) 2014年 Ricky. All rights reserved.
//

#import "MyApplication.h"

@implementation MyApplication

-(void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];
    if (event.type == UIEventTypeTouches) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenTouch" object:nil];
    }
}

@end
