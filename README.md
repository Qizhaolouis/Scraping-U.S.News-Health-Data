
# Best Hospitals of Different Specialty

This is a sample project to show how I scrape and clean data.

- Scrape the data from the <a href='https://health.usnews.com/best-hospitals/search'>U.S.News Health</a>.
- Get the top 50 hospitals' detailed data.
  - Name
  - Specilty
  - Score
  - Zipcode
  - City
  - State

### Packages Requirement
**Selenium**
- To install selenium, run in terminal:
```
pip install selenium
```

- Since I use **chrome**, I have to download <a href='http://chromedriver.chromium.org/'>Chrome Driver</a> first.
Then move it to a safe location
```
mv [location]/chromedriver /usr/local/bin/chromedriver
```

**BeautifulSoup**
- To install, run in terminal or run following cells:
```
pip install beautifulsoup4
```



```python
!pip install beautifulsoup4
!pip install selenium
!pip install pandas
!pip install imageio
```


```python
import time
from bs4 import BeautifulSoup
from selenium import webdriver
from html.parser import HTMLParser
import pandas as pd
from matplotlib.pyplot import imshow
import imageio
```


```python
driver = webdriver.Chrome(executable_path='/usr/local/bin/chromedriver')
url = 'https://health.usnews.com/best-hospitals/search'
driver.get(url)
```

### Screenshot
- Take a screenshot.
- There are `17` fields under `Specialty`.


```python
driver.execute_script("window.scrollTo(0, 1150);")
sc = driver.save_screenshot('images/screen.png')
content_image = imageio.imread('images/screen.png')
imshow(content_image,interpolation='nearest', aspect='auto')
```




    <matplotlib.image.AxesImage at 0x1190859b0>




![png](output_7_1.png)


## Configure URL

- Now that we want to get all the area under the specilty.
- All the `,` should be removed
- All the `&` becomes `and`.
- All the space characters are replaced by `-`.


```python
data = BeautifulSoup(driver.page_source, "html.parser")
fields = list(map(lambda x: x.replace('\n','').strip(), list(map(lambda x: x.text, data.find_all("label")))))
fields = list(map(lambda x: '-'.join(x.replace(',',' ').replace('&','and').split()), fields))
fields = fields[fields.index('Cancer'):(fields.index('Urology')+1)]
fields[fields.index('Geriatrics')] = 'geriatric-care'
fields
```




    ['Cancer',
     'Cardiology-and-Heart-Surgery',
     'Diabetes-and-Endocrinology',
     'Ear-Nose-and-Throat',
     'Gastroenterology-and-GI-Surgery',
     'geriatric-care',
     'Gynecology',
     'Long-Term-Care',
     'Nephrology',
     'Neurology-and-Neurosurgery',
     'Ophthalmology',
     'Orthopedics',
     'Psychiatry',
     'Pulmonology',
     'Rehabilitation',
     'Rheumatology',
     'Urology']




## Data Cleaning Functions


- Using the `Specialty` area
- Click `Load More` to get top 20 data.

### Names
- First of all we get the names.


```python
def get_name(data1):
    name = list(map(lambda x: x.text.replace('\n','').strip(), data1.find_all('a',{'class':'search-result-link'})))
    return name
```

### The Scores 
- We now get the scores of each hospital.
- Max score is 100.


```python
def get_score(data1):
    score = list(map(lambda x: x.replace('/100',''), [x.text for x in data1.find_all('dt') if len(str(x)) <= 18]))
    return score
```

### The address
- We want to get the city, state and zipcode


```python
def get_address(data1):
    block_tight = [x for x in data1.find_all('div',{'class':'block-tight'})[2:] if '<div class="block-tight">' in str(x)]
    address = list(map(lambda x: x.text.replace('\n','').strip(), block_tight))
    zipcode = list(map(lambda x: x.split()[-1], address))
    address = [address[i].replace(zipcode[i],'').split('|')[-1].strip() for i in range(len(address))]
    city = list(map(lambda x: x.split(',')[0],address))
    state =  list(map(lambda x: x.split(',')[1].strip(),address))
    return zipcode, city, state
```

    
## Scrape Data


