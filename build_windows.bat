@echo off
echo.
echo === CONFIGURANDO AMBIENTE PARA BUILD WINDOWS ===
echo.

:: 1. Configura ambiente MSVC (OBRIGATÓRIO!)
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

:: 2. Define PATH mínimo + Flutter + CMake do VS + PowerShell
set "PATH=C:\src\flutter\bin;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64;C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0"

echo.
echo VERIFICAÇÃO:
echo Flutter: & where flutter
echo CMake:   & where cmake
echo cl.exe:  & where cl
echo Powershell: & where powershell
echo.

:: 3. Limpa builds anteriores e instala dependências
flutter clean
flutter pub get
echo.
echo === COMPILANDO PARA WINDOWS ===
flutter build windows -v

echo.
echo === SUCESSO! Executável em: build\windows\x64\runner\Release\controle_financeiro.exe ===
pause
