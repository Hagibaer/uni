package hu.pda.ep;

import javax.jms.*;

import org.apache.activemq.ActiveMQConnectionFactory;

public class TemperatureEventConsumer implements Runnable{

    @Override
    public void run() {
        ActiveMQConnectionFactory factory =  new ActiveMQConnectionFactory("vm://localhost");
        try {
            Connection connection = factory.createConnection();
            connection.start();

            Session session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);

            // Listen to Temperature-Topic
            Topic temp_topic = session.createTopic("Temperature");
            MessageConsumer consumer = session.createConsumer(temp_topic);
            try {
                while (true) {
                    Message msg = consumer.receive();
                    if (msg instanceof MapMessage){
                        MapMessage message = (MapMessage) msg;
                        //System.out.println("Received a Temperature Event");
                    } else {
                        //System.out.println("Oh boy");
                    }
                }
            } finally {
                // clean up
                consumer.close();
                session.close();
                connection.close();
            }

        } catch (JMSException e) {
            e.printStackTrace();
        }
    }
}
