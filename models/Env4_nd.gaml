/**
* Name: environement
* Environement de base pour nos drones 
* Author: Clément Eloire
* Tags: 
*/

model drone


//---------------------------------------------------------------------------------------//
//										GLOBAL 											 //
//---------------------------------------------------------------------------------------//
global{
	
	float spawn_rate <- 0.001; // 1 chance sur 100 pour l'apparition d'intru sur une case avec criticité de plus de 200
	int seuil_spawn <- 200;
	int max_charge <- 800;
	int height_grid <- 50;
	int width_grid <- 100;
	int nb_drone <- 10;
	int crit_intru <- 100;
	int base_x <- 5;
	int base_y <-5;
	bool move_random <- false;
	
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
		//create intru number: 5;
	}
}
//---------------------------------------------------------------------------------------//
//										AGENT_MOBILE 									 //
//---------------------------------------------------------------------------------------//
species agent_mobile {
	
	int direction;
	drone_grid my_cell;
	int nord <- 0;
	int sud <- 0;
	int est <- 0;
	int ouest <- 0;
	
	int x update: my_cell.grid_x;
	int y update: my_cell.grid_y;
	
	int x_case_est min:0 max: width_grid - 1 update: x + 1;
	int x_case_ouest min:0 max: width_grid - 1 update: x - 1;

	int y_case_nord min:0 max: height_grid - 1 update: y -1;
	int y_case_sud min:0 max: height_grid - 1 update: y +1;
	
	//se deplacer sur une des positions adjacentes à la position courante : Nord Sud Est Ouest 
	action se_deplacer{
		switch (direction mod 360){
			//ouest
			match 90 {  

					my_cell <- drone_grid({x_case_ouest , y});
		    		location <- my_cell.location ;
	    		
	    			}	
	    	//nord
			match 180 {  

					my_cell <- drone_grid({x , y_case_nord});
		    		location <- my_cell.location ;
	  
	    			}
			//est
			match 270 { 
				my_cell <- drone_grid({x_case_est , y});
	    		location <- my_cell.location ;
			}
			//sud
			match 0 { 
				my_cell <- drone_grid({x , y_case_sud});
	    		location <- my_cell.location ;
			}
		}
	}
}

//A Utiliser avec la version 1.8.2
//---------------------------------------------------------------------------------------//
//								INTRU 													 //
//---------------------------------------------------------------------------------------//


/*species intru parent: agent_mobile{



    reflex basic_move{
        do se_deplacer();
        //my_cell.crit <- my_cell.crit + crit_intru;
    }

    reflex update_dir when: every(10#cycles){
        direction <- rnd(0,270,90); 
    }

    init{
        direction <- rnd(0,270,90);
    }
    image_file icon <- image_file("../includes/intru.png") ;
    aspect intru {
        draw icon size: 1;
    }

}*/



//A Utiliser avec les version antérieur à la 1.8.2
//---------------------------------------------------------------------------------------//
//								INTRU 													 //
//---------------------------------------------------------------------------------------//



species intru {
	drone_grid my_cell;
	int direction ;
	
	
	reflex update_dir when: every(10#cycles){
		direction <- rnd(0,270,90); 
	}

	init{
		direction <- rnd(0,270,90);
	}
	image_file icon <- image_file("../includes/intru.png") ;
	aspect intru {
		draw icon size: 1;
	}



	reflex basic_move{
		switch (direction mod 360){
			//Gauche
			match 90 {  
				if (my_cell.grid_x - 1 != -1){
					my_cell <- drone_grid({my_cell.grid_x - 1 , my_cell.grid_y});
		    		location <- my_cell.location ;
	    		}
	    			}	
	    	//Haut
			match 180 {  
				if (my_cell.grid_y - 1 != -1){
					my_cell <- drone_grid({my_cell.grid_x , my_cell.grid_y -1});
		    		location <- my_cell.location ;
	    		}
	    			}
			//Droite
			match 270 { 
				my_cell <- drone_grid({my_cell.grid_x +1 , my_cell.grid_y  });
	    		location <- my_cell.location ;
			}
			//Bas
			match 0 { 
				my_cell <- drone_grid({my_cell.grid_x  , my_cell.grid_y + 1});
	    		location <- my_cell.location ;
			}
		
		}
	}
	
}

