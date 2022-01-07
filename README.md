PAV - P4: reconocimiento y verificación del locutor
===================================================

**Obtenga su copia del repositorio de la práctica accediendo a [Práctica 4](https://github.com/albino-pav/P4)
y pulsando sobre el botón `Fork` situado en la esquina superior derecha. A continuación, siga las
instrucciones de la [Práctica 2](https://github.com/albino-pav/P2) para crear una rama con el apellido de
los integrantes del grupo de prácticas, dar de alta al resto de integrantes como colaboradores del proyecto
y crear la copias locales del repositorio.**

**También debe descomprimir, en el directorio `PAV/P4`, el fichero [db_8mu.tgz](https://atenea.upc.edu/pluginfile.php/3145524/mod_assign/introattachment/0/spk_8mu.tgz?forcedownload=1)
con la base de datos oral que se utilizará en la parte experimental de la práctica.**

**Como entrega deberá realizar un *pull request* con el contenido de su copia del repositorio. Recuerde
que los ficheros entregados deberán estar en condiciones de ser ejecutados con sólo ejecutar:**

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
  make release
  run_spkid mfcc train test classerr verify verifyerr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Recuerde que, además de los trabajos indicados en esta parte básica, también deberá realizar un proyecto
de ampliación, del cual deberá subir una memoria explicativa a Atenea y los ficheros correspondientes al
repositorio de la práctica.**

**A modo de memoria de la parte básica, complete, en este mismo documento y usando el formato *markdown*, los
ejercicios indicados.**

## Ejercicios.

### SPTK, Sox y los scripts de extracción de características.

- **Analice el script `wav2lp.sh` y explique la misión de los distintos comandos involucrados en el *pipeline*
  principal (`sox`, `$X2X`, `$FRAME`, `$WINDOW` y `$LPC`). Explique el significado de cada una de las 
  opciones empleadas y de sus valores.**

 	A a linia  43 i 44 del fixter "wav2lp.sh" hi trobem el següent codi:
 
	 `sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpc_order > $base.lp`
  
	 Les diferents ordres serveixen per:
 
	- **sox**: eina de processat de senyals d'àudio que permet, entre altres, canviar la codificació dels fitxers. S'invoca a partir de les opcions:
	   -  -t : inica el tipus de fitxer d'entrada, en aquest cas RAW
	   -  -e : Indica en quin tipus de codificació del fitxer d'entrada (el valor signed indica que es tracta de signed integer).
	   -  -b : indica el nombre de bits amb el que s'ha codificat el fitxer d'entrada 
	 - **X2X**: conversió enters de 16 bits a reals de 4 bytes
	 - **FRAME**: separació de l'arxiu per trames de 240 mostres (-l) amb un desplaçament entre elles de 80 (-p).
	 - **LPC**: ordre del conjunt SPTK que permet fer el càlcul de l'envolvent espectral mitjançant un filtre de predicció lineal. Per invocar aquesta operació es fa ús dels següents paràmetres:
	   -  -l 240 --> tamany de la finestra
	   -  -m $LPC_order --> ordre del diltre LPC, que entrarà per paràmetre quan s'invoqui l'script "wav2lp.sh" a l'script general "run_spkid.sk"
   	-  **WINDOW**: Enfinistrament del senyal amb finestres de 240 mostres tant d'entrada com de sortida (-l) i (-L).

- **Explique el procedimiento seguido para obtener un fichero de formato *fmatrix* a partir de los ficheros de
  salida de SPTK (líneas 45 a 47 del script `wav2lp.sh`).**

	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
	ncol=$((lpc_order+1)) # lpc p =>  (gain a1 a2 ... ap)
	nrow=`$X2X +fa < $base.lp | wc -l | perl -ne 'print $_/'$ncol', "\n";
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	L'objectiu del codi es guardar per columnes la informació extreta per cada caracteística per tant, primerament, cal definir el combre de columnes que tindrà el fitxer fmatrix. El nombre de columnes serà igual al nombre de coeficients de la parametrtzació +1 ja que l'enta de SPTK retorna en primer lloc el guany. A partir d'aquí les variables wc (word count) i wl (word line) compten el nombre de paraules del fitxer temporal (que es troba expressat en ASCII) per tal d'obtenir en nombre de filtes. Per imprimir el resultat al fitxer fmatrix es fa ús de l'eina `perl-ne`.

  * **¿Por qué es conveniente usar este formato (u otro parecido)? Tenga en cuenta cuál es el formato de
    entrada y cuál es el de resultado.**
    
 	 Guardar els reusltats de les parametritzacins de l'àudio en columnes és útil ja que permet un accès ràpid i ordenat al resultats.

- **Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales de predicción lineal
  (LPCC) en su fichero <code>scripts/wav2lpcc.sh</code>:**
  
  	`sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpcc_order | $LPCC -m $lpcc_order -M $cepstrum_order  > $base.lpcc`

- **Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales en escala Mel (MFCC) en su
  fichero <code>scripts/wav2mfcc.sh</code>:**
 
	 `sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	 $MFCC -l 240 -m $mfcc_order -n $filter_channel > $base.mfcc`


### Extracción de características.

- **Inserte una imagen mostrando la dependencia entre los coeficientes 2 y 3 de las tres parametrizaciones
  para todas las señales de un locutor.**
     
  <img width="617" alt="image" src="https://user-images.githubusercontent.com/91891270/148525987-9726f45d-205d-47ec-ac4c-e5571512757e.png">

	Observem un fitxer fmatrix qualsevol. Per tal de generar un fitxer on només hi hagi els valors d'aquests dos coeficients fem:

	(Observem la parametrització de la sessió SES061)

	`fmatrix_show work/lp/BLOCK06/SES061/*.lp | egrep '^\[' | cut -f2,3 > lp_coefs`

	`fmatrix_show work/lpcc/BLOCK06/SES061/*.lpcc | egrep '^\[' | cut -f2,3 > lpcc_coefs.txt`

	`fmatrix_show work/mfcc/BLOCK06/SES061/*.mfcc | egrep '^\[' | cut -f2,3 > mfcc_coefs.txt`


 	 Una vegada generat el fitxer representarem els resultats via Matlab.
  
  + **Indique todas las órdenes necesarias para obtener las gráficas a partir de las señales 
    parametrizadas**.
    
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
	cd('\\wsl$\Ubuntu-20.04\home\XXXXX\PAV\P4')


	load('lp_coefs.txt')

	scatter(lp_coefs(:,1), lp_coefs(:,2), 'red', '.')
	title('Representació coefcients LP 2 i 3')
	xlabel('Coeficient 2')
	ylabel('Coeficient 3')

	load('lpcc_coefs.txt')

	scatter(lpcc_coefs(:,1), lpcc_coefs(:,2), 'green', '.')
	title('Representació coefcients LPCC 2 i 3')
	xlabel('Coeficient 2')
	ylabel('Coeficient 3')

	load('mfcc_coefs.txt')

	scatter(mfcc_coefs(:,1), mfcc_coefs(:,2), 'm', '.')
	title('Representació coefcients MFCC 2 i 3')
	xlabel('Coeficient 2')
	ylabel('Coeficient 3')
	~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	  <img width="250" alt="image"  src="https://user-images.githubusercontent.com/91891270/148530000-5c30f1a3-98df-4018-9dc5-46a95e9e46fb.png">

	  <img width="250" alt="image"  src="https://user-images.githubusercontent.com/91891270/148530002-38e870cf-b2ae-43f4-8496-82ee4aa83f6b.png"> 

	  <img width="250" alt="image" src="https://user-images.githubusercontent.com/91891270/148530004-9bc275bd-887c-4f36-858b-14443188a0b6.png">


  + **¿Cuál de ellas le parece que contiene más información?**
 
	 Aportaran més informació els coeficients que estiguin menys correlats, ja que la incorrelació implica que el valor d'un coeficient no afecta al valor de l'altre. Els MFCC són, per definició, la parametrització més incorrelada, quelcom que es pot observar en les gràfiques anteriors.

- **Usando el programa <code>pearson</code>, obtenga los coeficientes de correlación normalizada entre los
  parámetros 2 y 3 para un locutor, y rellene la tabla siguiente con los valores obtenidos.**
  
  El programa Pearson et diu quantes dimensions aporten les components adicionals calculades amb MFCC. Executant la comanda 
    `pearson work/lp/BLOCK06/SES061/SA061S*.lp` veiem que el la incorrelació entre els coeficients 2 i 3 és de:
	  
   <img width="123" alt="image" src="https://user-images.githubusercontent.com/91891270/148542286-2432f03d-1f99-4e9d-953a-c4b42e472b5f.png">

   <img width="122" alt="image" src="https://user-images.githubusercontent.com/91891270/148542464-5d798e48-c196-45d4-8354-950bdd6381ef.png">


	Repetint el procès per a les altres dos parametritzacions:

	`pearson work/lpcc/BLOCK06/SES061/SA061S*.lpcc` 

	`pearson work/mfcc/BLOCK06/SES061/SA061S*.mfcc` 

  |                        | LP   | LPCC | MFCC |
  |------------------------|:----:|:----:|:----:|
  | &rho;<sub>x</sub>[2,3] |-0.82727|  0.108369    |   0.0328436   |

+ **Compare los resultados de <code>pearson</code> con los obtenidos gráficamente.**

	Veiem que aquests resultats concordem amb el que hem mencionat anteriorment.
  
- **Según la teoría, ¿qué parámetros considera adecuados para el cálculo de los coeficientes LPCC y MFCC?**

	La teoria ens diu que els coeficients més òptims per realizar les parametritzacions són:
	- LP:  sistema LP d'ordre 8 --> -m 8
	- LPCC:  sistema LP d'ordre 8 amb ceptrsum d'ordre 12 --> -m 8 -M 12
	- MFCC:  Banc de filtres d'ordre de 24 a 40, MFCC d'ordre 30 -->  -m 13 -n 40

### Entrenamiento y visualización de los GMM.

Complete el código necesario para entrenar modelos GMM.

- **Inserte una gráfica que muestre la función de densidad de probabilidad modelada por el GMM de un locutor
  para sus dos primeros coeficientes de MFCC**.
 
 A la següent imatge podem veure el model del locutor de la SES061: (parametritzat amb MFCC)
 
 `plot_gmm_feat work/gmm/mfcc/SES061.gmm -g blue -x 2 -y3 &`.
 
 
 <img width="440" alt="image" src="https://user-images.githubusercontent.com/91891270/148549584-8607a246-a4a6-462b-987c-7304dba8bd0b.png">
 
 Amb la comanda següent superposarem el model amb les mostres de la sessió per comprovar si s'ajusta bé o no:
 
 `plot_gmm_feat work/gmm/mfcc/SES061.gmm work/mfcc/BLOCK06/SES061/SA061S* -g blue -x 2 -y 3 &`
 
<img width="431" alt="image" src="https://user-images.githubusercontent.com/91891270/148549831-9ac839b4-b15c-47af-b422-347912509c55.png">
 
Veiem la dispesió de les mostres representa el mateix resultat que el que haviem obtingut amb Matlab i que el model és prou bo, ja que s'ajusta bé. Això que té sentit perquè hem pentrenat la GMM amb 60 gaussianes durant 90 interacions.
  
- **Inserte una gráfica que permita comparar los modelos y poblaciones de dos locutores distintos (la gŕafica
  de la página 20 del enunciado puede servirle de referencia del resultado deseado). Analice la capacidad
  del modelado GMM para diferenciar las señales de uno y otro.**
  
  Hem representat (següint les comandes anteriors) els models l'altres sessions:

`plot_gmm_feat work/gmm/mfcc/SES061.gmm work/mfcc/BLOCK02/SES022/SA022S* -g blue -x 2 -y 4 &`
  <img width="418" alt="image" src="https://user-images.githubusercontent.com/91891270/148550694-2cb9698a-17a4-41af-8c0a-22b46db5c0cc.png"> 
  
  ` plot_gmm_feat work/gmm/mfcc/SES061.gmm work/mfcc/BLOCK08/SES087/SA087S* -g blue -x 2 -y 3 &`
  
<img width="416" alt="image" src="https://user-images.githubusercontent.com/91891270/148550616-41469da5-eb4f-40e9-8104-7e715885044d.png">


Veiem que no en tots els casos el model GMM dels coeficients 2 i 3 s'ajusta igual de bé a la parametrització del senyal. Això és podria millorar amb més iteracions o bé implenentant una iniciañotzació VQ de les guassianes.



### Reconocimiento del locutor.

Complete el código necesario para realizar reconociminto del locutor y optimice sus parámetros.

- Inserte una tabla con la tasa de error obtenida en el reconocimiento de los locutores de la base de datos
  SPEECON usando su mejor sistema de reconocimiento para los parámetros LP, LPCC y MFCC.

### Verificación del locutor.

Complete el código necesario para realizar verificación del locutor y optimice sus parámetros.

- Inserte una tabla con el *score* obtenido con su mejor sistema de verificación del locutor en la tarea
  de verificación de SPEECON. La tabla debe incluir el umbral óptimo, el número de falsas alarmas y de
  pérdidas, y el score obtenido usando la parametrización que mejor resultado le hubiera dado en la tarea
  de reconocimiento.
 
### Test final

- Adjunte, en el repositorio de la práctica, los ficheros `class_test.log` y `verif_test.log` 
  correspondientes a la evaluación *ciega* final.

### Trabajo de ampliación.

- Recuerde enviar a Atenea un fichero en formato zip o tgz con la memoria (en formato PDF) con el trabajo 
  realizado como ampliación, así como los ficheros `class_ampl.log` y/o `verif_ampl.log`, obtenidos como 
  resultado del mismo.
