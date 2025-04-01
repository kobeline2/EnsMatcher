# EnsMatcher

本アプリケーションは、データ X, Y, Z を用いた処理・検証パイプラインを構成しています。処理はモジュールごとに分離されており、各処理は個別の YAML 設定ファイルを使って制御されます。

## 📁 ディレクトリ構成
<pre>
   MyApp/
   ├── config/    
   │   ├── preprocess.yaml         # 準備データ作成
   │   ├── compute.yaml            # マッチング
   │   └── evaluate.yaml           # 評価設定
   │
   ├── data/             
   │   ├── d4pdf/                  # D4PDF
   │   ├── ens/                    # ensemble 
   │   └── amedas/                 # amedas
   │
   ├── preprocessed/     
   │   └── X_prime/
   │
   ├── res/              
   │   ├── W_values/           # Wの出力
   │   └── evaluation/         # WとZの比較結果
   │
   ├── src/         
   │   ├── preprocessing/      # Xの前処理関数群
   │   ├── computeW/           # Wの計算関連コード
   │   └── evaluation/         # 評価処理（Zとの比較など）
   │
   ├── scripts/          
   │   ├── run_preprocess.m
   │   ├── run_compute.m
   │   └── run_evaluate.m
   │
   ├── utils/            
   │
   └── README.md         
</pre>



## 関数の説明
d4pdf_rainMatrix: 


## ⚙️ 処理の流れ
### 前処理
1. QGISから手動で流域を抽出
1. pythonでd4pdfから流域を切り出すためのd4pdf測点に対するティーセン分割をおこなう
   src/python/src/d4pdf2voronoi.py + config
1. d4pdfから流域を切り出して, 指定した流域の年N位までのM時間雨量を抽出 → output dat(ファイル数はN×732, 測点数×M行列)
   src/basin_extraction/d4pdf/d4pdf_rainMatrix.m
1. pythonでensから流域を切り出すためのens測点に対するティーセン分割をおこなう
   src/python/src/ensemble2voronoi.py
1. ensから流域を切り出して, 雨を切り出す → output dat (ファイル数は25（(15-3)/0.5日+1）の初期時刻×51, 測点数×M行列)
   src/basin_extraction/ensemble/ensemble_rainMatrix.m
1. pythonでamedasから流域を切り出すためのamedas測点に対するティーセン分割をおこなう
   src/python/src/kaiseki2voronoi.py
1. kaisekiから流域を切り出して, 雨を切り出す → output dat (ファイル数は1, 測点数×M行列)
   src/basin_extraction/kaiseki/kaiseki_rainMatrix.m
      ここで, 解析のリサンプリングも行う

### クラスタリング
1. d4pdfのクラスタリング
   src/matching/clustering_both.m → output 動画とmatファイルを出力（クラスタ数×（測点数×M時間）行列）
### マッチング
1. d4pdfとEnsとのマッチング（ここで解析雨量もマッチングする）
   src/matching/matching_both.m → output ヒートマップ & 的中率を計算するための情報
      ここで, アンサンブルのリサンプリングも行う
### 検証
1. 的中率を計算
   













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



## 個々の関数の説明
### runExtractRainGrib
grib形式の解析雨量データをMATLABで読めるように展開するコード.
内部ではc++が回っているので, 事前にOSに合わせてmakeする必要がある.
src/cpp/codeに移動し,
　```
make clean
make
　```





