param(
    [string]$HostSupabase = 'aws-1-us-east-1.pooler.supabase.com',
    [string]$Usuario = 'postgres.opjxuwjokbuzucvqogrl',
    [int]$Porta = 5432
)

$ErrorActionPreference = 'Stop'
$senha = Read-Host 'Senha do banco PostgreSQL no Supabase' -AsSecureString
if ($senha.Length -eq 0) { throw 'Informe a senha do banco.' }

$conexao = [System.Data.Common.DbConnectionStringBuilder]::new()
$conexao['Host'] = $HostSupabase
$conexao['Port'] = $Porta
$conexao['Database'] = 'postgres'
$conexao['Username'] = $Usuario
$conexao['Password'] = [System.Net.NetworkCredential]::new('', $senha).Password
$conexao['SSL Mode'] = 'VerifyFull'
$conexao['Root Certificate'] = Join-Path $PSScriptRoot 'backend/supabase-ca.crt'
$conexao['Timeout'] = 10

$arquivo = Join-Path $PSScriptRoot 'backend/appsettings.Local.json'
$config = if (Test-Path -LiteralPath $arquivo) {
    Get-Content -Raw -LiteralPath $arquivo | ConvertFrom-Json
} else {
    [pscustomobject]@{}
}
if ($null -eq $config.ConnectionStrings) {
    $config | Add-Member -NotePropertyName ConnectionStrings -NotePropertyValue ([pscustomobject]@{}) -Force
}
$config.ConnectionStrings | Add-Member -NotePropertyName Supabase -NotePropertyValue $conexao.ConnectionString -Force
$config | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -LiteralPath $arquivo
$conexao.Clear()
$senha.Dispose()
Write-Output 'Conexão gravada em backend/appsettings.Local.json.'
