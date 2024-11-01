# Módulo para utilitários de manipulação de strings
function Remove-DiacriticsAndSpecialChars {
    param ([string]$text)
    
    $normalized = $text.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object Text.StringBuilder
    
    for ($i = 0; $i -lt $normalized.Length; $i++) {
        $c = $normalized[$i]
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    
    return $sb.ToString()
}

Export-ModuleMember -Function Remove-DiacriticsAndSpecialChars