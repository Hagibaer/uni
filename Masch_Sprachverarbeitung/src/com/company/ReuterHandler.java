package com.company;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

public class ReuterHandler extends DefaultHandler{
    private int numArticles = 0;
    private boolean title = false;
    private boolean body = false;
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
        if(qName.equalsIgnoreCase("title") || qName.equalsIgnoreCase("body")){
            title = true;
            body = true;
        }
        if(qName.equalsIgnoreCase("topics")){
            topic = true;
        }
        if(qName.equalsIgnoreCase("places")){
            places = true;
        }
    }

    @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
        if(title || body){
            this.titleBodyCounter.count(new String(ch, start, length));
            title = false;
            body = false;
        }
        if(topic){
            this.TopicsCounter.countRaw(new String(ch, start, length));
            topic = false;
        }
        if(places){
            this.PlacesCounter.countRaw(new String(ch, start, length));
            places = false;
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
