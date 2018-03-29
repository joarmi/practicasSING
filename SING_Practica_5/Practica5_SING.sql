/*Javier Argente Micó - Jose Lluch Palop*/


/*Ejercicio 1: Piensa que consultas básicas tipo group by necesitarías ejecutar para obtener el resultado anterior.  

Utilizando el operador CUBE, genera una tabla de doble entrada que muestre las ventas por tipo de canal (SH.CHANNELS.CHANNEL_DESC) 
y por categoría de producto (atributo PRODUCTS.PROD_CATEGORY). 

En vista de estos datos, dí cuantos productos se han vendido en total por el canal ‘Internet’, y cuantos  por venta directa.*/

SELECT 
	sh.channels.channel_desc, 
	sh.products.prod_category,
	TO_CHAR(SUM(sh.sales.amount_sold),'9,999,999,999') SALES$
from 
	sh.channels, sh.products, sh.sales 
where 
	sh.channels.channel_id = sh.sales.channel_id and
	sh.products.prod_id = sh.sales.PROD_ID  
group by cube (sh.channels.channel_desc, sh.products.prod_category);

/*Por el canal de internet se han vendido un total de 13,706,802 productos.
  Por venta directa se han vendido un total de 57,875,261 productos*/

  
/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 2: Ejecuta la consulta del ejemplo anterior e interpreta los valores nulos que aparecen en algunas de las columnas.
 
Utiliza el operador ROLLUP para obtener las ventas de clientes agrupando dentro de la jerarquía de las direcciones de los 
clientes (country, country_region, country_subregion).  

Mirando los resultados, di que regiones están formadas únicamente por una sub-región, por lo que hay varias filas en las 
coinciden los subtotales */

SELECT
    SH.COUNTRIES.COUNTRY_REGION,
    SH.COUNTRIES.COUNTRY_SUBREGION,
    SH.COUNTRIES.COUNTRY_NAME
FROM 
    SH.COUNTRIES, SH.CUSTOMERS, SH.SALES

WHERE 
    SH.COUNTRIES.COUNTRY_ID = SH.CUSTOMERS.COUNTRY_ID AND
    SH.CUSTOMERS.CUST_ID = SH.SALES.CUST_ID

GROUP BY ROLLUP (SH.COUNTRIES.COUNTRY_REGION,
                 SH.COUNTRIES.COUNTRY_SUBREGION,
                 SH.COUNTRIES.COUNTRY_NAME);
				 
/*Las regiones que están formadas solo por una sub-región son Asia, Australia y Middle East*/


/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 3: Repite la consulta del ejercicio 2, pero mejorando su legibilidad, es decir utiliza la función GROUPING junto con DECODE. 
Construye un resultado que cambie los valores nulos que genera el GROUP BY ROLLUP por etiquetas apropiadas */

SELECT
    DECODE(
    GROUPING(SH.COUNTRIES.COUNTRY_REGION),
    1,
    'No hay nombre de country',
    SH.COUNTRIES.COUNTRY_REGION
    ) AS C_REGION,
    DECODE(
    GROUPING(SH.COUNTRIES.COUNTRY_SUBREGION),
    1,
    'No hay nombre de subregion',
    SH.COUNTRIES.COUNTRY_SUBREGION
    ) AS C_SREGION,
    DECODE(
    GROUPING(SH.COUNTRIES.COUNTRY_NAME),
    1,
    'No hay nombre de region',
    SH.COUNTRIES.COUNTRY_NAME
    ) AS C_NAME

FROM 
    SH.COUNTRIES, SH.CUSTOMERS, SH.SALES

WHERE 
    SH.COUNTRIES.COUNTRY_ID = SH.CUSTOMERS.COUNTRY_ID AND
    SH.CUSTOMERS.CUST_ID = SH.SALES.CUST_ID

GROUP BY ROLLUP (SH.COUNTRIES.COUNTRY_REGION,
                 SH.COUNTRIES.COUNTRY_SUBREGION,
                 SH.COUNTRIES.COUNTRY_NAME);
				 
				 
/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 4: Realiza una consulta que calcule el total de ventas agrupando por: 

-mes de venta y país de venta, 

-mes de venta y canal de distribución 

