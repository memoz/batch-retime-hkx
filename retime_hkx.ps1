#Requires -Version 3

$script_path = "$(Split-Path $MyInvocation.MyCommand.Path)"
$factor = 1.5

# Check dependencies
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw [System.IO.FileNotFoundException] "Java runtime not found in path."
}
if (-not (Test-Path -Path "$script_path\hkxpack-cli.jar" -PathType Leaf)) {
    throw [System.IO.FileNotFoundException] "$script_path\hkxpack-cli.jar not found."
}

# Check inputs
if ($args.count -eq 0) {
    throw [System.ArgumentException] "No input file specified."
}
Write-Output "Checking $($args.count) file(s) to process:"
foreach ($a in $args) {
    Write-Output "$([array]::IndexOf($args, $a)+1)/$($args.count) $a"
    if (-not (Test-Path -Path "$a" -PathType Leaf)) {
        throw [System.IO.FileNotFoundException] "File does not exist or is a directory."
    }
    if ($([System.IO.Path]::GetExtension($a)) -ine '.hkx') {
        throw [System.NotSupportedException] "File extension isn't hkx."
    }
}

# Modify hkx file(s)
Write-Output "`nStart processing:"
foreach ($a in $args) {
    $details = [System.Collections.Generic.List[PSObject]]::new()
    Write-Output "$([array]::IndexOf($args, $a)+1)/$($args.count) $a"
    & java -jar "$script_path\hkxpack-cli.jar" unpack "$a"
    if (-not $?) {
        throw "Unpack failed with error code $LASTEXITCODE."
    }
    $xml_file = -join ($([System.IO.Path]::GetFileNameWithoutExtension($a)), ".xml")
    [xml]$xml_content = Get-Content "$xml_file"
    if (-not $xml_content -or (-not $?)) {
        throw "Loading xml file failed."
    }
    $duration = Select-Xml -Xml $xml_content -XPath "/hkpackfile/hksection/hkobject[@class='hkaSplineCompressedAnimation']/hkparam[@name='duration']"
    $duration_secs = [double]::Parse($duration.Node."#text")
    $duration.Node."#text" = [string]($duration_secs * $factor)
    $details.Add([PSCustomObject]@{    
            Name = "duration"
            Old  = [string]$duration_secs
            New  = $($duration.Node.'#text')
        })
    $time_points = Select-Xml -Xml $xml_content -XPath "/hkpackfile/hksection/hkobject[@class='hkaSplineCompressedAnimation']/hkparam[6]/hkobject[1]/hkparam[2]/*"
    foreach ($p in $time_points) {
        $time_string = $p.Node.SelectSingleNode("child::hkparam[@name='time']")."#text"
        $text_string = $p.Node.SelectSingleNode("child::hkparam[@name='text']")."#text"
        $time_secs = [double]::Parse($time_string)
        $p.Node.SelectSingleNode("child::hkparam[@name='time']")."#text" = [string]($time_secs * $factor)
        $details.Add([PSCustomObject]@{
                Name = $text_string
                Old  = $time_string
                New  = $p.Node.SelectSingleNode("child::hkparam[@name='time']")."#text"
            })
    }
    $details | Format-Table -Property Name, Old, New | Write-Output
    $xml_content.Save($xml_file)
    & java -jar "$script_path\hkxpack-cli.jar" pack "$xml_file"
    if (-not $?) {
        throw "Pack failed with error code $LASTEXITCODE."
    }
    Remove-Item $xml_file
}

Write-Output "$($args.count) file(s) successfully processed.`n"