import sys
import string
import ssl

import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize


class NERTagger:
    def __init__(self, entities, stopwords_list):
        nltk.download('stopwords')
        self.entities = concatenate_dict(entities)
        self.punctuation = set(string.punctuation)
        self.stopwords_list = set(stopwords_list).union(set(stopwords.words('english')))
        self.tag_no_entity = "O"

    def tag_words(self, words):
        tagged_words = []
        for word in words:
            if word[0] in self.stopwords_list or word[0] in self.punctuation:
                tagged_words.append((word[0], self.tag_no_entity))
            elif word[0] in self.entities:
                tagged_words.append((word[0], word[1]))
            else:
                tagged_words.append((word[0], self.tag_no_entity))
        return tagged_words


def main():
    if len(sys.argv) < 2:
        input_file = "./../data/uebung4-training.iob"
        output_file = "./../output/uebung4-training.iob"
        tagging(input_file, output_file)
        print('---- NER-Tagger finished, see result in output file ----')

        # print('Please specifiy the input and output file you want to use')
    elif len(sys.argv) == 2:
        input_file = sys.argv[2]
        output_file = sys.argv[3]
        print('---- NER-Tagger finished, see result in output file ----')
    else:
        print(sys.argv[1].lower())
        print('Oops, something went wrong, please check if you called the script correctly :)')


def tagging(input_file, output_file):
    tagger, words = prepare_data(input_file)
    tagged_list = tagger.tag_words(words)

    my_file = open(output_file, 'w')

    for item in tagged_list:
        my_file.write("{} \t {}\n".format(item[0], item[1]))
    my_file.close()


def prepare_data(input_file):
    words, genes = build_dict_from_file(input_file)
    stopwords_list = build_stopwords()
    print("Words: "+str(len(words)))
    print("Genes: "+str(len(genes)))
    print("Stopwords: "+str(len(stopwords_list)))
    tagger = NERTagger(genes, stopwords_list)
    return tagger, words


def concatenate_dict(known_entities):
    entities_from_file = {}
    path = "./../data/dictionary/human-genenames.txt"
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_for_dict_from_list(f.readlines()):
            entities_from_file[token] = "B-protein"
    return dict(list(known_entities.items()) + list(entities_from_file.items()))


def build_stopwords():
    # Empty dict
    stopwords_list = []
    path = "./../data/dictionary/english_stop_words.txt"
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_for_dict_from_list(f.readlines()):
            stopwords_list.append(token)
    return stopwords_list


def build_dict_from_file(path):
    words = []
    # Empty dict
    genes = {}
    with open(path, "r", encoding='latin-1') as f:
        for token in get_tokens_for_dict(f.readlines()):
            words.append((token[0], token[1]))
            if token[1] != "O":
                genes[token[0]] = token[1]
    return words, genes


def get_tokens_for_dict_from_list(lines):
    for line in lines:
        if len(line) > 0:
            tokens = word_tokenize(line)
            if len(tokens) == 1:
                yield tokens[0]


def get_tokens_for_dict(lines):
    for line in lines:
        if len(line) > 0:
            tokens = nltk.word_tokenize(line)
            if len(tokens) == 2:
                yield (tokens[0], tokens[1])


if __name__ == '__main__':
    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context
    main()
