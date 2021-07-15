/***
* Name: M1-1
* Author: Huynh Vinh Nam
* Date: 27 - April - 2020 
***/

model M11

/* Global */

global {
	int dimensionsY <- int(424 / 2);
	int dimensionsX <- int(523 / 2);
	geometry shape <- rectangle(dimensionsX, dimensionsY);
	
	/* Time controllers */
	float stepDuration <- 3600#s;
	int timeElapsed <- 0 update:  int(cycle * stepDuration);
	float currentMinute <- 0.0 update: ((timeElapsed mod 3600#s))/60#s; 
	float currentHour <- 0.0 update: ((timeElapsed mod 86400#s))/3600#s;
	int currentDay <- int(0.0) update: int(((timeElapsed mod 31536000#s))/86400#s);
	
	/* Species variables */
	int individuals_number <- 500;
	int nb_init_infected <- 300;
	
	float infectious_distance <- 3.0;
	
	int maxIcount <- 0;
	int infectedDuration <- 0;
	
	int nbS <- individuals_number min: 0 max: 2000;
	int nbE <- 0; 	
	int nbI <- 0;
	int nbR <- 0;
	
	init {
		
		create individuals number: individuals_number;
		
		do init_epidemic();

		nbE <- 0;
		nbR <- 0;		
		nbS <- individuals_number - nbI;
	}
	
	action init_epidemic {
		loop i from: 0 to: nb_init_infected-1 {
			ask one_of(individuals) {
				isS <- false;
				isI <- true;
				
				nbI <- nbI + 1;
				
				color <- #red;
			}
		}
	}
}

/* Species */

species individuals skills: [moving] {
	float proba_infect <- 0.17;
	
	bool isS <- true;		// S: Susceptible - Normal person
	bool isE <- false;		// E: Exposed - An infected person but cannot infect others
	bool isI <- false;		// I: Infectious - An infected person and can spread the disease
	bool isR <- false;		// R: Recovered - Recovered one who cannot be infected anymore
	
	rgb color <- #green;
	
	int exposedDay <- 0;
	int infectiousDay <- 0;
	int incubationTime <- rnd(7) + 3;
	int infectiousTime <- rnd(20) + 5; 
		
	reflex moving {
		do wander speed: 3.0;
		if (flip(proba_infect)) 
		{
			do spread_disease();
		}
	} 
	
	reflex regain_health {
		do setRecovered();
	}
	
	action setExposed {
		isS <- false;
		isE <- true;
		isI <- true;
		
		nbS <- nbS - 1;
		nbE <- nbE + 1;
		
		exposedDay <- currentDay;
		
		color <- #orange;
	}
	
	action setInfected {
		if (isE) and (exposedDay + incubationTime < currentDay) {
			isE <- false;
						
			nbE <- nbE - 1;
			nbI <- nbI + 1;
			
			color <- #red;
			
			if (nbI > maxIcount) {
				infectedDuration <- currentDay;
				maxIcount <- nbI;
			}
		}
	}
	
	action setRecovered {
		if (isI) and (!isE) and (infectiousDay + infectiousTime < currentDay) {
			isI <- false;
			isR <- true;
						
			nbI <- nbI - 1;
			nbR <- nbR + 1;
			
			color <- #blue;
		}
	}
	
	action spread_disease {
		list<individuals> close_target <- individuals at_distance(infectious_distance);
		if (isI) {
			if (!isE) {
				ask close_target where (each.isS) {
				do setExposed;
				}
			}
			else {
				do setInfected;
			}
		}
	}
	
	aspect default {
		draw circle(1.0) color: color;
	}
}

/* Experiment */

experiment gui_exp type: gui {
	output {
		display all_agents {
			species individuals aspect: default;
		}
		display series_chart {
			chart "States of the agents" type: series style: line {
				datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.isS = true), individuals count (each.isE = true), 
														  individuals count (each.isI = true and !each.isE), individuals count (each.isR = true)] 
												  color: [#green, #orange, #red, #blue];
			}
		}
		monitor "nb susceptible people" value: individuals count(each.isS = true);
		monitor "nb exposed people" value: individuals count(each.isE = true);
		monitor "nb infected people" value: individuals count(each.isI = true);
	} 
}

experiment E1_1 {
	parameter "Number of people" var: individuals_number init: 500 min: 200 max:2000 step: 200;
	parameter "Initial infected" var: nb_init_infected init: 10 min:1 max: 100;	
	
	init {
		create simulation with:[individuals_number::individuals_number, nb_init_infected::nb_init_infected, seed::2];
		create simulation with:[individuals_number::individuals_number, nb_init_infected::nb_init_infected, seed::3];
		create simulation with:[individuals_number::individuals_number, nb_init_infected::nb_init_infected, seed::4];
		create simulation with:[individuals_number::individuals_number, nb_init_infected::nb_init_infected, seed::5];
	}
	
	output {
		display all_agents {
			species individuals aspect: default;
		}
		display series_chart {
			chart "States of the agents" type: series style: line {
				datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.isS = true), individuals count (each.isE = true), 
														  individuals count (each.isI = true and !each.isE), individuals count (each.isR = true)] 
												  color: [#green, #orange, #red, #blue];
			}
		}
		
	}
}

experiment E1_2 {
	parameter "Number of people" var: individuals_number init: 200 min: 200 max: 2000;
	parameter "Initial infected" var: nb_init_infected init: 10 min: 1 max: 100;	
		
	init {
		create simulation with:[individuals_number::200, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::400, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::600, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::800, nb_init_infected::nb_init_infected, seed::seed];
		/*
		create simulation with:[individuals_number::1000, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::1200, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::1400, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::1600, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::1800, nb_init_infected::nb_init_infected, seed::seed];
		create simulation with:[individuals_number::2000, nb_init_infected::nb_init_infected, seed::seed];
		*/
	}
	
	output {
		display all_agents {
			species individuals aspect: default;
		}
		display series_chart {
			chart "States of the agents" type: series style: line {
				datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.isS = true), individuals count (each.isE = true), 
														  individuals count (each.isI = true and !each.isE), individuals count (each.isR = true)] 
												  color: [#green, #orange, #red, #blue];
			}
		}
	}
}

experiment E1_3 type: batch until: (nbE = 0 and nbI = 0)  {
	parameter "Number of people" var: individuals_number init: 500 min: 200 max: 2000 step: 200;
	parameter "Initial infected" var: nb_init_infected init: 10 min: 10 max: 10;	
	
	method exhaustive;
	
	init {
		save ["Number of people", "Day (# infected is at max)", "Pandemic duration" ]
		to: "Ex1-3.csv" type:"csv" rewrite: true header: false;
	}
	
	reflex saving {
		ask simulations {
			save [self.individuals_number, self.infectedDuration, self.currentDay] 
			to: "Ex1-3.csv" type: "csv" rewrite: false;
		}
	}
	
}