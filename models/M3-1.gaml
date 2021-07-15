/***
* Name: M3-1
* Author: Huynh Vinh Nam
* Date: 18 - May - 2020 
***/

model M31

/* Global */

global {
	/* Building types matrix */
	int nb_building_types <- 9;
	matrix types <- matrix(["Home", "Industry", "Office",
							"School", "Shop" , "Supermarket",
							"Cafe", "Restaurant" , "Park"]);
	
	/* Time controllers */
	float stepDuration <- 3600#s;
	int timeElapsed <- 0 update:  int(cycle * stepDuration);
	float currentMinute <- 0.0 update: ((timeElapsed mod 3600#s))/60#s; 
	float currentHour <- 0.0 update: ((timeElapsed mod 86400#s))/3600#s;
	int currentDay <- int(0.0) update: int(((timeElapsed mod 31536000#s))/86400#s);
	
	/* Species variables */
	int individuals_number <- 1500;
	int nb_init_infected <- 10;
	bool contagionInTransport;
	float infectious_distance <- 3.0;
	
	int nbS <- individuals_number min:0 max: 2000;
	int nbE <- 0; 	
	int nbI <- 0;
	int nbR <- 0;
	float averageR0 <- 0.0 update: (individuals sum_of(each.R0)) / max(1, nbR + nbI);
	
	/* Loading Phuc Xa shape files */
	file road_file <- file("../includes/clean_roads.shp");
	file buildings_file <- file("../includes/buildings.shp");
	geometry shape <- envelope(envelope(road_file));	
	
	graph road_network;	
	map<road,float> road_weights;
	
	/* Policies types matrix and parameters initialized */
	int nb_policy_types <- 5;
	matrix policy_types <- matrix(["Total move freedom", "Total lockdown",
								   "Containment by ages" , "Close schools",
								   "Wear Masks"]);
	
	bool triggeredByTime <- false;
	bool triggeredByInfected <- false;
								   
	bool moveFreedom <- false;
	bool lockdown <- false;
	bool containmentByAge <- false;
	bool closeSchools <- false;
	bool requireToUseMask <- false;

	int policy_applied_time <- 10;
	int policy_applied_nb_infected <- 15;
	int nb_test <- 7;
	
	map<string,bool> isLocked;
	
	init {
		create road from: road_file;
		create building from: buildings_file;
		
		road_network <- as_edge_graph(road);
		road_weights <- road as_map (each::each.shape.perimeter);
		
		/* Get building types by randomness */
		loop build over: building {
			build.building_type <- types[rnd(nb_building_types-1)];
			
			if (build.building_type = "Home") {
				build.color <- #lime;
			}			
			if (build.building_type = "Industry" or "Office") {
				build.color <- #deepskyblue;
			}	
			if (build.building_type = "Shop" or "Supermarket") {
				build.color <- #yellow;
			}	
			if (build.building_type = "Cafe" or "Restaurant") {
				build.color <- #purple;
			}	
			if (build.building_type = "Park") {
				build.color <- #olive;
			}			
			if (build.building_type = "School") {
				build.color <- #red;
			}
			
		}
		
		loop i from: 0 to: nb_building_types-1 {
			isLocked[types[i]] <- false;
		}
		
		create LocalAuthority number: 1;
				
		/* Assign an agent of individual to one of the building */
		create individuals number: individuals_number {
			my_house <- one_of(building where (each.building_type = "Home"));
			my_workplace <- one_of(building where (each.building_type != "Home"));	
			my_school <- one_of(building where (each.building_type = "School"));	
			my_park	<- one_of(building where (each.building_type = "Park"));	
			my_supply <- one_of(building where (each.building_type = "Shop" or "Supermarket"));		
			location <- my_house.location;

			gender <- one_of(["male","female"]);
			age <- rnd(70) + 1;	
		}

		nbE <- 0;
		nbR <- 0;
		
		do init_epidemic();
				
		nbS <- individuals_number - nbI;
	}

	action init_epidemic {
		loop i from: 0 to: nb_init_infected {
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

species road {
	aspect default {
		draw shape color: #red border: #black;
	}
}

species building {
	rgb color <- #gray;		// Default color
	
	bool hasVirus <- false;
	int virus_lvl <- 0;
	int last3Day <- 0;
	
	string building_type;
	
	reflex virus_load {
		list<individuals> garrison <- (individuals overlapping(self));
		loop person over: garrison {
			ask person {
				if (person.isI) {
					myself.hasVirus <- true;
					myself.virus_lvl <- myself.virus_lvl + 1;
				}
			}		
		}
		
		if (last3Day != currentDay-2) {
			self.virus_lvl <- max(0, self.virus_lvl - 10);
			last3Day <- currentDay-2;
		}
	}
	
	reflex color_building {			
		if (hasVirus) {
			color <- #midnightblue;
		}
		
		if (self.virus_lvl = 0) {
			hasVirus <- false;
			
			if (building_type = "Home") {
				color <- #lime;
			}			
			if (building_type = "Industry" or "Office") {
				color <- #deepskyblue;
			}	
			if (building_type = "Shop" or "Supermarket") {
				color <- #yellow;
			}	
			if (building_type = "Cafe" or "Restaurant") {
				color <- #purple;
			}	
			if (building_type = "Park") {
				color <- #olive;
			}			
			if (building_type = "School") {
				color <- #red;
			}
		}
	}
	
	aspect default {
		draw shape color: color border: #black;
	}
}

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
	float R0 <- 0.0;
	
	int begin_work <- 7;
	int end_work <- 17;
	int begin_school <- 8;
	int end_school <- 16;
		
	building my_house;
	building my_workplace;
	building my_supply;
	building my_res;
	building my_park;
	building my_school;
	string gender;
	int age min: 0 max: 80;
		
	reflex moving {
		do wander speed: 0.25;
		if (flip(proba_infect)) 
		{
			do spread_disease();
		}
	} 
	
	reflex regain_health {
		do setRecovered();
	}
	
	reflex infect_others when: isI = true {		
		building myBuilding <- first(building overlapping(self));
		list<individuals> nearby_individuals <- (individuals overlapping(myBuilding)) where(each.isS = true);
		loop person over: nearby_individuals {
			if flip(proba_infect) {			
				R0 <- R0 + 1;	
				ask person {
					do setExposed();
				}
			}
		}		
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
	
	action environmentExposed {
		building cur_building <- first(building overlapping(self));
		if (cur_building.hasVirus = true) { 
			if (flip(proba_infect)) {
				do setExposed();
			}
		}
	}
	
	action setInfected {
		if (isE) and (exposedDay + incubationTime < currentDay) {
			isE <- false;
			
			nbE <- nbE - 1;
			nbI <- nbI + 1;
			
			color <- #red;
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
	
	action gotoLocation(building targetPlace) {
		bool arrived <- first(building overlapping(self)) = targetPlace;
		
		if (!arrived) {
			if (contagionInTransport) {
				do goto target: any_location_in(targetPlace) on: road_network speed: (rnd(100)+1) #m/#s;
			}
			else {
				location <- any_location_in(targetPlace);
			}			
		}
	}
	
	reflex go_child when: age <= 3 {
		// do nothing
	}
	
	reflex go_student when: age > 3 and age <= 22 {	
		bool isAtSchool <- first(building overlapping(self)) = my_school;
		bool isAtPark <- first(building overlapping(self)) = my_park;
		bool isAtHome <- first(building overlapping(self)) = my_house;
		
		if (!isLocked["School"] and currentHour >= begin_school and currentHour <= end_school) {
			if (!isAtSchool) {
				do gotoLocation(my_school);
			}
		}
		else if (!isLocked["Park"] and currentHour > end_school and currentHour <= end_work) {
			if (!isAtPark) {
				do gotoLocation(my_park);
			}
		}
		else {
			if(!isAtHome) {
  				do gotoLocation(my_house);  				
  			}
		}
	}
	
	reflex go_adult when: age > 22 and age <= 55 {		
		bool isAtWork <- first(building overlapping(self)) = my_workplace;
		bool isAtHome <- first(building overlapping(self)) = my_house;
		
		if (!isLocked[my_workplace.building_type] and currentHour >= begin_work and currentHour <= end_work) {
			if (!isAtWork) {
				do gotoLocation(my_workplace);
			}
		}
		else {
			if(!isAtHome) {
  				do gotoLocation(my_house);			
  			}
		}
	}
	
	reflex go_oldman when: age > 55 {
		// do nothing
		bool isAtSupply <- first(building overlapping(self)) = my_supply;
		
		if (currentHour <= end_work) {
			building targetLocation <- one_of(building);	
			if (!isLocked[targetLocation.building_type]) {		
				do gotoLocation(targetLocation);	
			}
		}						
		else if (currentHour > end_work and currentHour <= end_work+1) {
			if (!isAtSupply) {
				do gotoLocation(my_supply);
			}
		}
		else {
			do gotoLocation(my_house);
		}
	}
	
	reflex useMask when: requireToUseMask = true {
		self.proba_infect <- 0.05;
	}
	
	aspect default {
		draw circle(1.0) color: color;
	}
}

species LocalAuthority {				
	bool startPolicy <- false;
	
	reflex checkPolicy {
		if (triggeredByTime and currentDay >= policy_applied_time) {
			startPolicy <- true;
		}
		else {
			startPolicy <- false;
		}
			
		if (triggeredByInfected and nbI >= policy_applied_nb_infected) {
			startPolicy <- true;
		}
		else {
			startPolicy <- false;
		}
	}
		
	reflex applyPolicy when: (startPolicy) {
		if (moveFreedom) {
			loop i from: 0 to: nb_building_types-1 {
				isLocked[types[i]] <- false;
			}
			write("All people can now move freely");
		}
		
		if (lockdown) {
			loop i from: 0 to: nb_building_types-1 {
				isLocked[types[i]] <- true;
			}
					
			isLocked["Shop"] <- false;
			isLocked["Supermarket"] <- false;
			
			write("Lockdown is applied, except for Shop/Supermarket");
		}
		
		if (closeSchools) {
			isLocked["School"] <- true;
			write("Schools are now close!");
		}
		
		 
		if (requireToUseMask) {
			write("Mask is now required for all people!");
		}		

	}
}

species Policy {
	
}

/* Experiment */

experiment gui_exp type: gui {
	parameter "Number of people" var: individuals_number init: 500 min: 200 max: 2000;
	parameter "Initial number of infected" var: nb_init_infected init: 10 min: 1 max: 100;
	parameter "Contagion in transport" var: contagionInTransport init: false among: [true, false];
	
	parameter "Policy by time" var: triggeredByTime init: false among: [true, false];
	parameter "Policy by infected" var: triggeredByInfected init: false among: [true, false];
	
	parameter "Move Freedom" var: moveFreedom init: false among: [true, false];
	parameter "Lockdown" var: lockdown init: false among: [true, false];
	parameter "Close Schools" var: closeSchools init: false among: [true, false];
	parameter "Require Mask" var: requireToUseMask init: false among: [true, false];
	
	parameter "Number of tests per day" var: nb_test init: 10 min: 0 max: 1000;
	parameter "Time till policy" var: policy_applied_time init: 0 min: 0 max: 100;
	parameter "Infected till policy" var: policy_applied_nb_infected init: 1 min: 1 max:100;	
	
	output {
		display all_agents {
			species road aspect: default;
			species building aspect: default;
			species individuals aspect: default;
			species LocalAuthority;
		}
		display series_chart {
			chart "States of the agents" type: series style: line {
				datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.isS = true), individuals count (each.isE = true), 
														  individuals count (each.isI = true and !each.isE), individuals count (each.isR = true)] 
												  color: [#green, #orange, #red, #blue];
			}
		}
		
		monitor "Susceptible" value: nbS;
		monitor "Exposed" value: nbE;
		monitor "Infected" value: nbI;
		monitor "Recovered" value: nbR;
		monitor "Average R0" value: averageR0;
		monitor "Hour:" value: currentHour;
		monitor "Day:" value: currentDay;	
	} 
}