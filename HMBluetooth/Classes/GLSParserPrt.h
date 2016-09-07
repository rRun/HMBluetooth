//
//  GLSManagerPrt.h
//  Pods
//
//  Created by 何霞雨 on 16/8/11.
//
//

#import <Foundation/Foundation.h>

@class GLSParser;
@protocol GLSParserPrt <NSObject>

-(void)onOperationStarted;//开始执行命令
-(void)onOperationCompleted;//完成执行命令
-(void)onOperationFailed;//执行命令失败
-(void)onOperationAborted;//打断执行的命令
-(void)onOperationNotSupported;//不支持该命令
-(void)onDatasetChanged:(GLSParser *)parser;
-(void)onNumberOfRecordsRequested:(int) value;

@end
