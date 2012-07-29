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

#import <UIKit/UIKit.h>

#pragma mark - Common config

/// ナビゲーションバーの色
extern UIColor * const NAVIGATION_BAR_COLOR;

/// 更新ボタンの色
extern UIColor * const UPDATE_BUTTON_COLOR;

/// 戻るボタンの色
extern UIColor * const BACK_BUTTON_COLOR;

/// 再生中ボタンの色
extern UIColor * const PLAYING_BUTTON_COLOR;

#pragma mark - Headline table view config

/// 検索バーの色
extern UIColor * const SEARCH_BAR_COLOR;

/// テーブルの背景の色
extern UIColor * const HEADLINE_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
extern UIColor * const HEADLINE_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
extern UIColor * const HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
extern UIColor * const HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
extern UIColor * const HEADLINE_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのタイトルのテキストカラー
extern UIColor * const HEADLINE_CELL_TITLE_TEXT_COLOR;

/// テーブルセルのタイトルのテキスト選択時カラー
extern UIColor * const HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;

/// テーブルセルのDJのテキストカラー
extern UIColor * const HEADLINE_CELL_DJ_TEXT_COLOR;

/// テーブルセルのDJのテキスト選択時カラー
extern UIColor * const HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;

/// テーブルセルのリスナー数のテキストカラー
extern UIColor * const HEADLINE_CELL_LISTENERS_TEXT_COLOR;

/// テーブルセルのリスナー数のテキスト選択時カラー
extern UIColor * const HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR;

/// テーブルセルの日付の背景丸さ
extern const CGFloat HEADLINE_CELL_DATE_CORNER_RADIUS;

/// テーブルセルの日付の背景の色（明るい方）
extern UIColor * const HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの日付の背景の色（暗い方）
extern UIColor * const HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK;

/// テーブルセルの日付のテキストカラー
extern UIColor * const HEADLINE_CELL_DATE_TEXT_COLOR;

/// テーブルセルの日付のテキスト選択時カラー
extern UIColor * const HEADLINE_CELL_DATE_TEXT_SELECTED_COLOR;

/// テーブルセルのビットレートの背景丸さ
extern const CGFloat HEADLINE_CELL_BITRATE_CORNER_RADIUS;

/// テーブルセルのビットレートの背景の色（明るい方）
extern UIColor * const HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_LIGHT;

/// テーブルセルのビットレートの背景の色（暗い方）
extern UIColor * const HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_DARK;

/// テーブルセルのビットレートのテキストカラー
extern UIColor * const HEADLINE_CELL_BITRATE_TEXT_COLOR;

/// テーブルセルのビットレートのテキスト選択時カラー
extern UIColor * const HEADLINE_CELL_BITRATE_TEXT_SELECTED_COLOR;

// Pull Refreshのテキスト色
extern UIColor * const PULL_REFRESH_TEXT_COLOR;

// Pull Refreshの矢印イメージ
extern NSString * const PULL_REFRESH_ARROW_IMAGE;

// Pull Refreshの背景色
extern UIColor * const PULL_REFRESH_TEXT_BACKGROUND_COLOR;

/// Pull refreshでヘッドラインを有効にするか
extern const BOOL PULL_REFRESH_HEADLINE;

/// 再生が開始した際に、再生している番組をテーブルの一番上になるようにスクロールするか
extern const BOOL SCROLL_TO_TOP_AT_PLAYING_CHANNEL_CELL;

/// iAd広告を有効にするか
extern const BOOL HEADLINE_VIEW_IAD_ENABLE;

/// ヘッドライン取得失敗時にエラーを表示する秒数
extern const NSTimeInterval DELAY_FETCH_HEADLINE_MESSAGE;

#pragma mark - Channel view config

/// お気に入りボタンの色
extern UIColor * const FAVORITE_BUTTON_COLOR;

/// 下部Viewの上部の色
extern UIColor * const BOTTOM_BAR_TOP_COLOR;

/// 下部Viewの下部の色
extern UIColor * const BOTTOM_BAR_BOTTOM_COLOR;

/// リンクをクリックするとSafariが開く
extern const BOOL OPEN_SAFARI_WHEN_CLICK_LINK;

/// iAd広告を有効にするか
extern const BOOL CHANNEL_VIEW_IAD_ENABLE;

/// iAd広告を有効にするか
extern const BOOL WEB_PAGE_VIEW_IAD_ENABLE;

#pragma mark - Other table view config

/// テーブルの背景の色
extern UIColor * const OTHERS_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
extern UIColor * const OTHERS_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
extern UIColor * const OTHERS_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
extern UIColor * const OTHERS_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
extern UIColor * const OTHERS_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのメインのテキストカラー
extern UIColor * const OTHERS_CELL_MAIN_TEXT_COLOR;

/// テーブルセルのメインのテキスト選択時カラー
extern UIColor * const OTHERS_CELL_MAIN_TEXT_SELECTED_COLOR;

#pragma mark - Favorites table view config

/// テーブルの背景の色
extern UIColor * const FAVORITES_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
extern UIColor * const FAVORITES_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
extern UIColor * const FAVORITES_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
extern UIColor * const FAVORITES_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
extern UIColor * const FAVORITES_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのメインのテキストカラー
extern UIColor * const FAVORITES_CELL_MAIN_TEXT_COLOR;

/// テーブルセルのメインのテキスト選択時カラー
extern UIColor * const FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;

/// テーブルセルのサブのテキストカラー
extern UIColor * const FAVORITES_CELL_SUB_TEXT_COLOR;

/// テーブルセルのサブのテキスト選択時カラー
extern UIColor * const FAVORITES_CELL_SUB_TEXT_SELECTED_COLOR;

/// テーブルセルのタグのテキストカラー
extern UIColor * const FAVORITES_CELL_TAG_TEXT_COLOR;

/// テーブルセルのタグのテキスト選択時カラー
extern UIColor * const FAVORITES_CELL_TAG_TEXT_SELECTED_COLOR;

#pragma mark - Favorite view config

/// iAd広告を有効にするか
extern const BOOL FAVORITE_VIEW_IAD_ENABLE;

#pragma mark - Player config

/// 再生開始後のタイムアウト処理までの時間
extern const NSTimeInterval PLAY_TIMEOUT_SEC;

#pragma mark - Ad animation config

/// iADビューの表示アニメーションの秒数
extern const NSTimeInterval AD_VIEW_ANIMATION_DURATION;
