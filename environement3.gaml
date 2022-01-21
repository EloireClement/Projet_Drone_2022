/**
* Name: environement
* Environement de base pour nos drones 
* Author: Clément Eloire
* Tags: 
*/


model drone

global{
	float dist_security <- 2.0;
	int height_grid <- 50;
	int width_grid <- 100;
	int nb_intru <- 0;
	int nb_drone <- 10;
	int nb_obstacle <- 0;
	geometry shape <- rectangle(width_grid, height_grid);
	reflex update {
		ask drone_grid{
            self.crit <-  self.crit+1 ;}
        ask drone_grid {
        do update_crit;
    }
       

}
	init {
		create base number: 1;
		create drone number: nb_drone;
	}
}

species drone skills: [moving]{
	
	
	//list close_drones <-  agents_at_distance(dist_security) update: agents_at_distance(dist_security) ;
	//drone nearest_drone <- drone closest_to self update: drone closest_to self;
	
	drone_grid my_cell;
	matrix perception <- 0.5 as_matrix({9,9});

	image_file icon <- image_file("../includes/drone.png") ;

	init {
		my_cell <- one_of (drone_grid) ;
		location <- my_cell.location;
		}
		
	aspect square {
		draw square(2) color: #black;
	}
	
	aspect drone {
		draw icon size: 1;
	}
	
	reflex basic_move{
		//attirance par criticité
		//répulsivité par les autres drones
		//choisir une direction

		
		
		my_cell.occupe <- 1;
	    my_cell <- one_of (my_cell.neighbors1) ;
	    my_cell.occupe <- 0;
	    
	    location <- my_cell.location ;
	    //if (nearest_drone in close_drones) {
		//	my_cell <- drone_grid closest_to base[0];
		//}
	}
	

	
	reflex check_crit { //ici
		//drone_grid worst_neigh <- (my_cell.neighbors4) with_max_of (each.crit);
	   		int num_line <- 0;
	   		int num_col <-0;
	   		
	    	loop cellToCheck over: my_cell.neighbors4 {
	    		if (cellToCheck.crit > 50) {
	    			cellToCheck.crit <- 0;
	    		}
	    		num_col <- num_col + 1;
	    		if (num_col = 10) { num_line <- num_line + 1; }
	    		
	    			perception[num_line,num_col] <- cellToCheck.occupe + cellToCheck.crit/100;
	    		}
	    	}
    	
    	}

	


species base {
	rgb color <- #pink;
	aspect square {
		draw square(4) color: color border: #black;
	}
	init{
		location <- {0.0,0.0};
	}
}
grid drone_grid width: width_grid height: height_grid neighbors: 8 {
	rgb color <- rgb(255,255,255);
	int crit <- 0 max: 100;
	int occupe <- 1;
	int redness <- 0;
	list<drone_grid> neighbors1  <- (self neighbors_at 1);
	list<drone_grid> neighbors4  <- (self neighbors_at 4);
    action update_crit {
    	redness <- int((crit)*2.55);
    	color <- rgb(255,255-redness,255-redness);
    }
}


experiment name type: gui {

	
	// Define parameters here if necessary
	parameter "Hauteur de la grille" var: height_grid min: 10 max: 100 step: 1;
	parameter "Largeur de la grille" var: width_grid min: 10 max: 200 step: 1;
	parameter "Nombre d'intrus a faire apparaitre" var: nb_intru min:0 among: [0, 10, 20, 50];
	parameter "Nombre de drones" var: nb_drone min:0 among: [10, 20, 50, 100];
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
	// Define inspectors, browsers and displays here
	display test {
		
		grid drone_grid border: #black;
		species base aspect: square;
		species drone aspect: drone;
		}
	}
	// inspect one_or_several_agents;
	//
	// display "My display" { 
	//		species one_species;
	//		species another_species;
	// 		grid a_grid;
	// 		...
	// }

	
}