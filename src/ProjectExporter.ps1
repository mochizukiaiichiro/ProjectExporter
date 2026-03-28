# コマンド引数
[CmdletBinding()]
param(
    [ValidateScript({
            # null、空文字の場合はMain関数でローカルパスに置き換える
            if ([string]::IsNullOrWhiteSpace($_)) { return $true }
            # 値がある場合はパスの存在チェック
            Test-Path $_
        })]
    [string]$Path
)

# Main関数
function Main {
    begin {
        Write-Host Start

        # Pathがnull、空文字の場合はローカルパスに置き換える
        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = Get-Location
        }

        # 初期化
        Initialize-Constant -TargetPath $Path   # 定数定義
        Initialize-OutPutFile                   # OutPutファイルの削除
        # StreamWriter
        $writer = [System.IO.StreamWriter]::new($Script:OUTPUT_FILE, $false, [System.Text.Encoding]::UTF8)
    }

    process {
        # ファイルとディレクトリのList（構造の書き込み用）
        $filesList = Get-ProjectFiles $Script:TARGET_PATH $Script:EXCLUDE_DIRS $Script:EXCLUDE_FILE $Script:EXCLUDE_EXTS
        # ファイルのみのList（ファイルの書き込み用）
        $filesOnlyList = $filesList.Where({ $_ -is [System.IO.FileInfo] })

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

# 定数定義
function Initialize-Constant {
    param(
        [string]$TargetPath
    )

    Set-Variable -Name TARGET_PATH  -Value $TargetPath -Option ReadOnly -Scope Script                           # 対象ディレクトリ
    Set-Variable -Name OUTPUT_FILE  -Value "out.md" -Option ReadOnly -Scope Script                              # 出力ファイル
    Set-Variable -Name EXCLUDE_DIRS -Value @("node_modules", ".git", ".vscode") -Option ReadOnly -Scope Script  # 対象外のディレクトリ
    Set-Variable -Name EXCLUDE_FILE -Value @("ProjectExporter.ps1", "out.md") -Option ReadOnly -Scope Script    # 対象外のファイル
    Set-Variable -Name EXCLUDE_EXTS -Value @(".log") -Option ReadOnly -Scope Script                             # 対象外の拡張子
    Set-Variable -Name ROOT_PATH_LENGTH -Value (Resolve-Path $Script:TARGET_PATH).Path.Length -Option ReadOnly -Scope Script    # ルートディレクトリの絶対パスの文字数
    Set-Variable -Name LANGUAGE_MAP -Value @{
        ".md"           = "markdown"
        ".yml"          = "yaml"
        ".yaml"         = "yaml"
        ".env"          = "text"
        ".txt"          = "text"
        ".gitignore"    = "text"
        ".dockerignore" = "text"
        ".prettierrc"   = "json"
        ".eslintrc"     = "json"
        ".babelrc"      = "json"
    } -Option ReadOnly -Scope Script    # 拡張子とコードブロックの割当て（AIが誤認するもののみ）
}

# OutPutファイルの削除
function Initialize-OutPutFile {
    if (Test-Path $Script:OUTPUT_FILE) {
        Remove-Item $Script:OUTPUT_FILE
    }
}

# ファイル一覧の取得
function Get-ProjectFiles {
    param(
        [string]$RootPath,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFiles,
        [string[]]$ExcludeExts
    )

    $results = New-Object System.Collections.Generic.List[object]

    function Scan([string]$path) {

        # 現在のディレクトリ名
        $dirName = [System.IO.Path]::GetFileName($path) 

        # ディレクトリの除外
        if ($ExcludeDirs -contains $dirName) {
            return
        }

        # --- ファイル処理 ---
        $files = [System.IO.Directory]::GetFiles($path)
        foreach ($file in $files) {

            $name = [System.IO.Path]::GetFileName($file)
            $ext = [System.IO.Path]::GetExtension($file)

            # 除外ファイル・除外拡張子
            if ($ExcludeFiles -contains $name) { continue }
            if ($ExcludeExts -contains $ext) { continue }

            # FileInfo を追加
            $results.Add([System.IO.FileInfo]::new($file))
        }

        # --- ディレクトリ処理 ---
        $dirs = [System.IO.Directory]::GetDirectories($path)
        foreach ($dir in $dirs) {

            $name = [System.IO.Path]::GetFileName($dir)

            # ディレクトリの除外
            if ($ExcludeDirs -contains $name) { continue }

            # DirectoryInfoを追加
            $results.Add([System.IO.DirectoryInfo]::new($dir))

            # 再帰
            Scan $dir
        }
    }

    # 走査開始
    Scan $RootPath

    return $results
}


# プロジェクト構造のMarkdown生成
function Write-ProjectStructure($path, $lists, $length, $writer) {

    $writer.WriteLine("# PROJECT STRUCTURE`n")
    $writer.WriteLine(@"
以下のルールで構造を示します：
- `/` で終わるものはディレクトリ
- `/` が付かないものはファイル（拡張子の有無は問いません）

"@)
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
        if ($list -is [System.IO.DirectoryInfo]) {
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
        $lang = Get-CodeLanguage $list

        # ファイル開始
        $writer.WriteLine("## FILE: $relativePath`n")
        # メタ情報
        $writer.WriteLine("- path: $relativePath")
        $writer.WriteLine("- ext: $lang`n")

        # コードブロックの言語
        $writer.WriteLine('```' + $lang)

        # ファイル内容
        $content = Get-Content -LiteralPath $list.FullName -Raw -Encoding UTF8
        $writer.WriteLine($content)

        # コードブロック終了
        $writer.WriteLine('```')
    }
}

# 拡張子からコードブロックを取得
function Get-CodeLanguage($fileInfo) {
    $ext = $fileInfo.Extension.ToLower()

    # マッピングに存在する場合
    if ($Script:LANGUAGE_MAP.ContainsKey($ext)) {
        return $Script:LANGUAGE_MAP[$ext]
    }

    # 拡張子なし
    if ([string]::IsNullOrWhiteSpace($ext)) {
        return "text"
    }

    # 未知の拡張子 → 拡張子名をそのまま使う
    return $ext.TrimStart('.')
}

# エントリーポイント
Main
