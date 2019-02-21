//
//  XKInsertLimiter.m
//  TestDemo
//
//  Created by Nicholas on 2017/11/30.
//  Copyright © 2017年 nicholas. All rights reserved.
//

#import "XKInsertLimiter.h"

@interface XKInsertLimiter ()

@property (nonatomic, copy) NSString *validCharacters;

@property (nonatomic, copy) NSString *regex;

@end

@implementation XKInsertLimiter

#pragma mark 公共方法
#pragma mark 开始限制textField
- (void)xk_starLimitingTextField:(UITextField *)textField {
    [self xk_starLimit:textField];
}
#pragma mark 开始限制textView
- (void)xk_starLimitingTextView:(UITextView *)textView {
    [self xk_starLimit:textView];
}

- (void)xk_starLimit:(id)limitedObject {
    
    if ([limitedObject isKindOfClass:[UITextField class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldEditChanged:) name:UITextFieldTextDidChangeNotification object:limitedObject];
    }
    else if ([limitedObject isKindOfClass:[UITextView class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewEditChanged:) name:UITextViewTextDidChangeNotification object:limitedObject];
    }
    else {
        
        
    }
}
#pragma mark 停止监听
- (void)xk_stopLimiting {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark 限制只能输入传入的字符
- (void)xk_fliterWithValidCharacters:(NSString *)validCharacters {
    self.validCharacters = validCharacters;
}
#pragma mark 只能输入数字
- (void)setNumberLimited:(BOOL)numberLimited {
    _numberLimited = numberLimited;
    
    if (numberLimited) {
        [self xk_fliterWithValidCharacters:@"0123456789"];
    }
}
#pragma mark 正则过滤
- (void)xk_fliterWithRegex:(NSString *)regex {
    self.regex = regex;
}

#pragma mark - 私有方法
#pragma mark 观察者，监听文本输入的长度
#pragma mark text view
- (void)textViewEditChanged:(NSNotification *)notification {
    
    UITextView *textView = (UITextView *)notification.object;
    
    UITextRange *selectedRange = [textView markedTextRange];
    NSString *newText = [textView textInRange:selectedRange];//获取高亮部分
    if(newText.length > 0) return;
    
    textView.text = [self handleFliterCaseWithLimitedObject:textView];
    
    if (self.getCurrentLength) self.getCurrentLength(textView, textView.text.length);
    
}

#pragma mark text field
- (void)textFieldEditChanged:(NSNotification *)notification {
    
    UITextField *textField = (UITextField *)notification.object;
    
    UITextRange *selectedRange = [textField markedTextRange];
    NSString *newText = [textField textInRange:selectedRange];//获取高亮部分
    if(newText.length > 0) return;
    
    textField.text = [self handleFliterCaseWithLimitedObject:textField];
    
    if (self.getCurrentLength) self.getCurrentLength(textField, textField.text.length);
}
#pragma mark 处理不同的过滤情况
- (NSString *)handleFliterCaseWithLimitedObject:(id)limitedObject {
    
    NSString *validText = [limitedObject text];
    
    //长度限制
    if (self.maxLength > 0) {
        //获取高亮部分
        UITextRange *selectedRange = [limitedObject markedTextRange];
        UITextPosition *position   = [limitedObject positionFromPosition:selectedRange.start offset:0];
        
        validText = [self handleLengthLimitedWithPosition:position validText:validText];
    }
    
    //过滤中文
    if (self.filterChinese) {
        validText = [self fliterWithRegEx:kChineseRegex validText:validText];
    }
    
    //过滤emoji
    if (self.filterEmoji) {
        validText = [self fliterEmoji:validText];
    }
    
    //用可允许输入的字符来过滤
    if (self.validCharacters) {
        
        validText = [self fliterWithValidCharacters:validText];
    }
    
    //正则过滤
    if (self.regex) {
        validText = [self fliterText:validText whichOutsideRegex:self.regex];
    }
    
    return validText;
}

#pragma mark 过滤可允许输入之外的字符
- (NSString *)fliterWithValidCharacters:(NSString *)validText {
    
    NSMutableString* __block buffer = [NSMutableString stringWithCapacity:validText.length];
    
    [validText enumerateSubstringsInRange:NSMakeRange(0, validText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock: ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
        
        NSString *appendStr = [self.validCharacters containsString:substring] ? substring : @"";
        [buffer appendString:appendStr];
    }];
    
    return buffer;
}
#pragma mark 过滤emoji
- (NSString *)fliterEmoji:(NSString *)validText {
    
    NSMutableString* __block buffer = [NSMutableString stringWithCapacity:validText.length];
    
    [validText enumerateSubstringsInRange:NSMakeRange(0, validText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock: ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
        [buffer appendString:([self isEmoji:substring] ? @"": substring)];
    }];
    
    return buffer;
}
#pragma mark 通过正则过滤
- (NSString *)fliterWithRegEx:(NSString *)regex validText:(NSString *)validText {
    
    for (int i = 0; i < validText.length; i++) {
        
        NSString *string = [validText substringFromIndex:i];
        if ([self string:string matchWithRegex:regex]) {
            //替换空字符串
            validText = [validText stringByReplacingOccurrencesOfString:string withString:@""];
        }
        
    }
    return validText;
}
#pragma mark 过滤正则外的字符
- (NSString *)fliterText:(NSString *)validText whichOutsideRegex:(NSString *)regex {
    
    NSMutableString* __block buffer = [NSMutableString stringWithCapacity:validText.length];
    
    
    [validText enumerateSubstringsInRange:NSMakeRange(0, validText.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        [buffer appendString:([self string:substring matchWithRegex:regex] ? substring : @"")];
    }];
    return buffer;
}
#pragma mark 长度限制处理
- (NSString *)handleLengthLimitedWithPosition:(UITextPosition *)position validText:(NSString *)validText {
    
    //没有高亮选择的字，则对已输入的文字进行字数统计和限制
    if (!position) {
        
        if (validText.length > self.maxLength) {
            
            NSRange rangeIndex = [validText rangeOfComposedCharacterSequenceAtIndex:self.maxLength];
            
            if (rangeIndex.length == 1) {
                validText = [validText substringToIndex:self.maxLength];
            }
            else {
                NSRange rangeRange = [validText rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, self.maxLength)];
                validText = [validText substringWithRange:rangeRange];
            }
            
        }
    }
    return validText;
}

#pragma mark emoji判断
- (BOOL)isEmoji:(NSString *)string {
    
    NSCharacterSet *variationSelectors = [NSCharacterSet characterSetWithRange:NSMakeRange(0xFE00, 16)];
    
    if ([string rangeOfCharacterFromSet: variationSelectors].location != NSNotFound) {
        return YES;
    }
    
    const unichar high = [string characterAtIndex: 0];
    
    //(U+1D000-1F9FF)
    if (0xD800 <= high && high <= 0xDBFF) {
        const unichar low = [string characterAtIndex: 1];
        const int codepoint = ((high - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000;
        
        return (0x1D000 <= codepoint && codepoint <= 0x1F9FF);
        
        //(U+2100-27BF)
    } else {
        return (0x2100 <= high && high <= 0x27BF);
    }
}
#pragma mark 正则判断
- (BOOL)string:(NSString *)string matchWithRegex:(NSString *)regex {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [predicate evaluateWithObject:string];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"限制dealloc");
}

@end
