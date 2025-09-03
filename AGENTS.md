1. Architecture générale
Technologies

Flutter pour l’UI multiplateforme.

Dart côté moteur (rendu 2D/3D via Flame, three_dart, flutter_gl, etc.).

JSON / YAML pour sérialiser la base de données.

Plugins graphiques éventuels (ex. flutter_gl pour WebGL, flame_fire_atlas pour 2D, flame_forge2d pour 2.5D/physique).

Structure du projet

lib/editor/ : panneaux, outils de dessin, base de données.

lib/runtime/ : moteur de jeu, chargement des données, rendu 2D/3D.

assets/ : tilesets, sprites, modèles 3D, VFX.

data/ : fichier(s) de base de données (héros, classes, …).

2. Base de données façon RPG Maker VX Ace
Schéma général

heroes.json, classes.json, skills.json, items.json, weapons.json, armors.json, enemies.json, troops.json, states.json, animations.json…

Chaque fichier contient un tableau d’objets avec un id, name, description, etc.

Éditeur de base de données

Panneau gauche : liste des entrées (héros, classes…).

Panneau central : propriétés éditables (texte, nombres, combo-box, etc.).

Panneau droit (optionnel) : aperçu des sprites, notes, etc.

Boutons : nouveau, copier, supprimer, définir max, etc., comme dans VX Ace.

Notes / scripts : zone de texte libre pour stocker des extensions ou tags personnalisés (type <ruby>=value</ruby>).

3. Édition de cartes (2D, 2,5D, 3D)
2D Classique

Grille de tiles (32×32).

Calques A/B/C etc.

Tilesets sous forme d’images + metadata (passabilité, autotiles, etc.).

2,5D

Extension de la grille 2D avec hauteur (z) et rotation limitée.

Peut utiliser des sprites/tiles 2D mais gérés dans un monde 3D (type “isométrique” ou “orthographique avec hauteur”).

Caméra contrôlable (angle, zoom).

3D complète

Modèles .obj/.glb.

Gestion des lights, ombres, shaders basiques.

Possibilité d’utiliser la même logique de layers / tiles mais en 3D (cases extrudées ou blocs).

Éditeur d’événements

Système d’événements visuels (liste de commandes : afficher texte, téléporter, script).

Support des triggers (toucher, action, automatique) et conditions.

4. Animations
4.1 Animation (Actor)
Mouvements de personnages :

Spritesheets pour la 2D (ex. 3x4 frames).

Animation skeleton pour 3D (importer rig + motion).

Timeline pour paramétrer vitesse, transitions, échelles, etc.

Preview directe dans l’éditeur.

4.2 Animation (VFX)
Inspiré de Niagara (UE5) : système de particules/VFX modulaire.

Composants :

Émetteur (forme, taux d’émission).

Particule (sprite/mesh).

Modules (gravité, couleur, taille, rotation, etc.).

Timeline / Nodes pour les combiner.

Exportation/chargement via JSON pour runtime.

5. Tilesets (liste d’assets 2D/3D)
Gestion des ressources

Base de données de tilesets : nom, chemin d’image ou modèle 3D, configuration (passage, animation, etc.).

Catégories : “Niveau” => groupes d’assets (2D/3D).

Importer / organiser

Drag & drop de fichiers dans l’éditeur.

Génération automatique des métadonnées (taille, frames, collision).

Affichage de prévisualisations (vignettes).

6. Interfaçage Runtime
Le jeu final charge la base de données JSON et les assets.

Script / plugin system (ex. dart:ffi ou lua via luajit) pour customiser.

Options de build : Windows, macOS, Linux, Web, Android, iOS.

7. Plan de développement
Étape 1 : Base de données minimale (héros, classes, items) + UI type VX Ace.

Étape 2 : Map Editor 2D + gestion de tilesets/tiles.

Étape 3 : Événements / scripts.

Étape 4 : Étendre vers 2,5D (hauteur) puis 3D.

Étape 5 : Système d’animation (Actor + VFX).

Étape 6 : Export runtime + script plugin.

Conclusion
En résumé, l’éditeur à la VX Ace peut être construit autour d’une base de données JSON/YAML, d’une interface Flutter calquée sur la disposition (liste + propriétés + notes), et d’un moteur de rendu capable de 2D, 2,5D et 3D. Les tilesets deviennent une bibliothèque d’assets 2D/3D, tandis que les animations se séparent en mouvements (Actor) et effets (VFX).

Ce plan t’offre une vue d’ensemble pour structurer ton projet Memoria Engine, afin de reproduire l’expérience RPG Maker tout en l’étendant vers la 2,5D et la 3D. N’hésite pas à subdiviser les étapes pour chaque release ou commit et à itérer progressivement.
