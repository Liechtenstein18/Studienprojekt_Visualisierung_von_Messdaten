//Version richtige UI

// -*- Load LabJack U12 Custom DLL -*-
ilib_for_link(["cab", "cao"], "mile12.c", [], "c");
exec('loader.sce');


call("cao", 2.5, 1, "r", 2.5 , 2, "r", "out", [1,1], 3, "i");


// ==========================   STARTPROCESS   ==========================
function startProcess()

    //------------------------------------------------------------------
    //-- 1  globale Variablen holen
    //------------------------------------------------------------------
    global sec stop;
    global dauer_input neue_dauer;
    global abtastrate_input;
    global mess_start mess_stopp clear_point add_button export_button;
    global input_function_dropdown;
    global dt;
    global display_extra;         //  << NEU

    //------------------------------------------------------------------
    //-- 2  Buttons / GUI in Ausgangszustand
    //------------------------------------------------------------------
    initializeButtons()

    // Plot-Handles besorgen und leeren
    e1 = findobj("tag","minuteVoltage1");
    e2 = findobj("tag","minuteVoltage2");
    e3 = findobj("tag","minuteVoltage3");
    e4 = findobj("tag","minuteVoltage4");
    for h = [e1 e2 e3 e4]
        if ~isempty(h) then h.data = []; end
    end
    sec = 0;

    //------------------------------------------------------------------
    //-- 3  Messparameter aus GUI lesen
    //------------------------------------------------------------------
    neue_dauer     = evstr(dauer_input.string);
    samplesPerSec  = evstr(abtastrate_input.string);
    dt             = 1 / samplesPerSec;
    anzeigen_dauer = neue_dauer + display_extra;   // << hier geändert

    //------------------------------------------------------------------
    //-- 4  Kanal-Konstanten & GUI sperren
    //------------------------------------------------------------------
    channel1 = 0; channel2 = 2; channel3 = 4; channel4 = 6;
    inputValue2 = 12;
    stop = 0;

    mess_start.enable           = "off";
    mess_stopp.enable           = "on";
    clear_point.enable          = "off";
    add_button.enable           = "off";
    abtastrate_input.enable     = "off";
    dauer_input.enable          = "off";
    input_function_dropdown.enable = "off";
    export_button.enable = "off";

    //------------------------------------------------------------------
    //-- 4b  Zeitbasis vorbereiten
    //------------------------------------------------------------------
    t0     = getdate("s");
    n      = 0;
    ao_off = %f;

    //------------------------------------------------------------------
    //-- 5  Haupt-Schleife
    //------------------------------------------------------------------
    while (getdate("s") - t0) <= anzeigen_dauer

        if stop then ; break; end

        now = getdate("s");
        sec = now - t0;

        // 5a  Ausgänge
        if sec < neue_dauer then
            setOutputFunction(sec);
        elseif ~ao_off then
            call("cao", 2.5,1,"r", 2.5,2,"r", "out", [1,1], 3,"i");
            ao_off = %t;
        end

        // 5b  vier Eingänge lesen
        v1 = call("cab",channel1,1,"i",inputValue2,2,"i","out",[1,1],3,"r");
        v2 = call("cab",channel2,1,"i",inputValue2,2,"i","out",[1,1],3,"r");
        v3 = call("cab",channel3,1,"i",inputValue2,2,"i","out",[1,1],3,"r");
        v4 = call("cab",channel4,1,"i",inputValue2,2,"i","out",[1,1],3,"r");

        // 5c  an die Kurven anhängen
        e1.data = [e1.data ; sec , v1];
        e2.data = [e2.data ; sec , v2];
        e3.data = [e3.data ; sec , v3];
        e4.data = [e4.data ; sec , v4];

        // 5d  Abtast-Takt einhalten
        n      = n + 1;
        next_t = t0 + n*dt;
        delay  = next_t - getdate("s");
        if delay > 0 then sleep(delay*1000); end
    end

    //------------------------------------------------------------------
    //-- 6  Aufräumen
    //------------------------------------------------------------------
    call("cao",2.5,1,"r",2.5,2,"r","out",[1,1],3,"i");

    sec = 1;
    mess_start.enable           = "on";
    mess_stopp.enable           = "off";
    clear_point.enable          = "on";
    add_button.enable           = "on";
    abtastrate_input.enable     = "on";
    dauer_input.enable          = "on";
    input_function_dropdown.enable = "on";
    export_button.enable = "on";
