@echo off
rem ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
rem :: Recouvrement.cmd - Version 1.0
rem :: Utiliser pour remedier un disfonctionnement ZC 
rem :: lors du chiffrement des dossiers rediriges du profile user.
rem :: Probleme constate en v6.1.2236
rem ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rem :: Positionnement dans le répertoire temp de l'utilisateur et positionnement de l'environnement
pushd %temp%
setlocal

rem :: Définition des variables locales
rem :: Local_Script_Dir : Path du repertoire du script en cours (sans le nom et se terminant par un \)
rem :: Local_Script : Nom du script en cours avec son extension
rem :: Local_Script_Version : Version du script
rem :: Local_Tool_Dir : Path du repertoire des outils (Ici un sous repertoire du repertoire du script en cours)
rem :: Local_Iter : Compteur du nombre d'iteration
rem :: get_Arg1 : Argument 1 passé au script (sans les de debut et de fin)

set Local_Script_Dir=%~dp0
set Local_Script=%~nx0
set Local_Script_Version=1.0
set Local_Tool_Dir=%Local_Script_Dir%\Tools
set Local_Iter=0

set get_Arg1=%~1

rem :: Log information debut du script.
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Script_Start_Time=%Current_Time%
set Script_Start_Date=%Current_Date%
echo [%Current_Date%-%Current_Time%] Debut du script %Local_Script% v%Local_Script_Version%

rem :: Creation d'un repertoire vide (necessaire pour les verifications du mode RAW).
rem :: Att : ne doit pas se terminer par un \
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Dir_Vide=c:\temp\vide
echo [%Current_Date%-%Current_Time%] -- Creation d'un repertoire vide %Local_Dir_Vide%
md %Local_Dir_Vide% >NUL 2>&1

rem :: Creation d'un repertoire temporaire de travail.
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Dir_Temp=c:\temp\%Local_Script%\
echo [%Current_Date%-%Current_Time%] -- Creation d'un repertoire de travail %Local_Dir_Temp%
md "%Local_Dir_Temp%" >NUL 2>&1

rem :: Creation du fichier de reponse pour verifier l'etat du monde RAW
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_ZCACMD_RAW_file=%Local_Dir_Temp%\ZCACMD_Raw.txt
echo [%Current_Date%-%Current_Time%] -- Creation du fichier de reponse ZCACMD_RAW.txt dans %Local_Dir_Temp%
type "%Local_Tool_Dir%\ZCACMD_Raw.txt">%Local_ZCACMD_RAW_file%
echo %Local_Dir_Vide%>>%Local_ZCACMD_RAW_file%

