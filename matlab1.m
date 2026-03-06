%% ============================================================
%  run_HSS_DutyCycle.m
%  Startet LTspice aus MATLAB, führt den Duty-Cycle-Sweep aus
%  und liest die Messwerte (delta_i, ia_eff, delta_u, ua_eff)
%  aus der .log-Datei ein. Danach werden Diagramme erzeugt
%  und die Daten als Excel-Tabelle gespeichert.
%  ============================================================

clc; clear; close all;

%% 1) Pfade Eingabe ------------------------------------------

%Simulation 1: In Abhängigkeit der Duty cycle----------------------
%-------------------------------------------------------------------

% Pfad zu deiner LTspice-EXE
ltspiceExe1 = '"D:\School App\LT spice\LTspice.exe"';

% Arbeitsordner, in dem auch ASC- und LOG-Datei liegen
workDir1    = 'D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 1\';

% Deine LTspice-Datei (Hochsetzsteller mit .step param d ...)
ascFile1    = '"D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 1\C4 HSS 1.asc"';

% Log-Datei, die LTspice erzeugt
logFile1    = fullfile(workDir1, 'C4 HSS 1.log');

%step param defienieren
D = 0.2:0.2:0.8;   % = [0.2 0.4 0.6 0.8]
simVar1 = 'Duty cycle in %'; % Simulation Abhängigkeitsvariable als String eingeben

%Simulation 2: In Abhängigkeit der Frequenz----------------------
%--------------------------------------------------------------------

% Pfad zu deiner LTspice-EXE
ltspiceExe2 = '"D:\School App\LT spice\LTspice.exe"';

% Arbeitsordner, in dem auch ASC- und LOG-Datei liegen
workDir2    = 'D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 2\';

% Deine LTspice-Datei (Hochsetzsteller mit .step param d ...)
ascFile2    = '"D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 1\C4 HSS 2.asc"';

% Log-Datei, die LTspice erzeugt
logFile2    = fullfile(workDir2, 'C4 HSS 2.log');

%step param defienieren
f_kHz = 2.5:2.5:7.5;   % = [2.5 5.0 7.5]
simVar2 = 'Frequenz in kHz'; % Simulation Abhängigkeitsvariable als String eingeben

%Simulation 3: In Abhängigkeit der Wiederstand----------------------
%--------------------------------------------------------------------

% Pfad zu deiner LTspice-EXE
ltspiceExe3 = '"D:\School App\LT spice\LTspice.exe"';

% Arbeitsordner, in dem auch ASC- und LOG-Datei liegen
workDir3    = 'D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 3\';

% Deine LTspice-Datei (Hochsetzsteller mit .step param d ...)
ascFile3    = '"D:\HS Bremen\WiSe 3 (2025-2026)\SEELEK\Labour\Labor 2\simulation 1\C4 HSS 3.asc"';

% Log-Datei, die LTspice erzeugt
logFile3    = fullfile(workDir3, 'C4 HSS 3.log');
 
%step param defienieren
Rwerte = [100, 200, 400];   % = [100 200 400]
simVar3 = 'Last Wiederstand in Ohm'; % Simulation Abhängigkeitsvariable als String eingeben


%% 2) LTspice im Batch-Mode starten ---------------------------
cmd = sprintf('%s -b -run %s', ltspiceExe1, ascFile1);
fprintf('Starte LTspice mit:\n  %s\n', cmd);

status = system(cmd);

if status ~= 0
    error('LTspice konnte nicht gestartet werden (Status %d). Pfade pruefen!', status);
end

fprintf('LTspice-Simulation wurde gestartet. Warte kurz...\n');
pause(2);   % kurze Pause, damit .log sicher geschrieben ist

%% 3) .log-Datei einlesen -------------------------------------

logText = readLogFile(logFile1);
logText2 = readLogFile(logFile2);
logText3 = readLogFile(logFile3);

%% 4) Messwerte aus "Measurement: ..." Bloecken holen ---------

[Delta_i, Ie_eff, Delta_u, Ua_eff, measTable] = extractMeasurementTable(logText, simVar1);
[Delta_i2, Ie_eff2, Delta_u2, Ua_eff2, measTable2] = extractMeasurementTable(logText2, simVar2);
[Delta_i3, Ie_eff3, Delta_u3, Ua_eff3, measTable3] = extractMeasurementTable(logText3, simVar3);

%% 5) Varible-Vektor passend zu .step param Überprüfung --

checkStepLength(D, Delta_i);
checkStepLength(f_kHz, Delta_i2);
checkStepLength(Rwerte, Delta_i3);

%% 6) Diagramme erzeugen --------------------------------------
DInProzent = D*100;  % um in prozent plotern zu können
plotRippleDiagrams(DInProzent, Delta_i, Ie_eff, Delta_u, Ua_eff, simVar1);
plotRippleDiagrams(f_kHz, Delta_i2, Ie_eff2, Delta_u2, Ua_eff2, simVar2);
plotRippleDiagrams(Rwerte, Delta_i3, Ie_eff3, Delta_u3, Ua_eff3, simVar3);


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

