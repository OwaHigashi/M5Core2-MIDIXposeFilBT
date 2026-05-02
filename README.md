# M5Core-MIDIXposeFilBT

M5Core2 + M5 MIDI Module2 (外付け MIDI モジュール) を使った **MIDI トランスポーザー / メッセージ管理ツール / SMF プレーヤー** です。
本機自体には音源を持たないので、本リポジトリでは **PLAY モード (本体で発音するモード) は無効化** されています。
起動直後は転調グループの `DIRECT` モードに入り、`C` 長押しでグループ巡回 (`転調 -> MIDI 管理 -> SMF プレーヤー -> 転調 ...`) します。

現在のスケッチ本体は [M5Core2-MIDIXposeFilBT.ino](./M5Core2-MIDIXposeFilBT.ino) です。

> **姉妹プロジェクト**: M5 Unit MIDI (Port A 接続、内蔵音源あり) を使う UM 版は [`../M5Core2-MIDIXposeFilBTUM`](../M5Core2-MIDIXposeFilBTUM) です。
> ソースは MIDI ピン定義と冒頭の `#define MIDIXPOSE_HAS_LOCAL_SYNTH` (本リポジトリは `0`) を除いてほぼ同一になっています。
> このため一方の更新は、原則として両方に反映されます。

## ハードウェア

- **本体**: M5Stack Core2
- **MIDI 出力**: M5 MIDI Module2 (外付け、接続先の外部音源で発音)
- **接続**: Core2 の GPIO に MIDI Module2 を結線
- **UART**: G13=RX / G14=TX, 31250 bps (`Serial2`)
- I2C を解放する必要はありません (Port A は使用しないため)。

## 起動スプラッシュ

電源投入時に約 4 秒のオープニングが流れます。
"OWAMIDICON" のロゴが虹色グローで脈動し、上下のグラデーションバーがスイープイン、ローディングバーがゆっくり充填します。

## 概要 — 入力された MIDI の処理

入力された MIDI メッセージは次の順序で処理し、MIDI Module2 経由で外部音源へ流します。

1. `FILTER`
2. `MAPPER`
3. `Transpose`
4. MIDI OUT

`FILTER` と `MAPPER` はそれぞれ独立して `BYPASS` / `ACTIVE` を切り替えられます。
両方を `BYPASS` にすれば、従来どおりの低遅延な転調処理だけを使えます。

## 概要 — SMF プレーヤー

SD カードの `/smf` (または `/SMF`) フォルダにある `.mid` / `.smf` ファイルを再生し、MIDI Module2 経由で外部音源を鳴らします。

- **16 チャンネル分の鍵盤を画面下部に表示**します。再生中は Note On に応じてキーが緑 (白鍵) / オレンジ (黒鍵) で点灯します。
- **System Exclusive メッセージにも対応**します (受信したペイロードはそのまま MIDI OUT に流れます)。
- 内部の SMF パーサは `MD_MIDIFile` ライブラリ (本リポジトリ `src/MD_MIDIFile/` 同梱) を使用しています。
- 入室は `C` 長押しによるグループ巡回経由 (`MIDI 管理 -> SMF プレーヤー`)。
- 退出は `C` 長押し (`SMF プレーヤー -> 転調`)。
- 内部で SD バスを `SD.h` から `SdFat` に一旦譲渡し、退出時に戻します。

## モード構成

画面は `転調`、`MIDI 管理`、`SMF プレーヤー` の 3 つのグループで構成されます (PLAY モードはこのハードでは無効)。

- `C` 長押し: グループ巡回 `転調 -> MIDI 管理 -> SMF プレーヤー -> 転調 ...`
- `C` 短押し: 現在グループ内の次モードへ

### 1. 転調グループ (起動直後)

`C` 短押しで次を巡回します。

- `DIRECT`
- `KEY`
- `INSTANT`
- `SEQUENCE`

### 2. MIDI 管理グループ

`C` 短押しで次を巡回します。

- `FILTER`
- `MAPPER`

ここで処理した MIDI をそのまま MIDI Module2 から出力できます。

### 3. SMF プレーヤー

- `A` 短押し: 前の曲
- `B` 短押し: 再生 / 停止トグル
- `C` 短押し: 次の曲
- `C` 長押し: 転調グループへ戻る (再生中は停止し All Notes Off)

## ハードウェアボタン

### 共通

