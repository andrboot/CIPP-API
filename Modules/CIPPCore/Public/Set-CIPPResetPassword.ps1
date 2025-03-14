function Set-CIPPResetPassword {
    [CmdletBinding()]
    param(
        $userid,
        $tenantFilter,
        $APIName = 'Reset Password',
        $Headers,
        [bool]$forceChangePasswordNextSignIn = $true
    )

    try {
        $password = New-passwordString
        $passwordProfile = @{
            'passwordProfile' = @{
                'forceChangePasswordNextSignIn' = $forceChangePasswordNextSignIn
                'password'                      = $password
            }
        } | ConvertTo-Json -Compress

        $UserDetails = New-GraphGetRequest -uri "https://graph.microsoft.com/v1.0/users/$($UserId)?`$select=onPremisesSyncEnabled" -noPagination $true -tenantid $TenantFilter -verbose
        $null = New-GraphPostRequest -uri "https://graph.microsoft.com/v1.0/users/$($userid)" -tenantid $TenantFilter -type PATCH -body $passwordProfile -verbose

        #PWPush
        $PasswordLink = New-PwPushLink -Payload $password
        if ($PasswordLink) {
            $password = $PasswordLink
        }
        Write-LogMessage -headers $Headers -API $APIName -message "Reset the password for $($userid). User must change password is set to $forceChangePasswordNextSignIn" -Sev 'Info' -tenant $TenantFilter

        if ($UserDetails.onPremisesSyncEnabled -eq $true) {
            return [pscustomobject]@{ resultText = "Reset the password for $($userid). User must change password is set to $forceChangePasswordNextSignIn. The new password is $password. WARNING: This user is AD synced. Please confirm passthrough or writeback is enabled."
                copyField                        = $password
                state                            = 'warning'
            }
        } else {
            return [pscustomobject]@{ resultText = "Reset the password for $($userid). User must change password is set to $forceChangePasswordNextSignIn. The new password is $password"
                copyField                        = $password
                state                            = 'success'
            }
        }
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -headers $Headers -API $APIName -message "Could not reset password for $($userid). Error: $($ErrorMessage.NormalizedError)" -Sev 'Error' -tenant $TenantFilter -LogData $ErrorMessage
        return [pscustomobject]@{
            resultText = "Could not reset password for $($userid). Error: $($ErrorMessage.NormalizedError)"
            state      = 'Error'
        }
    }
}
