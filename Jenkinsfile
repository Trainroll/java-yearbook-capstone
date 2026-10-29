
pipeline {
    agent any

parameters {
    choice(
        name: 'DEPLOYMENT_MODE',
        choices: ['FULL', 'PORTFOLIO', 'JAVA'],
        description: 'Select which application component to deploy'
    )
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
                '''
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
            steps {
                sh '''
                    set -eu

                    if [ "$DEPLOYMENT_MODE" = "PORTFOLIO" ] || [ "$DEPLOYMENT_MODE" = "FULL" ]; then
                        echo "Testing portfolio homepage..."
                        curl --fail --silent --show-error --max-time 15 \
                            "http://${DEPLOY_HOST}/" > /dev/null
                        echo "Testing portfolio avatar..."
                        curl --fail --silent --show-error --max-time 15 \
                            "http://${DEPLOY_HOST}/avatars/avatar.png" > /dev/null
                    fi

                    if [ "$DEPLOYMENT_MODE" = "JAVA" ] || [ "$DEPLOYMENT_MODE" = "FULL" ]; then
                        echo "Testing Java application through Nginx..."
                        curl --fail --silent --show-error --max-time 15 \
                            "http://${DEPLOY_HOST}/yearbook/" > /dev/null
                    fi

                    echo "HTTP smoke tests passed for ${DEPLOYMENT_MODE} deployment."
                '''
       }
     }
   }
}
