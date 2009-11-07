/*
   Copyright (C) 2006-2008 Hans-Christoph Steiner.  All rights reserved.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   See file LICENSE.txt for further informations on licensing terms.
 */

/* 
 * TODO: add Servo support using setPinMode(pin, SERVO);
 * TODO: use Program Control to load stored profiles from EEPROM
 */

#include <EEPROM.h>
#include <Firmata.h>

/*==============================================================================
 * GLOBAL VARIABLES
 *============================================================================*/

/* analog inputs */
int analogInputsToReport = 0; // bitwise array to store pin reporting
int analogPin = 0; // counter for reading analog pins

/* digital pins */
byte reportPINs[TOTAL_PORTS];   // PIN == input port
byte previousPINs[TOTAL_PORTS]; // PIN == input port
byte pinStatus[TOTAL_DIGITAL_PINS]; // store pin status, default OUTPUT
byte portStatus[TOTAL_PORTS];

/* timer variables */
unsigned long currentMillis;     // store the current value from millis()
unsigned long nextExecuteMillis; // for comparison with currentMillis

/*==============================================================================
 * ARDUINOPONICS-SPECIFIC GLOBAL VARIABLES
 *============================================================================*/

int pump_pin = 9;
int led_pin = 11;
int second_pin = 13;

unsigned int seconds = 0;
unsigned int minutes = 0;
unsigned long arduinoponics_nextExecuteMillis; // for comparison with currentMillis

boolean second_led = false;

int pump_run_seconds = 4; //in seconds
int pump_run_interval = 10; //in minutes

boolean pump_on = false;
int pump_time = 0;

/*==============================================================================
 * FUNCTIONS                                                                
 *============================================================================*/

void outputPort(byte portNumber, byte portValue)
{
	portValue = portValue &~ portStatus[portNumber];
	if(previousPINs[portNumber] != portValue) {
		Firmata.sendDigitalPort(portNumber, portValue); 
		previousPINs[portNumber] = portValue;
		Firmata.sendDigitalPort(portNumber, portValue); 
	}
}

/* -----------------------------------------------------------------------------
 * check all the active digital inputs for change of state, then add any events
 * to the Serial output queue using Serial.print() */
void checkDigitalInputs(void) 
{
	byte i, tmp;
	for(i=0; i < TOTAL_PORTS; i++) {
		if(reportPINs[i]) {
			switch(i) {
				case 0: outputPort(0, PIND &~ B00000011); break; // ignore Rx/Tx 0/1
				case 1: outputPort(1, PINB); break;
				case ANALOG_PORT: outputPort(ANALOG_PORT, PINC); break;
			}
		}
	}
}

// -----------------------------------------------------------------------------
/* sets the pin mode to the correct state and sets the relevant bits in the
 * two bit-arrays that track Digital I/O and PWM status
 */
void setPinModeCallback(byte pin, int mode) {
	byte port = 0;
	byte offset = 0;

        /* ignore reserved pins on arduinoponics */
        if(pin == 9 || pin == 11 || pin == 13)
        {
          return;
        }

	if (pin < 8) {
		port = 0;
		offset = 0;
	} else if (pin < 14) {
		port = 1;
		offset = 8;     
	} else if (pin < 22) {
		port = 2;
		offset = 14;
	}

	if(pin > 1) { // ignore RxTx (pins 0 and 1)
		pinStatus[pin] = mode;
		switch(mode) {
			case INPUT:
				pinMode(pin, INPUT);
				portStatus[port] = portStatus[port] &~ (1 << (pin - offset));
				break;
			case OUTPUT:
				digitalWrite(pin, LOW); // disable PWM
			case PWM:
				pinMode(pin, OUTPUT);
				portStatus[port] = portStatus[port] | (1 << (pin - offset));
				break;
				//case ANALOG: // TODO figure this out
			default:
				Firmata.sendString("");
		}
		// TODO: save status to EEPROM here, if changed
	}
}

void analogWriteCallback(byte pin, int value)
{
	setPinModeCallback(pin,PWM);
	analogWrite(pin, value);
}

void digitalWriteCallback(byte port, int value)
{
	switch(port) {
		case 0: // pins 2-7 (don't change Rx/Tx, pins 0 and 1)
			// 0xFF03 == B1111111100000011    0x03 == B00000011
			PORTD = (value &~ 0xFF03) | (PORTD & 0x03);
			break;
		case 1: // pins 8-13 (14,15 are disabled for the crystal) 
			PORTB = (byte)value;
			break;
		case 2: // analog pins used as digital
			PORTC = (byte)value;
			break;
	}
}

// -----------------------------------------------------------------------------
/* sets bits in a bit array (int) to toggle the reporting of the analogIns
 */
//void FirmataClass::setAnalogPinReporting(byte pin, byte state) {
//}
void reportAnalogCallback(byte pin, int value)
{
	if(value == 0) {
		analogInputsToReport = analogInputsToReport &~ (1 << pin);
	}
	else { // everything but 0 enables reporting of that pin
		analogInputsToReport = analogInputsToReport | (1 << pin);
	}
	// TODO: save status to EEPROM here, if changed
}

