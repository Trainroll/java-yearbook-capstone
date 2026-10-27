
pipeline {
    agent any

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
                '''
            }
        }

        stage('Build Java Application') {
            steps {
                sh 'mvn -f java/pom.xml clean package'
            }
        }
    }
}
