/*
 * Copyright (c) 2012 Y.Hirano
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

#pragma mark - Common config

/// ナビゲーションバーの色
UIColor * const NAVIGATION_BAR_COLOR = [UIColor colorWithRed:(10.0f / 255)
                                                       green:(10.0f / 255)
                                                        blue:(10.0f / 255)
                                                       alpha:1.0f];

/// 更新ボタンの色
UIColor * const UPDATE_BUTTON_COLOR = [UIColor darkGrayColor];

/// 戻るボタンの色
UIColor * const BACK_BUTTON_COLOR = [UIColor darkGrayColor];

/// 再生中ボタンの色
UIColor * const PLAYING_BUTTON_COLOR = [UIColor colorWithRed:(191.0f / 255)
                                                       green:(126.0f / 255)
                                                        blue:(0.0f / 255)
                                                       alpha:1.0f];

#pragma mark - Headline table view config

/// 検索バーの色
UIColor * const SEARCH_BAR_COLOR = [UIColor colorWithRed:(10.0f / 255)
                                                   green:(10.0f / 255)
                                                    blue:(10.0f / 255)
                                                   alpha:1.0f];

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

/// テーブルセルの日付の背景丸さ
const CGFloat HEADLINE_CELL_DATE_CORNER_RADIUS = 7;

/// テーブルセルの日付の背景の色（明るい方）
UIColor * const HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT = [UIColor colorWithRed:(140.0f / 255)
                                                                            green:(140.0f / 255)
                                                                             blue:(140.0f / 255)
                                                                            alpha:1.0f];

/// テーブルセルの日付の背景の色（暗い方）
UIColor * const HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK = [UIColor colorWithRed:(120.0f / 255)
                                                                           green:(120.0f / 255)
                                                                            blue:(120.0f / 255)
                                                                           alpha:1.0f];

/// テーブルセルの日付のテキストカラー
UIColor * const HEADLINE_CELL_DATE_TEXT_COLOR = [UIColor blackColor];

/// テーブルセルの日付のテキスト選択時カラー
UIColor * const HEADLINE_CELL_DATE_TEXT_SELECTED_COLOR = [UIColor blackColor];

// Pull Refreshのテキスト色
UIColor * const PULL_REFRESH_TEXT_COLOR = [UIColor darkGrayColor];

// Pull Refreshの矢印イメージ
NSString * const PULL_REFRESH_ARROW_IMAGE = @"EGOTableViewPullRefresh.bundle/grayArrow.png";

// Pull Refreshの背景色
UIColor * const PULL_REFRESH_TEXT_BACKGROUND_COLOR = [UIColor lightGrayColor];

/// Pull refreshでヘッドラインを有効にするか
const BOOL PULL_REFRESH_HEADLINE = YES;

/// 再生が開始した際に、再生している番組をテーブルの一番上になるようにスクロールするか
const BOOL SCROLL_TO_TOP_AT_PLAYING_CHANNEL_CELL = YES;

/// 広告を有効にするか
const BOOL HEADLINE_VIEW_AD_ENABLE = NO;

/// ヘッドライン取得失敗時にエラーを表示する秒数
const NSTimeInterval DELAY_FETCH_HEADLINE_MESSAGE = 3.0;

#pragma mark - Channel view config

/// お気に入りボタンの色
UIColor * const FAVORITE_BUTTON_COLOR = [UIColor darkGrayColor];

/// 下部Viewの上部の色
UIColor * const BOTTOM_BAR_TOP_COLOR = [UIColor colorWithRed:0.11f green:0.11f blue:0.11f alpha:1.0f];

/// 下部Viewの下部の色
UIColor * const BOTTOM_BAR_BOTTOM_COLOR = [UIColor blackColor];

/// リンクをクリックするとSafariが開く
const BOOL OPEN_SAFARI_WHEN_CLICK_LINK = NO;

/// 広告を有効にするか
const BOOL CHANNEL_VIEW_AD_ENABLE = YES;

/// 広告を有効にするか
const BOOL WEB_PAGE_VIEW_AD_ENABLE = YES;

#pragma mark - Other table view config

/// テーブルの背景の色
UIColor * const OTHERS_TABLE_BACKGROUND_COLOR = HEADLINE_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
UIColor * const OTHERS_TABLE_SEPARATOR_COLOR = HEADLINE_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
UIColor * const OTHERS_TABLE_CELL_BACKGROUND_COLOR_DARK = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
UIColor * const OTHERS_TABLE_CELL_BACKGROUND_COLOR_LIGHT = HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
UIColor * const OTHERS_CELL_SELECTED_BACKGROUND_COLOR = HEADLINE_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのメインのテキストカラー
UIColor * const OTHERS_CELL_MAIN_TEXT_COLOR = HEADLINE_CELL_TITLE_TEXT_COLOR;

/// テーブルセルのメインのテキスト選択時カラー
UIColor * const OTHERS_CELL_MAIN_TEXT_SELECTED_COLOR = HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;

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

#pragma mark - Favorite view config

/// 広告を有効にするか
const BOOL FAVORITE_VIEW_AD_ENABLE = YES;

#pragma mark - Player config

/// 再生開始後のタイムアウト処理までの時間
const NSTimeInterval PLAY_TIMEOUT_SEC = 15.0;

#pragma mark - Ad animation config

/// iADビューの表示アニメーションの秒数
const NSTimeInterval AD_VIEW_ANIMATION_DURATION = 0.6;
