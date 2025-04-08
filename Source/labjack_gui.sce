// -*- Load LabJack U12 Custom DLL -*-
ilib_for_link(["cab", "cao"], "mile11.c", [], "c");
exec('loader.sce');

// -*- Main Window -*-
f = figure("dockable", "off");
f.resize = "on";
f.menubar_visible = "off";
f.toolbar_visible = "off";
f.figure_name = "Messung";
f.tag = "mainWindow";
f.figure_position = [400 200];
f.figure_size = [1000 700];
f.background = color(179, 179, 179); // color("darkgrey")

// -*- Main Panel -*-
mainFrame = uicontrol(f, "style", "frame", "position", [15 560 305 80], "tag", "mainFrame", ...
    "ForegroundColor", [0/255 0/255 0/255], "border", ...
    createBorder("titled", createBorder("line", "lightGray", 1), _("Main Panel"), "center", ...
    "top", createBorderFont("", 11, "normal"), "black"));

// Buttons
startButton = uicontrol("parent", f, "style", "pushbutton", "position", [20 595 145 30], ...
    "callback", "startProcess()", "string", "Start Acquisition", "tag", "startButton");
stopButton = uicontrol("parent", f, "style", "pushbutton", "position", [170 595 145 30], ...
    "callback", "stopProcess()", "callback_type", 10, "string", "Stop Acquisition", "tag", "stopButton");
resetButton = uicontrol("parent", f, "style", "pushbutton", "position", [20 565 145 30], ...
    "callback", "resetProcess()", "callback_type", 10, "string", "Reset", "tag", "resetButton");
quitButton = uicontrol("parent", f, "style", "pushbutton", "position", [170 565 145 30], ...
    "callback", "closeFigure()", "callback_type", 10, "string", "Quit", "tag", "quitButton");

// Toggle Buttons (rechts untereinander)
cb1 = uicontrol("style", "checkbox", "parent", f, "string", "Input - Füllstand", "value", 1, ...
    "position", [900 550 80 20], "callback", strcat(["toggleGraph(""minuteVoltage1"", gcbo.value)"]));
cb2 = uicontrol("style", "checkbox", "parent", f, "string", "Arbeit der Pumpe nach Verstärkung", "value", 1, ...
    "position", [900 520 80 20], "callback", strcat(["toggleGraph(""minuteVoltage2"", gcbo.value)"]));
cb3 = uicontrol("style", "checkbox", "parent", f, "string", "Füllstand", "value", 1, ...
    "position", [900 490 80 20], "callback", strcat(["toggleGraph(""minuteVoltage3"", gcbo.value)"]));
cb4 = uicontrol("style", "checkbox", "parent", f, "string", "Arbeit der Pumpe vor Verstärkung", "value", 1, ...
    "position", [900 460 80 20], "callback", strcat(["toggleGraph(""minuteVoltage4"", gcbo.value)"]));

// Eingabefeld für Analog Output AO1
uicontrol("style", "text", "parent", f, "string", "AO1 Spannung (0-10V):", "position", [575 560 130 25]);
analogOutField = uicontrol("style", "edit", "parent", f, "string", "1.0", ...
    "position", [700 560 60 25], "callback", "setAO1()");

function setAO1()
    valStr = analogOutField.string;
    val = evstr(valStr);
    if val >= 0 & val <= 10 then
        AO0 = 0.0;
        AO1 = (val+10)/4; // hier !!
        err = call("cao", AO1, 1, "r", AO0, 2, "r", "out", [1,1], 3, "i"); 
        if err <> 0 then
            disp("Fehler beim Setzen von AO1: Fehlercode " + string(err));
        end
    else
        disp("Ungültige Eingabe: Wert muss zwischen 0 und 10 liegen.");
    end
endfunction

function toggleGraph(tagName, visible)
    e = findobj("tag", tagName);
    if visible then
        e.visible = "on";
    else
        e.visible = "off";
    end
endfunction

// -*- Graph (Einzelplot) -*-
minVoltageDisplay = 0;
maxVoltageDisplay = 10;
timeBuffer = 300;

subplot(111);
plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e1 = gce().children(1);
e1.tag = "minuteVoltage1";
e1.foreground = color("black");
e1.visible = "on";
e1.thickness = 3;

plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e2 = gce().children(1);
e2.tag = "minuteVoltage2";
e2.foreground = color("green");
e2.visible = "on";
e2.thickness = 3;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e3 = gce().children(1);
e3.tag = "minuteVoltage3";
e3.foreground = color("blue");
e3.visible = "on";
e3.thickness = 3;


plot(0:timeBuffer, zeros(1, timeBuffer + 1));
e4 = gce().children(1);
e4.tag = "minuteVoltage4";
e4.foreground = color("red");
e4.visible = "on";
e4.thickness = 3;


gca().title.text = "Spannungsverlauf";
gca().data_bounds = [0, minVoltageDisplay; timeBuffer, maxVoltageDisplay];

// Sekunden-Counter
global sec;
sec = 1;

function closeFigure()
    global Stop;
    Stop = %t;
    f = findobj("tag", "mainWindow");
    delete(f);
endfunction

function stopProcess()
    global Stop;
    Stop = %t;
endfunction

function resetProcess()
    global sec;
    sec = 1;
    e = findobj("tag", "minuteVoltage1");
    e.data(:, 2) = 0;
endfunction

function startProcess()
    global sec;
    global Stop;

    Stop = %f;

    e = findobj("tag", "minuteVoltage1");
    e2 = findobj("tag", "minuteVoltage2");
    e3 = findobj("tag", "minuteVoltage3");
    e4 = findobj("tag", "minuteVoltage4");

    channel1 = 0;
    channel2 = 2;
    channel3 = 4;
    channel4 = 6;
    inputValue2 = 10;

    while %t
        voltage1 = call("cab", channel1, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e.data(sec, 2) = voltage1;

        voltage2 = call("cab", channel2, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e2.data(sec, 2) = voltage2;

        voltage3 = call("cab", channel3, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e3.data(sec, 2) = voltage3;

        voltage4 = call("cab", channel4, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e4.data(sec, 2) = voltage4;

        sleep(1000);
        sec = sec + 1;

        if Stop then
            break
        end
    end
endfunction
