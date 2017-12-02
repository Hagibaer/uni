package com.company;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import java.io.File;
import java.io.FilenameFilter;
import java.security.KeyStore;
import java.util.*;

public class Main {

    public static void main(String[] args) {
        long startTime = System.nanoTime();
        try{
            File directory = new File(args[0]);

            FilenameFilter xmlFilter = (dir, name) -> {
                String lowercaseName = name.toLowerCase();
                if(lowercaseName.endsWith(".xml")){
                    return true;
                } else {
                    return false;
                }
            };

            File[] xmlFiles = directory.listFiles(xmlFilter);
            SAXParserFactory factory = SAXParserFactory.newInstance();
            SAXParser parser = factory.newSAXParser();
            ReuterHandler reuterHandler = new ReuterHandler();


            for(File file: xmlFiles){
                parser.parse(file, reuterHandler);
            }
            int numArticles = reuterHandler.getNumArticles();
            int[] titleAndBody = reuterHandler.getTotalAndDistinct("title");
            int[] topics = reuterHandler.getTotalAndDistinct("topic");
            int[] places = reuterHandler.getTotalAndDistinct("place");
            int[] people = reuterHandler.getTotalAndDistinct("people");
            System.out.println("Total number of documents: " + numArticles);
            System.out.println("Total number of words " + titleAndBody[0] + "( " + titleAndBody[1] + " distinct)" );
            System.out.println("Total number of topics " + topics[0] + "( " + topics[1] + " distinct)" );
            System.out.println("Total number of places " + places[0] + "( " + places[1] + " distinct)" );
            System.out.println("Total number of people " + people[0] + "( " + people[1] + " distinct)" );

            // Assuming most common words and their count is only done within title & body
            System.out.println("Most common words: ");
            reuterHandler.getMostCommonWords();
        }catch (Exception e){
            e.printStackTrace();
        }
        long endTime = System.nanoTime();

        System.out.println("Total Time: "+ ((endTime-startTime)/1000000));
    }
}
