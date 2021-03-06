# Importation des packages ----
library(shiny)							# Shiny : pour l'application
library(shinydashboard)			# Jolie application shiny
library(ggplot2)						# Pour les graphiques
library (data.table)				# Dataframe plus efficace pour donnees imposantes
library (leaflet)						# Cartographie
library(geojsonio)					# Cartographie (etats USA)
library(dplyr)							# fonction desc
library(DT)

# Importation des donnees ---- 
fires <- fread(
	"./data/fires.csv",
	header = TRUE,
	sep = ",",
	na.strings = "",
	blank.lines.skip = TRUE,
	stringsAsFactors = TRUE
)

# Importation des polygones des Etats des USA
states <-
	geojsonio::geojson_read(
		"./data/us-states.json",
		what = "sp"
	)

# Importation des résultats de la prédiction
res_opt_rf <- read.csv("data/res_opt_rf.csv")

# Transformation des donnees ----
## On ajuste les types des colonnes mal importees
fires$fire_year <- as.factor(fires$fire_year) # l'annee en facteur
fires$month <- as.factor(data.table::month(fires[, fire_date]))

## On transforme les donnees pour la cartographie
states@data[,3] <- NULL
state.abb <- append(state.abb, c("DC", "PR"))
state.name <- append(state.name, c("District of Columbia", "Puerto Rico"))
fires$state <- state.name[match(fires[, state], state.abb)]

# Graphiques non interactifs ----

palcol <- c("#AEFF34", "#26FC4E", 
						"#2CFFB2", "#46B9FF", 
						"#5452FF", "#8B4AFF",
						"#EC63FF", "#FF3591",
						"#FF3B42", "#FF785D",
						"#FF6C2C", "#FFBA6F",
						"#FFBD24")

# G1. Graphique de l'annee----
plot_annee <- ggplot(as.data.frame(fires), aes(x = fire_year)) +
	geom_histogram(stat = "count",
								 # Nombre de feux
								 aes(fill = stat_cause_descr),
								 # Couleur selon cause
								 position = "stack") + # Histogramme empile
	labs(title = "", x = "", y = "") + # Titres
	scale_color_manual(values = palcol) +
	scale_fill_manual(values = palcol,
										name = "Cause of the fire") +
	theme_minimal() +
	theme(axis.text.x = element_text(angle = 70, size = 15),
				axis.text.y = element_text(size = 15),
				legend.title = element_text(size = 20),
				legend.text = element_text(size = 15)) # Penche les annees)

# G2. Graphique par mois ----
plot_mois <- ggplot(as.data.frame(fires), aes(x = reorder(month, dplyr::desc(month)))) +
	geom_histogram(stat = "count", # Nombre de feux
								 aes(fill = stat_cause_descr), # Couleur selon cause
								 position = "stack") + # Histogramme empile
	labs(title = "", x = "", y = "") + # Titres
	scale_color_manual(values = palcol) +
	scale_fill_manual(values = palcol,
										name = "Cause of the fire") +
	scale_x_discrete(labels=c("1" = "January",
														"2" = "February",
														"3" = "March",
														"4" = "April",
														"5" = "May",
														"6" = "June",
														"7" = "July",
														"8" = "August",
														"9" = "September",
														"10" = "October",
														"11" = "November",
														"12" = "December")) +
	coord_flip() +
	theme_minimal() +
	theme(axis.text.y = element_text(size = 15),
				axis.text.x = element_text(size = 15),
				legend.title = element_text(size = 20),
				legend.text = element_text(size = 15))

# G3. Taille moyenne selon la cause ----
taillecause <- fires[,list(mean_size = mean(fire_size)), 
										 by = stat_cause_descr]

plot_taillecause <- ggplot(as.data.frame(taillecause), 
													 aes(x = reorder(stat_cause_descr, mean_size),
													 		y = mean_size)) +
	geom_bar(stat = 'identity', fill = '#B83A1B') + 
	coord_flip() +
	labs(x = '', y = 'Acres') +
	theme_minimal() +
	theme(axis.text.x = element_text(size = 15),
				axis.text.y = element_text(size = 15))

# 3.4 Prevision ----
# 3.4.1 Graphique ----
## aggregation pour les annees 1995, 2000, 2005, 2010, 2015
firespred_bycause <- fires[fire_year %in% c(1995, 2000, 2005, 2010, 2015), 
													 list(fire_count = .N), 
													 by = stat_cause_descr]
## plot
plot_firespred_bycause <- ggplot(data = firespred_bycause,
																 aes(
																 	x = reorder(stat_cause_descr,-fire_count),
																 	y = fire_count / 1000
																 )) +
	geom_bar(stat = 'identity', fill = 'red') +
	labs(x = '', 
			 y = 'Nombre de feux (en milliers)') +
	theme_minimal() +
	theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 15),
				axis.text.y = element_text(size = 15),
				axis.title.y = element_text(size = 15))

# Graphiques Optimisation de l'algorithme randomForest
res_opt_rf_acc <- ggplot(data = res_opt_rf,
												 aes(x = ntree, y = accuracy)) +
	geom_line(colour = "#B83A1B")  + 
geom_point(colour = "#B83A1B") +
	labs(x = "Nombre d'arbres",
			 y = "Accuracy") +
	theme_minimal() +
	theme(axis.text.x = element_text(size = 15),
				axis.text.y = element_text(size = 15),
				axis.title.y = element_text(size = 17),
				axis.title.x = element_text(size = 17))


res_opt_rf_tps <- ggplot(data = res_opt_rf,
			 aes(x = ntree, y = syst_time)) +
	geom_line(colour = "#B83A1B") +
	geom_point(colour = "#B83A1B") +
	labs(x = "Nombre d'arbres", 
			 y = "Temps de calcul (en secondes)") +
	theme_minimal() +
	theme(axis.text.x = element_text(size = 15),
				axis.text.y = element_text(size = 15),
				axis.title.y = element_text(size = 17),
				axis.title.x = element_text(size = 17))

