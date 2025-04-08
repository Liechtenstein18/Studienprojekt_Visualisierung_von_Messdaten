// * Load LabJack U12 Custom DLL
ilib_for_link(['cab', 'cao'], "mile2.c", [], "c");
exec loader.sce;

// * Main Window
f=figure("dockable","off");
f.resize="off";
f.menubar_visible="off";
f.toolbar_visible="off";
f.figure_name="Messung";
f.tag="mainWindow";
f.figure_position = [400 200];
f.figure_size = [1000 700];
f.background = color(179, 179, 179); //color("darkgrey")

// * Main Panel
mainFrame = uicontrol(f, "style", "frame", "position", [15 560 305 80], ...
"tag", "mainFrame", "ForegroundColor", [0/255 0/255 0/255],...
"border", createBorder("titled", createBorder("line", "lightGray", 1)...
, _("Main Panel"), "center", "top", createBorderFont("", 11, "normal"), ...
"black"));
// Buttons
startButton = uicontrol("parent", f, "style", "pushbutton", "position", ...
[20 595 145 30], "callback", "startProcess()", "string", "Start Acquisition", ...
"tag", "startButton");
stopButton = uicontrol("parent", f, "style", "pushbutton", "position", ...
[170 595 145 30], "callback", "stopProcess()", "callback_type", 10, "string", "Stop Acquisition", ...
"tag", "stopButton");
resetButton = uicontrol("parent", f, "style", "pushbutton", "position", ...
[20 565 145 30], "callback", "resetProcess()", "callback_type", 10, "string", "Reset", ...
"tag", "resetButton");
quitButton = uicontrol("parent", f, "style", "pushbutton", "position", ...
[170 565 145 30], "callback", "closeFigure()", "callback_type", 10, "string", "Quit", ...
"tag", "quitButton");


// * Graph 
top_axes_bounds = [0.05 0.1 0.9 0.9];
minVotageDisplay = 0;
maxVoltageDispay = 10;
timeBuffer = 300;
subplot(222);
a = gca();
a.axes_bounds = top_axes_bounds;
a.y_location = "left";
a.y_label.text = "Spannung";
a.x_label.text = "Zeit";
a.filled = "on";
a.background = color("white");
a.tag = "minuteAxes";
a.title.text="Spannung Plot";
a.data_bounds = [0, minVotageDisplay; timeBuffer, maxVoltageDispay];

// analog IN 1
plot(0:timeBuffer, zeros(1,timeBuffer + 1));
e = gce();
e = e.children(1);
e.tag = "minuteVoltage1";
e.foreground = color("red");

// analog IN 2
plot(0:timeBuffer, zeros(1,timeBuffer + 1));
e = gce();
e = e.children(1);
e.tag = "minuteVoltage2";
e.foreground = color("blue");

// analog IN 3
plot(0:timeBuffer, zeros(1,timeBuffer + 1));
e = gce();
e = e.children(1);
e.tag = "minuteVoltage3";
e.foreground = color("green");

// analog IN 4
plot(0:timeBuffer, zeros(1,timeBuffer + 1));
e = gce();
e = e.children(1);
e.tag = "minuteVoltage4";
e.foreground = color("black");

// Seconds Counter
global sec;
sec = 1;

// * Functions
// Function to Close the Window
// Used in - Quit button on the Main Panel
function closeFigure()
    global Stop;
    Stop = %t;
    f = findobj("tag", "mainWindow");
    delete(f);
    
endfunction

// Function to stop acquiring data
// Used in - Stop button on the Main Panel
function stopProcess()
    global Stop;
    Stop = %t;
    
endfunction


// Function to reset display
// Used in - Reset button on the Main Panel
function resetProcess()
    global sec;
    sec = 1;
    e = findobj("tag", "minuteVoltage1");
    e.data(:, 2) = 0;

endfunction


// Function to start acquiring data
function startProcess()
    // channel 0 is analog In 1 RED
    // channel 2 is analog In 2 RED
    // channel 4 is analog In 3 RED
    // channel 6 is analog In 4 RED
    
    // channel 1 is analog In 1 BLUE
    // channel 3 is analog In 2 BLUE
    // channel 5 is analog In 3 BLUE
    // channel 7 is analog In 4 BLUE
    global sec;
    global Stop;
    Stop = %f;
    e = findobj("tag", "minuteVoltage1");
    e2 = findobj("tag", "minuteVoltage2");
    e3 = findobj("tag", "minuteVoltage3");
    e4 = findobj("tag", "minuteVoltage4");
    channel1 = 0; // Channel 1
    channel2 = 2; // Channel 2
    channel3 = 4; // Channel 3
    channel4 = 6; // Channel 4
    inputValue2 = 10; // Could be changed
    
    while %t
        // V1
        voltage1 = call("cab", channel1, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e.data(sec, 2) = voltage1;
        // V2
        voltage2 = call("cab", channel2, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e2.data(sec, 2) = voltage2;
        // V3
        voltage3 = call("cab", channel3, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e3.data(sec, 2) = voltage3;
        // V4
        voltage4 = call("cab", channel4, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
        e4.data(sec, 2) = voltage4;
        
        sleep(1000);
        sec = sec + 1;
        if Stop then
            break
        end
    end
    
endfunction













