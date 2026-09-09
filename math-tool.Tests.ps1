Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ImplementationPath = Join-Path $PSScriptRoot 'math-tool.ps1'
    . $script:ImplementationPath
}

Describe 'Get-Fibonacci' {
    It 'does not change caller strict mode or error preference when dot-sourced' {
        $callerState = & {
            Set-StrictMode -Off
            $ErrorActionPreference = 'Continue'

            . $script:ImplementationPath

            $uninitializedVariableThrows = $false
            try {
                $null = $uninitializedVariable
            } catch {
                $uninitializedVariableThrows = $true
            }

            [pscustomobject]@{
                ErrorActionPreference = $ErrorActionPreference
                UninitializedVariableThrows = $uninitializedVariableThrows
            }
        }

        $callerState.ErrorActionPreference | Should -Be 'Continue'
        $callerState.UninitializedVariableThrows | Should -BeFalse
    }

    It 'returns only the numeric Fibonacci value for N=<N>' -TestCases @(
        @{ N = 0; Expected = 0 }
        @{ N = 1; Expected = 1 }
        @{ N = 5; Expected = 5 }
    ) {
        param($N, $Expected)

        $result = @(Get-Fibonacci -N $N)

        $result.Count | Should -Be 1
        $result[0] | Should -Be $Expected
        $result[0] | Should -Not -BeOfType [string]
    }
}

Describe 'Get-Factorial' {
    It 'returns only the numeric factorial value for N=<N>' -TestCases @(
        @{ N = 0; Expected = 1 }
        @{ N = 1; Expected = 1 }
        @{ N = 5; Expected = 120 }
    ) {
        param($N, $Expected)

        $result = @(Get-Factorial -N $N)

        $result.Count | Should -Be 1
        $result[0] | Should -Be $Expected
        $result[0] | Should -Not -BeOfType [string]
    }
}

Describe 'math-tool CLI' {
    It 'writes exactly one Fibonacci result line for N=<N>' -TestCases @(
        @{ N = 0; Expected = 'Fibonacci(0) = 0' }
        @{ N = 1; Expected = 'Fibonacci(1) = 1' }
        @{ N = 5; Expected = 'Fibonacci(5) = 5' }
    ) {
        param($N, $Expected)

        $stdoutPath = Join-Path $TestDrive 'stdout.txt'
        $stderrPath = Join-Path $TestDrive 'stderr.txt'

        $process = Start-Process -FilePath 'pwsh' -ArgumentList @(
            '-NoLogo'
            '-NoProfile'
            '-File'
            $script:ImplementationPath
            '-N'
            [string] $N
        ) -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

        $stdoutLines = @(Get-Content -LiteralPath $stdoutPath)
        $stderr = if ((Get-Item -LiteralPath $stderrPath).Length -eq 0) {
            ''
        } else {
            Get-Content -LiteralPath $stderrPath -Raw
        }

        $process.ExitCode | Should -Be 0
        $stdoutLines.Count | Should -Be 1
        $stdoutLines[0] | Should -Be $Expected
        $stderr | Should -Be ''
    }

    It 'writes exactly one Fibonacci result line when explicitly selected' {
        $stdoutPath = Join-Path $TestDrive 'stdout.txt'
        $stderrPath = Join-Path $TestDrive 'stderr.txt'

        $process = Start-Process -FilePath 'pwsh' -ArgumentList @(
            '-NoLogo'
            '-NoProfile'
            '-File'
            $script:ImplementationPath
            '-Operation'
            'fibonacci'
            '-N'
            '5'
        ) -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

        $stdoutLines = @(Get-Content -LiteralPath $stdoutPath)
        $stderr = if ((Get-Item -LiteralPath $stderrPath).Length -eq 0) {
            ''
        } else {
            Get-Content -LiteralPath $stderrPath -Raw
        }

        $process.ExitCode | Should -Be 0
        $stdoutLines.Count | Should -Be 1
        $stdoutLines[0] | Should -Be 'Fibonacci(5) = 5'
        $stderr | Should -Be ''
    }

    It 'writes exactly one Factorial result line for N=<N>' -TestCases @(
        @{ N = 0; Expected = 'Factorial(0) = 1' }
        @{ N = 1; Expected = 'Factorial(1) = 1' }
        @{ N = 5; Expected = 'Factorial(5) = 120' }
    ) {
        param($N, $Expected)

        $stdoutPath = Join-Path $TestDrive 'stdout.txt'
        $stderrPath = Join-Path $TestDrive 'stderr.txt'

        $process = Start-Process -FilePath 'pwsh' -ArgumentList @(
            '-NoLogo'
            '-NoProfile'
            '-File'
            $script:ImplementationPath
            '-Operation'
            'factorial'
            '-N'
            [string] $N
        ) -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

        $stdoutLines = @(Get-Content -LiteralPath $stdoutPath)
        $stderr = if ((Get-Item -LiteralPath $stderrPath).Length -eq 0) {
            ''
        } else {
            Get-Content -LiteralPath $stderrPath -Raw
        }

        $process.ExitCode | Should -Be 0
        $stdoutLines.Count | Should -Be 1
        $stdoutLines[0] | Should -Be $Expected
        $stderr | Should -Be ''
    }

    It 'rejects negative input without writing a result line for <Operation>' -TestCases @(
        @{ Operation = $null }
        @{ Operation = 'factorial' }
    ) {
        param($Operation)

        $stdoutPath = Join-Path $TestDrive 'stdout.txt'
        $stderrPath = Join-Path $TestDrive 'stderr.txt'

        $arguments = @(
            '-NoLogo'
            '-NoProfile'
            '-File'
            $script:ImplementationPath
        )
        if ($null -ne $Operation) {
            $arguments += @(
                '-Operation'
                $Operation
            )
        }
        $arguments += @(
            '-N'
            '-1'
        )

        $process = Start-Process -FilePath 'pwsh' -ArgumentList $arguments -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

        $stdoutLines = @(Get-Content -LiteralPath $stdoutPath)
        $stdout = $stdoutLines -join [Environment]::NewLine

        $process.ExitCode | Should -Not -Be 0
        $stdout | Should -Not -Match '(?m)^Fibonacci\(-1\) = '
        $stdout | Should -Not -Match '(?m)^Factorial\(-1\) = '
    }

    It 'rejects unsupported operations without writing a result line' {
        $stdoutPath = Join-Path $TestDrive 'stdout.txt'
        $stderrPath = Join-Path $TestDrive 'stderr.txt'

        $process = Start-Process -FilePath 'pwsh' -ArgumentList @(
            '-NoLogo'
            '-NoProfile'
            '-File'
            $script:ImplementationPath
            '-Operation'
            'sum'
            '-N'
            '5'
        ) -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

        $stdoutLines = @(Get-Content -LiteralPath $stdoutPath)
        $stdout = $stdoutLines -join [Environment]::NewLine

        $process.ExitCode | Should -Not -Be 0
        $stdout | Should -Not -Match '(?m)^Fibonacci\(5\) = '
        $stdout | Should -Not -Match '(?m)^Factorial\(5\) = '
    }
}
