# Claude Worklog

## 2026-04-28

### 概要

M5Core2 ベースの MIDI トランスポーザーに、MIDI メッセージ管理機能を追加した。従来の転調機能に加えて、`FILTER` と `MAPPER` を持つ `MIDI Manager` グループを実装し、画面遷移、UI、実機操作、書き込みまで確認した。

### 実装内容

- 既存スケッチを `M5Core2-MIDITransposerBT.ino` から `M5Core2-MIDIXposeFilBT.ino` へ整理
- `MIDI Manager` を追加
- `FILTER` を追加
- `MAPPER` を追加
- 処理順を `FILTER -> MAPPER -> Transpose -> OUT` に変更
- `FILTER` / `MAPPER` それぞれに独立した `BYPASS` / `ACTIVE` を追加
- Common / Realtime を含む MIDI メッセージ分類を追加

### 画面と操作

- メニューを 2 階層化
- 長押し `C` で `転調グループ <-> MIDI Manager`
- 短押し `C` で現在グループ内のサブモード切替
- 左上タイトルを `MIDI Transposer` / `MIDI Manager` で切替
- `FILTER` / `MAPPER` / `BYPASS` の下の空き領域を使って編集 UI を再配置
- 下段の `<` / `>`、`EN/DIS`、`ADD`、`DEL`、`UP`、`DOWN` の操作領域を拡大
- `DOWN` 表記へ統一

### ボタン仕様

- 転調グループ中の `B`
  - `DIRECT`: レンジ切替
  - `KEY`: 上位転調/通常転調切替
- `FILTER` 中の `B`
  - `Type` の順送り
- `MAPPER` 中の `B`
  - `PG1/PG2` 切替

### 調整・修正履歴

- `MIDI Manager` 用見出しを別行で出していた構成をやめ、左上タイトル切替へ変更
- `FILTER` の `Type` を単独循環ボタン化
- `BtnB` が `FILTER` 中に誤って `MAPPER` 側の挙動へ流れる問題を修正
- `BtnB` 処理後に同一フレームで他ボタン処理へ落ちる経路を整理

### 実機確認

- `arduino-cli compile --fqbn m5stack:esp32:m5stack_core2 D:\M5\M5Core2-MIDIXposeFilBT`
- `arduino-cli upload -p COM4 --fqbn m5stack:esp32:m5stack_core2 D:\M5\M5Core2-MIDIXposeFilBT`
- `FILTER` 中の `B` が `Type` 切替として動作することを最終確認
