
#####################
# homework3 104971001
# Rscript hw3_yourID.R --target male/female --files meth1 meth2 … methx --out result.csv
# Code should able to read in multiple files.(~10 files)
# Find out which method contains the max.
# method,sensitivity,specificity,F1,AUC
# test for significance
#####################
pkgTest <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x,dep=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
}

pkgTest("ROCR")

getAUC <- function(scores, refs)
{
  return(attributes(performance(prediction(scores, refs), "auc"))$y.values[[1]])
}
# getAUC <- function(refer, scores)
# {
#   print(refer)
#   print(scores)
#   rocObj <- roc(refer, scores, direction = "<")
#   print(rocObj)
#   result = auc(rocObj)
#   return(result)
# }




# read parameters
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("USAGE: Rscript hw3_yourID.R --target male/female --files meth1 meth2 … methx --out result.csv", call.=FALSE)
}

# parse parameters
i<-1 
while(i < length(args))
{
  if(args[i] == "--target"){
    target<-args[i+1]
    i<-i+1
  }else if(args[i] == "--files"){
    j<-grep("-", c(args[(i+1):length(args)], "-"))[1]
    files<-args[(i+1):(i+j-1)]
    i<-i+j-1
  }else if(args[i] == "--out"){
    out_f<-args[i+1]
    i<-i+1
  }else{
    stop(paste("Unknown flag", args[i]), call.=FALSE)
  }
  i<-i+1
}

print(paste("target:", target))
print(paste("output file:", out_f))
print(paste("files:", files))

# initial vector
fname <- c()
sens <- c()
spes <- c()
f1s <- c()
aucs <- c()

# read files, calculate TP, TN, FP, FN
for(file in files)
{
  tp = 0
  tn = 0
  fp = 0
  fn = 0
  name<-gsub(".csv", "", basename(file))
  fname <- c(fname, name)
  d<-read.table(file, header=T,sep=",")
  for(i in 1:dim(d)[1])
  {
    if(target == d[i,2]){
      if(d[i,2] == d[i,3]){
        tp <- tp+1
      }else{
        fp <- fp+1
      }
    }else{
      if(d[i,2] == d[i,3]){
        tn <- tn+1
      }else{
        fn <- fn+1
      }
    }
    i <- i+1
  }
  # print(tp)
  # print(fp)
  # print(tn)
  # print(fn)
  sensitivity = round(tp/(tp+fn), 2)
  specificity = round(tn/(tn+fp), 2)
  f1 = round(((2*tp)/(2*tp + fp + fn)), 2)
  
  if(target == 'male'){
    auc <- round(getAUC(d$pred.score, ifelse(d[,"reference"] == "male",1,0)), 2)
  }else{
    auc <- round(getAUC(1-d$pred.score, ifelse(d[,"reference"] == "female",1,0)), 2)
  }
  
  sens <- c(sens, sensitivity)
  spes <- c(spes, specificity)
  f1s <- c(f1s, f1)
  aucs <- c(aucs, auc)
}


# create dataframe, find max item, and write to file
df <- data.frame(method=fname, sensitivity=sens, specificity=spes, F1=f1s, 
                 AUC=aucs, stringsAsFactors=FALSE)

# find the 2nd highest for F1
n <- length(files)
index1 <- order(df$F1, decreasing = T)[1]
index2 <- order(df$F1, decreasing = T)[2]
print(index2)

# build contingency matrix
data1 <- read.csv(files[index1], header=T, sep=",")
data2 <- read.csv(files[index2], header=T, sep=",")
contable <- table(data1$prediction, data2$prediction)
print("contingency table:")
print(contable)

# test for significance
pvalue <- fisher.test(contable)$p.value

index <- sapply(df[,c("sensitivity","specificity","F1","AUC")], which.max)
df <- rbind(df, c("highest", fname[index]))
if(pvalue < 0.05){
  df[length(files)+1,"F1"] <- paste(df[length(files)+1,"F1"], "*", sep="")
}
print(df)
write.table(df, file=out_f, row.names=F, quote=F, sep=",")






