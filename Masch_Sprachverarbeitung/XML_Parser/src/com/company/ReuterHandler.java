package com.company;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import java.io.UnsupportedEncodingException;

public class ReuterHandler extends DefaultHandler{
    private int numArticles = 0;
    private String text = "";
    private boolean title = false;
    private boolean body = false;
    private boolean people = false;
    private boolean topic = false;
    private boolean places = false;
    private WordCounter titleBodyCounter;
    private WordCounter TopicsCounter;
    private WordCounter PlacesCounter;
    private WordCounter PeopleCounter;


    public ReuterHandler() {
        super();
        this.titleBodyCounter = new WordCounter();
        this.TopicsCounter = new WordCounter();
        this.PlacesCounter = new WordCounter();
        this.PeopleCounter = new WordCounter();
    }

    @Override
    public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
        if(qName.equalsIgnoreCase("reuters")){
            this.numArticles += 1;
        }
        if(qName.equalsIgnoreCase("title")){
            title = true;
        }
        if(qName.equalsIgnoreCase("body")){
            body = true;
        }
        if(qName.equalsIgnoreCase("topics")){
            topic = true;
        }
        if(qName.equalsIgnoreCase("places")){
            places = true;
        }
        if(qName.equalsIgnoreCase("people")){
            people = true;
        }
    }

    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
        if(qName.equalsIgnoreCase("title")){
            this.titleBodyCounter.count(this.text);
            title = false;
            text = "";
        }
        if(qName.equalsIgnoreCase("body")){
            this.titleBodyCounter.count(this.text);
            body = false;
            text = "";
        }
        if(qName.equalsIgnoreCase("topics")){
            topic = false;
        }
        if(qName.equalsIgnoreCase("places")){
            places = false;
        }
        if(qName.equalsIgnoreCase("people")){
            people = false;
        }
    }

    @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
        if(title){
            this.text += new String(ch, start, length);
        }
        if(body){
            this.text += new String(ch, start, length);
        }
        if(topic){
            this.TopicsCounter.count(new String(ch, start, length));
        }
        if(places){
            this.PlacesCounter.count(new String(ch, start, length));
        }
        if(people){
            this.PeopleCounter.count(new String(ch, start, length));
        }
    }

    public int getNumArticles(){
        return this.numArticles;
    }

    public int[] getTotalAndDistinct(String category){
        int [] result = new int[2];
        int totalNumberofWords = 0;
        int distinctNumberofWords = 0;
        switch (category){
            case "title":
                totalNumberofWords = titleBodyCounter.getTotalNumberofWords();
                distinctNumberofWords = titleBodyCounter.getDistinctNumberofWords();
                result[0] = totalNumberofWords;
                result[1] = distinctNumberofWords;
                return result;
            case "topic":
                totalNumberofWords = TopicsCounter.getTotalNumberofWords();
                distinctNumberofWords = TopicsCounter.getDistinctNumberofWords();
                result[0] = totalNumberofWords;
                result[1] = distinctNumberofWords;
                return result;
            case "place":
                totalNumberofWords = PlacesCounter.getTotalNumberofWords();
                distinctNumberofWords = PlacesCounter.getDistinctNumberofWords();
                result[0] = totalNumberofWords;
                result[1] = distinctNumberofWords;
                return result;
            case "people":
                totalNumberofWords = PeopleCounter.getTotalNumberofWords();
                distinctNumberofWords = PeopleCounter.getDistinctNumberofWords();
                result[0] = totalNumberofWords;
                result[1] = distinctNumberofWords;
                return result;
        }
        return result;
    }

    public void getMostCommonWords() {
        titleBodyCounter.getMostCommonWords();
    }
}
