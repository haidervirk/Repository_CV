# %% [markdown]
# ## Model 2: Logistic Regression
# 

# %% [markdown]
# #### Imports

# %%
import pandas as pd
import numpy as np
import re

import matplotlib.pyplot as plt
import seaborn as sns


from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score,confusion_matrix
from tqdm import tqdm

# %% [markdown]
# #### Bag of Words Implementation
# 

# %%
# BagOfWords class, taken from PA 1.1
class BagOfWords:
    def __init__(self):
        self.vocabulary = {}
    
    def fit(self, documents):
        # documents : array of strings
        unique_words = set()
        for doc in documents:                   # for each string
            unique_words.update(doc.split())    # add all words to set

        self.vocabulary = {word: idx for idx, word in enumerate(unique_words)}
    
    def vectorize(self, sentence):  # convert sentence into vector
        
        vector = np.zeros(len(self.vocabulary), dtype=int)

        for word in sentence.split():
            if word in self.vocabulary:
                vector[self.vocabulary[word]] += 1
        return vector
    
    def transform(self, documents):
        # use vectorize on each row of the data
        return np.array([self.vectorize(doc) for doc in documents])



bow = BagOfWords()

# %% [markdown]
# #### Test - Train Split
# 

# %%
df_cleaned = pd.read_csv(r"cleaned.csv")
df_inputs = df_cleaned.drop(columns=["Gold Labels"])
df_outputs = df_cleaned["Gold Labels"]

# Split the dataset into training and test sets with test_size=0.3
X_train, X_test, y_train, y_test = train_test_split(df_inputs, df_outputs, test_size=0.3, random_state=15)

print(X_train.shape)
print(X_test.shape)
df_inputs.head()


# %% [markdown]
# 
# #### Converting into Bag of Words

# %%
bag = BagOfWords()
bag.fit(X_train["Contents"])
X_train_vectors = bag.transform(X_train['Contents'])
X_test_vectors = bag.transform(X_test['Contents'])

print(len(bag.vocabulary))
bag.vocabulary

# %% [markdown]
# ## Evaluation Metrics

# %%
# For evaluation, taken from 1.2

def accuracy_own(predicted_labels, true_labels): 
  return np.mean(predicted_labels == true_labels)


def make_confusion_matrix_own(predicted_labels, true_labels): 
  num_classes = len(np.unique(true_labels))
  confusion_matrix = np.zeros((num_classes, num_classes), dtype=int)
  for true, predicted in zip(true_labels, predicted_labels):
      confusion_matrix[true][predicted] += 1
  
  return confusion_matrix


def make_heat_map(confusion_matrix, title):
  plt.figure(figsize=(8, 6))
  sns.heatmap(confusion_matrix, annot=True, fmt="d", cmap="Blues", cbar=True)
  plt.title(title)
  plt.xlabel("Predicted Labels")
  plt.ylabel("True Labels")
  plt.show()


def precision_own(confusion_matrix, class_label):
  tp = confusion_matrix[class_label, class_label]
  fp = np.sum(confusion_matrix[:, class_label]) - tp
  
  if (tp + fp) == 0:
      return 0
  else:
      return tp / (tp + fp)

def recall_own(confusion_matrix, class_label):
  tp = confusion_matrix[class_label, class_label]
  fn = np.sum(confusion_matrix[class_label, :]) - tp
  
  if (tp + fn) == 0:
      return 0
  else:
      return tp / (tp + fn)

def f1_score_own(precision, recall):
  if (np.all(precision == 0) and np.all(recall == 0)):
      return 0
  else:
      return 2 * (precision * recall) / (precision + recall)


def macro_average_f1_own(confusion_matrix):
  num_classes = confusion_matrix.shape[0]
  f1_scores = []
  
  for class_label in range(num_classes):
      precision_value = precision_own(confusion_matrix, class_label)
      recall_value = recall_own(confusion_matrix, class_label)
      f1 = f1_score_own(precision_value, recall_value)
      f1_scores.append(f1)
  
  return np.mean(f1_scores)


def evaluate(predicted_labels, true_labels):
  accuracy_score = accuracy_own(predicted_labels, true_labels)
  confusion_matrix = make_confusion_matrix_own(predicted_labels, true_labels)
  macro_f1 = macro_average_f1_own(confusion_matrix)
  
  # Display my nicely formatted report
  print(f"Accuracy: {accuracy_score:.4f}") # .4f rounds it up to 4 decimal places
  print(f"Macro-Average F1 Score: {macro_f1:.4f}")
  print("\nConfusion Matrix:")
  make_heat_map(confusion_matrix, title="Confusion Matrix Heatmap")
  
  return accuracy_score, macro_f1, confusion_matrix

# %% [markdown]
# ## Logistic Regression Classifier 
# - `LogisticRegression` class implemented
# - Highly inspired by PA 2.2

