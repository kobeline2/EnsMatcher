# EnsMatcher

本アプリケーションは、データ X, Y, Z を用いた処理・検証パイプラインを構成しています。処理はモジュールごとに分離されており、各処理は個別の YAML 設定ファイルを使って制御されます。

## 📁 ディレクトリ構成
```MyApp/ ├── config/ # 各処理ステップの設定ファイル（YAML形式） │ ├── preprocess.yaml # Xの前処理設定 │ ├── compute.yaml # Wの計算設定（X'とY） │ └── evaluate.yaml # WとZの比較・評価設定 │ ├── data/ # 入力データ（X, Y, Z）を格納 │ ├── X/ # 元データ X │ ├── Y/ # 元データ Y │ └── Z/ # 評価用データ Z │ ├── preprocessed/ # 前処理済みのX'を保存 │ └── X_prime/ │ ├── results/ # 処理結果や評価結果を保存 │ ├── W_values/ # Wの出力 │ └── evaluation/ # WとZの比較結果 │ ├── src/ # 実装コード │ ├── preprocessing/ # Xの前処理関数群 │ ├── computeW/ # Wの計算関連コード │ └── evaluation/ # 評価処理（Zとの比較など） │ ├── scripts/ # 各ステップの実行スクリプト │ ├── run_preprocess.m │ ├── run_compute.m │ └── run_evaluate.m │ ├── utils/ # 補助関数（ファイル操作、ログ等） │ └── README.md # この説明ファイル


## ⚙️ 処理の流れ

1. **前処理（X → X'）**
   - `scripts/run_preprocess.m` を実行
   - 設定ファイル: `config/preprocess.yaml`
   - 出力先: `preprocessed/X_prime/`

2. **計算（X', Y → W）**
   - `scripts/run_compute.m` を実行
   - 設定ファイル: `config/compute.yaml`
   - 出力先: `results/W_values/`

3. **評価（W, Z → 精度指標）**
   - `scripts/run_evaluate.m` を実行
   - 設定ファイル: `config/evaluate.yaml`
   - 出力先: `results/evaluation/`

## 📝 YAML設定について

各 `.yaml` ファイルでは以下のような情報を指定します：

```yaml
# 例: preprocess.yaml
input: data/X/raw.csv
output: preprocessed/X_prime/processed.csv
method: standardize
params:
  window_size: 10
