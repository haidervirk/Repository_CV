# %% [markdown]
# # Model 3 : Neural Network
# 
# ##### Imports

# %%
import pandas as pd
import numpy as np

import matplotlib.pyplot as plt
import seaborn as sns

import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim


from sklearn.model_selection import train_test_split

# %% [markdown]
# #### Bag of Words Class

# %%

class BagOfWords:
    def __init__(self):
        self.vocabulary = {}
    
    def fit(self, documents):
        unique_words = set()
        for doc in documents:                   
            unique_words.update(doc.split())    

        self.vocabulary = {word: idx for idx, word in enumerate(unique_words)}
    
    def vectorize(self, sentence):  # convert sentence into vector
        
        vector = np.zeros(len(self.vocabulary), dtype=int)

        for word in sentence.split():
            if word in self.vocabulary:
                vector[self.vocabulary[word]] += 1
        return vector
    
    def transform(self, documents):
        return np.array([self.vectorize(doc) for doc in documents])




# %% [markdown]
# ### Reading article data and Train-Test-Eval Split
# #### 70-15-15 split

# %%

df_cleaned = pd.read_csv(r"cleaned.csv")

df_inputs = df_cleaned.drop(columns=["Gold Labels"])
df_outputs = df_cleaned["Gold Labels"]
# Split the dataset into training and test sets with test_size=0.3
# X_train, X_test, y_train, y_test = train_test_split(df_inputs, df_outputs, test_size=0.3, random_state=1)


X_train, X_temp, y_train, y_temp = train_test_split(df_inputs, df_outputs, test_size=0.3, random_state=15, stratify=df_outputs)

X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, random_state=22, stratify=y_temp)




print(f"Training set   : X_train.shape: {X_train.shape}  |  y_train.shape: {y_train.shape} ")
print(f"Validation set : X_val.shape: {X_val.shape}    |  y_val.shape {y_val.shape}")
print(f"Test set       : X_test.shape {X_test.shape}    |  y_test.shape {y_test.shape}   ")

# print(X_train.shape)
# print(X_test.shape)
X_train.head()

# %% [markdown]
# ##### Fitting Bag of words

# %%
bag = BagOfWords()
bag.fit(X_train["Contents"])
print(len(bag.vocabulary))
print(bag.vocabulary)

# %% [markdown]
# #### Vectorizing using bag of words 

# %%

X_train_vectors = bag.transform(X_train['Contents'])
X_val_vectors = bag.transform(X_val['Contents'])
X_test_vectors = bag.transform(X_test['Contents'])

print(X_train["Contents"].shape)
print(X_val["Contents"].shape)
print(X_test["Contents"].shape)

print("----"*3)
print(X_train_vectors.shape)
print(X_val_vectors.shape)
print(X_test_vectors.shape)
print("----"*3, '\n')

print(X_train_vectors[0])


# %% [markdown]
# ## Neural Network Model

# %%

# MultiClassClassifier class for 5 classes
class MultiClassClassifier(nn.Module):
    def __init__(self, input_dims, num_classes=5):
        super().__init__()
        self.input_dims = input_dims
        self.num_classes = num_classes
        self.model = nn.Sequential(
            nn.Linear(input_dims, 128),  
            nn.Sigmoid(),
            nn.Linear(128, 64),
            nn.LeakyReLU(),
            nn.Linear(64, num_classes)
        )
    def forward(self, x):
        x = self.model(x)
        x = torch.sigmoid(x)
        return x

# %% [markdown]
# # Training Loop 
# 1. **fit_one_epoch**: Performs one epoch of training 
#   
# 2. **evaluate**: Evaluates the model on the validation set
#  
# 3. **fit**: Run all epochs, recording training and validation accuracies and losses 

# %%
def fit_one_epoch(model, X, y, optimizer, loss_fn, batch_size):
    '''
    Perform one epoch of training for multi-class classification
    '''
    model.train()
    total_loss = 0
    correct = 0

    # Process data in batches
    num_samples = len(X)
    for i in range(0, num_samples, batch_size):
        x_batch = X[i:i+batch_size]  
        y_batch = y[i:i+batch_size]  

        y_pred = model(x_batch) 

        loss = loss_fn(y_pred, y_batch)
        optimizer.zero_grad()

        loss.backward()

        optimizer.step()

        total_loss += loss.item()

        # Calculate correct predictions
        predicted_classes = torch.argmax(y_pred, dim=1)  
        correct += (predicted_classes == y_batch).sum().item()

    accuracy = correct / num_samples

    return total_loss / num_samples, accuracy

@torch.no_grad()
def evaluate(model, X, y, loss_fn, batch_size = 128):
    '''
    Perform one epoch of evaluation for multi-class classification
    '''
    model.eval()
    total_loss = 0
    correct = 0

    num_samples = len(X)
    for i in range(0, num_samples, batch_size):
        x_batch = X[i:i+batch_size]  
        y_batch = y[i:i+batch_size]  

        y_pred = model(x_batch)  

        # Calculate loss
        loss = loss_fn(y_pred, y_batch)
        total_loss += loss.item()

        predicted_classes = torch.argmax(y_pred, dim=1) 
        correct += (predicted_classes == y_batch).sum().item()

    accuracy = correct / num_samples

    return total_loss / num_samples, accuracy