- `A`: All Notes Off の有効/無効切替 (SMF プレーヤー中は前曲)
- `B`: モード別アクション (SMF: 再生停止 / FILTER: Type 送り / 他)
- `C` 短押し: 現在グループ内の次モードへ (SMF: 次曲)
- `C` 長押し: グループ巡回

### 転調グループ中の `B`

- `DIRECT`: レンジ切替
  - `0..+11`
  - `-11..0`
  - `-5..+6`
- `KEY`: 上位転調/通常転調の切替
- `INSTANT`: 何もしない
- `SEQUENCE`: 何もしない

### MIDI 管理グループ中の `B`

- `FILTER`: `Type` を次のメッセージ種別へ進める
- `MAPPER`: `PG1/PG2` 切替

## 転調機能

### DIRECT

12 ボタンの直接選択方式です。
現在レンジ内の転調値をそのまま選択します。

### KEY

メジャー/マイナーのキー指定で転調値を決定します。

### INSTANT

よく使う転調値をワンタップで呼び出します。

- `0`
- `+1`
- `+2`
- `+3`
- `+5`
- `-1`
- `-2`
- `-3`
- `-5`

### SEQUENCE

複数ステップの転調値パターンを順番に呼び出します。
ステップ値編集、ステップ移動、パターン切替、SD 保存に対応しています。

## MIDI Manager

### FILTER

不要な MIDI メッセージをブロックします。
一致したメッセージは `MAPPER` と `Transpose` に進まず、その場で破棄されます。

現状のルール定義項目:

- `EN/DIS`
- `Type`
- `Ch`
- `ADD`
- `DEL`
- `UP`
- `DOWN`

`Type` はタップまたは `B` ボタンで順送りします。
`Ch` は `ALL` または `Ch1..Ch16` を切り替えます。

#### 対応メッセージ種別

- `NoteOff` / `NoteOn` / `KeyPrs` / `PrgChg` / `CtrlChg` / `ChPrs` / `Bend`
- `SysEx` / `MTC` / `SongPos` / `SongSel` / `TuneReq`
- `Clock` / `Start` / `Cont` / `Stop` / `ActSn` / `Reset`

### MAPPER

MIDI メッセージの再割り当て/変換を行います。
リスト先頭から順に評価し、最初に一致したルールだけを適用します。

現状のルール定義項目:

- `EN/DIS`
- `ADD`
- `DEL`
- `UP`
- `DOWN`
- `PG1/PG2`

#### PG1 (変換元) / PG2 (変換先)

- `Type`
- `Ch`
- `Data1`
- `Min`
- `Max`

補足:

- `Data1` は `ANY` / `KEEP` を使う項目があります
- `Min/Max` は値レンジ変換に使います
- `FILTER` の後に `MAPPER` が動作します

`tests/test_midi_mapper.cpp` に `MAPPER` 単体の動作検証ハーネス (PC ホストでビルド) を同梱しています (UM 版リポジトリ参照)。

## 画面サンプル

| 画面 | スクリーンショット |
|------|--------------------|
| DIRECT | `screenshots/01-direct.png` |
| KEY | `screenshots/02-key.png` |
| INSTANT | `screenshots/03-instant.png` |
| SEQUENCE | `screenshots/04-sequence.png` |
| FILTER (BYPASS) | `screenshots/05-filter.png` |
| FILTER (ACTIVE) | `screenshots/06-filter-active.png` |
| MAPPER PG1 | `screenshots/07-mapper-pg1.png` |
| MAPPER PG2 | `screenshots/08-mapper-pg2.png` |
| **SMF Player (停止)** | `screenshots/09-smf-stop.png` |
| **SMF Player (再生中)** | `screenshots/10-smf-playing.png` |

> 注: スクリーンショット (`00-play*` 含む) は UM 版用に作成されたものをそのまま流用しています。本リポジトリでは PLAY モードは表示されません。

## 基本的な使い方

### 転調だけを使う場合

1. 起動直後は `DIRECT` モードに入っています。
2. `C` 短押しで `DIRECT` / `KEY` / `INSTANT` / `SEQUENCE` を選びます。
3. `MIDI Manager` を経由させたくない場合は、`FILTER` と `MAPPER` の両方を `BYPASS` にして使います。

### SMF を再生する場合

