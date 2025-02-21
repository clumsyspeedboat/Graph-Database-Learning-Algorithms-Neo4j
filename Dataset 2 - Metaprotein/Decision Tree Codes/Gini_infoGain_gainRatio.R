###################
## Meta protein ### ---> DATA ANALYSIS + DECISION TREE ALGORITHMS
###################

# Cleaning the work space #

cat("\f")       # Clear old outputs
rm(list=ls())   # Clear all variables

if(!require("factoextra")) install.packages("factoextra") # PCA
if(!require("caret")) install.packages("caret") 
if(!require("FSelector")) install.packages("FSelector")   # Information Gain & Gain Ratio
if(!require("DescTools")) install.packages("DescTools")   # Gini Index
if(!require("rpart")) install.packages("rpart")           # Decision Tree : CART (gini)
if(!require("rpart.plot")) install.packages("rpart.plot") # Decision Tree plot : CART
if(!require("C50")) install.packages("C50")               # Decision Tree : C 5.0 (gain ratio)
if(!require("RWeka")) install.packages("RWeka")           # Decision Tree : C 4.5 (gain ratio)

library("factoextra")
library("caret")
library("FSelector")
library("DescTools")
library("rpart")
library("rpart.plot")
library("C50")
library("RWeka")

# Creating a data matrix #
data1 <- file.choose()
data_matrix <- read.csv(data1, header = TRUE, sep = ",")

# Transforming variables
data_matrix[,1:50] <- as.numeric(unlist(data_matrix[,1:50])) 
data_matrix[,51] <- as.factor(data_matrix[,51])


####################
## Pre Processing ##
####################

## Removing unnecessary rows ##

data_matrix <- data_matrix[1:2969,]


## To set metaprotein names as row names/identifier ##

# rownames(data_matrix) <- data_matrix[,1]


## Taking a subset of the data by choosing a certain Class or Species ##

# data_matrix_m <- data_matrix[data_matrix$Class == "Mammalia",]
# data_matrix_hs <- data_matrix[data_matrix$Species == "Homo sapiens",]


## Performing row sums : Do not perform this step if the decision tree codes below are to be implemented; ##
## otherwise make necessary changes ##

# Control_Patients <- as.numeric(rowSums(data_matrix[,c(13:33)]))
# CD_Patients <- as.numeric(rowSums(data_matrix[,c(34:46)]))
# UC_Patients <- as.numeric(rowSums(data_matrix[,c(37:60)]))
# data_matrix_patients <- as.data.frame(cbind(data_matrix, Control_Patients, CD_Patients, UC_Patients))
 

## Removing unnecessary columns and taking just the numeric columns of patient data ##

data_matrix <- data_matrix[,13:60]


## Transpose the matrix to set instances as rows and variables as columns ##

data_matrix_new <- t(data_matrix)
data_matrix_new <- as.data.frame(data_matrix_new)


##  Generating a class label - Control. CD & UC Patients labeled accordingly ##

Patient.Type <- matrix("C",)
data_matrix_new <- cbind(data_matrix_new, Patient.Type) 

for (i in 21:33) {
  
  data_matrix_new[i,2970] <- "CD"
  
}

for (i in 34:48) {
  
  data_matrix_new[i,2970] <- "UC"
  
}


###########################
## Unsupervised Learning ##
###########################

## Principal Component Analysis (Numeric Variables) ##

pca1 <- prcomp(data_matrix_new[,1:2969], scale = FALSE, center = FALSE)

fviz_pca_biplot(pca1, repel = F,
                col.var = "black", # Variables color
                addEllipses = T  # add ellipse around individuals
)


## Hierarchical Clustering ##

h_clust <- eclust(data_matrix_new[,1:2969], "hclust", 3 , hc_metric = "manhattan", hc_method = "ward.D", graph = TRUE)

fviz_dend(h_clust, show_labels = TRUE, palette = "jco", as.ggplot= TRUE)


## DBSCAN ##

dbscan <- fpc::dbscan(data_matrix_new[,1:2969], eps = 2000, MinPts =3)  
fviz_cluster(dbscan, data_matrix_new[,1:2969], stand = FALSE, ellipse = TRUE, geom = "point")


## Entropy, Information Gain & Gain Ratio of variables ##

ig_entropy <- information.gain(Patient.Type~., data_matrix_new, unit = "log2")
colnames(ig_entropy) <- "Information Gain"

gr_entropy <- gain.ratio(Patient.Type~., data_matrix_new, unit = "log2")
colnames(gr_entropy) <- "Gain Ratio"


## Gini Index of variables ##

gini_ind <- as.data.frame(lapply(data_matrix_new, Gini))
gini_ind <- as.data.frame(t(gini_ind))
colnames(gini_ind) <- "Gini Index"


###################
## Decision Tree ##
###################

###########################################
# CART # --> Gini Index
########

accuracy = vector("numeric")
time = vector("numeric")
mcc = vector("numeric")
cf = matrix("numeric")

