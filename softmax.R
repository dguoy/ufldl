source('common.R')
inputSize <- 28 * 28
numClasses <- 10

lambda <- 1e-4

trainData <- loadImageFile('data/train-images-idx3-ubyte')
trainLabels <- loadLabelFile('data/train-labels-idx1-ubyte')

theta <- 0.005 * runif(numClasses * inputSize)

optimTheta <- optim(theta,
		function(theta) softmaxCost(theta, numClasses, inputSize, lambda, trainData, trainLabels),
		function(theta) softmaxGrad(theta, numClasses, inputSize, lambda, trainData, trainLabels),
		method = "L-BFGS-B", control = list(trace = 3, maxit = 500))$par

testData <- loadImageFile('data/t10k-images-idx3-ubyte')
testLabels <- loadLabelFile('data/t10k-labels-idx1-ubyte')
softmaxPredict(optimTheta, testData, testLabels)

#************************************************ Function *******************************************************
softmaxCost <- function(theta, numClasses, inputSize, lambda, data, labels) {
	theta <- matrix(theta, numClasses, inputSize)

	numCases <- ncol(data)

	groundTruth <- matrix(0, numClasses, numCases)
	for(i in 1:length(labels)) {
		groundTruth[labels[i], i] <- 1
	}

	M <- theta %*% data
	p <- apply(M, 2, function(x) {y <- x - max(x); return(exp(y) / sum(exp(y)))})
	cost <- -(1 / numCases) * sum(groundTruth * log(p)) + (lambda / 2) * sum(theta^2)
	return(cost)
}
softmaxGrad <- function(theta, numClasses, inputSize, lambda, data, labels) {
	theta <- matrix(theta, numClasses, inputSize)

	numCases <- ncol(data)

	groundTruth <- matrix(0, numClasses, numCases)
	for(i in 1:length(labels)) {
		groundTruth[labels[i], i] <- 1
	}

	M <- theta %*% data
	p <- apply(M, 2, function(x) {y <- x - max(x); return(exp(y) / sum(exp(y)))})
	thetagrad <- -(1 / numCases) * (groundTruth - p) %*% t(data) + lambda * theta
	return(as.vector(thetagrad))
}
softmaxPredict <- function(theta, data, labels) {
	numClasses <- length(table(labels))
	inputSize <- nrow(data)
	theta <- matrix(theta, numClasses, inputSize)
	predict <- apply(theta %*% data, 2, function(x) which.max(x))
	sum(predict == labels) / length(labels)
}

#************************************************ Object *******************************************************
Softmax <- R6Class("Softmax",
 private = list(
   numClasses=NA,
   inputSize=NA,
   lambda=NA,
   data=NA,
   labels=NA,
   numCases=NA,
   groundTruth=NA,
   M=NA,
   p=NA
 ),
 public = list(
   initialize = function(numClasses, inputSize, lambda, data, labels) {
     private$numClasses <- numClasses
     private$inputSize <- inputSize
     private$lambda <- lambda
     private$data <- data
     private$labels <- labels
   },
   cost = function(theta) {
     theta <- matrix(theta, private$numClasses, private$inputSize)
     
     private$numCases <- ncol(private$data)
     
     private$groundTruth <- matrix(0, private$numClasses, private$numCases)
     for(i in 1:length(private$labels)) {
       private$groundTruth[private$labels[i], i] <- 1
     }
     
     private$M <- theta %*% private$data
     private$p <- apply(private$M, 2, function(x) {y <- x - max(x); return(exp(y) / sum(exp(y)))})
     cost <- -(1 / private$numCases) * sum(private$groundTruth * log(private$p)) + (private$lambda / 2) * sum(theta^2)
     return(cost)
   },
   grad = function(theta) {
     thetagrad <- -(1 / private$numCases) * (private$groundTruth - private$p) %*% t(private$data) + private$lambda * theta
     return(as.vector(thetagrad))
   },
   predict = function(theta, data, labels) {
     numClasses <- length(table(labels))
     inputSize <- nrow(data)
     theta <- matrix(theta, numClasses, inputSize)
     predict <- apply(theta %*% data, 2, function(x) which.max(x))
     sum(predict == labels) / length(labels)
   }
 )
)
softmax <- Softmax$new(numClasses, inputSize, lambda, trainData, trainLabels)
optimTheta <- optim(theta, softmax$cost, softmax$grad, method = "L-BFGS-B", control = list(trace = 3, maxit = 500))$par
softmax$predict(optimTheta, testData, testLabels)
softmax$predict(optimTheta, trainData, trainLabels)
