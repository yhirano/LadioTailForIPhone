/*
 * Copyright (c) 2012 Yuichi Hirano
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

#import "LadioTailConfig.h"

#pragma mark - Common view config

/// ナビゲーションバーの色
UIColor * const NAVIGATION_BAR_COLOR = [UIColor colorWithRed:(10.0f / 255)
                                                       green:(10.0f / 255)
                                                        blue:(10.0f / 255)
                                                       alpha:1.0f];

/// サイドメニューボタンの色
UIColor * const SIDEMENU_BUTTON_COLOR = [UIColor darkGrayColor];

/// 戻るボタンの色
UIColor * const BACK_BUTTON_COLOR = [UIColor darkGrayColor];

/// 再生中ボタンの色
UIColor * const PLAYING_BUTTON_COLOR = [UIColor colorWithRed:(191.0f / 255)
                                                       green:(126.0f / 255)
                                                        blue:(0.0f / 255)
                                                       alpha:1.0f];

#pragma mark - Side menu table view config

/// 背景の色
UIColor * const SIDEMENU_BACKGROUND_COLOR = [UIColor colorWithRed:(40.0f / 255)
                                                            green:(40.0f / 255)
                                                             blue:(40.0f / 255.0)
                                                            alpha:1.0f];

/// テーブルの背景の色
UIColor * const SIDEMENU_TABLE_BACKGROUND_COLOR = [UIColor colorWithRed:(40.0f / 255)
                                                                  green:(40.0f / 255)
                                                                   blue:(40.0f / 255.0)
                                                                  alpha:1.0f];

/// テーブルの境界線の色
UIColor * const SIDEMENU_TABLE_SEPARATOR_COLOR = [UIColor colorWithRed:(75.0f / 255)
                                                                 green:(75.0f / 255)
                                                                  blue:(75.0f / 255)
                                                                 alpha:1.0f];

/// テーブルセルの暗い側の色
UIColor * const SIDEMENU_TABLE_CELL_BACKGROUND_COLOR_DARK = [UIColor colorWithRed:(40.0f / 255)
                                                                            green:(40.0f / 255)
                                                                             blue:(40.0f / 255)
                                                                            alpha:1.0f];

/// テーブルセルの明るい側の色
UIColor * const SIDEMENU_TABLE_CELL_BACKGROUND_COLOR_LIGHT = [UIColor colorWithRed:(60.0f / 255)
                                                                             green:(60.0f / 255)
                                                                              blue:(60.0f / 255)
                                                                             alpha:1.0f];

/// テーブルセルの選択の色
UIColor * const SIDEMENU_CELL_SELECTED_BACKGROUND_COLOR = [UIColor colorWithRed:(255.0f / 255)
                                                                          green:(190.0f / 255)
                                                                           blue:(30.0f / 255)
                                                                          alpha:1.0f];

/// テーブルセクションの背景の色
UIColor * const SIDEMENU_TABLE_SECTION_BACKGROUND_COLOR = [UIColor colorWithRed:(20.0f / 255)
                                                                          green:(20.0f / 255)
                                                                           blue:(20.0f / 255)
                                                                          alpha:1.0f];

/// テーブルセクションのテキストの色
UIColor * const SIDEMENU_TABLE_SECTION_TEXT_COLOR = [UIColor whiteColor];

/// テーブルセクションのテキストの影の色
UIColor * const SIDEMENU_TABLE_SECTION_TEXT_SHADOW_COLOR = [UIColor grayColor];

/// テーブルセルのメインのテキストカラー
UIColor * const SIDEMENU_CELL_MAIN_TEXT_COLOR = [UIColor whiteColor];

/// テーブルセルのメインのテキスト選択時カラー
UIColor * const SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR = [UIColor blackColor];

#pragma mark - Headline table view config

/// 検索バーの色
UIColor * const SEARCH_BAR_COLOR = [UIColor colorWithRed:(10.0f / 255)
                                                   green:(10.0f / 255)
                                                    blue:(10.0f / 255)
                                                   alpha:1.0f];

/// リフレッシュコントロールの色
UIColor * const HEADLINE_PULL_REFRESH_COLOR = [UIColor colorWithWhite:0.6 alpha:1.0];;

/// テーブルの背景の色
UIColor * const HEADLINE_TABLE_BACKGROUND_COLOR = [UIColor colorWithRed:(40.0f / 255)
                                                                  green:(40.0f / 255)
                                                                   blue:(40.0f / 255.0)
                                                                  alpha:1.0f];

/// テーブルの境界線の色
UIColor * const HEADLINE_TABLE_SEPARATOR_COLOR = [UIColor colorWithRed:(75.0f / 255)
                                                                 green:(75.0f / 255)
                                                                  blue:(75.0f / 255)
                                                                 alpha:1.0f];

/// テーブルセルの暗い側の色
UIColor * const HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK = [UIColor colorWithRed:(40.0f / 255)
                                                                            green:(40.0f / 255)
                                                                             blue:(40.0f / 255)
                                                                            alpha:1.0f];

/// テーブルセルの明るい側の色
UIColor * const HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT = [UIColor colorWithRed:(60.0f / 255)
                                                                             green:(60.0f / 255)
                                                                              blue:(60.0f / 255)
                                                                             alpha:1.0f];

/// テーブルセルの選択の色
UIColor * const HEADLINE_CELL_SELECTED_BACKGROUND_COLOR = [UIColor colorWithRed:(255.0f / 255)
                                                                          green:(190.0f / 255)
                                                                           blue:(30.0f / 255)
                                                                          alpha:1.0f];

/// テーブルセルのタイトルのテキストカラー
UIColor * const HEADLINE_CELL_TITLE_TEXT_COLOR = [UIColor whiteColor];

/// テーブルセルのタイトルのテキスト選択時カラー
UIColor * const HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR = [UIColor blackColor];

/// テーブルセルのDJのテキストカラー
UIColor * const HEADLINE_CELL_DJ_TEXT_COLOR = [UIColor colorWithRed:(255.0f / 255)
                                                              green:(190.0f / 255)
                                                               blue:(30.0f / 255)
                                                              alpha:1.0f];

/// テーブルセルのDJのテキスト選択時カラー
UIColor * const HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR = [UIColor blackColor];

/// テーブルセルのリスナー数のテキストカラー
UIColor * const HEADLINE_CELL_LISTENERS_TEXT_COLOR = [UIColor whiteColor];

/// テーブルセルのリスナー数のテキスト選択時カラー
UIColor * const HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR = [UIColor blackColor];

/// テーブルセルの日付のテキストカラー
UIColor * const HEADLINE_CELL_DATE_TEXT_COLOR = [UIColor blackColor];

/// テーブルセルの日付のテキスト選択時カラー
UIColor * const HEADLINE_CELL_DATE_TEXT_SELECTED_COLOR = [UIColor blackColor];

/// テーブルセルのビットレートのテキストカラー
UIColor * const HEADLINE_CELL_BITRATE_TEXT_COLOR = [UIColor blackColor];

/// テーブルセルのビットレートのテキスト選択時カラー
UIColor * const HEADLINE_CELL_BITRATE_TEXT_SELECTED_COLOR = [UIColor blackColor];

/// プレイスワイプビューの文字色
UIColor * const HEADLINE_CELL_PLAY_SWIPE_TEXT_COLOR = [UIColor blackColor];

/// プレイスワイプビューの背景色（上）
UIColor * const HEADLINE_CELL_PLAY_SWIPE_BACKGROUND_TOP_COLOR = [UIColor colorWithHue:(40.0f / 359.0f)
                                                                           saturation:(89.0f / 100.0f)
                                                                           brightness:(95.0f / 100.0f)
                                                                                alpha:1.0f];


/// プレイスワイプビューの背景色（下）
UIColor * const HEADLINE_CELL_PLAY_SWIPE_BACKGROUND_BOTTOM_COLOR = [UIColor colorWithHue:(40.0f / 359.0f)
                                                                              saturation:(89.0f / 100.0f)
                                                                              brightness:(57.0f / 100.0f)
                                                                                   alpha:1.0f];

// Pull Refreshのテキスト色
UIColor * const PULL_REFRESH_TEXT_COLOR = [UIColor darkGrayColor];

// Pull Refreshの矢印イメージ
NSString * const PULL_REFRESH_ARROW_IMAGE = @"EGOTableViewPullRefresh.bundle/grayArrow.png";

// Pull Refreshの背景色
UIColor * const PULL_REFRESH_TEXT_BACKGROUND_COLOR = [UIColor lightGrayColor];

#if defined(LADIO_TAIL)
    /// 一文字ごとに検索を実行するか
    const BOOL SEARCH_EACH_CHAR = YES;
#elif defined(RADIO_EDGE)
    /// 一文字ごとに検索を実行するか
    const BOOL SEARCH_EACH_CHAR = NO;
#else
    #error "Not defined LADIO_TAIL or RADIO_EDGE"
#endif

/// 再生が開始した際に、再生している番組をテーブルの一番上になるようにスクロールするか
const BOOL SCROLL_TO_TOP_AT_PLAYING_CHANNEL_CELL = YES;

#pragma mark - Channel view config

/// お気に入りボタンの色
UIColor * const FAVORITE_BUTTON_COLOR = [UIColor darkGrayColor];

/// 広告VBiewの背景色
UIColor * const AD_VIRE_BACKGROUND_COLOR = [UIColor blackColor];

/// 下部Viewの上部の色
UIColor * const BOTTOM_BAR_TOP_COLOR = [UIColor colorWithRed:(28.0f / 255)
                                                       green:(28.0f / 255)
                                                        blue:(28.0f / 255)
                                                       alpha:1.0f];

/// 下部Viewの下部の色
UIColor * const BOTTOM_BAR_BOTTOM_COLOR = [UIColor blackColor];

#pragma mark - Favorites table view config

/// テーブルの背景の色
UIColor * const FAVORITES_TABLE_BACKGROUND_COLOR = HEADLINE_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
UIColor * const FAVORITES_TABLE_SEPARATOR_COLOR = HEADLINE_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
UIColor * const FAVORITES_TABLE_CELL_BACKGROUND_COLOR_DARK = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
UIColor * const FAVORITES_TABLE_CELL_BACKGROUND_COLOR_LIGHT = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
UIColor * const FAVORITES_CELL_SELECTED_BACKGROUND_COLOR = HEADLINE_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのメインのテキストカラー
UIColor * const FAVORITES_CELL_MAIN_TEXT_COLOR = HEADLINE_CELL_TITLE_TEXT_COLOR;

/// テーブルセルのメインのテキスト選択時カラー
UIColor * const FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR = HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;

/// テーブルセルのサブのテキストカラー
UIColor * const FAVORITES_CELL_SUB_TEXT_COLOR = HEADLINE_CELL_DJ_TEXT_COLOR;

/// テーブルセルのサブのテキスト選択時カラー
UIColor * const FAVORITES_CELL_SUB_TEXT_SELECTED_COLOR = HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;

/// テーブルセルのタグのテキストカラー
UIColor * const FAVORITES_CELL_TAG_TEXT_COLOR = [UIColor colorWithRed:(180.0f / 255)
                                                                green:(180.0f / 255)
                                                                 blue:(180.0f / 255)
                                                                alpha:1.0f];

/// テーブルセルのタグのテキスト選択時カラー
UIColor * const FAVORITES_CELL_TAG_TEXT_SELECTED_COLOR = [UIColor blackColor];

#pragma mark - Player config

/// 再生開始後のタイムアウト処理までの時間
const NSTimeInterval PLAY_TIMEOUT_SEC = 15.0;

#pragma mark - APNS config

/// お気に入り送信先のプロバイダ
///
/// お気に入りをプロバイダに送信しない場合はnil
NSString * const PROVIDER_URL = nil;


#pragma mark - LadioTailConfig class

@implementation LadioTailConfig

#pragma mark - Side menu table view config

+ (CGFloat)sideMenuLeftSize
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 250.0f;
    } else {
        return 246.0f;
    }
}

#pragma mark - AdMob config

+ (NSString *)admobUnitId
{
    return nil;
}

@end
