@echo off
setlocal enabledelayedexpansion

REM Ruta de la carpeta con los archivos
set "carpeta_archivos=C:\Users\quintc\Henkel\dx Iberia - Assets Mgmt Spain\PCLC\LC 2025\Blancco Reports"

REM Archivo con los números de serie
set "archivo_series=C:\Users\quintc\OneDrive - Henkel\Henkel\Software\scripts\pclc_blancco\numeros.txt"

REM Archivo donde se guardan los que no se encuentran
set "no_encontrados=C:\Users\quintc\OneDrive - Henkel\Henkel\Software\scripts\pclc_blancco\not-found.txt"

REM Limpiar archivo de no encontrados si existe
if exist "!no_encontrados!" del "!no_encontrados!"

for /f "usebackq delims=" %%s in ("%archivo_series%") do (
    set "serie=%%s"
    set "encontrado=false"
    
    for %%f in ("%carpeta_archivos%\*") do (
        echo %%~nxf | findstr /i "!serie!" >nul
        if !errorlevel! == 0 (
            set "encontrado=true"
        )
    )

    if "!encontrado!" == "false" (
        echo !serie! >> "!no_encontrados!"
        echo No encontrado: !serie!
    ) else (
        echo Encontrado: !serie!
    )
)

echo Proceso terminado.
pause
