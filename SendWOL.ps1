# WOL 送信 Script
#
# 同一セグメント内に Broad castで Magic packet (WOL)を送信する。
# ルータを超えることは(一部の製品を除いて)できない。
# 使い方(パラメータ指定)は DisplayUsage関数を参照
#
# 更新履歴
#	2022/09/18	Ver 0.1.1	USAGEを丁寧に書いた。ファイル先頭の説明コメント追加。
#	2022/09/17	Ver 0.1.0	新規作成

param(
	[Parameter( ValueFromPipeline = $true )][AllowEmptyString()]
	[string]$MAC,		# 起動したいPCのMACアドレス。区切り文字は':','-'のどちらか。

	[Parameter()]
	[uint32]$PORT = 9	# Port number
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = "stop"						# エラーが発生した場合はスクリプトの実行を停止


function DisplayUsage()
{
	Write-Host "USAGE：`n`t.`\$ScriptName -MAC MAC address [-PORT Port number]"
	Write-Host ""
	Write-Host "`t`t-MAC`t':' or '-' で区切られた6オクテットの文字列。"
	Write-Host "`t`t-PORT`tUDP packetを送信する際の Port number。省略時は9。通常は省略で良い。"
	Write-Host ""
	Write-Host "`t例:"
	Write-Host "`t`t.\SendWOL.ps1 -MAC AA-BB-CC-DD-EE-FF"
	Write-Host "`t`t.\SendWOL.ps1 -PORT 8080 -MAC 11:22:33:44:55:66"
}



# ～～ 𝕾𝖙𝖆𝖗𝖙 𝖔𝖋 𝖒𝖆𝖎𝖓 𝖕𝖗𝖔𝖈𝖊𝖘𝖘𝖎𝖓𝖌 ～～

# Script Version定義
[string]$ScriptName		= "SendWOL.ps1"
[string]$ScriptVertion	= "0.1.1"

# Title表示
Write-Host -ForegroundColor Yellow "`n$ScriptName   version $ScriptVertion`n"

# 変数の意図がわかりにくいため、引数を別変数に入れ替え
[string]$targetMacString = $MAC
[int]$targetPort = $PORT

# define代わりの定義
$MacRepeatTimes = 16		# Magic packetに含める MAC addressの数
$NumOfByteToBeSent = 6 + 6 * $MacRepeatTimes	# (FF * 6) + MAC * 繰り返し回数


# 起動対象未指定ならエラー終了
if( [string]::IsNullOrEmpty($targetMacString) ){
	Write-Host -ForegroundColor darkred "起動対象PCのMACアドレスが指定されていません。`n第1引数にMACアドレスを指定してください。`n"
	DisplayUsage
	exit -1
}

# Magic packet作成
# 先頭 FF * 6、以降は区切り文字なしMAC address * 12回以上連続したデータ
[int[]]$MacByteArray = $targetMacString -split "[:-]" | ForEach-Object { [Byte] "0x$_" }
[Byte[]]$MagicPacket = (,0xFF * 6) + ($MacByteArray  * $MacRepeatTimes)

# MAC addressを string ➔ int ➔ 再度stringにして表示
[string]$macStr = $MacByteArray | ForEach-Object { [Convert]::ToString($_,16) }
Write-Host "次の指定で Wake on Lan パケットを送信します`n`tMac address : $macStr`n`tPort number : $targetPort`n"

try {
	# UDPで送信
	$UdpClient = New-Object System.Net.Sockets.UdpClient
	$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),$targetPort)
	[int]$sendByte = $UdpClient.Send($MagicPacket,$MagicPacket.Length)
	$UdpClient.Close()
	if( $sendByte -lt $NumOfByteToBeSent ){
		Write-Host -ForegroundColor Yellow "送信データが破壊されている可能性があります。\n送信Byte数：$sendByte`n送信予定Byte数：$NumOfByteToBeSent"
	}
	elseif( $sendByte -gt $NumOfByteToBeSent ){
		Write-Host -ForegroundColor Yellow "送信データにごみデータが入っている可能性があります。\n送信Byte数：$sendByte`n送信予定Byte数：$NumOfByteToBeSent"
	}
	else {
		Write-Host "送信完了`n"
	}
}
catch {
    $Error[0] | Select-Object -Property *
}
