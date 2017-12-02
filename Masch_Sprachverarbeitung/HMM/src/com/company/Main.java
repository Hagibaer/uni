package com.company;

import java.io.*;

public class Main {

    public static void main(String[] args) throws IOException {
        String dir = "./corpus/brown_training";
        File directory = new File(dir);
        File[] files = directory.listFiles();
        HiddenMarkov hmm = new HiddenMarkov();
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
                } finally{

                }
            }
        }
        // Now that the words are counted, the relative log-likelihood-values have to be calculated
        hmm.convert_probabilities();
        // Save the model
        hmm.save();

        // Next up: annotate


    }
}
