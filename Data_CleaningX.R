library(data.table)
library(dplyr)
library(readr)
library(rvest)
shopping <- data.table::fread("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/shopping.csv")
config<-data.table::fread("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/configuration.csv")
leads<-data.table::fread("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/leads.csv")
trans<-data.table::fread("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/transactions.csv")
visitor <- read_csv("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/visitor.csv")
options(scipen=999)

####create response variable####
trans$buy<-1
y<-merge(leads[,"visitor_key"],trans[,c("visitor_key","buy")],by="visitor_key",all.x = T)
y<-unique(y)
y[is.na(y)]<-0

####Create New Variable####
#Feature 1: count of contact info per visitor key
count<-as.data.frame(table(leads$visitor_key))
names(count)[1]<-"visitor_key"
count$visitor_key<-as.numeric(as.character(count$visitor_key))
y<-merge(y,count,by="visitor_key")
names(y)[3]<-"contactinfo_n"

#Feature 2: count of different dates viewed per visitor ke
count2<-as.data.frame(table(shopping$visitor_key))
names(count2)[1]<-"visitor_key"
count2$visitor_key<-as.numeric(as.character(count2$visitor_key))
y<-merge(y,count2,by="visitor_key",all.x=T)
names(y)[4]<-"shoppingdate_n"

#Feature 3: Count of different cars viewed per visitor key
shopping$shoppingcar<-paste0(shopping$make_name," ",shopping$model_name)
result5<-shopping %>% group_by(visitor_key) %>% summarise(count=length(unique(shoppingcar)))
y<-merge(y,result5,by="visitor_key",all.x = T)
names(y)[5]<-"diffcar_n"

#Feature 4: Count of bought car viewed per visitor key
trans$boughtcar<-paste0(trans$make_bought," ",trans$model_bought)
shopping<-merge(shopping,trans[,c("visitor_key","boughtcar")],by="visitor_key",all.x=T)
shopping$shoppingcar<-paste0(shopping$make_name," ",shopping$model_name)
newshop<-shopping[-which(is.na(shopping$boughtcar)),]
newshop<-newshop[-which(newshop$shoppingcar=="-1 -1"),]

result = NULL
for(i in unique(newshop$visitor_key)){
  #i = unique(newshop$visitor_key)[1]
  count = 0
  a = subset(newshop,newshop$visitor_key == i)
  for(j in 1:nrow(a)){
    if(a$boughtcar[j] == a$shoppingcar[j]) count = count+1
  }
  result = rbind(result, data.frame(visitor_key = i, count = count))
}

y<-merge(y,result,by="visitor_key",all.x = T)
names(y)[5]<-"bcarview_n"

#Feature 5: Count of bought make viewed per visitor key
shopping<-merge(shopping,trans[,c("visitor_key","make_bought")],by="visitor_key",all.x=T)
newshop2<-shopping[-which(is.na(shopping$make_bought)),]
newshop2<-newshop2[-which(newshop2$make_name=="-1"),]

result2 = NULL
for(i in unique(newshop2$visitor_key)){
  #i = unique(newshop$visitor_key)[1]
  count = 0
  a = subset(newshop2,newshop2$visitor_key == i)
  for(j in 1:nrow(a)){
    if(a$make_name[j] == a$make_bought[j]) count = count+1
  }
  result2 = rbind(result2, data.frame(visitor_key = i, count = count))
}
y<-merge(y,result2,by="visitor_key",all.x = T)
names(y)[6]<-"bmakeview_n"

#Feature 6: Maximum webpage viewed count per day per visitor key
result3<-config %>% group_by(visitor_key,f_date) %>% summarise(count=n())
result4<-result3 %>% group_by(visitor_key) %>% summarise(max=max(count))
y<-merge(y,result4,by="visitor_key",all.x=T)
names(y)[7]<-"singleday_maxn"

