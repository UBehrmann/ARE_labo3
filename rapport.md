<div align="justify" style="margin-right:25px;margin-left:25px">

# Laboratoire 03 - <!-- omit from toc -->

## Etudiants

- Guillaume Gonin
- Urs Behrmann

# Table des matières

- [Table des matières](#table-des-matières)
- [Analyse](#analyse)
  - [Plan d’adressage](#plan-dadressage)
  - [schéma  bloc  de  l’interface  Avalon](#schéma--bloc--de--linterface--avalon)
    - [Décodeur d'adresse](#décodeur-dadresse)
    - [Read ID, switches et keys](#read-id-switches-et-keys)
    - [Read status lp36](#read-status-lp36)
    - [Write leds](#write-leds)
    - [Write lp36 data](#write-lp36-data)
    - [Write lp36 sel](#write-lp36-sel)
    - [Liaison avec la Max10](#liaison-avec-la-max10)
      - [MSS pour la liaison Max10](#mss-pour-la-liaison-max10)

# Analyse

Dans le plan d’adressage, la taille de la zone disponible pour votre interface correspond telle aux 14 bits d’adresse défini dans le bus Avalon ? Pourquoi ?

Parce que chaque adresse Avalon correspond à 4 octets (32 bits), ainsi les 14 bits d'adresse du côté FPGA couvrent une zone équivalente à celle des 16 bits d'adresse du côté CPU qui est disponible pour notre interface.

## Plan d’adressage

| Offset on bus AXI lightweight HPS-to-FPGA <br> (relative to BA_LW_AXI) | Lecture (Rd='1')                                    | Écriture (Wr='1')                 |
| ---------------------------------------------------------------------- | --------------------------------------------------- | --------------------------------- |
| 0x00_0000 – 0x00_0003                                                  | Constante design ID 32 bits                         | réservés                          |
| 0x00_0004 – 0x00_00FF                                                  | réservés                                            | réservés                          |
| 0x01_0000 – 0x01_0003                                                  | Constante interface ID 32 bits                      | réservés                          |
| 0x01_0004 – 0x01_0007                                                  | réservés                                            | leds (9..0), réservés (31..10)    |
| 0x01_0008 – 0x01_000B                                                  | switches (9..0), réservés (31..10)                  | réservés                          |
| 0x01_000C – 0x01_000F                                                  | keys (3..0), réservés (31..4)                       | réservés                          |
| 0x01_0010 – 0x01_0013                                                  | lp36_status (0), write_enable (1), réservés (31..2) | réservés                          |
| 0x01_0014 – 0x01_0017                                                  | réservés                                            | lp36_sel (3..0), réservés (31..4) |
| 0x01_0018 – 0x01_001B                                                  | réservés                                            | lp36_data (31..0)                 |
| 0x01_001C – 0x01_FFFF                                                  | réservés                                            | réservés                          |

## schéma  bloc  de  l’interface  Avalon

### Décodeur d'adresse

![Décodeur d'adresse](imgs/interface_avalon-Décodeur.svg)

#### Equations décodeur d'adresse <!-- omit in toc -->

cs_rd_id = addr = 0x01_0000 * rd
cs_wr_leds = addr = 0x01_0004 * wr
cs_rd_switches = addr = 0x01_0008 * rd
cs_rd_keys = addr = 0x01_000C * rd
cs_rd_lp36_status = addr = 0x01_0010 * rd
cs_wr_lp36_sel = addr = 0x01_0014 * wr
cs_wr_lp36_data = addr = 0x01_0018 * wr

### Read ID, switches et keys

Pour les lectures, les données sont directement envoyées sur le bus Avalon. Les signaux de contrôle sont activés pour chaque lecture. Les signaux de données sont activés pour les lectures de l'ID du design, des switches et des keys.

![Read 1](imgs/interface_avalon-rd1.svg)

### Read status lp36
 
Pour la lecture de l'erreur du lp36, on fait la même chose que pour les lectures précédentes, mais l'erreur est interprétée en fonction de la valeur du signal `lp36_status` et on plus de l'erreur, on retourne aussi le signal `write_enable` qui indique si on est en train d'écrire sur le lp36. Le signal `write_enable` est activé par la MSS.

![Read 2](imgs/interface_avalon-rd_status_lp36.svg)

Le status du lp36 est sur 2 bits, donc on peut avoir 4 valeurs différentes, mais seulement les deux premières sont utilisées pour indiquer si il y a une erreur ou non. Vu que les deux autres sont "réservées", on ne retourne pas d'erreur si le signal est à 2 ou 3.

![Décodeur status lp36](imgs/interface_avalon-Deco_etat_lp36.svg)

### Write leds

Pour l'écriture des leds, on active le signal de contrôle `wr_leds` et on enregistre les données dans un registre qui est ensuite utilisé pour allumer les leds.

![Write leds](imgs/interface_avalon-wr_leds.svg)

### Write lp36 data

Pour l'écriture des données du lp36, on active le signal de contrôle `wr_lp36_data` et on enregistre les données dans un registre qui est ensuite utilisé pour envoyer les données au lp36.

![Write lp36 data](imgs/interface_avalon-wr_data.svg)

### Write lp36 sel

Pour l'écriture du selecteur du lp36, on active le signal de contrôle `wr_lp36_sel` et on enregistre les données dans un registre qui est ensuite utilisé pour envoyer les données au lp36.

![Write lp36 sel](imgs/interface_avalon-wr_sel.svg)

### Liaison avec la Max10

Pour la liaison avec la Max10, on doit cadencer les données pour avoir une écriture valide. Pour cela, on utilise un MSS qui va permettre d'envoyer les données et d'informer le CPU de l'état de l'écriture.

Le CPU a deux informations à lire: l'état de l'écriture(`write_enable`) et l'état du lp36(`error`). 

Si le CPU veut écrire, il doit vérifier que le signal `write_enable` est à 0. Si c'est le cas, il peut écrire la sélection des leds pilotés et les données dans le registre de données. Une fois déposées, le CPU doit relire le même registre pour vérifier qu'il n'y a pas eu d'erreur. Si il y a une erreur, la sélection des leds pilotés n'est pas valide.

On a décidé d'utilisé un feedback du `write_enable` pour indiquer au CPU que l'écriture a été effectuée, même si le signal sera allumé que pendant un cycle d’écriture (1us) pour éviter des problèmes de timing. Cela ne devrait pas arrivé, car on dépendant d'input du user sur les boutons et switches pour changer les valeurs pour le Max10.

#### MSS pour la liaison Max10

![Schéma bloc MSS](imgs/interface_avalon-MSS_symb.svg)

![MSS pour la liaison Max10](imgs/interface_avalon-MSS.svg)



</div>