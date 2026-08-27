# Variables para scripts de PowerShell (Active Directory / Azure Arc)
$SubscriptionId = "c7655bef-2c3b-4462-a848-0d90efe64dd2"
$ResourceGroup  = "rg-enterprise-prod-westeurope"
$Location       = "westeurope"
$TenantId       = "cb561bac-8eae-4e86-979a-765c514af3ae"

# Comando para onboardear servidores Arc:
# .\scripts\arc-onboard-windows.ps1 -SubscriptionId $SubscriptionId -ResourceGroup $ResourceGroup -Location $Location -TenantId $TenantId
