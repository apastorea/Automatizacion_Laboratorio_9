function archivos = capturar_ensayo_rigol_lab9(caso, perfil)
% CAPTURAR_ENSAYO_RIGOL_LAB9 Adquiere UART y dos canales del DS1202Z-E.
%   ARCHIVOS = CAPTURAR_ENSAYO_RIGOL_LAB9(CASO) arma el osciloscopio en
%   disparo unico, espera que el PSoC sea programado para el caso indicado,
%   intenta recibir 600 muestras UART y guarda las formas de onda de CH1 y
%   CH2 aun cuando COM4 no entregue una trama nueva. El JSON de metadatos
%   distingue explicitamente una adquisicion sincronizada de una independiente.
%   CAPTURAR_ENSAYO_RIGOL_LAB9(CASO,"zoom") crea archivos separados con
%   10 mV/div en ambos canales y dispara por CH2. El perfil "sensibilidad"
%   reduce ambas escalas a 5 mV/div y el umbral a 4 mV para determinar si una
%   sonda fisicamente colocada en 10X esta configurada como 1X en el equipo.
%   El perfil "conexion" usa 10 mV/div, centra la ventana en +20 mV y eleva
%   el disparo de CH1 a 25 mV para la prueba abierta. CH1 se encuentra en J5
%   (mando) y CH2 en J7 (salida física de la planta).
%   Ninguno de estos perfiles sobrescribe la evidencia cuantitativa del perfil
%   predeterminado "dinamico".
%
%   Conexion del montaje usada en el laboratorio:
%     CH1: J5, mando físico aplicado a la planta.
%     CH2: J7, salida física de la planta y(t).
%     COM4: telemetria UART del PSoC a 115200 bit/s.
%
%   El PSoC debe permanecer inicialmente en MONITOR. Ejecute esta funcion y,
%   cuando aparezca el mensaje de espera, programe desde PSoC Creator el caso
%   LQR solicitado. El firmware espera 3 s antes de iniciar la adquisicion.

arguments
    caso (1,1) double {mustBeInteger,mustBeMember(caso,1:3)}
    perfil (1,1) string {mustBeMember(perfil, ...
        ["dinamico" "zoom" "sensibilidad" "conexion"])} = ...
        "dinamico"
end

% Las rutas se resuelven desde el propio archivo para que la adquisicion no
% dependa de la carpeta activa. Los resultados nuevos llevan el prefijo
% "rigol" y no sobrescriben las capturas UART previamente validadas.
carpetaScript = fileparts(mfilename("fullpath"));
carpetaCapturas = fullfile(carpetaScript, "..", "04_Ensayos", "capturas");
if ~isfolder(carpetaCapturas)
    mkdir(carpetaCapturas);
end
if perfil == "zoom"
    sufijo = "_zoom";
elseif perfil == "sensibilidad"
    sufijo = "_sensibilidad";
elseif perfil == "conexion"
    sufijo = "_conexion";
else
    sufijo = "";
end
rutaUART = fullfile(carpetaCapturas, ...
    "rigol_caso_"+caso+sufijo+"_uart_lab9.csv");
rutaScope = fullfile(carpetaCapturas, ...
    "rigol_caso_"+caso+sufijo+"_dos_canales_lab9.csv");
rutaPantalla = fullfile(carpetaCapturas, ...
    "rigol_caso_"+caso+sufijo+"_pantalla_lab9.png");
rutaMetadatos = fullfile(carpetaCapturas, ...
    "rigol_caso_"+caso+sufijo+"_metadatos_lab9.json");
rutaArmado = fullfile(carpetaCapturas, ...
    "rigol_caso_"+caso+"_armado.tmp");
rutaProgramado = fullfile(carpetaCapturas, ...
    "rigol_caso_"+caso+"_programado.tmp");
archivosTemporales = [rutaArmado, rutaProgramado];
for rutaTemporal = archivosTemporales
    if isfile(rutaTemporal)
        delete(rutaTemporal);
    end
end

% Primero se abre solo el osciloscopio. COM4 comparte el dispositivo USB del
% KitProg con el programador SWD; mantenerlo abierto durante Program impide
% que PSoC Creator seleccione el blanco en algunas estaciones Windows.
recursoVISA = "USB0::0x1AB1::0x0517::DS1ZE275014864::0::INSTR";

