/*
 * Copyright (c) 2012-2014 Yuichi Hirano
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

@class TempleteSubInfo;

/// テンプレートに渡す情報
@interface TempleteInfo : NSObject

/// タイトル
@property (nonatomic, strong) NSString *title;

/// サブタイトル
@property (nonatomic, strong) NSString *subTitle;

/// 注目テキスト
@property (nonatomic, strong) NSString *notificationText;

/// 表示情報
/// TempleteSubInfoのリスト
@property (nonatomic, strong) NSArray<TempleteSubInfo*> *info;

/// デバッグ情報
/// TempleteSubInfoのリスト
@property (nonatomic, strong) NSArray<TempleteSubInfo*> *debugInfo;

@end

/// テンプレートに表示する情報
@interface TempleteSubInfo : NSObject

@property (nonatomic, strong, readonly) NSString *tag;

@property (nonatomic, strong, readonly) NSString *value;

- (id)initWithTag:(NSString *)tag value:(NSString *)value;

@end