def fit(
    model, X_train, y_train, X_val, y_val,
    optimizer, loss_fn, epochs, batch_size=128):
    '''
    Perform the entire training process for multi-class classification
    '''
    train_losses, val_losses = [], []
    train_accuracies, val_accuracies = [], []

    for epoch in range(epochs):
        train_loss, train_acc = fit_one_epoch(model, X_train, y_train, optimizer, loss_fn, batch_size)
        val_loss, val_acc = evaluate(model, X_val, y_val, loss_fn, batch_size)
        
        # storing all the losses and accuracies
        train_losses.append(train_loss)
        train_accuracies.append(train_acc)
        val_losses.append(val_loss)
        val_accuracies.append(val_acc)
        
        print("--------------------------------------------------------------------")
        print(f"                     Epoch {epoch+1}/{epochs}:")
        print(f"             Train Loss: {train_loss:.4f}, Train Accuracy: {(train_acc*100):.2f} %")
        print(f"              Val Loss: {val_loss:.4f},  Val Accuracy: {(val_acc*100):.2f} %")

    print("--------------------------------------------------------------------")

    return train_losses, train_accuracies, val_losses, val_accuracies


# %% [markdown]
# ### Neural Network Declaration
# -  Loss function, learning rate and optimizer
# - Converting Inputs to tensors

# %%

input_dims = X_train_vectors.shape[1]  # Number of features in Bag of Words

print(input_dims)
num_classes = 5
model = MultiClassClassifier(input_dims=input_dims, num_classes=num_classes)

# Loss function, learning rate and optimizer
loss_fn = nn.CrossEntropyLoss()  
learning_rate = 0.001
optimizer = optim.Adam(model.parameters(), lr=learning_rate)

# Converting to tensors
X_trainT = torch.tensor(X_train_vectors, dtype=torch.float32)
X_valT = torch.tensor(X_val_vectors, dtype=torch.float32)

# Create a mapping from class names to numeric indices
class_mapping = {label: idx for idx, label in enumerate(y_train.unique())}
y_train_numeric = y_train.map(class_mapping)
y_val_numeric = y_val.map(class_mapping)
# Convert the mapped labels to PyTorch tensors
y_trainT = torch.tensor(y_train_numeric.values, dtype=torch.long)  
y_valT = torch.tensor(y_val_numeric.values, dtype=torch.long)

print("Class Mapping:", class_mapping)



# %% [markdown]
# ## Running the training loop

# %%

epochs = 30

# Training loop
train_losses, train_accuracies, val_losses, val_accuracies = fit(
    model, X_trainT, y_trainT, X_valT, y_valT, optimizer, loss_fn, epochs
)


# %% [markdown]
# ### Plotting Loss and Accuracy Curves 

# %%

# Plot Loss Curves
plt.figure(figsize=(8, 5))
# plt.subplot(2,1,1)
plt.plot(range(1, epochs + 1), train_losses, label='Train Loss')
plt.plot(range(1, epochs + 1), val_losses, label='Validation Loss')
plt.title('Loss Curves')
plt.xlabel('Epochs')
plt.ylabel('Loss')
plt.legend()
plt.grid()
plt.xticks(range(1, epochs + 1)) 

plt.show()

# Plot Accuracy Curves
plt.figure(figsize=(8, 5))
# plt.subplot(2,1,2)
plt.plot(range(1, epochs + 1), train_accuracies, label='Train Accuracy')
plt.plot(range(1, epochs + 1), val_accuracies, label='Validation Accuracy')
plt.title('Accuracy Curves')
plt.xlabel('Epochs')
plt.ylabel('Accuracy')
plt.legend()
plt.grid()

plt.xticks(range(1, epochs + 1)) 
plt.show()


# %% [markdown]
# ## Running on Test Set

# %%


X_testT = torch.tensor(X_test_vectors, dtype=torch.float32)


y_test_numeric = y_test.map(class_mapping)

y_testT = torch.tensor(y_test_numeric.values, dtype=torch.long)  # Numeric class indices



test_loss, test_accuracy = evaluate(model, X_testT, y_testT, loss_fn)

# test results
print(f"Test Loss: {test_loss:.4f}  \nTest Accuracy: {(100*test_accuracy):.2f} %")


# %% [markdown]
# ### Classification Report

# %%
from sklearn.metrics import classification_report

# Assuming y_train.unique() gives the unique class labels in the dataset
class_mapping = {label: idx for idx, label in enumerate(y_train.unique())}
class_names = list(class_mapping.keys())  

X_testT = X_testT.view(X_testT.size(0), -1)
print(X_testT.shape)
print(y_testT.shape)
print("----------------------------------")

model.eval()
with torch.no_grad():
    y_test_pred = model(X_testT)  
    y_test_pred_labels = torch.argmax(y_test_pred, dim=1).numpy()  

print("Classification Report:")
print(classification_report(y_testT.numpy(), y_test_pred_labels, target_names=class_names))


# %% [markdown]
# ### Confusion Matrix

# %%
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay

# Compute the confusion matrix
conf_matrix = confusion_matrix(y_testT.numpy(), y_test_pred_labels)

# Plot the confusion matrix
disp = ConfusionMatrixDisplay(confusion_matrix=conf_matrix, display_labels=class_names)
plt.figure(figsize=(20,20))
disp.plot(cmap='Blues')
plt.title("Confusion Matrix")
plt.show()