% El DS1202Z-E de esta estacion bloquea sesiones visadev consecutivas con su
% firmware 00.06.04. Se usa el proveedor NI-VISA .NET ya instalado, que abre
% y cierra el mismo recurso USB-TMC de forma determinista. Las advertencias de
% ensamblado duplicado se silencian solo durante la carga desde el GAC local.
programFiles = getenv("ProgramFiles");
rutaIvi = fullfile(programFiles, "IVI Foundation", "VISA", ...
    "Microsoft.NET", "Framework64", "v4.0.30319", ...
    "VISA.NET Shared Components 8.0.2", "Ivi.Visa.dll");
rutaNi = fullfile(programFiles, "IVI Foundation", "VISA", ...
    "Microsoft.NET", "Framework64", "v4.0.30319", ...
    "NI VISA.NET 26.3", "NationalInstruments.Visa.dll");
estadoAvisos = warning;
warning("off", "all");
NET.addAssembly(rutaIvi);
NET.addAssembly(rutaNi);
warning(estadoAvisos);
gerenciadorVISA = NationalInstruments.Visa.ResourceManager();
osciloscopio = gerenciadorVISA.Open(char(recursoVISA));
osciloscopio.TimeoutMilliseconds = 10000;
osciloscopio.TerminationCharacter = uint8(10); % LF de las respuestas SCPI.
osciloscopio.TerminationCharacterEnabled = true;
limpieza = onCleanup(@() liberarInterfaces(osciloscopio, gerenciadorVISA));

% La identificacion impide adquirir accidentalmente desde otro instrumento.
identificacion = strtrim(consultarScpi(osciloscopio, "*IDN?"));
assert(contains(identificacion, "RIGOL TECHNOLOGIES,DS1202Z-E"), ...
    "LAB9:InstrumentoIncorrecto", ...
    "La interfaz VISA no corresponde al RIGOL DS1202Z-E esperado.");

% El perfil dinamico esta optimizado para una respuesta positiva de 50 mV.
% CH1, conectado a J5, usa 20 mV/div para abarcar el mando bipolar previsto.
% CH2, conectado a J7, usa 10 mV/div y offset de +20 mV para presentar la
% salida entre aproximadamente -20 y +60 mV. El limite de ancho de banda y
% el modo de alta resolucion
% reducen ruido de alta frecuencia sin promediar ejecuciones distintas.
%
% Su disparo se eleva de 20 a 35 mV. Este nivel permanece por debajo de la
% meseta esperada, pero por encima de los picos espurios de 20--24 mV que
% dispararon prematuramente las adquisiciones iniciales mientras el PSoC aun
% estaba en MONITOR. El perfil zoom usa 10 mV/div sin offset en ambos canales
% y dispara por CH2 a 8 mV para investigar un posible transitorio de baja
% amplitud. El perfil sensibilidad baja a 5 mV/div y 4 mV de disparo: queda
% por encima del fondo previo de 2.4 mV, pero permite detectar una orden de
% 50--77 mV atenuada aproximadamente diez veces por una sonda en 10X. La base
% de 200 ms/div cubre el pulso y su retorno en todos los perfiles.
if perfil == "zoom"
    escalaCH1 = 0.01;
    escalaCH2 = 0.01;
    offsetCH1 = 0;
    offsetCH2 = 0;
    fuenteDisparo = "CHAN2";
    nivelDisparo = 0.008;
elseif perfil == "sensibilidad"
    escalaCH1 = 0.005;
    escalaCH2 = 0.005;
    offsetCH1 = 0;
    offsetCH2 = 0;
    fuenteDisparo = "CHAN2";
    nivelDisparo = 0.004;
elseif perfil == "conexion"
    % En el ensayo abierto se dispara con el mando físico J5 a 25 mV. CH2
    % registra simultáneamente la respuesta de la planta en J7.
    escalaCH1 = 0.02;
    escalaCH2 = 0.01;
    offsetCH1 = 0;
    offsetCH2 = 0.02;
    fuenteDisparo = "CHAN1";
    nivelDisparo = 0.025;
else
    escalaCH1 = 0.02;
    escalaCH2 = 0.01;
    offsetCH1 = 0;
    offsetCH2 = 0.02;
    fuenteDisparo = "CHAN2";
    nivelDisparo = 0.025;
end

% Los perfiles de control esperan una cabecera LQR; la prueba de conexion
% espera ABIERTO. Esto impide declarar sincronizada una trama de otro ensayo.
if perfil == "conexion"
    modoEsperado = "ABIERTO";
else
    modoEsperado = "LQR";
