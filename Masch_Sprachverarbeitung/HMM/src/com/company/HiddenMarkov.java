package com.company;

import javafx.util.Pair;

import java.io.*;
import java.util.*;

public class HiddenMarkov implements Serializable {
    private Map<String, Map<String, Double>> emission_prob;
    private Map<String, Map<String, Double>> transition_prob;
    private Map<String, Map <Integer, Double>> viterbi_prob;
    private Map<String, Map<Integer, String>> backpointer;
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
        // Initialize viterbi table, backlog & first_row boolean
        this.viterbi_prob = new HashMap<String, Map<Integer, Double>>();
        this.backpointer = new HashMap<String, Map<Integer, String>>();
        boolean first_row = true;

        String[] words_with_token = sentence.trim().split("\\s+");
        ArrayList<String> words = new ArrayList<String>();
        String word;

        // Loop over the complete sentence and fill the tables column-wise
        for(String word_with_token : words_with_token){
            word = word_with_token.substring(0,word_with_token.lastIndexOf('/'));
            words.add(word);

            // Loop over emmission-keyset == Brown-Tag-Set
            // Special for-loop for the first word, since it has no precessor.
            if(first_row){
                for(String tag: this.emission_prob.keySet()){
                    Double start_probability = this.start_prob.get(tag);
                    Double emission_probability = this.emission_prob.get(tag).get(word);

                    Double probability;
                    if(start_probability == null || emission_probability == null){
                        probability = 0 + this.emission_prob.get(tag).get("unknown");
                    }else{
                        probability = start_probability + emission_probability;
                    }

                    // Store probability for state s at position 1
                    Map<Integer, Double> inner_map = new HashMap<Integer, Double>();
                    inner_map.put(1, probability);
                    viterbi_prob.put(tag, inner_map);

                    // Store precessor in backlog for s at position 1
                    Map<Integer, String> inner_map_backlog = new HashMap<Integer, String>();
                    inner_map_backlog.put(1, "end");
                    this.backpointer.put(tag, inner_map_backlog);
                }
                first_row = false;
            }else{
                // Compute all the other columns that are not the first one

                int position = words.size(); // get current position

                // again loop over keyset == brown-set
                for(String tag: this.emission_prob.keySet()){
                    Double emission_probability = this.emission_prob.get(tag).get(word);
                    // Get max value and maxarg for the calculation
                    // I have to loop over the previous column.
                    // For every key_prev in the previous column, calculate: prob + trans_prob(key_prev, key_now)
                    // get the max value, and the argmax.
                    String max_state = "";
                    Double max_value = -9999999.9;

                    for(String key_prev : this.viterbi_prob.keySet()){
                        Double prev_prob = this.viterbi_prob.get(key_prev).get(position-1);
                        Double trans = this.transition_prob.get(key_prev).get(tag);
                        Double interim_prob;

                        if(prev_prob == null){
                            interim_prob = -9999999.0;
                        }else if(trans == null){
                            interim_prob = -9999999.0;
                        }else{
                            interim_prob = prev_prob + trans;
                        }
                        String state = key_prev;
                        if(interim_prob > max_value){
                            max_value = interim_prob;
                            max_state = state;
                        }
                    }

                    // Now calculate the value for this tag at our current position
                    Double probability;
                    if(emission_probability == null){
                        probability = this.emission_prob.get(tag).get("unknown") + max_value;
                    }else{
                        probability = emission_probability + max_value;
                    }

                    // And put it into the map for state s at position t
                    Map<Integer, Double> inner_map = new HashMap<Integer, Double>();
                    inner_map.put(position, probability);
                    viterbi_prob.put(tag, inner_map);

                    // Now save the precessor as well
                    Map<Integer, String> inner_map_backlog = new HashMap<Integer, String>();
                    inner_map_backlog.put(position, max_state);
                    this.backpointer.put(tag, inner_map_backlog);
                }
            }
        } // Tables are calculated

        // Get the last word and check which state has the highest probability
        String last_word = words.get(words.size()-1);
        Double maxValue = -999999.999;
        String state = "";
        for(String tag : this.viterbi_prob.keySet()){
            Double interim_value = this.viterbi_prob.get(tag).get(last_word);
            if(interim_value == null){
                interim_value = -999999.0;
            }
            String interim_tag = tag;
            if(interim_value > maxValue){
                maxValue = interim_value;
                state = interim_tag;
            }
        }
        // Now we got the last state and the position. Now we go through the backlog with that until we reach the end
        int position = words.size();
        ArrayList<String> result = new ArrayList<String>();
        String a = this.backpointer.get(state).get(position);


        while(this.backpointer.get(state).get(position).equals("end")){
            // add the state to the list
            result.add(state);

            // update state and position
            state = this.backpointer.get(state).get(position);
            position = position - 1;
        }

        System.out.println(result);



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
