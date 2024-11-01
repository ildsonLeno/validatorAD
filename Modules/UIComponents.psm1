# Módulo para componentes e manipuladores da interface do usuário
function New-ValidationForm {
    param (
        [scriptblock]$OnValidate,
        [scriptblock]$OnExport
    )
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Validador de Usuários AD'
    $form.Size = New-Object System.Drawing.Size(800,500)
    $form.StartPosition = 'CenterScreen'
    $form.Icon = [System.Drawing.SystemIcons]::Shield
    
    $components = @{
        BrowseButton = New-Object System.Windows.Forms.Button
        FilePathBox = New-Object System.Windows.Forms.TextBox
        ResultsList = New-Object System.Windows.Forms.ListBox
        ValidateButton = New-Object System.Windows.Forms.Button
        ExportButton = New-Object System.Windows.Forms.Button
    }
    
    # Configuração dos componentes
    $components.BrowseButton.Location = New-Object System.Drawing.Point(650,30)
    $components.BrowseButton.Size = New-Object System.Drawing.Size(100,23)
    $components.BrowseButton.Text = 'Procurar'
    
    $components.FilePathBox.Location = New-Object System.Drawing.Point(30,30)
    $components.FilePathBox.Size = New-Object System.Drawing.Size(600,20)
    
    $components.ResultsList.Location = New-Object System.Drawing.Point(30,70)
    $components.ResultsList.Size = New-Object System.Drawing.Size(720,330)
    $components.ResultsList.Font = New-Object System.Drawing.Font("Consolas", 10)
    
    $components.ValidateButton.Location = New-Object System.Drawing.Point(30,420)
    $components.ValidateButton.Size = New-Object System.Drawing.Size(100,23)
    $components.ValidateButton.Text = 'Validar'
    
    $components.ExportButton.Location = New-Object System.Drawing.Point(650,420)
    $components.ExportButton.Size = New-Object System.Drawing.Size(100,23)
    $components.ExportButton.Text = 'Exportar'
    $components.ExportButton.Enabled = $false
    
    # Adiciona manipuladores de eventos
    $components.BrowseButton.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Filter = "Arquivos de texto (*.txt)|*.txt"
        if ($dialog.ShowDialog() -eq 'OK') {
            $components.FilePathBox.Text = $dialog.FileName
        }
    }.GetNewClosure())
    
    # Corrigido: Usando GetNewClosure para preservar o escopo
    $components.ValidateButton.Add_Click({
        if ($OnValidate) {
            & $OnValidate $components
        }
    }.GetNewClosure())
    
    $components.ExportButton.Add_Click({
        if ($OnExport) {
            & $OnExport $components
        }
    }.GetNewClosure())
    
    # Adiciona controles ao formulário
    $form.Controls.AddRange(@(
        $components.BrowseButton,
        $components.FilePathBox,
        $components.ResultsList,
        $components.ValidateButton,
        $components.ExportButton
    ))
    
    return $form, $components
}

Export-ModuleMember -Function New-ValidationForm