-canal de distribución y categoría de producto. */

SELECT 
    CHA.channel_desc, 
    TI.calendar_month_desc, COU.country_iso_code,
    TO_CHAR(SUM(SA.amount_sold), '9,999,999,999') VENTAS

FROM 
    SH.sales SA, 
    SH.customers CU, 
    SH.times TI, 
    SH.channels CHA, 
    SH.countries COU,
    SH.PRODUCTS PROD
    
WHERE
SA.time_id=TI.time_id AND SA.cust_id=CU.cust_id AND SA.channel_id= CHA.channel_id AND
CU.COUNTRY_ID = COU.COUNTRY_ID AND SA.PROD_ID = PROD.PROD_ID AND

CHA.channel_desc IN ('Direct Sales', 'Internet') AND TI.calendar_month_desc IN ('2000-09',
'2000-10') AND COU.country_iso_code IN ('GB', 'US')


GROUP BY GROUPING 
SETS
(
(TI.calendar_month_desc, COU.country_iso_code), 
(TI.calendar_month_desc, CHA.CHANNEL_DESC), 
(CHA.CHANNEL_DESC, PROD.PROD_CATEGORY_ID)
);


/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 5: Sabiendo que las funciones RANK y DENSE_RANK pueden ordenar  por particiones, utiliza la claúsula correspondiente 
para hacer  una consulta que ordene las ventas realizadas para los distintos canales de distribución, en los meses comprendidos entre 
agosto y diciembre del año 2000.  

Nota : La clausula [QUERY PARTITION_CLAUSE], opcional, tiene la forma: 
 
PARTITION BY columna |expresión 

En base al resultado di en que mes se realizaron más ventas para cada canal de distribución existente.*/

SELECT 
    channel_desc, SH.TIMES.CALENDAR_MONTH_DESC, SUM(amount_sold) VENTAS,
    RANK() OVER (ORDER BY TRUNC(SUM(amount_sold),-5) DESC) AS ORDEN

FROM SH.sales, SH.products, SH.customers, SH.times, SH.channels, SH.countries
WHERE 
    SH.sales.prod_id=SH.products.prod_id AND
    SH.sales.cust_id=SH.customers.cust_id AND 
    SH.customers.country_id = SH.countries.country_id AND
    SH.sales.time_id=times.time_id

 AND SH.sales.channel_id=channels.channel_id
 AND SH.times.calendar_month_desc IN ('2000-08', '2000-09', '2000-10', '2000-11', '2000-12')AND
     SH.channels.channel_desc<>'Tele Sales'
     
GROUP BY channel_desc, SH.TIMES.CALENDAR_MONTH_DESC;

/*Para Direct Sales se realizaron más ventas en agosto, para Partners en octubre y para Internet en diciembre*/


/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 6: Realiza una consulta que calcule la posición PERCENT_RANK de los resultados de una consulta que calcula las ventas totales
de los clientes agrupados por país y por tipo de canal de venta. Realiza la misma operación utilizando la función CUME_DIST. */

SELECT 
    CHA.channel_desc,
    COU.country_iso_code,
    TO_CHAR(SUM(SA.amount_sold), '9,999,999,999') VENTAS,
    PERCENT_RANK() OVER (PARTITION BY CHA.channel_desc ORDER BY SUM(SA.amount_sold) ) AS PERCENT,
    CUME_DIST() OVER (PARTITION BY CHA.channel_desc ORDER BY SUM(SA.amount_sold) ) AS CUME

FROM 
    SH.sales SA, 
    SH.customers CU,  
    SH.channels CHA, 
    SH.countries COU
	
WHERE
	SA.cust_id=CU.cust_id AND 
	SA.channel_id= CHA.channel_id AND
	CU.COUNTRY_ID = COU.COUNTRY_ID
	
GROUP BY CHA.channel_desc, COU.country_iso_code;


/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 7: Realiza una consulta que calcule las compras realizadas por el cliente 6510 para cada uno de los meses en el año 1999.
 
Una vez tengas esta consulta, utiliza una ventana móvil para calcular el promedio de ventas utilizando la consulta anterior como base. */