endfunction
// ========================  END STARTPROCESS  ==========================


function toggleGraph(tagName, visible)
    e = findobj("tag", tagName);
    if visible then
        e.visible = "on";
    else
        e.visible = "off";
    end
endfunction


function export()
    // --- Handles der Kurven aus der Haupt-GUI ------------------------
    global e1 e2 e3 e4;

    // 1 neues Fenster + Achse
    expFig = figure("backgroundcolor", [1 1 1], "position", [200 100 1000 700]);   //  <-- größer!
    expFig.menubar_visible = "on";
    expFig.toolbar_visible = "on";
    expFig.name            = "Exportierter Spannungsverlauf";

    ax = newaxes();  sca(ax);      // Achse aktivieren

    // 2 Kurven neu zeichnen + Farbe/Dicke setzen
    //    Reihenfolge & Farben genau wie im Haupt-GUI

    if cb1.value == 1 then
    plot(e1.data(:,1), e1.data(:,2));
    h = gce().children(1);   h.foreground = color("black"); h.thickness = 2;
    end

    if cb2.value == 1 then
    plot(e2.data(:,1), e2.data(:,2));
    h = gce().children(1);   h.foreground = color("green"); h.thickness = 2;
    end 

    if cb3.value == 1 then
    plot(e3.data(:,1), e3.data(:,2));
    h = gce().children(1);   h.foreground = color("blue");  h.thickness = 2;
    end

    if cb4.value == 1 then
    plot(e4.data(:,1), e4.data(:,2));
    h = gce().children(1);   h.foreground = color("red");   h.thickness = 2;
    end 
    
    // 3 Achsenbegrenzungen so wählen, dass alle Punkte sichtbar sind
    x_all = [e1.data(:,1); e2.data(:,1); e3.data(:,1); e4.data(:,1)];
    y_all = [e1.data(:,2); e2.data(:,2); e3.data(:,2); e4.data(:,2)];
    ax.data_bounds = [min(x_all) , min(y_all) ;
                      max(x_all) , max(y_all)];

    // 4 Beschriftungen, Titel, Legende
    // 3  Achsenbegrenzungen:   x = min…max   |   y immer 0…12        ⚑
    x_all = [e1.data(:,1) ; e2.data(:,1) ; e3.data(:,1) ; e4.data(:,1)];
    if isempty(x_all) then                // falls keine Daten gezeichnet
        x_all = [0 ; 1];                  // Dummy-Bereich verhindern Fehler
    end

    x_min = min(x_all);
    x_max = max(x_all);
    if x_min == x_max then                // Messdauer evtl. nur ein Punkt
        x_max = x_max + 1;                // kleine Breite erzwingen
    end

ax.data_bounds = [x_min , 0 ;         // y-Minimum fest
                  x_max , 12];        // y-Maximum fest  ⚑

endfunction



// --- Fenster & Grundstruktur ---
f = figure("position", [100 100 1000 830], "backgroundcolor", [0.9 0.9 0.9]);
f.menubar_visible = "on";
f.toolbar_visible = "on";
f.resize = "off";


// --- GUI-Komponenten global machen ---
global dauer_input abtastrate_input dauer_val abtastrate;
global t_input a1_input a2_input;
global t_box a1_box a2_box;
global display_extra;
display_extra = 0;

// --- Beschriftungen & Eingaben oben ---

