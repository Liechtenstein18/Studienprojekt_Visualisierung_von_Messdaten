// -*- Load LabJack U12 Custom DLL -*-
//ilib_for_link(["cab", "cao"], "mile11.c", [], "c");
//exec('loader.sce');

//für den start der Messung
//function startProcess()
//    
//endfunction

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
    options = ["png", "pdf", "svg"];
    selected_idx = export_format_dropdown.value;
    selected_format = options(selected_idx);
    
    select selected_format
        case "png"
            xs2png(gcf(),'untitled.png');
        case "pdf"
            xs2pdf(gcf(),'untitled');
        case "svg"
            xs2svg(gcf(),'untitled.svg');
        else
            disp("Unknown format selected");
    end
    
endfunction
// --- Fenster & Grundstruktur ---
f = figure("position", [100 100 1000 800]);
f.menubar_visible = "on";
f.toolbar_visible = "on";
f.resize = "off";

//frame1 = uicontrol(f, "style", "frame", "position", [0 0 1000 200], "backgroundcolor", [1 0 1]);
//frame2 = uicontrol(f, "style", "frame", "position", [0 0 1000 600], "backgroundcolor", [0.5 0.5 0.5]);

// --- GUI-Komponenten global machen ---
global dauer_input abtastrate_input;
global t_input a1_input a2_input;
global t_box a1_box a2_box;

// --- Beschriftungen & Eingaben oben ---
uicontrol(f, "style", "text", "string", "Messparameter", "position", [40 780 150 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "Messdauer:", "position", [40 760 100 20], "backgroundcolor", [1 1 1], "horizontalalignment", "left");
dauer_input = uicontrol(f, "style", "edit", "string", "80", "position", [120 760 50 20]);
uicontrol(f, "style", "text", "string", " s", "position", [170 760 20 20], "backgroundcolor", [1 1 1]);

uicontrol(f, "style", "text", "string", "Abtastrate:", "position", [40 740 100 20], "backgroundcolor", [1 1 1], "horizontalalignment", "left");
abtastrate_input = uicontrol(f, "style", "edit", "string", "10", "position", [120 740 50 20]);
uicontrol(f, "style", "text", "string", " 1/s", "position", [170 740 20 20], "backgroundcolor", [1 1 1]);

// --- Globale Daten-Arrays ---
global t_list a1_list a2_list;
t_list = [];
a1_list = [];
a2_list = [];

// --- Tabellen (Listboxen) ---
t_box  = uicontrol(f, "style", "listbox", "position", [650 620 80 150], "string", "");
a1_box = uicontrol(f, "style", "listbox", "position", [750 620 80 150], "string", "");
a2_box = uicontrol(f, "style", "listbox", "position", [850 620 80 150], "string", "");

// --- Eingabefelder für neue Werte ---
t_input  = uicontrol(f, "style", "edit", "position", [280 740 100 30], "string", "0");
a1_input = uicontrol(f, "style", "edit", "position", [400 740 100 30], "string", "0");
a2_input = uicontrol(f, "style", "edit", "position", [520 740 100 30], "string", "0");

// --- Hinzufügen-Button ---
uicontrol(f, "style", "pushbutton", "string", "Hinzufügen", "position", [280 700 100 30], ...
  "callback", "add_checkpoint()");

  uicontrol(f, "style", "pushbutton", "string", "Entfernen", "position", [400 700 100 30], ...
  "callback", "remove_checkpoint()");

  uicontrol(f, "style", "pushbutton", "string", "Ersetzen", "position", [520 700 100 30], ...
  "callback", "replace_checkpoint()");

// beschriftung
uicontrol(f, "style", "text", "string", "t", "position", [650 770 80 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "A1", "position", [750 770 80 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "A2", "position", [850 770 80 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");

uicontrol(f, "style", "text", "string", "t", "position", [280 770 80 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "A1", "position", [400 770 80 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");
uicontrol(f, "style", "text", "string", "A2", "position", [520 770 80 20], "backgroundcolor", [0.8 0.8 0.8], "horizontalalignment", "left");

uicontrol(f, "style", "pushbutton", "string", "Messung starten", "position", [40 700 150 30], ...
    "callback", "startProcess()");

//checkboxes für das auswählen der plots
cb1 = uicontrol("style", "checkbox", "parent", f, "string", "Input 1", "value", 1, ...
    "position", [820 500 140 20], "callback", strcat(["toggleGraph(""minuteVoltage1"", gcbo.value)"]));
cb2 = uicontrol("style", "checkbox", "parent", f, "string", "Input 2", "value", 1, ...
    "position", [820 460 140 20], "callback", strcat(["toggleGraph(""minuteVoltage2"", gcbo.value)"]));
cb3 = uicontrol("style", "checkbox", "parent", f, "string", "Input 3", "value", 1, ...
    "position", [820 420 140 20], "callback", strcat(["toggleGraph(""minuteVoltage3"", gcbo.value)"]));
cb4 = uicontrol("style", "checkbox", "parent", f, "string", "Input 4", "value", 1, ...
    "position", [820 380 140 20], "callback", strcat(["toggleGraph(""minuteVoltage4"", gcbo.value)"]));

//drop down for the export button
global export_format_dropdown;
export_format_dropdown = uicontrol(f, "style", "popupmenu", ...
    "string", ["png"; "pdf"; "svg"], ...
    "position", [750 40 100 20]);
//export button
uicontrol(f, "style", "pushbutton", "string", "Export", "position", [860 40 100 20], ...
  "callback", "export()");    
    
ax = newaxes();
ax.axes_bounds = [-0.075, 0.20, 1, 0.75]; // Fill frame2 (which is lower 600px of 800px)
minVoltageDisplay = 0;
maxVoltageDisplay = 10;
timeBuffer = 80;

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

// Sekunden-Counter
global sec;
sec = 1;

// --- Funktion zum Hinzufügen eines Checkpoints ---
function add_checkpoint()
    // Zugriff auf globale Variablen & GUI-Objekte
    global t_list a1_list a2_list;
    global t_input a1_input a2_input;
    global t_box a1_box a2_box;

    // Eingaben auslesen und in Zahlen umwandeln
    t_val  = evstr(t_input.string);
    a1_val = evstr(a1_input.string);
    a2_val = evstr(a2_input.string);

    // Werte zur Liste hinzufügen
    t_list($+1)  = t_val;
    a1_list($+1) = a1_val;
    a2_list($+1) = a2_val;

    // Listboxen aktualisieren
    t_box.string  = string(t_list);
    a1_box.string = string(a1_list);
    a2_box.string = string(a2_list);
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
    end
endfunction