#Feature 7: Year difference between current year and model year
leads$leads_year<-as.numeric(substring(leads$lead_date,0,4))
leads$year_diff<-leads$leads_year-leads$model_year

#Feature 8: Distinguish Important and less important features
leads<-as.data.frame(leads)
for(i in 5:15){
  n=which(leads[,i]==""| leads[,i] =="none")
  leads[n,i]<-NA
  leads[-n,i]<-1
}

n1=which(is.na(leads$model_year))
leads[-n1,"model_year"]<-1
for(i in 5:15){
  leads[,i]<-as.numeric(leads[,i])
}
leads$impinfo_n<-rowSums(leads[,4:7],na.rm = T)
leads$lessinfo_n<-rowSums(leads[,8:15],na.rm = T)

#Feature 9: Binary features: old/new/cpo
leads$new<-0
leads$new[leads$new_used=="N"]<-1
leads$old<-0
leads$old[leads$new_used=="U"]<-1
leads$cpo<-0
leads$cpo[leads$new_used=="C"]<-1

#Feature 10: Binary: Price promise flag:Y/N
leads$ppfY<-0
leads$ppfY[leads$price_promise_flag=="Y"]<-1
leads$ppfN<-0
leads$ppfN[leads$price_promise_flag=="N"]<-1

#Feature 11: Binary: Ranking of US vehicles per capita (external data)
mainpage<-read_html("https://en.wikipedia.org/wiki/List_of_U.S._states_by_vehicles_per_capita")
ranking <- mainpage %>% html_nodes("td") %>% html_text()
ranking<-ranking[1:153]
ranking_table<-NULL
for(i in 1:51){
  temp = data.frame(rank=ranking[3*i-2],state= ranking[3*i-1],n = ranking[3*i])
  ranking_table = rbind(ranking_table,temp)
}

statepage<-read_html("https://www.50states.com/abbreviations.htm")
state <- statepage %>% html_nodes("td") %>% html_text()
state_table<-NULL
for(i in 1:65){
  temp = data.frame(state=state[2*i-1],abb= state[2*i])
  state_table = rbind(state_table,temp)
}

ranking_table<-merge(ranking_table,state_table,by="state")

top50<-as.character(ranking_table$abb[c(1:10)])
top40<-as.character(ranking_table$abb[c(11:20)])
top30<-as.character(ranking_table$abb[c(21:30)])
top20<-as.character(ranking_table$abb[c(31:40)])
top10<-as.character(ranking_table$abb[c(41:50)])

#Feature 12: Month of leads
leads$leads_month<-substring(leads$lead_date,6,7)

####Merge data####
y<-merge(y,leads[,c("visitor_key","dealer_distance","model_year","make","model","style","year_diff","leads_month","impinfo_n",
                    "lessinfo_n","new","old","cpo","ppfY","ppfN","top10","top20","top30","top40","top50")],by="visitor_key")
save(y,file = "~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/y5.rdata")

##########################################
######## Visitor Data Cleaning ###########
##########################################
# Feature binary
fea_binary <- read_excel("visitor_binary_fea.xlsx",col_names = F)
fea_binary <- t(fea_binary[,1])

visitor_binary <- visitor[,c("visitor_key",fea_binary)]

for(i in 2:ncol(visitor_binary)){
  n = which(visitor_binary[,i] > 0)
  visitor_binary[,i] = 0
  visitor_binary[n,i] <- 1
}

# Feature unchange
fea_unchange <- read_excel("visitor_unchang_fea.xlsx",col_names = F)
fea_unchange <- t(fea_unchange[,1])

visitor_unchange <- visitor[,c("visitor_key",fea_unchange)]

# Feature Quantile
fea_quantile <- read_excel("dat1_fea.xlsx",col_names = F)
fea_quantile <- t(fea_quantile[,1])
visitor_quantile <- visitor[,c("visitor_key",fea_quantile)]

