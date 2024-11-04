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

# Analyse

Dans le plan d’adressage, la taille de la zone disponible pour votre interface correspond telle aux 14 bits d’adresse défini dans le bus Avalon ? Pourquoi ?

Parce que chaque adresse Avalon correspond à 4 octets (32 bits), ainsi les 14 bits d'adresse du côté FPGA couvrent une zone équivalente à celle des 16 bits d'adresse du côté CPU qui est disponible pour notre interface.

## Plan d’adressage

| Offset on bus AXI lightweight HPS-to-FPGA (relative to BA_LW_AXI) | Lecture (Rd='1')                     | Écriture (Wr='1')                    |
| ----------------------------------------------------------------- | ------------------------------------ | ------------------------------------ |
| 0x00_0000 – 0x00_0003                                             | Constante ID 32 bits                 | réservés                             |
| 0x00_0004 – 0x00_00FF                                             | réservés                             | réservés                             |
| 0x01_0000 – 0x01_0003                                             | leds (9..0), réservés (31..10)       | leds (9..0), réservés (31..10)       |
| 0x01_0004 – 0x01_0007                                             | switches (9..0), réservés (31..10)   | réservés                             |
| 0x01_0008 – 0x01_000B                                             | keys (3..0), réservés (31..4)        | réservés                             |
| 0x01_000C – 0x01_000F                                             | lp36_status (1..0), réservés (31..2) | réservés                             |
| 0x01_0010 – 0x01_0013                                             | lp36_sel (3..0), réservés (31..4)    | lp36_sel (3..0), réservés (31..4)    |
| 0x01_0014 – 0x01_0017                                             | lp36_data (31..0)                    | lp36_data (31..0)                    |
| 0x01_0018 – 0x01_001B                                             | lp36_we (0), réservés (31..1)        | lp36_we (0), réservés (31..1)        |

NB: Nous avons permis la lecture de toutes les entrées et sorties bien que certains valeurs on moins de sens à être lu par le CPU (par exemple lp36_we). Avec cette manière de faire, le développement et les tests de notres solution seront simplifiées.

## schéma  bloc  de  l’interface  Avalon

![schéma  bloc  de  l’interface  Avalon](imgs/avalon.png)
