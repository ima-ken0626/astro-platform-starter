# はじめての方向け：メガトレンド再現セットの使い方

このページは、**MT4やTradingViewが初めて**でも迷わないように、手順をやさしく説明します。

---

## まず全体像（これだけ覚えてください）
- `pine/megatrend_follow_v2_strategy.pine`
  - TradingViewで「見た目と成績」を確認する用
- `mql4/Indicators/*.mq4`
  - MT4でチャートに線を出す用
- `mql4/Experts/MTF_Recreated_TestEA.mq4`
  - MT4で売買を自動実行する用

**おすすめ順序**
1. TradingViewで練習
2. MT4デモ口座で自動売買
3. 慣れたら小ロット本番

---

## Step 1: TradingViewで試す（いちばん簡単）
1. TradingViewを開く
2. Pineエディタを開く
3. `pine/megatrend_follow_v2_strategy.pine` の中身を貼り付け
4. 「チャートに追加」を押す
5. バックテスト画面で結果を見る

### 最初の設定（このまま推奨）
- `mode = close`
- `maBase = SMA`
- `lenMain = 50`
- `useVol = true`
- `atrMult = 3.3`

### ここを見る
- 利益曲線が右肩上がりか
- 最大ドローダウンが大きすぎないか
- 連敗が耐えられるか

---

## Step 2: MT4にインジケーターを入れる
1. MT4を起動
2. `ファイル > データフォルダを開く`
3. `MQL4/Indicators` に以下3ファイルをコピー
   - `MegaTrendFollow_v2.mq4`
   - `MegaTrendFollow_v2_subwindow.mq4`
   - `StopATR_v2.mq4`
4. MetaEditorで3ファイルを開いて「コンパイル」
5. MT4を再起動
6. ナビゲータからインジケーターをチャートへドラッグ

### 期待どおりなら
- メインチャートに赤/黄のトレンドライン
- サブウィンドウにADX/StdDev表示
- ATRストップライン表示

---

## Step 3: EA（自動売買）をデモ口座で動かす
1. `mql4/Experts/MTF_Recreated_TestEA.mq4` を `MQL4/Experts` にコピー
2. MetaEditorでコンパイル
3. MT4再起動
4. チャートにEAをドラッグ
5. 「自動売買を許可」をON
6. まずはデモ口座で2週間

### 最初のEA設定（安全寄り）
- `RiskPercent = 0.5`
- `MaxSpreadPoints = 30`
- `UseTrendinessFilter = true`
- `CloseOnly = true`
- `ATRPeriod = 14`
- `ATRMultiplier = 3.3`

---

## お金を守るルール（超重要）
- いきなり本番口座でやらない
- 最初は `RiskPercent=0.5` から
- 1日で大きく負けたら停止
- 連敗で設定をいじりすぎない
- 設定変更は1回に1つだけ

---

## よくあるつまずき
### Q1. シグナルが出ない
- 相場がレンジだと出にくいです
- `UseTrendinessFilter=true` だと厳しめです

### Q2. 売買が多すぎる
- `CloseOnly=true` になっているか確認
- 時間足をD1/H4中心にする

### Q3. 利益が安定しない
- 銘柄ごとに相性が違います
- まずは USDJPY / EURUSD / XAUUSD など少数で検証

---

## 最低限の運用チェック（毎週）
- 週の損益
- 最大連敗
- 最大ドローダウン
- どの通貨ペアで勝った/負けたか

この4つだけ記録すれば、改善の方向が見えます。
