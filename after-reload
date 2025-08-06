# Verificar DNS del NIC
$nic = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1 -Expand Name)
Set-DnsClientServerAddress -InterfaceAlias $nic -ServerAddresses "150.1.7.200"

# Forwarders
Remove-DnsServerForwarder -PassThru -ErrorAction SilentlyContinue | Out-Null
Add-DnsServerForwarder -IPAddress @("1.1.1.1","8.8.8.8")

# Zona reversa (PTR)
if (-not (Get-DnsServerZone | Where-Object {$_.ZoneName -like "*.in-addr.arpa"})) {
    Add-DnsServerPrimaryZone -NetworkId "150.1.7.0/24" -DynamicUpdate Secure
}

# Registros A útiles
$Domain = "cisco.com"
Add-DnsServerResourceRecordA -Name "dc1"   -ZoneName $Domain -IPv4Address "150.1.7.200" -CreatePtr
Add-DnsServerResourceRecordA -Name "www"   -ZoneName $Domain -IPv4Address "150.1.7.20"
Add-DnsServerResourceRecordA -Name "files" -ZoneName $Domain -IPv4Address "150.1.7.30"

# OU + usuario de prueba
Import-Module ActiveDirectory
New-ADOrganizationalUnit -Name "Lab" -Path "DC=cisco,DC=com" -ProtectedFromAccidentalDeletion $false
$UserPwd = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
New-ADUser -Name "lab.user" -SamAccountName "lab.user" -AccountPassword $UserPwd -Enabled $true -Path "OU=Lab,DC=cisco,DC=com"

Enable-PSRemoting -Force
