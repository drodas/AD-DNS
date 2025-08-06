# ================================
# Variables — AJUSTAR SI HACE FALTA
# ================================
$Hostname              = "DC1"
$EthernetAlias         = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1 -Expand Name)
$IPv4Address           = "150.1.7.200"
$IPv4PrefixLength      = 24                  # CAMBIAR si tu máscara NO es /24
$DefaultGateway        = "150.1.7.1"
$PreferredDNS          = $IPv4Address        # el propio DC/DNS
$AlternateDNS          = "1.1.1.1"           # opcional
$DomainFQDN            = "cisco.com"
$DomainNetBIOS         = "CISCO"
$SafeModePwdPlain      = "P@ssw0rd123!"      # CAMBIAR
$DnsForwarders         = @("1.1.1.1","8.8.8.8")
$ReverseNetworkId      = "150.1.7.0/24"      # CAMBIAR si NO es /24
# ================================

# 1) Renombrar host (si hace falta)
if ((hostname) -ne $Hostname) {
    Rename-Computer -NewName $Hostname -Force
    Write-Host "Hostname cambiado a $Hostname. Reiniciando..." -ForegroundColor Yellow
    Restart-Computer
    Start-Sleep -Seconds 10
    exit
}

# 2) Red: IP estática y DNS local
Write-Host "Configurando red en $EthernetAlias..." -ForegroundColor Cyan
Get-NetIPAddress -InterfaceAlias $EthernetAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Where-Object {$_.IPAddress -ne $IPv4Address} | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

if (-not (Get-NetIPAddress -InterfaceAlias $EthernetAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
          Where-Object {$_.IPAddress -eq $IPv4Address})) {
    New-NetIPAddress -InterfaceAlias $EthernetAlias -IPAddress $IPv4Address -PrefixLength $IPv4PrefixLength -DefaultGateway $DefaultGateway
}
Set-DnsClientServerAddress -InterfaceAlias $EthernetAlias -ServerAddresses ($PreferredDNS,$AlternateDNS)

# 3) Hora
w32tm /config /manualpeerlist:"time.windows.com,0x9" /syncfromflags:manual /reliable:yes /update | Out-Null
w32tm /resync | Out-Null

# 4) Roles AD DS + DNS
Write-Host "Instalando AD DS y DNS..." -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools

# 5) Crear bosque + DNS
$SecureDSRM = ConvertTo-SecureString $SafeModePwdPlain -AsPlainText -Force
Write-Host "Creando bosque $DomainFQDN..." -ForegroundColor Cyan
Install-ADDSForest `
  -DomainName $DomainFQDN `
  -DomainNetbiosName $DomainNetBIOS `
  -InstallDNS `
  -SafeModeAdministratorPassword $SecureDSRM `
  -Force
# => Reinicia automáticamente
