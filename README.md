# wheredns

Simple, dependency-light DNS lookup tool for domains and IPs. Uses only free data and requires no API keys.

## Requirements

- macOS or Linux: `bash`, `dig`
- Windows: PowerShell 5.1+ or PowerShell 7+, `Resolve-DnsName`

## Installation

### macOS

1) Make the script executable:

```bash
chmod +x wheredns
```

2) Optionally add it to your PATH:

```bash
sudo cp wheredns /usr/local/bin/wheredns
```

`dig` is included with macOS.

### Linux

1) Install `dig`:

```bash
sudo apt-get install dnsutils
```

2) Make the script executable and add it to your PATH:

```bash
chmod +x wheredns
sudo cp wheredns /usr/local/bin/wheredns
```

### Windows (PowerShell)

1) Use the PowerShell version:

```powershell
.\wheredns.ps1 example.com
```

2) If your execution policy blocks scripts, allow local scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

3) Optionally add the folder to your PATH or create an alias:

```powershell
Set-Alias wheredns "$PWD\wheredns.ps1"
```

## Usage

### Bash (macOS/Linux)

```bash
./wheredns example.com
./wheredns example.com -email
./wheredns 8.8.8.8 -ip
```

### PowerShell (Windows)

```powershell
.\wheredns.ps1 example.com
.\wheredns.ps1 example.com -Email
.\wheredns.ps1 8.8.8.8 -Ip
```

## Common uses

### Quick domain overview

```bash
./wheredns example.com
```

### Email configuration check

```bash
./wheredns example.com -email
```

### Reverse lookup for an IP

```bash
./wheredns 8.8.8.8 -ip
```

### Windows examples

```powershell
.\wheredns.ps1 example.com
.\wheredns.ps1 example.com -Email
.\wheredns.ps1 8.8.8.8 -Ip
```

## Options

- `-ip` / `-Ip`: Treat input as an IP and perform reverse lookup (PTR)
- `-email` / `-Email`: Show only email-related records (MX, SPF, DMARC)
- `-h, --help` / `-Help`: Show help
