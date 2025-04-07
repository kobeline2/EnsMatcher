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



## ⚙️ 処理の流れ
### 前処理

1. pythonでensから流域を切り出すためのens測点に対するティーセン分割をおこなう
   src/python/src/ensemble2voronoi.py
1. pythonでamedasから流域を切り出すためのamedas測点に対するティーセン分割をおこなう
   src/python/src/kaiseki2voronoi.py

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
   













## ⚙️ 処理の流れ(例えばmiya(宮川)の場合)
### 前処理
1. **初期化**
   - `EnsMatcher`に移動し, `init`とMATLABで打ち込む. 
   - `getConfig.m`に必要情報を記入する. 
1. **流域のシェープファイルを作る(GIS)**
   - GISなどを用いて作る. フォーマットはgeojsonにしておく. 
   - 保存先: `data/geo/miya/basin.geojson`

1. **ティーセン分割(python)**
   - 流域のシェープファイルをd4pdfの計算点に基づきティーセン分割する. 
   - 各セルには, d4pdfの番号が振られ, セルの面積が計算される. 
   - 設定ファイル: `src/python/config/config_d4pdf2voronoi.json`
   - 出力ファイル: `data/geo/miya/area_per_d4pdfcell.csv`
   - 実行方法
<pre>
python src/python/d4pdf2voronoi.py 
   → configファイルをきかれるので`config_d4pdf2voronoi.json`と打ち込む
</pre>

1. **d4pdfから流域を切り出して, 年N位までのM時間雨量を抽出**
- 設定ファイル: `config/rain_extraction.yaml`
- d4pdfデータ(yearStart~yearEnd)からbasin流域を抽出し(process A), 各年に対してrank番目までのnHourRain時間雨量を計算する. 
- saveD4pdfbasinRainがtrueであれば, process Aの結果が保存される(保存先: `data/d4pdf/miya`). 
メンバー数は通常51だが, debugなどで制限したければ, memStart=1, memEnd=4などと制限すればよい.
- 実行方法
<pre>
pathConfig = 'config/rain_extraction.yaml' 
runRainExtraction(pathConfig)
% runRainExtraction(pathConfig, 'debug') % debug時. test/の中のデータがまわる.
</pre>
- 出力先: `res/nHourRain/d4pdf/miya`

1. **ensから流域を切り出して, 雨を切り出す**
- 設定ファイル: `config/rain_extraction.yaml`
- ensembleデータ(Y年M月D日H時間からnHourRain時間分)からbasin流域を抽出する. 
- メンバー数は通常51だが, debugなどで制限したければ, memEnsStart=1, memEnsEnd=4などと制限すればよい.
- output dat (ファイル数は25（(15-3)/0.5日+1）の初期時刻×51, 測点数×M行列)
- 実行方法
<pre>
pathConfig = 'config/rain_extraction.yaml' 
runRainExtraction(pathConfig)
% runRainExtraction(pathConfig, 'debug') % debug時. test/の中のデータがまわる.
</pre>
- 出力先: `res/nHourRain/ens/miya`

1. **解析雨量をMATLABで読めるフォーマットに展開する**
‐ `runExtractRainGrib.mat`を実行
grib形式の解析雨量データをMATLABで読めるように展開するコード.
内部ではc++が回っているので, 事前にOSに合わせてmakeする必要がある.
`src/cpp/code`に移動し,
<pre>
make clean
make
</pre>


1. **解析雨量から流域を切り出して, 雨を切り出す**
- 設定ファイル: `config/rain_extraction.yaml`
- 解析雨量からtargetTimeからnHourRain時間分データを切り出しす. 
- 解析雨量のd4pdf計算点に対するリサンプリングもこの中で行う. 
リサンプリングの過程で, 流域抽出も行われる. 
- output dat (ファイル数は1, 測点数×M行列)
- 実行方法
<pre>
pathConfig = 'config/rain_extraction.yaml' 
runRainExtraction(pathConfig)
% runRainExtraction(pathConfig, 'debug') % debug時. test/の中のデータがまわる.
</pre>
- 出力先: `res/nHourRain/kaiseki/miya`
  
### Clustering
- 設定ファイル: `config/clustering.yaml`
- 例えばnHourRain=72の場合, `res/nHourRain/d4pdf/miya/72hours`配下にある1~maxRankデータを用いたクラスタリングを行う. 
- 実行方法
<pre>
pathConfig = 'config/clustering.yaml';
const = getConfig();
% const = getConfig('debug'); % debug時. test/の中のデータがまわる.
cfg = readyaml(pathConfig);
clusteringSpatioTemp(cfg, const)
% clusteringSpatioTemp(pathConfig, const) 
</pre>
- 出力先: `res/clustered/miya/spatioTemp/72hours`配下にクラスタリング結果と, そのメタ情報をいれたconfigファイルが拡張子以外同名で出力される.

### Matching
- 設定ファイル: `config/matching.yaml`
- 例えばnHourRain=72の場合, `res/nHourRain/d4pdf/miya/72hours`配下にある1~maxRankデータを用いたクラスタリングを行う. 
- 実行方法
<pre>
pathConfig = 'config/clustering.yaml';
const = getConfig();
% const = getConfig('debug'); % debug時. test/の中のデータがまわる.
cfg = readyaml(pathConfig);
clusteringSpatioTemp(cfg, const)
% clusteringSpatioTemp(pathConfig, const) 
</pre>
- 出力先: `res/clustered/miya/spatioTemp/72hours`配下にクラスタリング結果と, そのメタ情報をいれたconfigファイルが拡張子以外同名で出力される.

### Postprocessing



## 個々の関数の説明
### runExtractRainGrib
grib形式の解析雨量データをMATLABで読めるように展開するコード.
内部ではc++が回っているので, 事前にOSに合わせてmakeする必要がある.
`src/cpp/code`に移動し,
<pre>
make clean
make
</pre>
 ### runExtractRainGrib








## 出力のサイズ
1. `res/nHourRain/d4pdf`: cell number(d4pdf) × nHour
1. `res/nHourRain/ens`: cell number(ens) × nHour
1. `res/nHourRain/kaiseki`: cell number(d4pdf) × nHour (already resampled)
1. `res/clustered/`: (cell number × nHour) × cluster number







## 📝 YAML設定について

各 `.yaml` ファイルでは以下のような情報を指定します：

```yaml
# 例: preprocess.yaml
input: data/X/raw.csv
output: preprocessed/X_prime/processed.csv
method: standardize
params:
  window_size: 10
```

## memo
target event X basin
20200701 21:00

kaiseki 
“2020070012100”
2020/0701 - 2020/0704 kaiseki data

ensemble
20200701 21:00 - 12days(72 hours)
|
20200701 21:00
Xbasin ensemble data

