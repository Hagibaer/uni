#! /usr/bin/python3
import sys
import pickle
import pandas as pd
import numpy as np
import nltk
import os
import re
from nltk.corpus import stopwords
import scipy.sparse as sp
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.model_selection import GridSearchCV
from sklearn.externals import joblib
from sklearn.base import TransformerMixin

class ItemSelector(TransformerMixin):
    def __init__(self, column):
        self.column = column

    def fit(self, X, y=None):
        return self

    def transform(self, X, y=None):
        return X[self.column]





def main():
    if len(sys.argv) < 2:
        print('Please specifiy the mode you want to use (train / classify)')
    if sys.argv[1].lower() == 'train' and len(sys.argv) == 5:
        model_name = sys.argv[2]
        ham_directory = sys.argv[3]
        spam_directory = sys.argv[4]
        train_model(model_name, ham_directory, spam_directory)
        print('---- Training sucessfull ----')
    elif sys.argv[1].lower() == 'classify':
        model_name = sys.argv[2]
        email_directory = sys.argv[3]
        result_file = sys.argv[4]
        classify_mails(model_name, email_directory, result_file)
        print('---- Prediction completed ----')
    else:
        print(sys.argv[1].lower())
        print('Oops, something went wrong, please check if you called the script correctly :)')

def train_model(model_name, ham_directory, spam_directory):
    nltk.download('stopwords')
    df_ham = make_df(ham_directory, 0)
    df_spam = make_df(spam_directory, 1)

    # Create Test and Training data
    df_final = pd.concat([df_ham, df_spam])
    df_final = df_final.sample(frac=1).reset_index(drop=True)

    X = df_final[['body', 'subject', 'sender']]
    y = df_final.label.values

        # body pipe
    body_pipe = make_pipeline(
        ItemSelector('body'),
        TfidfVectorizer(encoding='latin1', lowercase=False, ngram_range=(1,3))
    )

    # subject pipe
    subject_pipe = make_pipeline(
        ItemSelector('subject'),
        TfidfVectorizer(encoding='latin1', lowercase=False, ngram_range=(1,3))
    )

    # sender pipe
    sender_pipe = make_pipeline(
        ItemSelector('sender'),
        TfidfVectorizer(encoding='latin1', lowercase=False, ngram_range=(1,3))
    )

    feature_union = make_union(body_pipe, subject_pipe, sender_pipe)

    lr_tfidf = Pipeline([
        ('union', feature_union),
        ('clf', LogisticRegression(random_state=0))
    ])

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

    # Tune LR
    param_grid = [
        {
            'clf__penalty': ['l1', 'l2'],
            'clf__C': [0.1, 1.0, 10.0, 100.0]
        }
    ]

    gs_lr = GridSearchCV(
        lr_tfidf,
        param_grid,
        scoring='accuracy',
        cv=5,
        n_jobs=-1
    )

    gs_lr.fit(X_train, y_train)
    print('Parameter: {}'.format(gs_lr.best_params_))
    print('Accuracy (CV): {}'.format(gs_lr.best_score_))
    best_classifier = gs_lr.best_estimator_
    print('Accuracy (Test): {}'.format(best_classifier.score(X_test, y_test)))

    # Train on the complete corpus
    best_classifier.fit(X, y)

    # Save trained model
    joblib.dump(best_classifier, '{}.clf'.format(model_name))

def classify_mails(model_name, email_directory, result_file):
    df = make_df(email_directory, 2) # label gets dropped later anyway
    X = df[['body', 'subject', 'sender']]
    clf = joblib.load(model_name)
    y = clf.predict(X)
    my_list = y.tolist()
    my_list = ['SPAM' if elem == 1  else 'HAM' for elem in my_list]
    filenames = os.listdir(email_directory)
    my_file = open(result_file, 'w')

    for i, item in enumerate(my_list):
        my_file.write("{} \t {}\n".format(filenames[i],item))
    my_file.close()





def convert_files(directory):
    root = "./"
    # build directory path
    directory_path = os.path.join(root, directory)

    for mail in os.listdir(directory_path):
        file_path = directory_path + "/" + mail
        with open(file_path, "r", encoding='latin-1') as m:
            mail_dict = parse_message(m)
            yield mail_dict

def parse_message(msg):
    body = ''
    email = {}
    email['subject'] = ''
    in_body = False
    exclude_terms = ['URL:', 'Date:', 'Return-Path:']
    sw = stopwords.words("english")

    for line in msg:
        if line == '\n':
            in_body = True
            continue

        if any(term in line for term in exclude_terms):
            continue

        #get rid of html markup
        line = re.sub('<[^>]*>', '', line)

        #get rid of stopwords
        line = ' '.join([word for word in line.split() if word.lower() not in sw])

        if in_body:
            body += line.strip()
            email['body'] = body
        elif line.startswith('From:'):
            sender = line.strip()
            sender = sender.replace('"', '')
            sender = line[5:]
            email['sender'] = sender
        elif line.startswith('Subject:'):
            subject = line.strip()
            subject = line[8:]
            email['subject'] = subject

        # Optionally an else branch could extract more features
    return email

def make_df(path, label):
    rows = []
    index = []
    for i, text in enumerate(convert_files(path)):
        rows.append({'body': text['body'],'subject': text['subject'], 'sender' : text['sender'], 'label': label})
        index.append(i)

    df = pd.DataFrame(rows, index=index)
    return df

if __name__ == '__main__':
    main()
