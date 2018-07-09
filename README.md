I made a <a href='https://louischoki.shinyapps.io/USNewsData/'>RShiny Dashboard</a>.
_______________________________________
# Best Hospitals of Different Specialty

<font color='coral'>
- Scrape the data from the <a href='https://health.usnews.com/best-hospitals/search'>U.S.News Health</a>.
- Get the top 50 hospitals' detailed data.
  - Name
  - Specilty
  - Score
  - Zipcode
  - City
  - State
- Automatically google search to get the exact address (with streets)
- Use `Google Map API` to get the longtitude and latitude data.
- Use `R shiny` to do map visualization.

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
import requests
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

<font color='coral'>


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

<font color='blue'>
    
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
hospitals.to_csv('best_hospital.csv', index = False)
```

## Search Address
- We use google to search the address of the hospitals.
- To get the right results, we search `business names` + `zipcode` + `"address"`.


```python
address = []
```


```python
searchString1 = hospitals['name'] + ' '+ hospitals['city'] + ' address'
searchString2 = hospitals['name'] + ' '+ hospitals['zipcode'] + ' address'
```


```python
def Get_address(search_term):
    escaped_search_term = search_term.replace('&',' ').replace('/',' ').replace(',',' ').replace(' ', '+')
    google_url = 'https://www.google.com/search?q={}&num=10&hl=en'.format(escaped_search_term)
    driver.get(google_url)
    data = BeautifulSoup(driver.page_source, "html.parser")
    try:
        if data.find('div',{'class':'Z0LcW'}) != None:
            return data.find('div',{'class':'Z0LcW'})
        else:
            driver.find_element_by_class_name("cXedhc").click()
            time.sleep(1)
            data = BeautifulSoup(driver.page_source, "html.parser")
            return data.find('span',{'class':'LrzXr'})
    except:
        return 'Cannot Find'
```


```python
driver = webdriver.Chrome(executable_path='/usr/local/bin/chromedriver')
for search_term in searchString1[310:]:
    address.append(Get_address(search_term))
for i in range(len(address)):
    if address[i] == 'Cannot Find' or address[i] == None:
        address[i] = Get_address(searchString2[i])
```

- Let's take a look at the first 10 addresses.


```python
address[:10]
```




    ['1515 Holcombe Blvd, Houston, TX 77030',
     '1275 York Ave, New York, NY 10065',
     '1216 2nd St SW, Rochester, MN 55902',
     '450 Brookline Ave, Boston, MA 02215',
     '1959 NE Pacific St, Seattle, WA 98195',
     '1800 Orleans St, Baltimore, MD 21287',
     '9500 Euclid Ave, Cleveland, OH 44195',
     '51 N 39th St, Philadelphia, PA 19104',
     '4117 E Fowler Ave, Tampa, FL 33612',
     '505 Parnassus Ave, San Francisco, CA 94143']




```python
hospitals['address'] = pd.Series(address)
```


```python
hospitals.to_csv('best_hospital.csv', index = False)
```

## Google Maps API 
- install `googlemaps`
```
pip install googlemaps
```
- get the <a href="https://developers.google.com/maps/documentation/geocoding/start">API key </a>
- Get the `Longtitude` and `Latitude`.


```python
from uszipcode import ZipcodeSearchEngine
import googlemaps
from datetime import datetime
## Getting API
gmaps = googlemaps.Client(key='AIzaSyA3SamAV641tF4lVHTLfYewQ-6-Mtz6i60')
search = ZipcodeSearchEngine()
```

- If we cannot find the location, use the zipcode instead.


```python
location = []
```


```python
# Geocoding an address
for i in range(len(address)):
    try:
        geocode_result = gmaps.geocode(address[i])
        location.append(geocode_result[0]['geometry']['location'])
    except:
        zc = hospitals.zipcode[i].split('-')[0]
        location.append({
            'lat': search.by_zipcode(zc),
            'lng': search.by_zipcode(zc)
        })
