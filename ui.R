library(shiny)
library(shinyIncubator)

# Define UI for random distribution application 
shinyUI(fluidPage(
    
    progressInit(),
    
    # Application title
    titlePanel("A Smart Soccer Ranking App"),
    
    # Sidebar with controls to select the random distribution type
    # and number of observations to generate. Note the use of the
    # br() element to introduce extra vertical spacing
    sidebarLayout(
        sidebarPanel(
            h3("Parameter Selection"),
            br(),
            h4("Date Range"),
            dateRangeInput("daterange", 
                           label="Adjust the date range you'd like to consider results between. Results begin from Jan 1st 2006. Longer ranges give more stable results, but may take longer to run.",
                           start = "2006-01-01",
                           min = "2005-12-31",
                           format = "dd-M-yyyy",
                           startview = "year",
                           separator = " to "),
            br(),
            
            h4("Decay Function"),
            checkboxInput("decay",
                          "Use decay function (recent results are more informative)?"),
            
            sliderInput("d_halflife", 
                        "Adjust half-life of decay function, in months. Results from this long ago will be half as influential as the latest results:", 
                        value = 12,
                        min = 1, 
                        max = 120,
                        step = 1),
            
            br(),
            
            h4("Friendlies"),
            sliderInput("friendlies", 
                        "How influential are friendlies, relative to competitive games? 0% = ignore friendlies, 100% = just as important as competitive matches.", 
                        value = 0.8,
                        min = 0, 
                        max = 1,
                        step = 0.01,
                        ticks = c("0%","50%","100%")),
            
            br(),
            br(),
            h4("Advanced Options"),
            helpText("The following options alter how the model treats outliers (very unusual results) and how much it 'stabilises' the parameters towards the average. Changing these is not necessarily recommended, but more aggressive settings might help make the model more predictive in some circumstances. See the help documentation for details."),
            br(),
            
            
            sliderInput("outliers",
                        "De-emphasise outliers?",
                        value = 0,
                        min = 0, 
                        max = 3,
                        step = 1,
                        ticks = c("None","Light","Normal","Aggressive")),
            
            br(),
            
            sliderInput("stabweight", 
                        "Stabilise parameters?", 
                        value = 0,
                        min = 0, 
                        max = 3,
                        step = 1,
                        ticks = c("None","Light","Normal","Aggressive"))

        ),
        
        mainPanel(
            tabsetPanel(
                id = "panelname",
                tabPanel("User Guide",
                         h3("User Guide"),
                         br(),
                         h4("The Basic Idea"),
                         p("Quick caveat - this is an early version of the app, and it's likely to evolve considerably to allow finer control, and more datasets."),
                         p("This app comes pre-loaded with every Fifa-registered international soccer match between 1 Jan 2006 and 21 Nov 2014. We're going to use these results to build a ranking of international teams, based on the frequency they score and concede goals against a typical opponent. The advantage of this approach (rather than, say, assigning points for wins) is that it should be predictive: We're attempting to estimate statistics for each team that have some real-world meaning. The basic idea is that a higher-ranked team should be the favourite in a match against any lower-ranked opponent. That's a property the existing FIFA rankings do not guarantee."),
                         p("Specifically, we're modelling the scoring of goals in a match as a poisson process, with each team's rate controlled by their attack multiplied by their opponent's defence (further multiplied by a constant, and also a home advantage factor, both of which the model calculates too). So high attack/defence values (>1) indicate the team scores/concedes more than average. The best teams will have a high attack and a low defence value, i.e. they'll score more than they concede against a typical opponent. It's possible to model goalscoring itself more accurately than we're doing here, of course. We're just using a simple independent poisson process, but in reality, goals scored by each team are likely not independent, since teams generally make more effort to attack when they are trailing. Those details, though, will have less effect on a ranking than they would on a score prediction, so we'll save that for a future update :-)."),
                         br(),
                         h4("Setting Parameters"),
                         p("The really nice thing about this ranking app, however, is that you have considerable control over the weights. This has a couple of effects: First, you don't need to buy my assumptions, or FIFA's, about how to weight different results (e.g. the importance of friendlies). Secondly, you can calculate your rankings for any point in time since 2006, by setting the max date in the range. For example, you could set it to be June 1 2010 and see how strong each team was going into the World Cup in South Africa."),
                         p("The following parameters can be set on the left:"),
                         p("DATE RANGE. Restrict the model to a range of dates. Smaller ranges include fewer matches, so run faster, but are less accurate/stable as a result. It's recommended to use the full range together with a decay function."),
                         p("DECAY FUNCTION. Reduce the importance of older results, using an exponential decay function. You can set the half-life directly, and the plot should update immediately to show you the relative importance of results on different dates."),
                         p("FRIENDLIES. Friendlies may be less reliable indicators of team strength than competitive games, since experimental lineups are sometimes used and they're not usually taken as seriously. But they probably are still useful! You can adjust how much weight they're given, between 0% and 100% (of a competitive game's importance)."),
                         p("ADVANCED OPTIONS. These currently allow you to downweight outliers (very unusual results) and stabilise team strength estimates, e.g. to account somewhat for regression to the mean and allow teams with few matches played to be entered into the model without it breaking. They're not always guaranteed to help though so be cautious with them! In particular, you may find with this dataset that stabilising team parameters inflates the strength of teams who've played (and thoroughly beaten) a lot of poor teams. Above-average island teams such as Fiji or New Caledonia are prime examples of this. In the future, options to adjust the model itself (modifications of the simple poisson for example) or to downweight large margin results will likely be included."),
                         br(),
                         h4("View Weighting Tab"),
                         p("Use this tab to fine-tune your date weighting parameters - the plot visualises how much weight is given to results from different times. Note that the 'View Weights' part of the app is sufficiently complex for the Data Products assignment, so if you're here to mark that - and you don't have much time (or interest in this app!) then you won't actually need to run the actual MLE solver."),
                         br(),
                         h4("Fit Data Tab"),
                         p("Once you have the parameters you want, head here to run the mle solver. You can select the number of iterations to run - higher gets you considerably more accuracy, but takes a few minutes. If you just want to try it out and see the data table, you can run 5-20 iterations fairly quickly, less than a minute generally."),
                         p("To give you a rough idea of timings, when I first deployed this app I found it took around 30s per 100 iterations, per year of results. The amount of time increases approximately linearly with both date range and iterations. So if you just run 10 iterations on 2 years of results it should complete very quickly (it took just a few seconds for me). But this will be quite inaccurate. Running a full 100 iterations on the full range of results is likely to take somewhere in the region of 5 minutes, so get a coffee! Note that you can run a shorter version first and look at the resulting data table while you set a longer version running."),
                         p("When the solver is finished, the greyed-out text will update with the negative (weighted) log-likelihood reached."),
                         br(),
                         h4("View Results Tab"),
                         p("When you've run the solver at least once, you can browse a table of the results in this tab. The statistics returned for each team include:"),
                         p("ATTACK: The mean number of goals scored per game against an average team, on neutral territory, relative to the overall mean (around 1.3 goals per team)."),
                         p("DEFENCE: The mean number of goals conceded per game against an average team, on neutral territory, relative to the overall mean."),
                         p("WIN CHANCE v USA: Since the 'average' team in this dataset is not that good (only the top 15% of sides reach the World Cup Finals for example), we can use a decent 'baseline' team - the USA - to compare the elite sides. The percentage here is the implied probability of the team beating the USA in a knockout match on neutral territory."),
                         p("RATING: A simple summary statistic from 0 (worst) to 1000 (best). It's a little more abstracted from the data, but allows a quick comparison of teams. It's constructed as the log of the attack/defence ratio for each team, expressed as a quantile of that distribution, and scaled to 1000. So 920 means that 920 out of 1000 teams would have a worse attack/defence ratio if you sampled them randomly. Another way of thinking about it: If you let every team play against the 'average' team for a very long time, and kept track of the goals they scored/conceded, the higher ranked teams by this 0-1000 rating should end up scoring the most goals for every one they concede."),
                         p("Wondering why the Rating and the Chance v USA aren't perfectly correlated? It's because winning a game doesn't just rely on your score/concede ratio, it also requires getting enough goals to be ahead in the 90 minutes you play for. So a team who score 1.5 and concede 0.5 on average are less likely to beat a weaker opponent than a team who score 3 and concede 1 on average - even though they both have a 3:1 score:concede ratio. Vice-versa, a defensive team is more likely than an attacking team to get an upset against someone stronger than them (e.g. by winning 1-0 or drawing 0-0 or 1-1).")
                         ),
                tabPanel("View Weighting",
                         h3("Decay Function Chosen"),
                         helpText("This plot shows the weighting applied to each result, as a function of when it was played. Update the weighting function as you wish by adjusting the parameters on the left."),
                         br(),
                         plotOutput(outputId = "dateplot",
                                    height = "300px")
                         ),
                tabPanel("Fit Data",
                         h3("Estimate Team Rankings using Maximum Likelihood Estimation"),
                         p("Here you can estimate the strengths of international soccer teams. When you click the buttons below, the app will use all of the results in the range you selected - along with your other parameter choices - to estimate the strengths of each team."),
                         br(),
                         p("Fair warning: This may take some time. If you're just here to mark the app for the Data Products class, and you don't care about soccer, you don't have to run the MLE solver at all - the parameter selection part of the app fulfils all of the simple criteria required by the assignment."),
                         br(),
                         p("But! If you are interested, I encourage you to try it out. Set your weighting parameters, choose a number of iterations to run, and click the button to start the algorithm running. Once it has finished, you can see the calculated table in the View Results tab. For the first run, try a low number of iterations - 10 iterations should run in under 30 seconds. 100 iterations will be much more accurate, especially for teams who face a limited variety of opposition (e.g. Pacific Island teams) - but it may take a few minutes to run. Note that the total run time and accuracy/stability increase with both iterations and matches (i.e. date range). See the User Guide for some benchmark timings."),
                         br(),
                         sliderInput("maxiter", 
                                     "Maximum iterations:", 
                                     value = 10,
                                     min = 5, 
                                     max = 100,
                                     step = 5),
                         br(),
                         actionButton("gomle","Run MLE"),
                         br(),
                         br(),
                         textOutput("text1"),
                         textOutput("text2")
                         ),
                tabPanel("View Results",
                         h3("Ranking Table"),
                         br(),
                         dataTableOutput(outputId="table")
                         )
            
            )
        )
    )
))