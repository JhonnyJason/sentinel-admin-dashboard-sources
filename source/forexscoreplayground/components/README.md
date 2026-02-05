# forexscoreplayground/components
Here are all the reusable component structures and their styles.
Therefore each has a corresponding `.pug`  and `.styl` file.

## Main Components
- `cotnorm-el` display of normalization function, params and results for the COTs per Area
- `cubdiff-el` display of cubic diff functions, params and results for weighing score differences between base and quote 
- `result-el` display of endresults for each timeframe (short-term, long-medium-term, long-term), plus their parameters and cacluation
- `linnorm-el` display of the linear normalization function, params and results mainly for the interest rate
- `makro-el` display of makrodata of an economic area which is used as the basis for the forexscore calculations
- `quadnorm-el` display of quadratic normalization function, params and results (inflation and gdp normalization)

## other files
- `./common.styl` collection of common styles that shared among many elements
- `./result-inner.pug` the result-box is made of 3 similar elements, so these are separated out contents.
- `./README.md` this file :-)