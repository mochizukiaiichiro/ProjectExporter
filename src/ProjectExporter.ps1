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

# プロジェクト構造のMarkdown生成
function Write-ProjectStructure($path, $lists, $length, $writer) {

    $writer.WriteLine("# PROJECT STRUCTURE`n")
    $writer.WriteLine('```text')

    # ルートディレクトリ
    $root = Split-Path $path -Leaf
    $writer.WriteLine("$root/")

    foreach ($list in $lists) {
        # 相対パス
        $relative = $list.FullName.Substring($length).TrimStart('\')

        # パスを分割して階層を計算
        $parts = $relative -split '\\'
        $depth = $parts.Count - 1

        # インデント（階層 × 2スペース）
        $indent = "  " * $depth

        # ディレクトリかファイルかで出力を変える
        if ($list.PSIsContainer) {
            $writer.WriteLine("$indent$($parts[-1])/")
        }
        else {
            $writer.WriteLine("$indent$($parts[-1])")
        }
    }

    $writer.WriteLine('```')
    $writer.WriteLine("")
}

# ファイルのMarkdown生成
function Write-ProjectFiles($lists, $length, $writer) {

    $writer.WriteLine("# PROJECT FILES`n")

    foreach ($list in $lists) {
        # 相対パス
        $relativePath = $list.FullName.Substring($length).TrimStart('\')
        # コードブロックの言語
        $lang = $list.Extension.TrimStart('.').ToLower()

        # ファイル開始
        $writer.WriteLine("## FILE: $relativePath`n")

        # コードブロックの言語
        $writer.WriteLine('```' + $lang)

        # ファイル内容
        $content = Get-Content -LiteralPath $list.FullName -Raw -Encoding UTF8
        $writer.WriteLine($content)

        # コードブロック終了
        $writer.WriteLine('```')
    }
}

# Main関数
function Main {
    begin {
        Write-Host Start
        # 初期化
        Initialize-Constant     # 定数定義
        Initialize-OutPutFile   # OutPutファイルの削除
        # StreamWriter
        $writer = [System.IO.StreamWriter]::new($Script:OUTPUT_FILE, $false, [System.Text.Encoding]::UTF8)
    }

    process {
        # ファイルとディレクトリのList（構造の書き込み用）
        $filesList = Get-ProjectFiles $Script:TARGET_PATH $Script:EXCLUDE_DIRS $Script:EXCLUDE_FILE $Script:EXCLUDE_EXTS
        # ファイルのみのList（ファイルの書き込み用）
        $filesOnlyList = $filesList.Where({ -not $_.PSIsContainer })

        # プロジェクト構造のMarkdown生成
        Write-ProjectStructure $Script:TARGET_PATH $filesList $Script:ROOT_PATH_LENGTH $writer
        # ファイルのMarkdown生成
        Write-ProjectFiles $filesOnlyList $Script:ROOT_PATH_LENGTH $writer
    }

    end {
        $writer.Close()
        Write-Host End
    }
}

# エントリーポイント
Main
