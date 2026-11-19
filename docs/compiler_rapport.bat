@echo off
REM Compile le rapport LaTeX en PDF.
REM Utilisation : double-cliquer ou executer :  compiler_rapport.bat

cd /d "%~dp0"

where pdflatex >nul 2>nul
if %errorlevel%==0 (
    echo [1/2] pdflatex...
    pdflatex -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    pdflatex -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    goto done
)

where xelatex >nul 2>nul
if %errorlevel%==0 (
    echo [1/2] xelatex...
    xelatex -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    xelatex -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    goto done
)

where lualatex >nul 2>nul
if %errorlevel%==0 (
    echo [1/2] lualatex...
    lualatex -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    lualatex -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    goto done
)

where tectonic >nul 2>nul
if %errorlevel%==0 (
    echo [1/2] tectonic...
    tectonic -X compile RAPPORT_Lab07_Sadoune_Fadjr.tex --keep-logs
    goto done
)

echo Aucune distribution LaTeX trouvee (pdflatex / xelatex / lualatex / tectonic).
echo Installer MiKTeX : https://miktex.org/download
exit /b 1

:done
if exist RAPPORT_Lab07_Sadoune_Fadjr.pdf (
    echo.
    echo PDF genere : %cd%\RAPPORT_Lab07_Sadoune_Fadjr.pdf
) else (
    echo Echec de la compilation, voir le fichier .log
)
pause
