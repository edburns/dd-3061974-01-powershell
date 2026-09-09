Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ImplementationPath = Join-Path $PSScriptRoot 'math-tool.ps1'
    . $script:ImplementationPath
}

Describe 'Get-Fibonacci' {
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

    It 'rejects negative input without writing a Fibonacci result line' {
        $stdoutPath = Join-Path $TestDrive 'stdout.txt'
        $stderrPath = Join-Path $TestDrive 'stderr.txt'

        $process = Start-Process -FilePath 'pwsh' -ArgumentList @(
            '-NoLogo'
            '-NoProfile'
            '-File'
            $script:ImplementationPath
            '-N'
            '-1'
        ) -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

        $stdoutLines = @(Get-Content -LiteralPath $stdoutPath)

        $process.ExitCode | Should -Not -Be 0
        ($stdoutLines -join [Environment]::NewLine) | Should -Not -Match '^Fibonacci\(-1\) = '
    }
}