//---------------------------------------------------------------------------------------//
//										BASE 											 //
//---------------------------------------------------------------------------------------//

species base {
	
	//donner de l'energie en 20 cycles quand un drone est à la base, les faire rester
	//donner rentrer_base - false - aux drones qui arrivent
	
	
	drone_grid base_cell;
	float seuil_rappel <- 0.30;
	list<int> energies_drones update: drone collect each.energie;

	int nb_slot <- 20 min: 1 max: 20;
	list<drone> drone_en_charge update: drone where ((each.my_cell.diff_base_x + each.my_cell.diff_base_y)<2) ;
	
	image_file icon <- image_file("../includes/upslogo.jpg") ;
    aspect ups {
        draw icon size: 4;
    }
	init{
		base_cell <- drone_grid[base_x,base_y];
		//location <- {0.0,0.0};
		location <- base_cell.location;
	}
	
	reflex signal {
		int i <- 0;
		loop energie over: energies_drones {
			
			if (energie < max_charge * seuil_rappel and length(drone_en_charge)<nb_slot) {
				ask drone[i] {
					rentrer_base <- true;
				}
			}
			i <- i+1;
		}
	}
	
	reflex recharge when: !empty(drone_en_charge) {
		color <- #chartreuse;
	}
	
	
}

//---------------------------------------------------------------------------------------//
//										DRONE 											 //
//---------------------------------------------------------------------------------------//

