param location string = resourceGroup().location
param registryName string = 'devopslearningacr123'
param planName string = 'devops-learning-plan'
param webAppName string = 'my-first-devops-app'
param imageTag string = 'initial'
param pipelineObjectId string

var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPushRoleId = '8311e382-0749-4cb8-b61a-304f252e45ec'
var websiteContributorRoleId = 'de139f84-1756-47ae-9be6-808fbbe84772'

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry.properties.loginServer}/my-first-app:${imageTag}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '3000'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

resource webAppPullsImages 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, webApp.id, acrPullRoleId)
  scope: registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource pipelinePushesImages 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, pipelineObjectId, acrPushRoleId)
  scope: registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPushRoleId)
    principalId: pipelineObjectId
    principalType: 'ServicePrincipal'
  }
}

resource pipelineUpdatesWebApp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(webApp.id, pipelineObjectId, websiteContributorRoleId)
  scope: webApp
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', websiteContributorRoleId)
    principalId: pipelineObjectId
    principalType: 'ServicePrincipal'
  }
}

output loginServer string = registry.properties.loginServer
output webAppPrincipalId string = webApp.identity.principalId
