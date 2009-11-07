int pump_pin =  9;
int led_pin = 11;
int second_pin = 12;

unsigned int seconds = 0;
unsigned int minutes = 0;
unsigned long last_tick = 0;
unsigned long gap = 0;

boolean second_led = false;

int pump_run_seconds = 4; //in seconds
int pump_run_interval = 10; //in minutes

boolean pump_on = false;
int pump_time = 0;

void setup()   
{                
  pinMode(pump_pin, OUTPUT);     
  pinMode(led_pin, OUTPUT);     
  pinMode(second_pin, OUTPUT);   
}

void loop()                     
{
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
  delay(1000);
  seconds++;
}

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
