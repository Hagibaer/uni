package hu.pda.ep;

import javax.jms.Connection;
import javax.jms.DeliveryMode;
import javax.jms.Destination;
import javax.jms.MapMessage;
import javax.jms.MessageProducer;
import javax.jms.Session;

import org.apache.activemq.ActiveMQConnectionFactory;

public class TemperatureEventProducer implements Runnable {
    
	int id;
	int[] values;
	
	public TemperatureEventProducer(int id, int[] values ) {
		this.id = id;
		this.values = values;
	}
	
	public void run() {
		try {
		
            // Create a ConnectionFactory
            ActiveMQConnectionFactory connectionFactory = new ActiveMQConnectionFactory("vm://localhost");

            // Create a Connection
            Connection connection = connectionFactory.createConnection();
            connection.start();

            // Create a Session
            Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);

            // Create the destination
			// Destination destination = session.createQueue("SENSORS"); old implementation with queues
			Destination destination = session.createTopic("Temperature");

            // Create a MessageProducer from the Session to the Topic or Queue
            MessageProducer producer = session.createProducer(destination);
            producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);

            for (int i = 0; i < values.length; i++) {
	            // Create a messages
	            MapMessage message = session.createMapMessage();
	            message.setLong("timestamp", System.nanoTime());
	            message.setInt("sensor", id);
	            message.setString("type", "temperature");
	            message.setInt("value", values[i]);
	            producer.send(message);
	            Thread.sleep(100);
	        }
			
            // Clean up
            session.close();
            connection.close();
		}
        catch (Exception e) {
            System.out.println("Caught: " + e);
            e.printStackTrace();
		}
	}

}
