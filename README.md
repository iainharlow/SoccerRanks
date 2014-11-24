Soccer-Rank-Shiny-App
=====================

##User Guide


###The Basic Idea
Quick caveat - this is an early version of the app, and it's likely to evolve considerably to allow finer control, and more datasets.
This app comes pre-loaded with every Fifa-registered international soccer match between 1 Jan 2006 and 21 Nov 2014. We're going to use these results to build a ranking of international teams, based on the frequency they score and concede goals against a typical opponent. The advantage of this approach (rather than, say, assigning points for wins) is that it should be predictive: We're attempting to estimate statistics for each team that have some real-world meaning. The basic idea is that a higher-ranked team should be the favourite in a match against any lower-ranked opponent. That's a property the existing FIFA rankings do not guarantee.
Specifically, we're modelling the scoring of goals in a match as a poisson process, with each team's rate controlled by their attack multiplied by their opponent's defence (further multiplied by a constant, and also a home advantage factor, both of which the model calculates too). So high attack/defence values (>1) indicate the team scores/concedes more than average. The best teams will have a high attack and a low defence value, i.e. they'll score more than they concede against a typical opponent. It's possible to model goalscoring itself more accurately than we're doing with a simple independent poisson process - in particular, goals scored by each time are likely not independent, since losing teams generally make more effort to attack - but those details will have less effect on our ranking than they might on a score prediction.

###Setting Parameters
The really nice thing about this ranking app, however, is that you have considerable control over the weights. This has a couple of effects: First, you don't need to buy my assumptions, or FIFA's, about how to weight different results (e.g. the importance of friendlies). Secondly, you can calculate your rankings for any point in time since 2006, by setting the max date in the range. For example, you could set it to be June 1 2010 and see how strong each team was going into the World Cup in South Africa.
The following parameters can be set on the left:
- DATE RANGE. Restrict the model to a range of dates. Smaller ranges include fewer matches, so run faster, but are less accurate/stable as a result. It's recommended to use the full range together with a decay function.
- DECAY FUNCTION. Reduce the importance of older results, using an exponential decay function. You can set the half-life directly, and the plot should update immediately to show you the relative importance of results on different dates.
- FRIENDLIES. Friendlies may be less reliable indicators of team strength than competitive games, since experimental lineups are sometimes used and they're not usually taken as seriously. But they probably are still useful! You can adjust how much weight they're given, between 0% and 100% (of a competitive game's importance).
- ADVANCED OPTIONS. These currently allow you to downweight outliers (very unusual results) and stabilise team strength estimates, e.g. to account somewhat for regression to the mean and allow teams with few matches played to be entered into the model without it breaking. They're not always guaranteed to help though so be cautious with them! In particular, you may find with this dataset that stabilising team parameters inflates the strength of teams who've played (and thoroughly beaten) a lot of poor teams. Above-average island teams such as Fiji or New Caledonia are prime examples of this. In the future, options to adjust the model itself (modifications of the simple poisson for example) or to downweight large margin results will likely be included.

###View Weighting Tab
Use this tab to fine-tune your date weighting parameters - the plot visualises how much weight is given to results from different times.
                        
###Fit Data Tab
Once you have the parameters you want, head here to run the mle solver. You can select the number of iterations to run - higher gets you considerably more accuracy, but takes a few minutes. If you just want to try it out and see the data table, you can run 5-20 iterations fairly quickly, less than a minute generally.
When the solver is finished, the greyed-out text will update with the negative (weighted) log-likelihood reached.
                        
###View Results Tab
When you've run the solver at least once, you can browse a table of the results in this tab. The statistics returned for each team include:
- ATTACK: The mean number of goals scored per game against an average team, on neutral territory, relative to the overall mean (around 1.3 goals per team).
- DEFENCE: The mean number of goals conceded per game against an average team, on neutral territory, relative to the overall mean.
- WIN CHANCE v USA: Since the 'average' team in this dataset is not that good (only the top 15% of sides reach the World Cup Finals for example), we can use a decent 'baseline' team - the USA - to compare sides. The percentage here is the implied probability of the team beating the USA in a knockout match on neutral territory.
- RATING: A simple summary statistic from 0 (worst) to 1000 (best). It's a little more abstracted from the data, but allows a quick comparison of teams. It's constructed as the log of the attack/defence ratio for each team, expressed as a quantile of that distribution, and scaled to 1000. So 920 means that 920 out of 1000 teams would have a worse attack/defence ratio if you sampled them randomly.
                        