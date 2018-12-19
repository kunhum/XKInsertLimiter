//
//  XKInsertLimiter.h
//  TestDemo
//
//  Created by Nicholas on 2017/11/30.
//  Copyright © 2017年 nicholas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kChineseRegex @"[\u4e00-\u9fa5]{0,}$"

@interface XKInsertLimiter : NSObject

///开始限制textField
- (void)xk_starLimitingTextField:(UITextField *)textField;
///开始限制textView
- (void)xk_starLimitingTextView:(UITextView *)textView;
///停止限制，一般不需要手动调用
- (void)xk_stopLimiting;

/**
 过滤规则外的字符

 @param validCharacters 需要遵循的规则，传入只允许输入的字符
 */
- (void)xk_fliterWithValidCharacters:(NSString *)validCharacters;

/**
 通过正则过滤，过滤正则外的字符

 @param regex 正则
 */
- (void)xk_fliterWithRegex:(NSString *)regex;

///限制输入的长度
@property (nonatomic, assign) NSUInteger maxLength;
///是否过滤emoji
@property (nonatomic, assign) BOOL       filterEmoji;
///是否过滤汉字
@property (nonatomic, assign) BOOL       filterChinese;
///只能输入数字
@property (nonatomic, assign) BOOL       numberLimited;

///当前长度回调
@property (nonatomic, copy)   void(^getCurrentLength)(id object, NSUInteger currentLength);



@end
