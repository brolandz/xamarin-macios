<#
VSTS interaction unit tests.
#>

Import-Module ./VSTS -Force

Describe 'Stop-Pipeline' {
    Context 'default' {
        It 'sets the correct variables' {
            Mock Write-Host

            Stop-Pipeline

            Assert-MockCalled -CommandName Write-Host -Times 1 -Scope It -ParameterFilter { $Object -eq "##vso[task.setvariable variable=agent.jobstatus;]canceled" }
            Assert-MockCalled -CommandName Write-Host -Times 1 -Scope It -ParameterFilter { $Object -eq "##vso[task.complete result=Canceled;]DONE" }
        }
    }
}

Describe 'Test-JobSuccess' {
    Context 'seuccesfull' {
        Test-JobSuccess -Status "Succeeded" | Should -Be $True
    }

    Context 'known failures' {
        Test-JobSuccess -Status "Canceled" | Should -Be $False
        Test-JobSuccess -Status "Failed" | Should -Be $False
        Test-JobSuccess -Status "SucceededWithIssues" | Should -Be $False
    }

    Context 'unknonw value' {
        Test-JobSuccess -Status "Random value" | Should -Be $False
    }
}