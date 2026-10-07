// =============================================================================
// Jenkinsfile — mirrors the real pipeline already running in GitHub Actions
// (.github/workflows/{terraform-ci,security-scan,policy-gate,trivy-sbom,
// python-tests,powershell-tests,ansible-lint}.yml), for an enterprise
// environment that standardizes on Jenkins instead of (or alongside) GitHub
// Actions. Not a parallel CI system actually wired to any webhook/trigger in
// this repo — GitHub Actions remains the CI that actually runs on every PR
// (see each workflow file). This Jenkinsfile is validated with
// `jenkins-plugin-cli`/online Jenkins syntax where noted below, but has not
// been run against a live Jenkins controller (no Jenkins instance in this
// portfolio lab — same no-new-infra-cost posture as the rest of the repo).
//
// Stage-for-stage mapping to the GitHub Actions workflows, so the two never
// drift silently out of sync:
//   Lint & Validate   <- terraform-ci.yml (fmt/validate/tflint), ansible-lint.yml
//   Security Scan     <- security-scan.yml (Checkov) + trivy-sbom.yml (Trivy/SBOM)
//   Policy Gate       <- policy-gate.yml (OPA/conftest + Kyverno fixtures)
//   Test (Python)     <- python-tests.yml (pytest, automation/tests + tests/python)
//   Test (PowerShell) <- powershell-tests.yml (Pester)
//   Build Image       <- (new) builds+tags the automation-controller image;
//                        never pushes to a registry (see README "o que não
//                        foi feito") — no registry credentials configured.
//
// `terraform apply` and `docker push` are deliberately absent from every
// stage below, same as every GitHub Actions workflow in this repo.
// =============================================================================

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        PYTHONDONTWRITEBYTECODE = '1'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint & Validate') {
            parallel {
                stage('Terraform fmt + validate') {
                    steps {
                        sh '''
                            set -eu
                            terraform fmt -check -recursive terraform/
                            for env in dev staging prod; do
                                (cd "terraform/environments/$env" && terraform init -backend=false -input=false && terraform validate)
                            done
                        '''
                    }
                }
                stage('TFLint') {
                    steps {
                        sh '''
                            set -eu
                            for env in dev staging prod; do
                                (cd "terraform/environments/$env" && tflint --init --config="$WORKSPACE/.tflint.hcl" && tflint --config="$WORKSPACE/.tflint.hcl" --recursive)
                            done
                        '''
                    }
                }
                stage('Ansible lint') {
                    steps {
                        sh 'ansible-lint ansible/ || true' // soft-fail, mirrors ansible-lint.yml's non-blocking posture for this scope
                    }
                }
            }
        }

        stage('Security Scan') {
            parallel {
                stage('Checkov (Terraform)') {
                    steps {
                        sh 'checkov --directory terraform/ --config-file .checkov.yaml --compact'
                    }
                }
                stage('Trivy (fs + image)') {
                    steps {
                        sh 'bash security/trivy-scan.sh'
                    }
                }
            }
        }

        stage('Policy Gate') {
            parallel {
                stage('OPA / conftest') {
                    steps {
                        sh 'bash tests/terraform/test-opa-policies.sh'
                    }
                }
                stage('Kyverno') {
                    steps {
                        sh 'bash tests/terraform/test-kyverno-policies.sh'
                    }
                }
            }
        }

        stage('Test') {
            parallel {
                stage('Python (pytest)') {
                    steps {
                        sh '''
                            set -eu
                            python -m pip install --upgrade pip
                            pip install -r requirements.txt -r requirements-dev.txt
                            pytest automation/tests tests/python -v --cov
                        '''
                    }
                }
                stage('PowerShell (Pester)') {
                    steps {
                        pwsh '''
                            Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
                            Invoke-Pester -Path powershell/tests -CI
                        '''
                    }
                }
            }
        }

        stage('Build Image') {
            steps {
                sh 'docker build -t automation-controller:${BUILD_NUMBER} -f Dockerfile .'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'security/sbom/**', allowEmptyArchive: true
        }
    }
}
