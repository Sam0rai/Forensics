<#
.SYNOPSIS
This script's purpose is to be the Windows "Netstat" command on steroids.

.DESCRIPTION
The script displays "Netstat" information, using varying degrees of verbosity, defined by the "InfoLevel" flag.
By default, the script displays "Low" level of information.

.EXAMPLE
.\Invoke-Netstat.ps1 | ft -AutoSize

This will display the following parameters:
- Process Name
- Process Id
- Local Address and  Local Port
- Remote Address and Remote Port
- Connection State
- Connection Creation Time
- Running Time of Connection (in Seconds)

.EXAMPLE
.\Invoke-Netstat.ps1 -InfoLevel Low | ft -AutoSize
Same output as with no flag "-InfoLevel" at all.

.EXAMPLE
.\Invoke-Netstat.ps1 -InfoLevel Medium | ft -AutoSize
Displays all connection parameters as "-InfoLevel Low", with added parameter "CommandLine" (process's full path). i.e.:
- Process Name
- Process Id
- Local Address and  Local Port
- Remote Address and Remote Port
- Connection State
- Connection Creation Time
- Running Time of Connection (in Seconds)
- CommandLine

.EXAMPLE
.\Invoke-Netstat.ps1 -InfoLevel High | ft -AutoSize
Displays all connection parameters as "-InfoLevel Medium", with added parameter "User" (user running the process). i.e.:
- Process Name
- Process Id
- Local Address and  Local Port
- Remote Address and Remote Port
- Connection State
- Connection Creation Time
- Running Time of Connection (in Seconds)
- CommandLine
- User

.PARAMETER InfoLevel
The level of details the script will display (Low, Medium or High).
#>
param(
    [ValidateSet("Low", "Medium", "High")]
    [string]$InfoLevel
)

if($InfoLevel -like "High") {
    $processOwners = @{}
    Get-WmiObject -Class Win32_Process | ForEach-Object {
        $processOwner = $_.GetOwner()
        # Combine the domain and user information together to get the process owner
        $processOwners[[int]$_.ProcessId] = $processOwner.Domain + '\' + $processOwner.User 
    }

    Get-NetTCPConnection | % {
        $now = Get-Date
        New-Object PSCustomObject -Property @{
            LocalAddress  = $_.LocalAddress
            LocalPort     = $_.LocalPort
            RemoteAddress = $_.RemoteAddress
            RemotePort    = $_.RemotePort
            State         = $_.State
            CreationTime  = $_.CreationTime
            RunningTimeInSeconds   = [math]::truncate(($now - $_.CreationTime).TotalSeconds)
            ProcessID     = $_.OwningProcess
            Process       = (Get-Process -Id $_.OwningProcess).ProcessName
            CommandLine   = (Get-CimInstance Win32_Process -Filter "ProcessId = $($($_.OwningProcess))").CommandLine
            User          = $processOwners[[int]$_.OwningProcess]
        }
    } | Select Process, ProcessID, User, LocalAddress, LocalPort, RemoteAddress, RemotePort, State, CreationTime, RunningTimeInSeconds, CommandLine
}
elseif($InfoLevel -like "Medium") {
    Get-NetTCPConnection | % {
        $now = Get-Date
        New-Object PSCustomObject -Property @{
            LocalAddress  = $_.LocalAddress
            LocalPort     = $_.LocalPort
            RemoteAddress = $_.RemoteAddress
            RemotePort    = $_.RemotePort
            State         = $_.State
            CreationTime  = $_.CreationTime
            RunningTimeInSeconds = [math]::truncate(($now - $_.CreationTime).TotalSeconds)
            ProcessID     = $_.OwningProcess
            Process       = (Get-Process -Id $_.OwningProcess).ProcessName
            CommandLine   = (Get-CimInstance Win32_Process -Filter "ProcessId = $($($_.OwningProcess))").CommandLine
        }
    } | Select Process, ProcessID, LocalAddress, LocalPort, RemoteAddress, RemotePort, State, CreationTime, RunningTimeInSeconds, CommandLine

}
else {
    $now = Get-Date
    Get-NetTCPConnection | Select @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}}, @{Name="ProcessID";Expression={$_.OwningProcess}}, LocalAddress, LocalPort, RemoteAddress, RemotePort, State, CreationTime, @{Name="RunningTimeInSeconds";Expression={[math]::truncate(($now - $_.CreationTime).TotalSeconds)}} | sort-object -property ProcessName
}