void reportDigitalCallback(byte port, int value)
{
	reportPINs[port] = (byte)value;
	if(port == ANALOG_PORT) // turn off analog reporting when used as digital
		analogInputsToReport = 0;
}

/*==============================================================================
 * ARDUINOPONICS-SPECIFIC FUNCTIONS                                                                
 *============================================================================*/

void inline pump_control(boolean state)
{
	if(state == true)
	{
		digitalWrite(pump_pin, HIGH);
		digitalWrite(led_pin, HIGH); 
		pump_on = true;
	}
	else
	{
		pump_on = false;
		digitalWrite(pump_pin, LOW);
		digitalWrite(led_pin, LOW);
	}
}

void inline led_blink()
{
	if(!second_led)
	{
		digitalWrite(second_pin, HIGH);
		second_led=true;
	}
	else
	{
		digitalWrite(second_pin, LOW);
		second_led=false;
	}
}


/*==============================================================================
 * SETUP()
 *============================================================================*/
void setup() 
{
	byte i;

	Firmata.setFirmwareVersion(2, 0);

	Firmata.attach(ANALOG_MESSAGE, analogWriteCallback);
	Firmata.attach(DIGITAL_MESSAGE, digitalWriteCallback);
	Firmata.attach(REPORT_ANALOG, reportAnalogCallback);
	Firmata.attach(REPORT_DIGITAL, reportDigitalCallback);
	Firmata.attach(SET_PIN_MODE, setPinModeCallback);

	portStatus[0] = B00000011;  // ignore Tx/RX pins
	portStatus[1] = B11000000;  // ignore 14/15 pins 
	portStatus[2] = B00000000;

	//    for(i=0; i<TOTAL_DIGITAL_PINS; ++i) { // TODO make this work with analogs
	for(i=0; i<14; ++i) {
		setPinModeCallback(i,OUTPUT);
	}
	// set all outputs to 0 to make sure internal pull-up resistors are off
	PORTB = 0; // pins 8-15
	PORTC = 0; // analog port
	PORTD = 0; // pins 0-7

	// TODO rethink the init, perhaps it should report analog on default
	for(i=0; i<TOTAL_PORTS; ++i) {
		reportPINs[i] = false;
	}
	// TODO: load state from EEPROM here

	/* send digital inputs here, if enabled, to set the initial state on the
	 * host computer, since once in the loop(), this firmware will only send
	 * digital data on change. */
	if(reportPINs[0]) outputPort(0, PIND &~ B00000011); // ignore Rx/Tx 0/1
	if(reportPINs[1]) outputPort(1, PINB);
	if(reportPINs[ANALOG_PORT]) outputPort(ANALOG_PORT, PINC);

	Firmata.begin(115200);

	/* Arduinoponics-specific setup function */
	pinMode(pump_pin, OUTPUT);
	pinMode(led_pin, OUTPUT);
	pinMode(second_pin, OUTPUT);
}

/*==============================================================================
 * LOOP()
 *============================================================================*/
void loop() 
{
	/* DIGITALREAD - as fast as possible, check for changes and output them to the
	 * FTDI buffer using Serial.print()  */
	checkDigitalInputs();  
	currentMillis = millis();
	if(currentMillis > nextExecuteMillis) {  
		nextExecuteMillis = currentMillis + 19; // run this every 20ms
		/* SERIALREAD - Serial.read() uses a 128 byte circular buffer, so handle
		 * all serialReads at once, i.e. empty the buffer */
		while(Firmata.available())
			Firmata.processInput();
		/* SEND FTDI WRITE BUFFER - make sure that the FTDI buffer doesn't go over
		 * 60 bytes. use a timer to sending an event character every 4 ms to
		 * trigger the buffer to dump. */

		/* ANALOGREAD - right after the event character, do all of the
		 * analogReads().  These only need to be done every 4ms. */
		for(analogPin=0;analogPin<TOTAL_ANALOG_PINS;analogPin++) {
			if( analogInputsToReport & (1 << analogPin) ) {
				Firmata.sendAnalog(analogPin, analogRead(analogPin));
			}
		}
	}

	if(currentMillis > arduinoponics_nextExecuteMillis) 
	{
		arduinoponics_nextExecuteMillis = currentMillis + 999; // run this every 1000ms
                
                /* //for dbugging
	   if(seconds >= 10)
	   {
	   run_pump(6000);
	   seconds=0;
	   }
	 */
	if(pump_on == true)
	{
		pump_time++;
	}

	if(seconds >= 60)
	{
		minutes++;
		seconds = 0;
	}


	if(pump_time == pump_run_seconds)
	{
		pump_control(false);
		pump_time = 0;
	}

	if(minutes >= pump_run_interval)
	{
		pump_control(true);
		minutes = 0;
	}
                
                led_blink();
		seconds++;
	}
}
