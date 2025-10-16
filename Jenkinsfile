/*
 * ✅ Performance Testing Pipeline – Session 5 Adaptado
 * 
 * Cambios principales:
 * 🟦 1. El test usa una API externa (https://httpbin.org).
 * 🟦 2. Se agregan propiedades (-Jthreads, -Jrampup, -Jduration, -Jbase_url)
 * 🟦 3. Se invoca el script check-thresholds.sh para validar P95/ErrorRate.
 */

pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  environment {
    OUT_DIR = 'out'
    REPORTS_DIR = 'reports'
    JMETER_IMAGE = 'jmeter-prom:latest'
    JMETER_CONTAINER_NAME = 'jmeter-run'
    BRANCH_NAME = 'main'

    // 🟦 Configuración de la API externa httpbin.org
    BASE_URL = 'https://httpbin.org'
    THREADS = '10'
    RAMPUP = '30'
    DURATION = '60'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        echo "Starting Performance Testing Pipeline for ${env.BRANCH_NAME}"
      }
    }

    stage('Build JMeter Image') {
      steps {
        sh "docker build -t ${JMETER_IMAGE} ./jmeter"
      }
    }

    // 🟦 Eliminamos “Wait for AUT” porque no hay aplicación local que levantar

    stage('Run Performance Tests') {
      steps {
        sh """
          echo "=== Starting JMeter Performance Tests (Session 5 API Mode) ==="
          rm -rf ${OUT_DIR}
          mkdir -p ${OUT_DIR}
          docker rm -f ${JMETER_CONTAINER_NAME} >/dev/null 2>&1 || true

          docker run -d \
            --name ${JMETER_CONTAINER_NAME} \
            --memory=3g --shm-size=512m \
            ${JMETER_IMAGE} sleep 600

          docker exec ${JMETER_CONTAINER_NAME} mkdir -p /work/jmeter /work/out
          docker cp jmeter/. ${JMETER_CONTAINER_NAME}:/work/jmeter/

          # 🟦 Ejecuta JMeter usando propiedades pasadas por -J (configuración basada en propiedades)
          echo "=== Running JMeter test plan with properties ==="
          timeout 300 docker exec ${JMETER_CONTAINER_NAME} jmeter -n \
            -t /work/jmeter/test-plan.jmx \
            -l /work/out/results.jtl \
            -e -o /work/out/jmeter-report \
            -Jthreads=${THREADS} \
            -Jrampup=${RAMPUP} \
            -Jduration=${DURATION} \
            -Jbase_url=${BASE_URL} \
            -Jjmeter.save.saveservice.output_format=csv \
            -Jjmeter.save.saveservice.response_data=false \
            -Jjmeter.save.saveservice.samplerData=false \
            -Jjmeter.save.saveservice.responseHeaders=false
          
          docker cp ${JMETER_CONTAINER_NAME}:/work/out/. ${OUT_DIR}/
          docker stop ${JMETER_CONTAINER_NAME} >/dev/null 2>&1 || true
          docker rm ${JMETER_CONTAINER_NAME} >/dev/null 2>&1 || true

          ls -la ${OUT_DIR}/
        """
      }
    }

    // 🟦 Nueva etapa de validación automática de umbrales
    stage('Validate Thresholds (SLA/SLO)') {
      steps {
        sh """
          echo "=== Validando SLA/SLO globales (P95 < 500ms, Error < 1%) ==="
          chmod +x ./jmeter/check-thresholds.sh
          bash ./jmeter/check-thresholds.sh ${OUT_DIR}/results.jtl
        """
      }
    }

    stage('Generate Performance Reports') {
      steps {
        sh """
          echo "=== Generating HTML Reports ==="
          mkdir -p ${REPORTS_DIR}/generated

          if [ -f "${OUT_DIR}/results.jtl" ]; then
            TOTAL=\$(tail -n +2 ${OUT_DIR}/results.jtl | wc -l)
            AVG=\$(awk -F',' 'NR>1{sum+=\$2; c++} END{if(c>0) print int(sum/c); else print 0}' ${OUT_DIR}/results.jtl)
            MAX=\$(awk -F',' 'NR>1{if(\$2>m) m=\$2} END{print int(m)}' ${OUT_DIR}/results.jtl)
            echo "<html><body><h2>Performance Summary</h2><p>Total: \$TOTAL | Avg: \$AVG ms | Max: \$MAX ms</p></body></html>" > ${REPORTS_DIR}/generated/summary.html
          fi
        """
      }
    }

    stage('Archive Results') {
      steps {
        script {
          if (fileExists("${OUT_DIR}/results.jtl")) {
            archiveArtifacts artifacts: "${OUT_DIR}/**", fingerprint: true
          }
          if (fileExists("${REPORTS_DIR}/generated")) {
            publishHTML([
              allowMissing: false,
              alwaysLinkToLastBuild: true,
              keepAll: true,
              reportDir: "${REPORTS_DIR}/generated",
              reportFiles: 'summary.html',
              reportName: 'Performance Summary'
            ])
          }
        }
      }
    }
  }

  post {
    always {
      echo "=== Pipeline complete ==="
      echo "Reports available under Jenkins > HTML Reports"
    }
    success {
      echo "✅ Performance testing PASSED (Session 5)"
    }
    failure {
      echo "❌ Performance testing FAILED - SLA/SLO not met"
    }
  }
}
