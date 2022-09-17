# WOL 送信 Script




# Requires -Version 5.0
param(
	[Parameter( ValueFromPipeline = $true )][AllowEmptyString()]
	[string]$MAC,	# 起動したいPCのMACアドレス。区切り文字は':','-',' 'のいずれか。

	[Parameter()]
	[uint32]$PORT = 9		# Port番号
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "stop"						# エラーが発生した場合はスクリプトの実行を停止


function DisplayUsage()
{
	Write-Host "USAGE：`n`t.`\$ScriptName AA-BB-CC-DD-EE-FF`n`t.`\$ScriptName 01:AA:BB:10:CC:9A 8080`n"
}



# ～～ 𝕾𝖙𝖆𝖗𝖙 𝖔𝖋 𝖒𝖆𝖎𝖓 𝖕𝖗𝖔𝖈𝖊𝖘𝖘𝖎𝖓𝖌 ～～


# Script Version定義
[string]$ScriptName		= "SendWOL.ps1"
[string]$ScriptVertion	= "0.1.0"

# Title表示
Write-Host -ForegroundColor Yellow "`n$ScriptName   version $ScriptVertion`n"

# 変数の意図がわかりにくいため、引数を別変数に入れ替え
[string]$targetMacString = $MAC
[int]$targetPort = $PORT


# 起動対象未指定ならエラー終了
if( [string]::IsNullOrEmpty($targetMacString) ){
	Write-Host "起動対象PCのMACアドレスが指定されていません。`n第1引数にMACアドレスを指定してください。`n"
	DisplayUsage
	exit -1
}

[int[]]$MacByteArray = $targetMacString -split "[:-]" | ForEach-Object { [Byte] "0x$_" }
[Byte[]]$MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16)

[string]$macStr = $MacByteArray | ForEach-Object { [Convert]::ToString($_,16) }
Write-Host "次の相手先に Wake on Lan パケットを送信します`n`tMac address : $macStr`n`tPort number : $targetPort`n"

try {
	$UdpClient = New-Object System.Net.Sockets.UdpClient
	$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),$targetPort)
	$UdpClient.Send($MagicPacket,$MagicPacket.Length)
	$UdpClient.Close()
}
catch {
    $Error[0] | Select-Object -Property *
}
