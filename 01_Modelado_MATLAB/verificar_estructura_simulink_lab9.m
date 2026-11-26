% VERIFICAR_ESTRUCTURA_SIMULINK_LAB9 Comprueba conectividad y renderiza modelo.
% No modifica ni guarda el archivo SLX.

clearvars;

carpetaModelo = fileparts(mfilename("fullpath"));
modelo = "lab9_control_optimo";
lab9Caso = 1;
lab9Planta = "identificada";
inicializar_simulink_lab9;

open_system(modelo);
% La actualizacion fuerza la compilacion del diagrama antes de inspeccionar
% conectividad, de modo que tambien se detecten parametros no resolubles.
set_param(modelo, "SimulationCommand", "update");

bloques = find_system(modelo, "LookUnderMasks", "all", ...
    "FollowLinks", "on", "Type", "block");
puertosSinConexion = strings(0,1);

% Se inspeccionan puertos de senal, activacion, disparo y conexiones fisicas.
for i = 1:numel(bloques)
    puertos = get_param(bloques{i}, "PortHandles");
    campos = ["Inport", "Outport", "Enable", "Trigger", ...
        "State", "LConn", "RConn"];
    for j = 1:numel(campos)
        nombreCampo = campos(j);
        if ~isfield(puertos, nombreCampo)
            continue;
        end
        manejadores = puertos.(nombreCampo);
        for k = 1:numel(manejadores)
            if get_param(manejadores(k), "Line") == -1
                puertosSinConexion(end+1,1) = ...
                    string(bloques{i}) + ":" + nombreCampo + k; %#ok<SAGROW>
            end
        end
    end
end

% Una linea es colgante si carece de origen o de al menos un destino valido.
lineas = find_system(modelo, "FindAll", "on", "Type", "line");
lineasColgantes = 0;
for i = 1:numel(lineas)
    origen = get_param(lineas(i), "SrcPortHandle");
    destinos = get_param(lineas(i), "DstPortHandle");
    if origen == -1 || isempty(destinos) || any(destinos == -1)
        lineasColgantes = lineasColgantes+1;
    end
end

assert(isempty(puertosSinConexion), ...
    "Hay puertos sin conexión:\n%s", join(puertosSinConexion, newline));
assert(lineasColgantes == 0, "Hay %d líneas colgantes.", lineasColgantes);

carpetaFiguras = fullfile(carpetaModelo, "..", "05_Resultados", "figuras");
if ~isfolder(carpetaFiguras), mkdir(carpetaFiguras); end
rutaFigura = fullfile(carpetaFiguras, "diagrama_simulink_lab9.png");
print("-s" + modelo, "-dpng", "-r180", rutaFigura);

fprintf("Modelo compilado: %d bloques, %d lineas.\n", ...
    numel(bloques), numel(lineas));
fprintf("Puertos sin conexion: 0. Lineas colgantes: 0.\n");
fprintf("Diagrama guardado en: %s\n", rutaFigura);

close_system(modelo, 0);
