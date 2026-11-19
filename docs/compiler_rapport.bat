@echo off
REM Compile les rapports LaTeX (FR + EN) en PDF.
REM Utilisation : double-cliquer ou executer :  compiler_rapport.bat

cd /d "%~dp0"
set ENGINE=

where pdflatex >nul 2>nul && set ENGINE=pdflatex
if not defined ENGINE where xelatex >nul 2>nul && set ENGINE=xelatex
if not defined ENGINE where lualatex >nul 2>nul && set ENGINE=lualatex

if defined ENGINE (
    echo [ENGINE] %ENGINE%
    if exist RAPPORT_Lab07_Sadoune_Fadjr_EN.tex (
        %ENGINE% -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr_EN.tex
        %ENGINE% -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr_EN.tex
    )
    if exist RAPPORT_Lab07_Sadoune_Fadjr.tex (
        %ENGINE% -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
        %ENGINE% -interaction=nonstopmode RAPPORT_Lab07_Sadoune_Fadjr.tex
    )
    goto done
)

where tectonic >nul 2>nul
if %errorlevel%==0 (
    echo [ENGINE] tectonic
    if exist RAPPORT_Lab07_Sadoune_Fadjr_EN.tex tectonic -X compile RAPPORT_Lab07_Sadoune_Fadjr_EN.tex
    if exist RAPPORT_Lab07_Sadoune_Fadjr.tex tectonic -X compile RAPPORT_Lab07_Sadoune_Fadjr.tex
    goto done
)

echo Aucune distribution LaTeX trouvee (pdflatex / xelatex / lualatex / tectonic).
echo Installer MiKTeX : https://miktex.org/download
exit /b 1

:done
echo.
if exist RAPPORT_Lab07_Sadoune_Fadjr_EN.pdf echo PDF EN : %cd%\RAPPORT_Lab07_Sadoune_Fadjr_EN.pdf
if exist RAPPORT_Lab07_Sadoune_Fadjr.pdf echo PDF FR : %cd%\RAPPORT_Lab07_Sadoune_Fadjr.pdf
pause
