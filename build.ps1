param([ValidateSet('debug', 'release')][string]$Mode = 'debug')

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$studio = $env:DEVECO_HOME
if (-not $studio -or -not (Test-Path -LiteralPath $studio)) {
  throw '请先安装 DevEco Studio 6.1，并设置 DEVECO_HOME 环境变量。'
}
$sdk = Join-Path $studio 'sdk'
$java = Join-Path $studio 'jbr'
$hvigor = Join-Path $studio 'tools\hvigor\bin\hvigorw.bat'
if (-not (Test-Path -LiteralPath $hvigor)) { throw '未找到 DevEco Studio 自带的 Hvigor。' }

$env:DEVECO_SDK_HOME = $sdk
$env:JAVA_HOME = $java
$env:PATH = (Join-Path $java 'bin') + ';' + $env:PATH
Push-Location $projectDir
try {
  & $hvigor --mode module -p module=entry@default -p product=default -p buildMode=$Mode assembleHap
  if ($LASTEXITCODE -ne 0) { throw "构建失败，退出码 $LASTEXITCODE" }
  Get-ChildItem (Join-Path $projectDir 'entry\build\default\outputs\default') -Filter '*.hap' |
    Select-Object FullName, Length
} finally { Pop-Location }
