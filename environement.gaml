/**
* Name: environement
* Environement de base pour nos drones 
* Author: Clément Eloire
* Tags: 
*/


model drone

global{
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
	rgb color <- rgb(255, 255,255);
	int crit <- 1;
    action update_crit {
    if (crit > 100) {
        color <- #red;
    } else if (crit > 50 ) {
        color <- #yellow;
    } else if (crit > 0) {
        color <- #green;
    }
    }
}


experiment name type: gui {

	
	// Define parameters here if necessary
	parameter "Hauteur de la grille" var: height_grid min: 10 max: 100 step: 1;
	parameter "Largeur de la grille" var: width_grid min: 10 max: 200 step: 1;
	parameter "Nombre d'intrus a faire apparaitre" var: nb_intru min:0 among: [0, 10, 20, 50];
	parameter "Nombre de drones" var: nb_drone min:0 among: [10, 20, 50, 100];
	parameter "Largeur de la grille" var: width_grid min: 0 max: 1000 step: 1;
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
	// Define inspectors, browsers and displays here
	display test {
		
		grid drone_grid lines: #black;
		species base aspect: square;
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
}