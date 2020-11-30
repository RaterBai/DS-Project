
library(readxl)
library(tidyverse)
library(broom)
library(readr)
library(lme4)
library(ggplot2)
library(dplyr)
library(glmnet)
library(caret)
library(ROCit)

set.seed(2020)

# Set working directory
setwd("C:/Users/fabia/OneDrive/Documentos/GitHub/DS-Project/prepared datasets")

train <- read.csv("train.csv")
test <- read.csv("test.csv")

train <- train[, -1]
test <- test[, -1]


#predictor matrix
x <- model.matrix(diabetes~.,train)[, -376]

#outcome variable 
y <- train$diabetes

#model <- glmnet(x, y, alpha = 1, family = "binomial", lambda = 0.1)
#Cross-validation (lambda)
#cv.model <- cv.glmnet(x, y, alpha = 1, family = "binomial")
fraction_0 <- rep(1 - sum(y == 0) / length(y), sum(y == 0))
fraction_1 <- rep(1 - sum(y == 1) / length(y), sum(y == 1))
# assign that value to a "weights" vector
weights <- numeric(length(y))

weights[y == 0] <- fraction_0
weights[y == 1] <- fraction_1

cv.model <- cv.glmnet(x,y, alpha =1, type.measure="auc", nfolds=5, weights=weights, family="binomial")
  


#Cross-validation plot of lambda
plot(cv.model)

cv.model$lambda.min # 0.03643724 This is the lambda (penalization parameter) that minimizes the prediction error

#Final Model Lasso ----
lasso.model <- glmnet(x, y, alpha = 1, family = "binomial", lambda = cv.model$lambda.min, weights=weights)

#Make prediction on the test data
x.test <- model.matrix(diabetes~.,test)[, -376]
probabilities <- lasso.model %>%  
                      predict(newx = x.test)

predicted.classes <- ifelse(probabilities >0.5, 1, 0)

table(predicted.classes)

#Metrics ----


#Model accuracy 
observed.classes <- test$diabetes
mean(predicted.classes == observed.classes)

results<- cbind(predicted.classes, observed.classes)
tp <- sum(predicted.classes==1 & observed.classes==1)
tn <- sum(predicted.classes==0 & observed.classes==0)
fp <- sum(predicted.classes==1 & observed.classes==0)
fn <- sum(predicted.classes==0 & observed.classes==1)

# Precision = TP / (TP+FP)
precision <- tp/(tp+fp) #90%

# Recall / Sensitivity = TP / (TP + FN) -- how well ML classifies positive cases
recall <- tp/(tp+fn) #24.80%

# Specificity = TN / (TN+FP) -- how well ML classifies negative cases
specificity <- tn/(tn+fp) #86%

#F1 score = 2*Precision*Recall / (Precision+Recall)
f1 <- 2*precision*recall/(precision+recall) #38.89%

#AUC value
cv.model$cvm[which(cv.model$lambda == cv.model$lambda.min)]

#Confusion Matrix
confusionMatrix(factor(predicted.classes), factor(observed.classes), positive ="1", dnn = c("Prediction", "Observed"))
#AUC and ROC plot
library("ROCR")    
pred <- prediction(probabilities, observed.classes)  
perf <- performance(pred, measure = "tpr", x.measure = "fpr")     
plot(perf, col=rainbow(7), main="ROC Curve (with feature selection) ", xlab="False Positive Rate", 
     ylab="True Positive Rate")   
abline(0, 1) #add a 45 degree line

auc = performance(pred, "auc")
auc@y.values #0.6357

#Full Model ----
full.model <- glm(formula = diabetes ~., family = "binomial", data=train, weights=weights)

#Make prediction on the test data
probabilities <- full.model %>%  
            predict(test, type="response")

predicted.classes <- ifelse(probabilities >0.5, 1, 0)

table(predicted.classes)
#Model accuracy or Success rate
observed.classes <- test$diabetes
mean(predicted.classes == observed.classes) #66% 
#Metrics ----

#Model accuracy 66%
observed.classes <- test$diabetes
mean(predicted.classes == observed.classes)

results<- cbind(predicted.classes, observed.classes)
tp <- sum(predicted.classes==1 & observed.classes==1)
tn <- sum(predicted.classes==0 & observed.classes==0)
fp <- sum(predicted.classes==1 & observed.classes==0)
fn <- sum(predicted.classes==0 & observed.classes==1)

# Precision = TP / (TP+FP)
precision <- tp/(tp+fp) #0.8544601

# Recall / Sensitivity = TP / (TP + FN) -- how well ML classifies positive cases
recall <- tp/(tp+fn) #0.7165

# Specificity = TN / (TN+FP) -- how well ML classifies negative cases
specificity <- tn/(tn+fp) #38%

#F1 score = 2*Precision*Recall / (Precision+Recall)
f1 <- 2*precision*recall/(precision+recall) # 0.7794

#Confusion Matrix
confusionMatrix(factor(predicted.classes), factor(observed.classes), positive ="1", dnn = c("Prediction", "Observed"))

#AUC and ROC plot
library("ROCR")    
pred <- prediction(probabilities, observed.classes)  
perf <- performance(pred, measure = "tpr", x.measure = "fpr")     
plot(perf, col=rainbow(7), main="ROC Curve (without feature selection) ", xlab="False Positive Rate", 
     ylab="True Positive Rate")    
abline(0, 1) #add a 45 degree line

auc = performance(pred, "auc")
auc@y.values #0.5482

