
library(UsingR)
library(dplyr)
library(stringr)
library(ggplot2)
library(scales)
library(shinyIncubator)
library(RCurl)

## Load up result database
filename <- c("intres.csv")
RESfull <- read.csv(filename,stringsAsFactors=FALSE)
 
# # Load up sensible starting values for parameters (speeds up mle covergence)
teamstart <- read.csv("teamstart.csv",stringsAsFactors=FALSE)

# names(RESfull) <- c("HOMEADV","FRIENDLY","HOME","AWAY","HG","AG","DATE")
# names(teamstart) <- c("Team","Attack","Defence")
# RESfull$DATE <- as.Date(RESfull$DATE,format="%m/%d/%Y")
# RESfull$W <- numeric(nrow(RESfull))
# RESfull$HOME <- toupper(str_trim(as.character(RESfull$HOME)))
# RESfull$AWAY <- toupper(str_trim(as.character(RESfull$AWAY)))
# teamstart$Team <- toupper(str_trim(as.character(teamstart$Team)))
# x<-seq(min(RESfull$DATE),max(RESfull$DATE),1)
# y<-integer(length(x))
# a<-0






# Define server logic for random distribution application
shinyServer(function(input, output, session) {

    # Grab fresh data
    
    
    
    try(RESfull <- read.csv(textConnection(getURL("https://raw.githubusercontent.com/iainharlow/SoccerRanks/master/intres.csv")),
                        stringsAsFactors=FALSE,
                        header=TRUE))
    try(teamstart <- read.csv(textConnection(getURL("https://raw.githubusercontent.com/iainharlow/SoccerRanks/master/teamstart.csv")),
                            stringsAsFactors=FALSE,
                            header=TRUE))
    names(RESfull) <- c("HOMEADV","FRIENDLY","HOME","AWAY","HG","AG","DATE")
    names(teamstart) <- c("Team","Attack","Defence")
    RESfull$DATE <- as.Date(RESfull$DATE,format="%m/%d/%Y")
    RESfull$W <- numeric(nrow(RESfull))
    RESfull$HOME <- toupper(str_trim(as.character(RESfull$HOME)))
    RESfull$AWAY <- toupper(str_trim(as.character(RESfull$AWAY)))
    teamstart$Team <- toupper(str_trim(as.character(teamstart$Team)))
    x<-seq(min(RESfull$DATE),max(RESfull$DATE),1)
    y<-integer(length(x))
    a<-0
    
    # Reactive weight plot
    output$dateplot <- renderPlot({
        y<-as.integer(x>=input$daterange[1]&x<=input$daterange[2])
        y<-y*(exp(-as.numeric(input$daterange[2]-x)/(input$d_halflife*(365/12)/log(2)))/(input$d_halflife*(365/12)/log(2)))^as.integer(input$decay)
        y<-y/max(y)
        ggplot(data = data.frame("x"=x,"y"=y),
               aes(x=x,y=y)) +
            geom_line(colour = "blue",size = 1) +
            geom_abline(intercept=0, slope=0) +
            scale_y_continuous(limits=c(0,1),labels = percent) +
            theme(axis.line = element_line(colour = "black", size = 0.5)) +
            theme(axis.line.x = element_blank()) +
            theme(axis.title.x = element_blank()) +
            theme(axis.title.y = element_blank()) +
            theme(axis.line.y = element_line(colour = "black", size = 0.5))
    })
    
    # MLE dependent calculations:
    data <- reactive({
        
        # Change when the "gomle" button is pressed...
        input$gomle
        
        # ...but not for anything else
        isolate({
            withProgress(session, {
                setProgress(message = "Maximising Likelihood... Please be patient...")
                
                paramtext <- "Running."
                #                 paramtext <- cat("Model run with the following parameters:",
                #                                        "\nDate range: ",
                #                                        as.character(input$daterange[1]),
                #                                        " to ",
                #                                        as.character(input$daterange[2]),
                #                                        "\nDecay function: ",
                #                                        if (input$decay==0) "None."
                #                                        else paste("Exponential with half-life = ",
                #                                                   as.character(input$d_halflife),
                #                                                   " months."),
                #                                        "\nFriendlies weighted as: ",
                #                                        sprintf("%1f%%",input$friendlies)
                #                 )
                
                # Calculate weights and discard games with w=0
                sw <- as.integer(RESfull$DATE>=input$daterange[1]&RESfull$DATE<=input$daterange[2])
                dw <- (exp(-as.numeric(input$daterange[2]-RESfull$DATE)/(input$d_halflife*(365/12)/log(2)))/(input$d_halflife*(365/12)/log(2)))^as.integer(input$decay)
                fw <- input$friendlies^(RESfull$FRIENDLY)
                tempw<-sw*dw*fw
                RESfull$W <- tempw/mean(tempw)
                RES <- RESfull[RESfull$W>0,]
                
                # Find unique teams and order alphabetically 
                TEAMS <- factor(c(sort(unique(c(RES$HOME,RES$AWAY))),"DUMMY"),levels=c(sort(unique(c(RES$HOME,RES$AWAY))),"DUMMY"))
                RES$HOME <- as.integer(factor(RES$HOME,levels=TEAMS))
                RES$AWAY <- as.integer(factor(RES$AWAY,levels=TEAMS))
                
                # Get average goals and average home advantage
                Gmean <- mean(c(RES$HG,RES$AG))
                Hadvmean <- (sum(RES$HG[RES$HOMEADV==1])/sum(RES$AG[RES$HOMEADV==1]))^0.5
                
                # Add dummy games for model stability
                RESEXTRA <- RES[1:(length(TEAMS)*2-2),]
                RESEXTRA$HOME <- c(head(TEAMS,-1),head(TEAMS,-1))
                RESEXTRA$AWAY <- c(head(TEAMS,-1),rep(tail(TEAMS,1),(length(TEAMS)-1)))
                RESEXTRA[,1:2] <- 0
                RESEXTRA[,c("HG","AG")] <- 1
                RESEXTRA$W <- c(rep(1,(length(TEAMS)-1)),rep(input$stabweight,(length(TEAMS)-1)))
                RESCALC <- rbind(RES,RESEXTRA)
                #RESCALC <- RES
                
                # Set global (data) variables for the mle function
                H<-RESCALC$HG
                A<-RESCALC$AG
                HT<-RESCALC$HOME
                AT<-RESCALC$AWAY
                home<-RESCALC$HOMEADV
                w<-RESCALC$W
                o<-(1-input$outliers/4)
                
                # Estimate reasonable starting parameters for the mle function
                #                 homegoals <- RES[,c("HOME","HG","AG","AWAY")]
                #                 awaygoals <- RES[,c("AWAY","AG","HG","HOME")]
                #                 names(homegoals) <- c("TEAM","F","A","OPP")
                #                 names(awaygoals) <- c("TEAM","F","A","OPP")
                
                # A measure of how much information we have on each team, sqrt(matches):
                # Use this to moderate the weights a little
                
                #                 teamcount <- table(homegoals$TEAM)
                #                 teaminfo <- (teamcount^0.5)/mean(teamcount^0.5)
                #                 w <- w*sum(teaminfo[RESCALC$HOME],teaminfo[RESCALC$HOME])^0.5
                #                 w <- w/mean(w)
                
                #                 allgoals <- rbind(homegoals,awaygoals)
                #                 gpd_goals <- group_by(allgoals[,1:3],TEAM)
                #                 avg <- summarise_each(gpd_goals,funs(mean))
                # 
                #                 # Begin with average goals scored/conceded as parameters
                #                 attstart<-avg$F/Gmean*(teaminfo^0.2)
                #                 defstart<-avg$A/Gmean/(teaminfo^0.2)
                # 
                #                 # Now iterate once to correct for opposition
                #                 relativegoals <- allgoals
                #                 relativegoals$F <- as.numeric(relativegoals$F/defstart[relativegoals$OPP])
                #                 relativegoals$A <- as.numeric(relativegoals$A/attstart[relativegoals$OPP])
                #                 gpd_goals <- group_by(relativegoals[,1:3],TEAM)
                #                 avg <- summarise_each(gpd_goals,funs(mean))
                # 
                #                 attstart<-avg$F/Gmean
                #                 defstart<-avg$A/Gmean
                #                 paramstart<-c(Gmean,Hadvmean,attstart,defstart) # Gets stuck in local minima if some teams play very unbalanced schedules
                attstart <- rep(1,length(TEAMS))
                defstart <- rep(1,length(TEAMS))
                attstart[is.element(TEAMS,teamstart$Team)] <- teamstart[is.element(teamstart$Team,TEAMS),2]
                defstart[is.element(TEAMS,teamstart$Team)] <- teamstart[is.element(teamstart$Team,TEAMS),3]
                paramstart<-c(Gmean,Hadvmean,attstart,defstart)
                # paramstart<-c(Gmean,1.1,rep(1,(length(TEAMS)*2)))
                
                # Likelihood function to minimise
                mtmp <- function(tparams){
                    mgls<-tparams[1]
                    hadv<-tparams[2]
                    Att<-tparams[3:(length(tparams)/2+1)]
                    Def<-tparams[(length(tparams)/2+2):length(tparams)]
                    sum(((-log(dpois(H,mgls*Att[HT]*Def[AT]*(hadv^home))))^o+(-log(dpois(A,mgls*Att[AT]*Def[HT]/(hadv^home))))^o)*w)
                }
                
                m<-nlm(mtmp, paramstart, gradtol=1e-4, steptol=1e-4, iterlim = input$maxiter)
                list(as.character(TEAMS),paramstart,m$estimate,m$minimum,sum(w))
                #list(as.character(TEAMS),names(RESEXTRA),Gmean,Hadvmean,sum(w))
            })
        })
    })
    
    # Create Data Table
    output$table <- renderDataTable({
        if (input$gomle==0) data.frame("No data yet!" = 0)
        else isolate({
            skellam <- function(k,mu1,mu2){
                return(exp(-mu1-mu2)*((mu1/mu2)^(k/2))*besselI(2*sqrt(mu1*mu2),k))
            }
            tl <- length(data()[[1]])
            pl <- length(data()[[3]])
            teamcol <- head(data()[[1]],(tl-1))
            attcol <- data()[[3]][3:(tl+1)]
            defcol <- tail(head(data()[[3]],(pl-1)),(tl-1))
            logratio <- log(attcol/defcol)
            logratio <- pnorm(as.numeric(scale(logratio)))*1000
            
            # To make the numbers more concrete, let's use "beating the USA" as a baseline for whether a team is good or not!
            probcol <- numeric(length(teamcol))
            USA_att <- attcol[teamcol=="USA"]
            USA_def <- defcol[teamcol=="USA"]
            
            # When dealing with draws, could either ignore them (exaggerates better team) or assign them 50% to each team (exaggerates weak teams, and attacking strong teams relative to defensive strong teams). Let's split the difference for now.
            for (k in seq(1,length(probcol),1)){
                probcol[k] <- mean(sum(skellam(seq(1,20,1),attcol[k]*USA_def*head(data()[[3]],1),defcol[k]*USA_att*head(data()[[3]],1)))/(1-skellam(0,attcol[k]*USA_def*head(data()[[3]],1),defcol[k]*USA_att*head(data()[[3]],1))),
                                   sum(skellam(seq(1,20,1),attcol[k]*USA_def*head(data()[[3]],1),defcol[k]*USA_att*head(data()[[3]],1)))+0.5*skellam(0,attcol[k]*USA_def*head(data()[[3]],1),defcol[k]*USA_att*head(data()[[3]],1)))
            }
            
            df <- arrange(data.frame("Rank" = integer(length(teamcol)),
                                     "Team" = teamcol,
                                     "Attack" = sprintf("%04.2f",attcol),
                                     "Defence" = sprintf("%04.2f",defcol),
                                     "Winprob" = sprintf("%04.1f%%",probcol*100),
                                     "Rating" = sprintf("%03.0f",logratio)),
                          desc(Rating))
            df$Rank <- seq(1,length(teamcol))
            names(df) <- c("Rank","Team","Attack","Defence","Win chance vs USA","Rating")
            df
        })
    })
    
    output$text1 <- renderText({
        "Negative (weighted) log-likelihood reached: "
    })
    
    output$text2 <- renderText({
        if(input$gomle>0) sprintf("%.1f",data()[[4]])
        else    "No MLE run yet." 
    })
    
})