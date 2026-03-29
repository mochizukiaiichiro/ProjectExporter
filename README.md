# ProjectExporter

任意のフォルダのディレクトリ構造とファイルをMarkdown形式にまとめてエクスポートします。
AI にローカルのプロジェクトを丸ごと読み込まることができ、コピー＆ペーストの手間をなくし、AI の理解精度を向上させます。

## 機能

- プロジェクトのディレクトリ構造とファイルをMarkdown形式で出力
- ディレクトリ構造を階層形式で出力
- ファイルはコードブロックで出力（コードブロックの言語は拡張子を設定）
- 出力対象外設定（ディレクトリ / 拡張子 / ファイル名）
- 出力ファイルの自動分割（指定サイズごとに out_1.md / out_2.md ... を生成）

## 動作環境

本スクリプトはPowerShell7で動作します。

## 使用方法

1. スクリプトを任意の場所に保存
2. PowerShell で実行

```powershell
.\ProjectExporter.ps1
```

3. out_1.md, out_2.md ... のように、指定サイズごとに分割された Markdown が生成されます

## 出力イメージ

````txt
# PROJECT STRUCTURE

```text
src/
file1.txt
file2.txt
lib/
  lib1.lib
  proj/
    proj1.txt
```

# PROJECT FILES

## FILE: file1.txt
```txt
Hello world.
```

## FILE: file2.txt
```txt
Sample text.
```

## FILE: lib\lib1.lib
```lib
LIBRARY CONTENTS
```

## FILE: lib\proj\proj1.txt
```txt
proj1
```
````

## 設定

スクリプト冒頭で対象ディレクトリや除外設定ができます。

```powershell
    Set-Variable -Name ROOT_PATH  -Value $TargetPath -Option ReadOnly -Scope Script             # 対象ディレクトリ
    Set-Variable -Name OUTPUT_FILE_PATH -Value $PSScriptRoot -Option ReadOnly -Scope Script     # 出力ファイルディレクトリ
    Set-Variable -Name OUTPUT_FILE_BASE_NAME -Value "out" -Option ReadOnly -Scope Script        # 出力ファイル名のベース名
    Set-Variable -Name MAX_FILE_SIZE_MB  -Value (1 * 1MB) -Option ReadOnly -Scope Script        # 出力ファイルの分割サイズ（MB）
    Set-Variable -Name EXCLUDE_DIRS -Value @("node_modules", ".git", ".vscode") -Option ReadOnly -Scope Script  # 対象外のディレクトリ
    Set-Variable -Name EXCLUDE_FILES -Value @("ProjectExporter.ps1", "out.md") -Option ReadOnly -Scope Script   # 対象外のファイル
    Set-Variable -Name EXCLUDE_EXTS -Value @(".log") -Option ReadOnly -Scope Script                             # 対象外の拡張子
```

## ライセンス

MIT License
