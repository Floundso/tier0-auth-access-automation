@{
    Severity     = @('Error', 'Warning')

    IncludeRules = @(
        # Sicherheit - Pflicht
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingUsernameAndPasswordParams',

        # Best Practices
        'PSUseApprovedVerbs',
        'PSAvoidUsingCmdletAliases',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidGlobalVars',
        'PSUseShouldProcessForStateChangingFunctions',

        # Code Qualität
        'PSUseOutputTypeCorrectly',
        'PSAvoidUsingPositionalParameters',
        'PSUsePSCredentialType'
    )

    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )

    Rules        = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('7.0', '7.2')
        }

        PSAvoidUsingComputerNameHardcoded = @{
            Enable = $true
        }
    }
}
