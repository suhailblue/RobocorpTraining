*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser
Library           RPA.Excel.Files
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets


*** Variables ***

${RETRY_TIMES}    5x
${RETRY_INTERVAL}    1s
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}..${/}output${/}reciepts
${OUTPUT_DIRECTORY}=    ${CURDIR}${/}..${/}output


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${order_list}=    Get orders
        FOR    ${row}    IN    @{order_list}
            Log   Each Row: ${row} 
            Close the popup
            Fill the form for order   ${row}
            Preview the order
            Wait Until Keyword Succeeds   ${RETRY_TIMES}    ${RETRY_INTERVAL}    Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt    ${screenshot}    ${pdf}
            Go to order another robot
        END
    Create a archive of the receipts
    [Teardown]    Close Browser

Minimal task
    Log  Done.

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order


*** Keywords ***
Collect downloadfilepath From User
    Add text input    location    label=Download path
    ${response}=     Run dialog
    [Return]    ${response.location}

*** Keywords ***
Get orders
    ${file_url}=  Get Secret    downloadfilepath
    Log    ${file_url}[url]
    #${file_url}=    Collect downloadfilepath From User
    #Download    https://robotsparebinindustries.com/orders.csv   overwrite=True
    #Download    ${file_url}   overwrite=True
    Download    ${file_url}[url]   overwrite=True
    ${order_list}=    Read table from CSV    orders.csv
    Log   Found columns: ${order_list.columns}
    
    [Return]    ${order_list}

*** Keywords ***
Close the popup
  Click Element if Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

*** Keywords ***
Fill the form for order 
    [Arguments]    ${order}
    
    ${head_value_string}=    Convert To String    ${order}[Head]
    ${body_value_string}=    Convert To String    ${order}[Body]
    ${legs_value_string}=    Convert To String    ${order}[Legs]
    ${address_value_string}=    Convert To String    ${order}[Address]

    Select From List By Value    head    ${head_value_string}
    Click Element    id-body-${body_value_string}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${legs_value_string}
    Input Text    address    ${address_value_string}
        
** Keywords ***
Preview the order
    Click Button  preview

** Keywords ***
Submit the order
    Click Button  order
    Assert order submitted

** Keywords ***
Assert order submitted
    Wait Until Element Is Visible    id:order-completion

** Keywords ***
Store the receipt as a PDF file    
    [Arguments]    ${order_number}

    Wait Until Element Is Visible    receipt
    ${reciept_html}=    Get Element Attribute    xpath://*[@id="receipt"]   outerHTML
    ${directory_exists}=    Does Directory Exist    ${CURDIR}${/}..${/}output${/}reciepts
    Run Keyword If    ${directory_exists}==False    Create directory    ${CURDIR}${/}..${/}output${/}reciepts
    ${pdf_filepath}=    Set Variable    ${CURDIR}${/}..${/}output${/}reciepts${/}${order_number}.pdf

    Html To Pdf    ${reciept_html}    ${pdf_filepath}

    [Return]    ${pdf_filepath}




*** Keywords ***
Take a screenshot of the robot  
    [Arguments]    ${order_number}

    ${directory_exists}=    Does Directory Exist    ${CURDIR}${/}..${/}output${/}screens
    Run Keyword If    ${directory_exists}==False    Create directory    ${CURDIR}${/}..${/}output${/}screens
    ${screenshot_path}=    Capture Element Screenshot    robot-preview-image    ${CURDIR}${/}..${/}output${/}screens${/}${order_number}.png

    [Return]    ${screenshot_path}


*** Keywords ***
Embed the robot screenshot to the receipt
    [Arguments]    ${screenshot_path}    ${pdf_path}
    
    Add Watermark Image To PDF    ${screenshot_path}    ${pdf_path}    ${pdf_path}


*** Keywords ***
Go to order another robot 
    Click Button  order-another


*** Keywords ***
Set up directories

    ${directory_exists}=    Does Directory Exist    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Run Keyword If    ${directory_exists}==False    Create directory    ${PDF_TEMP_OUTPUT_DIRECTORY}

    ${directory_exists}=    Does Directory Exist    ${OUTPUT_DIRECTORY}
    Run Keyword If    ${directory_exists}==False    Create directory     ${OUTPUT_DIRECTORY}

*** Keywords ***
Create a archive of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIRECTORY}/orders.zip

    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

