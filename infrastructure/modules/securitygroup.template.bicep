// extension microsoftGraph

// @description('The display name for the security group')
// param groupName string

// @description('Security group members (optional)')
// param members array = []


//Currently only Azure CLI and Azure PowerShell are supported for interactive deployments using a signed-in user.

// resource securityGroup 'Microsoft.Graph/groups@v1.0' = {
//   displayName: groupName
//   mailEnabled: false
//   securityEnabled: true
//   members: members
//   mailNickname: groupName
//   uniqueName: groupName
// }
