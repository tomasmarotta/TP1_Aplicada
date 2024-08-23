/*******************************************************************************
							 Trabajo Práctico 1 
				De Boeck, Garay Adriel, Kastika y Marotta 	
				
                          Universidad de San Andrés
                              Economía Aplicada
									2024							           
*******************************************************************************/

clear all 
set more off

*save path in global 
* TM(21/08/2024): Pongan el directorio con otro "else if" para que stata reconozca automáticamente el directorio que tiene que usar
if "`c(username)'" == "sofia" {
    global main "/Users/sofia/Desktop/Maestría/Optativas/Tercer trimestre/Economía Aplicada/TPs/TP 1"
} 
else if "`c(username)'" == "tomasmarotta" {
    global main "/Users/tomasmarotta/Documents/GitHub/TP1_Aplicada"
} 
else {
    display "Error: Usuario no reconocido. No se ha configurado el directorio principal."
    exit
}

// Cambiar al directorio principal
cd "$main"
global input "$main/input"
global output "$main/output"

*inserto base de datos 
use "$input/data_russia.dta", clear

*==============================================================================*
*								CLEANING DATA								   *
*==============================================================================*

** 1) Pasamos todas las variables a formato numérico 

*pasamos variables a numericas (factor)
encode sex, gen(sex1) 
drop sex

encode obese, gen(obese1)
replace obese1=. if obese1==1
drop obese

*cambiamos categoria a 1 
replace smokes="1" if smokes=="Smokes"
destring smokes, replace

*pasamos variables a numericas y pasamos los numeros escritos en texto a números 
foreach var of varlist econrk powrnk resprk satlif satecc highsc belief monage cmedin hprblm hosl3m htself wtchng evalhl operat hattac alclmo waistc hhpres tincm_r geo work0 work1 work2 ortho marsta1 marsta2 marsta3 marsta4 { 
    capture confirm string variable `var'
    if _rc == 0 {
        replace `var' = "1" if `var' == "one"
        replace `var' = "2" if `var' == "two"
        replace `var' = "3" if `var' == "three"
        replace `var' = "4" if `var' == "four"
        replace `var' = "5" if `var' == "five"
        replace `var' = "." if `var' == ".b"
		replace `var' = "." if `var' == ".d"
        destring `var', replace
    }
}

*pasamos a numericas variables con split
split hipsiz, gen(hipsiz1)
drop hipsiz12
drop hipsiz11
rename hipsiz13 hipsiz1
replace hipsiz1="." if hipsiz1==","
replace hipsiz1 = subinstr(hipsiz1, ",", ".", .)
destring hipsiz1, replace 
drop hipsiz

split totexpr, gen(totexpr1)
drop totexpr11
drop totexpr12
rename totexpr13 totexpr1
replace totexpr1="." if totexpr1==","
replace totexpr1 = subinstr(totexpr1, ",", ".", .)
destring totexpr1, replace 
drop totexpr

*paso a numerica 
replace tincm_r="." if tincm_r==","
replace tincm_r = subinstr(tincm_r, ",", ".", .)
destring tincm_r, replace 


*2) Vemos cuántos missing tienen las variables 
mdesc // vemos los missing para todas las variables 

*Missing values
*econrk: 28
*powrnk: 87
*resprk: 129
*satlif: 28
*satecc: 12
*highsc: 8 
*belief: 38
*monage: 203
*cmedin: 6
*hosl3m: 2
*htself: 185
*wtchng: 97
*evalhl: 5 
*alclmo: 2
*height: 28
*waistc: 21
*hhpres: 12
*obese1: 203
*hipsiz1: 21
*totexpr1: 187

*vemos si alguna de esas variables tiene mas del 5% de valores faltantes
summarize econrk powrnk resprk satlif satecc highsc belief monage cmedin hosl3m htself wtchng evalhl alclmo height waistc hhpres obese1 hipsiz1 totexpr1

*comparamos el resultado de la cantidad de observaciones por 0.05 con los números de arriba

*3) Reemplazamos outliers con missing 

foreach var of varlist inwgt monage htself height waistc tincm_r {
    summarize `var', detail
    local p99 = r(p99)
    drop if `var' > `p99'
}

*solo para las variables numericas (no las categoricas), sacamos los outliers, definidos como aquellos valores por encima del percentil 99
*Variables: inwgt (individual sample weight), monage (age in months), htself (altura reportada), height (altura), waistc (circumferencia de cintura), tincm_r (ingreso real) 

*4) Ordenamos dataset 
order id site sex1
sort totexpr1 //ordeno de menor a mayor por fila

*DESCRIPTIVE STATISTICS

*5) Agregarle labels a las variables y después summarize 

*Agregamos labels
label var sex1 "Sexo"
label var satlif "Satisfacción con la vida"
label var waistc "Circunferencia de cintura"
label var totexpr1 "Gasto real"

*Genero variable edad en años
gen edad = monage/12 
recast int edad, force // redondeamos los años
label var edad "Edad"

* Guardar las estadísticas descriptivas
estpost summarize sex1 satlif waistc totexpr1 edad

* Exportar la tabla en formato LaTeX con las estadísticas completas
esttab using "$output/tabla_est_descriptivas.tex", ///
    cells("count(fmt(%9.0fc)) mean(fmt(%9.2f)) sd(fmt(%9.2f)) min(fmt(%9.2f)) max(fmt(%9.2f))") ///
    label ///
    collabels("Obs." "Mean" "SD" "Min" "Max") ///
    title("Estadísticas Descriptivas") ///
    replace ///
    tex ///
	nonumber

