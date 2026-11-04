
pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOYMENT_MODE',
            choices: ['FULL', 'PORTFOLIO', 'JAVA', 'INFRASTRUCTURE'],
            description: 'Select which application component to deploy'
        )

        string(name: 'TF_VAR_aws_region', defaultValue: 'us-east-1')
        string(name: 'TF_VAR_project_name', defaultValue: 'capstone-project')
        string(name: 'TF_VAR_vpc_cidr', defaultValue: '10.1.0.0/16')
        string(name: 'TF_VAR_public_subnet_cidr', defaultValue: '10.1.16.0/20')
        string(name: 'TF_VAR_availability_zone', defaultValue: 'us-east-1a')
        string(name: 'TF_VAR_ami_id', defaultValue: 'ami-08c46876c64a927b8')
        string(name: 'TF_VAR_instance_type', defaultValue: 'm7i-flex.large')
        string(name: 'TF_VAR_admin_cidr', defaultValue: '')
        string(name: 'TF_VAR_key_name', defaultValue: 'm_key')
    }

    environment {
        DEPLOY_HOST = '98.89.67.243'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Toolchain') {
            steps {
                sh '''
                    git --version
                    java -version
                    mvn -version
                    ansible-playbook --version
                    terraform version
                '''
            }
        }

        stage('Terraform Validate') {
            when {
                expression {
                    params.DEPLOYMENT_MODE == 'INFRASTRUCTURE'
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-terraform-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir('terraform') {
                        sh '''
                            set +x
                            set -eu

                            terraform fmt -check -recursive
                            terraform init -backend=false
                            terraform validate
                        '''
                    }
                }
            }
        }

        stage('Terraform Backend Init') {
            when {
                expression {
                    params.DEPLOYMENT_MODE == 'INFRASTRUCTURE'
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-terraform-credentials',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    dir('terraform') {
                        sh '''
                            set +x
                            set -eu
                            terraform init -input=false -reconfigure
                        '''
                    }
                }
            }
        }


           stage('Terraform Plan, Approval and Apply') {
              when {
                  expression {
                      params.DEPLOYMENT_MODE == 'INFRASTRUCTURE'
                }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-terraform-credentials',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        ),
                        sshUserPrivateKey(
                            credentialsId: 'ec2-deploy-key',
                            keyFileVariable: 'SSH_KEY'
                           )
                        ]) {
                           dir('terraform') {
                               sh '''
                                    set +x
                                    set -eu

                                : "${TF_VAR_admin_cidr:?Enter your administrator CIDR when starting the build}"

                                terraform plan \
                                    -input=false \
                                    -lock-timeout=5m \
                                    -var="ssh_private_key_path=$SSH_KEY" \
                                    -out=tfplan

                                terraform show -no-color tfplan
                            '''

                            input(
                                message: 'Review the Terraform plan. Approve only if the proposed changes are expected.',
                                ok: 'Approve Terraform Apply'
                            )

                            sh '''
                                set +x
                                set -eu

                                terraform apply \
                                    -input=false \
                                    -lock-timeout=5m \
                                    tfplan
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Java Application') {
            when {
                expression {
                    params.DEPLOYMENT_MODE == 'JAVA' ||
                    params.DEPLOYMENT_MODE == 'FULL'
                }
            }
            steps {
                sh 'mvn -f java/pom.xml clean package'
            }
        }

        stage('Deploy to EC2') {
            when {
                expression {
                    params.DEPLOYMENT_MODE != 'INFRASTRUCTURE'
                }
            }
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'ec2-deploy-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        set -eu

                        INVENTORY=$(mktemp)
                        trap 'rm -f "$INVENTORY"' EXIT
                        chmod 600 "$INVENTORY"

                        cat > "$INVENTORY" <<EOF
[app]
${DEPLOY_HOST} ansible_user=${SSH_USER} ansible_ssh_private_key_file=${SSH_KEY} ansible_python_interpreter=/usr/bin/python3
EOF

                        ANSIBLE_HOST_KEY_CHECKING=True \
                            ansible-playbook \
                            -i "$INVENTORY" \
                            -e "deployment_mode=${DEPLOYMENT_MODE}" \
                            ansible/playbook.yml
                    '''
                }
            }
        }

        stage('HTTP Smoke Tests') {
            when {
                expression {
                    params.DEPLOYMENT_MODE != 'INFRASTRUCTURE'
                }
            }
            steps {
                sh '''
                    set -eu

                    if [ "$DEPLOYMENT_MODE" = "PORTFOLIO" ] || [ "$DEPLOYMENT_MODE" = "FULL" ]; then
                        curl --fail --silent --show-error --max-time 15 \
                            "http://${DEPLOY_HOST}/" > /dev/null

                        curl --fail --silent --show-error --max-time 15 \
                            "http://${DEPLOY_HOST}/avatars/avatar.png" > /dev/null
                    fi

                    if [ "$DEPLOYMENT_MODE" = "JAVA" ] || [ "$DEPLOYMENT_MODE" = "FULL" ]; then
                        curl --fail --silent --show-error --max-time 15 \
                            "http://${DEPLOY_HOST}/yearbook/" > /dev/null
                    fi

                    echo "HTTP smoke tests passed for ${DEPLOYMENT_MODE} deployment."
                '''
            }
        }
    }

    post {
        always {
            sh '''
                set +x
                rm -f "$WORKSPACE/terraform/tfplan"
            '''
        }
    }
}
