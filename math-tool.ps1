[CmdletBinding()]
param(
    [ValidateRange(0, [int]::MaxValue)]
    [int] $N
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Fibonacci {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $N
    )

    if ($N -eq 0) {
        return [System.Numerics.BigInteger]::Zero
    }

    $previous = [System.Numerics.BigInteger]::Zero
    $current = [System.Numerics.BigInteger]::One

    for ($i = 2; $i -le $N; $i++) {
        $next = $previous + $current
        $previous = $current
        $current = $next
    }

    return $current
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $PSBoundParameters.ContainsKey('N')) {
        throw 'N is required.'
    }

    $value = Get-Fibonacci -N $N
    "Fibonacci($N) = $value"
}
