package com.company;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Main {

    public static void main(String[] args) {
	String s  = "abcd/2/asd/f John/n Frank/n punkt/. John/n DerKlaus/n";
	String[] words_with_token = s.split("\\s+");
	List<String> words = new ArrayList<String>();
	List<String> tags = new ArrayList<String>();
	Map<String, Map<String, Double>> emission_prob = new HashMap<String, Map<String, Double>>();
	Map<String, Double> start_prob = new HashMap<String,Double>();
	String tag;
	String word;
	for(String word_with_token: words_with_token){

		// Split word and token
		tag = word_with_token.substring(word_with_token.lastIndexOf('/')+1).trim();
		word = word_with_token.substring(0,word_with_token.lastIndexOf('/')).trim();

		// increase counts in emmision_probabilities for every word appearing
		Map<String, Double> word_emmision_prob_map = emission_prob.get(tag);
		//Check if the tag exists already in the map
		if(word_emmision_prob_map == null){
			Map<String, Double> tag_emmision_prob  = new HashMap<String, Double>();
			tag_emmision_prob.put(word, 1.0);
			emission_prob.put(tag, tag_emmision_prob);
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
	Double prob_first_word = start_prob.get(words.get(0));
	if(prob_first_word == null){
		start_prob.put(words.get(0), 1.0);
	}else
		start_prob.put(words.get(0), prob_first_word + 1 );


	System.out.println(Math.log());


	System.out.println(start_prob.size());
	System.out.println(emission_prob.get("n").get("John") / emission_prob.get("n").size());
	System.out.println(emission_prob.get("n").get("John"));
	System.out.println(tags.get(0));

    }
}
