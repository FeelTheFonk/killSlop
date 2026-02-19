@{
    # PSAvoidUsingWriteHost            - intentional: killSlop is an interactive CLI tool; Write-Host is required for colored output.
    # PSAvoidUsingPositionalParameters - intentional: used deliberately for conciseness in tightly scoped scripts.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPositionalParameters'
    )
}
