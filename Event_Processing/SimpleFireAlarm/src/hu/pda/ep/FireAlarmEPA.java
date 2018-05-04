package hu.pda.ep;

import java.util.ArrayList;

import javax.jms.Connection;
import javax.jms.DeliveryMode;
import javax.jms.Destination;
import javax.jms.MapMessage;
import javax.jms.Message;
import javax.jms.MessageConsumer;
import javax.jms.MessageProducer;
import javax.jms.Session;

import org.apache.activemq.ActiveMQConnectionFactory;

public class FireAlarmEPA implements Runnable {
	
	@Override
	public void run() {
		// Variable definition
		ArrayList<Integer> temp_window = new ArrayList<Integer>();
		boolean smoke_detected = false;
		boolean alarm_detected = false;

		// Connection Factory
		ActiveMQConnectionFactory factory  = new ActiveMQConnectionFactory("vm://localhost");

		try {
			// Connection
			Connection connection = factory.createConnection();
			connection.start();
			// Session
			Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
			
			// Create two queues Sensor & Alarm
			Destination sensor_destination = session.createQueue("SENSORS");
			Destination alarm_destination = session.createQueue("ALARMS");
			// Create Topic sub for Temperature
			Destination temperature_destination = session.createTopic("Temperature");
			
			// Message Consumer from 'SENSOR'
			 MessageConsumer sensor_consumer = session.createConsumer(sensor_destination);
			 MessageConsumer temperature_consumer = session.createConsumer(temperature_destination);

			// Message Producer to 'ALARMS'
			 MessageProducer alarm_producer = session.createProducer(alarm_destination);
			 alarm_producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);
			 
			 try {
				 while (true) {
					 // Listen to the SENSOR events
					 Message message = sensor_consumer.receive();
					 Message temp_message = temperature_consumer.receive();

					 if (message instanceof MapMessage){
					 	MapMessage m = (MapMessage) message;
						 if (m.getString("type").equals("smoke")) {
							 if(m.getBoolean("value")) {
								 smoke_detected = true;
							 }
						 }
					 }

					 if(smoke_detected && temp_message instanceof  MapMessage){
					 	MapMessage m_temp = (MapMessage) temp_message;
					    temp_window.add(m_temp.getInt("value"));
					     if(temp_window.size() == 5) {
						     for (int value : temp_window) {
							     if(value > 50) {
								     alarm_detected = true;
							     }
						     }
						     temp_window.clear();
					     }
					     if (alarm_detected) {
						     smoke_detected = false;
						     // publish alarm event
						     MapMessage alarm_msg = session.createMapMessage();
						     alarm_msg.setLong("timestamp", System.nanoTime());
						     alarm_msg.setString("type", "ALARM!!! Better hurry up boi!");
						     alarm_producer.send(alarm_msg);
						     //Thread.sleep(50);
					     }
					 }
					 
				 }
				 
			 } finally {
				 // Clean up
				 sensor_consumer.close();
				 alarm_producer.close();
				 session.close();
				 connection.close();	 
			 }
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