// Frame um die Messparameter und Kanäle
uicontrol(f, "style", "frame", "position", [10 815 151 1], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [10 610 1 205], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [10 610 150 1], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [160 610 1 205], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");

uicontrol(f, "style", "text", "string", "Messparameter", "position", [20 806 83 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "center", "fontsize", 12);
uicontrol(f, "style", "text", "string", "Messdauer:", "position", [15 775 100 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left", "fontsize", 12);
dauer_input = uicontrol(f, "style", "edit", "string", "15", "position", [82 775 45 20], "callback", "updateInputFunction()");
dauer_val = evstr(dauer_input.string); // Wandelt z. B. "80" → 80 (Double)
uicontrol(f, "style", "text", "string", " s", "position", [127 775 20 20], "backgroundcolor", [0.9 0.9 0.9], "fontsize", 12);
neue_dauer = evstr(dauer_input.string); // Wandelt z. B. "80" → 80 (Double)
uicontrol(f, "style", "text", "string", "Abtastrate:", "position", [15 745 100 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left", "fontsize", 12);
abtastrate_input = uicontrol(f, "style", "edit", "string", "10", "position", [82 745 45 20]);


//abtastrate = 1 / evstr(abtastrate_input.string); // umformen der Abtastrate in 1/s


uicontrol(f, "style", "text", "string", " 1/s", "position", [127 745 25 20], "backgroundcolor", [0.9 0.9 0.9], "fontsize", 12);
//checkboxes für das auswählen der plots
uicontrol(f, "style", "frame", "position", [12 725 148 1], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "text", "string", "Kanäle", "position", [20 717 35 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left", "fontsize", 12);
cb1 = uicontrol("style", "checkbox", "parent", f, "string", "Kanal 1", "value", 1, "position", [20 693 65 25],"backgroundcolor", [0.9 0.9 0.9], "callback", strcat(["toggleGraph(""minuteVoltage1"", gcbo.value)"]), "fontsize", 12);
cb2 = uicontrol("style", "checkbox", "parent", f, "string", "Kanal 2", "value", 1, "position", [20 668 65 25],"backgroundcolor", [0.9 0.9 0.9], "callback", strcat(["toggleGraph(""minuteVoltage2"", gcbo.value)"]), "fontsize", 12);
cb3 = uicontrol("style", "checkbox", "parent", f, "string", "Kanal 3", "value", 1, "position", [20 643 65 25],"backgroundcolor", [0.9 0.9 0.9], "callback", strcat(["toggleGraph(""minuteVoltage3"", gcbo.value)"]), "fontsize", 12);
cb4 = uicontrol("style", "checkbox", "parent", f, "string", "Kanal 4", "value", 1, "position", [20 618 65 25],"backgroundcolor", [0.9 0.9 0.9], "callback", strcat(["toggleGraph(""minuteVoltage4"", gcbo.value)"]), "fontsize", 12);
global cb1 cb2 cb3 cb4;

// --- Globale Daten-Arrays ---
global t_list a1_list a2_list;
global neue_dauer;
global ax bax;
global rem_point rep_point;
global initializeButtons;
t_list = [];
a1_list = [];
a2_list = [];

//uicontrol(f, "style", "frame", "position", [174 610 1 1], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [174 610 380 1], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [174 610 1 205], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [174 815 380 1], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "frame", "position", [553 610 1 205], "backgroundcolor", [0.0 0.0 0.0], "tag", "parameter_frame");
uicontrol(f, "style", "text", "string", "Ausgänge", "position", [200 806 55 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left", "fontsize", 12);


// --- Tabellen (Listboxen) ---
t_box  = uicontrol(f, "style", "listbox", "position", [400 635 40 155], "string", "", "callback", "on_listbox_select()");
a1_box = uicontrol(f, "style", "listbox", "position", [450 635 40 155], "string", "", "callback", "on_listbox_select()");
a2_box = uicontrol(f, "style", "listbox", "position", [500 635 40 155], "string", "", "callback", "on_listbox_select()");

//eingabe feld beschriftung
uicontrol(f, "style", "text", "string", "Zeitpunkt: ", "position", [182 775 55 30], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "Ausgang 1: ", "position", [247 775 55 30], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "Ausgang 2: ", "position", [312 775 55 30], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "left");

// --- Eingabefelder für neue Werte ---
t_input  = uicontrol(f, "style", "edit", "position", [182 750 65 30], "string", "0");
a1_input = uicontrol(f, "style", "edit", "position", [247 750 65 30], "string", "0");
a2_input = uicontrol(f, "style", "edit", "position", [312 750 65 30], "string", "0");

// Tabelle - Eingaben auflistung
uicontrol(f, "style", "text", "string", "t", "position", [400 790 40 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "center");
uicontrol(f, "style", "text", "string", "A1", "position", [450 790 40 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "center");
uicontrol(f, "style", "text", "string", "A2", "position", [500 790 40 20], "backgroundcolor", [0.9 0.9 0.9], "horizontalalignment", "center");

// --- Hinzufügen-Button ---
add_button = uicontrol(f, "style", "pushbutton", "string", "Hinzufügen", "position", [180 710 100 30], "callback", "add_checkpoint()", "enable", "on");
rem_point = uicontrol(f, "style", "pushbutton", "string", "Entfernen", "position", [280 710 100 30], "callback", "remove_checkpoint()", "enable", "off");
rep_point = uicontrol(f, "style", "pushbutton", "string", "Ersetzen", "position", [180 680 100 30], "callback", "replace_checkpoint()", "enable", "off");
clear_point = uicontrol(f, "style", "pushbutton", "string", "Alles löschen", "position", [280 680 100 30], "callback", "clear_checkpoint()", "enable", "on");
// Button zum Laden vordefinierter Funktionen
// Dropdown zur Auswahl der Eingabefunktion
input_function_dropdown = uicontrol(f, "style", "popupmenu", "string", ["manuelle Eingabe"; "Funktion A"; "Funktion B"], "position", [180 640 200 30], "callback", "load_preset_function()");

// --- Messung Starten
mess_start = uicontrol(f, "style", "pushbutton", "string", "Messung starten", "position", [820 20 130 50], "callback", "startProcess()", "enable", "on", "fontsize", 12);

// --- Messung Stoppen
mess_stopp = uicontrol(f, "style", "pushbutton", "string", "Messung stoppen", "position", [670 20 130 50], "callback", "setStop()", "callback_type", 12, "enable", "off", "fontsize", 12);


//export button
export_button = uicontrol(f, "style", "pushbutton", "string",  "Export","position", [20 20 130 50],"callback", "export()","enable","on","tag","export_button", "fontsize", 12);
global export_button;
//uicontrol(f, "style", "pushbutton", "string", "Export", "position", [20 20 130 50], "callback", "export()", "fontsize", 12);    
timeBuffer = evstr(dauer_input.string);    
ax = newaxes();
ax.axes_bounds = [-0.1, 0.22, 1.2, 0.75]; // Fill frame2 (which is lower 600px of 800px)
minVoltageDisplay = 0;
maxVoltageDisplay = 12;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
global e1;  
e1 = gce().children(1);
e1.tag = "minuteVoltage1";
e1.foreground = color("black");
e1.visible = "on";
e1.thickness = 2;

plot(0:timeBuffer, zeros(1, timeBuffer + 1));
global e2;  
e2 = gce().children(1);
e2.tag = "minuteVoltage2";
e2.foreground = color("green");
e2.visible = "on";
e2.thickness = 2;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
global e3;  
e3 = gce().children(1);
e3.tag = "minuteVoltage3";
e3.foreground = color("blue");
e3.visible = "on";
e3.thickness = 2;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
global e4;  
e4 = gce().children(1);
e4.tag = "minuteVoltage4";
e4.foreground = color("red");
e4.visible = "on";
e4.thickness = 2;


gca().title.text = "Spannungsverlauf";
gca().data_bounds = [0, minVoltageDisplay; timeBuffer+display_extra, maxVoltageDisplay];

xlabel("Zeit (s)");
ylabel("Spannung (V)");

// Sekunden-Counter
global sec;
sec = 1;

global stop;
stop = 1; //0 = false , 1 = true

// Zweites Diagramm, für Eingabe Funtkion 
bax = newaxes();
bax.axes_bounds = [0.52, 0.0, 0.5, 0.27]; 

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

//gca().title.text = "Eingabe Funktion";
gca().data_bounds = [0, minVoltageDisplay; timeBuffer+ display_extra, maxVoltageDisplay];
initializeButtons();

// --- Funktion zum Hinzufügen eines Checkpoints ---
function add_checkpoint()
    global t_list a1_list a2_list;
    global t_input a1_input a2_input;
    global t_box a1_box a2_box;
    global neue_dauer dt;

    // ---------- Eingaben lesen & begrenzen ----------
    t_val  = max(0, evstr(t_input.string));             //  t ≥ 0
    a1_val = min(10, max(0, evstr(a1_input.string)));   //  0 … 10 V
    a2_val = min(10, max(0, evstr(a2_input.string)));   //  0 … 10 V

    if isempty(dt) then             // noch nicht definiert?
        rate = evstr(abtastrate_input.string);
        if rate <= 0 then
            messagebox("Bitte zuerst eine gültige Abtastrate eingeben.","Hinweis");
            return
        end
        dt = 1 / rate;
    end

    // Schrittweite erzwingen
    if modulo(t_val, dt) <> 0 then
        messagebox("Zeitwerte müssen ein ganzzahliges Vielfaches von "+string(dt)+" s sein.","Hinweis");
        return
    end

    // Auf Messfenster begrenzen
    if t_val > neue_dauer then t_val = neue_dauer; end

    // ---------- Doppeltes t?  →  ersetzen ----------
    idx = find(t_list == t_val);
    if ~isempty(idx) then
        t_list(idx)  = t_val;
        a1_list(idx) = a1_val;
        a2_list(idx) = a2_val;
    else                       // sonst neu anhängen
        t_list($+1)  = t_val;
        a1_list($+1) = a1_val;
        a2_list($+1) = a2_val;
    end

    // ---------- Listen sortieren & GUI refresh ----------
    [t_list, order] = gsort(t_list,"g","i");
    a1_list = a1_list(order);
    a2_list = a2_list(order);

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
    global neue_dauer dt;

    // Index ermitteln (welcher Eintrag wurde markiert?)
    idx = max([t_box.value, a1_box.value, a2_box.value]);
    if idx == 0 then return; end      // nichts markiert

    // ---------- Eingaben lesen & begrenzen ----------
    t_val  = max(0, evstr(t_input.string));
    a1_val = min(10, max(0, evstr(a1_input.string)));
    a2_val = min(10, max(0, evstr(a2_input.string)));

    if modulo(t_val, dt) <> 0 then
        messagebox("Zeitwerte müssen ein ganzzahliges Vielfaches von "+string(dt)+" s sein.","Hinweis");
        return
    end
    if t_val > neue_dauer then t_val = neue_dauer; end

    // ---------- Prüfen, ob t_val schon anderweitig existiert ----------
    idx_dupl = find(t_list == t_val);
    if ~isempty(idx_dupl) & idx_dupl <> idx then
        messagebox("Es existiert bereits ein Punkt bei t = "+string(t_val)+" s.","Hinweis");
        return
    end

    // ---------- Wert übernehmen ----------
    t_list(idx)  = t_val;
    a1_list(idx) = a1_val;
    a2_list(idx) = a2_val;

    // Neu sortieren
    [t_list, order] = gsort(t_list,"g","i");
    a1_list = a1_list(order);
    a2_list = a2_list(order);

    // GUI-Refresh
    t_box.string  = string(t_list);
    a1_box.string = string(a1_list);
    a2_box.string = string(a2_list);
    update_input_plot();
    updateEingabe();
endfunction

function replace_checkpoint_at(index, t_val, a1_val, a2_val)
    global t_list a1_list a2_list neue_dauer dt;

    // ---------- Grenzen & Schrittweite ----------
    t_val  = max(0, min(t_val , neue_dauer));
    a1_val = min(10, max(0, a1_val));
    a2_val = min(10, max(0, a2_val));
    if modulo(t_val, dt) <> 0 then return; end

    // --------- doppeltes t an anderer Stelle? ----------
    idx_dupl = find(t_list == t_val);
    if ~isempty(idx_dupl) & idx_dupl <> index then
        return   // nichts ändern, um Duplikate zu vermeiden
    end

    // ---------- übernehmen ----------
    t_list(index)  = t_val;
    a1_list(index) = a1_val;
    a2_list(index) = a2_val;
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
    
    // Zweite Achse aktivieren
    f = gcf();
    a = findobj("tag", "EingabeAchse");
    scf(f); // zur aktuellen Figur
    
    update_input_plot();
    updateEingabe();
    updateSpannung();
    
endfunction

function updateSpannung()
    global ax neue_dauer display_extra;
    sca(ax);

    plot_ende = neue_dauer + display_extra;

    plot(0:plot_ende, zeros(1, plot_ende + 1));
    e1 = gce().children(1);
    e1.tag = "minuteVoltage1";
    e1.foreground = color("black");
    e1.visible = "on";
    e1.thickness = 2;

    plot(0:plot_ende, zeros(1, plot_ende + 1));
    e2 = gce().children(1);
    e2.tag = "minuteVoltage2";
    e2.foreground = color("green");
    e2.visible = "on";
    e2.thickness = 2;

    plot(0:plot_ende, zeros(1, plot_ende + 1));
    e3 = gce().children(1);
    e3.tag = "minuteVoltage3";
    e3.foreground = color("blue");
    e3.visible = "on";
    e3.thickness = 2;

    plot(0:plot_ende, zeros(1, plot_ende + 1));
    e4 = gce().children(1);
    e4.tag = "minuteVoltage4";
    e4.foreground = color("red");
    e4.visible = "on";
    e4.thickness = 2;

    gca().data_bounds = [0, 0; plot_ende, 12];
    
endfunction

function updateEingabe()
    global bax neue_dauer display_extra;
    sca(bax);

    plot_ende = neue_dauer + display_extra;
    // Treppenkurven für die Initialisierung erzeugen
    [x0, y0] = stairs_data(0:neue_dauer, zeros(1, neue_dauer + 1));

    // A1 plotten (rot)
    plot(x0, y0);
    e5 = gce().children(1);
    e5.tag = "A1";
    e5.foreground = color("red");
    e5.visible = "on";
    e5.thickness = 2;

    // A2 plotten (schwarz)
    plot(x0, y0);
    e6 = gce().children(1);
    e6.tag = "A2";
    e6.foreground = color("black");
    e6.visible = "on";
    e6.thickness = 2;

    // Achseneinstellung für die Eingabedarstellung
    gca().data_bounds = [0, 0; plot_ende, 12];
endfunction

function update_input_plot() 
    global t_list a1_list a2_list;
    global dauer_input;
    global neue_dauer display_extra;
    global t_box a1_box a2_box;

    updateEingabe();

    // Plot-Ende = Messdauer + 10 s
    dauer        = neue_dauer;        // reiner Messbereich
     plot_ende = neue_dauer + display_extra;


    // komplette Zeitachse (0 … Messdauer + 10 s)
    t = 0:1:plot_ende;


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

    // 0 V erzwingen, sobald t > Messdauer
    idx_zero        = find(t > neue_dauer);
    if ~isempty(idx_zero) then
        y1(idx_zero) = 0;
        y2(idx_zero) = 0;
    end

    // Plot aktualisieren
    f = gcf();
    scf(f);
    
    [xs,  ys1] = stairs_data(t, y1);
    [dummy, ys2] = stairs_data(t, y2);   // dummy kannst du ignorieren

    // A1 updaten
    a1_plot = findobj("tag", "A1");
    a1_plot.data = [xs' ys1'];

    // A2 updaten
    a2_plot = findobj("tag", "A2");
    a2_plot.data = [xs' ys2'];
    
endfunction

function setStop() 
    global mess_stopp;
    global stop;
    global input_function_dropdown;
    stop = 1;
    //ausgänge auf 0 setzen
    call("cao", 2.5, 1, "r", 2.5 , 2, "r", "out", [1,1], 3, "i");
    clear_point.enable = "on";
    abtastrate_input.enable = "on";
    dauer_input.enable = "on";
    add_button.enable = "on";
    mess_start.enable = "on";
    mess_stopp.enable = "off";
    input_function_dropdown.enable = "off";
    export_button.enable = "on";
    
    
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
    
   
    
    err= call("cao", (output_A1+10)/4, 1, "r", (output_A2+10)/4, 2, "r", "out", [1,1], 3, "i");
    if err <> 0 then
        disp("Fehler beim Setzen von AO1: Fehlercode " + string(err));
    end
    
endfunction

function initializeButtons()
    // Überprüfen und Erstellen der Buttons
    global mess_start add_button rem_point rep_point clear_point mess_stopp input_function_dropdown export_button;

    // Initialize "Messung starten" Button
    mess_start = findobj("tag", "mess_start");
    if isempty(mess_start) then
        mess_start = uicontrol(f, "style", "pushbutton", "string", "Messung starten", "position", [820 20 130 50], "callback", "startProcess()", "enable", "on", "tag", "mess_start", "fontsize", 12);
    else
        mess_start.string = "Messung starten";  // Setze den Text des Buttons zurück
        mess_start.enable = "on";  // Stelle sicher, dass der Button aktiv ist
    end

    // Initialize "Messung stoppen" Button
    mess_stopp = findobj("tag", "mess_stopp");
    if isempty(mess_stopp) then
        mess_stopp = uicontrol(f, "style", "pushbutton", "string", "Messung stoppen", ...
            "position", [670 20 130 50], "callback", "setStop()", "callback_type", 12, "enable", "off", "tag", "mess_stopp", "fontsize", 12);
    else
        mess_stopp.string = "Messung stoppen";  // Setze den Text des Buttons zurück
        mess_stopp.enable = "off";  // Stelle sicher, dass der Button deaktiviert ist
    end

    // Initialize "Hinzufügen" Button
    add_button = findobj("tag", "add_button");
    if isempty(add_button) then
        add_button = uicontrol(f, "style", "pushbutton", "string", "Hinzufügen", "position", [180 710 100 30], "callback", "add_checkpoint()", "enable", "on", "tag", "add_button", "fontsize", 12);
    else
        add_button.string = "Hinzufügen";  // Setze den Text des Buttons zurück
        add_button.enable = "on";  // Stelle sicher, dass der Button aktiv ist
    end

    // Initialize "Entfernen" Button
    rem_point = findobj("tag", "rem_point");
    if isempty(rem_point) then
        rem_point = uicontrol(f, "style", "pushbutton", "string", "Entfernen", "position", [[280 710 100 30]], "callback", "remove_checkpoint()", "enable", "off", "tag", "rem_point", "fontsize", 12);
    else
        rem_point.string = "Entfernen";  // Setze den Text des Buttons zurück
        rem_point.enable = "off";  // Stelle sicher, dass der Button deaktiviert ist
    end

    // Initialize "Ersetzen" Button
    rep_point = findobj("tag", "rep_point");
    if isempty(rep_point) then
        rep_point = uicontrol(f, "style", "pushbutton", "string", "Ersetzen", ...
            "position", [180 680 100 30], "callback", "replace_checkpoint()", "enable", "off", "tag", "rep_point", "fontsize", 12);
    else
        rep_point.string = "Ersetzen";  // Setze den Text des Buttons zurück
        rep_point.enable = "off";  // Stelle sicher, dass der Button deaktiviert ist
    end

    // Initialize "Clear" Button
    clear_point = findobj("tag", "clear_point");
    if isempty(clear_point) then
        clear_point = uicontrol(f, "style", "pushbutton", "string", "Alles löschen", ...
            "position", [280 680 100 30], "callback", "clear_checkpoint()", "enable", "on", "tag", "clear_point", "fontsize", 11);
    else
        clear_point.string = "Alles löschen";  // Setze den Text des Buttons zurück
        clear_point.enable = "on";  // Stelle sicher, dass der Button aktiv ist
    end

    // Initialize Dropdown for Input Function
    input_function_dropdown = findobj("tag", "input_function_dropdown");
    if isempty(input_function_dropdown) then
        input_function_dropdown = uicontrol(f, "style", "popupmenu", "string", ["manuelle Eingabe"; "Funktion A"; "Funktion B"], "position", [180 640 200 30], "callback", "load_preset_function()", "tag", "input_function_dropdown", "value", 1, "fontsize", 12, "enable", "on");
    end

    // Initialize Export Button
    export_button = findobj("tag", "export_button");
    if isempty(export_button) then
        export_button = uicontrol(f, "style", "pushbutton", "string", "Export", "position", [20 20 130 50], "callback", "export()", "enable", "on", "tag", "export_button", "fontsize", 12);
    else
        export_button.string = "Export";
        export_button.enable = "on";
    end
endfunction


function load_preset_function()
    global t_list a1_list a2_list;
    global t_box a1_box a2_box;
    global dauer_input;
    global neue_dauer;
    global input_function_dropdown;

    // Ausgewählte Option abrufen
    selected_idx = input_function_dropdown.value;

    select selected_idx
        case 1  // Manuelle Eingabe
            t_list = [];
            a1_list = [];
            a2_list = [];
            neue_dauer = 80;  // Standarddauer setzen
            // Listboxen leeren
            t_box.string = "";
            a1_box.string = "";
            a2_box.string = "";
            update_input_plot();
        case 2  // Funktion A
            t_list = [0; 10; 70];
            a1_list = [0; 10; 0];
            a2_list = [0; 0; 0];
            neue_dauer = 80;
        case 3  // Funktion B
            t_list = [0; 10; 80; 150];
            a1_list = [0; 5; 7; 0];
            a2_list = [0; 0; 0; 0];
            neue_dauer = 160;
        else
            return;
    end

    // Messdauer aktualisieren
    dauer_input.string = string(neue_dauer);

    // Listboxen aktualisieren
    t_box.string = string(t_list);
    a1_box.string = string(a1_list);
    a2_box.string = string(a2_list);

    updateSpannung()
    updateInputFunction()
    update_input_plot();
endfunction

function [xs, ys] = stairs_data(x, y)
//  Wandelt Vektoren (x,y) in Stützpunkte für eine Treppenkurve um
    n  = length(x);
    xs = zeros(1, 2*n - 1);
    ys = zeros(1, 2*n - 1);
    for k = 1:n-1
        xs(2*k-1) = x(k);      
        ys(2*k-1) = y(k);   // horizontale Linie
        xs(2*k)   = x(k+1);    
        ys(2*k)   = y(k);   // senkrechter Sprung
    end
    xs($) = x($);              
    ys($) = y($);       // letzter Punkt
endfunction