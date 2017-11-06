package com.company;


import java.security.KeyStore;
import java.util.*;

public class WordCounter
{
    private Map<String, MutableInt> dictionary;

    public WordCounter(){
        this.dictionary = new HashMap<String, MutableInt>();
    }

    private String[] sanitize(String input){
        input = input.toLowerCase();
        String [] sanitizedString = input.split(" ");
        return sanitizedString;
    }

    public void count(String input){
        String[] words = sanitize(input);
        for(String word : words){
            if(!word.isEmpty()){
                MutableInt count = this.dictionary.get(word);
                if (count == null){
                    this.dictionary.put(word, new MutableInt());
                } else {
                    count.increment();
                    this.dictionary.put(word, count);
                }
            }
        }
    }

    public int getTotalNumberofWords(){
        int result = 0;
        for (MutableInt i : this.dictionary.values()){
            result += i.value;
        }
        return result;
    }

    public int getDistinctNumberofWords() {
        return this.dictionary.size();
    }
    public void getMostCommonWords(){
        List<Map.Entry<String, MutableInt>> list = new LinkedList<Map.Entry<String , MutableInt>>(this.dictionary.entrySet());
        Collections.sort(list, new Comparator<Map.Entry<String, MutableInt>>() {
            @Override
            public int compare(Map.Entry<String, MutableInt> o1, Map.Entry<String, MutableInt> o2) {
                return o2.getValue().compareTo(o1.getValue());
            }
        });

        for(Map.Entry<String, MutableInt> item: list.subList(0,29)){
            System.out.println(item.getKey()+ " ----- " + this.dictionary.get(item.getKey()).getValue());
        }
    }

    public void countRaw(String word) {
        if(!word.isEmpty()){
            MutableInt count = this.dictionary.get(word);
            if (count == null){
                this.dictionary.put(word, new MutableInt());
            } else {
                count.increment();
                this.dictionary.put(word, count);
            }
        }
    }
}
