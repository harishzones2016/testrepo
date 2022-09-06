pipeline {
    agent any
    stages {


         stage('CHECKOUT') {
            steps {
              git url: 'https://github.com/harishzones2016/testrepo.git', branch :'main'
            }
        }


           stage('kubernetescheck') {
            steps {
            sh 'kubectl get nodes -o wide'                        }

        }
            stage('test') {
            steps {
             sh ' kubectl create -f nginxser.yaml '
            }
}

          stage('get pods') {
            steps {
                sh ' kubectl get pods -o wide  '
            }

    }
}
}
