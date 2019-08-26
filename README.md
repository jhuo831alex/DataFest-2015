# About the Project
The main goal of this project was to answer one question: "If a customer leaves information on *Edmunds.com* for a particular car, is he/she going to buy the car?". By determining how likely a certain user will buy cars, we then decided if to pursue this user or not.

# Methodology
* Data was provided by *[Edmunds.com](https://www.edmunds.com/)* (data size: 1.7GB & 5 Tables)
* Engineered 12 new features from 5 tables
* Prepared dataset for modeling (missing value removal, outlier removal, bucketing, onehot encoding, and etc.)
* Reduced data dimensionality with Chi-square test
* Standardized numeric features
* Activated parallel computing capabilities
* Implemented binary logistic classification using XGBoost
* Tuned hyperparameter using random search (Hyperparameter tuned: eta, nrounds, max_depth, eval_metric='AUC')
* 3-fold cross validation 
* Model accuracy: 86.8%

# Further Details
For more information: 
- [Deck](https://github.com/jhuo831alex/DataFest2015_Edmunds/blob/master/Presentation_Deck.pdf)
- [Project Report](https://github.com/jhuo831alex/DataFest2015_Edmunds/blob/master/Project_Report.pdf)


# About DataFest
ASA DataFestTM is a data hackathon for undergraduate students, sponsored by the American Statistical Association and founded at UCLA, in 2011. <br /> <br />
For more information: [DataFest@UCLA](http://datafest.stat.ucla.edu/)
