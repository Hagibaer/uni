package com.company;

import java.io.*;
import java.util.*;

public class HiddenMarkov implements Serializable {
    private Map<String, Map<String, Double>> emission_prob;
    private Map<String, Map<String, Double>> transition_prob;
    private Map<String, Double> start_prob;

    public HiddenMarkov(){
        this.start_prob = new HashMap<String, Double>();
        this.transition_prob = new HashMap<String, Map<String, Double>>();
        this.emission_prob = new HashMap<String, Map<String, Double>>();
    }
    public void train(String sentence){
        String[] words_with_token = sentence.trim().split("\\s+");
        List<String> words = new ArrayList<String>();
        List<String> tags = new ArrayList<String>();
        String tag;
        String word;

        // Go through the sentence and split the tokens
        for(String word_with_token: words_with_token){
            // Split word and token
            tag = word_with_token.substring(word_with_token.lastIndexOf('/')+1).trim();
            word = word_with_token.substring(0,word_with_token.lastIndexOf('/'));

            // increase counts in emmision_probabilities for every word appearing
            Map<String, Double> word_emmision_prob_map = this.emission_prob.get(tag);
            if(word_emmision_prob_map == null){
                Map<String, Double> tag_emission_prob  = new HashMap<String, Double>();
                tag_emission_prob.put(word, 1.0);
                this.emission_prob.put(tag, tag_emission_prob);
            }else{
                // Check if the word exists for the tag
                if(word_emmision_prob_map.get(word) == null){
                    word_emmision_prob_map.put(word, 1.0);
                }else{
                    word_emmision_prob_map.put(word, word_emmision_prob_map.get(word) + 1);
                }
            }
            words.add(word);
            tags.add(tag);
        }

        // increase start_prob for the first word in the words ArrayList
        Double prob_first_word = this.start_prob.get(words.get(0));
        if(prob_first_word == null){
            this.start_prob.put(words.get(0), 1.0);
        }else
            this.start_prob.put(words.get(0), prob_first_word + 1 );

        // Create all the transition probabilities
        for(int i = 0; i < tags.size()-1; i++){
            String tag1 = tags.get(i);
            String tag2 = tags.get(i+1);

            Map<String, Double> tag_transition_prob_map = this.transition_prob.get(tag1);
            if(tag_transition_prob_map == null){
                Map<String, Double> tag_to_tag_prob = new HashMap<String, Double>();
                tag_to_tag_prob.put(tag2, 1.0);
                this.transition_prob.put(tag1, tag_to_tag_prob);
            }else{
                // Check if  tag2 exists already as follow-up to tag1
                if(tag_transition_prob_map.get(tag2) == null){
                    tag_transition_prob_map.put(tag2, 1.0);
                }else{
                    tag_transition_prob_map.put(tag2, tag_transition_prob_map.get(tag2) + 1);
                }
            }
        }
    }
    public void convert_probabilities(){
        convert_String_Double_Map_probs(this.start_prob);
        convert_nested_map_probs(this.transition_prob);
        convert_nested_map_probs(this.emission_prob);
    }

    private void convert_nested_map_probs(Map<String, Map<String, Double>> map) {
        for( String key: map.keySet()){
            Map<String, Double> inner_map = map.get(key);
            convert_String_Double_Map_probs(inner_map);
        }
    }

    private void convert_String_Double_Map_probs(Map<String, Double> map) {
        Double total = map.values().stream().mapToDouble(Double::doubleValue).sum();
        for(String word : map.keySet()){
            map.put(word, Math.log(map.get(word)/total));
        }
    }

    public Map<String, Map<String, Double>> get_Emmision_prob() {
        return emission_prob;
    }

    public Map<String, Map<String, Double>> get_Transition_prob() {
        return transition_prob;
    }

    public Map<String, Double> get_Start_prob() {
        return start_prob;
    }

    public void save() throws IOException {
        FileOutputStream fout = new FileOutputStream("./Markov.hmm");
        ObjectOutputStream oos = new ObjectOutputStream(fout);
        oos.writeObject(this);
    }
}
