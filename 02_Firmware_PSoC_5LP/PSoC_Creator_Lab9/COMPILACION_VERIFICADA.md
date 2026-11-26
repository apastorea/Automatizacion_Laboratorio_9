# Compilación verificada del workspace Lab9

Fecha: 25/11/2026  
Herramienta: PSoC Creator 4.4, ARM GCC 5.4-2016-q2-update  
Configuración: Release

```text
cyprjmgr -wrk Lab9.cywrk -clean -build -c Release -warn High
```

Resultado: compilación exitosa, sin advertencias.

- Dispositivo: `CY8C5888LTQ-LP097`.
- Flash: 9560 de 262144 bytes (3,6 %).
- SRAM: 33889 de 65536 bytes (51,7 %).
- Salidas: `Lab9.hex` y `Lab9.elf`.
- Modo predeterminado: `LAB9_MODO_MONITOR`.
- Enclavamientos de actuación: cuatro valores en cero.

La compilación no programa el dispositivo ni autoriza el lazo físico.
