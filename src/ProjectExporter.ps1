# 定数定義
function Initialize-Constant {
    Set-Variable -Name TARGET_PATH  -Value "../test/dir" -Option ReadOnly -Scope Script                         # 対象ディレクトリ
    Set-Variable -Name OUTPUT_FILE  -Value "out.md" -Option ReadOnly -Scope Script                              # 出力ファイル
    Set-Variable -Name EXCLUDE_DIRS -Value @("node_modules", ".git", ".vscode") -Option ReadOnly -Scope Script  # 対象外のディレクトリ
    Set-Variable -Name EXCLUDE_FILE -Value @("FolderExporter.ps1", "out.md") -Option ReadOnly -Scope Script     # 対象外のファイル
    Set-Variable -Name EXCLUDE_EXTS -Value @("*.log") -Option ReadOnly -Scope Script                            # 対象外の拡張子
    Set-Variable -Name ROOT_PATH_LENGTH -Value (Resolve-Path $Script:TARGET_PATH).Path.Length -Option ReadOnly -Scope Script    # ルートディレクトリの絶対パスの文字数
}

# OutPutファイルの削除
function Initialize-OutPutFile {
    if (Test-Path $Script:OUTPUT_FILE) {
        Remove-Item $Script:OUTPUT_FILE
    }
}

# ファイル一覧の取得
function Get-ProjectFiles($path, $dirs, $file , $exts) {
    # 正規表現を生成
    $regex = '\\(' + ($dirs -replace '\.', '\.' -join '|') + ')(?=\\|$)'
    # ファイル一覧の取得
    return (Get-ChildItem -Path $path -Recurse -Exclude $exts).
    Where({ $_.Name -notin $file }).
    Where({ $_.FullName -notmatch $regex }) |
    Sort-Object FullName
}

# 構造の書き込み
function Write-ProjectStructure($path, $lists, $length) {
    $lines = @()
    $lines += "# PROJECT STRUCTURE`n"
    $lines += '```text'

    # ルートディレクトリ
    $root = Split-Path $path -Leaf
    $lines += "$root/"

    foreach ($item in $lists) {
        # 相対パス
        $relative = $item.FullName.Substring($length).TrimStart('\')

        # パスを分割して階層を計算
        $parts = $relative -split '\\'
        $depth = $parts.Count - 1

        # インデント（階層 × 2スペース）
        $indent = "  " * $depth

        # ディレクトリかファイルかで出力を変える
        if ($item.PSIsContainer) {
            $lines += "$indent$($parts[-1])/"
        }
        else {
            $lines += "$indent$($parts[-1])"
        }
    }

    $lines += '```'
    $lines += ""

    #出力
    $lines | Out-File -FilePath $Script:OUTPUT_FILE -Append
}

# フィルの書き込み
function Write-ProjectFiles {
    $lines = @()
    $lines += "# PROJECT FILES`n"

    foreach ($list in $Script:filesOnlyList) {
        # 相対パス
        $relativePath = $list.FullName.Substring($Script:ROOT_PATH_LENGTH).TrimStart('\')
        # コードブロックの言語
        $lang = $list.Extension.TrimStart('.').ToLower()

        $lines += "## FILE: $relativePath`n"    # ファイル開始
        $lines += '```' + $lang                 # コードブロック開始
        $lines += Get-Content $list.FullName    # ファイル内容
        $lines += '```'                         # コードブロック終了
        $lines += ""
    }
    #出力
    $lines | Out-File -FilePath $Script:OUTPUT_FILE -Append
}
# Main関数
function Main {

    begin {
        Write-Host Start
        # 初期化
        Initialize-Constant     # 定数定義
        Initialize-OutPutFile   # OutPutファイルの削除
    }

    process {
        # ファイルとディレクトリのList（構造の書き込み用）
        $Script:filesList = Get-ProjectFiles $Script:TARGET_PATH $Script:EXCLUDE_DIRS $Script:EXCLUDE_FILE $Script:EXCLUDE_EXTS
        # ファイルのみのList（ファイルの書き込み用）
        $Script:filesOnlyList = $filesList.Where({ -not $_.PSIsContainer })

        # 構造の書き込み
        Write-ProjectStructure $Script:TARGET_PATH $filesList $Script:ROOT_PATH_LENGTH
        # フィルの書き込み
        Write-ProjectFiles
    }

    end {
        Write-Host End
    }
}

# エントリーポイント
Main
