/**
* Name: model1
* Based on the internal empty template. 
* Author: duc
* Tags: 
*/


model M1

/* Insert your model definition here */
// Each inhabitant have 2 building house and workingplace(random)
// 7AM go to work 5PM go home
/* Step
 * 
 * 
 */
global{	
	int number_of_people <- 500;
	int number_of_infected_people <- 1;
	float dangerous_distance <- 0.5#m;
	int pandemic_duration <- 0;
	int number_people_infected <- 0;
	int start_pandemic_date <-0;
	int end_pandemic_date <- 0;
	init{
		//create buildings from: buildings0_shape_file with: [height_building::int(rnd(10,29))];
		create individuals number: number_of_people;
		loop i from: 0 to: number_of_infected_people - 1{
			ask one_of(individuals){
				is_infected <- true;
				my_color <- #yellow;
				epidemic_state <- "E";
				count_date_expose <- 1;
			}
		}
	}
}

species individuals skills:[moving]{
	bool is_infected <- false;
	string epidemic_state <- "S";
	rgb my_color <- #blue;
	int count_date_expose <- 0;
	int count_date_infectious <- 0;
	
	reflex move{
		do wander speed: 1.0;
	}
	
	//Expose to infectious
	reflex dynamicTurnBad when:(count_date_expose >= 72) and (count_date_expose <= 240) and (epidemic_state = "E"){
		write "Change bad state";
		epidemic_state <- "I";
		is_infected <- true;
		my_color <- #red;
		count_date_infectious <- count_date_expose + 1;
		
	}
	
	//Infectious to recovery
	reflex dynamicTurnGood when: (count_date_infectious >= 240) and (count_date_infectious <= 720) and (epidemic_state = "I"){
		write "Change good state";
		epidemic_state <- "R";
		is_infected <- false;
		my_color <- #green;
		count_date_expose <- 0;
		count_date_infectious <- 0;
	}
	
	reflex check_epidemic_duration when: epidemic_state = "I"{
		int count_infect_plp <- individuals count (each.epidemic_state = "I");
		if(count_infect_plp = 1){
			start_pandemic_date <- current_date.day;
			write "start_pandemic_date: " + start_pandemic_date;
		}
		
		if(count_infect_plp = 0){
			end_pandemic_date <- current_date.day;
			write "end_pandemic_date: " + end_pandemic_date;
			pandemic_duration <- abs(end_pandemic_date - start_pandemic_date);
		}
		
		/* 
		if(count_infect_plp != 0){
			//end_pandemic_date <- current_date.day;
			//pandemic_duration <- abs(end_pandemic_date - start_pandemic_date);
			pandemic_duration <- pandemic_duration + 1;
		}*/
	}
	

	reflex infect when:(epidemic_state = "I"){
		ask individuals at_distance 3.0 {
			if (self.epidemic_state = "S"){
				self.is_infected <- true;
				self.epidemic_state <- "E";
				self.my_color <- #yellow;
			}
		}
	}
	
	
	//Counter of expose duration
	// one day is 24 hour -> 3 days is 72 hour
	// one day is 24 hour -> 10 days is 240 hour
	// one day is 24 hour -> 30 days is 720 hour
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
		
	}
	
	
	
	aspect infor{
		draw circle(0.5) color: my_color;
	}
}

experiment M1_1 type: gui{
	
	output{
		display M1_1{
			species individuals aspect:infor;
		}
		
	}
}

experiment E1_1 type: gui{
	parameter "Number of people: " var: number_of_people min:10 max: 1000 step: 10;
	parameter "Number of infected people: " var: number_of_infected_people min: 1 max: 50 step: 10;
	init{
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::1];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::2];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::3];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::4];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::5];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::6];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::7];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::8];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::9];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::10];
	}
	output{
		display E1_1{
			chart "Ch" type:series{
				datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.epidemic_state = "S"), individuals count (each.epidemic_state = "E"), 
														  individuals count (each.epidemic_state = "I"), individuals count (each.epidemic_state = "R")] 
												  color: [#blue, #yellow, #red, #green];
			}
		}
		
	}
}

experiment E1_2 type: gui{
	parameter "Number of people: " var: number_of_people min:200 max: 2000 step: 200;
	parameter "Number of infected people: " var: number_of_infected_people min: 1 max: 50 step: 10;
	
	init{
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
		create simulation with:[number_of_people::number_of_people,number_of_infected_people::number_of_infected_people,seed::seed];
	}
	
	output{
		display E1_2{
			chart "Ch" type:series{
					datalist ["#S", "#E", "#I", "#R"] value: [individuals count (each.epidemic_state = "S"), individuals count (each.epidemic_state = "E"), 
														  individuals count (each.epidemic_state = "I"), individuals count (each.epidemic_state = "R")] 
												  color: [#blue, #yellow, #red, #green];
			}
		}
		
	}
}

experiment E1_3 type: batch until: (individuals count(each.epidemic_state="I") = 0) and (individuals count(each.epidemic_state="E") = 0){
	parameter "Number of people: " var: number_of_people min:200 max: 2000 step: 200;
	parameter "Number of infected people: " var: number_of_infected_people init:10 min: 10 max: 10;
	
	init {
		save ["Number of people","duration"] to: "data.csv" type: "csv" rewrite: true header: false;
	}
	
	reflex saving{
		ask simulations{
		save [self.number_of_people, self.pandemic_duration] to: "data.csv" type: "csv" rewrite: false;
		}
	}

}