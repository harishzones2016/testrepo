pipeline {
    environment {
        registry = "harishnarang2018/kopal"
        registryCredential = 'dockerhub'
        dockerImage = ''
    }
    agent any
    stages {
        stage('Building our image') {
            steps {
                script {
                    dockerImage = docker.build registry + "nginx:latest"
                }
            }
        }
        stage('Deploy our image') {
            steps {
                script {
                    docker.withRegistry( '', registryCredential ) {
                        dockerImage.push()
                    }
                }
            }
        }
stage ('RUN pod on cluster') {
                    steps {
      sh 'ssh -o StrictHostKeyChecking=no root@192.168.1.109 "kubectl create -f maa.yaml" '
      sh 'ssh -o StrictHostKeyChecking=no root@192.168.1.109 "kubectl create -f svc.yaml" '
}}

}
}
