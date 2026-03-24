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

function Get-ProjectFiles {
    # 正規表現を生成
    $regex = '\\(' + ($EXCLUDE_DIRS -replace '\.', '\.' -join '|') + ')(?=\\|$)'

    # ファイル一覧の取得
    $lists = (Get-ChildItem -Path $Script:TARGET_PATH -Recurse -Exclude $Script:EXCLUDE_EXTS).
    Where({ $_.Name -notin $Script:EXCLUDE_FILE }).
    Where({ $_.FullName -notmatch $regex })

    foreach ($list in $lists) {
        # ファイルとディレクトリのList（構造の書き込み用）
        $Script:filesList.Add($list)

        # ファイルのみのList（ファイルの書き込み用）
        if (-not $list.PSIsContainer) {
            $Script:filesOnlyList.Add($list)
        }
    }
}

# 構造の書き込み
function Write-ProjectStructure {
    $lines = @()
    $lines += "# PROJECT STRUCTURE`n"
    $lines += '```text'

    # ルートディレクトリ
    $root = Split-Path $Script:TARGET_PATH -Leaf
    $lines += "$root/"

    foreach ($item in $Script:filesList | Sort-Object FullName) {
        # 相対パス
        $relative = $item.FullName.Substring($Script:ROOT_PATH_LENGTH).TrimStart('\')

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

    foreach ($list in $Script:filesOnlyList | Sort-Object FullName) {
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
        # 変数
        $Script:filesList = [System.Collections.Generic.List[object]]::new()        # ファイルとディレクトリのList（構造の書き込み用）
        $Script:filesOnlyList = [System.Collections.Generic.List[object]]::new()    # ファイルのみのList（ファイルの書き込み用）

        # ファイル一覧の取得
        Get-ProjectFiles
        # 構造の書き込み
        Write-ProjectStructure
        # フィルの書き込み
        Write-ProjectFiles
    }

    end {
        Write-Host End
    }
}

# エントリーポイント
Main
