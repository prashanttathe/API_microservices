pipeline {	
	environment {	
    		def APP_NAME = "petclinicapi"	
    		def GIT_REPO_NAME = "prashanttathe"	
    		def DEPLOY_ENV = "dev"	
	}	
    	agent any	
    	stages {	
		stage('Code Checkout') {	
			steps {	
				sh "if [ -d ${APP_NAME} ]; then rm -rf ${APP_NAME}; fi"	
				sh "git --branch prashant --single-branch clone https://github.com/${GIT_REPO_NAME}/${APP_NAME}.git"	
			}	
		}	
		stage('Azure Cloud Connect'){	
			steps {	
				sh "az login --identity"	
				sh "az account set --subscription aafef7b4-6886-45b4-afeb-2556fc54b425"	
				sh "az aks get-credentials --resource-group atos-tra-pla-rg --name atos-tra-pla-cluster"				
			}	
		}	
		stage('Build & Image'){	
			steps {	
				sh "cd ${APP_NAME} && gradle wrapper && ./gradlew build && az acr build -r tntaksreg -t ${APP_NAME} ."				
			}	
		}	
		stage('Deploy'){	
			steps {	
				sh "kubectl apply -f ${APP_NAME}/${DEPLOY_ENV}.yml --namespace=${DEPLOY_ENV}"			
			}	
		}	
    	}	
        post { 	
    		success { 	
    		    echo "Your application URL will be - http://${APP_NAME}.e46708b92c054086909b.eastus.aksapp.io"	
    		}	
    		failure { 	
    		    echo "Please check logs for more details."	
    		}	
    	}	
}
