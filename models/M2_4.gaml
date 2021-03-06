/**
* Name: model2
* Based on the internal empty template. 
* Author: duc
* Tags: 
*/


model M2_4

/* Insert your model definition here */
global{
	shape_file buildings0_shape_file <- shape_file("../includes/buildings.shp");
	shape_file clean_roads0_shape_file <- shape_file("../includes/clean_roads.shp");
	geometry shape <- envelope(clean_roads0_shape_file);
	graph road_graph;
	int number_of_inhabitant <- 150;
	
	float step <- 1#mn;
	date starting_date <- date([2021,1,2,0,0,0]);
	
	int pandemic_duration <- 0;
	int number_people_infected <- 50;
	int number_of_virus <- 100;
	
	init{
		create inhabitants number: number_of_inhabitant{
			rdAge <- rnd(0,2);
			my_color <- ageColorList[rdAge];
			if(my_color = #aqua){
				is_adult <- true;
			}
			else if(my_color = #lawngreen){
				is_kid <- true;
			}
			else if(my_color = #mediumorchid){
				is_old <- true;
			}
			//Get random age
			if(is_adult = true){
				my_age <- rnd(22, 55);
			}
			else if(is_kid = true){
				my_age <- rnd(1, 21);
			}
			else if(is_old = true){
				my_age <- rnd(56, 100);
			}
			
			//Random gender
			
			rdGender <- rnd(0,1);
			my_gender <- genderChoiceList[rdGender];
			if(my_gender = "male"){
				is_male <- true;
			}
			else if(my_gender = "female"){
				is_female <- true;
			}
			
			// Contain virus or not
			/* 
			rdInfected <- rnd(0,1);
			if(rdInfected = 0){
				//is_infected <- false;
				epidemic_state <- "S";
			}
			if(rdInfected = 1){
				is_exposed_state <- true;
				is_susceptible_state <- false;
				
				my_color <- #gold;
				epidemic_state <- "E";
			}*/
		}
		loop i from: 0 to: number_people_infected - 1{
			ask one_of(inhabitants){
				is_susceptible_state <- false;
				is_exposed_state <- true;
				my_color <- #gold;
				epidemic_state <- "E";
			}
		}
		create buildings from: buildings0_shape_file{
			var <- [#darkgrey,#yellow,#green,#brown,#orange,#blue,#purple];
			rdIndex <- rnd(0,6);
			my_color <- var[rdIndex];
			if(my_color = #darkgrey){
				is_building <- true;
				if(have_people = false){
					int number_of_child <- rnd(0,3);
					int number_of_male_adult <- 1;
					int number_of_female_adult <- 1;
					int number_of_grand_father <- 1;
					int number_of_grand_mother <- 1;
										
					loop index from: 0 to: number_of_male_adult{
						ask one_of(inhabitants where(each.is_adult = true and each.my_gender="male")){
							if(self.location != myself.location and self.have_home = false){
								self.location <- any_location_in(myself);
								self.have_home <- true;
								self.houseLocation <- location;
								break;
							}
						}
					}
					
					
					loop index from: 0 to: number_of_female_adult{
						ask one_of(inhabitants where(each.is_adult = true and each.my_gender="female")){
							if(self.location != myself.location and self.have_home = false){
								self.location <- any_location_in(myself);
								self.have_home <- true;
								self.houseLocation <- location;
								break;
							}
						}
					}
					
					loop index from: 0 to: number_of_grand_father{
						ask one_of(inhabitants where(each.is_old = true and each.my_gender="male")){
							if(self.location != myself.location and self.have_home = false){
								self.location <- any_location_in(myself);
								self.have_home <- true;
								self.houseLocation <- location;
								break;
							}
						}
					}
					
					loop index from: 0 to: number_of_grand_mother{
						ask one_of(inhabitants where(each.is_old = true and each.my_gender="female")){
							if(self.location != myself.location and self.have_home = false){
								self.location <- any_location_in(myself);
								self.have_home <- true;
								self.houseLocation <- location;
								break;
							}
						}
					}
					
					loop index from: 0 to: number_of_child{
						ask one_of(inhabitants where(each.is_kid = true )){
							if(self.location != myself.location and self.have_home = false){
								self.location <- any_location_in(myself);
								self.have_home <- true;
								self.houseLocation <- location;
								break;
							}
						}
					}
					nb_people <- number_of_child + number_of_male_adult + number_of_female_adult + number_of_grand_father + number_of_grand_mother;
				}
			}
			else if(my_color = #yellow){
				is_workspace <- true;
			}
			else if(my_color = #green){
				is_park <- true;
			}
			else if(my_color = #brown){
				is_coffeeshop <- true;
			}
			else if(my_color = #orange){
				is_restaurant <- true;
			}
			else if(my_color = #blue){
				is_school <- true;
			}
			else if(my_color = #purple){
				is_gorcery <- true;
			}
		}
		create roads from: clean_roads0_shape_file;
		do init_other_location();
		create virus number: number_of_virus{
			location <- any_location_in(one_of(roads));
		}
		road_graph <- as_edge_graph(roads);
	}
	
	action init_other_location{
		buildings workspace;
		buildings park;
		buildings coffeeshop;
		buildings restaurant;
		buildings school;
		buildings gorcery;
		loop i from: 0 to: number_of_inhabitant {
			ask one_of(inhabitants){
					workspace <- one_of(buildings where(each.is_workspace = true));
					park <- one_of(buildings where(each.is_park = true));
					coffeeshop <- one_of(buildings where(each.is_coffeeshop = true));
					restaurant <- one_of(buildings where(each.is_restaurant = true));
					school <- one_of(buildings where(each.is_school = true));
					gorcery <- one_of(buildings where(each.is_gorcery = true));
					
					workLocation <- any_location_in(workspace);
					parkLocation <- any_location_in(park);
					coffeeLocation <- any_location_in(coffeeshop);
					restaurantLocation <- any_location_in(restaurant);
					schoolLocation <- any_location_in(school);
					gorceryLocation <- any_location_in(gorcery);
					
				}
		}
	}
	reflex dd{
		write current_date;
		write current_date.hour;
		write "--------------";
	}
}
species inhabitants skills:[moving]{
    list ageColorList <- [#aqua,#lawngreen,#mediumorchid];
    list genderChoiceList <- ["male","female"];
	rgb my_color <- #blue;
	int rdAge;
	bool is_adult;
	bool is_kid;
	bool is_old;
	
	int my_age;
	int rdGender;
	string my_gender;
	bool is_male;
	bool is_female;
	
	bool have_home <- false;
	
	int rdInfected;
	
	bool is_susceptible_state <- true;
	bool is_infected_state <- false;
	bool is_exposed_state <- false;
	bool is_recovery_state <- false;
	
	string epidemic_state <- "S";
	
	point houseLocation;
	point workLocation;
	point coffeeLocation;
	point schoolLocation;
	point parkLocation;
	point restaurantLocation;
	point gorceryLocation;
	
	point target <- nil;
	
	int count_date_expose <- 0;
	int count_date_infectious <- 0;
	
	// Adult schedule
	reflex goToCoffeShop when: (is_adult = true and current_date.hour = 6){
		target <- any_location_in(coffeeLocation);
		do goto target: target on: road_graph;
	}
	
	reflex goToWork when: (is_adult = true and current_date.hour = 7){
		target <- any_location_in(workLocation);
		do goto target: target on: road_graph;
	}
	
	reflex adultGoShopping when: (is_adult = true and current_date.hour = 17){
		target <- gorceryLocation;
		do goto target: target on: road_graph;
	}
	
	reflex goRestaurant when: (is_adult = true and current_date.hour = 19){
		target <- restaurantLocation;
		do goto target: target on: road_graph;
	}
	
	//Kid schedule
	reflex goToSchool when: (is_kid = true and current_date.hour = 7){
		target <- schoolLocation;
		do goto target: target on: road_graph;
		
		if(location = target){
			target <- houseLocation;
		}
	}
	
	reflex kidGoToPark when: (is_kid = true and current_date.hour = 16){
		target <- parkLocation;
		do goto target: target on: road_graph;
		
		if(location = target){
			target <- houseLocation;
		}
	}
	
	//Retire people/ old people
	reflex oldPlpGoToPark when: (is_old = true and (current_date.hour = 5 or current_date.hour = 16)){
		target <- parkLocation;
		do goto target: target on: road_graph;
	}
	
	reflex oldPlpGoShopping when: (is_old = true and current_date.hour = 7){
		target <- gorceryLocation;
		do goto target: target on: road_graph;
	}
	
	reflex oldPlpGoHone when: (is_old = true and current_date.hour = 10){
		target <- houseLocation;
		do goto target: target on: road_graph;
	}
	
		//Infected process 
		// one day is 24 hour -> 3 days is 72 hour
		// one day is 24 hour -> 10 days is 240 hour
		// one day is 24 hour -> 30 days is 720 hour
	reflex dynamicTurnBad when:(count_date_expose >= 72) and (count_date_expose <= 240) and (epidemic_state = "E") and (is_exposed_state = true){
		write "Change bad state";
		epidemic_state <- "I";
		
		is_infected_state <- true;
		is_exposed_state <- false;
		is_susceptible_state <- false;
		
		my_color <- #red;
		//number_people_infected <- number_people_infected + 1;
		count_date_infectious <- count_date_expose + 1;
		
	}
	
	reflex dynamicTurnGood when: (count_date_infectious >= 240) and (count_date_infectious <= 720) and (epidemic_state = "I") and (is_infected_state = true){
		write "Change good state";
		epidemic_state <- "R";
		
		is_infected_state <- false;
		is_recovery_state <- true;
		
		my_color <- #lightblue;
		count_date_expose <- 0;
		count_date_infectious <- 0;
	}

	reflex infect when:(epidemic_state = "I"){
		ask inhabitants at_distance 3.0 {
			if (self.epidemic_state = "S"){
				
				self.is_susceptible_state <- false;
				self.is_exposed_state <- true;
				self.epidemic_state <- "E";
				
				self.my_color <- #gold;
			}
		}
	}
	
	reflex infect_in_one_building when:(epidemic_state = "I"){
		buildings my_location <- first(buildings overlapping(self));
		list<inhabitants> list_colleague <- (inhabitants overlapping(my_location)) where(each.is_susceptible_state = true);
		loop person over: list_colleague{
			ask person{
				person.is_susceptible_state <- false;
				person.is_exposed_state <- true;
				epidemic_state <- "E";
				person.my_color <- #gold;
			}
		}
	}
	
	reflex increaseExposeDate when: epidemic_state = "E"{
		if(count_date_expose = 240){
			count_date_expose <- 0;
		}
		if(cycle mod 60 = 0 and cycle != 0){
			count_date_expose <- count_date_expose + 1;
		}
	}
	
	reflex increaseInfectiousDate when: epidemic_state = "I"{
		if(count_date_infectious = 720){
			count_date_infectious <- 0;
		}
		if(cycle mod 60 = 0 and cycle != 0){
			count_date_infectious <- count_date_infectious + 1;
		}
		pandemic_duration <- count_date_infectious;
	}
	
	
	// End of the day
	reflex goHone when: (target != nil and current_date.hour = 18) or (is_adult = true and current_date.hour = 21){
		target <- houseLocation;
		do goto target: target on: road_graph;
		if(location = target){
			target <- nil;
		}
	}
	
	aspect goem{
		draw circle(4) color: my_color;
	}
}

species buildings{
	list var;
	int rdIndex;
	rgb my_color;
	bool is_building <- false;
	bool is_workspace <- false;
	bool is_park <- false;
	bool is_coffeeshop <- false;
	bool is_restaurant <- false;
	bool is_school <- false;
	bool is_gorcery <- false;
	bool have_people <- flip(0.5);
	int nb_people <- 0;
	int nb_virus <- 0;
	rgb old_color;
	bool has_virus <- false;
	//bool test <- true;
	int count_life_time <- 0;
	
	reflex virus_load{
		list<inhabitants> list_of_people <- (inhabitants overlapping(self));
		loop person over: list_of_people{
			if(person.is_infected_state = true){
				//myself.old_color <- myself.my_color; 
				//write "Detect infected people";
				has_virus <- true;
				nb_virus <- nb_virus + 1;
				//test <- false;
			}
		}
	}
	
	reflex infect when: has_virus = true{
		list<inhabitants> list_of_people <- (inhabitants overlapping(self));
		loop person over: list_of_people{
			if(person.is_susceptible_state = true){
				//myself.old_color <- myself.my_color; 
				//write "Infected people";
				
				person.is_susceptible_state <- false;
				person.is_exposed_state <- true;
				person.epidemic_state <- "E";
				
				person.my_color <- #gold;
				
			}
		}
	}
	
	reflex decrease_virus when: has_virus = true and count_life_time = 24{
		//write "Decrease virus";
		nb_virus <- max(0, nb_virus - 1);
	}
	
	reflex death when: count_life_time = 48{
		//write "virus dead";
		nb_virus <- 0;
	}
	
	reflex count_life_time when: has_virus = true{
		if(count_life_time = 48){
			count_life_time <- 0;
		}
		if(cycle mod 60 = 0){
			count_life_time <- count_life_time + 1;
		}
	}
	
	reflex color_building {			
		if (has_virus) {
			my_color <- #black;
		}
		if (self.nb_virus = 0) {
			has_virus <- false;
			
			if (is_building = true) {
				my_color <- #darkgrey;
			}			
			if (is_workspace = true) {
				my_color <- #yellow;
			}	
			if (is_park = true) {
				my_color <- #green;
			}	
			if (is_coffeeshop = true) {
				my_color <- #brown;
			}	
			if (is_restaurant = true) {
				my_color <- #orange;
			}			
			if (is_school = true) {
				my_color <- #blue;
			}
			if (is_gorcery = true) {
				my_color <- #purple;
			}
		}
	}
			
	//rgb my_color;
	aspect goem{
		draw shape color: my_color;
	}

}

species roads{
	aspect goem{
		draw shape color:#black;
	}
}

species virus skills:[moving]{
	
	rgb my_color <- #red;
	bool is_live <- true;
	int count_life_time <- 0;
	
	reflex move{
		do wander speed: 0.005;
	}
	
	
	reflex infect when: is_live = true{
		ask inhabitants at_distance 3.0 {
			if (self.epidemic_state = "S"){
				
				self.is_susceptible_state <- false;
				self.is_exposed_state <- true;
				self.epidemic_state <- "E";
				
				self.my_color <- #gold;
			}
		}
	}
	// virus can life 3 days on the environment
	 
	reflex death when: count_life_time = 72{
		is_live <- false;
		my_color <- #black;
		do die;
	}
	
	reflex count_life_time when: is_live = true{
		if(count_life_time = 72){
			count_life_time <- 0;
		}
		if(cycle mod 60 = 0){
			count_life_time <- count_life_time + 1;
		}
	}
	
	aspect goem{
		draw triangle(4) color: my_color;
	}
}

experiment M2_4{
	output{
		display map{
			species buildings aspect:goem;
			species roads aspect: goem;
			species inhabitants aspect: goem;
			species virus aspect: goem;
		}
		monitor "nb susceptible people" value: inhabitants count(each.is_susceptible_state = true);
		monitor "nb exposed people" value: inhabitants count(each.is_exposed_state = true);
		monitor "nb infected people" value: inhabitants count(each.is_infected_state = true);
		monitor "nb recovery people" value: inhabitants count(each.is_recovery_state = true);
	}
}

experiment E2_4{
	output{
		display Epidemic_plotting {
			chart "States of the agents" type: series style: line {
				datalist ["#S", "#E", "#I", "#R"] value: [inhabitants count (each.is_susceptible_state = true), inhabitants count (each.is_exposed_state = true), 
														  inhabitants count (each.is_infected_state = true), inhabitants count (each.is_recovery_state = true)] 
												  color: [#blue, #gold, #red, #lightblue];
			}
		}
		monitor "nb susceptible people" value: inhabitants count(each.is_susceptible_state = true);
		monitor "nb exposed people" value: inhabitants count(each.is_exposed_state = true);
		monitor "nb infected people" value: inhabitants count(each.is_infected_state = true);
		monitor "nb recovery people" value: inhabitants count(each.is_recovery_state = true);
	}
}


