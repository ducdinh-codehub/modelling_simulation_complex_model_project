/***
* Name: M2-3
* Author: Huynh Vinh Nam
* Date: 12 - May - 2020 
***/

model M23

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
	int nb_init_infected <- 1;
	bool contagionInTransport;
	float infectious_distance <- 3.0;
	
	int nbS <- individuals_number min: 0 max: 2000;
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
	
	string building_type;
	
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
		
		if (currentHour >= begin_school and currentHour <= end_school) {
			if (!isAtSchool) {
				do gotoLocation(my_school);
			}
		}
		else if (currentHour > end_school and currentHour <= end_work) {
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
		
		if (currentHour >= begin_work and currentHour <= end_work) {
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
			do gotoLocation(targetLocation);
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
	
	aspect default {
		draw circle(1.0) color: color;
	}
}

/* Experiment */

experiment gui_exp type: gui {

	
	output {
		display all_agents {
			species road aspect: default;
			species building aspect: default;
			species individuals aspect: default;
		}
		display series_chart {
			chart "States of the agents" type: series style: line {
				datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.isS = true), individuals count (each.isE = true), 
														  individuals count (each.isI = true and !each.isE), individuals count (each.isR = true)] 
												  color: [#green, #orange, #red, #blue];
			}
		}
		display R0_chart {
			chart "R0" type: series style: line {
				datalist ["R0 Min", "R0 Max", "R0 Average"] 
				value: [individuals where (each.isS or each.isR) min_of(each.R0), individuals where (each.isI) max_of(each.R0), averageR0] 
				color: [#green, #orange, #red, #teal, #blue];
			}
		}
		
		display Population_gender {
			chart "Population gender" type: histogram {
				datalist ["Male", "Female"] value:[length(individuals where(each.gender="male")), length(individuals where(each.gender="female"))];
			}								
		}
		
		display Population_by_age {
			chart "Population by age" type: histogram {
				datalist ["Childen", "Students", "Adults", "Old man"] 
				value:[length(individuals where(each.age <= 3)), 
					   length(individuals where(3 < each.age and each.age <= 22)),
					   length(individuals where(22 < each.age and each.age <= 55)), 
					   length(individuals where(55 < each.age))
					  ];
			}
		}
		
		monitor "Susceptible" value: nbS;
		monitor "Exposed" value: nbE;
		monitor "Infected" value: nbI;
		monitor "Recovered" value: nbR;
		monitor "Hour:" value: currentHour;
		monitor "Day:" value: currentDay;	
	} 
}