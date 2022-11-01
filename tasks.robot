*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.PDF
Library             String
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault    default_adapter=RPA.Robocorp.Vault.FileSecrets
Library             Collections


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download the user given CSV file
    Open the robot order website
    Make a folder for the order receipts
    Fill the order forms using the data from the CSV file
    Package the orders folder to a ZIP file
    [Teardown]    Close the website


*** Keywords ***
Get order page URL from secrets
    ${secret}=    Get Secret    robot order robot
    ${url}=    Get From Dictionary    ${secret}    ORDER_URL
    RETURN    ${url}

Open the robot order website
    ${url}=  Get order page URL from secrets
    Open Available Browser    ${url}

Close the website
    Close Browser

Ask user input for orders CSV file URL
    #Add heading    Orders CSV file URL
    Add text input    url    label=Orders CSV file URL    rows=1
    ${result}=    Run dialog
    RETURN  ${result.url}

#Download orders file
#    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Download the user given CSV file
    ${url}=    Ask user input for orders CSV file URL
    Download    ${url}    overwrite=True

Close the start modal
    Wait Until Element Is Visible    css:div.alert-buttons
    Click Button    Yep

Make a folder for the order receipts
    Create Directory    ${OUTPUT_DIR}${/}Orders

Package the orders folder to a ZIP file
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Orders    ${OUTPUT_DIR}${/}Orders.zip

Preview the robot and submit the order
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image
    Click Button    id:order
    ${error_exist}=    Does Page Contain Element    css:.alert-danger
    WHILE    ${error_exist}
        Click Button    id:order
        ${error_exist}=    Does Page Contain Element    css:.alert-danger
    END

Fill the order form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Save the order preview and receipt as a PDF file
    [Arguments]    ${order_number}
    ${out_path}=    Format String    {o}{s}Orders{s}Order_{n}    o=${OUTPUT_DIR}    s=${/}    n=${order_number}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Screenshot    id:robot-preview-image    ${out_path}_Preview.png
    ${file}=    Create List    ${out_path}_Preview.png:align=center
    Html To Pdf    ${receipt_html}    ${out_path}_Receipt.pdf
    Add Files To Pdf    ${file}    ${out_path}_Receipt.pdf    True

Go back to order page
    Click Button    id:order-another

Fill the order forms using the data from the CSV file
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Close the start modal
        Fill the order form    ${order}
        Preview the robot and submit the order
        Save the order preview and receipt as a PDF file    ${order}[Order number]
        Go back to order page
    END