```


```python
hospitals['lat'] = pd.DataFrame(location)['lat']
hospitals['long'] = pd.DataFrame(location)['lng']
```


```python
hospitals.to_csv('best_hospital.csv', index = False)
```

## Now we have the final data.


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
      <th>name</th>
      <th>specialty</th>
      <th>score</th>
      <th>city</th>
      <th>state</th>
      <th>zipcode</th>
      <th>address</th>
      <th>lat</th>
      <th>long</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th>0</th>
      <td>University of Texas MD Anderson Cancer Center</td>
      <td>Cancer</td>
      <td>100.0</td>
      <td>Houston</td>
      <td>TX</td>
      <td>77030-4000</td>
      <td>1515 Holcombe Blvd, Houston, TX 77030</td>
      <td>29.7072</td>
      <td>-95.397</td>
    </tr>
    <tr>
      <th>1</th>
      <td>Memorial Sloan Kettering Cancer Center</td>
      <td>Cancer</td>
      <td>97.4</td>
      <td>New York</td>
      <td>NY</td>
      <td>10065-6007</td>
      <td>1275 York Ave, New York, NY 10065</td>
      <td>40.7641</td>
      <td>-73.956</td>
    </tr>
    <tr>
      <th>2</th>
      <td>Mayo Clinic</td>
      <td>Cancer</td>
      <td>91.8</td>
      <td>Rochester</td>
      <td>MN</td>
      <td>55902-1906</td>
      <td>1216 2nd St SW, Rochester, MN 55902</td>
      <td>44.0188</td>
      <td>-92.4785</td>
    </tr>
    <tr>
      <th>3</th>
      <td>Dana-Farber/Brigham and Women's Cancer Center</td>
      <td>Cancer</td>
      <td>84.4</td>
      <td>Boston</td>
      <td>MA</td>
      <td>02215-5418</td>
      <td>450 Brookline Ave, Boston, MA 02215</td>
      <td>42.3375</td>
      <td>-71.1082</td>
    </tr>
    <tr>
      <th>4</th>
      <td>Seattle Cancer Alliance/University of Washingt...</td>
      <td>Cancer</td>
      <td>76.5</td>
      <td>Seattle</td>
      <td>WA</td>
      <td>98109-4405</td>
      <td>1959 NE Pacific St, Seattle, WA 98195</td>
      <td>47.6499</td>
      <td>-122.308</td>
    </tr>
    <tr>
      <th>5</th>
      <td>Johns Hopkins Hospital</td>
      <td>Cancer</td>
      <td>75.9</td>
      <td>Baltimore</td>
      <td>MD</td>
      <td>21205-1832</td>
      <td>1800 Orleans St, Baltimore, MD 21287</td>
      <td>39.2963</td>
      <td>-76.5918</td>
    </tr>
    <tr>
      <th>6</th>
      <td>Cleveland Clinic</td>
      <td>Cancer</td>
      <td>75.0</td>
      <td>Cleveland</td>
      <td>OH</td>
      <td>44195-5108</td>
      <td>9500 Euclid Ave, Cleveland, OH 44195</td>
      <td>41.5034</td>
      <td>-81.6212</td>
    </tr>
    <tr>
      <th>7</th>
      <td>Hospitals of the University of Pennsylvania-Pe...</td>
      <td>Cancer</td>
      <td>75.0</td>
      <td>Philadelphia</td>
      <td>PA</td>
      <td>19104-4206</td>
      <td>51 N 39th St, Philadelphia, PA 19104</td>
      <td>39.9584</td>
      <td>-75.1995</td>
    </tr>
    <tr>
      <th>8</th>
      <td>Moffitt Cancer Center and Research Institute</td>
      <td>Cancer</td>
      <td>74.9</td>
      <td>Tampa</td>
      <td>FL</td>
      <td>33612-9497</td>
      <td>4117 E Fowler Ave, Tampa, FL 33612</td>
      <td>28.0536</td>
      <td>-82.4146</td>
    </tr>
    <tr>
      <th>9</th>
      <td>UCSF Medical Center</td>
      <td>Cancer</td>
      <td>73.3</td>
      <td>San Francisco</td>
      <td>CA</td>
      <td>94143-0296</td>
      <td>505 Parnassus Ave, San Francisco, CA 94143</td>
      <td>37.7631</td>
      <td>-122.458</td>
    </tr>
    <tr>
      <th>10</th>
      <td>Stanford Health Care-Stanford Hospital</td>
      <td>Cancer</td>
      <td>73.2</td>
      <td>Stanford</td>
      <td>CA</td>
      <td>94304-2203</td>
      <td>300 Pasteur Dr, Stanford, CA 94305</td>
      <td>37.4331</td>
      <td>-122.175</td>
    </tr>
    <tr>
      <th>11</th>
      <td>Massachusetts General Hospital</td>
      <td>Cancer</td>
      <td>71.4</td>
      <td>Boston</td>
      <td>MA</td>
      <td>02114-2696</td>
      <td>Blake 4, 55 Fruit St, Boston, MA 02114</td>
      <td>42.3632</td>
      <td>-71.0688</td>
    </tr>
    <tr>
      <th>12</th>
      <td>UCLA Medical Center</td>
      <td>Cancer</td>
      <td>71.4</td>
      <td>Los Angeles</td>
      <td>CA</td>
      <td>90095-8358</td>
      <td>757 Westwood Plaza, Los Angeles, CA 90095</td>
      <td>34.0665</td>
      <td>-118.447</td>
    </tr>
    <tr>
      <th>13</th>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>Cancer</td>
      <td>71.4</td>
      <td>Ann Arbor</td>
      <td>MI</td>
      <td>48109</td>
      <td>1500 E Medical Center Dr, Ann Arbor, MI 48109</td>
      <td>42.282</td>
      <td>-83.7273</td>
    </tr>
    <tr>
      <th>14</th>
      <td>USC Norris Cancer Hospital-Keck Medical Center...</td>
      <td>Cancer</td>
      <td>70.5</td>
      <td>Los Angeles</td>
      <td>CA</td>
      <td>90089-0112</td>
      <td>1441 Eastlake Ave, Los Angeles, CA 90033</td>
      <td>34.0615</td>
      <td>-118.205</td>
    </tr>
    <tr>
      <th>15</th>
      <td>Northwestern Memorial Hospital</td>
      <td>Cancer</td>
      <td>69.9</td>
      <td>Chicago</td>
      <td>IL</td>
      <td>60611-2908</td>
      <td>251 E Huron St, Chicago, IL 60611</td>
      <td>41.8946</td>
      <td>-87.621</td>
    </tr>
    <tr>
      <th>16</th>
      <td>Mayo Clinic-Phoenix</td>
      <td>Cancer</td>
      <td>69.6</td>
      <td>Phoenix</td>
      <td>AZ</td>
      <td>85054-4502</td>
      <td>5777 E Mayo Blvd, Phoenix, AZ 85054</td>
      <td>33.6591</td>
      <td>-111.956</td>
    </tr>
    <tr>
      <th>17</th>
      <td>Mayo Clinic Jacksonville</td>
      <td>Cancer</td>
      <td>69.5</td>
      <td>Jacksonville</td>
      <td>FL</td>
      <td>32224-1865</td>
      <td>4500 San Pablo Rd S, Jacksonville, FL 32224</td>
      <td>30.2645</td>
      <td>-81.4418</td>
    </tr>
    <tr>
      <th>18</th>
      <td>Siteman Cancer Center</td>
      <td>Cancer</td>
      <td>69.3</td>
      <td>Saint Louis</td>
      <td>MO</td>
      <td>63110-1003</td>
      <td>4921 Parkview Pl, St. Louis, MO 63110</td>
      <td>38.6365</td>
      <td>-90.2642</td>
    </tr>
    <tr>
      <th>19</th>
      <td>Jefferson Health-Thomas Jefferson University H...</td>
      <td>Cancer</td>
      <td>69.1</td>
      <td>Philadelphia</td>
      <td>PA</td>
      <td>19107-5084</td>
      <td>132 S 10th St, Philadelphia, PA 19107</td>
      <td>39.9491</td>
      <td>-75.1574</td>
    </tr>
    <tr>
      <th>20</th>
      <td>Cleveland Clinic</td>
      <td>Cardiology and Heart Surgery</td>
      <td>100.0</td>
      <td>Cleveland</td>
      <td>OH</td>
      <td>44195-5108</td>
      <td>Carnegie Ave, Cleveland, OH 44103</td>
      <td>41.5017</td>
      <td>-81.6452</td>
    </tr>
    <tr>
      <th>21</th>
      <td>Mayo Clinic</td>
      <td>Cardiology and Heart Surgery</td>
      <td>99.5</td>
      <td>Rochester</td>
      <td>MN</td>
      <td>55902-1906</td>
      <td>1216 2nd St SW, Rochester, MN 55902</td>
      <td>44.0188</td>
      <td>-92.4785</td>
    </tr>
    <tr>
      <th>22</th>
      <td>New York-Presbyterian Hospital-Columbia and Co...</td>
      <td>Cardiology and Heart Surgery</td>
      <td>85.2</td>
      <td>New York</td>
      <td>NY</td>
      <td>10065-4870</td>
      <td>505 E 70th St, New York, NY 10021</td>
      <td>40.7657</td>
      <td>-73.9541</td>
    </tr>
    <tr>
      <th>23</th>
      <td>Smidt Heart Institute at Cedars-Sinai</td>
      <td>Cardiology and Heart Surgery</td>
      <td>81.8</td>
      <td>Los Angeles</td>
      <td>CA</td>
      <td>90048-1865</td>
      <td>127 San Vicente Blvd., Advanced Health Science...</td>
      <td>34.0746</td>
      <td>-118.379</td>
    </tr>
    <tr>
      <th>24</th>
      <td>Massachusetts General Hospital</td>
      <td>Cardiology and Heart Surgery</td>
      <td>79.0</td>
      <td>Boston</td>
      <td>MA</td>
      <td>02114-2696</td>
      <td>Blake 4, 55 Fruit St, Boston, MA 02114</td>
      <td>42.3632</td>
      <td>-71.0688</td>
    </tr>
    <tr>
      <th>25</th>
      <td>Johns Hopkins Hospital</td>
      <td>Cardiology and Heart Surgery</td>
      <td>77.3</td>
      <td>Baltimore</td>
      <td>MD</td>
      <td>21205-1832</td>
      <td>1800 Orleans St, Baltimore, MD 21287</td>
      <td>39.2963</td>
      <td>-76.5918</td>
    </tr>
    <tr>
      <th>26</th>
      <td>Northwestern Memorial Hospital</td>
      <td>Cardiology and Heart Surgery</td>
      <td>76.7</td>
      <td>Chicago</td>
      <td>IL</td>
      <td>60611-2908</td>
      <td>251 E Huron St, Chicago, IL 60611</td>
      <td>41.8946</td>
      <td>-87.621</td>
    </tr>
    <tr>
      <th>27</th>
      <td>Hospitals of the University of Pennsylvania-Pe...</td>
      <td>Cardiology and Heart Surgery</td>
      <td>75.4</td>
      <td>Philadelphia</td>
      <td>PA</td>
      <td>19104-4206</td>
      <td>51 N 39th St, Philadelphia, PA 19104</td>
      <td>39.9584</td>
      <td>-75.1995</td>
    </tr>
    <tr>
      <th>28</th>
      <td>Mount Sinai Hospital</td>
      <td>Cardiology and Heart Surgery</td>
      <td>75.1</td>
      <td>New York</td>
      <td>NY</td>
      <td>10029-0310</td>
      <td>1468 Madison Ave, New York, NY 10029</td>
      <td>40.7901</td>
      <td>-73.9528</td>
    </tr>
    <tr>
      <th>29</th>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>Cardiology and Heart Surgery</td>
      <td>74.5</td>
      <td>Ann Arbor</td>
      <td>MI</td>
      <td>48109</td>
      <td>1500 E Medical Center Dr, Ann Arbor, MI 48109</td>
      <td>42.282</td>
      <td>-83.7273</td>
    </tr>
    <tr>
      <th>...</th>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
      <td>...</td>
    </tr>
    <tr>
      <th>290</th>
      <td>UPMC Presbyterian Shadyside</td>
      <td>Rheumatology</td>
      <td>7.6</td>
      <td>Pittsburgh</td>
      <td>PA</td>
      <td>15213-2536</td>
      <td>200 Lothrop St, Pittsburgh, PA 15213</td>
      <td>40.4426</td>
      <td>-79.961</td>
    </tr>
    <tr>
      <th>291</th>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>Rheumatology</td>
      <td>7.4</td>
      <td>Ann Arbor</td>
      <td>MI</td>
      <td>48109</td>
      <td>1500 E Medical Center Dr, Ann Arbor, MI 48109</td>
      <td>42.282</td>
      <td>-83.7273</td>
    </tr>
    <tr>
      <th>292</th>
      <td>Duke University Hospital</td>
      <td>Rheumatology</td>
      <td>6.9</td>
      <td>Durham</td>
      <td>NC</td>
      <td>27705-4699</td>
      <td>2301 Erwin Rd, Durham, NC 27710</td>
      <td>36.0071</td>
      <td>-78.9371</td>
    </tr>
    <tr>
      <th>293</th>
      <td>Stanford Health Care-Stanford Hospital</td>
      <td>Rheumatology</td>
      <td>5.9</td>
      <td>Stanford</td>
      <td>CA</td>
      <td>94304-2203</td>
      <td>300 Pasteur Dr, Stanford, CA 94305</td>
      <td>37.4331</td>
      <td>-122.175</td>
    </tr>
    <tr>
      <th>294</th>
      <td>Northwestern Memorial Hospital</td>
      <td>Rheumatology</td>
      <td>4.8</td>
      <td>Chicago</td>
      <td>IL</td>
      <td>60611-2908</td>
      <td>251 E Huron St, Chicago, IL 60611</td>
      <td>41.8946</td>
      <td>-87.621</td>
    </tr>
    <tr>
      <th>295</th>
      <td>Hospitals of the University of Pennsylvania-Pe...</td>
      <td>Rheumatology</td>
      <td>4.3</td>
      <td>Philadelphia</td>
      <td>PA</td>
      <td>19104-4206</td>
      <td>51 N 39th St, Philadelphia, PA 19104</td>
      <td>39.9584</td>
      <td>-75.1995</td>
    </tr>
    <tr>
      <th>296</th>
      <td>Barnes-Jewish Hospital</td>
      <td>Rheumatology</td>
      <td>4.2</td>
      <td>Saint Louis</td>
      <td>MO</td>
      <td>63110-1003</td>
      <td>1 Barnes Jewish Hospital Plaza, St. Louis, MO ...</td>
      <td>38.6352</td>
      <td>-90.2649</td>
    </tr>
    <tr>
      <th>297</th>
      <td>University of Colorado Hospital</td>
      <td>Rheumatology</td>
      <td>3.6</td>
      <td>Aurora</td>
      <td>CO</td>
      <td>80045-2545</td>
      <td>12605 E 16th Ave, Aurora, CO 80045</td>
      <td>39.7426</td>
      <td>-104.842</td>
    </tr>
    <tr>
      <th>298</th>
      <td>MUSC Health-University Medical Center</td>
      <td>Rheumatology</td>
      <td>3.4</td>
      <td>Charleston</td>
      <td>SC</td>
      <td>29425-8905</td>
      <td>650 Ellis Oak Dr, Charleston, SC 29412</td>
      <td>32.746</td>
      <td>-79.9695</td>
    </tr>
    <tr>
      <th>299</th>
      <td>Scripps La Jolla Hospitals</td>
      <td>Rheumatology</td>
      <td>3.1</td>
      <td>La Jolla</td>
      <td>CA</td>
      <td>92037-1200</td>
      <td>9888 Genesee Ave, La Jolla, CA 92037</td>
      <td>32.8852</td>
      <td>-117.226</td>
    </tr>
    <tr>
      <th>300</th>
      <td>Cleveland Clinic</td>
      <td>Urology</td>
      <td>100.0</td>
      <td>Cleveland</td>
      <td>OH</td>
      <td>44195-5108</td>
      <td>Carnegie Ave, Cleveland, OH 44103</td>
      <td>41.5017</td>
      <td>-81.6452</td>
    </tr>
    <tr>
      <th>301</th>
      <td>Mayo Clinic</td>
      <td>Urology</td>
      <td>99.5</td>
      <td>Rochester</td>
      <td>MN</td>
      <td>55902-1906</td>
      <td>1216 2nd St SW, Rochester, MN 55902</td>
      <td>44.0188</td>
      <td>-92.4785</td>
    </tr>
    <tr>
      <th>302</th>
      <td>Johns Hopkins Hospital</td>
      <td>Urology</td>
      <td>95.9</td>
      <td>Baltimore</td>
      <td>MD</td>
      <td>21205-1832</td>
      <td>1800 Orleans St, Baltimore, MD 21287</td>
      <td>39.2963</td>
      <td>-76.5918</td>
    </tr>
    <tr>
      <th>303</th>
      <td>UCLA Medical Center</td>
      <td>Urology</td>
      <td>86.6</td>
      <td>Los Angeles</td>
      <td>CA</td>
      <td>90095-8358</td>
      <td>757 Westwood Plaza, Los Angeles, CA 90095</td>
      <td>34.0665</td>
      <td>-118.447</td>
    </tr>
    <tr>
      <th>304</th>
      <td>Memorial Sloan Kettering Cancer Center</td>
      <td>Urology</td>
      <td>86.3</td>
      <td>New York</td>
      <td>NY</td>
      <td>10065-6007</td>
      <td>1275 York Ave, New York, NY 10065</td>
      <td>40.7641</td>
      <td>-73.956</td>
    </tr>
    <tr>
      <th>305</th>
      <td>UCSF Medical Center</td>
      <td>Urology</td>
      <td>85.1</td>
      <td>San Francisco</td>
      <td>CA</td>
      <td>94143-0296</td>
      <td>505 Parnassus Ave, San Francisco, CA 94143</td>
      <td>37.7631</td>
      <td>-122.458</td>
    </tr>
    <tr>
      <th>306</th>
      <td>University of Michigan Hospitals-Michigan Medi...</td>
      <td>Urology</td>
      <td>83.7</td>
      <td>Ann Arbor</td>
      <td>MI</td>
      <td>48109</td>
      <td>1500 E Medical Center Dr, Ann Arbor, MI 48109</td>
      <td>42.282</td>
      <td>-83.7273</td>
    </tr>
    <tr>
      <th>307</th>
      <td>New York-Presbyterian Hospital-Columbia and Co...</td>
      <td>Urology</td>
      <td>80.4</td>
      <td>New York</td>
      <td>NY</td>
      <td>10065-4870</td>
      <td>505 E 70th St, New York, NY 10021</td>
      <td>40.7657</td>
      <td>-73.9541</td>
    </tr>
    <tr>
      <th>308</th>
      <td>Vanderbilt University Medical Center</td>
      <td>Urology</td>
      <td>80.2</td>
      <td>Nashville</td>
      <td>TN</td>
      <td>37232-2102</td>
      <td>1211 Medical Center Dr, Nashville, TN 37232</td>
      <td>36.1424</td>
      <td>-86.8004</td>
    </tr>
    <tr>
      <th>309</th>
      <td>Duke University Hospital</td>
      <td>Urology</td>
      <td>80.1</td>
      <td>Durham</td>
      <td>NC</td>
      <td>27705-4699</td>
      <td>2301 Erwin Rd, Durham, NC 27710</td>
      <td>36.0071</td>
      <td>-78.9371</td>
    </tr>
    <tr>
      <th>310</th>
      <td>Northwestern Memorial Hospital</td>
      <td>Urology</td>
      <td>79.0</td>
      <td>Chicago</td>
      <td>IL</td>
      <td>60611-2908</td>
      <td>251 E Huron St, Chicago, IL 60611</td>
      <td>41.8946</td>
      <td>-87.621</td>
    </tr>
    <tr>
      <th>311</th>
      <td>Cedars-Sinai Medical Center</td>
      <td>Urology</td>
      <td>78.0</td>
      <td>Los Angeles</td>
      <td>CA</td>
      <td>90048-1865</td>
      <td>8700 Beverly Blvd, Los Angeles, CA 90048</td>
      <td>34.0752</td>
      <td>-118.38</td>
    </tr>
    <tr>
      <th>312</th>
      <td>UPMC Presbyterian Shadyside</td>
      <td>Urology</td>
      <td>77.7</td>
      <td>Pittsburgh</td>
      <td>PA</td>
      <td>15213-2536</td>
      <td>200 Lothrop St, Pittsburgh, PA 15213</td>
      <td>40.4426</td>
      <td>-79.961</td>
    </tr>
    <tr>
      <th>313</th>
      <td>Stanford Health Care-Stanford Hospital</td>
      <td>Urology</td>
      <td>77.3</td>
      <td>Stanford</td>
      <td>CA</td>
      <td>94304-2203</td>
      <td>300 Pasteur Dr, Stanford, CA 94305</td>
      <td>37.4331</td>
      <td>-122.175</td>
    </tr>
    <tr>
      <th>314</th>
      <td>NYU Langone Hospitals</td>
      <td>Urology</td>
      <td>76.5</td>
      <td>New York</td>
      <td>NY</td>
      <td>10016-6402</td>
      <td>550 1st Avenue, New York, NY 10016</td>
      <td>40.7421</td>
      <td>-73.974</td>
    </tr>
    <tr>
      <th>315</th>
      <td>University of Wisconsin Hospitals</td>
      <td>Urology</td>
      <td>76.0</td>
      <td>Madison</td>
      <td>WI</td>
      <td>53792-0002</td>
      <td>750 Highland Ave, Madison, WI 53726</td>
      <td>43.0771</td>
      <td>-89.4291</td>
    </tr>
    <tr>
      <th>316</th>
      <td>University of Kansas Hospital</td>
      <td>Urology</td>
      <td>75.6</td>
      <td>Kansas City</td>
      <td>KS</td>
      <td>66160-7200</td>
      <td>4000 Cambridge St, Kansas City, KS 66160</td>
      <td>39.0562</td>
      <td>-94.6088</td>
    </tr>
    <tr>
      <th>317</th>
      <td>Barnes-Jewish Hospital</td>
      <td>Urology</td>
      <td>74.4</td>
      <td>Saint Louis</td>
      <td>MO</td>
      <td>63110-1003</td>
      <td>1 Barnes Jewish Hospital Plaza, St. Louis, MO ...</td>
      <td>38.6352</td>
      <td>-90.2649</td>
    </tr>
    <tr>
      <th>318</th>
      <td>UT Southwestern Medical Center</td>
      <td>Urology</td>
      <td>74.2</td>
      <td>Dallas</td>
      <td>TX</td>
      <td>75390-9265</td>
      <td>5323 Harry Hines Blvd, Dallas, TX 75390</td>
      <td>32.8122</td>
      <td>-96.8405</td>
    </tr>
    <tr>
      <th>319</th>
      <td>University of Alabama at Birmingham Hospital</td>
      <td>Urology</td>
      <td>73.8</td>
      <td>Birmingham</td>
      <td>AL</td>
      <td>35249-1900</td>
      <td>1802 6th Ave S, Birmingham, AL 35233</td>
      <td>33.5066</td>
      <td>-86.8032</td>
    </tr>
  </tbody>
</table>
<p>320 rows × 9 columns</p>
</div>


