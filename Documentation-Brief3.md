# Brief_3 Script  
David, Dunvael, Nicolas

<div id='top'/>

### Sommaire :  

### [1 - Topologie de l'infrastructure](#structure)  
&nbsp;&nbsp;&nbsp;[a) Topologie](#Topologie)
&nbsp;&nbsp;&nbsp;[b) Liste des ressources](#Ressources)  

### [2 - Présentation du script](#Présentation)  

### [3 - Conditions nécessaires à l'éxécution du script](#Script)   

[&#8679;](#top) 

<div id='Structure'/>  

## 1 - Infrastructure  

<div id='Topologie'/>  

#### a) Topologie  
```mermaid
  graph TD
    subgraph one[VM AZURE]
        C(Jenkins)
        F[Disque utilisateur]
    end 
    subgraph two[Local]
        A[Administrateur]        
    end
    A[Administrateur] -->|Bastion Azure SSH| C(Apache / Jenkins)
    C --> D[Sauvegarde Azure - Azure Vault Backup]
    E[Utilisateur] -->|https| C
    C -.-> F[Disque utilisateur]

```

[&#8679;](#top) 

<div id='Ressources'/>  

#### b) Liste des ressources
Dimension des ressources minimales déployées.

|  | Bastion Azure | Apache | Jenkins | VM |
|-----------|-----------|-----------|----------|--------|
| Version |en développement  | 2.4.54 | 2.346.2 | 11.4 |
| OS |  |  |  | Debian|
| RAM |  |  | 4 GB | 4 GB
| CPU |  |  |  |1GHz Pentium processor|
| Disques durs |  |  | 64 GB (50 GB)| 30 GB (8 GB)|
| SSH |22 | 80 | 8080 |80
| Vnet Bastion |10.0.0.0 |
| Vnet VM| |  |  | 10.0.1.0 |  |
| Masque de sous-réseau Bastion Azure | /24 |  |  | /24|


[&#8679;](#top) 

<div id='Présentation'/>  

## 2 - Présentation du script


- Création dans un ordre précis des variables à l'intérieur du script afin d'éviter des conflits et des erreurs. Par exemple, la variable $VAULTID dans le Backup de la VM.  

- Création de trois scripts : le script principal az-jenkins.sh appelle les deux autres scripts qui vont s'éxécuter sur la vm au fur et à mesure du déroulement.  

- Création d'un menu dans le script permettant de pouvoir (si besoin) exécuter les étapes de son choix.

![](https://i.imgur.com/iNEcH8t.png)

[&#8679;](#top) 

<div id='Script'/>  

## 3 - Conditions nécessaires à l'éxécution du script  

- Avoir une console Azure CLI connectée dans un environnement Linux  

- Installation de la librairie JQ afin de pouvoir récupérer des informations au format JSON  

- Fournir les clés SSH des administrateurs dans le fichier texte authorized_keys afin qu'ils puissent avoir l'accès à la VM via le Bastion  

- Définir les variables pour leur utilisation dans le reste du script  

- Décompresser le fichier Brief3-groupe4.zip et exécuter le script depuis le même dossier  

- Suivre l'ordre des paramètres nécessaires à l'exécution du script :  

```./az-jenkins.sh FQDN NOM_VM TAILLE_DISQUE LOCALISATION ```


**Apperçu**

![](https://i.imgur.com/vq5fOMV.png)

![](https://i.imgur.com/b6nMcHg.png)


![](https://i.imgur.com/5PReuVy.png)

![](https://i.imgur.com/fW7iX7V.png)





[&#8679;](#top) 