end
comandosAdquisicion = [":STOP"; ":CHAN1:DISP ON"; ":CHAN2:DISP ON"; ...
    ":CHAN1:COUP DC"; ":CHAN2:COUP DC"; ":CHAN1:PROB 1"; ...
    ":CHAN2:PROB 1"; ":CHAN1:BWL 20M"; ":CHAN2:BWL 20M"; ...
    ":CHAN1:SCAL "+escalaCH1; ":CHAN2:SCAL "+escalaCH2; ...
    ":CHAN1:OFFS "+offsetCH1; ":CHAN2:OFFS "+offsetCH2; ":TIM:MODE MAIN"; ...
    ":TIM:MAIN:SCAL 0.2"; ":TIM:MAIN:OFFS 0"; ":ACQ:TYPE HRES"; ...
    ":TRIG:MODE EDGE"; ":TRIG:EDGE:SOUR "+fuenteDisparo; ...
    ":TRIG:EDGE:COUP DC"; ":TRIG:EDGE:SLOP POS"; ...
    ":TRIG:EDGE:LEV "+nivelDisparo];
for comando = comandosAdquisicion'
    escribirScpi(osciloscopio, comando);
end

% El archivo centinela permite que la automatizacion programe el PSoC solo
% cuando VISA ya identifico y armo el instrumento. De este modo no compiten
% el programador del PSoC y el controlador USB-TMC durante la apertura.
writelines("ARMADO", rutaArmado, Encoding="UTF-8");

fprintf("RIGOL configurado para el caso %d, perfil %s. Programe ahora " + ...
    "el PSoC desde PSoC Creator.\n", caso, perfil);

% La automatizacion crea PROGRAMADO solo despues de que PSoC Creator termina
% el ciclo SWD. Recién entonces se abre COM4, dentro de la espera de 3 s que
% el firmware deja antes del escalon, evitando toda contencion con KitProg.
relojProgramador = tic;
while ~isfile(rutaProgramado) && toc(relojProgramador) < 120
    pause(0.02);
end
assert(isfile(rutaProgramado), "LAB9:PSoCNoProgramado", ...
    "No se recibio la confirmacion de programacion del PSoC.");
delete(rutaProgramado);

% SINGLE se envia despues de la programacion. Asi el osciloscopio no puede
% dispararse por el ruido producido durante el ciclo SWD y queda armado dentro
% de la espera de seguridad de 3 s anterior al escalon del firmware.
escribirScpi(osciloscopio, ":SING");
puerto = serialport("COM4", 115200, "Timeout", 2);
configureTerminator(puerto, "LF");
flush(puerto);

% Se descartan mensajes previos hasta hallar los metadatos LQR del caso. A
% partir de ellos se conserva el bloque completo hasta las 600 filas de datos.
lineas = strings(0, 1);
capturaCorrecta = false;
filasDatos = 0;
relojEspera = tic;
while toc(relojEspera) < 12 && filasDatos < 600
    if puerto.NumBytesAvailable == 0
        pause(0.02);
        continue
    end
    % NumBytesAvailable puede ser positivo aunque la trama aun no contenga
    % el terminador LF. En ese caso readline agota su Timeout y devuelve un
    % arreglo vacio; se convierte explicitamente a string y se reintenta en
    % lugar de abortar la adquisicion durante strip.
    lectura = readline(puerto);
    if isempty(lectura)
        continue
    end
    linea = strip(string(lectura));
    if startsWith(linea, "# LAB9") && ...
            contains(linea, "modo="+modoEsperado) && ...
            contains(linea, "caso="+caso+" ")
        capturaCorrecta = true;
    end
    if capturaCorrecta
        lineas(end+1, 1) = linea; %#ok<AGROW>
        if ~isempty(regexp(linea, '^\d+,', 'once'))
            filasDatos = filasDatos+1;
        end
    end
end
uartSincronizada = capturaCorrecta && filasDatos == 600;
if uartSincronizada
    writelines(lineas, rutaUART, Encoding="UTF-8");
else
    % El osciloscopio es una medicion fisica independiente. Si el puente
    % KitProg-UART no entrega datos, no se descarta la forma de onda: se usa
    % como respaldo la captura UART experimental ya validada para este caso
    % y se registra la falta de sincronismo en los metadatos JSON.
    rutaUARTRespaldo = fullfile(carpetaCapturas, "caso_"+caso+"_uart.csv");
    assert(isfile(rutaUARTRespaldo), "LAB9:UARTRespaldoAusente", ...
        "No existe una captura UART experimental valida del caso %d.", caso);
    rutaUART = rutaUARTRespaldo;
    warning("LAB9:UARTNoSincronizada", ...
        "COM4 no entrego 600 filas; se conserva la captura RIGOL y se " + ...
        "referencia la UART experimental validada del caso %d.", caso);
