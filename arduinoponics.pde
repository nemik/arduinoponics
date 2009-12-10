
/* timer variables */
unsigned long currentMillis;     // store the current value from millis()
unsigned long nextExecuteMillis; // for comparison with currentMillis

/*==============================================================================
 * ARDUINOPONICS-SPECIFIC GLOBAL VARIABLES
 *============================================================================*/

int pump_pin = 9;
int led_pin = 11;
int second_pin = 13;
int lights_pin = 12;

unsigned int seconds = 0;
unsigned int minutes = 0;
unsigned long arduinoponics_nextExecuteMillis; // for comparison with currentMillis

boolean second_led = false;

int pump_run_seconds = 4; //in seconds
int pump_run_interval = 10; //in minutes

boolean pump_on = false;
int pump_time = 0;

boolean lights_on = false;

int incomingByte = 0;	// for incoming serial data

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

void inline sendAnalogs()
{
  // read the analog input into a variable:
  int val0 = analogRead(0);
  int val1 = analogRead(1);
  int val2 = analogRead(2);
  int val3 = analogRead(3);
  int val4 = analogRead(4);
  int val5 = analogRead(5);
  
  //[0]0001|[1]10001|2:200|3:300|4:400|5:500
  
  Serial.print(val0);
  Serial.print("|");
  Serial.print(val1);
  Serial.print("|");
  Serial.print(val2);
  Serial.print("|");
  Serial.print(val3);
  Serial.print("|");
  Serial.print(val4);
  Serial.print("|");
  Serial.print(val5);
  Serial.print(13,BYTE);
  Serial.print(10,BYTE);
}

void inline toggleLights()
{
  if(lights_on)
  {
    lights_on = false;
  }
  else
  {
    lights_on = true;
  }
}

void inline checkSerial()
{
  if (Serial.available() > 0)
  {
    int incoming = Serial.read();
    
    if ((char)incoming == 'l')
    {
      toggleLights();
    }
  }
}

/*==============================================================================
 * SETUP()
 *============================================================================*/
void setup() 
{
	/* Arduinoponics-specific setup function */
	pinMode(pump_pin, OUTPUT);
	pinMode(led_pin, OUTPUT);
	pinMode(second_pin, OUTPUT);
        pinMode(lights_pin, OUTPUT);

        Serial.begin(9600);
        
        digitalWrite(lights_pin, HIGH);
}

/*==============================================================================
 * LOOP()
 *============================================================================*/
void loop() 
{
	
	currentMillis = millis();

	if(currentMillis > arduinoponics_nextExecuteMillis) 
	{
          arduinoponics_nextExecuteMillis = currentMillis + 999; // run this every 1000ms
                
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
          if(lights_on == true)
          {
            //fucking PNP....
            digitalWrite(lights_pin, LOW);
          }
          else if(lights_on == false)
          {
            digitalWrite(lights_pin, HIGH);
          }
                
          led_blink();
          seconds++;
          sendAnalogs();
          
          checkSerial();
	}
}