* 6) 
	* a. 
	
		* Calcular las medias para hombres y mujeres
			summarize hipsiz if sex1 == 2
			local mean_hombres = r(mean)

			summarize hipsiz if sex1 == 1
			local mean_mujeres = r(mean)

		* Creo un gráfico comparando la distribución del tamaño de cadera para hombres y mujeres.
			twoway (kdensity hipsiz if sex1 == 2, lcolor(navy) lpattern(solid) ///
						legend(label(1 "Hombres"))) ///
				   (kdensity hipsiz if sex1 == 1, lcolor(maroon) lpattern(solid) ///
						legend(label(2 "Mujeres"))) ///
				, ///
				title("") ///
				ytitle("Densidad") xtitle("Tamaño de la cadera (cm)") ///
				legend(pos(1) ring(0) box cols(1))
			
		* Exporto el gráfico
				graph export "$output/hipsiz_kernel_density.png", width(1000) replace

		
	* b.
		* Realizo un test T de medias por sexo
			ttest hipsiz, by(sex)
			
		* Guardar los resultados del ttest
			estpost ttest hipsiz, by(sex)

		* Exportar los resultados a LaTeX
			esttab using "$output/ttest_hipsiz.tex", ///
				cells("mu_1(fmt(3)) mu_2(fmt(3)) b(fmt(3)) se(fmt(3)) t(fmt(3)) p(fmt(3))") ///
				label replace ///
				title("Test de Medias: Tamaño de Cadera por Sexo") ///
				collabels("Media M" "Media H" "Dif." "SE" "t-valor" "p-valor") ///
				fragment

							
* 7)

* Preservar el conjunto de datos original para evitar cambios no deseados durante el procesamiento
preserve

* Calcular la media y la desviación estándar de 'satlif' por 'satecc'
collapse (mean) mean_sat=satlif (sd) sd_sat=satlif, by(satecc)

* Generar los límites superior e inferior para las barras de error
generate lower = mean_sat - sd_sat
generate upper = mean_sat + sd_sat

* Formatear la variable mean_sat para que muestre solo dos decimales para mayor claridad
gen mean_sat_formatted = string(mean_sat, "%9.2f")

* Crear un gráfico de barras con barras de error y etiquetas para los valores medios
twoway ///
    (bar mean_sat satecc, ///
        barwidth(0.5) ///
        lcolor(black) ///
        fcolor(navy) ///
        lwidth(medium)) /// Barras de Media con contorno negro
    (rcap lower upper satecc, ///
        lcolor(black) lwidth(medium)) /// Barras de Error
    (scatter mean_sat satecc, ///
        mlabel(mean_sat_formatted) ///
        mlabposition(11) /// Posicionar las etiquetas en la parte superior de la barra
        mlabcolor(black) ///
        mlabsize(medium) ///
        msymbol(none)) /// Sin símbolos, solo etiquetas
, ///
ytitle("Media de Satisfacción con la Vida") ///
xtitle("Satisfacción con la Condición Económica") ///
title("") ///
ylabel(, angle(horizontal)) ///
xlabel(, angle(horizontal)) ///
legend(order(1 "Media de Satisfacción con la Vida" 2 "Barras de Error") pos(6) col(2))

* Exportar el gráfico en formato PNG
gr export "$output/satlif_over_satecc.png", width(1000) replace

* Restaurar el conjunto de datos original
restore

* Preservar los datos originales de nuevo para otro gráfico
preserve 
    * Calcular la media de 'satlif' por 'edad' y 'sex1'
    collapse (mean) mean_sat=satlif, by(edad sex1)

    * Crear un gráfico de dispersión con puntos de media y líneas de ajuste
    twoway (scatter mean_sat edad if sex1==1, mcolor(navy*0.5) msize(medium)) ///
        (lfit mean_sat edad if sex1==1, lcolor(navy) lwidth(medium)) ///
        (scatter mean_sat edad if sex1==2, mcolor(maroon*0.5) msize(medium)) ///
        (lfit mean_sat edad if sex1==2, lcolor(maroon) lwidth(medium)) ///
        , ytitle("Media de Satisfacción con la Vida") ///
            xtitle("Edad (años)") ///
            legend(order(1 "Hombres" 3 "Mujeres") pos(11) ring(0) col(1)) ///
            yscale(range(1 5)) ///
            ylabels(1 "1" 2 "2" 3 "3" 4 "4" 5 "5") 
    gr export "$output/satlif_edad_sexo.png", width(1000) replace

* Restaurar los datos originales nuevamente
restore

preserve
replace sex1 = 0 if sex1 == 2 // Para poder interpretar mejor el coeficiente

* Realizar las regresiones
reg satlif satecc sex1 edad
eststo modelo1

reg satlif satecc marsta1 marsta2 marsta3 marsta4 sex1 edad
eststo modelo2

* Exportar los resultados de las regresiones a LaTeX utilizando esttab
esttab modelo1 modelo2 using "$output/regression_results.tex", ///
    replace style(tex) ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    varlabels(_cons "Constante" satecc "Satisfacción con la Condición Económica" ///
    sex1 "Sexo" edad "Edad" marsta1 "Estado Civil: Casado" ///
    marsta2 "Estado Civil: Viven juntos" marsta3 "Estado Civil: Divorciados" marsta4 "Estado Civil: Viudo") ///
    title("Resultados de las estimaciones") ///
    align( c c ) ///
    keep(satecc sex1 edad marsta1 marsta2 marsta3 marsta4 _cons) ///
    stats(N r2, labels("Observaciones" "R-cuadrado")) ///
    mgroups("Modelo 1" "Modelo 2", pattern(1 0) prefix(\textbf{) suffix(}) span) ///
    mtitles
