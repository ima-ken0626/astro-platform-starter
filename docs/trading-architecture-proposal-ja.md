# 無料運用を前提にしたトレード自動化アーキテクチャ提案（GAS中心からの移行）

## 要点
- 判定エンジンは **GAS中心から Python中心へ移行** する。
- GASは **LINE通知** と **Google Sheets反映** に絞る。
- データソースは単一依存を避け、複数系統で冗長化する。
- 「通知するだけ」ではなく、毎週の検証で改善する **研究・運用システム** にする。

## 推奨構成

```text
GitHub Actions + Python + 複数データソース + Google Sheets + GAS + LINE
```

### 役割分担
| 役割 | 担当 |
|---|---|
| OHLC取得 | Python |
| EMA/ATR/RSI計算 | Python |
| D1/H4/H1判定 | Python |
| 通貨強弱計算 | Python |
| シグナル生成 | Python |
| 保存 | GitHub JSON/CSV または Sheets |
| 通知 | GAS + LINE |

## データソース戦略（無料運用向け）
- メイン: Twelve Data
- サブ: yfinance
- 検証: OANDA Practice API
- 長期バックテスト: Stooq / MT5履歴

## 運用レーン

### 1) リアルタイム運用
1. GitHub Actions定期実行
2. Pythonでデータ取得・判定
3. `signal_latest.json` 更新
4. GASがJSONを参照
5. 条件を満たす場合のみLINE通知
6. Sheetsへ実績保存

### 2) バックテスト
- 総トレード数
- 勝率
- 平均利益/平均損失
- 最大DD
- 連敗数
- RR別成績
- D1/H4/H1条件別成績
- 建値移動・トレール有無比較

## ステート管理への変更
従来の `BUY/SELL/NO_ENTRY` 一発判定ではなく、状態遷移を持つ。

```text
WATCH -> CANDIDATE -> ARMED -> ENTRY -> MANAGE -> CLOSED
```

通知ポリシー例:
- CANDIDATE: 通知なし
- ARMED: 1日1回
- ENTRY: 即時通知
- MANAGE: 重要変化のみ

## スコアリング化
完全一致判定ではなく、点数制で機会損失を削減する。

判定例:
- 90点以上: ENTRY
- 75〜89点: ARMED
- 60〜74点: CANDIDATE
- 59点以下: NO_ENTRY

## 導入優先順位
1. Python判定エンジン移行（Sheets/LINEは維持）
2. GitHub Actions自動実行
3. バックテスト機能追加
4. スコアリング導入
5. OANDA/MT5/Stooqによる補助データ統合

## 参考URL
- GitHub Actions Workflow Syntax: https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions
- yfinance: https://github.com/ranaroussi/yfinance
- OANDA v20: https://developer.oanda.com/rest-live-v20/introduction/
- Stooq data: https://stooq.com/db/
- MT5 Python integration: https://www.mql5.com/en/docs/python_metatrader5
- TradingView pricing: https://www.tradingview.com/pricing/


## 現在運用との比較（結論）
結論として、このドキュメントの構成は**多くのケースで現行運用より優秀になりやすい**です。
ただし「必ず上位互換」ではなく、次の前提を満たすときに優位性が出ます。

### 優位になりやすい条件
- Python実行環境（GitHub Actions など）を安定運用できる。
- シグナル精度を週次で検証し、閾値や条件を更新できる。
- データソース差異（Twelve Data / yfinance / OANDA 等）を監視できる。

### 現行運用が勝つ可能性がある条件
- 監視対象が少なく、ロジックも単純で、GASのみで十分な場合。
- 運用者がPython保守よりもGAS保守に慣れている場合。
- 追加の運用負荷（CI/CD、ログ管理、例外処理）を増やしたくない場合。

### 実務的な判定基準
「どちらが優秀か」は次の3指標で判定すると明確です。
1. 月次の見逃し率（本来拾うべきシグナルの取りこぼし）
2. 再現性（同条件で同結果になる割合）
3. 改善速度（週次で条件改善を回せるか）

この3指標を取るなら、一般に **Python中心 + GAS補助** の方が改善しやすく、長期で優位になりやすいです。


## Google Chrome / Chromebook で可能か
結論: **可能です**。ただし「何をChrome側で実行するか」を分けるのが重要です。

### 可能な運用（推奨）
- 判定エンジン: GitHub Actions（クラウド）でPython実行
- 閲覧/管理: ChromeでGitHub・Sheets・LINEを操作
- 通知: GAS + LINE

この形なら、ローカル端末がChrome/Chromebookでも運用可能です。

### 制約が出やすい運用
- MT5をローカルで常時起動してデータ取得する構成

この場合は、Chromebook単体だと運用難易度が上がるため、
Windows端末/VPS等でMT5を動かし、Chrome側は監視UIに寄せる設計が現実的です。

### 実務上の推奨
1. まずは **クラウド完結（Actions + APIデータ）** で稼働
2. 必要になったら MT5 は補助データとして別ホストで追加
3. Chrome は「監視・承認・分析」役に固定
