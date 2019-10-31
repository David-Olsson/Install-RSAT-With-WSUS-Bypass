<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.157
	 Created on:   	2019-09-16 10:52
	 Created by:   	David Olsson
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$reg_key_path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing"
if (!(Test-Path $reg_key_path))
{
	New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" -Name "Servicing" | Out-Null
}

IF (Test-Path "$reg_key_path")
{
	Write-Host "Bypassing WSUS..." -ForegroundColor Yellow
	$reg_value = Get-ItemProperty "$reg_key_path" "RepairContentServerSource" -ErrorAction SilentlyContinue
	if ($reg_value -eq $null)
	{
		Write-Host "Creating reg value... (RepairContentServerSource)" -ForegroundColor Yellow
		New-ItemProperty -path "$reg_key_path" -name "RepairContentServerSource" -Value 2 -PropertyType DWord | Out-Null
		
	}
	else
	{
		$current_value = $reg_value.RepairContentServerSource
		if ($current_value -ne 2)
		{
			Write-Host "Changing reg value for RepairContentServerSource... (Current value: $($current_value))" -ForegroundColor Yellow
			Set-ItemProperty -Path "$reg_key_path" -Name "RepairContentServerSource" -Value 2
		}
		
	}
	$RSAT_Capabilities = Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State, Name
	
	foreach ($tool in $RSAT_Capabilities)
	{
		
		if ($tool.state -eq "NotPresent")
		{
			Write-Host "Installing $($tool.Name)..." -ForegroundColor Yellow
			$Add_tool = $tool | Add-WindowsCapability –Online
			Write-Host "Installation complete - Requires restart: $($Add_tool.RestartNeeded)" -ForegroundColor Green
		}
		elseif ($tool.state -eq "Installed")
		{
			Write-Host "$($tool.Name) is already installed!" -ForegroundColor Magenta
		}
	}
	
	Write-Host "Removing WSUS bypass..." -ForegroundColor Yellow
	if ($current_value -eq $null)
	{
		try
		{
			Remove-ItemProperty -Path "$reg_key_path" -Name "RepairContentServerSource"
		}
		catch
		{
			Write-Host "Unable to remove WSUS bypass reg value!" -ForegroundColor Red
		}
	}
	else
	{
		Set-ItemProperty -Path "$reg_key_path" -Name "RepairContentServerSource" -Value $current_value
	}
	
	Write-Host "Complete!" -ForegroundColor Green
	Read-Host "Press 'Enter' to close"
}
else
{
	Write-Host "'Servicing' reg key do not exist." -ForegroundColor Red
}