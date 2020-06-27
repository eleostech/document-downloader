<#Collaboration on this code by Corey Fuller and ELijah Webb.
Since I am currently having trouble getting 
Drive Axle API keys we are going to use the NASA
Astronomy Picture of the day to test functionality -Eli
#>

#File path to the folder where you want files stored -Eli
$PATH_VAR = "C:\Users\xaubr\OneDrive\Desktop\E-pics\nasa.jpg"

#Place holder API KEY -Eli
$API_KEY = "Cf1jJAX2OXflpgkj3nBdcVCdJwN7HpAg1yjUxqFg"

#This will be used to hold the return of Invoke-Web-Request -Eli
$RETURN_VALUE

<#CJ and I thought about using Invoke-RestMethod, but realized
it does not return the http status code so we returned to the
original idea of using Invoke-WebRequest -Eli
#>
<#$URI = "https://api.nasa.gov/planetary/apod?api_key="

$RETURN_VALUE = Invoke-RestMethod -Method Get -Uri https://api.nasa.gov/planetary/apod?api_key=$API_KEY

$RETURN_VALUE.StatusCode

wget $RETURN_VALUE.url -outfile "C:\Users\xaubr\OneDrive\Desktop\E-pics\nasa.jpg"#>

$RETURN_VALUE = Invoke-WebRequest -Uri https://api.nasa.gov/planetary/apod?api_key=$API_KEY -Method Get

<#Although Invoke-WebRequest gives us the StatusCode member
it does not natively return just the JSON object like Invoke-RestMethod
So I had to use ConvertFrom-Json as a workaround to access the file URL -Eli
#>
$JSON_Object = ConvertFrom-Json $RETURN_VALUE

<#This downloads the file and places it in the folder
The folder must already exist when this command is called -Eli
#>
wget $JSON_Object.url -OutFile $PATH_VAR



#Need API key from Drive Axle Hub

## Script Structure to Implement - Corey


<#
    Call the /next enpoint until we get a 304 status
        Use Location header
        Get response from location header
        use the "download_url" to get the data
        Delete download url 
        sort data into respective folder

        Append information to a log
#>