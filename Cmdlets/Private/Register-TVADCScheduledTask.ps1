function Register-TVADCScheduledTask {
    [CmdletBinding()]

    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]

    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        $Action,

        [Parameter(Mandatory = $true)]
        $Trigger,

        [Parameter(Mandatory = $true)]
        $Principal
    )

    # Registers via a plain-parameter wrapper because Register-ScheduledTask's Action/Trigger/Principal are CDXML dynamic parameters that Pester cannot mock directly.
    return Register-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal
}