unique(visitor_quantile$credit_worthiness)
visitor_quantile$credit_VeryGood <- 0
visitor_quantile$credit_VeryGood[visitor_quantile$credit_worthiness == "Very Good"] <- 1
visitor_quantile$credit_Excellent <- 0
visitor_quantile$credit_Excellent[visitor_quantile$credit_worthiness == "Excellent"] <- 1
visitor_quantile$credit_Good <- 0
visitor_quantile$credit_Good[visitor_quantile$credit_worthiness == "Good"] <- 1
visitor_quantile$credit_Fair <- 0
visitor_quantile$credit_Fair[visitor_quantile$credit_worthiness == "Fair"] <- 1
visitor_quantile$credit_Poor <- 0
visitor_quantile$credit_Poor[visitor_quantile$credit_worthiness == "Poor"] <- 1

unique(visitor_quantile$age_range)
# "66-70" "71-75" "36-40" "76+"   "41-45" "61-65" "46-50" "56-60" "51-55" "31-35"
# "21-25" "26-30" "18-20"
visitor_quantile$age6670 <- 0
visitor_quantile$age6670[visitor_quantile$age_range == "66-70"] <- 1
visitor_quantile$age7175 <- 0
visitor_quantile$age7175[visitor_quantile$age_range == "71-75"] <- 1
visitor_quantile$age3640 <- 0
visitor_quantile$age3640[visitor_quantile$age_range == "36-40"] <- 1
visitor_quantile$age76 <- 0
visitor_quantile$age76[visitor_quantile$age_range == "76+"] <- 1
visitor_quantile$age4145 <- 0
visitor_quantile$age4145[visitor_quantile$age_range == "41-45"] <- 1
visitor_quantile$age6165 <- 0
visitor_quantile$age6165[visitor_quantile$age_range == "61-65"] <- 1
visitor_quantile$age4650 <- 0
visitor_quantile$age4650[visitor_quantile$age_range == "46-50"] <- 1
visitor_quantile$age5660 <- 0
visitor_quantile$age5660[visitor_quantile$age_range == "56-60"] <- 1
visitor_quantile$age5155 <- 0
visitor_quantile$age5155[visitor_quantile$age_range == "51-55"] <- 1
visitor_quantile$age3135 <- 0
visitor_quantile$age3135[visitor_quantile$age_range == "31-35"] <- 1
visitor_quantile$age2125 <- 0
visitor_quantile$age2125[visitor_quantile$age_range == "21-25"] <- 1
visitor_quantile$age2630 <- 0
visitor_quantile$age2630[visitor_quantile$age_range == "26-30"] <- 1
visitor_quantile$age1820 <- 0
visitor_quantile$age1820[visitor_quantile$age_range == "18-20"] <- 1

visitor_quantile = visitor_quantile[,-which(names(visitor_quantile) %in% c("age_range","credit_worthiness"))]

# Merge with y
visitor_new = cbind(visitor_binary,visitor_unchange[,-1],visitor_quantile[,-1])
y_new = merge(y,visitor_new,by="visitor_key")

##### Train/Test
set.seed(1)
size<-sample(length(y_new$visitor_key),length(y_new$visitor_key)*0.5)
train<-y_new[-size,]
test<-y_new[size,]
save(train, file = "train_v01.rdata")
save(test, file = "test_v01.rdata")

# Quantile
names(train)

# dat1 = train[,c(1,60:79)]
dat1 = as.data.frame(train)

# Get rid of outliers
quantile(t(dat1[,60]),prob = c(0,0.25,0.5,0.75,0.99,1)) # 1453
dat1 = subset(dat1,dat1[,60]<=1453 )

quantile(t(dat1[,61]),prob = c(0,0.25,0.5,0.75,0.99,1)) # 375
dat1 = subset(dat1,dat1[,61]<=375 )

quantile(t(dat1[,62]),prob = c(0,0.25,0.5,0.75,0.99,1)) # 31
dat1 = subset(dat1,dat1[,62]<=31 )

