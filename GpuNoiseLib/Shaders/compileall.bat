setlocal

SET TWOMGFX="C:\Program Files (x86)\MSBuild\MonoGame\v3.0\Tools\2mgfx.exe"

@for /f %%f IN ('dir /b *.fx') do (

  call %TWOMGFX% %%~nf.fx Compiled\%%~nf.ogl.mgfxo

  call %TWOMGFX% %%~nf.fx Compiled\%%~nf.dx11.mgfxo /Profile:DirectX_11

)

endlocal