```python
def SearchUSNewsHealth(specialty):
    driver = webdriver.Chrome(executable_path='/usr/local/bin/chromedriver')
    best_hospitals = []
    url = 'https://health.usnews.com/best-hospitals/rankings/'+specialty
    driver.get(url)
    ## Scroll down once to get 10 more
    driver.find_element_by_css_selector("#search-app-matches-more-button-region > div > a").click()
    ## Sleep 2 seconds for the data to load completely
    time.sleep(2)
    data1 = BeautifulSoup(driver.page_source, "html.parser")
    ## The name
    name = get_name(data1)
    ## The score
    score = get_score(data1)
    ## The address
    zipcode, city, state = get_address(data1)
    ## return the list
    for i in range(len(name)):
        best_hospitals.append({
            'specialty': ' '.join(specialty.split('-')),
            'name': name[i],
            'zipcode':zipcode[i],
            'city': city[i],
            'state': state[i],
            'score': score[i]
        })
    driver.quit()
    return best_hospitals
```

- We exclude `Long term care` since it is not being scored.


```python
bests = []
fields.remove('Long-Term-Care')
for specialty in fields:
    bests += SearchUSNewsHealth(specialty)
hospitals = pd.DataFrame(bests)
```


```python
hospitals
```




<div>
<style scoped>
    .dataframe tbody tr th:only-of-type {
        vertical-align: middle;
    }

    .dataframe tbody tr th {
        vertical-align: top;
    }

    .dataframe thead th {
        text-align: right;
    }
