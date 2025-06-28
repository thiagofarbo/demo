#!groovy
 import br.com.uol.ps.pipelineutils.TeamsAPI

 node("java21") {
     def javaHome = tool 'java21'
     env.PATH = "${javaHome}/bin:${env.PATH}"
     env.JAVA_HOME = "${javaHome}"
     jenkinslibs = library identifier: 'jenkinslibs@v4.0.2', retriever: modernSCM(
             [$class       : 'GitSCMSource',
              remote       : 'git@github.com:developer-productivity/jenkinslibs.git',
              credentialsId: 'svcacc_ps_jenkins_ssh'])

     def pipeline = jenkinslibs.br.com.uol.ps.actions.Pipeline.new()
     def utils = jenkinslibs.br.com.uol.ps.actions.Utils.new()
     def paramsObj = jenkinslibs.br.com.uol.ps.actions.Params.new()
     def paramsjl = readJSON text: paramsObj.json
     def security = jenkinslibs.br.com.uol.ps.actions.Security.new()
     def testOptions = ''
     def teamsAPI = new TeamsAPI(this)

      properties([
                  parameters([
                          booleanParam(name: 'DO_TEST', defaultValue: true, description: 'Precisa rodar testes integrados?'),
//                           choice(name: 'ENVIRONMENT', choices: ['qa', 'prod'], defaultValue: 'qa', description: 'Environment')
                  ])
          ])

//      paramsjl.header.environment = params.ENVIRONMENT
     paramsjl.deploy.cluster.pagcloud.k8s.namespace = "debt-collection-enrichment"
//      paramsjl.header.project.repository.name = "debt-collection-bifrost"
//      paramsjl.header.project.topdomain = "debtcollection"
//      paramsjl.header.project.group = "debtcollection-docker-${paramsjl.header.environment}".toString()
//      paramsjl.header.project.name = "debt-collection-bifrost"
//      paramsjl.header.project.port = "8095"
//      paramsjl.header.team = "Atenas"
//      paramsjl.header.project.language = "java"
//      paramsjl.build.type = "gradlew"
//      env.SPRING_PROFILES_ACTIVE = paramsjl.header.environment

     // ------------------------------- Resources -----------------------------------
     paramsjl.container.resources.requests.qa.memory = "800Mi"
     paramsjl.container.resources.limits.qa.memory = "1450Mi"
     paramsjl.container.resources.requests.qa.cpu = "150m"
     paramsjl.container.resources.limits.qa.cpu = "500m"

     paramsjl.container.resources.requests.prod.memory = "1000Mi"
     paramsjl.container.resources.limits.prod.memory = "1450Mi"
     paramsjl.container.resources.requests.prod.cpu = "150m"
     paramsjl.container.resources.limits.prod.cpu = "500m"

     // ---------------------------- Strategy Deploy --------------------------------
     paramsjl.deploy.cluster.pagcloud.k8s.rollout.strategy.canary.qa.isEnable = "true"
     paramsjl.deploy.cluster.pagcloud.k8s.rollout.strategy.canary.qa.steps = ["50", "100"]
     paramsjl.deploy.cluster.pagcloud.k8s.rollout.strategy.canary.qa.pauseDuration = "10"

     paramsjl.deploy.cluster.pagcloud.k8s.rollout.strategy.canary.prod.isEnable = "true"
     paramsjl.deploy.cluster.pagcloud.k8s.rollout.strategy.canary.prod.steps = ["50", "100"]
     paramsjl.deploy.cluster.pagcloud.k8s.rollout.strategy.canary.prod.pauseDuration = "10"

     // --------------------- HPA :: PROD -------------------------
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.prod.replicas.min = "1"
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.prod.replicas.max = "2"
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.prod.cpu.averageUtilization = "90"

     // --------------------- HPA :: QA -------------------------
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.qa.replicas.min = "1"
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.qa.replicas.max = "2"
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.qa.cpu.averageUtilization = "90"
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.qa.memory.isEnable = "true"
     paramsjl.deploy.cluster.pagcloud.k8s.hpa.qa.memory.averageValue = "990Mi"

     // ---------------------------- New IAM rotate feature --------------------------------
     paramsjl.security.vault.credential.aws.qa.iam_user = "ps-cobranca"
     paramsjl.security.vault.credential.aws.prod.iam_user = "ps-cobranca"

     // ------------------------------ Certificates ----------------------------------
     paramsjl.deploy.cluster.pagcloud.k8s.ingress.secret.name.prod = "debt-collection-bifrost.prod.intranet.pags"
     paramsjl.deploy.cluster.pagcloud.k8s.ingress.secret.name.qa =  "debt-collection-bifrost.qa.intranet.pags"

     // --------------------- Liveness & Readiness :: PROD -------------------------
     paramsjl.container.probes.prod.liveness.initialDelaySeconds = 30
     paramsjl.container.probes.prod.liveness.periodSeconds = 150
     paramsjl.container.probes.prod.readiness.initialDelaySeconds = 30
     paramsjl.container.probes.prod.readiness.periodSeconds = 150
     paramsjl.container.probes.prod.liveness.path = "/debt-collection-bifrost/actuator/health"
     paramsjl.container.probes.prod.readiness.path = "/debt-collection-bifrost/actuator/health"

     // ---------------------- Liveness & Readiness :: QA --------------------------
     paramsjl.container.probes.qa.liveness.initialDelaySeconds = 30
     paramsjl.container.probes.qa.liveness.periodSeconds = 150
     paramsjl.container.probes.qa.readiness.initialDelaySeconds = 30
     paramsjl.container.probes.qa.readiness.periodSeconds = 150
     paramsjl.container.probes.qa.liveness.path = "/debt-collection-bifrost/actuator/health"
     paramsjl.container.probes.qa.readiness.path = "/debt-collection-bifrost/actuator/health"

     // PagVault Integrations
     // ----------------------------- PagVault :: QA --------------------------------
     paramsjl.security.vault.credential.pagcloud.qa.getSecretValues = "false"
     paramsjl.security.vault.credential.pagcloud.qa.jenkins = "role-id-pagvault-debt-collection-bifrost-qa"
     paramsjl.security.vault.credential.pagcloud.qa.path = "debt/collection/enrichment/debt_collection_bifrost"
     paramsjl.security.vault.credential.pagcloud.qa.key = ["mongo", "keys"]

     // ---------------------------- PagVault :: PROD -------------------------------
     paramsjl.security.vault.credential.pagcloud.prod.getSecretValues = "false"
     paramsjl.security.vault.credential.pagcloud.prod.jenkins = "role-id-pagvault-debt-collection-bifrost-prod"
     paramsjl.security.vault.credential.pagcloud.prod.path = "debt/collection/enrichment/debt_collection_bifrost"
     paramsjl.security.vault.credential.pagcloud.prod.key = ["mongo", "keys"]

     if (DO_TEST == "false") {
         testOptions = "-x test"
     }

     paramsjl.test.options = testOptions
     paramsjl.build.options = testOptions

     paramsjl.deploy.opentelemetry.protocol = "grpc"
     paramsjl.deploy.opentelemetry.qa.url = "http://collector.pagmon.qa.intranet.pags:4317"
     paramsjl.deploy.opentelemetry.prod.url = "http://collector.pagmon.intranet.pags:4317"

     utils.SetEnvironment(paramsjl)

     // -------------------------- Enviroment variables -----------------------------
     if (paramsjl.header.environment == "prod") {
         paramsjl.deploy.cluster.pagcloud.k8s.configmap.data = [
             HTTP_PROXY: "http://proxy.intranet.pags:3128",
             HTTPS_PROXY: "http://proxy.intranet.pags:3128",
             ALL_PROXY: "socks5://proxy.intranet.pags:3128",
             NO_PROXY: "schema-registry.prd-aws.intranet.pagseguro.uol:8081,*.host.intranet,*.intranet.pagseguro.uol,*.pagseguro.intranet,*.pagseguro.srv.intranet,*.intranet.pags",
             JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=50 -Dfile.encoding=UTF-8 -Dotel.service.name=debt-collection-bifrost",
             SPRING_PROFILES_ACTIVE: paramsjl.header.environment,
             OTEL_SERVICE_NAME : "debt-collection-bifrost",
             OTEL_EXPORTER_OTLP_ENDPOINT : "http://collector.pagmon.intranet.pags:4317",
             OTEL_EXPORTER_OTLP_PROTOCOL : "grpc",
             OTEL_INSTRUMENTATION_MICROMETER_ENABLED: "false"
         ]
     } else {
         paramsjl.deploy.cluster.pagcloud.k8s.configmap.data = [
             HTTP_PROXY: "http://proxy-qa.intranet.pags:3128",
             HTTPS_PROXY: "http://proxy-qa.intranet.pags:3128",
             ALL_PROXY: "socks5://proxy-qa.intranet.pags:3128",
             NO_PROXY: "schema-registry.qa-aws.intranet.pagseguro.uol:8081,*.host.intranet,*.intranet.pagseguro.uol,*.pagseguro.intranet,*.pagseguro.srv.intranet,*.intranet.pags",
             JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=50 -Dfile.encoding=UTF-8 -Dotel.service.name=debt-collection-bifrost",
             SPRING_PROFILES_ACTIVE: paramsjl.header.environment,
             OTEL_SERVICE_NAME : "debt-collection-bifrost",
             OTEL_EXPORTER_OTLP_ENDPOINT : "http://collector.pagmon.qa.intranet.pags:4317",
             OTEL_EXPORTER_OTLP_PROTOCOL : "grpc",
             OTEL_INSTRUMENTATION_MICROMETER_ENABLED: "false"
         ]
     }

     try {
         deleteDir()

         def message = "${currentBuild.number}: (<${env.JOB_URL}|${env.JOB_NAME}>) - Start pipeline environment=${paramsjl.header.environment} branch=${paramsjl.header.branch.value}"
         teamsAPI.sendMessage([
                 'teams'       : 'cobranca',
                 'channel'     : 'Deployments',
                 'webhook_name': 'Jenkins',
                 'message'     : message
         ])

         stage(name: "checkout") {
             checkout scm
         }

         // Aprovação obrigatória para produção
         if (paramsjl.header.environment == "prod") {
             stage(name: "Aprovação para Produção") {
                 input message: 'Deseja prosseguir com o deploy em PRODUÇÃO?',
                       ok: 'Aprovar Deploy',
                       submitterParameter: 'APPROVER'

                 echo "Deploy em produção aprovado por: ${env.APPROVER}"

                 // Notificação de aprovação
                 def approvalMessage = "${currentBuild.number}: Deploy em PRODUÇÃO aprovado por ${env.APPROVER}"
                 teamsAPI.sendMessage([
                         'teams'       : 'cobranca',
                         'channel'     : 'Deployments',
                         'webhook_name': 'Jenkins',
                         'message'     : approvalMessage
                 ])
             }
         }

         pipeline.Start(paramsjl)

         message = "${currentBuild.number}: (<${env.JOB_URL}|${env.JOB_NAME}>) - End pipeline environment=${paramsjl.header.environment} branch=${paramsjl.header.branch.value}"
         teamsAPI.sendMessage([
                 'teams'       : 'cobranca',
                 'channel'     : 'Deployments',
                 'webhook_name': 'Jenkins',
                 'message'     : message
         ])

     } catch (Exception e) {
         throw e
     }
   }