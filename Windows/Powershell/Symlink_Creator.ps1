# Required Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Symlink Creator"
$form.Size = New-Object System.Drawing.Size(400, 250)
$form.StartPosition = "CenterScreen"

# Target file label and textbox
$targetLabel = New-Object System.Windows.Forms.Label
$targetLabel.Text = "Target File:"
$targetLabel.Location = New-Object System.Drawing.Point(10, 20)
$targetLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($targetLabel)

$targetTextbox = New-Object System.Windows.Forms.TextBox
$targetTextbox.Location = New-Object System.Drawing.Point(120, 20)
$targetTextbox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($targetTextbox)

$targetBrowseButton = New-Object System.Windows.Forms.Button
$targetBrowseButton.Text = "Browse"
$targetBrowseButton.Location = New-Object System.Drawing.Point(330, 20)
$targetBrowseButton.Size = New-Object System.Drawing.Size(60, 20)
$form.Controls.Add($targetBrowseButton)

# Link file label and textbox
$linkLabel = New-Object System.Windows.Forms.Label
$linkLabel.Text = "Link File:"
$linkLabel.Location = New-Object System.Drawing.Point(10, 60)
$linkLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($linkLabel)

$linkTextbox = New-Object System.Windows.Forms.TextBox
$linkTextbox.Location = New-Object System.Drawing.Point(120, 60)
$linkTextbox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($linkTextbox)

$linkBrowseButton = New-Object System.Windows.Forms.Button
$linkBrowseButton.Text = "Browse"
$linkBrowseButton.Location = New-Object System.Drawing.Point(330, 60)
$linkBrowseButton.Size = New-Object System.Drawing.Size(60, 20)
$form.Controls.Add($linkBrowseButton)

# Create symlink button
$createButton = New-Object System.Windows.Forms.Button
$createButton.Text = "Create Symlink"
$createButton.Location = New-Object System.Drawing.Point(150, 120)
$createButton.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($createButton)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = ""
$statusLabel.Location = New-Object System.Drawing.Point(10, 170)
$statusLabel.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($statusLabel)

# Browse for Target File
$targetBrowseButton.Add_Click({
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    if ($fileDialog.ShowDialog() -eq "OK") {
        $targetTextbox.Text = $fileDialog.FileName
    }
})

# Browse for Link File
$linkBrowseButton.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    if ($saveDialog.ShowDialog() -eq "OK") {
        $linkTextbox.Text = $saveDialog.FileName
    }
})

# Create Symlink logic
$createButton.Add_Click({
    $targetPath = $targetTextbox.Text
    $linkPath = $linkTextbox.Text

    if (-not (Test-Path $targetPath)) {
        $statusLabel.Text = "Error: Target file does not exist."
        return
    }

    if ([string]::IsNullOrWhiteSpace($linkPath)) {
        $statusLabel.Text = "Error: Link file path is empty."
        return
    }

    try {
        # Attempt PowerShell method
        New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetPath -ErrorAction Stop
        $statusLabel.Text = "Symlink created successfully using PowerShell!"
    } catch {
        try {
            # Attempt cmd method
            $cmdCommand = "cmd /c mklink `"$linkPath`" `"$targetPath`""
            Invoke-Expression $cmdCommand
            if ($LASTEXITCODE -eq 0) {
                $statusLabel.Text = "Symlink created successfully using cmd!"
            } else {
                throw
            }
        } catch {
            $statusLabel.Text = "Error: Failed to create symlink using both methods."
        }
    }
})

# Run the form
[void]$form.ShowDialog()