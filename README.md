# Gender Sorting and Occupational Tasks Across Countries

## Project Description

This project investigates **how men and women sort into different types of occupations** defined by task content:

- **Abstract**
- **Routine**
- **Manual**

We focus specifically on two mechanisms:

1. **Overwork Sorting**  
   How do long-hour work environments affect the gender composition of high-skill jobs?

2. **Baseline Ability Sorting**  
   How do measures of baseline skills (numeracy, literacy, problem-solving) predict women's occupational outcomes compared to men's?

Our analysis leverages survey data that includes:

- Occupational codes
- Skill assessments
- Work hours and job characteristics
- Demographics

## Project Structure

```
.
├── Code/
│   ├── 0_Master.do          
│   ├── 01_Create Dataset.do
│   ├── 10_Analysis.do
│   ├── 11_Sorting.do
│   ├── 12_Replication.do
│   └──  13_Mismatch.do                   
├── Data/
│   └── (Not Posted)
├── Outputs/
│   └── (Not Posted)/
├── README.md
```

## Replication Instructions

1. Clone the repo:
   ```
   git clone https://github.com/yourusername/gender-task-sorting.git
   ```

2. Open Stata, change the path, then run:
   - `0_Master.do`    
  This will run all of the code for the project.

## Data Sources

- **PIAAC Survey Data**: Job information, hours information, adult skill assessment data and demographic information
- **ONET**: Abstract, routine, manual classification

Note: Data files are not included in the repository for size reasons. Please contact the me for the data.

## Authors

- **Chinhui Juhn**, Professor of Economics, University of Houston
- Code is written by **Brian Murphy**, PhD Student in Economics  
