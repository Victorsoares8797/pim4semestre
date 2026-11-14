param(
    [ValidateRange(1, 65535)]
    [int]$Porta = 5080
)

$ErrorActionPreference = 'Stop'
$backend = Join-Path $PSScriptRoot 'backend'
$publicado = Join-Path $backend 'Buillon.Api.dll'
$url = "http://localhost:$Porta"

Push-Location -LiteralPath $backend
try {
    if (Test-Path -LiteralPath $publicado) {
        & dotnet $publicado --urls $url
    } else {
        & dotnet run --project Buillon.Api.csproj --urls $url
    }
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}
