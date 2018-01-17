#! /usr/bin/python3
import sys
import string
import ssl
import math
from typing import List

import pickle

import nltk
from nltk.stem.snowball import *
from nltk.metrics import edit_distance
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize


class Token:
    def __init__(self, value, tag) -> object:
        self.value = value
        self.tag = tag


class NERTagger:
    __tag_no_entity = "O"

    def __init__(self, *args):
        if len(args) == 3:
            self.dictionary = args[0]
            self.stopwords_list = args[1]
            self.punctuation = args[2]
        else:
            self.__load_dictionaries()

    def save_dictionaries(self):
        pickle.dump(self.dictionary, open("dictionary.p", "wb"))
        pickle.dump(self.stopwords_list, open("stopwords_list.p", "wb"))
        pickle.dump(self.punctuation, open("punctuation.p", "wb"))

    def __load_dictionaries(self):
        self.dictionary = pickle.load(open("dictionary.p", "rb"))
        self.stopwords_list = pickle.load(open("stopwords_list.p", "rb"))
        self.punctuation = pickle.load(open("punctuation.p", "rb"))

    def tag_tokens(self, words: List[Token]):
        tagged_words = []
        for word in words:
            if word.value in self.stopwords_list or word.value in self.punctuation:
                tagged_words.append(Token(word.value, self.__tag_no_entity))
            else:
               rules_checked =  self.__check_rules(word.value, tagged_words)
        return tagged_words

    def __check_rules(self, word, tagged_words):
        keys = list(self.dictionary.keys())

        if word in self.dictionary:
            tagged_words.append(Token(word, self.dictionary[word]))
            return True
        elif self.__check_distance(word, tagged_words, keys):
            return True
        # elif self.__check_word_stems(word, tagged_words, keys):
        #     return True

        # elif for further rules

        else:
            tagged_words.append(Token(word, self.__tag_no_entity))
            return True

    def __check_distance(self, word, tagged_words, keys):
        # calculate edit-distances
        distances = list(map(lambda x: edit_distance(word, x), keys))

        # get index where distance is minimal - conflict resolution happens here as we just pick first index_min
        index_min = min(range(len(distances)), key=distances.__getitem__)

        if distances[index_min] < round(math.floor(len(word)) * 0.9):
            tagged_words.append(Token(word, self.dictionary[keys[index_min]]))
            return True

        return False

    def __check_word_stems(self, word, tagged_words, keys):
        stemmer = SnowballStemmer("english")
        stemmed_word = stemmer.stem(word)
        stemmed_keys = list(map(lambda x: stemmer.stem(x), keys)) # mb cache that?

        if stemmed_word in stemmed_keys:
            idx = stemmed_keys.index(stemmed_word)
            tagged_words.append(Token(word, self.dictionary[keys[idx]]))
            return True

        return False


def main():
    if len(sys.argv) < 2:
        nltk.download()
        input_file = "./../data/uebung4-training.iob"
        train_tagger(input_file)
        print('---- Training for NER-Tagger is finished ----')
    elif len(sys.argv) == 3:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        tag_tokens(input_file, output_file)
        print('---- NER-Tagger finished, see result in output file ----')
    else:
        print(sys.argv[1].lower())
        print('Oops, something went wrong, please check if you called the script correctly :)')


def train_tagger(input_file):
    gold_std = build_dict_from_input_file(input_file)
    additional_dictionary = build_additional_dict()
    dictionary = concatenate_dicts(gold_std, additional_dictionary)
    stopwords_list = build_stopwords()
    punctuation = set(string.punctuation)
    tagger = NERTagger(dictionary, stopwords_list, punctuation)
    tagger.save_dictionaries()


def tag_tokens(input_file, output_file):
    tokens = read_tokens_from_input_file(input_file)
    tagger = NERTagger()
    tagged_list = tagger.tag_tokens(tokens)
    write_annotations_to_file(tagged_list, output_file)


def build_dict_from_input_file(path):
    entities_from_file = {}
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_from_input_file(f.readlines()):
            if token.tag != "O":
                entities_from_file[token.value] = token.tag
    return entities_from_file


def build_additional_dict():
    entities_from_file = {}
    path = "./../data/dictionary/human-genenames.txt"
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_from_list(f.readlines()):
            entities_from_file[token] = "B-protein"
    return entities_from_file


def concatenate_dicts(gold_std, additional_dict):
    return dict(list(gold_std.items()) + list(additional_dict.items()))


def build_stopwords():
    nltk.download('stopwords')
    stopwords_list = []
    path = "./../data/dictionary/english_stop_words.txt"
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_from_list(f.readlines()):
            stopwords_list.append(token)
    return set(stopwords_list).union(set(stopwords.words('english')))


def read_tokens_from_input_file(path):
    tokens = []
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_from_input_file(f.readlines()):
            tokens.append(token)
    return tokens


def write_annotations_to_file(annotations: List[Token], output_file):
    my_file = open(output_file, 'w')
    for token in annotations:
        my_file.write("{} {}\n".format(token.value, token.tag))
    my_file.close()


def get_tokens_from_list(lines):
    tokens = []
    for line in lines:
        if len(line) > 0:
            found_tokens = word_tokenize(line)
            if len(found_tokens) == 1:
                tokens.append(found_tokens[0])
    return tokens


def get_tokens_from_input_file(lines):
    tokens = []
    for line in lines:
        if len(line) > 0:
            found_tokens = word_tokenize(line)
            if len(found_tokens) == 2:
                tokens.append(Token(found_tokens[0], found_tokens[1]))
    return tokens


if __name__ == '__main__':
    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context
    main()
