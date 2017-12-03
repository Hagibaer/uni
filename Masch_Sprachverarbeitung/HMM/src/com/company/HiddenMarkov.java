package com.company;

import javafx.util.Pair;

import java.io.*;
import java.util.*;

public class HiddenMarkov implements Serializable {
    private Map<String, Map<String, Double>> emission_prob;
    private Map<String, Map<String, Double>> transition_prob;
    private Map<String, Map<String, Double>> viterbi_prob;
    private Map<String, Map<String, String>> viterbi_ways;
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
        Double prob_first_tag = this.start_prob.get(tags.get(0));
        if(prob_first_tag == null){
            this.start_prob.put(tags.get(0), 1.0);
        }else
            this.start_prob.put(tags.get(0), prob_first_tag + 1 );

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
        convert_String_Double_Map_probs(this.start_prob, false);
        convert_nested_map_probs(this.transition_prob, false); // Maybe smooth as well?
        convert_nested_map_probs(this.emission_prob, true);
    }

    private void convert_nested_map_probs(Map<String, Map<String, Double>> map, boolean smooth) {
        for( String key: map.keySet()){
            Map<String, Double> inner_map = map.get(key);
            convert_String_Double_Map_probs(inner_map, smooth);
        }
    }

    private void convert_String_Double_Map_probs(Map<String, Double> map, boolean smooth) {
        Double total = map.values().stream().mapToDouble(Double::doubleValue).sum(); // = N in lindstone

        if(smooth){
            Double B = map.keySet().size() * 1.0;
            Double lambda = 0.5; // Fix for now, maybe allow as function parameter later
            for(String word : map.keySet()){
                map.put(word, Math.log(map.get(word)/total));
            }
            Double smoothedProb = lambda / (total + lambda * B);
            map.put("unknown", Math.log(smoothedProb));
        } else {
            for(String word : map.keySet()){
                map.put(word, Math.log(map.get(word)/total));
            }
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
        oos.close();
        fout.close();
    }

    public String annotate(String sentence) {
        /*
         3. For every sentence: hmm.annotate
            - split into word and tag (= NA)
            - calculate the probabilities of all states for this word via viterbi v(s+1) = Emission(v(s+1) + max(v(s) + trans(v(s), ...)
              - if emission == 0 --> emission = assign unknown probability
            (because we already have made all the probabilites logs the formula is correct)
            - Remember precessor (Which tag - transition was the highest?)
            - Repeat for every word until the end of the sentence
            - If the sentence is done:
            - Get max probability in the last column --> Get this state and precessor (save state to list)
                - get precessors state and precessor ... until precessor = null
            - loop through the state list from back to front, assign tag[i] to word[i]
         */
        this.viterbi_prob= new HashMap<String, Map<String, Double>>();
        this.viterbi_ways = new HashMap<String, Map<String, String>>();

        String[] words_with_token = sentence.trim().split("\\s+");
        ArrayList<String> words = new ArrayList<String>();
        String word;
        boolean first_row = true;


        for (String word_with_token : words_with_token){
            word = word_with_token.substring(0,word_with_token.lastIndexOf('/'));
            words.add(word);

            // Calculate first column - loop over trans-key Set because we can assume that it has all the tags in it
            if(first_row){
                for(String tag : this.emission_prob.keySet()){
                    Double prob = 0.0;
                    if(this.start_prob.get(tag) == null && this.emission_prob.get(tag).get(word) == null){
                        prob = 0 + this.emission_prob.get(tag).get("unknown");
                    }else if(this.start_prob.get(tag) == null){
                        prob = 0 + this.emission_prob.get(tag).get(word);
                    }else if(this.emission_prob.get(tag).get(word) == null){
                        prob = this.start_prob.get(tag) + this.emission_prob.get(tag).get("unknown");
                    }else{
                        prob = this.start_prob.get(tag) + this.emission_prob.get(tag).get(word);
                    }

                    Map<String, Double> prob_map = new HashMap<String, Double>();
                    prob_map.put(tag, prob);
                    // Save probabilities
                    this.viterbi_prob.put(word, prob_map);

                    // Save precessor
                    Map<String, String> precessor = new HashMap<String, String>();
                    precessor.put(word, "end");
                    this.viterbi_ways.put(tag, precessor);
                }
                first_row = false;
            }else{
                // Calculate other columns
                for(String tag1 : this.emission_prob.keySet()){
                    ArrayList<Double> routesToCurrentState = new ArrayList<Double>();
                    Map<String, Double> innerMap = viterbi_prob.get(words.get(words.size()-2));
                    for(String tag2 : innerMap.keySet()){
                        if(this.transition_prob.get(tag2).get(tag1) != null){
                            routesToCurrentState.add(innerMap.get(tag2) + this.transition_prob.get(tag2).get(tag1));
                        }
                    }
                    System.out.println(routesToCurrentState);
                    Double max_value = Collections.max(routesToCurrentState);
                    if(this.emission_prob.get(tag1).get(word) == null){
                        Double prob = this.emission_prob.get(tag1).get("unknown") + max_value;
                    }
                    Double prob = this.emission_prob.get(tag1).get(word) + max_value;
                }
            }
        }
        sentence = "ABCD ".trim() + "\n";
        return sentence;
    }
    private Double maxValue(Double first, Double... rest){
        Double ret = first;
        for(Double value: rest){
            ret = Math.max(ret, value);
        }
        return ret;
    }
}