%%======================================================================
% Methode um Log-Datei Einzulesen
% readLogFile - Liest eine Log-Datei ein und gibt den Inhalt als Text zurück.
%
% Eingabe:
%   logFilePath - Pfad zur Log-Datei (als String)
%
% Ausgabe:
%   logText     - Inhalt der Log-Datei als String
%======================================================================

function logText = readLogFile(logFilePath)

    if ~exist(logFilePath, 'file')
        error('Log-Datei %s wurde nicht gefunden. Ist die Simulation durchgelaufen?', logFilePath);
    end

    fprintf('Lese Log-Datei: %s\n\n', logFilePath);
    logText = fileread(logFilePath);
end

%%======================================================================
% extractMeasurementTable - Holt Messwerte aus einem Log-Text und zeigt sie als Tabelle an.
%
% Eingaben:
%   logText     - Inhalt der .log-Datei als String
%   simVarName  - Name der Simulationsvariable zur Anzeige
%
% Ausgabe:
%   measTable   - Tabelle mit Messwerten (Delta_i, Ie_eff, Delta_u, Ua_eff)
%%====================================================================
function [Delta_i, Ie_eff, Delta_u, Ua_eff, measTable] = extractMeasurementTable(logText, simVarName)


    % Messwerte aus Log extrahieren
    Delta_i = getMeasValues(logText, 'delta_i');   % Strom-Ripple
    Ie_eff  = getMeasValues(logText, 'ie_eff');    % Effektivstrom
    Delta_u = getMeasValues(logText, 'delta_u');   % Spannungs-Ripple
    Ua_eff  = getMeasValues(logText, 'ua_eff');    % Effektivspannung

    % Messwerte als Tabelle anzeigen
    fprintf('Gefundene Werte (in Abhängigkeit vom %s) aus .log:\n', simVarName);
    measTable = table(Delta_i(:), Ie_eff(:), Delta_u(:), Ua_eff(:), ...
        'VariableNames', {'Delta_i', 'Ie_eff', 'Delta_u', 'Ua_eff'});

    disp(measTable);
end

%%======================================================================
% checkStepLength - Prüft, ob die Anzahl der Step-Werte zu den Messwerten passt.
%
% Eingaben:
%   var        - Vektor mit den in der Simulation verwendeten .step-Variable (z. B. Duty Cycle)
%   gemesseneDaten  - Vektor mit gemessenen Werten (z. B. Strom-Ripple)
%
% Gibt eine Warnung aus, wenn die Längen nicht übereinstimmen.
%%=====================================================================

function checkStepLength(var, gemesseneDaten)

    if numel(var) ~= numel(gemesseneDaten)
        warning('Anzahl der .step-Werte (%d) passt nicht zur Zahl der Messwerte (%d).', ...
            numel(var), numel(gemesseneDaten));
    end
end

%%=========================================================================
% plotRippleDiagrams - Erstellt zwei Diagramme für Strom- und Spannungsverlauf
%
% Eingaben:
%   var         - Vektor der Step-Werte (z. B. Duty Cycle)
%   Delta_i   - Stromripple-Werte (pk-pk) in Aktuelle Simulation
%   Ia_eff    - Effektivwerte des Eingangsstroms in Aktuelle Simulation
%   Delta_u   - Spannungsripple-Werte (pk-pk) in Aktuelle Simulation
%   Ua_eff    - Effektivwerte der Ausgangsspannung in Aktuelle Simulation
%   simVarName - Name der Aktuelle Simulationsvariablen als String (z. B. 'Duty cycle')

%%===========================================================================

function plotRippleDiagrams(var, Delta_i, Ie_eff, Delta_u, Ua_eff, simVarName)

    % Diagramm 1 – Ströme
    figure;
    yyaxis left;
    plot(var, Ie_eff, '-or', 'LineWidth', 1.5);
    ylabel('I_{e,eff} / A');

    yyaxis right;
    plot(var, Delta_i, '-ob', 'LineWidth', 1.5);
    ylabel('\Delta i_e (pk-pk) / A');

    xlabel(sprintf('%s', simVarName));
    title(sprintf('Eingangsstrom I_{e,eff} und Stromripple \\Delta i_e in Abhängigkeit vom %s', simVarName));
    grid on;

    % Diagramm 2 – Spannungen
    figure;
    yyaxis left;
    plot(var, Ua_eff, '-or', 'LineWidth', 1.5);
    ylabel('U_{a,eff} / V');

    yyaxis right;
    plot(var, Delta_u, '-ob', 'LineWidth', 1.5);
    ylabel('\Delta U_a (pk-pk) / V');

    xlabel(sprintf('%s', simVarName));
    title(sprintf('Ausgangsspannung U_{a,eff} und Spannungsripple \\Delta U_a in Abhängigkeit vom %s', simVarName));
    grid on;
end



