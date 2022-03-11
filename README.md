#convert  
Suite d'outilen shell pour encoder depuis différents formats vers le format ogg.  
Attention tout du moin car l'outil d'encodage des fichier flac avec le cue associé ne fonctionne pas avec les fichiers cue/flac contenant du vide entre les titres.  
Le fichier comment.sh est un exemple car beaucoup de combinaisons peuvent être faites.(il s'utilise avec find: find ~/Musique -name \*.ogg -exec ./comment.sh '{}' \;  
Sous licence Beerware  
/*
 * ---------------------------------------------------------------------------- 
 * "LICENCE BEERWARE" (Révision 42): 
 * <phk@FreeBSD.ORG> a créé ce fichier. Tant que vous conservez cet avertissement, 
 * vous pouvez faire ce que vous voulez de ce truc. Si on se rencontre un jour et 
 * que vous pensez que ce truc vaut le coup, vous pouvez me payer une bière en 
 * retour. Poul-Henning Kamp 
 * ---------------------------------------------------------------------------- 
 */
