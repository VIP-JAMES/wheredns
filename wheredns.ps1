 #!/usr/bin/env pwsh
param(
  [Parameter(Position=0)]
  [string]$InputValue,
  [switch]$Ip,
  [switch]$Email,
  [switch]$Help
)

Set-StrictMode -Version Latest

function Show-Usage {
@"
Usage: ./wheredns.ps1 <domain|ip> [options]

Options:
  -Ip           Treat input as an IP and perform reverse lookup (PTR)
  -Email        Show only email-related records (MX, SPF, DMARC)
  -Help         Show this help

Default (no options): show A, AAAA, MX, SPF, DMARC, NS, CNAME, SOA, TXT
"@ | Write-Output
}

if ($Help -or [string]::IsNullOrWhiteSpace($InputValue)) {
  Show-Usage
  if ($Help) {
    exit 0
  }
  exit 1
}

function Print-Section([string]$Title) {
  Write-Output ""
  Write-Output "==== $Title ===="
}

function Is-Ip([string]$Value) {
  $parsed = [System.Net.IPAddress]$null
  [System.Net.IPAddress]::TryParse($Value, [ref]$parsed)
}

function Get-Records([string]$Name, [string]$Type) {
  try {
    Resolve-DnsName -Name $Name -Type $Type -ErrorAction Stop
  } catch {
    @()
  }
}

function Get-PropValue([object]$Obj, [string[]]$Names) {
  foreach ($name in $Names) {
    $prop = $Obj.PSObject.Properties[$name]
    if ($null -ne $prop) {
      return $prop.Value
    }
  }
  return $null
}

function Get-ReverseName([string]$IpString) {
  $ip = [System.Net.IPAddress]$null
  if (-not [System.Net.IPAddress]::TryParse($IpString, [ref]$ip)) {
    return $null
  }

  if ($ip.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
    $bytes = $ip.GetAddressBytes()
    [array]::Reverse($bytes)
    return ("{0}.in-addr.arpa" -f ($bytes -join "."))
  }

  if ($ip.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
    $hex = ($ip.GetAddressBytes() | ForEach-Object { $_.ToString("x2") }) -join ""
    $nibbles = $hex.ToCharArray()
    [array]::Reverse($nibbles)
    return ("{0}.ip6.arpa" -f ($nibbles -join "."))
  }

  return $null
}

if (Is-Ip $InputValue) {
  $Ip = $true
}

if ($Ip) {
  Print-Section "PTR"
  $ptrName = Get-ReverseName $InputValue
  if ([string]::IsNullOrWhiteSpace($ptrName)) {
    Write-Output "Invalid IP address."
    exit 1
  }
  $ptr = Get-Records -Name $ptrName -Type "PTR"
  if (@($ptr).Count -gt 0) {
    $ptr | ForEach-Object { Get-PropValue $_ @("NameHost", "Name") } | Write-Output
  } else {
    Write-Output "No PTR records found."
  }
  exit 0
}

$Domain = $InputValue
Write-Output "Domain: $Domain"

function Get-Spf([string]$Name) {
  Get-Records -Name $Name -Type "TXT" |
    ForEach-Object { $_.Strings } |
    Where-Object { $_ -match '(?i)^v=spf1' }
}

function Get-Dmarc([string]$Name) {
  Get-Records -Name $Name -Type "TXT" |
    ForEach-Object { $_.Strings } |
    Where-Object { $_ -match '(?i)^v=DMARC1' }
}

function Get-Mx([string]$Name) {
  Get-Records -Name $Name -Type "MX" |
    ForEach-Object { "{0} {1}" -f $_.Preference, $_.NameExchange }
}

function Get-A([string]$Name) {
  Get-Records -Name $Name -Type "A" |
    ForEach-Object { $_.IPAddress }
}

function Get-Aaaa([string]$Name) {
  Get-Records -Name $Name -Type "AAAA" |
    ForEach-Object { $_.IPAddress }
}

function Get-Ns([string]$Name) {
  Get-Records -Name $Name -Type "NS" |
    ForEach-Object { Get-PropValue $_ @("NameHost", "Name") }
}

function Get-Cname([string]$Name) {
  Get-Records -Name $Name -Type "CNAME" |
    ForEach-Object { Get-PropValue $_ @("NameHost", "Name") }
}

function Get-Soa([string]$Name) {
  Get-Records -Name $Name -Type "SOA" |
    ForEach-Object {
      "PrimaryServer: {0}" -f (Get-PropValue $_ @("PrimaryServer", "NameServer"))
      "ResponsiblePerson: {0}" -f (Get-PropValue $_ @("ResponsiblePerson", "NameAdministrator"))
      "SerialNumber: {0}" -f (Get-PropValue $_ @("SerialNumber"))
      "RefreshInterval: {0}" -f (Get-PropValue $_ @("RefreshInterval"))
      "RetryDelay: {0}" -f (Get-PropValue $_ @("RetryDelay"))
      "ExpireLimit: {0}" -f (Get-PropValue $_ @("ExpireLimit"))
      "MinimumTTL: {0}" -f (Get-PropValue $_ @("MinimumTTL"))
    }
}

function Get-Txt([string]$Name) {
  Get-Records -Name $Name -Type "TXT" |
    ForEach-Object { $_.Strings }
}

if ($Email) {
  Print-Section "MX"
  $mx = Get-Mx $Domain
  if (@($mx).Count -gt 0) { $mx | Write-Output } else { Write-Output "No MX records found." }

  Print-Section "SPF"
  $spf = Get-Spf $Domain
  if (@($spf).Count -gt 0) { $spf | Write-Output } else { Write-Output "No SPF record found." }

  Print-Section "DMARC"
  $dmarcHost = "_dmarc.$Domain"
  $dmarc = Get-Dmarc $dmarcHost
  Write-Output "Host: $dmarcHost"
  if (@($dmarc).Count -gt 0) { $dmarc | Write-Output } else { Write-Output "No DMARC record found." }

  exit 0
}

Print-Section "A"
$a = Get-A $Domain
if (@($a).Count -gt 0) { $a | Write-Output } else { Write-Output "No A records found." }

Print-Section "AAAA"
$aaaa = Get-Aaaa $Domain
if (@($aaaa).Count -gt 0) { $aaaa | Write-Output } else { Write-Output "No AAAA records found." }

Print-Section "MX"
$mx = Get-Mx $Domain
if (@($mx).Count -gt 0) { $mx | Write-Output } else { Write-Output "No MX records found." }

Print-Section "SPF"
$spf = Get-Spf $Domain
if (@($spf).Count -gt 0) { $spf | Write-Output } else { Write-Output "No SPF record found." }

Print-Section "DMARC"
$dmarcHost = "_dmarc.$Domain"
$dmarc = Get-Dmarc $dmarcHost
Write-Output "Host: $dmarcHost"
if (@($dmarc).Count -gt 0) { $dmarc | Write-Output } else { Write-Output "No DMARC record found." }

Print-Section "NS"
$ns = Get-Ns $Domain
if (@($ns).Count -gt 0) { $ns | Write-Output } else { Write-Output "No NS records found." }

Print-Section "CNAME"
$cname = Get-Cname $Domain
if (@($cname).Count -gt 0) { $cname | Write-Output } else { Write-Output "No CNAME records found." }

Print-Section "SOA"
$soa = Get-Soa $Domain
if (@($soa).Count -gt 0) { $soa | Write-Output } else { Write-Output "No SOA record found." }

Print-Section "TXT"
$txt = Get-Txt $Domain
if (@($txt).Count -gt 0) { $txt | Write-Output } else { Write-Output "No TXT records found." }
 