1. SD カードに `/smf` または `/SMF` フォルダを作り、`.mid` / `.smf` ファイルを置きます。
2. 起動後、`C` 長押しで `転調 -> MIDI 管理 -> SMF プレーヤー` の順にグループを進めます。
3. `A` / `C` 短押しで曲を選択、`B` で再生 / 停止。
4. 戻るには `C` 長押し (`SMF プレーヤー -> 転調`)。

### FILTER を設定する場合

1. `C` 長押しで `MIDI Manager` に入ります。
2. `C` 短押しで `FILTER` を表示します。
3. `ADD` でルールを追加し、対象ルールを一覧から選びます。
4. `Type` をタップ、または `B` ボタンでブロック対象のメッセージ種別を切り替えます。
5. `Ch` で `ALL` または `Ch1..Ch16` を選びます。
6. `EN/DIS` でそのルールを有効化します。
7. 画面上部の `BYPASS` / `ACTIVE` で、FILTER 全体を即座に有効/無効化できます。

### MAPPER を設定する場合

1. `MIDI Manager` 内で `C` 短押しを使って `MAPPER` を表示します。
2. `ADD` でルールを追加し、対象ルールを一覧から選びます。
3. `B` ボタンで `PG1` と `PG2` を切り替えます。
4. `PG1` で変換元の `Type` / `Ch` / `Data1` / `Min` / `Max` を設定します。
5. `PG2` で変換先の `Type` / `Ch` / `Data1` / `Min` / `Max` を設定します。
6. `UP` / `DOWN` でルール順を変更します。評価順はリスト先頭からなので、上にあるルールほど優先されます。
7. `EN/DIS` で個別ルールを有効化し、上部の `BYPASS` / `ACTIVE` で MAPPER 全体の有効/無効を切り替えます。

### すぐに効果を確認する場合

- `FILTER` または `MAPPER` を `ACTIVE` にすると、その場で受信 MIDI に対して処理が反映されます。
- 効果比較をしたい場合は、上部の `BYPASS` と `ACTIVE` を切り替えるだけで元の経路と比較できます。
- 低遅延の従来動作に戻したい場合は、`FILTER` と `MAPPER` の両方を `BYPASS` にします。

## タッチ操作

`FILTER` / `MAPPER` / `BYPASS(ACTIVE)` は上段の大ボタンです。
一覧から対象ルールを選び、下段の操作ボタンと編集ボックスで設定します。

SMF プレーヤー画面はタッチ操作なし、`A` / `B` / `C` ボタンのみです。

## MIDI 処理仕様メモ

- Realtime / Common メッセージも分類して処理
- `FILTER` はメッセージ単位でブロック
- `MAPPER` は最初に一致した 1 ルールを適用
- `Transpose` は主に Note On / Note Off へ適用
- `All Notes Off` は全 16ch に送信
- SMF 再生はファイル内のテンポ/ティック情報に従い、SysEx も含めて送出

現状の制限:

- `SysEx` はフィルタ対象だが、ペイロード変換は未実装
- SMF プレーヤー入室中は他機能の SD カード書き込みが一時停止します (退出時に復帰)

## ファイル構成

- `M5Core2-MIDIXposeFilBT.ino`: メインスケッチ
- `src/`: Bluetooth HID 関連コード
- `src/MD_MIDIFile/`: SMF パーサライブラリ (移植元: `../M5Core2-SMF-Player`)
- `screenshots/`: 各モードの画面キャプチャ
- `scripts/`: 画面キャプチャ用 PowerShell スクリプト (UM 版に同梱)

## ビルドと書き込み

```bash
arduino-cli compile --fqbn m5stack:esp32:m5stack_core2 .
arduino-cli upload  -p COM3 --fqbn m5stack:esp32:m5stack_core2 .
```

`-p` オプションには本機が見えている COM ポート (USB) を指定します
(`arduino-cli board list` で確認可能)。

ディレクトリ名と `.ino` 名は一致しているので、追加のジャンクション/コピーは不要です。

## USB シリアルコマンド

PC から USB シリアルで本体を操作できます。
シリアル速度は `115200bps`、改行は `LF` または `CRLF` です。

起動後に `HELP` を送ると、利用できるコマンド一覧を返します。
`STATUS` は現モード (`mode=DIRECT/.../SMF_PLAYER` を含む)、転調値、FILTER/MAPPER の状態、MIDI 入出力カウントなどを 1 行で返します。
`MODE PLAY` / `GROUP PLAY` コマンドは内部的に PLAY モードへ遷移しますが、本ハードでは音源が無いため画面表示以上の意味はありません (デバッグ用)。
