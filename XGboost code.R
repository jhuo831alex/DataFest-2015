library(xgboost)

# create task
####### 
trainTask = makeClassifTask(data = dat_train, target = "buy")
testTask = makeClassifTask(data = dat_test,  target = "buy")

trainTask <- normalizeFeatures(trainTask,method = "standardize")
testTask <- normalizeFeatures(testTask,method = "standardize")

# convert to binary for classification
trainTask = createDummyFeatures(trainTask)
testTask = createDummyFeatures(testTask)

## create mlr learner
set.seed(1)
lrn = makeLearner("classif.xgboost",predict.type = "prob")

lrn$params <- list(
  objective           <- "binary:logistic",
  eta                 <- 0.2,
  max_depth           <- 5,
  nrounds             <- 100,
  print.every.n       <- 50
)

## parallel with parallelMap
parallelStartSocket(10)
parallelExport("auc")

# hyperparameter tuning
# 1) Define the set of parameters 
ps = makeParamSet(
  makeNumericParam("eta", lower = 0.05, upper = 0.3),
  makeIntegerParam("nrounds",lower=50,upper=800),
  makeIntegerParam("max_depth",lower=6,upper=12)
  # makeNumericParam("lambda",lower=0.55,upper=0.9),
  # makeNumericParam("gamma",lower=0,upper=1),
  # makeNumericParam("colsample_bytree", lower = 0.6,upper=0.90),
  # makeNumericParam("subsample", lower = 0.5, upper = 0.95),
  # makeNumericParam("max_delta_step",lower=1,upper=10)
)

# 2) 3-fold Cross-Validation to measure improvements
rdesc = makeResampleDesc("CV", iters = 3L)

# 3) Random Search
ctrl =  makeTuneControlRandom(budget = 100, maxit = 100)

# 4) tune
res = tuneParams(lrn, task = trainTask, resampling = rdesc, par.set = ps, control = ctrl,measures=list(mlr::auc))
res

# 5) set the optimal hyperparameter
lrn$params <- list(
  objective           <- "binary:logistic",
  eta                 <- 0.0608,
  max_depth           <- 9,
  nrounds             <- 376,
  print.every.n       <- 50
)
parallelStop()

dat_train = train_new_select
dat_test = test_new_select

dat_target = as.matrix(dat_train$buy)
Xtrain = as.matrix(dat_train[,-c(1,2)])
Xtest = as.matrix(dat_test[,-c(1,2)])

xgtrain <- xgb.DMatrix(data = Xtrain, label = dat_target, missing = NA)
xgtest <- xgb.DMatrix(data = Xtest,missing = NA)

####### xgboost
params <- list()
params$objective <- "binary:logistic"
params$eta <- 0.0608
params$max_depth <- 9
params$eval_metric <- "auc"

####buiding model
model_xgb <- xgb.train(params = params, xgtrain, nrounds = 376, nthread = 4)

####feature importance
vimp <- xgb.importance(model = model_xgb, feature_names = colnames(Xtrain))
head(vimp)
xgb.plot.importance(vimp)


#### Predict
pred <- predict(model_xgb, xgtest)
res_table = data.frame(ID = dat_test$visitor_key , Score=pred,true= dat_test$buy)
res_table$Pred[res_table$Score>=0.5] <-1
res_table$Pred[res_table$Score<0.5] <-0

#confusion matrix
table(res_table[,-c(1,2)])
(table(res_table[,-c(1,2)])[1]+table(res_table[,-c(1,2)])[4])/nrow(dat_test)