end
if isfile(rutaArmado)
    delete(rutaArmado);
end

% Una adquisicion SINGLE debe quedar detenida tras el disparo. Se fuerza STOP
% despues del volcado UART para congelar exactamente la forma de onda visible.
% El estado se consulta antes de detener: WAIT demuestra que el umbral no fue
% alcanzado y evita presentar una linea base como si fuera un transitorio.
estadoDisparo = upper(string(strtrim( ...
    consultarScpi(osciloscopio, ":TRIG:STAT?"))));
disparoDetectado = estadoDisparo == "STOP";
if ~disparoDetectado
    warning("LAB9:RIGOLSinDisparo", ...
        "El RIGOL permanecio en %s; se guardara la linea base diagnostica.", ...
        estadoDisparo);
end
escribirScpi(osciloscopio, ":STOP");
[tiempo1_s, canal1_V, preambulo1] = leerCanal(osciloscopio, "CHAN1");
[tiempo2_s, canal2_V, preambulo2] = leerCanal(osciloscopio, "CHAN2");
assert(numel(tiempo1_s) == numel(tiempo2_s), ...
    "LAB9:LongitudesScope", "Los canales tienen longitudes diferentes.");
assert(max(abs(tiempo1_s-tiempo2_s)) < 1e-9, ...
    "LAB9:TiemposScope", "Las bases temporales de CH1 y CH2 no coinciden.");

% El CSV conserva unidades SI para evitar conversiones implicitas. El tiempo
% es relativo al punto de disparo definido por el preambulo del instrumento.
capturaScope = table(tiempo1_s, canal1_V, canal2_V, ...
    VariableNames=["t_s", "ch1_mando_V", "ch2_salida_V"]);
writetable(capturaScope, rutaScope);

% La imagen nativa del RIGOL constituye evidencia visual independiente del
% CSV. Se solicita en PNG color sin inversion mediante un bloque binario TMC.
imagen = consultarBloqueBinario(osciloscopio, ":DISP:DATA? ON,OFF,PNG");
identificador = fopen(rutaPantalla, "w");
assert(identificador >= 0, "LAB9:ArchivoPantalla", ...
    "No se pudo crear el archivo PNG del RIGOL.");
limpiezaArchivo = onCleanup(@() fclose(identificador));
fwrite(identificador, imagen, "uint8");
clear limpiezaArchivo

% Los metadatos permiten reconstruir la conversion de cuentas a voltios y
% vinculan cada archivo con el numero de serie fisico del osciloscopio.
metadatos = struct("caso", caso, "perfil", perfil, ...
    "modoEsperado", modoEsperado, ...
    "instrumento", identificacion, ...
    "recursoVISA", recursoVISA, "canal1", "J5: mando fisico", ...
    "canal2", "J7: salida fisica de planta", ...
    "preambuloCH1", preambulo1, ...
    "preambuloCH2", preambulo2, "muestrasUART", filasDatos, ...
    "uartSincronizada", uartSincronizada, "archivoUART", rutaUART, ...
    "muestrasScope", height(capturaScope), "escalaCH1_Vdiv", escalaCH1, ...
    "escalaCH2_Vdiv", escalaCH2, "offsetCH1_V", offsetCH1, ...
    "offsetCH2_V", offsetCH2, ...
    "fuenteDisparo", fuenteDisparo, "nivelDisparo_V", nivelDisparo, ...
    "estadoDisparo", estadoDisparo, "disparoDetectado", disparoDetectado);
writelines(jsonencode(metadatos, PrettyPrint=true), rutaMetadatos, ...
    Encoding="UTF-8");

archivos = struct("uart", rutaUART, "scope", rutaScope, ...
    "pantalla", rutaPantalla, "metadatos", rutaMetadatos);
fprintf("Captura RIGOL del caso %d guardada; disparo detectado=%d.\n", ...
    caso, disparoDetectado);
end

