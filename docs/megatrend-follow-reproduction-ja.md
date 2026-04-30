# 西山孝四郎／石原順 メガトレンドフォロー再現レポート（実装指向版）

## 目的
本ドキュメントは、公開情報に基づいて「メガトレンドフォロー」を**実装可能な粒度**で再現するための仕様書です。

> 注意: 公式配布は `.ex4` 中心で、内部式の一部は未公開です。したがって本書は「完全一致複製」ではなく「公開情報に整合した再現実装」を目的とします。

## 再現の結論（初期値）
- 主系列: **一般化Hull系**（期間 `50`、ベースMA `SMA`、`close` モード）
- 補助: `ADX(14)` 上昇 + `StdDev(26)` 上昇（必要に応じて `StdDev(52)` を遅行基準線に追加）
- 損益管理: **STOPATR 3.3**（終値クロスで反転/手仕舞い）

## 公開情報から固定できる要素
- ドテン型トレンドフォロー（反対シグナルで反転）
- close版 / intrabar版 の2系統
- STOPATR の存在と倍率3.3の実例

## 推定が必要な要素
- VOLT1/VOLT2/Ver2.x の内部式
- ATR期間
- 矢印表示の厳密条件

## 実装構成（推奨）
```text
pine/
  megatrend_follow_v2_strategy.pine
mql4/
  Indicators/
    MegaTrendFollow_v2.mq4
    MegaTrendFollow_v2_subwindow.mq4
    StopATR_v2.mq4
  Experts/
    MTF_Recreated_TestEA.mq4
```

## 主要数式
標準HMA:

\[
\mathrm{HMA}_n(x)=\mathrm{WMA}(2\cdot \mathrm{WMA}(x,n/2)-\mathrm{WMA}(x,n),\sqrt{n})
\]

一般化Hull（ベースMA差し替え）:

\[
\mathrm{HullLike}_n(x)=\mathrm{MA}(2\cdot \mathrm{MA}(x,n/2)-\mathrm{MA}(x,n),\sqrt{n})
\]

## シグナル最小核（擬似コード）
```text
mega = HullLike(close, 50, SMA)
trend = BUY if mega > mega[1] else SELL if mega < mega[1] else trend[1]

flipLong  = trend == BUY  and trend[1] != BUY
flipShort = trend == SELL and trend[1] != SELL

if mode == close:
  signal only when bar closes
```

## 補助ロジック（推奨）
- `trendiness_ok = ADX14 > ADX14[1] && StdDev26 > StdDev26[1] && StdDev26 >= StdDev52`
- 補助ロジックは方向判定ではなく「トレンド有無判定」にのみ使う

## リスク管理
- 1トレードの口座リスク: `0.5%〜1.0%`
- 口座DD: 累計 `-10%` 到達時に停止
- ロット計算:

\[
\text{Position Size}=\frac{\text{Equity}\times\text{Risk\%}}{|\text{Entry}-\text{Stop}|\times\text{PointValue}}
\]

## 検証計画
- 対象: `USDJPY / EURUSD / AUDJPY / XAUUSD / USOIL / JP225CFD`
- 足: `D1` 主軸、`W1` 補助
- 比較群:
  - 50/SMA
  - 72/SMA
  - 144/LWMA
  - 各々で STOPATR有無
  - 各々で ADX/StdDev フィルタ有無

## 実装フェーズ
1. Pineで可視化・概念検証（close/intrabar切替）
2. MQL4主系列インジ移植
3. MQL4 subwindow / STOPATR 分離実装
4. EAでドテン挙動を機械テスト
5. 代表銘柄でチャート照合 + パラメータ校正
