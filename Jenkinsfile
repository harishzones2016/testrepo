node {
stage ('scm checkoutb'){

git branch: 'main', url: 'https://github.com/harishzones2016/testrepo.git'

}

stage ('docker build image') {
    sh 'docker build -t harishnarang2018/kopal:latest .'
}

stage('Push Docker Image'){
     withCredentials([string(credentialsId: 'docker-pwd', variable: 'dockerHubPwd')]) {
        sh "docker login -u harishnarang2018 -p ${dockerHubPwd}"
     }
     sh 'docker push harishnarang2018/kopal:latest'
   }

stage ('run container on dev') {
sh 'ssh -o StrictHostKeyChecking=no root@192.168.1.233 "sudo docker run -p 8080:80 -d --name harish harishnarang2018/kopal:latest" '
}
}