species drone parent: agent_mobile{
	
	
	//recharger quand on est dans la base

	bool rentrer_base <- false;

	int intru_caught <- 0;
	//float lastheading;

	int energie min: 0 max: max_charge;
	int temps <- 0;
	list All_min; //liste de tout les index minimaux

	image_file icon <- image_file("../includes/drone.png") ; //intru inside each <-> les intrus dans chaque case
	list<intru> intru_at_sight <- nil update: (my_cell.neighbors2 where (!empty(intru inside each))) collect one_of(intru inside each);
	int compteur <- 0;
	drone_grid pos_base <- drone_grid({base_x,base_y});
	
	init {
		energie <- int(max_charge/4 + rnd(3*max_charge/4));
		my_cell <- one_of (drone_grid);
		x <- my_cell.grid_x;
		y <- my_cell.grid_y;
		location <- my_cell.location;
	}
		
	
	aspect drone {
		draw icon size: 1;
	}
	
	reflex recharger when: rentrer_base  and my_cell.diff_base_x + my_cell.diff_base_x < 2 {
		if temps = 20{
			energie <- max_charge;
			rentrer_base <- false;
			temps <- 0;
		}else{temps <- temps + 1;}
		
	}
	
	
	reflex rentrer when: energie > 0 and rentrer_base {
		//utiliser diff_base_x et diff_base_y pour trouver la case a mettre dans direction 
		// aller à la direction trouvée en se déplaçant
		nord <- 0;
		sud <- 0;
		est <- 0;
		ouest <- 0;
		
		All_min <- [];
		compteur <-0;
		
		drone_grid cell_est <- drone_grid({x_case_est , y });
		drone_grid cell_ouest <- drone_grid({x_case_ouest  , y });
		drone_grid cell_nord <- drone_grid({x , y_case_nord});
		drone_grid cell_sud <- drone_grid({x , y_case_sud});
		
		est <- cell_est.diff_base_x + cell_est.diff_base_y; //somme de diffx et diffy pour la case de droite
		ouest <- cell_ouest.diff_base_x + cell_ouest.diff_base_y;
		nord <- cell_nord.diff_base_x + cell_nord.diff_base_y;
		sud <- cell_sud.diff_base_x + cell_sud.diff_base_y;
		
		
		//probleme quand le drone est collé au bord
		
	    map liste <- [0::270,1::90,2::180 ,3::0];
	    
	    list inter <- [est , ouest, nord ,sud];
	    
	    list clef  <- inter all_indexes_of ( (inter min_of (each))); //valeur min 
	    
	    
	    //write clef;
	    loop valeur over: clef{
	    	//write liste[valeur] ;
	    		add liste[valeur] at: compteur to: All_min;
	    		compteur <- compteur + 1;
	    		
	    }
	    direction <- int(one_of(All_min));
	    
	    do se_deplacer();
	    
	    
		
		energie <- energie - 1;
	}
	
	//reflex arreter when: intru overlaps one_of (my_cell.neighbors1){
	//	ask one_of (intru in my_cell.neighbors1) { do die; }
	//}
	reflex catch_intru when: !empty(intru_at_sight) and energie > 0{
		ask intru_at_sight[0] {
			do die;
		}
		intru_caught <- intru_caught + 1;
	}
	
	
	
	
	reflex basic_move when: energie > 0 and not(rentrer_base){
		if (move_random){
			direction <- rnd(0,270,90);
		}
		else {
			nord <-0;
			sud <- 0;
			est<-0;
			ouest<-0;
			
			loop cellToCheck over: my_cell.neighbors4 {
		    		//Maj Bas
		    		if (cellToCheck.grid_y > y ){
		    			
		    			sud <- sud + cellToCheck.crit;
		    		}
		    		//Maj Haut
		    		if (cellToCheck.grid_y < y ){
		    		
		    			nord <- nord + cellToCheck.crit;
		    		}
		    		//maj Gauche
		    		if (cellToCheck.grid_x < x ){
		    			
		    			ouest <- ouest + cellToCheck.crit;
		    		}
		    		//MAJ DROITE
		    		if (cellToCheck.grid_x > x){
		    			
		    			est <- est + cellToCheck.crit;
		    		}
		    		
	
		    	}
		    map liste <- [270::est,90::ouest,180::nord ,0::sud];
		    direction <- int(liste index_of (liste max_of (each)));
	    }
	    //direction <- 90;
		
		do se_deplacer();
		
		energie <- energie - 1;
	/*  if (nearest_drone in close_drones) {
			my_cell <- drone_grid closest_to base[0];
		}*/

	}
	
	reflex check_crit when: energie > 0{
		//drone_grid worst_neigh <- (my_cell.neighbors4) with_max_of (each.crit);
		

	    	//matrix matrice <- matrix(my_cell.neighbors4);
	    	//set matrice <- #blue;
	    	loop cellToCheck over: my_cell.neighbors2 {
	    		cellToCheck.crit <- 0;
	    	}
			
    }
	
}

//---------------------------------------------------------------------------------------//
//										GRILLE 											 //
//---------------------------------------------------------------------------------------//

grid drone_grid width: width_grid height: height_grid neighbors: 8 {
	int diff_base_x <- abs(base_x - self.grid_x);
	int diff_base_y <- abs(base_y - self.grid_y);
	rgb color <- rgb(255,255,255);
	int crit <- 0;
	int redness <- 0;
	list<drone_grid> neighbors1 <- (self neighbors_at 1);
	
	list<drone_grid> neighbors2  <- (self neighbors_at 2);
	list<drone_grid> neighbors4  <- (self neighbors_at 4);
    action update_crit {
    	//if (crit > 0 ){ color <- rgb(255,0,0);}else{color <- rgb(0,0,0);}
    	
    	redness <- int((crit)*(255/seuil_spawn));
    	color <- rgb(255,255-redness,255-redness);
    }
    reflex intru_spawn when: self.crit > seuil_spawn {
    	if flip(spawn_rate){
    		create intru number: 1 {
	    		my_cell <- myself;
	    		
	    		//A utiliser avec la Version 1.8.2 (évite la duplication du code)
	    		/*x <- myself.grid_x;
	    		y <- myself.grid_y;
	    		x_case_est <- x + 1;
				x_case_ouest <- x - 1;
				y_case_nord <- y -1;
				y_case_sud <- y +1;*/
				location <- my_cell.location;
    		}
    	}
    }
}
//---------------------------------------------------------------------------------------//
//										BATCH 											 //
//---------------------------------------------------------------------------------------//

