%% ============================================================
%  run_HSS_DutyCycle.m
%  Startet LTspice aus MATLAB, führt den Duty-Cycle-Sweep aus
%  und liest die Messwerte (delta_i, ia_eff, delta_u, ua_eff)
%  aus der .log-Datei ein. Danach werden Diagramme erzeugt
%  und die Daten als Excel-Tabelle gespeichert.
%  ============================================================

clc; clear; close all;

%% 1) Pfade anpassen ------------------------------------------
% Pfad zu deiner LTspice-EXE
ltspiceExe = '"D:\School App\LT spice\LTspice.exe"';

% Arbeitsordner, in dem auch ASC- und LOG-Datei liegen
workDir    = 'D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 1\';

% Deine LTspice-Datei (Hochsetzsteller mit .step param d ...)
ascFile    = '"D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 1\C4 HSS 1.asc"';

% Log-Datei, die LTspice erzeugt
logFile    = fullfile(workDir, 'C4 HSS 1.log');

cd(workDir);   % Ins Arbeitsverzeichnis wechseln

%% 2) LTspice im Batch-Mode starten ---------------------------
cmd = sprintf('%s -b -run %s', ltspiceExe, ascFile);
fprintf('Starte LTspice mit:\n  %s\n', cmd);

status = system(cmd);

if status ~= 0
    error('LTspice konnte nicht gestartet werden (Status %d). Pfade pruefen!', status);
end

fprintf('LTspice-Simulation wurde gestartet. Warte kurz...\n');
pause(2);   % kurze Pause, damit .log sicher geschrieben ist

%% 3) .log-Datei einlesen -------------------------------------
if ~exist(logFile, 'file')
    error('Log-Datei %s wurde nicht gefunden. Ist die Simulation durchgelaufen?', logFile);
end

fprintf('Lese Log-Datei: %s\n\n', logFile);
logText = fileread(logFile);

%% 4) Messwerte aus "Measurement: ..." Bloecken holen ---------

Delta_i = getMeasValues(logText, 'delta_i');   % Strom-Ripple
Ia_eff  = getMeasValues(logText, 'ia_eff');    % I_e,eff
Delta_u = getMeasValues(logText, 'delta_u');   % Spannungs-Ripple
Ua_eff  = getMeasValues(logText, 'ua_eff');    % U_a,eff

fprintf('Gefundene Werte aus .log:\n');
disp(table(Delta_i(:), Ia_eff(:), Delta_u(:), Ua_eff(:), ...
    'VariableNames', {'Delta_i', 'Ia_eff', 'Delta_u', 'Ua_eff'}));

%% 5) Duty-Cycle-Vektor passend zu .step param d 0.2 0.8 0.2 --

D = 0.2:0.2:0.8;   % = [0.2 0.4 0.6 0.8]

if numel(D) ~= numel(Delta_i)
    warning('Anzahl der .step-Werte (%d) passt nicht zur Zahl der Messwerte (%d).', ...
        numel(D), numel(Delta_i));
end

%% 6) Diagramme erzeugen --------------------------------------

figure;
plot(D*100, Ua_eff, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Duty Cycle D / %');
ylabel('U_{a,eff} / V');
title('Ausgangsspannung U_{a,eff} in Abhaengigkeit vom Duty Cycle');

figure;
plot(D*100, Ia_eff, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Duty Cycle D / %');
ylabel('I_{e,eff} / A');
title('Eingangsstrom I_{e,eff} in Abhaengigkeit vom Duty Cycle');

figure;
plot(D*100, Delta_i, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Duty Cycle D / %');
ylabel('\Delta i_e (pk-pk) / A');
title('Stromripple \Delta i_e in Abhaengigkeit vom Duty Cycle');

figure;
plot(D*100, Delta_u, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Duty Cycle D / %');
ylabel('\Delta U_a (pk-pk) / V');
title('Spannungsripple \Delta U_a in Abhaengigkeit vom Duty Cycle');

%% 7) Ergebnisse in Excel speichern ---------------------------

outTable = table( ...
    D(:)*100, Delta_i(:), Ia_eff(:), Delta_u(:), Ua_eff(:), ...
    'VariableNames', {'D_percent', 'Delta_i_A', 'Ie_eff_A', 'Delta_Ua_V', 'Ua_eff_V'});

excelFile = fullfile(workDir, 'HSS_DutyCycle_Results.xlsx');
writetable(outTable, excelFile, 'Sheet', 'LTspice');

fprintf('\nErgebnisse wurden nach %s geschrieben.\n', excelFile);
fprintf('FERTIG.\n');

%% ============================================================
%  Hilfsfunktion: Messwerte aus einem "Measurement:"-Block
%  im LTspice-Log extrahieren.
%  Sucht nach:
%     Measurement: <name>
%     step 1   <WERT>
%     step 2   <WERT>
%     ...
%  und gibt die WERTe als double-Vektor zurueck.
%  ============================================================

function values = getMeasValues(logText, measName)

    % Position des "Measurement: <name>"-Blocks finden
    pattern = ['Measurement:\s*' measName];
    startIdx = regexp(logText, pattern, 'start', 'ignorecase');

    if isempty(startIdx)
        warning('Messung "%s" nicht im Log gefunden.', measName);
        values = [];
        return;
    end

    % Startposition
    startPos = startIdx(0+1); %#ok<NASGU> % erste Fundstelle

    % Naechste "Measurement:"-Position finden (oder Ende des Textes)
    nextIdx = regexp(logText(startPos+1:end), 'Measurement:', 'start', 'ignorecase');
    if isempty(nextIdx)
        block = logText(startPos:end);
    else
        block = logText(startPos : startPos + nextIdx(1) - 2);
    end

    % Alle Zahlen hinter "step ..." Zeilen holen
    tok = regexp(block, '\n\s*\d+\s+([0-9\.\+\-Ee]+)', 'tokens');
    values = str2double([tok{:}]);
end
