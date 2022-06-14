*** Settings ***
Library  SeleniumLibrary

Test Setup       Test Case Setup
Test Teardown    Test Case Teardown

*** Test Cases ***
Verify Version
    Go To   http://localhost:8080 
    ${meta_version} =   Get Element Attribute  xpath=//html/head/meta[@name="version"]  content
    Should Be Equal  ${meta_version}  ${BUILD_VERSION}

*** Keywords ***

Test Case Setup
    Create WebDriver With Chrome Options

Create WebDriver With Chrome Options
    ${chrome_options} =    Evaluate    selenium.webdriver.ChromeOptions()
    Call Method    ${chrome_options}    add_argument    --log-level\=3
    Call Method    ${chrome_options}    add_argument    --headless
    Call Method    ${chrome_options}    add_argument    --disable-extensions
    Call Method    ${chrome_options}    add_argument    --no-sandbox
    Call Method    ${chrome_options}    add_argument    --disable-dev-shm-usage
    Create WebDriver    Chrome    chrome_options=${chrome_options} 

Test Case Teardown
    Capture Page Screenshot
    Close Browser 