# %%
class LogisticRegression:
    def __init__(self, learning_rate = 0.1, epochs = 200):
        self.learning_rate = learning_rate
        self.epoch = epochs
        self.bias = None
        self.weights = None
        self.losses = []

    def sigmoid(self, x):
        return 1 / (1 + np.exp(-x))
    
    def cross_entropy_loss(self, y_true, y_pred):
        return -np.mean(y_true*np.log(y_pred) + (1-y_true)*np.log(1-y_pred))  

    def fit(self, x_train, y_train, reg_lambda=0.01):
        self.weights = np.zeros(x_train.shape[1])
        self.bias = 0
        self.losses = []
        
        for _ in tqdm(range(self.epoch)):
            linear_model = np.dot(x_train, self.weights) + self.bias
            y_pred = self.sigmoid(linear_model)
            dw = (np.dot(x_train.T, (y_pred - y_train)) + reg_lambda * self.weights) / y_train.size
            db = np.sum(y_pred - y_train) / y_train.size
            self.weights -= self.learning_rate * dw
            self.bias -= self.learning_rate * db
            self.losses.append(self.cross_entropy_loss(y_train, y_pred))

    def predict(self, x_test):
        probabilities = self.sigmoid(np.dot(x_test, self.weights) + self.bias)
        labels = np.round(probabilities)
        return labels, probabilities


    def evaluate(self, y_true, y_pred):
        accuracy = np.mean(y_pred == y_true)

        num_classes = len(np.unique(y_true))
        confusion_matrix = np.zeros((num_classes, num_classes), dtype=int)
        for true, predicted in zip(y_true, y_pred):
            confusion_matrix[int(true)][int(predicted)] += 1

        macro_f1_score=macro_average_f1_own(confusion_matrix)
    
        return accuracy, macro_f1_score, confusion_matrix

# %% [markdown]
# ##  Implementation of One vs All Classification
# 
# We build five classifiers, one for each class.
# 
# - We have created a plot for each of the classifier with the losses.

# %%
# One-vs-Rest Classifiers
classifiers = {}
losses = {}  # To store losses for each classifier

unique_classes = np.unique((y_train))
label_mapping = {label: idx for idx, label in enumerate(unique_classes)}
y_train_encoded = np.array([label_mapping[label] for label in y_train])

for i in range(5):
    y_binary = (y_train_encoded == i).astype(int)  # Current positive class, use this while fitting to train data
    classifiers[i] = LogisticRegression(learning_rate=0.1, epochs=200)       # declare your logistic regression model here 
    classifiers[i].fit(X_train_vectors, y_binary)
    cost = classifiers[i].losses                 # fit on your training data and store the cost.
    losses[i] = cost            # Save the cost values for plotting

# Plot training loss for each classifier
epochs = np.arange(0, classifiers[0].epoch)
plt.figure(figsize=(10, 6))
for i in range(5):
    plt.plot(epochs, losses[i], label=f'Class {i}')
plt.xlabel('Epochs')
plt.ylabel('Loss')
plt.title('Loss vs Number of Iterations')
plt.legend()
plt.show()


# %% [markdown]
# ## Evalution of our model on test data

# %%
# Evaluate each binary classifier
y_test_encoded = np.array([label_mapping[label] for label in y_test])

results = {
    'Class': [],
    'Probs':[],
    'Accuracy': [],
    'F1 Score': [],
    'Confusion Matrix': []
}

for i in range(5):  
    predicted_class, probability = classifiers[i].predict(X_test_vectors)     # predict on your test data
    accuracy, macro_f1, cm = classifiers[i].evaluate((y_test_encoded==i).astype(int), predicted_class)
    
    results['Class'].append(i)
    results['Probs'].append(probability)
    results['Accuracy'].append(accuracy)
    results['F1 Score'].append(macro_f1)
    results['Confusion Matrix'].append(cm)

results_df = pd.DataFrame(results)
results_df.head()

# %%
results_df.drop('Probs',axis=1)

# %% [markdown]
# ## Assigning labels for multiclass predictions
# 
# - Here we follow the mappings we created for `y_train` and `y_test`
# - We assign the index to it's corresponding label.
# - For each article, we compare all the probabilities from each classifer and assign the label of the highest probability class.

# %%
class_labels = ['Class 0: entertainment', 
                'Class 1: business', 
                'Class 2: sports',
                'Class 3: science-technology',
                'Class 4: world']

all_probabilities = np.column_stack(results['Probs'])  
multiclass_predictions = np.argmax(all_probabilities, axis=1)
final_labels = [class_labels[pred] for pred in multiclass_predictions]
print(final_labels)

# %% [markdown]
# ## Multiclass Evaluation

# %%
accuracy, m_f1, c = evaluate(multiclass_predictions, y_test_encoded)


