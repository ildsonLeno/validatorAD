# Módulo para operações do Active Directory
function Test-ADModuleAvailability {
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        return $false
    }
    return $true
}

function Install-ADModule {
    try {
        Install-WindowsFeature RSAT-AD-PowerShell
        return $true
    }
    catch {
        return $false
    }
}

function Get-ADUserStatus {
    param (
        [string]$displayName
    )
    
    try {
        $searchName = $displayName.Trim()
        # Define a base de pesquisa da OU
        $searchBase = "OU=Usuarios_Ibyte,DC=" + ($env:USERDNSDOMAIN -replace '\.',',DC=')
        
        # Pesquisa apenas dentro da OU especificada
        $adUsers = Get-ADUser -Filter "DisplayName -like '*$searchName*'" `
                            -SearchBase $searchBase `
                            -Properties Enabled,LastLogonDate,DisplayName,SamAccountName `
                            -Server $env:USERDNSDOMAIN
        
        if ($adUsers) {
            foreach ($adUser in $adUsers) {
                $normalizedAD = Remove-DiacriticsAndSpecialChars $adUser.DisplayName
                $normalizedSearch = Remove-DiacriticsAndSpecialChars $searchName
                
                if ($normalizedAD -eq $normalizedSearch) {
                    return @{
                        Found = $true
                        Enabled = $adUser.Enabled
                        User = $adUser
                    }
                }
            }
        }
        
        return @{
            Found = $false
            Enabled = $false
            User = $null
        }
    }
    catch {
        throw $_
    }
}

Export-ModuleMember -Function Test-ADModuleAvailability, Install-ADModule, Get-ADUserStatus