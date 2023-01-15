@description('Webapplicaiton location detials')
param webapp1location string = resourceGroup().location

@description('webapplication secondary location detials')
param webapp2location string= 'NorthEurope'
@description('app serviceplan details')
param appserviceplan1 string='appserviceplan-we01'
param appserviceplan2 string='appserviceplan-ne01'

@description('app service details')
param appservicename1 string ='SAFWebpp-We01'
param appservicename2 string='SAFWebapp-Ne01'

@description('The name of the Front Door endpoint to create. This must be globally unique.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'
var frontDoorProfileName = 'SAFfrontdoor-01'
var frontDoorOriginGroupName = 'SAFOrgingroup'
var frontDoorOriginName1 = 'SAFOrigin-Ne01'
var frontDoorOriginName2 = 'SAFOrigin-We01'
var frontDoorRouteName = 'Webapproute'

@description('SqlSerevr Name')
param sqlservername string ='Samplesqlserver'

@description('sql server database name')
param sqldatabasename string='mydatabse'

@description('Admin username')
param sqlserveradminname string = 'TestUser'
@description('sql admin passwordname')
@secure()
param sqlserveradminpassword string

resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}
resource appServicePlan1 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appserviceplan1
  location: webapp1location
  sku: {
    name: 'F1'
    capacity: 1
  }
}
resource appServicePlan2 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appserviceplan2
  location: webapp2location
  sku: {
    name: 'F1'
    capacity: 1
  }
}
resource webApplication1 'Microsoft.Web/sites@2021-01-15' = {
  name: appservicename1
  location: webapp1location
  kind: 'app'
  tags: {
    tag1: 'webapp'
  }
  properties: {
    serverFarmId:appServicePlan1.id
    siteConfig: {
      detailedErrorLoggingEnabled:true
      httpLoggingEnabled:true
      requestTracingEnabled:true
      minTlsVersion:'1.2'
      ipSecurityRestrictions:[
         {
           tag:'ServiceTag'
           ipAddress:'AzurefrontDoor.Backend'
           action:'Allow'
           priority:100
           name:'Allow traffic from front door'

         }] 
    }
  }
  dependsOn:[
     appServicePlan2
  ]
}

resource webApplication2 'Microsoft.Web/sites@2021-01-15' = {
  name: appservicename2
  location: webapp2location
  kind: 'app'
  tags: {
    tag1: 'webapp'
  }
  properties: {
    serverFarmId:appServicePlan1.id
    siteConfig: {
      detailedErrorLoggingEnabled:true
      httpLoggingEnabled:true
      requestTracingEnabled:true
      minTlsVersion:'1.2'
      ipSecurityRestrictions:[
         {
           tag:'ServiceTag'
           ipAddress:'AzurefrontDoor.Backend'
           action:'Allow'
           priority:100
           name:'Allow traffic from front door'

         }


      ]
    }

  }
  dependsOn: [
    appServicePlan2
  ]
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  location: 'global'
  parent: frontDoorProfile
  properties: {
    enabledState: 'Enabled'
  }
}
resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}
resource frontDoorOrigin1 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginName1
  parent: frontDoorOriginGroup
  properties: {
    hostName: webApplication1.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: webApplication1.properties.defaultHostName
    priority: 1
    weight: 1000
  }
}

resource frontDoorOrigin2 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginName2
  parent: frontDoorOriginGroup
  properties: {
    hostName: webApplication2.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: webApplication2.properties.defaultHostName
    priority: 2
    weight: 1000
  }
}
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin1
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
}

resource sqlServer 'Microsoft.Sql/servers@2014-04-01' ={
  name: sqlservername
  location: webapp1location
  properties:{
 administratorLogin: sqlserveradminname
 administratorLoginPassword:sqlserveradminpassword
 version:'12.0'
  }
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2014-04-01' = {
  parent: sqlServer
  name: sqldatabasename
  location: webapp1location
  properties: {
    collation: 'collation'
    edition: 'Basic'
    maxSizeBytes: 'maxSizeBytes'
    requestedServiceObjectiveName: 'Basic'

  }
}