rem :: Determination de la version de ZC et de la presence de l'outil ZCACMD correspondant (Test uniquement pour les v6.1 et v6.2)
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_ZCACMD_RAW_file=%Local_Dir_Temp%\ZCACMD_Raw.txt
set Local_ZC_Version=Indetermine
set Local_ZC_Build=Indetermine
echo [%Current_Date%-%Current_Time%] -- Verification de la version de ZC
echo [%Current_Date%-%Current_Time%] ++++ Pour deternimer la version de ZCACMD a utiliser.
echo [%Current_Date%-%Current_Time%] ++++ Si non determine ou ZCACMD absent, arret du script.
(reg query HKLM\SOFTWARE\Prim'X\ZoneCentral\6.1\Install /v ProductVersion >NUL 2>&1) && Set Local_ZC_Version=6.1
(reg query HKLM\SOFTWARE\Prim'X\ZoneCentral\6.2\Install /v ProductVersion >NUL 2>&1) && Set Local_ZC_Version=6.2

echo [%Current_Date%-%Current_Time%]    Version : %Local_ZC_Version%
rem :: Version non determinee - Sortie du script
if .%Local_ZC_Version% == .Indetermine (call :ExitErrorlevel 1 & exit /B %ERRORVEL%)

for /F "tokens=3" %%I in ('reg query HKLM\SOFTWARE\Prim'X\ZoneCentral\%Local_ZC_Version%\Install /v ProductVersion 2^>NUL') do set Local_ZC_Build=%%I
echo [%Current_Date%-%Current_Time%]    Build   : %Local_ZC_Build%

set Local_ZCACMD_file=%Local_Tool_Dir%\zcacmd v%Local_ZC_Build%.exe
echo [%Current_Date%-%Current_Time%]    ZCACMD  : %Local_ZCACMD_file%

rem :: L'outil ZCACMD existe - Saut directement à la balise de debut de boucle
if EXIST "%Local_ZCACMD_file%" goto :Start

rem :: L'outil ZCACMD n'existe pas - Sortie du script
echo [%Current_Date%-%Current_Time%]    Le fichier %Local_ZCACMD_file% n'est pas present.
(call :ExitErrorlevel 2 & exit /B %ERRORVEL%)


rem :: Balise de debut de boucle (inclut un saut de ligne)
:Start
echo.

rem :: Log debut de boucle
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set /A Local_Iter+=1
echo [%Current_Date%-%Current_Time%] -- Comptage du nombre d'iteration.
echo [%Current_Date%-%Current_Time%]    Iteration : %Local_Iter% 

rem :: Verification de la presence d'un répertoire en mode RAW (RepRAW)
rem :: Les commandes suivantes sont passees à la commande ZCACMD RAW : 2 [Enter] 1 [Enter] le chemin du repertoire vide [Enter]
rem :: S'il y a un repertoire en mode RAW, il y a le menu qui s'affiche. 
rem :: Les actions 2 [Enter] 1 [Enter] permettent de remettre le repertoire en mode normale.
rem :: L'action le chemin du repertoire vide [Enter] n'est pas prise en compte car le process ZCACMD est deja terminé
rem :: S'il n'y a pas de repertoire en mode RAW, il faut entrer directement le repertoire a passe en mode raw.
rem :: Les actions 2 [Enter] 1 [Enter] generent des erreurs (vu qu'il n'y a pas de répertoire 1 ou 2)
rem :: L'action le chemin du repertoire vide [Enter] permet de repond a la demandeZCACMD, et bascule répertoire vide en mode RAW
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\ZCACMD-RAWQuery-%RANDOM%.log
echo [%Current_Date%-%Current_Time%] -- Lancement de la command "ZCACMD.exe raw" pour detecter et sortir du mode de maintenance.
echo [%Current_Date%-%Current_Time%] -- Resultat dans %Local_Command_Log%
echo [%Current_Date%-%Current_Time%] ++++ Pour eviter un blocage si pas de zone en maintenance, cela basculera le repertoire %Local_Dir_Vide% en maintenance transitoire.
call "%Local_ZCACMD_file%" raw -g "%Local_Command_Log%" <"%Local_ZCACMD_RAW_file%"

rem :: Verification de la presence de l'information "Emplacement(s) actuellement en mode 'raw' ou en cours de maintenance"
rem :: pour verifier s'il y a une zone déja en RAW
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
echo [%Current_Date%-%Current_Time%] -- Verification du resultat de la commande "ZCACMD.exe raw".
find /I "Emplacement(s) actuellement en mode 'raw' ou en cours de maintenance" "%Local_Command_Log%" >NUL 2>&1
set Current_Command_Error=%errorlevel%

rem :: Pas de zone en maintenance - Remise du répertoire vide en mode normal - Sortie du script
if .%Current_Command_Error% == .1 (call :RawError1 || (call :ExitErrorlevel 0 & exit /B %ERRORVEL%) )  
rem :: Presence d'une zone en maintenance - Recuperation du repertoire en maintenance (RepRAW)
if .%Current_Command_Error% == .0 call :RawError0

rem :: Passage volontaire du répertoire RepRAW en maintenance
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\ZCACMD-RAWSet-%RANDOM%.log
echo [%Current_Date%-%Current_Time%] -- Lancement de la commande "ZCACMD.exe raw" pour basculer la zone %Current_Zone% en maintenance.
echo [%Current_Date%-%Current_Time%] -- Resultat dans %Local_Command_Log%
echo [%Current_Date%-%Current_Time%] ++++ Ceci pour sauvegarder les fichiers.
call "%Local_ZCACMD_file%" raw -g "%Local_Command_Log%" -s "%Current_Zone%"

rem :: Sauvegarde du contenu du repertoire RepRAW dans un ss répertoire de travail et suppression des fichiers
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\Robocopy-%RANDOM%.log
set Local_Copy_Folder=%Local_Dir_Temp%\Lecteur_%Current_Zone::=%
echo [%Current_Date%-%Current_Time%] -- Sauvegarde les fichiers de %Current_Zone% dans %Local_Copy_Folder% 
echo [%Current_Date%-%Current_Time%] -- Resultat dans %Local_Command_Log%
echo [%Current_Date%-%Current_Time%] ++++ Ceci pour sauvegarder les fichiers et les supprimer de la source.
call "Robocopy" "%Current_Zone%" "%Local_Copy_Folder%" "*.*" /E /MOV /R:1 /W:1 /LOG:"%Local_Command_Log%" /TEE /NP

ccall :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\ZCACMD-RAWUnset-%RANDOM%.log
echo [%Current_Date%-%Current_Time%] -- Lancement de la commande "ZCACMD.exe raw" pour basculer la zone %Current_Zone% en mode normal.
echo [%Current_Date%-%Current_Time%] -- Resultat dans %Local_Command_Log%
call "%Local_ZCACMD_file%" raw -g "%Local_Command_Log%" -u "%Current_Zone%"

rem :: Recouvrement du répertoire RepRAW (si user est architecte) sinon l'action est faire pendant la verification du chiffrement.
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\ZCACMD-RECOVER-%RANDOM%.log
echo [%Current_Date%-%Current_Time%] -- Lancement de la commande "ZCACMD.exe recover" pour reparer la zone %Current_Zone%.
echo [%Current_Date%-%Current_Time%] -- Resultat dans %Local_Command_Log%
call "%Local_ZCACMD_file%" recover -g "%Local_Command_Log%" -z "%Current_Zone%"

rem :: Declenchement de la verification du chiffrement.
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\ZCACMD-RECOVER-%RANDOM%.log
echo [%Current_Date%-%Current_Time%] -- Lancement de la commande "ZCAPPLY.exe -nostart -applypoliciesdirectives" pour reprendre le primo chiffrement.
echo [%Current_Date%-%Current_Time%] -- Resultat dans le repertoire standard des log ZC.
start "Fenetre ZCAPPLY" /wait "c:\Program Files\Prim'X\ZoneCentral\zcapply.exe" -nostart -applypoliciesdirectives
pause

rem :: Ici a voir s'il faut des actions complementaires.
rem :: en cas de disparition de ZCAPPLY, blocage de ZCU.....

rem :: Fin de la boucle
rem :: Saut directement à la balise de debut de boucle pour reverifier si le probleme est toujours present apres cette verification du chiffrement
Goto :Start

exit /B 0

rem :: Call pour recuperer la date et l'heure (pour la log)
:LNow
set LNow_date=%date%
set LNow_date=%LNow_date: =0%
set LNow_date=%LNow_date:/=%
set LNow_time=%time%
set LNow_time=%LNow_time: =0%
set LNow_time=%LNow_time::=%
set LNow_time=%LNow_time:~0,6%
exit /B 0

rem :: Call en cas : pas de zone en maintenance
rem :: Remettre le repertoire vide en mode normal (basculer en RAW lors du test)
:RawError1
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Local_Command_Log=%Local_Dir_Temp%\ZCACMD-RAWUnset-%RANDOM%.log
echo [%Current_Date%-%Current_Time%]    Aucun Zone en maintenance.
echo [%Current_Date%-%Current_Time%] ++++ Remise du repertoire %Local_Dir_Vide% en mode normal.
call "%Local_ZCACMD_file%" raw -u "%Local_Dir_Vide%" -g "%Local_Command_Log%"
exit /B 1

rem :: Call en cas : zone en maintenance
rem :: Determination du repertoire en maintenance en fonction des informations de la commande ZCACMD
:RawError0
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
set Current_Zone=
echo [%Current_Date%-%Current_Time%]    Une Zone etait en maintenance, determination de la zone en question.
for /F "skip=1 tokens=1* delims=-" %%I in ('find /I "raw -unset" "%Local_Command_Log%"') do set Current_Zone=%%J
set Current_Zone=%Current_Zone:~7,-1%
echo [%Current_Date%-%Current_Time%]    Zone : %Current_Zone%
exit /B 0

rem :: Call de sortie du script
rem :: Affichage des informations
:ExitErrorlevel
echo.
call :LNow
set Current_Time=%LNow_time%
set Current_Date=%LNow_date%
Set Fin_Errorlevel=%~1
echo [%Current_Date%-%Current_Time%] Fin du script %Local_Script% v%Local_Script_Version%
echo [%Current_Date%-%Current_Time%] Errorlevel : %Fin_Errorlevel%
echo [%Current_Date%-%Current_Time%] Debut du script : %Script_Start_Date%-%Script_Start_Time%
echo [%Current_Date%-%Current_Time%] Fin du script   : %Current_Date%-%Current_Time%
echo [%Current_Date%-%Current_Time%] Nombre d'iteration : %Local_Iter%


exit /B %Fin_Errorlevel%

