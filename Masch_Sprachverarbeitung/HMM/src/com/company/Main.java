package com.company;

import java.io.*;
import java.util.ArrayList;

public class Main {

    public static void main(String[] args) throws IOException, ClassNotFoundException {
        String dir = "./corpus/brown_training";
        File directory = new File(dir);
        File[] files = directory.listFiles();
        HiddenMarkov hmm = new HiddenMarkov();

        // Train the model
        for(File file: files){
            if(file.isFile()){
                try{
                    BufferedReader reader = new BufferedReader(new FileReader(file));
                    String sentence;
                    while((sentence=reader.readLine()) != null){
                        if(sentence.length() > 1){
                            hmm.train(sentence);
                        }
                    }
                } catch (FileNotFoundException e) {
                    e.printStackTrace();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        // Now that the words are counted, the relative log-likelihood-values have to be calculated
        hmm.convert_probabilities();
        // Save the model
        hmm.save();

        // Read object
        FileInputStream fin = new FileInputStream("./Markov.hmm");
        ObjectInputStream ois = new ObjectInputStream(fin);
        HiddenMarkov hmm2 = (HiddenMarkov) ois.readObject();

        File input_dir = new File("./corpus/test");
        File output_dir = new File("./corpus/output");
        File[] test_files = input_dir.listFiles();
        for(File file: test_files){
            if(file.isFile()){
                try{
                    BufferedReader reader = new BufferedReader(new FileReader(file));
                    BufferedWriter writer = new BufferedWriter(new FileWriter(output_dir + "/" + file.getName(), true));
                    String sentence;
                    while((sentence=reader.readLine()) != null){
                        if(sentence.length() > 1){
                            sentence = hmm2.annotate(sentence);
                            //Save file to output_dir/input-file-name
                            writer.write(sentence);
                        }
                    }
                    writer.flush();
                    writer.close();
                } catch (FileNotFoundException e) {
                    e.printStackTrace();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        ArrayList<String> words = new ArrayList<String>();
        String s = "a b c d e f";
        String[] tokens = s.trim().split("\\s+");
        for(String token: tokens){
            words.add(token);
        }
        System.out.println();
        // Next up: annotate
        /*
        1. Read object from file
        2. Get test file
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
         4. Save annotated text to output_dir/input_file_name
         */

    }
}
