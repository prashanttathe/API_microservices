pipeline {
    agent any
    stages {
        stage('reference-pipeline') {
            steps {
	       sh "rm -rf sample-app"
	       sh "git clone https://github.com/mrganeshkudale/sample-app.git"
	       sh "az login --identity"
               sh "az acr build -r tntaksreg -t myngnix ."
               sh "az account set --subscription aafef7b4-6886-45b4-afeb-2556fc54b425"
               sh "az aks get-credentials --resource-group atos-tra-pla-rg --name atos-tra-pla-cluster"
               sh "kubectl apply -f development.yml"
            }
        }
    }
}
