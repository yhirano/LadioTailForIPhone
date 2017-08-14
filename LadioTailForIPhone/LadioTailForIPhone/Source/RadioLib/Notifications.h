/*
 * Copyright (c) 2012-2017 Yuichi Hirano
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

/// ヘッドラインの取得を開始した際のNotification
#define RadioLibHeadlineDidStartLoadNotification @"RadioLibHeadlineDidStartLoadNotification"
/// ヘッドラインの取得に成功した際のNotification
#define RadioLibHeadlineDidFinishLoadNotification @"RadioLibHeadlineDidFinishLoadNotification"
/// ヘッドラインの取得に失敗した際のNotification
#define RadioLibHeadlineFailLoadNotification @"RadioLibHeadlineFailLoadNotification"
/// ヘッドラインの内容が変更した際のNotification
#define RadioLibHeadlineChannelChangedNotification @"RadioLibHeadlineChannelChangedNotification"

/// お気に入りの情報が変化した際のNotification
/// 複数のお気に入りが1度に変化した場合、1回発行する
#define RadioLibChannelChangedFavoritesNotification @"RadioLibChannelChangedFavoritesNotification"

/// お気に入りの情報が変化した際のNotification
/// お気に入り1つの変更に対し1回発行する
#define RadioLibChannelChangedFavoriteNotification @"RadioLibChannelChangedFavoriteNotification"

/// 履歴が変化した際のNotification
#define RadioLibHistoryChangedNotification @"RadioLibHistoryChangedNotification"
