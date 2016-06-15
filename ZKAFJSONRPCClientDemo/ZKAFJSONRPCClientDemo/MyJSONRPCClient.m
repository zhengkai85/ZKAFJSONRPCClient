//
//  MyJSONRPCClient.m
//  huimin
//
//  Created by zhengkai on 16/4/7.
//  Copyright © 2016年 zhengkai. All rights reserved.
//

#import "MyJSONRPCClient.h"

static NSString * const kMyClientURL = @"http://www.domain.com";


@implementation MyJSONRPCClient

+ (MyJSONRPCClient *)sharedInstance
{
    static MyJSONRPCClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[MyJSONRPCClient alloc] initWithEndpointURL:[NSURL URLWithString:kMyClientURL]];

    });
    
    return _sharedInstance;
}



- (void)dealWithInterface:(NSString*)interface
                   method:(NSString *)method
               parameters:(id)parameters
               isShowLoad:(BOOL)showLoad
                    block:(void (^)(NSURLSessionDataTask *operation, id posts,NSInteger code,NSString *errorMsg))block {
    
    if(showLoad) {
        // loading 加载 [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:NO];
    }

    [self invokeMethod:method
        withParameters:parameters
             interface:interface 
               success:^(NSURLSessionDataTask *operation, id responseObject) {
                   if(showLoad) {
                       //loading 取消 [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                   }
                   
                   if([responseObject isKindOfClass:[NSDictionary class]]) {
                       NSDictionary *dic = responseObject;
                       if([dic[@"resultCode"] integerValue] == 10086 ) {
                           //业务处理  比如登录
                           return ;
                       }
                       block(operation,responseObject,[dic[@"success"] integerValue],dic[@"resultMessage"]);
                   } else{
                       block(operation,responseObject,0,@"返回不是字典类型");
                   }
               }
               failure:^(NSURLSessionDataTask *operation, NSError *error) {
                   if(showLoad) {
                       //loading 取消 [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                   }
                   block(operation,nil,0 ,@"当前网络不可用");
               }];
}


- (void)dealWithInterface:(NSString*)interface
                   method:(NSString *)method
               parameters:(id)parameters
                    block:(void (^)(NSURLSessionDataTask *operation, id posts,NSInteger code,NSString *errorMsg))block{
    
    [self dealWithInterface:interface
                     method:method
                 parameters:parameters
                 isShowLoad:YES
                      block:block];
}







@end