for (i in 1:30) {
  
  options(digits.secs = 6)
  start.time1 <- Sys.time()
  train.control <- trainControl(method = 'cv', number = 10)
  tree1 <- train(Patient_Type ~. ,data = data_matrix, method = "rpart", trControl = train.control, parms=list(split="gini"))
  end.time1 <- Sys.time()
  
  Prediction1 <- confusionMatrix(tree1)
  
  print(Prediction1)
  
  cf <- as.data.frame(as.table(Prediction1$table))
  
  a = sum(cf[1,3],cf[2,3],cf[3,3])
  b = sum(cf[4,3],cf[5,3],cf[6,3])
  c = sum(cf[7,3],cf[8,3],cf[9,3])
  d = sum(cf[1,3],cf[4,3],cf[7,3])
  e = sum(cf[2,3],cf[5,3],cf[8,3])
  f = sum(cf[3,3],cf[6,3],cf[9,3])
  diagonal = sum(cf[1,3],cf[5,3],cf[9,3])
  total = sum(cf$Freq)
  
  corrPred = diagonal/total
  accuracy[i] = corrPred*100
  
  mccNum <- (diagonal*total)-(c*f)-(b*e)-(a*d)
  mccDen <- sqrt(total**2 - a**2 -b**2 -c**2) * sqrt(total**2 - d**2 - e**2 - f**2)

  numMcc <- mccNum/mccDen
  mcc[i] = numMcc
  
  time_taken1 <- end.time1 -start.time1
  time_taken1
  time[i] <- time_taken1
  
}

mean(accuracy)
mean(mcc)
mean(time)

###########################################

###########################################
# ID3 # --> Information Gain
########

accuracy = vector("numeric")
time = vector("numeric")
mcc = vector("numeric")
cf = matrix("numeric")

for (i in 1:30) {
  
  options(digits.secs = 6)
  start.time1 <- Sys.time()
  train.control <- trainControl(method = 'cv', number = 10)
  tree1 <- train(Patient_Type ~. ,data = data_matrix, method = "rpart", trControl = train.control, parms=list(split="information"))
  end.time1 <- Sys.time()
  
  Prediction1 <- confusionMatrix(tree1)
  
  print(Prediction1)
  
  cf <- as.data.frame(as.table(Prediction1$table))
  
  a = sum(cf[1,3],cf[2,3],cf[3,3])
  b = sum(cf[4,3],cf[5,3],cf[6,3])
  c = sum(cf[7,3],cf[8,3],cf[9,3])
  d = sum(cf[1,3],cf[4,3],cf[7,3])
  e = sum(cf[2,3],cf[5,3],cf[8,3])
  f = sum(cf[3,3],cf[6,3],cf[9,3])
  diagonal = sum(cf[1,3],cf[5,3],cf[9,3])
  total = sum(cf$Freq)
  
  corrPred = diagonal/total
  accuracy[i] = corrPred*100
  
  mccNum <- (diagonal*total)-(c*f)-(b*e)-(a*d)
  mccDen <- sqrt(total**2 - a**2 -b**2 -c**2) * sqrt(total**2 - d**2 - e**2 - f**2)
  
  numMcc <- mccNum/mccDen
  mcc[i] = numMcc
  
  time_taken1 <- end.time1 -start.time1
  time_taken1
  time[i] <- time_taken1
  
}

mean(accuracy)
mean(mcc)
mean(time)

###########################################


###########################################
# C4.5 # --> Gain Ratio
########

accuracy = vector("numeric")
time = vector("numeric")
mcc = vector("numeric")
cf = matrix("numeric")

for (i in 1:30) {
  
  options(digits.secs = 6)
  start.time1 <- Sys.time()
  tree1 <- J48(Patient_Type~., data = data_matrix)
  end.time1 <- Sys.time()
  
  Predictions1 <- evaluate_Weka_classifier(tree1, numFolds = 10, class = TRUE)
  cf <- as.data.frame(as.table(Prediction1$confusionMatrix))
  
  a = sum(cf[1,3],cf[2,3],cf[3,3])
  b = sum(cf[4,3],cf[5,3],cf[6,3])
  c = sum(cf[7,3],cf[8,3],cf[9,3])
  d = sum(cf[1,3],cf[4,3],cf[7,3])
  e = sum(cf[2,3],cf[5,3],cf[8,3])
  f = sum(cf[3,3],cf[6,3],cf[9,3])
  diagonal = sum(cf[1,3],cf[5,3],cf[9,3])
  total = sum(cf$Freq)
  
  corrPred = diagonal/total
  accuracy[i] = corrPred*100
  
  mccNum <- (diagonal*total)-(c*f)-(b*e)-(a*d)
  mccDen <- sqrt(total**2 - a**2 -b**2 -c**2) * sqrt(total**2 - d**2 - e**2 - f**2)
  
  numMcc <- mccNum/mccDen
  mcc[i] = numMcc
  
  time_taken1 <- end.time1 -start.time1
  time_taken1
  time[i] <- time_taken1
  
}

mean(accuracy)
mean(mcc)
mean(time)

###########################################
######################################################################################