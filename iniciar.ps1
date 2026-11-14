param(
    [string]$Device = 'chrome',
    [string]$FlutterPath = '',
    [string]$ApiUrl = 'http://localhost:5080',
    [switch]$Demo
)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not $FlutterPath) {
    $taskFlutter = Get-Command flutter -ErrorAction SilentlyContinue
    if ($taskFlutter) { $FlutterPath = $taskFlutter.Source }
    elseif (Test-Path -LiteralPath 'D:\Desenvolvimento\flutter\bin\flutter.bat') {
        $FlutterPath = 'D:\Desenvolvimento\flutter\bin\flutter.bat'
    } else { throw 'Flutter não encontrado. Informe -FlutterPath com o caminho de flutter.bat.' }
}
# A prévia Web dispensa os links simbólicos dos plugins Windows.
if ($Device -in @('chrome', 'edge', 'web-server')) {
    $env:FLUTTER_WINDOWS = 'false'
}
& $FlutterPath pub get
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível resolver as dependências.' }
$taskRun = @('run', '-d', $Device)
if ($Demo) {
    $taskRun += '--dart-define=BUILLON_API_URL='
} else {
    $taskRun += "--dart-define=BUILLON_API_URL=$ApiUrl"
    if ($Device -in @('chrome', 'edge', 'web-server')) {
        $taskRun += @('--web-hostname', 'localhost', '--web-port', '5173')
    }
}
& $FlutterPath @taskRun
exit $LASTEXITCODE
