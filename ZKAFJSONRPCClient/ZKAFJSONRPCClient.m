// ZKAFJSONRPCClient.m
//
// Created by wiistriker@gmail.com
// Copyright (c) 2016 zhengkai
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZKAFJSONRPCClient.h"
#import "AFNetworking.h"

#import <objc/runtime.h>

NSString * const AFJSONRPCErrorDomain = @"com.alamofire.networking.json-rpc";

static NSString * AFJSONRPCLocalizedErrorMessageForCode(NSInteger code) {
    switch(code) {
        case -32700:
            return @"Parse Error";
        case -32600:
            return @"Invalid Request";
        case -32601:
            return @"Method Not Found";
        case -32602:
            return @"Invalid Params";
        case -32603:
            return @"Internal Error";
        default:
            return @"Server Error";
    }
}

@interface AFJSONRPCProxy : NSProxy
- (id)initWithClient:(ZKAFJSONRPCClient *)client
            protocol:(Protocol *)protocol;
@end

#pragma mark -

@interface ZKAFJSONRPCClient ()
@property (nonatomic,strong)AFHTTPSessionManager *manager;
@end

@implementation ZKAFJSONRPCClient


- (id)initWithEndpointURL:(NSURL *)URL {
    NSParameterAssert(URL);
    

    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.manager = [[AFHTTPSessionManager alloc] initWithBaseURL:URL];
    self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"application/json-rpc", @"application/jsonrequest", nil];
    
    self.endpointURL = URL;
    
    return self;
}



- (void)invokeMethod:(NSString *)method
             success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
             failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure
{
    [self invokeMethod:method withParameters:@[] success:success failure:failure];
}

- (void)invokeMethod:(NSString *)method
      withParameters:(id)parameters
             success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
             failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure
{
    [self invokeMethod:method withParameters:parameters  success:success failure:failure];
}

- (void)invokeMethod:(NSString *)method
      withParameters:(id)parameters
           requestId:(id)requestId
             success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
             failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure {
    [self invokeMethod:method withParameters:parameters  interface:@"" success:success failure:failure];
    
}

- (void)invokeMethod:(NSString *)method
      withParameters:(id)parameters
           interface:(NSString*)interface
             success:(void (^)(NSURLSessionDataTask *operation, id responseObject))success
             failure:(void (^)(NSURLSessionDataTask *operation, NSError *error))failure
{

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"jsonrpc"] = @"2.0";
    payload[@"method"] = method;
    payload[@"params"] = @[parameters];
    payload[@"id"] = @"1";
    
    [self.manager POST:[[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",self.endpointURL,interface]] absoluteString]
            parameters:payload
              progress:^(NSProgress * _Nonnull uploadProgress) {
        
      } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
           NSInteger code = 0;
           NSString *message = nil;
           id data = nil;
           
           if ([responseObject isKindOfClass:[NSDictionary class]]) {
               id result = responseObject[@"result"];
               id error = responseObject[@"error"];
               
               if (result && result != [NSNull null]) {
                   if (success) {
                       success(task, result);
                       return;
                   }
               } else if (error && error != [NSNull null]) {
                   if ([error isKindOfClass:[NSDictionary class]]) {
                       if (error[@"code"]) {
                           code = [error[@"code"] integerValue];
                       }
                       
                       if (error[@"message"]) {
                           message = error[@"message"];
                       } else if (code) {
                           message = AFJSONRPCLocalizedErrorMessageForCode(code);
                       }
                       
                       data = error[@"data"];
                   } else {
                       message = NSLocalizedStringFromTable(@"Unknown Error", @"ZKAFJSONRPCClient", nil);
                   }
               } else {
                   message = NSLocalizedStringFromTable(@"Unknown JSON-RPC Response", @"ZKAFJSONRPCClient", nil);
               }
           } else {
               message = NSLocalizedStringFromTable(@"Unknown JSON-RPC Response", @"ZKAFJSONRPCClient", nil);
           }
           
           if (failure) {
               NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
               if (message) {
                   userInfo[NSLocalizedDescriptionKey] = message;
               }
               
               if (data) {
                   userInfo[@"data"] = data;
               }
               
               NSError *error = [NSError errorWithDomain:@"" code:code userInfo:userInfo];
               
               failure(task, error);
           }
       }
       failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           if (failure) {
               failure(task, error);
           }
       }];
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                parameters:(id)parameters
                                 requestId:(id)requestId
{
    NSParameterAssert(method);
    
    if (!parameters) {
        parameters = @[];
    }
    
    NSAssert([parameters isKindOfClass:[NSDictionary class]] || [parameters isKindOfClass:[NSArray class]], @"Expect NSArray or NSDictionary in JSONRPC parameters");
    
    if (!requestId) {
        requestId = @(0);
    }
    
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"jsonrpc"] = @"2.0";
    payload[@"method"] = method;
    payload[@"params"] = @[parameters];
    payload[@"id"] = @"0";
    
    return [self.manager.requestSerializer requestWithMethod:@"POST" URLString:[self.endpointURL absoluteString] parameters:payload error:nil];
}

#pragma mark - AFHTTPClient

- (id)proxyWithProtocol:(Protocol *)protocol {
    return [[AFJSONRPCProxy alloc] initWithClient:self protocol:protocol];
}

@end

#pragma mark -

typedef void (^AFJSONRPCProxySuccessBlock)(id responseObject);
typedef void (^AFJSONRPCProxyFailureBlock)(NSError *error);

@interface AFJSONRPCProxy ()
@property (readwrite, nonatomic, strong) ZKAFJSONRPCClient *client;
@property (readwrite, nonatomic, strong) Protocol *protocol;
@end

@implementation AFJSONRPCProxy

- (id)initWithClient:(ZKAFJSONRPCClient*)client
            protocol:(Protocol *)protocol
{
    self.client = client;
    self.protocol = protocol;
    
    return self;
}

- (BOOL)respondsToSelector:(SEL)selector {
    struct objc_method_description description = protocol_getMethodDescription(self.protocol, selector, YES, YES);
    
    return description.name != NULL;
}

- (NSMethodSignature *)methodSignatureForSelector:(__unused SEL)selector {
    // 0: v->RET || 1: @->self || 2: :->SEL || 3: @->arg#0 (NSArray) || 4,5: ^v->arg#1,2 (block)
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:@^v^v"];
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSParameterAssert(invocation.methodSignature.numberOfArguments == 5);
    
    NSString *RPCMethod = [NSStringFromSelector([invocation selector]) componentsSeparatedByString:@":"][0];
    
    __unsafe_unretained id arguments;
    __unsafe_unretained AFJSONRPCProxySuccessBlock unsafeSuccess;
    __unsafe_unretained AFJSONRPCProxyFailureBlock unsafeFailure;
    
    [invocation getArgument:&arguments atIndex:2];
    [invocation getArgument:&unsafeSuccess atIndex:3];
    [invocation getArgument:&unsafeFailure atIndex:4];
    
    [invocation invoke];
    
    __strong AFJSONRPCProxySuccessBlock strongSuccess = [unsafeSuccess copy];
    __strong AFJSONRPCProxyFailureBlock strongFailure = [unsafeFailure copy];
    
    [self.client invokeMethod:RPCMethod withParameters:arguments success:^(__unused NSURLSessionDataTask *operation, id responseObject) {
        if (strongSuccess) {
            strongSuccess(responseObject);
        }
    } failure:^(__unused NSURLSessionDataTask *operation, NSError *error) {
        if (strongFailure) {
            strongFailure(error);
        }
    }];
}

@end