experiment Optimisation type: batch repeat: 2 keep_seed: true until: ( time > 1500 ){
	list<int> nb_drones_test <- [5, 10, 20, 40, 80];
	parameter "Nombre de drones" var: nb_drone min:0 among: nb_drones_test;
	method exhaustive minimize: drone_grid sum_of(each.crit);
	permanent {
		display Couverture {
			chart "Minimiser la criticité des cases (i.e. maximiser la couverture de surveillance)" type: series x_serie_labels: nb_drones_test x_label: "Nombre de drones"{
				data "Citicité totale du terrain" value: simulations mean_of(each.drone_grid sum_of(each.crit));
			}
		}
	}
}

experiment Cooperation type: batch repeat: 2 keep_seed: true until: ( time > 500 ){
	list<int> nb_drones_test <- [5, 20];
	list<string> Labels <- ["Aleatoire | 5", "Calcul | 5","Aleatoire | 20","Calcul | 20"];
	parameter "Nombre de drones" var: nb_drone min:0 among: nb_drones_test;
	parameter "Mouvement aleatoire" var: move_random among: [true,false];
	method exhaustive minimize: drone_grid sum_of(each.crit);
	permanent {
		display Couverture {
			chart "Minimiser la criticité des cases (i.e. maximiser la couverture de surveillance)" type: series x_serie_labels: Labels y_log_scale: true x_label: "Nature du mouvement | Nombre de drones"{
				data "Citicité totale du terrain" value: simulations mean_of(each.drone_grid sum_of(each.crit));
			}
		}
	}
}


//---------------------------------------------------------------------------------------//
//										GUI 											 //
//---------------------------------------------------------------------------------------//
experiment Visuel type: gui {

	//parameter "POSITION BASE"
	parameter "Position de la base en abscices" var: base_x min: 0;
	parameter "Position de la base en ordonnées" var: base_y min: 0;
	// Define parameters here if necessary
	parameter "Criticité augmentée par les intrus" var: crit_intru min: 0 max: 1000 step: 50;
	parameter "Frequence d'apparition des intrus" var: spawn_rate min: 0.0 max: 0.1 step: 0.001 ;
	parameter "Hauteur de la grille" var: height_grid min: 10 max: 100 step: 1;
	parameter "Largeur de la grille" var: width_grid min: 10 max: 200 step: 1;
	//parameter "Nombre d'intrus a faire apparaitre" var: nb_intru min:0 among: [0, 10, 20, 50];
	parameter "Nombre de drones" var: nb_drone min:0 among: [10, 20, 50, 100];
	// parameter "My parameter" category: "My parameters" var: one_global_attribute;
	
	// Define attributes, actions, a init section and behaviors if necessary
	// init { }
	
	
	output {
	// Define inspectors, browsers and displays here
		display Population_information refresh: every(10#cycles) {
				chart "Espèces" type: series size: {1,1} position: {0, 0} {
					data "Nombre de drones" value: drone count (each.energie > 0) color: #blue;
					data "Nombre d'intrus" value: length(intru) color: #red;
				}
				
		}
		display Actions_Performed refresh: every(10#cycles) {
				chart "Valeurs énergétiques" type: series size: {1,1} position: {0, 0} {
					data "energie moyenne des drones" value: drone mean_of (each.energie) color: #green;
					//data "intrus attrapés" value: drone sum_of (each.intru_caught) color: #red;
				}
		}
			
		display test {
			
			grid drone_grid;// lines: #black;
			species base aspect: ups;
			species drone aspect: drone;
			species intru aspect: intru;
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