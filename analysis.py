import datetime
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import pymc3 as pm
import seaborn as sns
from sklearn import ensemble
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import AdaBoostRegressor
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
from keras.models import Sequential
from keras.layers import Dense
import tensorflow as tf
import warnings
warnings.filterwarnings('ignore')
warnings.filterwarnings('ignore', category=DeprecationWarning)




xls_main = pd.ExcelFile("agoda_data_cleaned.xls")
df = pd.read_excel(xls_main,
                       #"City_A",
                       index_col=0)


# adding key features (y_1 = time_diff):
df['stay_length'] = (df['checkout_date'] - df['checkin_date']).dt.days
df_orig = df.copy()
df['booking_date'] = pd.to_datetime(df['booking_date']).astype(np.int64)
df['checkin_date'] = pd.to_datetime(df['checkin_date']).astype(np.int64)
df['checkout_date'] = pd.to_datetime(df['checkout_date']).astype(np.int64)
del df['log_ADR_USD']
del df['checkout_date']



# CORRELATION MATRIX
#correlation = df.corr()
#plt.figure(figsize=(18, 18))
#sns.heatmap(correlation, vmax=1, square=True,annot=True,cmap='viridis')
#plt.title('Correlation between different features (Original)')
#plt.savefig("agoda_corr_matrix_4.png")

# FEATURE ANALYSIS
X = df.loc[:, df.columns != 'ADR_USD']

y = df.loc[:, df.columns == 'ADR_USD']
scaler = StandardScaler()
X=scaler.fit_transform(X)
pca = PCA(n_components=8)
pca.fit(X)
var=np.cumsum(np.round(pca.explained_variance_ratio_, decimals=3)*100)
print(var)
#plt.ylabel('Percentage of Variance Explained')
#plt.xlabel('Number of Features')
#plt.title('Principle Component Analysis: Agoda Hotel Featureset')
#plt.style.context('seaborn-whitegrid')
#plt.plot(var)
#plt.savefig("agoda_feature_viz_final2.png")

X_train, X_test, Y_train, Y_test = train_test_split(X, y, test_size=0.1, random_state=1)

NN_model = Sequential()

# promising architecture:
# The Input Layer :
NN_model.add(Dense(8, kernel_initializer='normal',input_dim = X_train.shape[1], activation='relu'))

# The Hidden Layers :
NN_model.add(Dense(3, kernel_initializer='normal',activation='relu'))

# The Output Layer :
NN_model.add(Dense(1, kernel_initializer='normal',activation='linear'))

# Compile the network :
NN_model.compile(loss='mean_absolute_percentage_error',
                 optimizer='adam',
                 metrics=['mean_absolute_percentage_error'],
                 )
NN_model.summary()

hist = NN_model.fit(X_train, Y_train, epochs=200, batch_size=10, validation_split = 0.2)
NN_model.evaluate(X_test, Y_test)

plt.plot(hist.history['loss'])
plt.plot(hist.history['val_loss'])
plt.title('Model loss: Optimized Architecture E')
plt.ylim(20, 50)
plt.ylabel('Mean Absolute Percentage Error')
plt.xlabel('Epoch')
plt.legend(['Training', 'Validation'], loc='upper right')
plt.savefig("neural_net_model_loss_e")
y_nets = NN_model.predict(X)


# 10 is good depth
regr_1 = DecisionTreeRegressor(criterion='friedman_mse',
                               splitter='random',
                               max_depth=9,
                               )
regr_1.fit( X, y)
y_1 = regr_1.predict(X)
df_orig['net_preds'] = y_nets
df_orig.to_excel('nets_output_2.xlsx')

xls_short = pd.ExcelFile("agoda_data_short.xls")
df_short = pd.read_excel(xls_short,
                       #"City_A",
                       index_col=0)
del df_short['_clus_1']
del df_short['_clus_2']
short_dict = df_short.to_dict(orient='index')

