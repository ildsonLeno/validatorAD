# Arquivo principal do script
using module .\Modules\StringUtils.psm1
using module .\Modules\ADOperations.psm1
using module .\Modules\UIComponents.psm1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Verifica privil�gios de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    Exit
}

# Verifica e instala o m�dulo AD se necess�rio
if (-not (Test-ADModuleAvailability)) {
    $installAD = [System.Windows.Forms.MessageBox]::Show(
        "O m�dulo Active Directory n�o est� instalado. Deseja instal�-lo?",
        "M�dulo Ausente",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($installAD -eq 'Yes') {
        if (-not (Install-ADModule)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Falha ao instalar o m�dulo AD. Por favor, instale as ferramentas RSAT manualmente.",
                "Falha na Instala��o",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            Exit
        }
    }
    else {
        Exit
    }
}

Import-Module ActiveDirectory

# Define o manipulador de valida��o
$script:validationHandler = {
    param($components)
    
    if (-not $components) {
        [System.Windows.Forms.MessageBox]::Show(
            "Erro: Componentes n�o inicializados corretamente.",
            "Erro",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    $components.ResultsList.Items.Clear()
    $components.ExportButton.Enabled = $false
    
    try {
        if (-not (Test-Path $components.FilePathBox.Text)) {
            throw "Arquivo n�o encontrado!"
        }
        
        $users = Get-Content $components.FilePathBox.Text -Encoding UTF8
        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Location = New-Object System.Drawing.Point(140,420)
        $progressBar.Size = New-Object System.Drawing.Size(500,23)
        $components.ValidateButton.Parent.Controls.Add($progressBar)
        $progressBar.Maximum = $users.Count
        $progressBar.Value = 0
        
        foreach ($displayName in $users) {
            try {
                $result = Get-ADUserStatus $displayName
                
                if ($result.Found) {
                    if (-not $result.Enabled) {
                        $components.ResultsList.Items.Add(
                            "DESATIVADO: $($result.User.DisplayName) | Login: $($result.User.SamAccountName) | �ltimo Acesso: $($result.User.LastLogonDate)"
                        )
                    }
                } else {
                    $components.ResultsList.Items.Add("N�O ENCONTRADO: $displayName")
                }
            }
            catch {
                $components.ResultsList.Items.Add("ERRO AO PROCESSAR: $displayName - $($_.Exception.Message)")
            }
            $progressBar.Value++
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        if ($components.ResultsList.Items.Count -eq 0) {
            $components.ResultsList.Items.Add("Todos os usu�rios est�o ativos no AD")
        }
        else {
            $components.ExportButton.Enabled = $true
        }
        
        $components.ValidateButton.Parent.Controls.Remove($progressBar)
        $progressBar.Dispose()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Erro: $_",
            "Erro",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

# Define o manipulador de exporta��o
$script:exportHandler = {
    param($components)
    
    if (-not $components) {
        [System.Windows.Forms.MessageBox]::Show(
            "Erro: Componentes n�o inicializados corretamente.",
            "Erro",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.Filter = "Arquivos CSV (*.csv)|*.csv"
    $SaveFileDialog.FileName = "Resultados_AD_Validacao.csv"
    
    if ($SaveFileDialog.ShowDialog() -eq 'OK') {
        $components.ResultsList.Items | Export-Csv -Path $SaveFileDialog.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show(
            "Resultados exportados com sucesso!",
            "Exporta��o Conclu�da",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
}

# Cria e exibe o formul�rio principal
$form, $components = New-ValidationForm -OnValidate $script:validationHandler -OnExport $script:exportHandler
[void]$form.ShowDialog()