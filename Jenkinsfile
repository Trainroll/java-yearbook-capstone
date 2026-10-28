
pipeline {
    agent any

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
                            ansible/playbook.yml
                    '''
                }
            }
        }

        stage('HTTP Smoke Tests') {
            steps {
                sh '''
                    set -eu

                    curl --fail --silent --show-error --max-time 15 \
                        "http://${DEPLOY_HOST}/" > /dev/null

                    curl --fail --silent --show-error --max-time 15 \
                        "http://${DEPLOY_HOST}/yearbook/" > /dev/null

                    curl --fail --silent --show-error --max-time 15 \
                        "http://${DEPLOY_HOST}/avatars/avatar.png" > /dev/null

                    echo "All HTTP smoke tests passed."
                '''
            }
        }
    }
}