SELECT 
    c.cust_id, 
    t.calendar_quarter_desc, 
    SUM(amount_sold) AS Q_SALES,
    TO_CHAR(AVG(AVG(amount_sold)) 
    OVER (PARTITION BY c.cust_id ORDER BY c.cust_id, t.calendar_quarter_desc 
    ROWS UNBOUNDED 
    PRECEDING), '9,999,999,999.99') AS CUM_SALES
    
FROM 
    sh.sales s, 
    sh.times t, 
    sh.customers c   
    
WHERE 
    s.time_id=t.time_id AND 
    s.cust_id=c.cust_id AND 
    t.calendar_year=1999 AND
    c.cust_id = 6510
    
GROUP BY 
    c.cust_id, t.calendar_quarter_desc;

	
/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 8: Realiza una consulta básica que calcule la suma de cantidad invertida (gastada) para cada producto y la cantidad de productos. 
Se debe mostrar el nombre del producto, el dinero invertido, y la cantidad de ese producto comprada (para todos los países, y clientes, y 
tiempo).

Anota el tiempo que tarde en resolver la consulta.*/

SELECT
    p.prod_name,
    SUM(s.amount_sold) AS INVERTIDO,
    SUM(s.quantity_sold) AS CANTIDAD
    
FROM
    sh.products p,
    sh.sales s,
    sh.customers c,
    sh.countries cou,
    sh.times t
    
WHERE
    p.prod_id = s.prod_id AND
    s.cust_id = c.cust_id AND
    c.country_id = cou.country_id AND
    s.time_id = t.time_id
    
GROUP BY cou.country_id, c.cust_id, t.time_id, p.prod_name;

/*Tarda un tiempo de 4,5 segundos aproximadamente*/


/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 9: Crea ahora una vista materializada que guarde para cada country_id, nombre de producto y tipo de canal de distribución la 
cantidad de dinero invertida y el número de productos vendidos. 

Revisa la vista y utiliza dicha vista para resolver el ejercicio 8.  Anota el tiempo que tarda en resolver la consulta. 

Crea después un índice sobre la vista materializada que creas que mejore el rendimiento. */

CREATE MATERIALIZED VIEW ejer_9 
REFRESH COMPLETE ON DEMAND 
AS
SELECT
    SUM(s.amount_sold) AS INVERTIDO,
    SUM(s.quantity_sold) AS CANTIDAD
    
FROM
    sh.products p,
    sh.sales s,
    sh.customers c,
    sh.countries cou,
    sh.channels ch
    
WHERE
    p.prod_id = s.prod_id AND
    s.cust_id = c.cust_id AND
    c.country_id = cou.country_id AND
    ch.channel_id = s.channel_id
    
GROUP BY cou.country_id, p.prod_name, ch.channel_desc;
/*Vista creada*/

select * from ejer_9;
/*Revisar contenido de la vista*/

CREATE INDEX ejer_9_indice ON ejer_9(INVERTIDO);
/*Indice para mejorar el rendimiento sobre INVERTIDO, ya que es lo que más ralentiza la consulta dentro de la vista*/


/*---------------------------------------------------------------------------------------------------------------------------------------*/


/*Ejercicio 10: Realiza la siguiente consulta y mira el tiempo de ejecución: 

SELECT t.calendar_month_desc, SUM(s.amount_sold) 
FROM sh.sales s, sh.times t WHERE s.time_id = t.time_id 
GROUP BY t.calendar_month_desc; 

Ahora crea la siguiente vista con la opción de QUERY REWRITE: 

CREATE MATERIALIZED VIEW ventas_por_mes  
ENABLE QUERY REWRITE AS 
SELECT t.calendar_month_desc, SUM(s.amount_sold) AS dollars 
FROM sh.sales s, sh.times t WHERE s.time_id = t.time_id 
GROUP BY t.calendar_month_desc; 

Ejecuta ahora la consulta primera de nuevo y revisa el tiempo de ejecución. ¿Ha tardado menos?? ¿¿Qué es lo que ha cambiado?? */

/*El tiempo se ha reducido debido al efecto de QUERY REWRITE, el cual permite que el optimizador 
  modifique de forma interna nuestra consulta sobre una determinada tabla, ante la existencia de 
  una determinada vista, para mejorar el rendimiento de la consulta*/