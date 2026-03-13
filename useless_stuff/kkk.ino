
cnst int sensoPin = 2;
int totalCount = 0 ;
bool personDetected = false;


void setup() {
    pinMode(sensorPin,INPUT);
    Serial.begin(9600);
    Serial.println("NITKRacing Counter Active!");
    Serial.println("Total People: 0");

}

Void loop(){
    int beamStatus = digitalRead(sensorPin);

    if (beamStatus == LOW && !personDetected) {
        totalCount ++;
        personDetected = true;
        Serial.print("Total Count: ");
        Serial.println(totalCount);

        delay(500);

    }

    if (beamStatus == HIGH) {
        personDetected = false;
    }
}