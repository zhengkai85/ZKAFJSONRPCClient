//
//  MyJSONRPCClient.h
//  huimin
//
//  Created by zhengkai on 16/4/7.
//  Copyright © 2016年 zhengkai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZKAFJSONRPCClient.h"

typedef void(^NetBlock)(NSURLSessionDataTask *operation, id posts,NSInteger code,NSString *errorMsg);


@interface MyJSONRPCClient : ZKAFJSONRPCClient

+ (MyJSONRPCClient *)sharedInstance;

- (void)dealWithInterface:(NSString*)interface
                   method:(NSString *)method
               parameters:(id)parameters
                    block:(void (^)(NSURLSessionDataTask *operation, id posts,NSInteger code,NSString *errorMsg))block;

- (void)dealWithInterface:(NSString*)interface
                   method:(NSString *)method
               parameters:(id)parameters
               isShowLoad:(BOOL)showLoad
                    block:(void (^)(NSURLSessionDataTask *operation, id posts,NSInteger code,NSString *errorMsg))block;



@end
