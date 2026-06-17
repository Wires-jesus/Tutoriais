<#
.SYNOPSIS
    Generates cascading flow diagrams for C5/CONSINCO objects to monitorpdvmiddle tables
#>

param(
    [string]$OracleUser = "local",
    [string]$OraclePassword = "local",
    [string]$ServiceName = "LOCAL",
    [string]$TnsAdminPath = "C:\oracle\product\11.2.0\dbhome_1\NETWORK\ADMIN"
)

$ErrorActionPreference = "Stop"
$env:TNS_ADMIN = $TnsAdminPath

function Connect-Oracle {
    param([string]$User, [string]$Password, [string]$ServiceName)
    Write-Host "Connecting to Oracle: $User@$ServiceName..." -ForegroundColor Cyan
    $testQuery = 'SELECT banner FROM v$version WHERE ROWNUM = 1;'
    $result = $testQuery | sqlplus -s "$User/$Password@$ServiceName" 2>&1
    if ($result -match "ORA-") { throw "Failed to connect: $result" }
    Write-Host "[OK] Connection successful" -ForegroundColor Green
    return "$User/$Password@$ServiceName"
}

function Invoke-OracleQuery {
    param([string]$SqlQuery, [string]$ConnectionString)
    $tmpFile = [System.IO.Path]::GetTempFileName()
    try {
        $SqlQuery | Out-File -FilePath $tmpFile -Encoding ASCII
        return (& sqlplus -s $ConnectionString "@$tmpFile" 2>&1)
    } finally {
        Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

function Extract-DependencyData {
    param([string]$ConnectionString, [string]$OutputCsvPath)
    Write-Host "Extracting dependency data from Oracle..." -ForegroundColor Cyan
    
    $sqlQuery = 'WITH c5_objects AS (
  SELECT object_name, object_type, owner
  FROM dba_objects
  WHERE (object_name LIKE ''%C5%'' OR object_name LIKE ''%CONSINCO%'')
)
SELECT c.object_name || ''|'' || c.object_type || ''|'' || c.owner || ''|'' ||
       NVL(d.referenced_name, '''') || ''|'' || NVL(d.referenced_type, '''') || ''|'' || NVL(d.referenced_owner, '''')
FROM c5_objects c
LEFT JOIN dba_dependencies d ON c.object_name = d.name AND c.owner = d.owner AND d.type = c.object_type
ORDER BY c.object_name, d.referenced_name;'

    $data = Invoke-OracleQuery -SqlQuery $sqlQuery -ConnectionString $ConnectionString
    $csvContent = "object_name|object_type|owner|referenced_name|referenced_type|referenced_owner`n"
    
    foreach ($line in $data) {
        if ($line -match '\|' -and $line -notmatch '^-' -and $line.Trim()) {
            $csvContent += "$line`n"
        }
    }
    
    $csvContent | Out-File -FilePath $OutputCsvPath -Encoding UTF8
    Write-Host "[OK] Data extracted: $OutputCsvPath" -ForegroundColor Green
    return (Import-Csv -Path $OutputCsvPath -Delimiter '|')
}

function Build-CascadingFlow {
    param([object[]]$DependencyData)
    Write-Host "Building cascading flow structure..." -ForegroundColor Cyan
    
    $flowMap = @{}
    foreach ($record in $DependencyData) {
        $objectKey = $record.object_name + "_" + $record.object_type + "_" + $record.owner
        
        if ($null -eq $flowMap[$objectKey]) {
            $flowMap[$objectKey] = @{
                object_name = $record.object_name
                object_type = $record.object_type
                owner = $record.owner
                dependencies = @()
                sources = @()
                destinations = @()
            }
        }
        
        if ($record.referenced_name) {
            $flowMap[$objectKey].dependencies += @{
                name = $record.referenced_name
                type = $record.referenced_type
                owner = $record.referenced_owner
            }
            
            if ($record.referenced_type -eq 'TABLE') {
                if ($record.referenced_owner -eq 'MONITORPDVMIDDLE') {
                    $flowMap[$objectKey].destinations += $record.referenced_name
                } else {
                    $flowMap[$objectKey].sources += $record.referenced_name
                }
            }
        }
    }
    
    Write-Host ("[OK] Flow structure built: " + $flowMap.Keys.Count + " objects") -ForegroundColor Green
    return $flowMap
}

function Generate-MarkdownReport {
    param([hashtable]$FlowMap, [string]$OutputPath)
    Write-Host "Generating Markdown report..." -ForegroundColor Cyan
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $totalCount = $FlowMap.Keys.Count
    
    $lines = @()
    $lines += "# Analise de Fluxo C5/CONSINCO para MONITORPDVMIDDLE"
    $lines += ""
    $lines += ("**Gerado em:** " + $timestamp)
    $lines += ("**Total de Objetos:** " + $totalCount)
    $lines += ""
    $lines += "## Indice"
    $lines += ""
    
    $index = 1
    foreach ($key in $FlowMap.Keys | Sort-Object) {
        $obj = $FlowMap[$key]
        $lines += ("- " + $index + ". " + $obj.object_name + " (" + $obj.object_type + ")")
        $index++
    }
    
    $lines += ""
    $lines += "---"
    $lines += ""
    $lines += "## Fluxos Detalhados"
    $lines += ""
    
    $flowIndex = 1
    foreach ($key in $FlowMap.Keys | Sort-Object) {
        $obj = $FlowMap[$key]
        $lines += ("### " + $flowIndex + ". " + $obj.object_name + " (" + $obj.object_type + ")")
        $lines += ""
        $lines += ("**Owner:** " + $obj.owner)
        $lines += ""
        $lines += ("**Tipo:** " + $obj.object_type)
        $lines += ""
        
        if ($obj.sources.Count -gt 0) {
            $lines += "#### Fontes de Dados"
            $lines += ""
            $lines += "| Tabela | Owner |"
            $lines += "|--------|-------|"
            foreach ($src in $obj.sources | Sort-Object -Unique) {
                $lines += ("| " + $src + " | (detectado) |")
            }
            $lines += ""
        }
        
        if ($obj.dependencies.Count -gt 0) {
            $lines += "#### Dependencias"
            $lines += ""
            $lines += "| Nome | Tipo | Owner |"
            $lines += "|------|------|-------|"
            foreach ($dep in $obj.dependencies | Sort-Object -Property name) {
                if ($dep.name) {
                    $lines += ("| " + $dep.name + " | " + $dep.type + " | " + $dep.owner + " |")
                }
            }
            $lines += ""
        }
        
        if ($obj.destinations.Count -gt 0) {
            $lines += "#### Destinos (MONITORPDVMIDDLE)"
            $lines += ""
            $lines += "| Tabela |"
            $lines += "|--------|"
            foreach ($dest in $obj.destinations | Sort-Object -Unique) {
                $lines += ("| " + $dest + " |")
            }
            $lines += ""
        }
        
        $lines += "---"
        $lines += ""
        $flowIndex++
    }
    
    $lines -join "`n" | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host ("[OK] Report generated: " + $OutputPath) -ForegroundColor Green
}

function Main {
    try {
        $connString = Connect-Oracle -User $OracleUser -Password $OraclePassword -ServiceName $ServiceName
        
        $csvPath = ".\tools\analysis\flow-analysis-data.csv"
        $mdPath = ".\docs\superpowers\flows\fluxo-c5-consinco.md"
        
        if ($null -eq (Test-Path (Split-Path $csvPath))) {
            New-Item -ItemType Directory -Path (Split-Path $csvPath) -Force | Out-Null
        }
        if ($null -eq (Test-Path (Split-Path $mdPath))) {
            New-Item -ItemType Directory -Path (Split-Path $mdPath) -Force | Out-Null
        }
        
        $data = Extract-DependencyData -ConnectionString $connString -OutputCsvPath $csvPath
        $flow = Build-CascadingFlow -DependencyData $data
        Generate-MarkdownReport -FlowMap $flow -OutputPath $mdPath
        
        Write-Host ""
        Write-Host "[OK] Analysis complete!" -ForegroundColor Green
        Write-Host ("  - CSV Data: " + $csvPath) -ForegroundColor Green
        Write-Host ("  - Markdown Report: " + $mdPath) -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error: $_" -ForegroundColor Red
        exit 1
    }
}

Main
