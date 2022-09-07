node {
stage ('scm checkoutb'){

git branch: 'main', url: 'https://github.com/harishzones2016/testrepo.git'

}

stage ('docker build image') {
    sh 'docker build -t harishnarang2018/ubuntu:latest .'
}

stage ('docker push image') {
   sh 'docker login -u harishnarang2018 -p Negro@1234'
   sh 'docker push harishnarang2018/ubuntu:latest'
    }

}