quantile(t(dat1[,63]),prob = c(0,0.25,0.5,0.75,0.99,1)) # 27
dat1 = subset(dat1,dat1[,63]<=27 )

quantile(t(dat1[,64]),prob = c(0,0.25,0.5,0.75,0.99,1)) # 249414
dat1 = subset(dat1,dat1[,64]<=249414 )

quantile(t(dat1[,65]),prob = c(0,0.25,0.5,0.75,0.99,1)) # 8863
dat1 = subset(dat1,dat1[,65]<=8863 )

quantile(t(dat1[,66]),prob = c(0,0.25,0.5,0.75,0.99,1)) #266
dat1 = subset(dat1,dat1[,66]<=266 )

quantile(t(dat1[,67]),prob = c(0,0.25,0.5,0.75,0.99,1)) #226
dat1 = subset(dat1,dat1[,67]<=226 )

quantile(t(dat1[,68]),prob = c(0,0.25,0.5,0.75,0.99,1)) #559
dat1 = subset(dat1,dat1[,68]<=559 )

quantile(t(dat1[,69]),prob = c(0,0.25,0.5,0.75,0.99,1)) #258
dat1 = subset(dat1,dat1[,69]<=258 )

quantile(t(dat1[,70]),prob = c(0,0.25,0.5,0.75,0.99,1)) #188
dat1 = subset(dat1,dat1[,70]<=188 )

quantile(t(dat1[,71]),prob = c(0,0.25,0.5,0.75,0.99,1)) #14
dat1 = subset(dat1,dat1[,71]<=14 )

quantile(t(dat1[,72]),prob = c(0,0.25,0.5,0.75,0.99,1)) #22
dat1 = subset(dat1,dat1[,72]<=22 )

quantile(t(dat1[,73]),prob = c(0,0.25,0.5,0.75,0.99,1)) #23
dat1 = subset(dat1,dat1[,73]<=23 )

quantile(t(dat1[,74]),prob = c(0,0.25,0.5,0.75,0.99,1)) #22
dat1 = subset(dat1,dat1[,74]<=22 )

quantile(t(dat1[,75]),prob = c(0,0.25,0.5,0.75,0.99,1)) #25
dat1 = subset(dat1,dat1[,75]<=25 )

quantile(t(dat1[,76]),prob = c(0,0.25,0.5,0.75,0.99,1)) #29
dat1 = subset(dat1,dat1[,76]<=29 )

dat1 = subset(dat1, dat1$tot_dwell_time >= 0)
quantile(t(dat1[,77]),prob = c(0,0.25,0.5,0.75,0.99,1)) #1216680
dat1 = subset(dat1,dat1[,77]<=1216680)

quantile(t(dat1[,78]),prob = c(0,0.25,0.5,0.75,0.99,1)) #490.42
dat1 = subset(dat1,dat1[,78]<=490.42 )

quantile(t(dat1[,79]),prob = c(0,0.25,0.5,0.75,0.99,1)) #5
dat1 = subset(dat1,dat1[,79]<=5 )
# dat1_bak = dat1

# ====================================================================
# quantile on new dat1 (after ommiting outliers)

quant_res = dat1$visitor_key
quant = NULL

for(i in 60: 79){
  # i=2
  print(i)
  q = quantile(dat1[,i],probs = c(0,0.33,0.66,1))
  fea = colnames(dat1)[i]
  quant = rbind(quant,data.frame(fea = fea, q[1],q[2],q[3],q[4]))
  
  x1 = rep(0,nrow(dat1))
  x1[dat1[i]>=q[1] & dat1[i] <q[2]] <- 1
  
  x2 = rep(0,nrow(dat1))
  x2[dat1[i]>=q[2] & dat1[i] <q[3]] <- 1
  
  x3 = rep(0,nrow(dat1))
  x3[dat1[i]>=q[3] & dat1[i] <=q[4]] <- 1
  
  temp = data.frame(x1,  x2, x3)
  colnames(temp) = c(paste0(fea,"_L"),paste0(fea,"_M"),paste0(fea,"_H"))
  
  quant_res = cbind(quant_res,temp)
}
colnames(quant_res)[1] = "visitor_key"
# ========================================================================
### Apply on train
train_new = cbind(dat1[,-c(60:79)],quant_res[,-1])
save(train_new,file="train_v01_final.rdata")

