#Connect to Azure
Connect-AzureAD
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome
#Get the current users, this can be user or group
#$users = get-azureaduser | where-object UserPrincipalName -like "<user>@<tenant>.onmicrosoft.com"
$users = get-azureadgroup -SearchString "PIM-RG-Owners" | get-azureadgroupmember
$subscriptions = get-azsubscription

#Get role assignments from PIM, and remove it if it exists
foreach ($user in $users) {
    $PrincipalToQueryTransitiveMemberOf = Get-MgUserTransitiveMemberOf -All -UserId $user.ObjectId

    $output = foreach ($subscription in $subscriptions) {
    $EligibleRBACRolesUnfiltered = Get-AzRoleEligibilityScheduleInstance -Scope "/subscriptions/$($subscription.Id)"
    $EligibleRBACRoles = $EligibleRBACRolesUnfiltered | Where-Object {($_.PrincipalId -eq $PrincipalToQuery) -or ($_.PrincipalId -in $PrincipalToQueryTransitiveMemberOf.Id)}
    $EligibleRBACRoles
    }

    if ((Get-AzRoleAssignment -ObjectId $user.ObjectId -Scope $output.ScopeId) -ne $null)
        {
       
        Remove-AzRoleAssignment -scope $output.ScopeId -ObjectId $user.ObjectId -RoleDefinitionName $output.RoleDefinitionDisplayName
        }
  }
    