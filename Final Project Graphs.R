library(usmap)
library(ggplot2)
library(plotly)
library(dplyr)
library(zipcode)
######################################
rankingtable <- read.csv("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/rankingtable.csv")
data("statepop")
names(rankingtable)[5]<-"abbr"
statecar<-merge(statepop[,-4],rankingtable[,c(4,5)],by="abbr")
p1<-usmap::plot_usmap(data = statecar, values = "n", lines = "red") + 
  scale_fill_continuous(
    low = "white", high = "red", name = "Vehicles per 1000 People", label = scales::comma
  ) + theme(legend.position = "right")
print(p1)

######################################
Age_group_buy <- read.csv("~/Dropbox/UCLA/[Courses]/Stats Major/STATS 141/Stats141 Project/DataFest 2015 Data-20180213/Age_group_buy.csv")
p2 <- plot_ly(Age_group_buy, labels = ~fea, values = ~a,
             textposition = 'inside',
             textinfo = 'label+percent',
             insidetextfont = list(color = '#FFFFFF'),
             hoverinfo = 'text',
             text = Age_group_buy$a,
             marker = list(colors = colors,
                           line = list(color = '#FFFFFF', width = 1)),
             #The 'pull' attribute can also be used to create space between the sectors
             showlegend = FALSE) %>%
             add_pie(hole = 0.6) %>%
  layout(title = 'Age Group',
         xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
         yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
print(p2)

######################################
data(zipcode)
mapzip<-merge(trans[,c(1,6)],leads[,c(3,20,23)],by="visitor_key",all.x = T)
dat1<-mapzip %>% group_by(dealer_location_id) %>% summarise(count=n()) %>% arrange(desc(count))
dat2<-mapzip[mapzip$dealer_location_id==11455,]
dat2$zip_bought<- clean.zipcodes(dat2$zip_bought)
dat2$dealer_zip<- clean.zipcodes(dat2$dealer_zip)

dat3 <- merge(dat2, zipcode[,c(1,4,5)], by.x='zip_bought', by.y='zip')
names(dat3)[5]<-"start_lat"
names(dat3)[6]<-"start_lon"

dat4<-merge(dat3,zipcode[,c(1,4,5)],by.x ="dealer_zip", by.y='zip')
names(dat4)[7]<-"end_lat"
names(dat4)[8]<-"end_lon"

dat5<-dat4 %>% group_by(visitor_key) %>% summarise(freq=n())
dat6<-merge(dat4,dat5,by="visitor_key",all.x = T)

geo <- list(
  scope = 'usa',
  projection = list(type = 'albers usa'),
  showland = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray80")
)

p3 <- plot_geo(locationmode = 'USA-states', color = I("red")) %>%
  add_markers(
    data = dat6, x = ~start_lon, y = ~start_lat, text = ~zip_bought,
    size = ~freq, hoverinfo = "text", alpha = 0.5
  ) %>%
  add_segments(
    data = dat6,
    x = ~start_lon, xend = ~end_lon,
    y = ~start_lat, yend = ~end_lat,
    alpha = 0.3, size = I(1), hoverinfo = "none"
  ) %>%
  layout(
    geo = geo, showlegend = FALSE, height=800
  )
print(p3)

###############################################################
quantile(leads$dealer_distance,prob = c(0,0.25,0.5,0.75,0.99,1)) #148.177
dealerDis = subset(leads$dealer_distance,leads$dealer_distance<=148.177)
hist(dealerDis,col = "lightblue")