# ==========================================================================
### Chi-square
require(caret)
library(reshape)
library("plyr")
library("dplyr")
library("stringr")
library("glmnet")

dat.select = train_new
fea.score = do.call(rbind.data.frame, lapply(3:ncol(dat.select), function(x) {
  chi.tmp = cbind(dat.select[, x], dat.select[, "buy"])
  # class = 0
  
  A = sum(chi.tmp[, 1]==1 & chi.tmp[, 2]==0,na.rm = T)
  B = sum(chi.tmp[, 1]==1 & chi.tmp[, 2]==1,na.rm = T)
  C = sum(chi.tmp[, 1]==0 & chi.tmp[, 2]==0,na.rm = T)
  D = sum(chi.tmp[, 1]==0 & chi.tmp[, 2]==1,na.rm = T)
  N = nrow(dat.select)
  s2 = N*(A*D-C*B)^2/(A+C)/(B+D)/(A+B)/(C+D)
  # class = 1
  A = sum(chi.tmp[, 1]==1 & chi.tmp[, 2]==1,na.rm = T)
  B = sum(chi.tmp[, 1]==1 & chi.tmp[, 2]==0,na.rm = T)
  C = sum(chi.tmp[, 1]==0 & chi.tmp[, 2]==1,na.rm = T)
  D = sum(chi.tmp[, 1]==0 & chi.tmp[, 2]==0,na.rm = T)
  N = nrow(dat.select)
  s1 = N*(A*D-C*B)^2/(A+C)/(B+D)/(A+B)/(C+D)
  return(c(A, B, C, D, s1, s2, max(s1, s2, na.rm = T)))
}))
colnames(fea.score) = c("A", "B", "C", "D", "Case.Score", "Control.Score", "CHI.Score")
rownames(fea.score) = colnames(dat.select[,-c(1,2)])
fea.score$feaName = rownames(fea.score)
fea.score = fea.score[order(fea.score$CHI.Score, decreasing = T), ]

fea_select = subset(fea.score,fea.score$CHI.Score>0)
fea_select = fea_select$feaName
save(fea.score,file="Chi.Score.train_v01.rdata")

# write.csv(train_new,"train_v01_final.csv")
train_new_select = train_new[,c("visitor_key","buy",fea_select)]
save(train_new_select,file="train_v01_select.rdata")

# ====================================================================
### Apply on test data
dat2 = test
names(dat2)
quant_res2 = dat2$visitor_key

for(i in 60:79){
  # i=60
  print(i)
  j = i-59
  fea = colnames(dat2)[i]
  
  x1 = rep(0,nrow(dat2))
  x1[dat2[i]>=quant[j,2] & dat2[i] < quant[j,3]] <- 1
  
  x2 = rep(0,nrow(dat2))
  x2[dat2[i]>=quant[j,3] & dat2[i] <quant[j,4]] <- 1
  
  x3 = rep(0,nrow(dat2))
  x3[dat2[i]>=quant[j,4] & dat2[i] <=quant[j,5]] <- 1
  
  temp = data.frame(x1,  x2, x3)
  colnames(temp) = c(paste0(fea,"_L"),paste0(fea,"_M"),paste0(fea,"_H"))
  
  quant_res2 = cbind(quant_res2,temp)
}
test_new = cbind(dat2[,-c(60:79)],quant_res2[,-1])
save(test_new,file="test_v01_final.rdata")
test_new = as.data.frame(test_new)
test_new_select = test_new[,c("visitor_key","buy",fea_select)]
save(test_new_select,file="test_v01_select.rdata")