</style>
<table border="1" class="dataframe">
  <thead>
    <tr style="text-align: right;">
      <th></th>
      <th>city</th>
      <th>name</th>
      <th>score</th>
      <th>specialty</th>
      <th>state</th>
      <th>zipcode</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>Houston</td>
      <td>University of Texas MD Anderson Cancer Center</td>
      <td>100.0</td>
      <td>Cancer</td>
      <td>TX</td>
      <td>77030-4000</td>
    </tr>
    <tr>
      <th>1</th>
      <td>New York</td>
      <td>Memorial Sloan Kettering Cancer Center</td>
      <td>97.4</td>
      <td>Cancer</td>
      <td>NY</td>
      <td>10065-6007</td>
    </tr>
    <tr>
      <th>2</th>
      <td>Rochester</td>
      <td>Mayo Clinic</td>
      <td>91.8</td>
      <td>Cancer</td>
      <td>MN</td>
      <td>55902-1906</td>
    </tr>
    <tr>
      <th>3</th>
      <td>Boston</td>
      <td>Dana-Farber/Brigham and Women's Cancer Center</td>
      <td>84.4</td>
      <td>Cancer</td>
      <td>MA</td>
      <td>02215-5418</td>
    </tr>
    <tr>
      <th>4</th>
      <td>Seattle</td>
      <td>Seattle Cancer Alliance/University of Washingt...</td>
      <td>76.5</td>
      <td>Cancer</td>
      <td>WA</td>
      <td>98109-4405</td>
    </tr>
    <tr>
      <th>5</th>
      <td>Baltimore</td>
      <td>Johns Hopkins Hospital</td>
      <td>75.9</td>
      <td>Cancer</td>
      <td>MD</td>
      <td>21205-1832</td>
    </tr>
    <tr>
      <th>6</th>
      <td>Cleveland</td>
      <td>Cleveland Clinic</td>
      <td>75.0</td>
      <td>Cancer</td>
      <td>OH</td>
      <td>44195-5108</td>
    </tr>
    <tr>
      <th>7</th>
      <td>Philadelphia</td>
      <td>Hospitals of the University of Pennsylvania-Pe...</td>
      <td>75.0</td>
      <td>Cancer</td>
      <td>PA</td>
      <td>19104-4206</td>
    </tr>
    <tr>
      <th>8</th>
      <td>Tampa</td>
      <td>Moffitt Cancer Center and Research Institute</td>
      <td>74.9</td>
      <td>Cancer</td>
      <td>FL</td>
      <td>33612-9497</td>
    </tr>
    <tr>
      <th>9</th>
      <td>San Francisco</td>
      <td>UCSF Medical Center</td>
      <td>73.3</td>
      <td>Cancer</td>
      <td>CA</td>
      <td>94143-0296</td>
    </tr>
    <tr>
      <th>10</th>
      <td>Stanford</td>
      <td>Stanford Health Care-Stanford Hospital</td>
      <td>73.2</td>
      <td>Cancer</td>
      <td>CA</td>
      <td>94304-2203</td>
    </tr>
    <tr>
      <th>11</th>
      <td>Boston</td>
      <td>Massachusetts General Hospital</td>
      <td>71.4</td>
      <td>Cancer</td>
      <td>MA</td>
      <td>02114-2696</td>
    </tr>
    <tr>
      <th>12</th>
      <td>Los Angeles</td>
      <td>UCLA Medical Center</td>
      <td>71.4</td>
      <td>Cancer</td>
      <td>CA</td>
      <td>90095-8358</td>
    </tr>
    <tr>
      <th>13</th>
      <td>Ann Arbor</td>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>71.4</td>
      <td>Cancer</td>
      <td>MI</td>
      <td>48109</td>
    </tr>
    <tr>
      <th>14</th>
      <td>Los Angeles</td>
      <td>USC Norris Cancer Hospital-Keck Medical Center...</td>
      <td>70.5</td>
      <td>Cancer</td>
      <td>CA</td>
      <td>90089-0112</td>
    </tr>
    <tr>
      <th>15</th>
      <td>Chicago</td>
      <td>Northwestern Memorial Hospital</td>
      <td>69.9</td>
      <td>Cancer</td>
      <td>IL</td>
      <td>60611-2908</td>
    </tr>
    <tr>
      <th>16</th>
      <td>Phoenix</td>
      <td>Mayo Clinic-Phoenix</td>
      <td>69.6</td>
      <td>Cancer</td>
      <td>AZ</td>
      <td>85054-4502</td>
    </tr>
    <tr>
      <th>17</th>
      <td>Jacksonville</td>
      <td>Mayo Clinic Jacksonville</td>
      <td>69.5</td>
      <td>Cancer</td>
      <td>FL</td>
      <td>32224-1865</td>
    </tr>
    <tr>
      <th>18</th>
      <td>Saint Louis</td>
      <td>Siteman Cancer Center</td>
      <td>69.3</td>
      <td>Cancer</td>
      <td>MO</td>
      <td>63110-1003</td>
    </tr>
    <tr>
      <th>19</th>
      <td>Philadelphia</td>
      <td>Jefferson Health-Thomas Jefferson University H...</td>
      <td>69.1</td>
      <td>Cancer</td>
      <td>PA</td>
      <td>19107-5084</td>
    </tr>
    <tr>
      <th>20</th>
      <td>Cleveland</td>
      <td>Cleveland Clinic</td>
      <td>100.0</td>
      <td>Cardiology and Heart Surgery</td>
      <td>OH</td>
      <td>44195-5108</td>
    </tr>
    <tr>
      <th>21</th>
      <td>Rochester</td>
      <td>Mayo Clinic</td>
      <td>99.5</td>
      <td>Cardiology and Heart Surgery</td>
      <td>MN</td>
      <td>55902-1906</td>
    </tr>
    <tr>
      <th>22</th>
      <td>New York</td>
      <td>New York-Presbyterian Hospital-Columbia and Co...</td>
      <td>85.2</td>
      <td>Cardiology and Heart Surgery</td>
      <td>NY</td>
      <td>10065-4870</td>
    </tr>
    <tr>
      <th>23</th>
      <td>Los Angeles</td>
      <td>Smidt Heart Institute at Cedars-Sinai</td>
      <td>81.8</td>
      <td>Cardiology and Heart Surgery</td>
      <td>CA</td>
      <td>90048-1865</td>
    </tr>
    <tr>
      <th>24</th>
      <td>Boston</td>
      <td>Massachusetts General Hospital</td>
      <td>79.0</td>
      <td>Cardiology and Heart Surgery</td>
      <td>MA</td>
      <td>02114-2696</td>
    </tr>
    <tr>
      <th>25</th>
      <td>Baltimore</td>
      <td>Johns Hopkins Hospital</td>
      <td>77.3</td>
      <td>Cardiology and Heart Surgery</td>
      <td>MD</td>
      <td>21205-1832</td>
    </tr>
    <tr>
      <th>26</th>
      <td>Chicago</td>
      <td>Northwestern Memorial Hospital</td>
      <td>76.7</td>
      <td>Cardiology and Heart Surgery</td>
      <td>IL</td>
      <td>60611-2908</td>
    </tr>
    <tr>
      <th>27</th>
      <td>Philadelphia</td>
      <td>Hospitals of the University of Pennsylvania-Pe...</td>
      <td>75.4</td>
      <td>Cardiology and Heart Surgery</td>
      <td>PA</td>
      <td>19104-4206</td>
    </tr>
    <tr>
      <th>28</th>
      <td>New York</td>
      <td>Mount Sinai Hospital</td>
      <td>75.1</td>
      <td>Cardiology and Heart Surgery</td>
      <td>NY</td>
      <td>10029-0310</td>
    </tr>
    <tr>
      <th>29</th>
      <td>Ann Arbor</td>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>74.5</td>
      <td>Cardiology and Heart Surgery</td>
      <td>MI</td>
      <td>48109</td>
    </tr>
    <tr>
      <th>...</th>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
    </tr>
    <tr>
      <th>290</th>
      <td>Pittsburgh</td>
      <td>UPMC Presbyterian Shadyside</td>
      <td>7.6</td>
      <td>Rheumatology</td>
      <td>PA</td>
      <td>15213-2536</td>
    </tr>
    <tr>
      <th>291</th>
      <td>Ann Arbor</td>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>7.4</td>
      <td>Rheumatology</td>
      <td>MI</td>
      <td>48109</td>
    </tr>
    <tr>
      <th>292</th>
      <td>Durham</td>
      <td>Duke University Hospital</td>
      <td>6.9</td>
      <td>Rheumatology</td>
      <td>NC</td>
      <td>27705-4699</td>
    </tr>
    <tr>
      <th>293</th>
      <td>Stanford</td>
      <td>Stanford Health Care-Stanford Hospital</td>
      <td>5.9</td>
      <td>Rheumatology</td>
      <td>CA</td>
      <td>94304-2203</td>
    </tr>
    <tr>
      <th>294</th>
      <td>Chicago</td>
      <td>Northwestern Memorial Hospital</td>
      <td>4.8</td>
      <td>Rheumatology</td>
      <td>IL</td>
      <td>60611-2908</td>
    </tr>
    <tr>
      <th>295</th>
      <td>Philadelphia</td>
      <td>Hospitals of the University of Pennsylvania-Pe...</td>
      <td>4.3</td>
      <td>Rheumatology</td>
      <td>PA</td>
      <td>19104-4206</td>
    </tr>
    <tr>
      <th>296</th>
      <td>Saint Louis</td>
      <td>Barnes-Jewish Hospital</td>
      <td>4.2</td>
      <td>Rheumatology</td>
      <td>MO</td>
      <td>63110-1003</td>
    </tr>
    <tr>
      <th>297</th>
      <td>Aurora</td>
      <td>University of Colorado Hospital</td>
      <td>3.6</td>
      <td>Rheumatology</td>
      <td>CO</td>
      <td>80045-2545</td>
    </tr>
    <tr>
      <th>298</th>
      <td>Charleston</td>
      <td>MUSC Health-University Medical Center</td>
      <td>3.4</td>
      <td>Rheumatology</td>
      <td>SC</td>
      <td>29425-8905</td>
    </tr>
    <tr>
      <th>299</th>
      <td>La Jolla</td>
      <td>Scripps La Jolla Hospitals</td>
      <td>3.1</td>
      <td>Rheumatology</td>
      <td>CA</td>
      <td>92037-1200</td>
    </tr>
    <tr>
      <th>300</th>
      <td>Cleveland</td>
      <td>Cleveland Clinic</td>
      <td>100.0</td>
      <td>Urology</td>
      <td>OH</td>
      <td>44195-5108</td>
    </tr>
    <tr>
      <th>301</th>
      <td>Rochester</td>
      <td>Mayo Clinic</td>
      <td>99.5</td>
      <td>Urology</td>
      <td>MN</td>
      <td>55902-1906</td>
    </tr>
    <tr>
      <th>302</th>
      <td>Baltimore</td>
      <td>Johns Hopkins Hospital</td>
      <td>95.9</td>
      <td>Urology</td>
      <td>MD</td>
      <td>21205-1832</td>
    </tr>
    <tr>
      <th>303</th>
      <td>Los Angeles</td>
      <td>UCLA Medical Center</td>
      <td>86.6</td>
      <td>Urology</td>
      <td>CA</td>
      <td>90095-8358</td>
    </tr>
    <tr>
      <th>304</th>
      <td>New York</td>
      <td>Memorial Sloan Kettering Cancer Center</td>
      <td>86.3</td>
      <td>Urology</td>
      <td>NY</td>
      <td>10065-6007</td>
    </tr>
    <tr>
      <th>305</th>
      <td>San Francisco</td>
      <td>UCSF Medical Center</td>
      <td>85.1</td>
      <td>Urology</td>
      <td>CA</td>
      <td>94143-0296</td>
    </tr>
    <tr>
      <th>306</th>
      <td>Ann Arbor</td>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>83.7</td>
      <td>Urology</td>
      <td>MI</td>
      <td>48109</td>
    </tr>
    <tr>
      <th>307</th>
      <td>New York</td>
      <td>New York-Presbyterian Hospital-Columbia and Co...</td>
      <td>80.4</td>
      <td>Urology</td>
      <td>NY</td>
      <td>10065-4870</td>
    </tr>
    <tr>
      <th>308</th>
      <td>Nashville</td>
      <td>Vanderbilt University Medical Center</td>
      <td>80.2</td>
      <td>Urology</td>
      <td>TN</td>
      <td>37232-2102</td>
    </tr>
    <tr>
      <th>309</th>
      <td>Durham</td>
      <td>Duke University Hospital</td>
      <td>80.1</td>
      <td>Urology</td>
      <td>NC</td>
      <td>27705-4699</td>
    </tr>
    <tr>
      <th>310</th>
      <td>Chicago</td>
      <td>Northwestern Memorial Hospital</td>
      <td>79.0</td>
      <td>Urology</td>
      <td>IL</td>
      <td>60611-2908</td>
    </tr>
    <tr>
      <th>311</th>
      <td>Los Angeles</td>
      <td>Cedars-Sinai Medical Center</td>
      <td>78.0</td>
      <td>Urology</td>
      <td>CA</td>
      <td>90048-1865</td>
    </tr>
    <tr>
      <th>312</th>
      <td>Pittsburgh</td>
      <td>UPMC Presbyterian Shadyside</td>
      <td>77.7</td>
      <td>Urology</td>
      <td>PA</td>
      <td>15213-2536</td>
    </tr>
    <tr>
      <th>313</th>
      <td>Stanford</td>
      <td>Stanford Health Care-Stanford Hospital</td>
      <td>77.3</td>
      <td>Urology</td>
      <td>CA</td>
      <td>94304-2203</td>
    </tr>
    <tr>
      <th>314</th>
      <td>New York</td>
      <td>NYU Langone Hospitals</td>
      <td>76.5</td>
      <td>Urology</td>
      <td>NY</td>
      <td>10016-6402</td>
    </tr>
    <tr>
      <th>315</th>
      <td>Madison</td>
      <td>University of Wisconsin Hospitals</td>
      <td>76.0</td>
      <td>Urology</td>
      <td>WI</td>
      <td>53792-0002</td>
    </tr>
    <tr>
      <th>316</th>
      <td>Kansas City</td>
      <td>University of Kansas Hospital</td>
      <td>75.6</td>
      <td>Urology</td>
      <td>KS</td>
      <td>66160-7200</td>
    </tr>
    <tr>
      <th>317</th>
      <td>Saint Louis</td>
      <td>Barnes-Jewish Hospital</td>
      <td>74.4</td>
      <td>Urology</td>
      <td>MO</td>
      <td>63110-1003</td>
    </tr>
    <tr>
      <th>318</th>
      <td>Dallas</td>
      <td>UT Southwestern Medical Center</td>
      <td>74.2</td>
      <td>Urology</td>
      <td>TX</td>
      <td>75390-9265</td>
    </tr>
    <tr>
      <th>319</th>
      <td>Birmingham</td>
      <td>University of Alabama at Birmingham Hospital</td>
      <td>73.8</td>
      <td>Urology</td>
      <td>AL</td>
      <td>35249-1900</td>
    </tr>
  </tbody>
</table>
<p>320 rows × 6 columns</p>
</div>




```python
hospitals.to_csv('best_hospital.csv')
```
