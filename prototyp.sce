// -*- Load LabJack U12 Custom DLL -*-
ilib_for_link(["cab", "cao"], "mile12.c", [], "c");
exec('loader.sce');

disp("analog outputs auf 0 setzen");
call("cao", 2.5, 1, "r", 2.5 , 2, "r", "out", [1,1], 3, "i");



//für den start der Messung
function startProcess()
    
    global sec;
    global stop;
    global abtastrate_input;
    global abtastrate;
    global dauer_input;
    global neue_dauer;
    global clear_point;
    global add_button;
    global mess_start;
    global mess_stopp;

     // Überprüfen, ob der Button schon existiert und korrekt gesetzt wurde
     // Überprüfen, ob der Button bereits existiert
     
     initializeButtons()

    // Neue Dauer auslesen
    neue_dauer = evstr(dauer_input.string);
    //falls in der Zeit der Messung jemand auf die Idee kommen sollte die Dauer der Messung zu verändern
    local_dauer_val = neue_dauer;
    local_abtastrate = abtastrate;
    disp(local_dauer_val);

    stop = 0;

    e1 = findobj("tag", "minuteVoltage1");
    e2 = findobj("tag", "minuteVoltage2");
    e3 = findobj("tag", "minuteVoltage3");
    e4 = findobj("tag", "minuteVoltage4");

    channel1 = 0;
    channel2 = 2;
    channel3 = 4;
    channel4 = 6;
    inputValue2 = 10;

    disp("local_dauer_val");
    disp(local_dauer_val);
    mess_start.enable = "off";
    mess_stopp.enable = "on";
    clear_point.enable = "off";
    abtastrate_input.enable = "off";
    add_button.enable = "off";
    dauer_input.enable = "off";
    
    while sec <= local_dauer_val
        disp("local_dauer_val");
    disp(local_dauer_val);
        
        
        if stop == 1 then
            disp("Messung gestoppt.");
            break
        end

        setOutputFunction(sec);
        disp(sec);
        
        voltage1 = call("cab", channel1, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e.data(sec, 2) = voltage1;

        voltage2 = call("cab", channel2, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e2.data(sec, 2) = voltage2;

        voltage3 = call("cab", channel3, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e3.data(sec, 2) = voltage3;

        voltage4 = call("cab", channel4, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e4.data(sec, 2) = voltage4;
        
        //berechne neuer Zeitpunkt 
        sleep(local_abtastrate * 1000);
        sec = sec + local_abtastrate;

        
    end
    disp("analog outputs auf 0 setzen");
    call("cao", 2.5, 1, "r", 2.5 , 2, "r", "out", [1,1], 3, "i");
    //zeit auf 0 setzen
    sec = 1;
    clear_point.enable = "on";
    abtastrate_input.enable = "on";
    dauer_input.enable = "on";
    add_button.enable = "on";
    mess_start.enable = "on";
    mess_stopp.enable = "off";
endfunction

function toggleGraph(tagName, visible)
    e = findobj("tag", tagName);
    if visible then
        e.visible = "on";
    else
        e.visible = "off";
    end
endfunction

function export()
    global export_format_dropdown;

    //auslesen aus dem Drop Down Menu
    options = ["png", "pdf", "svg", "emf", "eps"];
    selected_idx = export_format_dropdown.value;
    selected_format = options(selected_idx);
    
    select selected_format
        case "png"
            xs2png(gcf(),'untitled.png');
        case "pdf"
            xs2pdf(gcf(),'untitled');
        case "svg"
            xs2svg(gcf(),'untitled.svg');
        case "emf"
            xs2emf(gcf(), 'untitled.emf'); 
        case "eps"
            xs2eps(gcf(), 'untitled.eps');
        else
            disp("Unknown format selected");
    end
    
endfunction
// --- Fenster & Grundstruktur ---
f = figure("position", [100 100 1000 830]);
f.menubar_visible = "on";
f.toolbar_visible = "on";
f.resize = "off";


// --- GUI-Komponenten global machen ---
global dauer_input abtastrate_input dauer_val abtastrate;
global t_input a1_input a2_input;
global t_box a1_box a2_box;

// --- Beschriftungen & Eingaben oben ---
uicontrol(f, "style", "text", "string", " Messparameter", "position", [20 780 150 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", " Messdauer:", "position", [20 760 100 20], "backgroundcolor", [1 1 1], "horizontalalignment", "left");
dauer_input = uicontrol(f, "style", "edit", "string", "15", "position", [80 760 50 20], "callback", "updateInputFunction()");
dauer_val = evstr(dauer_input.string); // Wandelt z. B. "80" → 80 (Double)
uicontrol(f, "style", "text", "string", " s", "position", [130 760 20 20], "backgroundcolor", [1 1 1]);
neue_dauer = evstr(dauer_input.string); // Wandelt z. B. "80" → 80 (Double)
disp("neue dauer:");
disp(neue_dauer);

uicontrol(f, "style", "text", "string", " Abtastrate:", "position", [20 740 100 20], "backgroundcolor", [1 1 1], "horizontalalignment", "left");
abtastrate_input = uicontrol(f, "style", "edit", "string", "10", "position", [80 740 50 20]);
abtastrate = 1 / evstr(abtastrate_input.string); // umformen der Abtastrate in 1/s
uicontrol(f, "style", "text", "string", " 1/s", "position", [130 740 20 20], "backgroundcolor", [1 1 1]);

// --- Globale Daten-Arrays ---
global t_list a1_list a2_list;
global neue_dauer;
global ax bax;
global rem_point rep_point;
t_list = [];
a1_list = [];
a2_list = [];

// --- Tabellen (Listboxen) ---
t_box  = uicontrol(f, "style", "listbox", "position", [400 620 40 150], "string", "", "callback", "on_listbox_select()");
a1_box = uicontrol(f, "style", "listbox", "position", [450 620 40 150], "string", "", "callback", "on_listbox_select()");
a2_box = uicontrol(f, "style", "listbox", "position", [500 620 40 150], "string", "", "callback", "on_listbox_select()");

//eingabe feld beschriftung
uicontrol(f, "style", "text", "string", "Zeitpunkt: ", "position", [160 750 60 30], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "right");
uicontrol(f, "style", "text", "string", "A1: ", "position", [160 710 60 30], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "right");
uicontrol(f, "style", "text", "string", "A2: ", "position", [160 670 60 30], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "right");

// --- Eingabefelder für neue Werte ---
t_input  = uicontrol(f, "style", "edit", "position", [220 750 50 30], "string", "0");
a1_input = uicontrol(f, "style", "edit", "position", [220 710 50 30], "string", "0");
a2_input = uicontrol(f, "style", "edit", "position", [220 670 50 30], "string", "0");

// Tabelle - Eingaben auflistung
uicontrol(f, "style", "text", "string", "t", "position", [400 770 40 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "center");
uicontrol(f, "style", "text", "string", "A1", "position", [450 770 40 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "center");
uicontrol(f, "style", "text", "string", "A2", "position", [500 770 40 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "center");

// --- Hinzufügen-Button ---
add_button = uicontrol(f, "style", "pushbutton", "string", "Hinzufügen", "position", [280 750 100 30], "callback", "add_checkpoint()", "enable", "on");
rem_point = uicontrol(f, "style", "pushbutton", "string", "Entfernen", "position", [280 710 100 30], "callback", "remove_checkpoint()", "enable", "off");
rep_point = uicontrol(f, "style", "pushbutton", "string", "Ersetzen", "position", [280 670 100 30], "callback", "replace_checkpoint()", "enable", "off");
clear_point = uicontrol(f, "style", "pushbutton", "string", "Clear", "position", [280 630 100 30], "callback", "clear_checkpoint()", "enable", "on");

// --- Messung Starten
mess_start = uicontrol(f, "style", "pushbutton", "string", "Messung starten", "position", [20 640 130 30], "callback", "startProcess()", "enable", "on");

// --- Messung Stoppen
mess_stopp = uicontrol(f, "style", "pushbutton", "string", "Messung stoppen", "position", [20 600 130 30], "callback", "setStop()", "callback_type", 12, "enable", "off");




//checkboxes für das auswählen der plots
cb1 = uicontrol("style", "checkbox", "parent", f, "string", "Input 1", "value", 1, "position", [820 500 140 20], "callback", strcat(["toggleGraph(""minuteVoltage1"", gcbo.value)"]));
cb2 = uicontrol("style", "checkbox", "parent", f, "string", "Input 2", "value", 1, "position", [820 460 140 20], "callback", strcat(["toggleGraph(""minuteVoltage2"", gcbo.value)"]));
cb3 = uicontrol("style", "checkbox", "parent", f, "string", "Input 3", "value", 1, "position", [820 420 140 20], "callback", strcat(["toggleGraph(""minuteVoltage3"", gcbo.value)"]));
cb4 = uicontrol("style", "checkbox", "parent", f, "string", "Input 4", "value", 1, "position", [820 380 140 20], "callback", strcat(["toggleGraph(""minuteVoltage4"", gcbo.value)"]));

//drop down for the export button
global export_format_dropdown;
export_format_dropdown = uicontrol(f, "style", "popupmenu", ...
    "string", ["png"; "pdf"; "svg"; "emf"; "eps"], ...
    "position", [750 30 100 20]);

//export button
uicontrol(f, "style", "pushbutton", "string", "Export", "position", [860 30 100 20], "callback", "export()");    
timeBuffer = evstr(dauer_input.string);    
ax = newaxes();
ax.axes_bounds = [-0.075, 0.25, 1, 0.75]; // Fill frame2 (which is lower 600px of 800px)
minVoltageDisplay = 0;
maxVoltageDisplay = 10;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e1 = gce().children(1);
e1.tag = "minuteVoltage1";
e1.foreground = color("black");
e1.visible = "on";
e1.thickness = 2;

plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e2 = gce().children(1);
e2.tag = "minuteVoltage2";
e2.foreground = color("green");
e2.visible = "on";
e2.thickness = 2;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e3 = gce().children(1);
e3.tag = "minuteVoltage3";
e3.foreground = color("blue");
e3.visible = "on";
e3.thickness = 2;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e4 = gce().children(1);
e4.tag = "minuteVoltage4";
e4.foreground = color("red");
e4.visible = "on";
e4.thickness = 2;


gca().title.text = "Spannungsverlauf";
gca().data_bounds = [0, minVoltageDisplay; timeBuffer, maxVoltageDisplay];

xlabel("Zeit (s)");
ylabel("Spannung (V)");

// Sekunden-Counter
global sec;
sec = 1;

global stop;
stop = 1; //0 = false , 1 = true

// Zweites Diagramm, für Eingabe Funtkion 
bax = newaxes();
bax.axes_bounds = [0.55, 0.00, 0.45, 0.3]; 

plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e5 = gce().children(1);
e5.tag = "A1";
e5.foreground = color("red");
e5.visible = "on";
e5.thickness = 2;

plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e6 = gce().children(1);
e6.tag = "A2";
e6.foreground = color("black");
e6.visible = "on";
e6.thickness = 2;

gca().title.text = "Eingabe Funktion";
gca().data_bounds = [0, minVoltageDisplay; timeBuffer, maxVoltageDisplay];

// --- Funktion zum Hinzufügen eines Checkpoints ---
// --- Funktion zum Hinzufügen eines Checkpoints ---
function add_checkpoint()
    // Zugriff auf globale Variablen & GUI-Objekte
    global t_list a1_list a2_list;
    global t_input a1_input a2_input;
    global t_box a1_box a2_box;
    global neue_dauer;
    global abtastrate;

    // Eingaben auslesen und in Zahlen umwandeln
    
    t_val  = evstr(t_input.string);
    if t_val < 0 then
        t_val = 0;
    end
    a1_val = evstr(a1_input.string);
    if a1_val < 0 then
        a1_val = 0;
    end
    a2_val = evstr(a2_input.string);
    if a2_val < 0 then
        a2_val = 0;
    end

     // Prüfen, ob t_val bereits in t_list enthalten ist
     idx = find(t_list == t_val);
     
        // Werte zur Liste hinzufügen, wenn die angebene neue_dauer> Messdauer, dann nimmt er einfach die Messdauer.
    if modulo(t_val, abtastrate) == 0 then
        if ~isempty(idx) then
            replace_checkpoint_at(idx(1), t_val, a1_val, a2_val); // Zeitwert existiert – alten Punkt ersetzen
        else
            if t_val < neue_dauer then
                t_list($+1)  = t_val;
            else
                t_list($+1)  = neue_dauer; 
            end    

            if a1_val < 10 then   
                a1_list($+1) = a1_val;
            else
                a1_list($+1) = 10;
            end

            if a2_val < 10 then   
                a2_list($+1) = a2_val;
            else
                a2_list($+1) = 10;
            end
        end
    end

    // Liste nach t_list sortieren
    [t_list, indices] = gsort(t_list, "g", "i");
    a1_list = a1_list(indices);
    a2_list = a2_list(indices);

    // Listboxen aktualisieren
    t_box.string  = string(t_list);
    a1_box.string = string(a1_list);
    a2_box.string = string(a2_list);
    update_input_plot();
    updateEingabe();  
    
endfunction

function remove_checkpoint()
    global t_list a1_list a2_list;
    global t_box a1_box a2_box;

    // Index aus allen drei Listboxen holen
    idx_t  = t_box.value;
    idx_a1 = a1_box.value;
    idx_a2 = a2_box.value;

    // Kombinieren und den gültigen nehmen
    idx_list = [idx_t, idx_a1, idx_a2];
    idx_list = idx_list(idx_list > 0); // Nur gültige

    if ~isempty(idx_list) then
        idx = idx_list(1); // Nimm den ersten gültigen (alle sollten synchron sein)

        // Entferne Eintrag
        t_list(idx)  = [];
        a1_list(idx) = [];
        a2_list(idx) = [];

        // GUI aktualisieren
        t_box.string  = string(t_list);
        a1_box.string = string(a1_list);
        a2_box.string = string(a2_list);

        // Auswahl zurücksetzen
        t_box.value = 0;
        a1_box.value = 0;
        a2_box.value = 0;
        
        update_input_plot();
        on_listbox_select()
    end
endfunction

function replace_checkpoint()
    global t_list a1_list a2_list;
    global t_input a1_input a2_input;
    global t_box a1_box a2_box;

    // Index holen (egal aus welcher Box)
    idx_list = [t_box.value, a1_box.value, a2_box.value];
    idx_list = idx_list(idx_list > 0);
    
    if ~isempty(idx_list) then
        idx = idx_list(1);

        // Neue Werte holen
        t_val  = evstr(t_input.string);
        a1_val = evstr(a1_input.string);
        a2_val = evstr(a2_input.string);

        // Werte ersetzen
        t_list(idx)  = t_val;
        a1_list(idx) = a1_val;
        a2_list(idx) = a2_val;

        // GUI aktualisieren
        t_box.string  = string(t_list);
        a1_box.string = string(a1_list);
        a2_box.string = string(a2_list);
        update_input_plot();
        on_listbox_select()
    end
endfunction

function replace_checkpoint_at(index, t_val, a1_val, a2_val)
    global t_list a1_list a2_list;
    global t_box a1_box a2_box;

    // Werte korrigieren und begrenzen
    if modulo(t_val, abtastrate) == 0 then
        if t_val > neue_dauer then
            t_val = neue_dauer;
        end

        a1_val = min(a1_val, 10);
        a2_val = min(a2_val, 10);

        // Ersetzen
        t_list(index)  = t_val;
        a1_list(index) = a1_val;
        a2_list(index) = a2_val;

        // GUI aktualisieren
        t_box.string  = string(t_list);
        a1_box.string = string(a1_list);
        a2_box.string = string(a2_list);
        update_input_plot();
        on_listbox_select();
    end
endfunction

function clear_checkpoint()
    global t_list a1_list a2_list;
    global t_box a1_box a2_box;

    // Datenlisten leeren
    t_list = [];
    a1_list = [];
    a2_list = [];

    // GUI-Listboxen leeren
    set(t_box, "string", "");
    set(a1_box, "string", "");
    set(a2_box, "string", "");

    update_input_plot();
endfunction

function on_listbox_select()
    global t_box a1_box a2_box;
    global rem_point rep_point;

    idx = max([t_box.value, a1_box.value, a2_box.value]);
    if idx > 0 then
        rem_point.enable = "on";
        rep_point.enable = "on";
    else
        rem_point.enable = "off";
        rep_point.enable = "off";
    end
endfunction


function updateInputFunction()
    global dauer_input;
    global neue_dauer;

    // Neue Dauer auslesen
    neue_dauer = evstr(dauer_input.string);
    disp(neue_dauer);
    
    // Zweite Achse aktivieren
    f = gcf();
    a = findobj("tag", "EingabeAchse");
    scf(f); // zur aktuellen Figur
    
    update_input_plot();
    updateEingabe();
    updateSpannung();
    
endfunction

function updateSpannung()
    global ax;
    sca(ax);
    plot(0:neue_dauer, zeros(1, neue_dauer + 1));
    e1 = gce().children(1);
    e1.tag = "minuteVoltage1";
    e1.foreground = color("black");
    e1.visible = "on";
    e1.thickness = 2;

    plot(0:neue_dauer, zeros(1, neue_dauer + 1));
    e2 = gce().children(1);
    e2.tag = "minuteVoltage2";
    e2.foreground = color("green");
    e2.visible = "on";
    e2.thickness = 2;

    plot(0:neue_dauer, zeros(1, neue_dauer + 1));
    e3 = gce().children(1);
    e3.tag = "minuteVoltage3";
    e3.foreground = color("blue");
    e3.visible = "on";
    e3.thickness = 2;

    plot(0:neue_dauer, zeros(1, neue_dauer + 1));
    e4 = gce().children(1);
    e4.tag = "minuteVoltage4";
    e4.foreground = color("red");
    e4.visible = "on";
    e4.thickness = 2;

    gca().data_bounds = [0, 0; neue_dauer, 10];

endfunction

function updateEingabe()
    global bax;
    sca(bax);
    plot(0:neue_dauer, zeros(1, neue_dauer + 1));

    e5 = gce().children(1);
    e5.tag = "A1";
    e5.foreground = color("red");
    e5.visible = "on";
    e5.thickness = 2;
    disp("Eingabe Updatet");
    plot(0:neue_dauer, zeros(1, neue_dauer + 1));
    e6 = gce().children(1);
    e6.tag = "A2";
    e6.foreground = color("black");
    e6.visible = "on";
    e6.thickness = 2;

    gca().data_bounds = [0, 0; neue_dauer, 10];
endfunction

function update_input_plot() 
    global t_list a1_list a2_list;
    global dauer_input;
    global neue_dauer;
    global t_box a1_box a2_box;

    updateEingabe();
    dauer = evstr(dauer_input.string); //alt, kann eigentlich gelöscht werden.
    dauer = neue_dauer;
    disp(dauer);

    // Durch alle Punkte iterieren und prüfen, ob t > dauer
    for i = 1:length(t_list)
        if t_list(i) > dauer then
            // Punkt löschen, wenn t > dauer
            t_list(i) = [];
            a1_list(i) = [];
            a2_list(i) = [];
        end
    end

    // Listboxen aktualisieren
    t_box.string  = string(t_list);
    a1_box.string = string(a1_list);
    a2_box.string = string(a2_list);
    
    // Initiale Zeitachse
    t = 0:1:dauer;
    
    // Sicherstellen, dass Checkpoints vorhanden sind
    if isempty(t_list) then
        y1 = zeros(t);
        y2 = zeros(t);
    else
        // Liste sortieren (falls nicht sortiert eingegeben)
        [t_sorted, indices] = gsort(t_list, "g", "i");
        a1_sorted = a1_list(indices);
        a2_sorted = a2_list(indices);

        // Schrittweise Werte erzeugen
        y1 = zeros(t);
        y2 = zeros(t);

        for i = 1:length(t_sorted)
            start_idx = find(t >= t_sorted(i));
            if i == length(t_sorted)
                y1(start_idx) = a1_sorted(i);
                y2(start_idx) = a2_sorted(i);
            else
                next_t = t_sorted(i + 1);
                idx_range = find(t >= t_sorted(i) & t < next_t);
                y1(idx_range) = a1_sorted(i);
                y2(idx_range) = a2_sorted(i);
            end
        end
    end

    // Plot aktualisieren
    f = gcf();
    scf(f);
    
    // A1 updaten
    a1_plot = findobj("tag", "A1");
    a1_plot.data = [t' y1'];

    // A2 updaten
    a2_plot = findobj("tag", "A2");
    a2_plot.data = [t' y2'];
    
endfunction

function setStop() 
    global mess_stopp;
    global stop;
    stop = 1;
    disp("Messung gestoppt.");
    //ausgänge auf 0 setzen
    call("cao", 2.5, 1, "r", 2.5 , 2, "r", "out", [1,1], 3, "i");
    disp("Messung gestoppt 2");
    clear_point.enable = "on";
    abtastrate_input.enable = "on";
    dauer_input.enable = "on";
    add_button.enable = "on";
    mess_start.enable = "on";
    mess_stopp.enable = "off";
    
    
endfunction

function setOutputFunction(sec)
    global t_list a1_list a2_list;

    // Standardwerte
    output_A1 = 0;
    output_A2 = 0;

    // Falls keine Checkpoints vorhanden sind
    if size(t_list, "*") == 0 then
        return;
    end

    // Sortieren zur Sicherheit (falls neu hinzugefügt wurde)
    [t_sorted, sort_idx] = gsort(t_list, "g", "i");
    a1_sorted = a1_list(sort_idx);
    a2_sorted = a2_list(sort_idx);

    // Finde den letzten gültigen Index für die aktuelle Zeit
    idx = find(t_sorted <= sec);
    if ~isempty(idx) then
        last_idx = idx($);
        output_A1 = a1_sorted(last_idx);
        output_A2 = a2_sorted(last_idx);
    end

    // Ausgabe zur Kontrolle
    mprintf("t = %.2f s | AO1 = %.2f V | AO2 = %.2f V\n", sec, output_A1, output_A2);
    
    disp(output_A2);
    
    err= call("cao", (output_A1+10)/4, 1, "r", (output_A2+10)/4, 2, "r", "out", [1,1], 3, "i");
    if err <> 0 then
        disp("Fehler beim Setzen von AO1: Fehlercode " + string(err));
    end
    
endfunction

function initializeButtons()
    // Überprüfen und Erstellen der Buttons
    global mess_start add_button rem_point rep_point clear_point mess_stopp;

    // Initialize "Messung starten" Button
    mess_start = findobj("tag", "mess_start");
    if isempty(mess_start) then
        mess_start = uicontrol(f, "style", "pushbutton", "string", "Messung starten", "position", [20 640 130 30], "callback", "startProcess()", "enable", "on", "tag", "mess_start");
    else
        mess_start.string = "Messung starten";  // Setze den Text des Buttons zurück
        mess_start.enable = "on";  // Stelle sicher, dass der Button aktiv ist
    end

    // Initialize "Messung stoppen" Button
    mess_stopp = findobj("tag", "mess_stopp");
    if isempty(mess_stopp) then
        mess_stopp = uicontrol(f, "style", "pushbutton", "string", "Messung stoppen", "position", [20 600 130 30], "callback", "setStop()", "callback_type", 12, "enable", "off", "tag", "mess_stopp");
    else
        mess_stopp.string = "Messung stoppen";  // Setze den Text des Buttons zurück
        mess_stopp.enable = "off";  // Stelle sicher, dass der Button deaktiviert ist
    end

    // Initialize "Hinzufügen" Button
    add_button = findobj("tag", "add_button");
    if isempty(add_button) then
        add_button = uicontrol(f, "style", "pushbutton", "string", "Hinzufügen", "position", [280 750 100 30], "callback", "add_checkpoint()", "enable", "on", "tag", "add_button");
    else
        add_button.string = "Hinzufügen";  // Setze den Text des Buttons zurück
        add_button.enable = "on";  // Stelle sicher, dass der Button aktiv ist
    end

    // Initialize "Entfernen" Button
    rem_point = findobj("tag", "rem_point");
    if isempty(rem_point) then
        rem_point = uicontrol(f, "style", "pushbutton", "string", "Entfernen", "position", [280 710 100 30], "callback", "remove_checkpoint()", "enable", "off", "tag", "rem_point");
    else
        rem_point.string = "Entfernen";  // Setze den Text des Buttons zurück
        rem_point.enable = "off";  // Stelle sicher, dass der Button deaktiviert ist
    end

    // Initialize "Ersetzen" Button
    rep_point = findobj("tag", "rep_point");
    if isempty(rep_point) then
        rep_point = uicontrol(f, "style", "pushbutton", "string", "Ersetzen", "position", [280 670 100 30], "callback", "replace_checkpoint()", "enable", "off", "tag", "rep_point");
    else
        rep_point.string = "Ersetzen";  // Setze den Text des Buttons zurück
        rep_point.enable = "off";  // Stelle sicher, dass der Button deaktiviert ist
    end

    // Initialize "Clear" Button
    clear_point = findobj("tag", "clear_point");
    if isempty(clear_point) then
        clear_point = uicontrol(f, "style", "pushbutton", "string", "Clear", "position", [280 630 100 30], "callback", "clear_checkpoint()", "enable", "on", "tag", "clear_point");
    else
        clear_point.string = "Clear";  // Setze den Text des Buttons zurück
        clear_point.enable = "on";  // Stelle sicher, dass der Button aktiv ist
    end
endfunction