function [tiempo_s, voltaje_V, preambulo] = leerCanal(instrumento, canal)
% LEERCANAL Recupera los 1200 puntos visibles y aplica el preambulo RIGOL.
    escribirScpi(instrumento, ":WAV:SOUR "+canal);
    escribirScpi(instrumento, ":WAV:MODE NORM");
    escribirScpi(instrumento, ":WAV:FORM BYTE");
    escribirScpi(instrumento, ":WAV:STAR 1");
    escribirScpi(instrumento, ":WAV:STOP 1200");
    valores = str2double(split(strtrim(consultarScpi(instrumento, ...
        ":WAV:PRE?")), ","));
    assert(numel(valores) == 10 && all(isfinite(valores)), ...
        "LAB9:PreambuloRigol", "Preambulo de forma de onda invalido.");
    cuentas = consultarBloqueBinario(instrumento, ":WAV:DATA?");

    xIncremento = valores(5);
    xOrigen = valores(6);
    xReferencia = valores(7);
    yIncremento = valores(8);
    yOrigen = valores(9);
    yReferencia = valores(10);
    indices = (0:numel(cuentas)-1)';
    tiempo_s = (indices-xReferencia)*xIncremento+xOrigen;
    voltaje_V = (double(cuentas(:))-yOrigen-yReferencia)*yIncremento;
    preambulo = valores(:)';
end

function escribirScpi(instrumento, comando)
% ESCRIBIRSCPI Envia un comando ASCII con el terminador LF requerido.
    instrumento.RawIO.Write(char(string(comando)+newline));
end

function respuesta = consultarScpi(instrumento, comando)
% CONSULTARSCPI Ejecuta una consulta ASCII y devuelve texto MATLAB.
    escribirScpi(instrumento, comando);
    respuesta = string(char(instrumento.RawIO.ReadString()));
end

function datos = consultarBloqueBinario(instrumento, comando)
% CONSULTARBLOQUEBINARIO Decodifica un bloque IEEE 488.2 #Nxxxxxxxxx<data>.
%   El proveedor NI-VISA entrega como maximo 1024 bytes por lectura en este
%   instrumento. Por eso se lee primero el encabezado y luego se acumulan
%   fragmentos hasta completar la longitud declarada, mas el LF residual.
    terminadorPrevio = instrumento.TerminationCharacterEnabled;
    instrumento.TerminationCharacterEnabled = false;
    limpiezaTerminador = onCleanup(@() restaurarTerminador( ...
        instrumento, terminadorPrevio));
    escribirScpi(instrumento, comando);

    encabezado = uint8(instrumento.RawIO.Read(int64(2)));
    assert(numel(encabezado) == 2 && encabezado(1) == uint8('#'), ...
        "LAB9:BloqueRigol", "Encabezado binario RIGOL invalido.");
    cantidadDigitos = str2double(char(encabezado(2)));
    assert(isfinite(cantidadDigitos) && cantidadDigitos >= 1, ...
        "LAB9:BloqueRigol", "Longitud binaria RIGOL invalida.");
    textoLongitud = uint8(instrumento.RawIO.Read(int64(cantidadDigitos)));
    cantidadDatos = str2double(char(textoLongitud));
    assert(isfinite(cantidadDatos) && cantidadDatos > 0, ...
        "LAB9:BloqueRigol", "Bloque binario RIGOL vacio.");

    respuesta = uint8.empty(0, 1);
    while numel(respuesta) < cantidadDatos
        faltantesConLF = cantidadDatos+1-numel(respuesta);
        fragmento = uint8(instrumento.RawIO.Read(int64(faltantesConLF)));
        assert(~isempty(fragmento), "LAB9:BloqueRigol", ...
            "El bloque binario RIGOL termino antes de lo declarado.");
        respuesta = [respuesta; fragmento(:)]; %#ok<AGROW>
    end
    datos = respuesta(1:cantidadDatos);
    instrumento.TerminationCharacterEnabled = terminadorPrevio;
    clear limpiezaTerminador
end

function restaurarTerminador(instrumento, estado)
% RESTAURARTERMINADOR Repone el modo ASCII aun si falla una lectura binaria.
    instrumento.TerminationCharacterEnabled = estado;
end

function liberarInterfaces(osciloscopio, gerenciadorVISA)
% LIBERARINTERFACES Lleva el RIGOL a STOP y libera las sesiones NI-VISA.
    try
        escribirScpi(osciloscopio, ":STOP");
    catch
    end
    try
        osciloscopio.Dispose();
    catch
    end
    try
        gerenciadorVISA.Dispose();
    catch
    end
end
