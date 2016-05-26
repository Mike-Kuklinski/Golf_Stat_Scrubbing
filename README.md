#Golf Stat Scrubbing

**Author:** Mike Kuklinski  
**Date:** 5/26/16  
**Language:** R  
**Computer:** Windows 10, 64-bit  
**Description:**  
    
Enclosed is code which can be used for scrubbing PGATour.com for the golf statistics
of a given year and stat ID number. The code can also scan espn.com for previous finishes 
in a given tournament, given a tournament ID. I have included the tournament IDs for the 4 Majors (Masters, PGA Championship, Open Championship, and US Open) dating from 2004-2016. To get other tournament IDs, you can search for the Major and year on espn.com, then locate the ID in the URL.  
See example, in this case 774 is the tournament ID for Masters 2010:  
[http://espn.go.com/golf/leaderboard?tournamentId=774](http://espn.go.com/golf/leaderboard?tournamentId=774)

All stat IDs on PGATour.com are in the range between 014 and 02675. To populate the complete stat list, the code scans every number within the range and checks if it exists on PGATour.com. If it exists, then it adds the stat ID number and description to a list and saves it.

Finally, the code runs through each year in a range and populates a csv file for each available stat found.

**Please Note:**  
- I have already populated all the available stats from 2005 to 2016 and they are included in the repository.  
- 2016 is obviously still in progress so the associated stats included are only as of 5/11/16.  
- The Tournament Finishes only include the Player's Name, Finish Place, and Year. You can tweak the code to change which columns it'll return.  
- The Tournament Finishes include extrapolated finish places for players who didn't make the CUT. You can change this by setting `rank_cut` to `TRUE` (this is actually the default) when calling the function.

### Libraries Used    
dplyr  
qdap  
stringr  
httr  
XML  
stringr  