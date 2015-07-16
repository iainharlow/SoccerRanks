
library(googleVis)
library(stringr)
library(dplyr)
setwd("C:/Users/Iain/Google Drive/Github/Blog/SoccerRanks/SoccerRanks")
testframe <- read.csv("countrydata.csv",stringsAsFactors=FALSE)
names(testframe) <- toupper(str_trim(as.character(names(testframe))))
testframe$TEAM <- toupper(str_trim(as.character(testframe$TEAM)))
#testframe$RATING <- round(pnorm(testframe$Z_RAT)*1000)
testframe$RATING <- round(testframe$P_RAT.GDP)

testframe$TEAM[testframe$TEAM=="CHINA PR"] <- "CHINA"
testframe$TEAM[testframe$TEAM=="CONGO DR"] <- "DR CONGO"
testframe$TEAM[testframe$TEAM=="KOREA DPR"] <- "NORTH KOREA"
testframe$TEAM[testframe$TEAM=="KOREA REPUBLIC"] <- "SOUTH KOREA"
GB <- round(pnorm(mean(qnorm(testframe$P_RAT.GDP[testframe$TEAM=="ENGLAND"]/1000,0,1),
                       qnorm(testframe$P_RAT.GDP[testframe$TEAM=="SCOTLAND"]/1000,0,1),
                       qnorm(testframe$P_RAT.GDP[testframe$TEAM=="WALES"]/1000,0,1),
                       qnorm(testframe$P_RAT.GDP[testframe$TEAM=="NORTHERN IRELAND"]/1000,0,1)))*1000)

plotframe <- testframe[,c("TEAM","RATING")]
plotframe <- rbind(plotframe,c("GB",GB))

frame <- tbl_df(testframe)
by_confed <- group_by(frame,CONFEDERATION)
summarise(by_confed,
          pop_corr = cor(Z_RAT,Z_POP),
          gdp_corr = cor(Z_RAT,Z_GDP),
          gdp_extra = cor(RAT.POP,Z_GDP))


G <- gvisGeoChart(plotframe, "TEAM", "RATING",
                  options=list(
                      projection="kavrayskiy-vii",
                      colorAxis="{minValue: 0, maxValue: 1000,  colors: ['#eeeedd', '#229911']}",
                      region="world",
                      resolution="countries",
                      height=500,
                      width=900,
                      keepAspectRatio=TRUE))

plot(G)


# Green: ['#eeeedd', '#228800']