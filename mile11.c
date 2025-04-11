#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <windows.h>

typedef long (__stdcall *tEAnalogOut)(long*,long,float,float);
typedef long (__stdcall *tEAnalogIn)(long*,long,long,long,long*,float*);

/**************************************************/
// To Load this file into the Scilab Program we need to enter the following code
// at the beginning of the file :
//   ilib_for_link(['cab', 'cao'], "mile2.c", [], "c");
//   exec loader.sce;   
// 
/**************************************************/

/**************************************************/
// This function sends the given voltage into the LabJack 
// AO0 and AO1 connector
// The graph for the LabJack can be found here : https://support.labjack.com/docs/2-hardware-description-u12-datasheet
// To call the cao Function in the while Loop or wherever we need : 
//    AO0 and AO1 can be changed to send different values for the voltage.
//      AO0 = 2.0;
//      AO1 = 4.0;
//      errorcode = call("cao", AO0, 1, "r", AO1, 2, "r", "out", [1,1], 3, "i");
// call Function Documentation can be found here :  https://help.scilab.org/call
/**************************************************/
void cao(float *a, float *b, int *c)
{   

    //Define variables for functions we will use.
    tEAnalogOut m_pEAnalogOut;

    // Load the LabJack U12 DLL
    HINSTANCE hDLLInstance = LoadLibrary("ljackuw.dll");
    if (hDLLInstance == NULL) {
        printf("Failed to load DLL\n");
    }

    // Get function addresses
    m_pEAnalogOut = (tEAnalogOut)GetProcAddress(hDLLInstance, "EAnalogOut");


    long errorcode;
    long idnum = 2;
    long demo = 0;
    float AO0 = a[0];
    float AO1 = b[0];

    // Calls the Analog Out Function
    // This function sends the given Voltage into AO0 and AO1 
    // For further information visit : https://support.labjack.com/docs/4-2-eanalogout-u12-datasheet
	errorcode = m_pEAnalogOut(&idnum, demo, AO0, AO1);

    // Returns LabJack errorcodes or 0 for no error.
    c[0] = (int) errorcode;

}



/**************************************************/
// This function reads the voltage from the given Channel 
// To call the cab Function in the while Loop or wherever we need : 
// channel1 is the given Channel
// inputValue2 is a testing value, in this function it has no impact
// voltage1 saves the voltage that has been read from the given channel
//      voltage1 = call("cab", channel1, 1, "i", inputValue2, 2, "i", "out", [1,1], 3, "r");
// call Function Documentation can be found here :  https://help.scilab.org/call
/**************************************************/
void cab(int *a, int *b, float *c)
{   

    int test2 = b[0];
    //Define variables for functions we will use.
    tEAnalogIn m_pEAnalogIn;

    // Load the LabJack U12 DLL
    HINSTANCE hDLLInstance = LoadLibrary("ljackuw.dll");
    if (hDLLInstance == NULL) {
        printf("Failed to load DLL\n");
    }

    // Get function addresses
    m_pEAnalogIn = (tEAnalogIn)GetProcAddress(hDLLInstance, "EAnalogIn");


    long errorcode;
    long idnum = 1;
    long demo = 0;
    long channel = a[0];
    long gain = 0;
    long ov = 0;
    float voltage = 0;

	errorcode = m_pEAnalogIn(&idnum, demo, channel, gain, &ov, &voltage);

    c[0] = voltage;
}