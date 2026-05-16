# Auto elevate to admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$startMenuDirs = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Shortcut Path Updater"
$form.Size = New-Object System.Drawing.Size(540, 360)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Step 1
$lbl1 = New-Object System.Windows.Forms.Label
$lbl1.Text = "Step 1 - Select shortcut (.lnk):"
$lbl1.Location = New-Object System.Drawing.Point(20, 20)
$lbl1.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($lbl1)

$txtLnk = New-Object System.Windows.Forms.TextBox
$txtLnk.Location = New-Object System.Drawing.Point(20, 45)
$txtLnk.Size = New-Object System.Drawing.Size(380, 25)
$txtLnk.ReadOnly = $true
$form.Controls.Add($txtLnk)

$btnPickLnk = New-Object System.Windows.Forms.Button
$btnPickLnk.Text = "Browse..."
$btnPickLnk.Location = New-Object System.Drawing.Point(410, 43)
$btnPickLnk.Size = New-Object System.Drawing.Size(100, 27)
$form.Controls.Add($btnPickLnk)

# Current target display
$lblCurrent = New-Object System.Windows.Forms.Label
$lblCurrent.Text = "Current target:"
$lblCurrent.Location = New-Object System.Drawing.Point(20, 78)
$lblCurrent.Size = New-Object System.Drawing.Size(490, 18)
$lblCurrent.ForeColor = [System.Drawing.Color]::Gray
$lblCurrent.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$form.Controls.Add($lblCurrent)

# Step 2
$lbl2 = New-Object System.Windows.Forms.Label
$lbl2.Text = "Step 2 - Select new .exe:"
$lbl2.Location = New-Object System.Drawing.Point(20, 110)
$lbl2.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($lbl2)

$txtExe = New-Object System.Windows.Forms.TextBox
$txtExe.Location = New-Object System.Drawing.Point(20, 135)
$txtExe.Size = New-Object System.Drawing.Size(380, 25)
$txtExe.ReadOnly = $true
$form.Controls.Add($txtExe)

$btnPickExe = New-Object System.Windows.Forms.Button
$btnPickExe.Text = "Browse..."
$btnPickExe.Location = New-Object System.Drawing.Point(410, 133)
$btnPickExe.Size = New-Object System.Drawing.Size(100, 27)
$form.Controls.Add($btnPickExe)

# Update button
$btnUpdate = New-Object System.Windows.Forms.Button
$btnUpdate.Text = "Update Shortcut"
$btnUpdate.Location = New-Object System.Drawing.Point(20, 185)
$btnUpdate.Size = New-Object System.Drawing.Size(490, 38)
$btnUpdate.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
$btnUpdate.ForeColor = [System.Drawing.Color]::White
$btnUpdate.FlatStyle = "Flat"
$btnUpdate.Enabled = $false
$form.Controls.Add($btnUpdate)

# Result
$txtResult = New-Object System.Windows.Forms.TextBox
$txtResult.Location = New-Object System.Drawing.Point(20, 240)
$txtResult.Size = New-Object System.Drawing.Size(490, 70)
$txtResult.Multiline = $true
$txtResult.ReadOnly = $true
$txtResult.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$form.Controls.Add($txtResult)

# Logic
$btnPickLnk.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Select shortcut file"
    $dlg.Filter = "Shortcut (*.lnk)|*.lnk"
    $dlg.InitialDirectory = $startMenuDirs[1]
    if ($dlg.ShowDialog() -eq "OK") {
        $txtLnk.Text = $dlg.FileName
        $shell = New-Object -ComObject WScript.Shell
        $sc = $shell.CreateShortcut($dlg.FileName)
        $lblCurrent.Text = "Current target: $($sc.TargetPath)"
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        if ($txtExe.Text) { $btnUpdate.Enabled = $true }
    }
})

$btnPickExe.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Select new .exe"
    $dlg.Filter = "Executable (*.exe)|*.exe"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtExe.Text = $dlg.FileName
        if ($txtLnk.Text) { $btnUpdate.Enabled = $true }
    }
})

$btnUpdate.Add_Click({
    try {
        $shell = New-Object -ComObject WScript.Shell
        $sc = $shell.CreateShortcut($txtLnk.Text)
        $sc.TargetPath = $txtExe.Text
        $sc.WorkingDirectory = Split-Path $txtExe.Text -Parent
        $sc.Save()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        $txtResult.ForeColor = [System.Drawing.Color]::FromArgb(0, 128, 0)
        $txtResult.Text = "Done! Shortcut updated successfully.`r`nNew target: $($txtExe.Text)"
    } catch {
        $txtResult.ForeColor = [System.Drawing.Color]::Red
        $txtResult.Text = "Failed: $($_.Exception.Message)"
    }
})

$form.ShowDialog()
