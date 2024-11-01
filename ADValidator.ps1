# Arquivo principal do script
using module .\Modules\StringUtils.psm1
using module .\Modules\ADOperations.psm1
using module .\Modules\UIComponents.psm1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Verifica privilégios de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    Exit
}

# Verifica e instala o módulo AD se necessário
if (-not (Test-ADModuleAvailability)) {
    $installAD = [System.Windows.Forms.MessageBox]::Show(
        "O módulo Active Directory não está instalado. Deseja instalá-lo?",
        "Módulo Ausente",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($installAD -eq 'Yes') {
        if (-not (Install-ADModule)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Falha ao instalar o módulo AD. Por favor, instale as ferramentas RSAT manualmente.",
                "Falha na Instalação",
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

# Define o manipulador de validação
$script:validationHandler = {
    param($components)
    
    if (-not $components) {
        [System.Windows.Forms.MessageBox]::Show(
            "Erro: Componentes não inicializados corretamente.",
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
            throw "Arquivo não encontrado!"
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
                            "DESATIVADO: $($result.User.DisplayName) | Login: $($result.User.SamAccountName) | Último Acesso: $($result.User.LastLogonDate)"
                        )
                    }
                } else {
                    $components.ResultsList.Items.Add("NÃO ENCONTRADO: $displayName")
                }
            }
            catch {
                $components.ResultsList.Items.Add("ERRO AO PROCESSAR: $displayName - $($_.Exception.Message)")
            }
            $progressBar.Value++
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        if ($components.ResultsList.Items.Count -eq 0) {
            $components.ResultsList.Items.Add("Todos os usuários estão ativos no AD")
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

# Define o manipulador de exportação
$script:exportHandler = {
    param($components)
    
    if (-not $components) {
        [System.Windows.Forms.MessageBox]::Show(
            "Erro: Componentes não inicializados corretamente.",
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
            "Exportação Concluída",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
}

# Cria e exibe o formulário principal
$form, $components = New-ValidationForm -OnValidate $script:validationHandler -OnExport $script:exportHandler
[void]$form.ShowDialog()