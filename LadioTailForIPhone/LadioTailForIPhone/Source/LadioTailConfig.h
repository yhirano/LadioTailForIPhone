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
FOUNDATION_EXPORT UIColor * const NAVIGATION_BAR_COLOR;

/// サイドメニューボタンの色
FOUNDATION_EXPORT UIColor * const SIDEMENU_BUTTON_COLOR;

/// 戻るボタンの色
FOUNDATION_EXPORT UIColor * const BACK_BUTTON_COLOR;

/// 再生中ボタンの色
FOUNDATION_EXPORT UIColor * const PLAYING_BUTTON_COLOR;

#pragma mark - Side menu table view config

/// サイドメニューを開いた際の残り幅
FOUNDATION_EXPORT const CGFloat SIDEMENU_LEFT_LEDGE;

/// テーブルの背景の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセクションの背景の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_SECTION_BACKGROUND_COLOR;

/// テーブルセクションのテキストの色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_SECTION_TEXT_COLOR;

/// テーブルセクションのテキストの影の色
FOUNDATION_EXPORT UIColor * const SIDEMENU_TABLE_SECTION_TEXT_SHADOW_COLOR;

/// テーブルセルのメインのテキストカラー
FOUNDATION_EXPORT UIColor * const SIDEMENU_CELL_MAIN_TEXT_COLOR;

/// テーブルセルのメインのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const SIDEMENU_CELL_MAIN_TEXT_SELECTED_COLOR;

#pragma mark - Headline table view config

/// 検索バーの色
FOUNDATION_EXPORT UIColor * const SEARCH_BAR_COLOR;

/// テーブルの背景の色
FOUNDATION_EXPORT UIColor * const HEADLINE_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
FOUNDATION_EXPORT UIColor * const HEADLINE_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
FOUNDATION_EXPORT UIColor * const HEADLINE_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
FOUNDATION_EXPORT UIColor * const HEADLINE_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのタイトルのテキストカラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_TITLE_TEXT_COLOR;

/// テーブルセルのタイトルのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_TITLE_TEXT_SELECTED_COLOR;

/// テーブルセルのDJのテキストカラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_DJ_TEXT_COLOR;

/// テーブルセルのDJのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_DJ_TEXT_SELECTED_COLOR;

/// テーブルセルのリスナー数のテキストカラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_LISTENERS_TEXT_COLOR;

/// テーブルセルのリスナー数のテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_LISTENERS_TEXT_SELECTED_COLOR;

/// テーブルセルの日付の背景丸さ
FOUNDATION_EXPORT const CGFloat HEADLINE_CELL_DATE_CORNER_RADIUS;

/// テーブルセルの日付の背景の色（明るい方）
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT;

/// HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT の時間（秒）
FOUNDATION_EXPORT const NSInteger HEADLINE_CELL_DATE_BACKGROUND_COLOR_LIGHT_SEC;

/// テーブルセルの日付の背景の色（暗い方）
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK;

/// HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK の時間（秒）
FOUNDATION_EXPORT const NSInteger HEADLINE_CELL_DATE_BACKGROUND_COLOR_DARK_SEC;

/// テーブルセルの日付のテキストカラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_DATE_TEXT_COLOR;

/// テーブルセルの日付のテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_DATE_TEXT_SELECTED_COLOR;

/// テーブルセルのビットレートの背景丸さ
FOUNDATION_EXPORT const CGFloat HEADLINE_CELL_BITRATE_CORNER_RADIUS;

/// テーブルセルのビットレートの背景の色（明るい方）
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_LIGHT;

/// HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_LIGHT のビットレート
FOUNDATION_EXPORT const NSInteger HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_LIGHT_BITRATE;

/// テーブルセルのビットレートの背景の色（暗い方）
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_DARK;

/// HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_DARK のビットレート
FOUNDATION_EXPORT const NSInteger HEADLINE_CELL_BITRATE_BACKGROUND_COLOR_DARK_BITRATE;

/// テーブルセルのビットレートのテキストカラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_BITRATE_TEXT_COLOR;

/// テーブルセルのビットレートのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_BITRATE_TEXT_SELECTED_COLOR;

/// プレイスワイプビューの文字色
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_PLAY_SWIPE_TEXT_COLOR;

/// プレイスワイプビューの背景色（上）
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_PLAY_SWIPE_BACKGROUND_TOP_COLOR;

/// プレイスワイプビューの背景色（下）
FOUNDATION_EXPORT UIColor * const HEADLINE_CELL_PLAY_SWIPE_BACKGROUND_BOTTOM_COLOR;

// Pull Refreshのテキスト色
FOUNDATION_EXPORT UIColor * const PULL_REFRESH_TEXT_COLOR;

// Pull Refreshの矢印イメージ
FOUNDATION_EXPORT NSString * const PULL_REFRESH_ARROW_IMAGE;

// Pull Refreshの背景色
FOUNDATION_EXPORT UIColor * const PULL_REFRESH_TEXT_BACKGROUND_COLOR;

/// 一文字ごとに検索を実行するか
FOUNDATION_EXPORT const BOOL SEARCH_EACH_CHAR;

/// Pull refreshでヘッドラインを有効にするか
FOUNDATION_EXPORT const BOOL PULL_REFRESH_HEADLINE;

/// 再生が開始した際に、再生している番組をテーブルの一番上になるようにスクロールするか
FOUNDATION_EXPORT const BOOL SCROLL_TO_TOP_AT_PLAYING_CHANNEL_CELL;

#pragma mark - Channel view config

/// お気に入りボタンの色
FOUNDATION_EXPORT UIColor * const FAVORITE_BUTTON_COLOR;

/// 下部Viewの上部の色
FOUNDATION_EXPORT UIColor * const BOTTOM_BAR_TOP_COLOR;

/// 下部Viewの下部の色
FOUNDATION_EXPORT UIColor * const BOTTOM_BAR_BOTTOM_COLOR;

/// リンクをクリックするとSafariが開く
FOUNDATION_EXPORT const BOOL OPEN_SAFARI_WHEN_CLICK_LINK;

#pragma mark - Favorites table view config

/// テーブルの背景の色
FOUNDATION_EXPORT UIColor * const FAVORITES_TABLE_BACKGROUND_COLOR;

/// テーブルの境界線の色
FOUNDATION_EXPORT UIColor * const FAVORITES_TABLE_SEPARATOR_COLOR;

/// テーブルセルの暗い側の色
FOUNDATION_EXPORT UIColor * const FAVORITES_TABLE_CELL_BACKGROUND_COLOR_DARK;

/// テーブルセルの明るい側の色
FOUNDATION_EXPORT UIColor * const FAVORITES_TABLE_CELL_BACKGROUND_COLOR_LIGHT;

/// テーブルセルの選択の色
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_SELECTED_BACKGROUND_COLOR;

/// テーブルセルのメインのテキストカラー
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_MAIN_TEXT_COLOR;

/// テーブルセルのメインのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_MAIN_TEXT_SELECTED_COLOR;

/// テーブルセルのサブのテキストカラー
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_SUB_TEXT_COLOR;

/// テーブルセルのサブのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_SUB_TEXT_SELECTED_COLOR;

/// テーブルセルのタグのテキストカラー
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_TAG_TEXT_COLOR;

/// テーブルセルのタグのテキスト選択時カラー
FOUNDATION_EXPORT UIColor * const FAVORITES_CELL_TAG_TEXT_SELECTED_COLOR;

#pragma mark - Player config

/// 再生開始後のタイムアウト処理までの時間
FOUNDATION_EXPORT const NSTimeInterval PLAY_TIMEOUT_SEC;

#pragma mark - APNS config

/// お気に入り送信先のプロバイダ
FOUNDATION_EXPORT NSString * const PROVIDER_URL;

#pragma mark - AdMob config

/// AdMob Publisher ID
FOUNDATION_EXPORT NSString * const ADMOB_PUBLISHER_ID;
