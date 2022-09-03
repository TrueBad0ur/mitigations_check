Function checkSEHOP {
	Write-Host "`r`n[SEHOP check]" -ForegroundColor red
	$isEnabledFlag = 1
	$ErrorActionPreference = "stop"
	$valueFromRegistry = -1
	Try {
    	$valueFromRegistry = Get-ItemPropertyValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'DisableExceptionChainValidation'
	} Catch [System.Management.Automation.PSArgumentException] {
		$isEnabledFlag = 0
    	"Registry Key Property missing"
    	Write-Host "SEHOP is disabled" -ForegroundColor green
	} Catch [System.Management.Automation.ItemNotFoundException] {
		$isEnabledFlag = 0
		"Registry Key itself is missing"
		Write-Host "SEHOP is disabled" -ForegroundColor green
	}
	Finally { $ErrorActionPreference = "Continue" }

	if ( $isEnabledFlag -eq 1 -And $valueFromRegistry -ne -1 ) {
		if ( $valueFromRegistry -eq 0 ) {
			Write-Host "SEHOP is enabled" -ForegroundColor green
			Write-Host "To turn it off run: "  -ForegroundColor gray
			Write-Host 'New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "DisableExceptionChainValidation" -Value 1 -PropertyType DWORD -Force' -ForegroundColor gray
		} elseif ($valueFromRegistry -eq 1) {
			Write-Host "SEHOP is disabled" -ForegroundColor green
		}
	}
}

Function clearScreen {
	cls
}

# return:
# SP version checking not implemented yet
#	1 - Windows XP
#	2 - Windows 7
#	3 - Windows 10
Function getWindowsVersion {
	$gotWMI = (Get-WmiObject -class Win32_OperatingSystem).Caption
	if ( $gotWMI.Contains("Microsoft Windows XP") ) { 
		Write-Host "Analyzing Microsoft Windows XP`r`n" -ForegroundColor red
		return 1
	} elseif ( $gotWMI.Contains("Microsoft Windows 7") ) {
		Write-Host "Analyzing Microsoft Windows 7`r`n" -ForegroundColor red
		return 2
	}
	elseif ( $gotWMI.Contains("Microsoft Windows 10") ) {
		Write-Host "Analyzing Microsoft Windows 10`r`n" -ForegroundColor red
		return 3
	}
}

Function checkDEP {
	$supportPolicyValue = -1
	$AvailableValue = -1
	$result = "Error occured!\n"
	
	# AlwaysOff - 0
	$supportPolicyAlwaysOff = "DEP is turned off for all 32-bit applications on the computer with no exceptions"
	
	# AlwaysOn - 1
	$supportPolicyAlwaysOn = "DEP is enabled for all 32-bit applications on the computer"

	# OptIn - 2
	$supportPolicyOptIn = "DEP is enabled for a limited number of binaries, the kernel, and all Windows-based services. However, it is off by default for all 32-bit applications. A user or administrator must explicitly choose either the Always On or the Opt Out setting before DEP can be applied to 32-bit applications"

	#OptOut - 3 
	$supportPolicyOptOut= "DEP is enabled by default for all 32-bit applications. A user or administrator can explicitly remove support for a 32-bit application by adding the application to an exceptions list"

	$supportPolicyValue = Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty DataExecutionPrevention_Available
	if ($supportPolicyValue) {
		$supportPolicyValue =  Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty DataExecutionPrevention_SupportPolicy
		Write-Host "[DEP check]" -ForegroundColor red
		Write-Host '*DEP is "always on" for 64bit processes on 64bit versions of Windows and it cannot be disabled.' -ForegroundColor red
		if ( $supportPolicyValue -eq 0 ) { 
			$result = $supportPolicyAlwaysOff
			Write-Host $result -ForegroundColor green
		} elseif ( $supportPolicyValue -eq 1 ) {
			$result = $supportPolicyAlwaysOn
			Write-Host $result -ForegroundColor green
		} elseif ( $supportPolicyValue -eq 2 ) {
			$result = $supportPolicyOptIn
			Write-Host $result -ForegroundColor green
		} elseif ( $supportPolicyValue -eq 3 ) {
			$result = $supportPolicyOptOut
			Write-Host $result -ForegroundColor green
		}
		Write-Host "(Change will be applied after reboot)`r`nTo turn it off run: "  -ForegroundColor gray
		Write-Host 'cmd.exe /c "bcdedit.exe /set {current} nx AlwaysOff"' -ForegroundColor gray
	}
}

########################## Script Start ##########################
clearScreen
$windowsVersion = getWindowsVersion
checkDEP
checkSEHOP
