[CmdletBinding()]
param(
    [ValidateSet('fibonacci', 'factorial')]
    [string] $Operation = 'fibonacci',

    [ValidateRange(0, [int]::MaxValue)]
    [int] $N
)

function Get-Fibonacci {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $N
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

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

function Get-Factorial {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $N
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $result = [System.Numerics.BigInteger]::One
    for ($i = 2; $i -le $N; $i++) {
        $result *= $i
    }

    return $result
}

if ($MyInvocation.InvocationName -ne '.') {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not $PSBoundParameters.ContainsKey('N')) {
        throw 'N is required.'
    }

    switch ($Operation) {
        'fibonacci' {
            $value = Get-Fibonacci -N $N
            "Fibonacci($N) = $value"
        }
        'factorial' {
            $value = Get-Factorial -N $N
            "Factorial($N) = $value"
        }
        default {
            throw "Unsupported operation '$Operation'."
        }
    }
}
