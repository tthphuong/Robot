*** Settings ***
Documentation     Robot to enter weekly sales data into the RobotSpareBin Industries Intranet.
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library    		  RPA.Robocloud.Secrets
Library           RPA.Dialogs
Library           RPA.Browser.Selenium
Library           OperatingSystem


*** Variables ***
${FILENAME}=   orders.csv
${DOWNLOAD_DIR}=    ${CURDIR}

# +
*** Keywords ***
Collect Search Query From User
    Add heading     Input URL of order file
    Add text input    search    label=Search query
    Add text      URL : https://robotsparebinindustries.com/orders.csv
    ${response}=    Run dialog
    [Return]    ${response.search}

Wait For Download To Complete
    Wait Until Keyword Succeeds
    ...    2 min
    ...    5 sec
    ...    File Should Exist
    ...    ${FILENAME}

Download Orders file to download directory
    ${urlOrder}=    Collect Search Query From User
    Set Download Directory     ${DOWNLOAD_DIR}
    Open Available Browser
    ...    ${urlOrder}    
    Wait For Download To Complete 
    [Teardown]    Close All Browsers
    
Open the robot order website
	${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[url]
    Maximize Browser Window    
    Sleep    3
    
Get orders
    ${orders}=
    ...    Read Table From Csv
    ...    ${CURDIR}${/}orders.csv
    ...    header=True
    Return From Keyword  ${orders}
Close the annoying modal
    Click Button    OK
    Sleep    3

Go to order another robot
    Click Element    xpath = //*[@id='order-another']
    Sleep    1


Take Screenshot
    Set Screenshot Directory    ${CURDIR}${/}output${/}Screenshots         
    Capture Page Screenshot    


Fill the form
    [Arguments]    ${order}
    Log  ${order}
    Click Element    xpath = //*[@id='head']
    Sleep    1    
    Click Element   xpath = //*[@id='head']//option[@value = ${order}[Head]]
    Sleep    1
    Scroll Element Into View     xpath = //label[@for ='id-body-${order}[Body]']
    Click Element   xpath = //label[@for ='id-body-${order}[Body]']
    Sleep    1
    Scroll Element Into View    xpath = //label[contains(text(),'Leg')]/following-sibling::*[@class="form-control"]
    Input Text    xpath = //label[contains(text(),'Leg')]/following-sibling::*[@class="form-control"]    ${order}[Legs]
    Sleep    1
    Scroll Element Into View    xpath = //*[@id ='address']
    Input Text    xpath = //*[@id ='address']    ${order}[Address]
    Sleep    1

Preview the robot
    Scroll Element Into View    xpath = //button[text()='Order']
    Click Button    Preview
    Sleep    1     

Submit the order
    FOR	${var}	IN RANGE    999
        Click Button    Order
        Sleep    2
        ${btnOrder}=  Get Element Count    xpath =//button[text()='Order']       
        Log    ${btnOrder}
        Exit For Loop If    ${btnOrder}==0
    END       
    Sleep    1    
    Take Screenshot

Store the receipt as a PDF file  
    [Arguments]    ${numberOrder}
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=   Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${CURDIR}${/}output${/}pfdFile${/}order_${numberOrder}.pdf

Take a screenshot of the robot
    [Arguments]    ${numberOrder}
    Wait Until Element Is Visible    id:robot-preview-image
    Capture Element Screenshot    id:robot-preview-image     ${CURDIR}${/}output${/}pfdFile${/}robotImage_${numberOrder}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${numberOrder}
    Add Watermark Image To PDF
    ...             image_path=${CURDIR}${/}output${/}pfdFile${/}robotImage_${numberOrder}.png
    ...             source_path=${CURDIR}${/}output${/}pfdFile${/}order_${numberOrder}.pdf
    ...             output_path=${CURDIR}${/}output${/}pfdFile${/}order_${numberOrder}.pdf

Create a ZIP file of the receipts
    Archive Folder With ZIP   ${CURDIR}${/}output${/}pfdFile  Orders.zip   recursive=True  include=*.pdf
   @{files}                  List Archive             Orders.zip
   FOR  ${file}  IN  ${files}
      Log  ${file}
   END

# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc  
    Download Orders file to download directory
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        Store the receipt as a PDF file    ${row}[Order number]
        Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts
    
