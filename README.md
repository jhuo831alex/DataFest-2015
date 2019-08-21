<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a>
    <img src="https://santanderconsumerusa.com/wp-content/uploads/2014/05/05-01-scusa_best-auto-shopping-websites_itunes-apple_-com_.png" alt="Logo" width="80" height="80">
  </a>
  <h2 align="center">DataFest2015: Edmunds</h2>

  <p align="center">
    Classification of buyers and nonbuyers
  </p>
</p>


<!-- ABOUT THE PROJECT -->
## About the project
The main goal of this project was to answer one question: "If a customer leaves information on Edmunds.com for a particular car, is he/she going to buy the car?". By determining how likely a certain user will buy cars, we then decide if to pursue this user or not.
* Data was provided by [Edmunds](https://www.edmunds.com/) (data size: 1.7GB & 4 Tables)
* Engineered 12 new features from 4 tables
* Prepared dataset for modeling (missing value removal, outlier removal, bucketing, onehot encoding, and etc.)
* Reduced data dimensionality with Chi-square test
* Standardized numeric features
* Activated parallel computing capabilities
* Implemented binary logistic classification using XGBoost
* Tuned hyperparameter using random search (Hyperparameter tuned: eta, nrounds, max_depth, eval_metric='AUC')
* 3-fold cross validation 
* Model accuracy: 86.8%

For more information: [Deck](https://github.com/jhuo831alex/DataFest2015_Edmund/blob/master/141%20PPT.pdf)

<!-- ABOUT DataFest -->
## About DataFest
ASA DataFestTM is a data hackathon for undergraduate students, sponsored by the American Statistical Association and founded at UCLA, in 2011. <br />
For more information: [DataFest@UCLA](http://datafest.stat.ucla.edu/)

<!-- CONTACT -->
## Contact
Alex (Jiahao) Huo: 
[![LinkedIn][linkedin-shield]][linkedin-url]
[![Email][email-shield]][email-url]


<!-- MARKDOWN LINKS & IMAGES -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/jiahaohuo/
[email-shield]: https://img.shields.io/badge/-Gmail-black.svg?style=flat-square&logo=gmail&colorB=555
[email-url]: mailto:jiahao.h@columbia.edu
