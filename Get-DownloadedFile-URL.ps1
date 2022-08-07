$folder = C:\Users\JohnDoe\Downloads
$resultsArray = @()
$files = Get-ChildItem $folder -File

foreach($file in $files) {
    try {
        $zoneIdentifier = Get-Content -Path $file.FullName -Stream Zone.Identifier
        if($zoneIdentifier) {
            $match = $zoneIdentifier -match "ReferrerUrl=(<Referr>\w+), "
            $obj = New-Object PSObject -Property @{
                FullName    = $file.FullName
                ReferrerUrl = ($zoneIdentifier -match "ReferrerUrl=").Replace("ReferrerUrl=", "")
                HostUrl     = ($zoneIdentifier -match "HostUrl=").Replace("HostUrl=", "")
            }
            $resultsArray += $obj
        }
    }
    catch { }
}

$resultsArray | Select FullName, ReferrerUrl, HostUrl | ogv
$resultsArray | Select FullName, ReferrerUrl, HostUrl | Export-Csv c:\temp\HostUrl.csv -NoTypeInformation -Encoding Unicode